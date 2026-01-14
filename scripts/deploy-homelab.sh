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
log_info "Validating Docker installation..."

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    log_info "Please run the setup script first:"
    log_info "  cd ~/AI-Homelab/scripts"
    log_info "  sudo ./setup-homelab.sh"
    exit 1
fi

if ! docker info &> /dev/null 2>&1; then
    log_error "Docker daemon is not running or not accessible"
    echo ""
    log_info "Troubleshooting steps:"
    log_info "  1. Start Docker: sudo systemctl start docker"
    log_info "  2. Enable Docker on boot: sudo systemctl enable docker"
    log_info "  3. Check Docker status: sudo systemctl status docker"
    log_info "  4. If recently added to docker group, log out and back in"
    log_info "  5. Test access: docker ps"
    echo ""
    log_info "Current user: $ACTUAL_USER"
    log_info "Docker group membership: $(groups $ACTUAL_USER | grep -o docker || echo 'NOT IN DOCKER GROUP')"
    exit 1
fi

log_success "Docker is available and running"
log_info "Docker version: $(docker --version | cut -d' ' -f3 | tr -d ',')"
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
log_info "Preparing core stack configuration files..."

# Safety: Stop existing core stack if running (prevents file conflicts)
if [ -f "/opt/stacks/core/docker-compose.yml" ]; then
    log_info "Stopping existing core stack for safe reconfiguration..."
    cd /opt/stacks/core && docker compose down 2>/dev/null || true
    sleep 2
fi

# Clean up any incorrect directory structure from previous runs
if [ -d "/opt/stacks/core/traefik/acme.json" ]; then
    log_warning "Removing incorrectly created acme.json directory"
    rm -rf /opt/stacks/core/traefik/acme.json
fi
if [ -d "/opt/stacks/core/traefik/traefik.yml" ]; then
    log_warning "Removing incorrectly created traefik.yml directory"
    rm -rf /opt/stacks/core/traefik/traefik.yml
fi

# Copy compose file
cp "$REPO_DIR/docker-compose/core.yml" /opt/stacks/core/docker-compose.yml

# Safely remove and replace config directories
if [ -d "/opt/stacks/core/traefik" ]; then
    rm -rf /opt/stacks/core/traefik
fi
if [ -d "/opt/stacks/core/authelia" ]; then
    rm -rf /opt/stacks/core/authelia
fi

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

# Configure Authelia admin user from setup script
if [ -f /tmp/authelia_admin_credentials.tmp ] && [ -f /tmp/authelia_password_hash.tmp ]; then
    log_info "Loading Authelia admin credentials from setup script..."
    source /tmp/authelia_admin_credentials.tmp
    
    if [ -n "$ADMIN_USER" ] && [ -n "$ADMIN_EMAIL" ]; then
        log_success "Using credentials: $ADMIN_USER ($ADMIN_EMAIL)"
        
        # Create users_database.yml with credentials from setup
        # Use single quotes in heredoc to prevent variable expansion issues with $ in hash
        cat > /opt/stacks/core/authelia/users_database.yml << 'EOF'
###############################################################
#                         Users Database                      #
###############################################################

users:
  ADMIN_USER_PLACEHOLDER:
    displayname: "Admin User"
    password: "PASSWORD_HASH_PLACEHOLDER"
    email: ADMIN_EMAIL_PLACEHOLDER
    groups:
      - admins
      - users
EOF
        # Now safely replace placeholders
        # Read hash from file (not bash variable) to avoid shell expansion
        # The hash file was written directly from Docker output in setup script
        export ADMIN_USER
        export ADMIN_EMAIL
        python3 << 'PYTHON_EOF'
# Read password hash from file to completely avoid bash variable expansion
with open('/tmp/authelia_password_hash.tmp', 'r') as f:
    password_hash = f.read().strip()

import os
admin_user = os.environ['ADMIN_USER']
admin_email = os.environ['ADMIN_EMAIL']

content = f"""###############################################################
#                         Users Database                      #
###############################################################

users:
  {admin_user}:
    displayname: "Admin User"
    password: "{password_hash}"
    email: {admin_email}
    groups:
      - admins
      - users
"""

