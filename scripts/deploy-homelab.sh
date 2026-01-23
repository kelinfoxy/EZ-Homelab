#!/bin/bash
# EZ-Homelab Deployment Script
# This script deploys homelab services with flexible options
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

# Get script directory (EZ-Homelab/scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

log_info "EZ-Homelab Deployment Script"
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

# Deployment options menu
echo "=========================================="
echo "        EZ-HOMELAB DEPLOYMENT OPTIONS"
echo "=========================================="
echo ""
echo "Choose your deployment scenario:"
echo ""
echo "1) Full deployment (recommended for new servers)"
echo "   - Deploy core infrastructure (Traefik, Authelia, etc.)"
echo "   - Deploy infrastructure stack (Dockge, Pi-hole, etc.)"
echo "   - Deploy dashboards (Homepage, Homarr)"
echo "   - Setup all remaining stacks for Dockge"
echo ""
echo "2) Skip core stack (for existing homelab servers)"
echo "   - Skip core infrastructure deployment"
echo "   - Deploy infrastructure stack (Dockge, Pi-hole, etc.)"
echo "   - Deploy dashboards (Homepage, Homarr)"
echo "   - Setup all remaining stacks for Dockge"
echo ""
echo "3) Setup stacks only (no deployment)"
echo "   - Setup all stacks in Dockge without deploying any"
echo "   - Useful for preparing stacks for manual deployment"
echo ""
read -p "Enter your choice (1-3): " DEPLOY_CHOICE

case $DEPLOY_CHOICE in
    1)
        DEPLOY_CORE=true
        DEPLOY_INFRASTRUCTURE=true
        DEPLOY_DASHBOARDS=true
        SETUP_STACKS=true
        log_info "Selected: Full deployment"
        ;;
    2)
        DEPLOY_CORE=false
        DEPLOY_INFRASTRUCTURE=true
        DEPLOY_DASHBOARDS=true
        SETUP_STACKS=true
        log_info "Selected: Skip core stack"
        ;;
    3)
        DEPLOY_CORE=false
        DEPLOY_INFRASTRUCTURE=false
        DEPLOY_DASHBOARDS=false
        SETUP_STACKS=true
        log_info "Selected: Setup stacks only"
        ;;
    *)
        log_error "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""

