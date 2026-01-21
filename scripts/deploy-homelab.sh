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
if [ "$EUID" -eq 0 ]; then 
    log_error "Please do NOT run this script as root or with sudo"
    log_info "Run as: ./deploy-homelab.sh"
    exit 1
fi

# Get script directory (AI-Homelab/scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

log_info "AI-Homelab Deployment Script"
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
docker network create media-network 2>/dev/null && log_success "Created media-network" || log_info "media-network already exists"
echo ""

# Step 3: Deploy core infrastructure (DuckDNS, Traefik, Authelia, Gluetun)
log_info "Step 3/5: Deploying core infrastructure stack..."
log_info "  - DuckDNS (Dynamic DNS)"
log_info "  - Traefik (Reverse Proxy with SSL)"
log_info "  - Authelia (Single Sign-On)"
log_info "  - Gluetun (VPN Client)"
echo ""

# Copy core stack files with overwrite checks
if [ -f "/opt/stacks/core/docker-compose.yml" ]; then
    log_warning "docker-compose.yml already exists in /opt/stacks/core/"
    log_info "Creating backup: docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)"
    cp /opt/stacks/core/docker-compose.yml /opt/stacks/core/docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
fi
cp "$REPO_DIR/docker-compose/core.yml" /opt/stacks/core/docker-compose.yml

if [ -d "/opt/stacks/core/traefik" ]; then
    log_warning "Traefik configuration already exists in /opt/stacks/core/"
    log_info "Creating backup: traefik.backup.$(date +%Y%m%d_%H%M%S)"
    mv /opt/stacks/core/traefik /opt/stacks/core/traefik.backup.$(date +%Y%m%d_%H%M%S)
fi
cp -r "$REPO_DIR/config-templates/traefik" /opt/stacks/core/

if [ -d "/opt/stacks/core/authelia" ]; then
    log_warning "Authelia configuration already exists in /opt/stacks/core/"
    log_info "Creating backup: authelia.backup.$(date +%Y%m%d_%H%M%S)"
    mv /opt/stacks/core/authelia /opt/stacks/core/authelia.backup.$(date +%Y%m%d_%H%M%S)
fi
cp -r "$REPO_DIR/config-templates/authelia" /opt/stacks/core/

if [ -f "/opt/stacks/core/.env" ]; then
    log_warning ".env already exists in /opt/stacks/core/"
    log_info "Creating backup: .env.backup.$(date +%Y%m%d_%H%M%S)"
    cp /opt/stacks/core/.env /opt/stacks/core/.env.backup.$(date +%Y%m%d_%H%M%S)
fi
cp "$REPO_DIR/.env" /opt/stacks/core/.env

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
log_info "  - Portainer (Alternative Docker UI)"
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

# Step 5: Deploy Dokuwiki
log_info "Step 5/6: Deploying Dokuwiki wiki platform..."
log_info "  - DokuWiki (File-based wiki with pre-configured content)"
echo ""

# Create Dokuwiki directory
mkdir -p /opt/stacks/dokuwiki/config

# Copy Dokuwiki compose file
cp "$REPO_DIR/config-templates/dokuwiki/docker-compose.yml" /opt/stacks/dokuwiki/docker-compose.yml

# Copy pre-configured Dokuwiki config, content, and keys
cp -r "$REPO_DIR/config-templates/dokuwiki/conf" /opt/stacks/dokuwiki/config/
cp -r "$REPO_DIR/config-templates/dokuwiki/data" /opt/stacks/dokuwiki/config/
cp -r "$REPO_DIR/config-templates/dokuwiki/keys" /opt/stacks/dokuwiki/config/

# Set proper ownership for Dokuwiki config
sudo chown -R 1000:1000 /opt/stacks/dokuwiki/config

# Deploy Dokuwiki
cd /opt/stacks/dokuwiki
docker compose up -d

log_success "Dokuwiki deployed with pre-configured content"
echo ""

# Step 6: Wait for Dockge to be ready and open browser
log_info "Step 6/6: Waiting for Dockge web UI to be ready..."

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
echo "  � Wiki:     https://wiki.${DOMAIN}"
echo "  �🔒 Authelia: https://auth.${DOMAIN}"
echo "  🔀 Traefik:  https://traefik.${DOMAIN}"
echo ""
log_info "Next steps:"
echo ""
echo "  1. Log in to Dockge using your Authelia credentials"
echo "     (configured in /opt/stacks/core/authelia/users_database.yml)"
echo ""
echo "  2. Access your pre-deployed Dokuwiki at https://wiki.${DOMAIN}"
echo "     (admin/admin credentials)"
echo ""
echo "  3. Deploy additional stacks through Dockge's web UI:"
echo "     - dashboards.yml (Homepage, Homarr)"
echo "     - media.yml (Plex, Jellyfin, Sonarr, Radarr, etc.)"
echo "     - media-extended.yml (Readarr, Lidarr, etc.)"
echo "     - homeassistant.yml (Home Assistant and accessories)"
echo "     - productivity.yml (Nextcloud, Gitea, additional wikis)"
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
