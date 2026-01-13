#!/bin/bash
# AI-Homelab Deployment Script
# This script deploys the core infrastructure and Dockge
# Run after: 1) setup-homelab.sh and 2) editing .env file
# Run as: ./deploy-homelab.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root (use: sudo ./deploy-homelab.sh)"
    exit 1
fi

# Get the actual user who invoked sudo
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" = "root" ]; then
    log_error "Please run this script with sudo, not as root user"
    exit 1
fi

# Get script directory (AI-Homelab/scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

log_info "AI-Homelab Deployment Script"
log_info "Running as user: $ACTUAL_USER"
echo ""

# Check if .env file exists
if [ ! -f "$REPO_DIR/.env" ]; then
    log_error ".env file not found!"
    log_info "Please create and configure your .env file first:"
    echo "  cd $REPO_DIR"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please run setup-homelab.sh first."
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running or you don't have permission."
    log_info "Try: sudo systemctl start docker"
    log_info "Or log out and log back in for group changes to take effect"
    exit 1
fi

log_success "Docker is available and running"
echo ""

# Load environment variables for domain check
source "$REPO_DIR/.env"

if [ -z "$DOMAIN" ]; then
    log_error "DOMAIN is not set in .env file"
    log_info "Please edit .env and set your DuckDNS domain"
    exit 1
fi

log_info "Using domain: $DOMAIN"
echo ""

# Step 1: Create required directories
log_info "Step 1/5: Creating required directories..."
mkdir -p /opt/stacks/core
mkdir -p /opt/stacks/infrastructure
mkdir -p /opt/dockge/data
log_success "Directories created"
echo ""

# Step 2: Create Docker networks (if they don't exist)
log_info "Step 2/5: Creating Docker networks..."
docker network create homelab-network 2>/dev/null && log_success "Created homelab-network" || log_info "homelab-network already exists"
docker network create traefik-network 2>/dev/null && log_success "Created traefik-network" || log_info "traefik-network already exists"
docker network create dockerproxy-network 2>/dev/null && log_success "Created dockerproxy-network" || log_info "dockerproxy-network already exists"
docker network create media-network 2>/dev/null && log_success "Created media-network" || log_info "media-network already exists"
echo ""

# Step 3: Deploy core infrastructure (DuckDNS, Traefik, Authelia, Gluetun)
log_info "Step 3/5: Deploying core infrastructure stack..."
log_info "  - DuckDNS (Dynamic DNS)"
log_info "  - Traefik (Reverse Proxy with SSL)"
log_info "  - Authelia (Single Sign-On)"
log_info "  - Gluetun (VPN Client)"
echo ""

# Copy core stack files
cp "$REPO_DIR/docker-compose/core.yml" /opt/stacks/core/docker-compose.yml
cp -r "$REPO_DIR/config-templates/traefik" /opt/stacks/core/
cp -r "$REPO_DIR/config-templates/authelia" /opt/stacks/core/
cp "$REPO_DIR/.env" /opt/stacks/core/.env

# Create acme.json as a file (not directory) with correct permissions
log_info "Creating acme.json for SSL certificates..."
touch /opt/stacks/core/traefik/acme.json
chmod 600 /opt/stacks/core/traefik/acme.json
log_success "acme.json created with correct permissions"

# Replace email placeholder in traefik.yml
log_info "Configuring Traefik with email: $ACME_EMAIL..."
sed -i "s/ACME_EMAIL_PLACEHOLDER/${ACME_EMAIL}/g" /opt/stacks/core/traefik/traefik.yml
log_success "Traefik email configured"

# Replace domain placeholder in authelia configuration
log_info "Configuring Authelia for domain: $DOMAIN..."
sed -i "s/your-domain.duckdns.org/${DOMAIN}/g" /opt/stacks/core/authelia/configuration.yml

# Generate Authelia admin password if not already configured
if grep -q "CHANGEME" /opt/stacks/core/authelia/users_database.yml 2>/dev/null || [ ! -f /opt/stacks/core/authelia/users_database.yml ]; then
    log_info "Generating Authelia admin credentials..."
    
    # Generate a random password if not provided
    ADMIN_PASSWORD="${AUTHELIA_ADMIN_PASSWORD:-$(openssl rand -base64 16)}"
    
    # Generate password hash using Authelia container
    log_info "Generating password hash (this may take a moment)..."
    PASSWORD_HASH=$(docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password "$ADMIN_PASSWORD" | grep 'Digest:' | awk '{print $2}')
    
    if [ -z "$PASSWORD_HASH" ]; then
        log_error "Failed to generate password hash"
        log_info "Using template users_database.yml - please configure manually"
    else
        # Create users_database.yml with generated credentials
        cat > /opt/stacks/core/authelia/users_database.yml << EOF
###############################################################
#                         Users Database                      #
###############################################################

users:
  admin:
    displayname: "Admin User"
    password: "${PASSWORD_HASH}"
    email: ${ACME_EMAIL}
    groups:
      - admins
      - users