# Function to setup stacks without deploying them
setup_stacks_for_dockge() {
    log_info "Setting up all stacks for Dockge..."
    
    # List of stacks to setup
    STACKS=("vpn" "media" "media-management" "monitoring" "productivity" "utilities" "alternatives" "homeassistant" "nextcloud")
    
    for stack in "${STACKS[@]}"; do
        STACK_DIR="/opt/stacks/$stack"
        REPO_STACK_DIR="$REPO_DIR/docker-compose/$stack"
        
        if [ -d "$REPO_STACK_DIR" ]; then
            log_info "Setting up $stack stack..."
            
            # Create stack directory
            mkdir -p "$STACK_DIR"
            
            # Copy docker-compose.yml
            if [ -f "$REPO_STACK_DIR/docker-compose.yml" ]; then
                cp "$REPO_STACK_DIR/docker-compose.yml" "$STACK_DIR/"
                cp "$REPO_DIR/.env" "$STACK_DIR/.env"
                
                # Copy any additional config directories
                for config_dir in "$REPO_STACK_DIR"/*/; do
                    if [ -d "$config_dir" ] && [ "$(basename "$config_dir")" != "." ]; then
                        cp -r "$config_dir" "$STACK_DIR/"
                    fi
                done
                
                log_success "$stack stack prepared for Dockge"
            else
                log_warning "$stack stack docker-compose.yml not found, skipping..."
            fi
        else
            log_warning "$stack stack directory not found in repo, skipping..."
        fi
    done
    
    log_success "All stacks prepared for Dockge deployment"
    echo ""
}

# Step 1: Create required directories
log_info "Step 1: Creating required directories..."
mkdir -p /opt/stacks/core
mkdir -p /opt/stacks/infrastructure
mkdir -p /opt/dockge/data
log_success "Directories created"
echo ""

# Step 2: Create Docker networks (if they don't exist)
log_info "Step 2: Creating Docker networks..."
docker network create homelab-network 2>/dev/null && log_success "Created homelab-network" || log_info "homelab-network already exists"
docker network create traefik-network 2>/dev/null && log_success "Created traefik-network" || log_info "traefik-network already exists"
docker network create media-network 2>/dev/null && log_success "Created media-network" || log_info "media-network already exists"
echo ""

# Step 3: Deploy core infrastructure (DuckDNS, Traefik, Authelia, Gluetun)
if [ "$DEPLOY_CORE" = true ]; then
    log_info "Step 3: Deploying core infrastructure stack..."
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
    cp "$REPO_DIR/docker-compose/core/docker-compose.yml" /opt/stacks/core/docker-compose.yml

    if [ -d "/opt/stacks/core/traefik" ]; then
        log_warning "Traefik configuration already exists in /opt/stacks/core/"
        log_info "Creating backup: traefik.backup.$(date +%Y%m%d_%H%M%S)"
        mv /opt/stacks/core/traefik /opt/stacks/core/traefik.backup.$(date +%Y%m%d_%H%M%S)
    fi
    cp -r "$REPO_DIR/config-templates/traefik" /opt/stacks/core/

    # Detect server hostname and update configuration
    log_info "Detecting server hostname..."
    DETECTED_HOSTNAME=$(hostname)
    if [ -n "$DETECTED_HOSTNAME" ] && [ "$DETECTED_HOSTNAME" != "debian" ]; then
        log_info "Detected hostname: $DETECTED_HOSTNAME"
        # Update SERVER_HOSTNAME in the copied .env file
        sed -i "s/SERVER_HOSTNAME=.*/SERVER_HOSTNAME=$DETECTED_HOSTNAME/" /opt/stacks/core/.env
        # Update SERVER_HOSTNAME in the source .env file for future deployments
        sed -i "s/SERVER_HOSTNAME=.*/SERVER_HOSTNAME=$DETECTED_HOSTNAME/" "$REPO_DIR/.env"
        # Update sablier.yml with detected hostname
        sed -i "s/debian-/$DETECTED_HOSTNAME-/g" /opt/stacks/core/traefik/dynamic/sablier.yml
        log_success "Updated configuration with detected hostname: $DETECTED_HOSTNAME"
    else
        log_info "Using default hostname 'debian' (hostname detection failed or returned default)"
    fi
    echo ""

    if [ -d "/opt/stacks/core/authelia" ]; then
        log_warning "Authelia configuration already exists in /opt/stacks/core/"
        log_info "Creating backup: authelia.backup.$(date +%Y%m%d_%H%M%S)"
        mv /opt/stacks/core/authelia /opt/stacks/core/authelia.backup.$(date +%Y%m%d_%H%M%S)
    fi
    cp -r "$REPO_DIR/config-templates/authelia" /opt/stacks/core/

    # Replace domain placeholders in Authelia config
    sed -i "s/your-domain.duckdns.org/${DOMAIN}/g" /opt/stacks/core/authelia/configuration.yml

    if [ -f "/opt/stacks/core/.env" ]; then
        log_warning ".env already exists in /opt/stacks/core/"
        log_info "Creating backup: .env.backup.$(date +%Y%m%d_%H%M%S)"
        cp /opt/stacks/core/.env /opt/stacks/core/.env.backup.$(date +%Y%m%d_%H%M%S)
    fi
    cp "$REPO_DIR/.env" /opt/stacks/core/.env

    # Replace secret placeholders in Authelia config
    source /opt/stacks/core/.env
    sed -i "s|\${AUTHELIA_JWT_SECRET}|${AUTHELIA_JWT_SECRET}|g" /opt/stacks/core/authelia/configuration.yml
    sed -i "s|\${AUTHELIA_SESSION_SECRET}|${AUTHELIA_SESSION_SECRET}|g" /opt/stacks/core/authelia/configuration.yml
    sed -i "s|\${AUTHELIA_STORAGE_ENCRYPTION_KEY}|${AUTHELIA_STORAGE_ENCRYPTION_KEY}|g" /opt/stacks/core/authelia/configuration.yml

    # Replace placeholders in Authelia users database
    sed -i "s/admin/${AUTHELIA_ADMIN_USER}/g" /opt/stacks/core/authelia/users_database.yml
    sed -i "s/admin@example.com/${AUTHELIA_ADMIN_EMAIL}/g" /opt/stacks/core/authelia/users_database.yml
    sed -i "s|\$argon2id\$v=19\$m=65536,t=3,p=4\$CHANGEME|${AUTHELIA_ADMIN_PASSWORD}|g" /opt/stacks/core/authelia/users_database.yml

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
else
    log_info "Skipping core infrastructure deployment"
    echo ""
fi

# Step 4: Deploy infrastructure stack (Dockge and monitoring tools)
if [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
    log_info "Step 4: Deploying infrastructure stack..."
    log_info "  - Dockge (Docker Compose Manager)"
    log_info "  - Pi-hole (DNS Ad Blocker)"
    log_info "  - Watchtower (Container Updates)"
    log_info "  - Dozzle (Log Viewer)"
    log_info "  - Glances (System Monitor)"
    log_info "  - Docker Proxy (Security)"
    echo ""

    # Copy infrastructure stack
    cp "$REPO_DIR/docker-compose/infrastructure/docker-compose.yml" /opt/stacks/infrastructure/docker-compose.yml
    cp "$REPO_DIR/.env" /opt/stacks/infrastructure/.env

    # Deploy infrastructure stack
    cd /opt/stacks/infrastructure
    docker compose up -d

    log_success "Infrastructure stack deployed"
    echo ""
else
    log_info "Skipping infrastructure stack deployment"
    echo ""
fi

# Step 5: Deploy dashboard stack
if [ "$DEPLOY_DASHBOARDS" = true ]; then
    log_info "Step 5: Deploying dashboard stack..."
    log_info "  - Homepage (Application Dashboard)"
    log_info "  - Homarr (Modern Dashboard)"
    echo ""

    # Create dashboards directory
    mkdir -p /opt/stacks/dashboards

    # Copy dashboards compose file
    cp "$REPO_DIR/docker-compose/dashboards/docker-compose.yml" /opt/stacks/dashboards/docker-compose.yml
    cp "$REPO_DIR/.env" /opt/stacks/dashboards/.env

    # Copy homepage config
    if [ -d "$REPO_DIR/docker-compose/dashboards/homepage" ]; then
        cp -r "$REPO_DIR/docker-compose/dashboards/homepage" /opt/stacks/dashboards/
    fi

    # Deploy dashboards stack
    cd /opt/stacks/dashboards
    docker compose up -d

    log_success "Dashboard stack deployed"
    echo ""
else
    log_info "Skipping dashboard stack deployment"
    echo ""
fi

# Step 6: Deploy Dokuwiki
log_info "Step 6: Deploying Dokuwiki wiki platform..."
log_info "  - DokuWiki (File-based wiki with pre-configured content)"
echo ""

# Create Dokuwiki directory
mkdir -p /opt/stacks/dokuwiki/config

# Copy Dokuwiki compose file
cp "$REPO_DIR/config-templates/dokuwiki/docker-compose.yml" /opt/stacks/dokuwiki/docker-compose.yml

# Copy pre-configured Dokuwiki config, content, and keys
if [ -d "$REPO_DIR/config-templates/dokuwiki/conf" ]; then
    cp -r "$REPO_DIR/config-templates/dokuwiki/conf" /opt/stacks/dokuwiki/config/
else
    log_warning "Dokuwiki conf directory not found, skipping..."
fi

if [ -d "$REPO_DIR/config-templates/dokuwiki/data" ]; then
    cp -r "$REPO_DIR/config-templates/dokuwiki/data" /opt/stacks/dokuwiki/config/
else
    log_warning "Dokuwiki data directory not found, skipping..."
fi

if [ -d "$REPO_DIR/config-templates/dokuwiki/keys" ]; then
    cp -r "$REPO_DIR/config-templates/dokuwiki/keys" /opt/stacks/dokuwiki/config/
else
    log_warning "Dokuwiki keys directory not found, skipping..."
fi

# Set proper ownership for Dokuwiki config
sudo chown -R 1000:1000 /opt/stacks/dokuwiki/config

# Deploy Dokuwiki
cd /opt/stacks/dokuwiki
docker compose up -d

log_success "Dokuwiki deployed with pre-configured content"
echo ""

# Step 7: Setup stacks for Dockge (if requested)
if [ "$SETUP_STACKS" = true ]; then
    setup_stacks_for_dockge
fi

# Deployment completed
echo ""
echo "=========================================="
log_success "Deployment completed successfully!"
echo "=========================================="
echo ""
log_info "Access your services:"
echo ""
echo "  🚀 Dockge:   $DOCKGE_URL"
echo "  📊 Homepage: https://home.${DOMAIN}"
echo "  🎯 Homarr:   https://homarr.${DOMAIN}"
echo "  📖 Wiki:     https://wiki.${DOMAIN}"
echo "  🔒 Authelia: https://auth.${DOMAIN}"
echo "  🔀 Traefik:  https://traefik.${DOMAIN}"
echo ""
log_info "Next steps:"
echo ""
echo "  1. Log in to Dockge using your Authelia credentials"
echo "     (configured in /opt/stacks/core/authelia/users_database.yml)"
echo ""
echo "  2. Access your dashboards:"
echo "     - Homepage: https://home.${DOMAIN} (AI-configurable dashboard)"
echo "     - Homarr: https://homarr.${DOMAIN} (Modern dashboard)"
echo ""
echo "  3. Access your pre-deployed Dokuwiki at https://wiki.${DOMAIN}"
echo "     (admin/admin credentials)"
echo ""
echo "  4. Deploy additional stacks through Dockge's web UI:"
echo "     - media.yml (Plex, Jellyfin, Sonarr, Radarr, etc.)"
echo "     - media-extended.yml (Readarr, Lidarr, etc.)"
echo "     - homeassistant.yml (Home Assistant and accessories)"
echo "     - productivity.yml (Nextcloud, Gitea, additional wikis)"
echo "     - monitoring.yml (Grafana, Prometheus, etc.)"
echo "     - utilities.yml (Backups, code editors, etc.)"
echo ""
echo "  5. Configure services via the AI assistant in VS Code"
echo ""
echo "=========================================="
echo ""
log_info "For documentation, see: $REPO_DIR/docs/"
log_info "For troubleshooting, see: $REPO_DIR/docs/quick-reference.md"
echo ""
