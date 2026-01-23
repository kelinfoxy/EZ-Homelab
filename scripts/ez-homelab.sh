#!/bin/bash
# EZ-Homelab Unified Setup & Deployment Script
# This script provides a guided setup and deployment experience
# Run as: ./ez-homelab.sh (will use sudo when needed)

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

# Get script directory and repo directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Default values
DOMAIN=""
SERVER_IP=""
ADMIN_USER=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
DEPLOY_CORE=false
DEPLOY_INFRASTRUCTURE=false
DEPLOY_DASHBOARDS=false
SETUP_STACKS=false

# Load existing .env file if it exists
load_env_file() {
    if [ -f "$REPO_DIR/.env" ]; then
        log_info "Found existing .env file, loading current configuration..."
        source "$REPO_DIR/.env"

        # Show current values
        echo ""
        echo "Current configuration:"
        echo "  Domain: ${DOMAIN:-Not set}"
        echo "  Server IP: ${SERVER_IP:-Not set}"
        echo "  Server Hostname: ${SERVER_HOSTNAME:-Not set}"
        echo "  Admin User: ${AUTHELIA_ADMIN_USER:-Not set}"
        echo "  Admin Email: ${AUTHELIA_ADMIN_EMAIL:-Not set}"
        echo "  Timezone: ${TZ:-Not set}"
        echo ""

        return 0
    else
        log_info "No existing .env file found. We'll create one during setup."
        return 1
    fi
}

# Save configuration to .env file
save_env_file() {
    log_info "Saving configuration to .env file..."

    # Create .env file if it doesn't exist
    if [ ! -f "$REPO_DIR/.env" ]; then
        cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
    fi

    # Update values
    sed -i "s%DOMAIN=.*%DOMAIN=$DOMAIN%" "$REPO_DIR/.env"
    sed -i "s%SERVER_IP=.*%SERVER_IP=$SERVER_IP%" "$REPO_DIR/.env"
    sed -i "s%SERVER_HOSTNAME=.*%SERVER_HOSTNAME=$SERVER_HOSTNAME%" "$REPO_DIR/.env"
    sed -i "s%TZ=.*%TZ=$TZ%" "$REPO_DIR/.env"

    # Authelia settings (only if deploying core)
    if [ "$DEPLOY_CORE" = true ]; then
        # Ensure we have admin credentials
        if [ -z "$ADMIN_USER" ]; then
            ADMIN_USER="admin"
        fi
        if [ -z "$ADMIN_EMAIL" ]; then
            ADMIN_EMAIL="${ADMIN_USER}@${DOMAIN}"
        fi
        if [ -z "$ADMIN_PASSWORD" ]; then
            log_info "Using default admin password (changeme123) - please change this after setup!"
            ADMIN_PASSWORD="changeme123"
        fi

        if [ -z "$AUTHELIA_JWT_SECRET" ]; then
            AUTHELIA_JWT_SECRET=$(openssl rand -hex 64)
        fi
        if [ -z "$AUTHELIA_SESSION_SECRET" ]; then
            AUTHELIA_SESSION_SECRET=$(openssl rand -hex 64)
        fi
        if [ -z "$AUTHELIA_STORAGE_ENCRYPTION_KEY" ]; then
            AUTHELIA_STORAGE_ENCRYPTION_KEY=$(openssl rand -hex 64)
        fi

        # Save Authelia settings to .env
        sed -i "s%AUTHELIA_JWT_SECRET=.*%AUTHELIA_JWT_SECRET=$AUTHELIA_JWT_SECRET%" "$REPO_DIR/.env"
        sed -i "s%AUTHELIA_SESSION_SECRET=.*%AUTHELIA_SESSION_SECRET=$AUTHELIA_SESSION_SECRET%" "$REPO_DIR/.env"
        sed -i "s%AUTHELIA_STORAGE_ENCRYPTION_KEY=.*%AUTHELIA_STORAGE_ENCRYPTION_KEY=$AUTHELIA_STORAGE_ENCRYPTION_KEY%" "$REPO_DIR/.env"
        sed -i "s%# AUTHELIA_ADMIN_USER=.*%AUTHELIA_ADMIN_USER=$ADMIN_USER%" "$REPO_DIR/.env"
        sed -i "s%# AUTHELIA_ADMIN_EMAIL=.*%AUTHELIA_ADMIN_EMAIL=$ADMIN_EMAIL%" "$REPO_DIR/.env"

        # Generate password hash if needed
        if [ -z "$AUTHELIA_ADMIN_PASSWORD" ]; then
            log_info "Generating Authelia password hash..."
            # Pull Authelia image if needed
            if ! docker images | grep -q authelia/authelia; then
                docker pull authelia/authelia:latest > /dev/null 2>&1
            fi
            AUTHELIA_ADMIN_PASSWORD=$(docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password "$ADMIN_PASSWORD" 2>&1 | grep -o '\$argon2id.*')
            if [ -z "$AUTHELIA_ADMIN_PASSWORD" ]; then
                log_error "Failed to generate Authelia password hash. Please check that ADMIN_PASSWORD is set."
                exit 1
            fi
        fi

        # Save password hash
        sed -i "s%# AUTHELIA_ADMIN_PASSWORD=.*%AUTHELIA_ADMIN_PASSWORD=$AUTHELIA_ADMIN_PASSWORD%" "$REPO_DIR/.env"
        sed -i "s%AUTHELIA_ADMIN_PASSWORD=.*%AUTHELIA_ADMIN_PASSWORD=$AUTHELIA_ADMIN_PASSWORD%" "$REPO_DIR/.env"
    fi

    log_success "Configuration saved to .env file"
}