with open('/opt/stacks/core/authelia/users_database.yml', 'w') as f:
    f.write(content)
PYTHON_EOF
        
        log_success "Authelia admin user configured from setup script"
        echo ""
        echo "==========================================="
        log_info "Authelia Login Credentials:"
        echo "  Username: $ADMIN_USER"
        echo "  Password: $ADMIN_PASSWORD"
        echo "  Email: $ADMIN_EMAIL"
        echo "==========================================="
        echo ""
        log_warning "SAVE THESE CREDENTIALS!"
        
        # Save password to file for reference
        echo "$ADMIN_PASSWORD" > /opt/stacks/core/authelia/ADMIN_PASSWORD.txt
        chmod 600 /opt/stacks/core/authelia/ADMIN_PASSWORD.txt
        chown $ACTUAL_USER:$ACTUAL_USER /opt/stacks/core/authelia/ADMIN_PASSWORD.txt
        log_info "Password also saved to: /opt/stacks/core/authelia/ADMIN_PASSWORD.txt"
        echo ""
        
        # Clean up credentials file
        rm -f /tmp/authelia_admin_credentials.tmp
    else
        log_warning "Incomplete credentials from setup script"
        log_info "Using template users_database.yml - please configure manually"
    fi
else
    log_warning "No credentials file found from setup script"
    log_info "Using template users_database.yml from config-templates"
    log_info "Please run setup-homelab.sh first or configure manually"
fi

# Clean up old Authelia database if encryption key changed
# This prevents "encryption key does not appear to be valid" errors
if [ -d "/var/lib/docker/volumes/core_authelia-data/_data" ]; then
    log_info "Checking for existing Authelia database..."
    # Check if database exists and might have encryption key mismatch
    if [ -f "/var/lib/docker/volumes/core_authelia-data/_data/db.sqlite3" ]; then
        log_warning "Existing Authelia database found from previous deployment"
        log_info "If deployment fails with encryption key errors, run: sudo ./scripts/reset-test-environment.sh"
    fi
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
log_info "Step 4/6: Deploying infrastructure stack..."
log_info "  - Dockge (Docker Compose Manager)"
log_info "  - Pi-hole (DNS Ad Blocker)"
log_info "  - Dozzle (Log Viewer)"
log_info "  - Glances (System Monitor)"
log_info "  - Docker Proxy (Security)"
log_info "  Note: Watchtower temporarily disabled (Docker API compatibility)"
echo ""

# Copy infrastructure stack
cp "$REPO_DIR/docker-compose/infrastructure.yml" /opt/stacks/infrastructure/docker-compose.yml
cp "$REPO_DIR/.env" /opt/stacks/infrastructure/.env

# Deploy infrastructure stack
cd /opt/stacks/infrastructure
docker compose up -d

log_success "Infrastructure stack deployed"
echo ""

# Step 5: Deploy dashboards stack (Homepage and Homarr)
log_info "Step 5/6: Deploying dashboards stack..."
log_info "  - Homepage (AI-configurable Dashboard)"
log_info "  - Homarr (Modern Dashboard)"
echo ""

# Copy dashboards stack
mkdir -p /opt/stacks/dashboards
cp "$REPO_DIR/docker-compose/dashboards.yml" /opt/stacks/dashboards/docker-compose.yml
cp "$REPO_DIR/.env" /opt/stacks/dashboards/.env

# Copy and configure homepage templates
if [ -d "$REPO_DIR/config-templates/homepage" ]; then
    cp -r "$REPO_DIR/config-templates/homepage" /opt/stacks/dashboards/
    
    # Replace HOMEPAGE_VAR_DOMAIN with actual domain in all homepage config files
    # Homepage doesn't support environment variables in configs
    find /opt/stacks/dashboards/homepage -type f \( -name "*.yaml" -o -name "*.yml" \) -exec sed -i "s/{{HOMEPAGE_VAR_DOMAIN}}/${DOMAIN}/g" {} \;
    
    log_info "Homepage configuration templates copied and configured"