EOF
        
        log_success "Authelia admin user configured"
        log_info "Admin username: admin"
        log_info "Admin password: $ADMIN_PASSWORD"
        log_warning "SAVE THIS PASSWORD! Writing to /opt/stacks/core/authelia/ADMIN_PASSWORD.txt"
        echo "$ADMIN_PASSWORD" > /opt/stacks/core/authelia/ADMIN_PASSWORD.txt
        chmod 600 /opt/stacks/core/authelia/ADMIN_PASSWORD.txt
    fi
else
    log_info "Authelia users_database.yml already configured"
fi

# Deploy core stack
cd /opt/stacks/core
docker compose up -d

log_success "Core infrastructure deployed"
echo ""

# Wait for Traefik to be ready
log_info "Waiting for Traefik to initialize..."
sleep 10

# Check if Traefik is healthy
if docker ps | grep -q "traefik.*Up"; then
    log_success "Traefik is running"
else
    log_warning "Traefik container check inconclusive, continuing..."
fi
echo ""

# Step 4: Deploy infrastructure stack (Dockge and monitoring tools)
log_info "Step 4/5: Deploying infrastructure stack..."
log_info "  - Dockge (Docker Compose Manager)"
log_info "  - Pi-hole (DNS Ad Blocker)"
log_info "  - Watchtower (Container Updates)"
log_info "  - Dozzle (Log Viewer)"
log_info "  - Glances (System Monitor)"
log_info "  - Docker Proxy (Security)"
echo ""

# Copy infrastructure stack
cp "$REPO_DIR/docker-compose/infrastructure.yml" /opt/stacks/infrastructure/docker-compose.yml
cp "$REPO_DIR/.env" /opt/stacks/infrastructure/.env

# Deploy infrastructure stack
cd /opt/stacks/infrastructure
docker compose up -d

log_success "Infrastructure stack deployed"
echo ""

# Step 5: Wait for Dockge to be ready and open browser
log_info "Step 5/5: Waiting for Dockge web UI to be ready..."

DOCKGE_URL="https://dockge.${DOMAIN}"
MAX_WAIT=60  # Maximum wait time in seconds
WAITED=0

# Function to check if Dockge is accessible
check_dockge() {
    # Try to connect to Dockge (ignore SSL cert warnings for self-signed during startup)
    curl -k -s -o /dev/null -w "%{http_code}" "$DOCKGE_URL" 2>/dev/null
}

# Wait for Dockge to respond
while [ $WAITED -lt $MAX_WAIT ]; do
    HTTP_CODE=$(check_dockge)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "401" ]; then
        log_success "Dockge web UI is ready!"
        break
    fi
    echo -n "."
    sleep 2
    WAITED=$((WAITED + 2))
done

echo ""
echo ""

if [ $WAITED -ge $MAX_WAIT ]; then
    log_warning "Dockge did not respond within ${MAX_WAIT} seconds"
    log_info "It may still be starting up. Check manually at: $DOCKGE_URL"
else
    # Try to open browser
    log_info "Opening Dockge in your browser..."
    
    # Detect and use available browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "$DOCKGE_URL" &> /dev/null &
        log_success "Browser opened"
    elif command -v gnome-open &> /dev/null; then
        gnome-open "$DOCKGE_URL" &> /dev/null &
        log_success "Browser opened"
    elif command -v firefox &> /dev/null; then
        firefox "$DOCKGE_URL" &> /dev/null &
        log_success "Browser opened"
    elif command -v google-chrome &> /dev/null; then
        google-chrome "$DOCKGE_URL" &> /dev/null &
        log_success "Browser opened"
    else
        log_warning "No browser detected. Please manually open: $DOCKGE_URL"
    fi
fi

echo ""
echo "=========================================="
log_success "Deployment completed successfully!"
echo "=========================================="
echo ""
log_info "Access your services:"
echo ""
echo "  🚀 Dockge:   $DOCKGE_URL"
echo "  🔒 Authelia: https://auth.${DOMAIN}"
echo "  🔀 Traefik:  https://traefik.${DOMAIN}"
echo ""
log_info "Next steps:"
echo ""
echo "  1. Log in to Dockge using your Authelia credentials"
echo "     (configured in /opt/stacks/core/authelia/users_database.yml)"
echo ""
echo "  2. Deploy additional stacks through Dockge's web UI:"
echo "     - alternatives.yml (Portainer, Authentik - optional alternatives)"
echo "     - dashboards.yml (Homepage, Homarr)"
echo "     - media.yml (Plex, Jellyfin, Sonarr, Radarr, etc.)"
echo "     - media-extended.yml (Readarr, Lidarr, etc.)"
echo "     - homeassistant.yml (Home Assistant and accessories)"
echo "     - productivity.yml (Nextcloud, Gitea, wikis)"
echo "     - monitoring.yml (Grafana, Prometheus, etc.)"
echo "     - utilities.yml (Backups, code editors, etc.)"
echo ""
echo "  3. Configure services via the AI assistant in VS Code"
echo ""
echo "=========================================="
echo ""
log_info "For documentation, see: $REPO_DIR/docs/"
log_info "For troubleshooting, see: $REPO_DIR/docs/quick-reference.md"
echo ""