# Prompt for required values
prompt_for_values() {
    echo ""
    log_info "Please provide the following information:"
    echo "  (Press Enter without typing to keep the current/default value shown in brackets)"
    echo ""

    # Domain
    if [ -z "$DOMAIN" ]; then
        read -p "Enter your domain (e.g., example.duckdns.org): " DOMAIN
        while [ -z "$DOMAIN" ]; do
            log_warning "Domain is required"
            read -p "Enter your domain (e.g., example.duckdns.org): " DOMAIN
        done
    else
        read -p "Domain [$DOMAIN] (press Enter to keep current): " input
        [ -n "$input" ] && DOMAIN="$input"
    fi

    # Server IP
    if [ -z "$SERVER_IP" ]; then
        read -p "Enter your server IP address: " SERVER_IP
        while [ -z "$SERVER_IP" ]; do
            log_warning "Server IP is required"
            read -p "Enter your server IP address: " SERVER_IP
        done
    else
        read -p "Server IP [$SERVER_IP] (press Enter to keep current): " input
        [ -n "$input" ] && SERVER_IP="$input"
    fi

    # Server Hostname
    if [ -z "$SERVER_HOSTNAME" ]; then
        SERVER_HOSTNAME="debian"
    fi
    read -p "Server hostname [$SERVER_HOSTNAME] (press Enter to keep current): " input
    [ -n "$input" ] && SERVER_HOSTNAME="$input"

    # Timezone
    if [ -z "$TZ" ]; then
        TZ="America/New_York"
    fi
    read -p "Timezone [$TZ] (press Enter to keep current): " input
    [ -n "$input" ] && TZ="$input"

    # Admin credentials (only if deploying core)
    if [ "$DEPLOY_CORE" = true ]; then
        echo ""
        log_info "Authelia Admin Credentials:"

        if [ -z "$ADMIN_USER" ]; then
            ADMIN_USER="admin"
        fi
        read -p "Admin username [$ADMIN_USER] (press Enter to keep current): " input
        [ -n "$input" ] && ADMIN_USER="$input"

        if [ -z "$ADMIN_EMAIL" ]; then
            ADMIN_EMAIL="${ADMIN_USER}@${DOMAIN}"
        fi
        read -p "Admin email [$ADMIN_EMAIL] (press Enter to keep current): " input
        [ -n "$input" ] && ADMIN_EMAIL="$input"

        if [ -z "$ADMIN_PASSWORD" ]; then
            while [ -z "$ADMIN_PASSWORD" ]; do
                read -s -p "Admin password (will be hashed): " ADMIN_PASSWORD
                echo ""
                if [ ${#ADMIN_PASSWORD} -lt 8 ]; then
                    log_warning "Password must be at least 8 characters"
                    ADMIN_PASSWORD=""
                fi
            done
        else
            log_info "Admin password already configured"
        fi
    fi

    echo ""
}

# System setup function (Docker, directories, etc.)
system_setup() {
    log_info "Performing system setup..."

    # Check if running as root for system setup
    if [ "$EUID" -ne 0 ]; then
        log_warning "System setup requires root privileges. Running with sudo..."
        exec sudo "$0" "$@"
    fi

    # Get the actual user who invoked sudo
    ACTUAL_USER=${SUDO_USER:-$USER}

    # Step 1: System Update
    log_info "Step 1/10: Updating system packages..."
    apt-get update && apt-get upgrade -y
    log_success "System updated successfully"

    # Step 2: Install required packages
    log_info "Step 2/10: Installing required packages..."
    apt-get install -y curl wget git htop nano vim ufw fail2ban unattended-upgrades apt-listchanges

    # Step 3: Install Docker
    log_info "Step 3/10: Installing Docker..."
    if command -v docker &> /dev/null && docker --version &> /dev/null; then
        log_success "Docker is already installed ($(docker --version))"
        # Check if Docker service is running
        if ! systemctl is-active --quiet docker; then
            log_warning "Docker service is not running, starting it..."
            systemctl start docker
            systemctl enable docker
            log_success "Docker service started and enabled"
        else
            log_info "Docker service is already running"
        fi
    else
        curl -fsSL https://get.docker.com | sh
        usermod -aG docker "$ACTUAL_USER"
    fi

    # Step 4: Install Docker Compose
    log_info "Step 4/10: Installing Docker Compose..."
    if command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
        log_success "Docker Compose is already installed ($(docker-compose --version))"
    else
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        log_success "Docker Compose installed ($(docker-compose --version))"
    fi

    # Step 5: Configure UFW firewall
    log_info "Step 5/10: Configuring firewall..."
    ufw --force enable
    ufw allow ssh
    ufw allow 80
    ufw allow 443

    # Step 6: Configure automatic updates
    log_info "Step 6/10: Configuring automatic updates..."
    dpkg-reconfigure -f noninteractive unattended-upgrades

    # Step 7: Create required directories
    log_info "Step 7/10: Creating required directories..."
    mkdir -p /opt/stacks/core
    mkdir -p /opt/stacks/infrastructure
    mkdir -p /opt/stacks/dashboards
    mkdir -p /opt/dockge

    # Step 8: Set proper ownership
    log_info "Step 8/10: Setting directory ownership..."
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/dockge

    # Step 9: Create Docker networks
    log_info "Step 9/10: Creating Docker networks..."
    docker network create homelab-network 2>/dev/null && log_success "Created homelab-network" || log_info "homelab-network already exists"
    docker network create traefik-network 2>/dev/null && log_success "Created traefik-network" || log_info "traefik-network already exists"
    docker network create media-network 2>/dev/null && log_success "Created media-network" || log_info "media-network already exists"

    # Step 10: Generate SSH keys for Git (optional)
    log_info "Step 10/10: SSH key setup (optional)..."
    if [ ! -f "/home/$ACTUAL_USER/.ssh/id_rsa" ]; then
        log_info "Generating SSH key for $ACTUAL_USER..."
        sudo -u "$ACTUAL_USER" ssh-keygen -t rsa -b 4096 -f "/home/$ACTUAL_USER/.ssh/id_rsa" -N ""
        log_info "SSH public key:"
        cat "/home/$ACTUAL_USER/.ssh/id_rsa.pub"
        echo ""
        log_info "Add this key to your Git provider (GitHub, GitLab, etc.)"
    fi

    log_success "System setup completed!"
    echo ""
    log_info "Please log out and back in for Docker group changes to take effect."
    echo ""
}

# Deployment function
perform_deployment() {
    log_info "Starting deployment..."

    # Switch back to regular user if we were running as root
    if [ "$EUID" -eq 0 ]; then
        ACTUAL_USER=${SUDO_USER:-$USER}
        log_info "Switching to user $ACTUAL_USER for deployment..."
        exec sudo -u "$ACTUAL_USER" "$0" "$@"
    fi

    # Source the .env file
    source "$REPO_DIR/.env"

    # Step 1: Create required directories
    log_info "Step 1: Creating required directories..."
    mkdir -p /opt/stacks/core
    mkdir -p /opt/stacks/infrastructure
    mkdir -p /opt/stacks/dashboards
    mkdir -p /opt/dockge
    log_success "Directories created"

    # Step 2: Create Docker networks (if they don't exist)
    log_info "Step 2: Creating Docker networks..."
    docker network create homelab-network 2>/dev/null && log_success "Created homelab-network" || log_info "homelab-network already exists"
    docker network create traefik-network 2>/dev/null && log_success "Created traefik-network" || log_info "traefik-network already exists"
    docker network create media-network 2>/dev/null && log_success "Created media-network" || log_info "media-network already exists"
    echo ""

    # Step 3: Deploy Dockge (always deployed)
    log_info "Step 3: Deploying Dockge stack manager..."
    log_info "  - Dockge (Docker Compose Manager)"
    echo ""

    # Copy Dockge stack files
    cp "$REPO_DIR/docker-compose/dockge/docker-compose.yml" /opt/dockge/docker-compose.yml
    cp "$REPO_DIR/.env" /opt/dockge/.env

    # Deploy Dockge stack
    cd /opt/dockge
    docker compose up -d
    log_success "Dockge deployed"
    echo ""

    # Deploy core infrastructure
    if [ "$DEPLOY_CORE" = true ]; then
        log_info "Step 4: Deploying core infrastructure stack..."
        log_info "  - DuckDNS (Dynamic DNS)"
        log_info "  - Traefik (Reverse Proxy with SSL)"
        log_info "  - Authelia (Single Sign-On)"
        echo ""

        # Copy core stack files
        cp "$REPO_DIR/docker-compose/core/docker-compose.yml" /opt/stacks/core/docker-compose.yml
        cp "$REPO_DIR/.env" /opt/stacks/core/.env

        # Copy configs
        if [ -d "/opt/stacks/core/traefik" ]; then
            mv /opt/stacks/core/traefik /opt/stacks/core/traefik.backup.$(date +%Y%m%d_%H%M%S)
        fi
        cp -r "$REPO_DIR/config-templates/traefik" /opt/stacks/core/

        # Replace ACME email placeholder
        sed -i "s/ACME_EMAIL_PLACEHOLDER/${AUTHELIA_ADMIN_EMAIL}/g" /opt/stacks/core/traefik/traefik.yml

        # Replace domain placeholders in traefik dynamic configs
        find /opt/stacks/core/traefik/dynamic -name "*.yml" -exec sed -i "s/\${DOMAIN}/${DOMAIN}/g" {} \;
        find /opt/stacks/core/traefik/dynamic -name "*.yml" -exec sed -i "s/\${SERVER_HOSTNAME}/${SERVER_HOSTNAME}/g" {} \;

        if [ -d "/opt/stacks/core/authelia" ]; then
            mv /opt/stacks/core/authelia /opt/stacks/core/authelia.backup.$(date +%Y%m%d_%H%M%S)
        fi
        cp -r "$REPO_DIR/config-templates/authelia" /opt/stacks/core/

        # Replace domain placeholders
        sed -i "s/your-domain.duckdns.org/${DOMAIN}/g" /opt/stacks/core/authelia/configuration.yml
        sed -i "s/\${DOMAIN}/${DOMAIN}/g" /opt/stacks/core/authelia/configuration.yml

        # Replace secret placeholders
        sed -i "s|\${AUTHELIA_JWT_SECRET}|${AUTHELIA_JWT_SECRET}|g" /opt/stacks/core/authelia/configuration.yml
        sed -i "s|\${AUTHELIA_SESSION_SECRET}|${AUTHELIA_SESSION_SECRET}|g" /opt/stacks/core/authelia/configuration.yml
        sed -i "s|\${AUTHELIA_STORAGE_ENCRYPTION_KEY}|${AUTHELIA_STORAGE_ENCRYPTION_KEY}|g" /opt/stacks/core/authelia/configuration.yml
        sed -i "s/admin/${AUTHELIA_ADMIN_USER}/g" /opt/stacks/core/authelia/users_database.yml
        sed -i "s/admin@example.com/${AUTHELIA_ADMIN_EMAIL}/g" /opt/stacks/core/authelia/users_database.yml
        sed -i "s/\${DEFAULT_EMAIL}/${AUTHELIA_ADMIN_EMAIL}/g" /opt/stacks/core/authelia/users_database.yml
        sed -i "s|\$argon2id\$v=19\$m=65536,t=3,p=4\$CHANGEME|${AUTHELIA_ADMIN_PASSWORD}|g" /opt/stacks/core/authelia/users_database.yml

        # Deploy core stack
        cd /opt/stacks/core
        docker compose up -d
        log_success "Core infrastructure deployed"
        echo ""
    fi

    # Deploy infrastructure stack
    if [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
        step_num=$([ "$DEPLOY_CORE" = true ] && echo "5" || echo "4")
        log_info "Step $step_num: Deploying infrastructure stack..."
        log_info "  - Pi-hole (DNS Ad Blocker)"
        log_info "  - Watchtower (Container Updates)"
        log_info "  - Dozzle (Log Viewer)"
        log_info "  - Glances (System Monitor)"
        log_info "  - Docker Proxy (Security)"
        echo ""

        # Copy infrastructure stack
        cp "$REPO_DIR/docker-compose/infrastructure/docker-compose.yml" /opt/stacks/infrastructure/docker-compose.yml
        cp "$REPO_DIR/.env" /opt/stacks/infrastructure/.env

        # If core is not deployed, remove Authelia middleware references
        if [ "$DEPLOY_CORE" = false ]; then
            log_info "Core infrastructure not deployed - removing Authelia middleware references..."
            sed -i '/middlewares=authelia@docker/d' /opt/stacks/infrastructure/docker-compose.yml
        fi

        # Deploy infrastructure stack
        cd /opt/stacks/infrastructure
        docker compose up -d
        log_success "Infrastructure stack deployed"
        echo ""
    fi

    # Deploy dashboard stack
    if [ "$DEPLOY_DASHBOARDS" = true ]; then
        if [ "$DEPLOY_CORE" = true ] && [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
            step_num=6
        elif [ "$DEPLOY_CORE" = true ] || [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
            step_num=5
        else
            step_num=4
        fi
        log_info "Step $step_num: Deploying dashboard stack..."
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
    fi

    # Setup stacks for Dockge
    if [ "$SETUP_STACKS" = true ]; then
        setup_stacks_for_dockge
    fi

    # Deploy Dokuwiki (always deployed as it's part of the base setup)
    deployed_count=3  # Dockge is always deployed
    [ "$DEPLOY_CORE" = true ] && deployed_count=$((deployed_count + 1))
    [ "$DEPLOY_INFRASTRUCTURE" = true ] && deployed_count=$((deployed_count + 1))
    [ "$DEPLOY_DASHBOARDS" = true ] && deployed_count=$((deployed_count + 1))
    step_num=$((deployed_count + 1))
    log_info "Step $step_num: Deploying Dokuwiki wiki platform..."
    log_info "  - DokuWiki (File-based wiki with pre-configured content)"
    echo ""

    # Create Dokuwiki directory
    mkdir -p /opt/stacks/dokuwiki/config

    # Copy Dokuwiki compose file
    cp "$REPO_DIR/config-templates/dokuwiki/docker-compose.yml" /opt/stacks/dokuwiki/docker-compose.yml

    # Replace domain placeholders in Dokuwiki
    sed -i "s/\${DOMAIN}/${DOMAIN}/g" /opt/stacks/dokuwiki/docker-compose.yml

    # Copy pre-configured Dokuwiki config, content, and keys
    if [ -d "$REPO_DIR/config-templates/dokuwiki/conf" ]; then
        cp -r "$REPO_DIR/config-templates/dokuwiki/conf" /opt/stacks/dokuwiki/config/
    fi

    if [ -d "$REPO_DIR/config-templates/dokuwiki/data" ]; then
        cp -r "$REPO_DIR/config-templates/dokuwiki/data" /opt/stacks/dokuwiki/config/
    fi

    if [ -d "$REPO_DIR/config-templates/dokuwiki/keys" ]; then
        cp -r "$REPO_DIR/config-templates/dokuwiki/keys" /opt/stacks/dokuwiki/config/
    fi

    # Set proper ownership for Dokuwiki config
    sudo chown -R 1000:1000 /opt/stacks/dokuwiki/config

    # Deploy Dokuwiki
    cd /opt/stacks/dokuwiki
    docker compose up -d
    log_success "Dokuwiki deployed with pre-configured content"
    echo ""
}

# Setup stacks for Dockge function
setup_stacks_for_dockge() {
    log_info "Setting up all stacks for Dockge..."

    # List of stacks to setup
    STACKS=("vpn" "media" "media-management" "monitoring" "productivity" "utilities" "alternatives" "homeassistant" "nextcloud")

    for stack in "${STACKS[@]}"; do
        STACK_DIR="/opt/stacks/$stack"
        REPO_STACK_DIR="$REPO_DIR/docker-compose/$stack"

        if [ -d "$REPO_STACK_DIR" ]; then
            mkdir -p "$STACK_DIR"
            if [ -f "$REPO_STACK_DIR/docker-compose.yml" ]; then
                cp "$REPO_STACK_DIR/docker-compose.yml" "$STACK_DIR/docker-compose.yml"
                cp "$REPO_DIR/.env" "$STACK_DIR/.env"
                log_success "Prepared $stack stack for Dockge"
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

# Main menu
show_main_menu() {
    echo "=========================================="
    echo "        EZ-HOMELAB SETUP & DEPLOYMENT"
    echo "=========================================="
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "1) 🚀 Default Setup (Recommended)"
    echo "   - Deploy Dockge, core infrastructure, dashboards & monitoring"
    echo "   - All additional stacks prepared for Dockge"
    echo ""
    echo "2) 🏗️  Core Only"
    echo "   - Deploy Dockge and core infrastructure only"
    echo "   - All stacks prepared for Dockge"
    echo ""
    echo "3) 🔧 Infrastructure Only"
    echo "   - Deploy Dockge and monitoring tools"
    echo "   - Requires existing Traefik (from previous setup)"
    echo "   - Services accessible without authentication"
    echo "   - All stacks prepared for Dockge"
    echo ""
    echo "4) ❌ Exit"
    echo ""
}

# Main logic
main() {
    log_info "EZ-Homelab Unified Setup & Deployment Script"
    echo ""

    # Load existing configuration
    ENV_EXISTS=false
    if load_env_file; then
        ENV_EXISTS=true
    fi

    # Show main menu
    show_main_menu
    read -p "Choose an option (1-4): " MAIN_CHOICE

    case $MAIN_CHOICE in
        1)
            log_info "Selected: Default Setup"
            DEPLOY_CORE=true
            DEPLOY_INFRASTRUCTURE=true
            DEPLOY_DASHBOARDS=true
            SETUP_STACKS=true
            ;;
        2)
            log_info "Selected: Core Only"
            DEPLOY_CORE=true
            DEPLOY_INFRASTRUCTURE=false
            DEPLOY_DASHBOARDS=false
            SETUP_STACKS=true
            ;;
        3)
            log_info "Selected: Infrastructure Only"
            DEPLOY_CORE=false
            DEPLOY_INFRASTRUCTURE=true
            DEPLOY_DASHBOARDS=false
            SETUP_STACKS=true
            ;;
        4)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid choice. Please run the script again."
            exit 1
            ;;
    esac

    echo ""

    # Check if system setup is needed
    # Only run system setup if Docker is not installed OR if running as root and Docker setup hasn't been done
    DOCKER_INSTALLED=false
    if command -v docker &> /dev/null && docker --version &> /dev/null; then
        DOCKER_INSTALLED=true
    fi

    # Check if current user is in docker group (or if we're root and will add them)
    USER_IN_DOCKER_GROUP=false
    if groups "$USER" 2>/dev/null | grep -q docker; then
        USER_IN_DOCKER_GROUP=true
    fi

    if [ "$EUID" -eq 0 ]; then
        # Running as root - check if we need to do system setup
        if [ "$DOCKER_INSTALLED" = false ] || [ "$USER_IN_DOCKER_GROUP" = false ]; then
            log_info "Docker not fully installed or user not in docker group. Performing system setup..."
            system_setup "$@"
            echo ""
            log_info "System setup complete. Please log out and back in, then run this script again."
            exit 0
        else
            log_info "Docker is already installed and user is in docker group. Skipping system setup."
        fi
    else
        # Not running as root
        if [ "$DOCKER_INSTALLED" = false ]; then
            log_error "Docker is not installed. Please run this script with sudo to perform system setup."
            exit 1
        fi
        if [ "$USER_IN_DOCKER_GROUP" = false ]; then
            log_error "Current user is not in the docker group. Please log out and back in, or run with sudo to fix group membership."
            exit 1
        fi
    fi

    # Prompt for configuration values
    prompt_for_values

    # Save configuration
    save_env_file

    # Perform deployment
    perform_deployment

    # Show completion message
    echo ""
    echo "=========================================="
    log_success "Setup and deployment completed successfully!"
    echo "=========================================="
    echo ""

    if [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
        log_info "Access your services:"
        echo ""
        echo "  🚀 Dockge:   https://dockge.${DOMAIN}"
        [ "$DEPLOY_CORE" = true ] && echo "  🔒 Authelia: https://auth.${DOMAIN}"
        [ "$DEPLOY_CORE" = true ] && echo "  🔀 Traefik:  https://traefik.${DOMAIN}"
        echo "  📊 Homepage: https://home.${DOMAIN}"
        echo "  🎯 Homarr:   https://homarr.${DOMAIN}"
        echo "  📖 Wiki:     https://wiki.${DOMAIN}"
        echo ""
    fi

    log_info "Next steps:"
    echo ""
    echo "  1. Access Dockge at https://dockge.${DOMAIN}"
    if [ "$DEPLOY_CORE" = true ]; then
        echo "     (Use your Authelia credentials: ${AUTHELIA_ADMIN_USER})"
    fi
    echo ""
    echo "  2. Start additional stacks from Dockge's web UI"
    echo ""
    echo "  3. Configure services via the AI assistant in VS Code"
    echo ""
    echo "=========================================="
    echo ""
    log_info "For documentation, see: $REPO_DIR/docs/"
    log_info "For troubleshooting, see: $REPO_DIR/docs/quick-reference.md"
    echo ""
}

# Run main function
main "$@"