fi

# Deploy dashboards stack
cd /opt/stacks/dashboards
docker compose up -d

log_success "Dashboards stack deployed"
echo ""

# Step 6: Deploy additional stacks to Dockge (not started)
log_info "Step 6/7: Preparing additional stacks for Dockge..."
echo ""
log_info "The following stacks can be deployed through Dockge's web UI:"
log_info "  - media.yml (Plex, Jellyfin, Sonarr, Radarr, etc.)"
log_info "  - media-extended.yml (Readarr, Lidarr, etc.)"
log_info "  - homeassistant.yml (Home Assistant and accessories)"
log_info "  - productivity.yml (Nextcloud, Gitea, wikis)"
log_info "  - monitoring.yml (Grafana, Prometheus, etc.)"
log_info "  - utilities.yml (Backups, code editors, etc.)"
log_info "  - alternatives.yml (Portainer, Authentik)"
echo ""

# Ask user if they want to pre-pull images for additional stacks
read -p "Pre-pull Docker images for additional stacks? This will take time but speeds up first deployment (y/N): " PULL_IMAGES
PULL_IMAGES=${PULL_IMAGES:-n}

# Copy additional stacks to Dockge directory
ADDITIONAL_STACKS=("media" "media-extended" "homeassistant" "productivity" "monitoring" "utilities" "alternatives")

for stack in "${ADDITIONAL_STACKS[@]}"; do
    mkdir -p "/opt/stacks/$stack"
    cp "$REPO_DIR/docker-compose/${stack}.yml" "/opt/stacks/$stack/docker-compose.yml"
    cp "$REPO_DIR/.env" "/opt/stacks/$stack/.env"
    
    # Pre-pull images if requested
    if [[ "$PULL_IMAGES" =~ ^[Yy]$ ]]; then
        log_info "Pulling images for $stack stack..."
        cd "/opt/stacks/$stack"
        docker compose pull 2>&1 | grep -E '(Pulling|Downloaded|Already exists|up to date)' || true
    fi
done

log_success "Additional stacks prepared in Dockge"
log_info "These stacks are NOT started - deploy them via Dockge web UI as needed"
echo ""

# Step 7: Wait for Dockge to be ready and open browser
log_info "Step 7/7: Waiting for Dockge web UI to be ready..."

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
log_info "SSL Certificates:"
echo "  📝 Let's Encrypt certificates will be acquired automatically within 2-5 minutes"
echo "  ⚠️  Initial access uses self-signed certs (browser warning is normal)"
echo "  🔓 Ensure ports 80/443 are accessible from internet for Let's Encrypt"
echo "  💾 Admin password saved to: /opt/stacks/core/authelia/ADMIN_PASSWORD.txt"
echo ""
log_info "Next steps:"
echo ""
echo "  1. Log in to Dockge using your Authelia credentials"
echo "     Username: admin"
echo "     Password: (saved in /opt/stacks/core/authelia/ADMIN_PASSWORD.txt)"
echo ""
echo "  2. Deploy additional stacks through Dockge's web UI:"
echo "     - media.yml (Plex, Jellyfin, Sonarr, Radarr, etc.)"
echo "     - media-extended.yml (Readarr, Lidarr, etc.)"
echo "     - homeassistant.yml (Home Assistant and accessories)"
echo "     - productivity.yml (Nextcloud, Gitea, wikis)"
echo "     - monitoring.yml (Grafana, Prometheus, etc.)"
echo "     - utilities.yml (Backups, code editors, etc.)"
echo "     - alternatives.yml (Portainer, Authentik - optional)"
echo ""
echo "  3. Access your dashboards:"
echo "     \ud83c\udfe0 Homepage: https://home.${DOMAIN}"
echo "     \ud83d\udcca Homarr:   https://homarr.${DOMAIN}"
echo ""
echo "  4. Configure services via the AI assistant in VS Code"
echo ""
echo "=========================================="
echo ""
log_info "For documentation, see: $REPO_DIR/docs/"
log_info "For troubleshooting, see: $REPO_DIR/docs/quick-reference.md"
echo ""
