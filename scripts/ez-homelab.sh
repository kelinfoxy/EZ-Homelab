#!/bin/bash
# EZ-Homelab Unified Setup & Deployment Script

# Two step process required for first-time setup:
# Run 'sudo ./ez-homelab.sh' to install Docker and perform system setup
# Run './ez-homelab.sh' to deploy stacks after initial setup
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

# Reusable function to replace environment variable placeholders in files
replace_env_placeholders() {
    local file_path="$1"
    local missing_vars=""

    if [ ! -f "$file_path" ]; then
        log_warning "File $file_path does not exist, skipping placeholder replacement"
        return
    fi

    # Find all ${VAR} patterns in the file
    local vars=$(grep -o '\${[^}]*}' "$file_path" | sed 's/\${//' | sed 's/}//' | sort | uniq)

    for var in $vars; do
        if [ -z "${!var:-}" ]; then
            log_warning "Environment variable $var not found in .env file"
            missing_vars="$missing_vars $var"
        else
            # Replace ${VAR} with the value
            sed -i "s|\${$var}|${!var}|g" "$file_path"
        fi
    done

    # Store missing vars for end-of-script summary
    if [ -n "$missing_vars" ]; then
        MISSING_VARS_SUMMARY="${MISSING_VARS_SUMMARY}${missing_vars}"
    fi
}

# Function to generate shared CA for multi-server TLS
generate_shared_ca() {
    local ca_dir="/opt/stacks/core/shared-ca"
    mkdir -p "$ca_dir"
    openssl genrsa -out "$ca_dir/ca-key.pem" 4096
    openssl req -new -x509 -days 365 -key "$ca_dir/ca-key.pem" -sha256 -out "$ca_dir/ca.pem" -subj "/C=US/ST=State/L=City/O=Homelab/CN=Homelab-CA"
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ca_dir"
    log_success "Shared CA generated"
}

# Function to setup multi-server TLS for remote servers
setup_multi_server_tls() {
    local ca_dir="/opt/stacks/core/shared-ca"
    sudo mkdir -p "$ca_dir"
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" "$ca_dir"

    if [ -n "$CORE_SERVER_IP" ]; then
        log_info "Setting up multi-server TLS using shared CA from core server $CORE_SERVER_IP..."
    else
        # Prompt for core server IP if not set
        read -p "Enter the IP address of your core server: " CORE_SERVER_IP
        while [ -z "$CORE_SERVER_IP" ]; do
            log_warning "Core server IP is required for shared TLS"
            read -p "Enter the IP address of your core server: " CORE_SERVER_IP
        done
        log_info "Setting up multi-server TLS using shared CA from core server $CORE_SERVER_IP..."
    fi

    # Prompt for SSH username if not set
    if [ -z "$SSH_USER" ]; then
        DEFAULT_SSH_USER="${DEFAULT_USER:-$USER}"
        read -p "SSH username for core server [$DEFAULT_SSH_USER]: " SSH_USER
        SSH_USER="${SSH_USER:-$DEFAULT_SSH_USER}"
    fi

    # Test SSH connection - try key authentication first
    log_info "Testing SSH connection to core server ($SSH_USER@$CORE_SERVER_IP)..."
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes "$SSH_USER@$CORE_SERVER_IP" "echo 'SSH connection successful'" 2>/dev/null; then
        log_success "SSH connection established using key authentication"
        USE_SSHPASS=false
    else
        # Key authentication failed, try password authentication
        log_info "Key authentication failed, trying password authentication..."
        read -s -p "Enter SSH password for $SSH_USER@$CORE_SERVER_IP: " SSH_PASSWORD
        echo ""

        if sshpass -p "$SSH_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "echo 'SSH connection successful'" 2>/dev/null; then
            log_success "SSH connection established using password authentication"
            USE_SSHPASS=true
        else
            log_error "Cannot connect to core server via SSH. Please check:"
            echo "  1. SSH is running on the core server"
            echo "  2. SSH keys are properly configured, or username/password are correct"
            echo "  3. The core server IP is correct"
            echo ""
            TLS_ISSUES_SUMMARY="⚠️  TLS Configuration Issue: Cannot connect to core server $CORE_SERVER_IP via SSH
   This will prevent Sablier from connecting to remote Docker daemons.
   
   To fix this:
   1. Ensure SSH is running on the core server
   2. Configure SSH keys or provide correct password
   3. Verify the core server IP is correct
   4. Test SSH connection: ssh $SSH_USER@$CORE_SERVER_IP
   
   Without SSH access, shared CA cannot be fetched for secure multi-server TLS."
            return
        fi
    fi

    # Fetch shared CA certificates from core server
    log_info "Fetching shared CA certificates from core server..."
    SHARED_CA_EXISTS=false

    # Check if shared CA exists on core server (check both old and new locations)
    if [ "$USE_SSHPASS" = true ] && [ -n "$SSH_PASSWORD" ]; then
        if sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "[ -f /opt/stacks/core/shared-ca/ca.pem ] && [ -f /opt/stacks/core/shared-ca/ca-key.pem ] && [ -r /opt/stacks/core/shared-ca/ca.pem ] && [ -r /opt/stacks/core/shared-ca/ca-key.pem ]" 2>/dev/null; then
            SHARED_CA_EXISTS=true
            SHARED_CA_PATH="/opt/stacks/core/shared-ca"
            log_info "Detected CA certificate and key in shared-ca location"
        elif sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "[ -f /opt/stacks/core/docker-tls/ca.pem ] && [ -f /opt/stacks/core/docker-tls/ca-key.pem ] && [ -r /opt/stacks/core/docker-tls/ca.pem ] && [ -r /opt/stacks/core/docker-tls/ca-key.pem ]" 2>/dev/null; then
            SHARED_CA_EXISTS=true
            SHARED_CA_PATH="/opt/stacks/core/docker-tls"
            log_info "Detected CA certificate and key in docker-tls location"
        fi
    else
        if ssh -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "[ -f /opt/stacks/core/shared-ca/ca.pem ] && [ -f /opt/stacks/core/shared-ca/ca-key.pem ] && [ -r /opt/stacks/core/shared-ca/ca.pem ] && [ -r /opt/stacks/core/shared-ca/ca-key.pem ]" 2>/dev/null; then
            SHARED_CA_EXISTS=true
            SHARED_CA_PATH="/opt/stacks/core/shared-ca"
            log_info "Detected CA certificate and key in shared-ca location"
        elif ssh -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "[ -f /opt/stacks/core/docker-tls/ca.pem ] && [ -f /opt/stacks/core/docker-tls/ca-key.pem ] && [ -r /opt/stacks/core/docker-tls/ca.pem ] && [ -r /opt/stacks/core/docker-tls/ca-key.pem ]" 2>/dev/null; then
            SHARED_CA_EXISTS=true
            SHARED_CA_PATH="/opt/stacks/core/docker-tls"
            log_info "Detected CA certificate and key in docker-tls location"
        fi
    fi

    if [ "$SHARED_CA_EXISTS" = true ]; then
        # Copy existing shared CA from core server
        set +e
        scp_output=$(scp -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP:$SHARED_CA_PATH/ca.pem" "$SSH_USER@$CORE_SERVER_IP:$SHARED_CA_PATH/ca-key.pem" "$ca_dir/" 2>&1)
        scp_exit_code=$?
        set -e
        if [ $scp_exit_code -eq 0 ]; then
            log_success "Shared CA certificate and key fetched from core server"
            setup_docker_tls
        else
            log_error "Failed to fetch shared CA certificate and key from core server"
            TLS_ISSUES_SUMMARY="⚠️  TLS Configuration Issue: Could not copy shared CA from core server $CORE_SERVER_IP
   SCP Error: $scp_output
   
   To fix this:
   1. Ensure SSH key authentication works: ssh $ACTUAL_USER@$CORE_SERVER_IP
   2. Verify core server has: $SHARED_CA_PATH/ca.pem and ca-key.pem
   3. Check file permissions on core server: ls -la $SHARED_CA_PATH/
   4. Manually copy CA: scp $ACTUAL_USER@$CORE_SERVER_IP:$SHARED_CA_PATH/ca.pem $ca_dir/
      scp $ACTUAL_USER@$CORE_SERVER_IP:$SHARED_CA_PATH/ca-key.pem $ca_dir/
   5. Regenerate server certificates: run setup_docker_tls after copying
   6. Restart Docker: sudo systemctl restart docker
   
   Then restart Sablier on the core server to reconnect."
            return
        fi
    else
        log_warning "Shared CA certificates not found on core server."
        log_info "Please ensure the core server has been set up first and has generated the shared CA certificates."
        TLS_ISSUES_SUMMARY="⚠️  TLS Configuration Issue: Shared CA certificates not found on core server $CORE_SERVER_IP
   This will prevent Sablier from connecting to remote Docker daemons.
   
   To fix this:
   1. Ensure the core server is set up and has generated shared CA certificates
   2. Verify SSH access: ssh $ACTUAL_USER@$CORE_SERVER_IP
   3. Check core server locations: /opt/stacks/core/shared-ca/ or /opt/stacks/core/docker-tls/
   4. Manually copy CA certificates if needed
   5. Re-run the infrastructure deployment
   
   Without shared CA, remote Docker access will not work securely."
        return
    fi
}

# Get script directory and repo directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Get actual user
if [ "$EUID" -eq 0 ]; then
    ACTUAL_USER=${SUDO_USER:-$USER}
else
    ACTUAL_USER=$USER
fi

# Default values
DOMAIN=""
SERVER_IP=""
CORE_SERVER_IP=""
ADMIN_USER=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
DEPLOY_CORE=false
DEPLOY_INFRASTRUCTURE=false
DEPLOY_DASHBOARDS=false
SETUP_STACKS=false
TLS_ISSUES_SUMMARY=""

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
        echo "  Default User: ${DEFAULT_USER:-Not set}"
        if [ -n "${DEFAULT_PASSWORD:-}" ]; then
            echo "  Default Password: [HIDDEN]"
        else
            echo "  Default Password: Not set"
        fi
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
        sudo -u "$ACTUAL_USER" cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
    fi

    # Update values as the actual user
    sudo -u "$ACTUAL_USER" sed -i "s%DOMAIN=.*%DOMAIN=$DOMAIN%" "$REPO_DIR/.env"
    sudo -u "$ACTUAL_USER" sed -i "s%SERVER_IP=.*%SERVER_IP=$SERVER_IP%" "$REPO_DIR/.env"
    sudo -u "$ACTUAL_USER" sed -i "s%SERVER_HOSTNAME=.*%SERVER_HOSTNAME=$SERVER_HOSTNAME%" "$REPO_DIR/.env"
    sudo -u "$ACTUAL_USER" sed -i "s%TZ=.*%TZ=$TZ%" "$REPO_DIR/.env"

    # Authelia settings (only generate secrets if deploying core)
    if [ "$DEPLOY_CORE" = true ]; then
        # Ensure we have admin credentials
        if [ -z "$ADMIN_USER" ]; then
            ADMIN_USER="${DEFAULT_USER:-admin}"
        fi
        if [ -z "$ADMIN_EMAIL" ]; then
            ADMIN_EMAIL="${DEFAULT_EMAIL:-${ADMIN_USER}@${DOMAIN}}"
        fi
        if [ -z "$ADMIN_PASSWORD" ]; then
            ADMIN_PASSWORD="${DEFAULT_PASSWORD:-changeme123}"
            if [ "$ADMIN_PASSWORD" = "changeme123" ]; then
                log_info "Using default admin password (changeme123) - please change this after setup!"
            fi
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
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_JWT_SECRET=.*%AUTHELIA_JWT_SECRET=$AUTHELIA_JWT_SECRET%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_SESSION_SECRET=.*%AUTHELIA_SESSION_SECRET=$AUTHELIA_SESSION_SECRET%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_STORAGE_ENCRYPTION_KEY=.*%AUTHELIA_STORAGE_ENCRYPTION_KEY=$AUTHELIA_STORAGE_ENCRYPTION_KEY%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%# AUTHELIA_ADMIN_USER=.*%AUTHELIA_ADMIN_USER=$ADMIN_USER%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%# AUTHELIA_ADMIN_EMAIL=.*%AUTHELIA_ADMIN_EMAIL=$ADMIN_EMAIL%" "$REPO_DIR/.env"

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
        sudo -u "$ACTUAL_USER" sed -i "s%# AUTHELIA_ADMIN_PASSWORD=.*%AUTHELIA_ADMIN_PASSWORD=$AUTHELIA_ADMIN_PASSWORD%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_ADMIN_PASSWORD=.*%AUTHELIA_ADMIN_PASSWORD=$AUTHELIA_ADMIN_PASSWORD%" "$REPO_DIR/.env"
    fi

    log_success "Configuration saved to .env file"
}

# Prompt for required values
prompt_for_values() {
    echo ""
    log_info "Configuration Setup:"
    echo ""

    # Set defaults from env file or hardcoded fallbacks
    DEFAULT_DOMAIN="${DOMAIN:-example.duckdns.org}"
    DEFAULT_SERVER_IP="${SERVER_IP:-$(hostname -I | awk '{print $1}')}"
    DEFAULT_CORE_SERVER_IP="${CORE_SERVER_IP:-}"
    DEFAULT_SERVER_HOSTNAME="${SERVER_HOSTNAME:-$(hostname)}"
    DEFAULT_TZ="${TZ:-America/New_York}"

    # Display current/default configuration
    echo "Please review the following configuration:"
    echo "  Domain: $DEFAULT_DOMAIN"
    echo "  Server IP: $DEFAULT_SERVER_IP"
    echo "  Server Hostname: $DEFAULT_SERVER_HOSTNAME"
    echo "  Timezone: $DEFAULT_TZ"

    if [ "$DEPLOY_CORE" = false ] && [ -z "$DEFAULT_CORE_SERVER_IP" ]; then
        echo "  Core Server IP: [Will be prompted for multi-server TLS]"
    elif [ -n "$DEFAULT_CORE_SERVER_IP" ]; then
        echo "  Core Server IP: $DEFAULT_CORE_SERVER_IP"
    fi

    if [ "$DEPLOY_CORE" = true ]; then
        DEFAULT_ADMIN_USER="${DEFAULT_USER:-admin}"
        DEFAULT_ADMIN_EMAIL="${DEFAULT_EMAIL:-${DEFAULT_ADMIN_USER}@${DEFAULT_DOMAIN}}"
        echo "  Admin User: $DEFAULT_ADMIN_USER"
        echo "  Admin Email: $DEFAULT_ADMIN_EMAIL"
        echo "  Admin Password: [Will be prompted if needed]"
    fi

    echo ""
    read -p "Use these default values? (Y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Please enter custom values:"
        echo ""

        # Domain
        read -p "Domain [$DEFAULT_DOMAIN]: " DOMAIN
        DOMAIN="${DOMAIN:-$DEFAULT_DOMAIN}"

        # Server IP
        read -p "Server IP [$DEFAULT_SERVER_IP]: " SERVER_IP
        SERVER_IP="${SERVER_IP:-$DEFAULT_SERVER_IP}"

        # Server Hostname
        read -p "Server Hostname [$DEFAULT_SERVER_HOSTNAME]: " SERVER_HOSTNAME
        SERVER_HOSTNAME="${SERVER_HOSTNAME:-$DEFAULT_SERVER_HOSTNAME}"

        # Timezone
        read -p "Timezone [$DEFAULT_TZ]: " TZ
        TZ="${TZ:-$DEFAULT_TZ}"

        # Core server IP (for multi-server setup)
        if [ "$DEPLOY_CORE" = false ]; then
            echo ""
            read -p "Core server IP (for shared TLS CA): " CORE_SERVER_IP
        fi

        # Admin credentials (only if deploying core)
        if [ "$DEPLOY_CORE" = true ]; then
            echo ""
            log_info "Authelia Admin Credentials:"

            read -p "Admin username [$DEFAULT_ADMIN_USER]: " ADMIN_USER
            ADMIN_USER="${ADMIN_USER:-$DEFAULT_ADMIN_USER}"

            read -p "Admin email [$DEFAULT_ADMIN_EMAIL]: " ADMIN_EMAIL
            ADMIN_EMAIL="${ADMIN_EMAIL:-$DEFAULT_ADMIN_EMAIL}"

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
    else
        # Use defaults
        DOMAIN="$DEFAULT_DOMAIN"
        SERVER_IP="$DEFAULT_SERVER_IP"
        SERVER_HOSTNAME="$DEFAULT_SERVER_HOSTNAME"
        TZ="$DEFAULT_TZ"
        CORE_SERVER_IP="$DEFAULT_CORE_SERVER_IP"

        if [ "$DEPLOY_CORE" = true ]; then
            ADMIN_USER="$DEFAULT_ADMIN_USER"
            ADMIN_EMAIL="$DEFAULT_ADMIN_EMAIL"
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
    apt-get install -y curl wget git htop nano vim ufw fail2ban unattended-upgrades apt-listchanges sshpass

    # Step 3: Install Docker
    log_info "Step 3/10: Installing Docker..."
    if command -v docker &> /dev/null && docker --version &> /dev/null; then
        log_success "Docker is already installed ($(docker --version))"
        # Check if user is in docker group
        if ! groups "$ACTUAL_USER" | grep -q docker; then
            log_info "Adding $ACTUAL_USER to docker group..."
            usermod -aG docker "$ACTUAL_USER"
            NEEDS_LOGOUT=true
        fi
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
        NEEDS_LOGOUT=true
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

    # Step 5: Generate shared CA for multi-server TLS
    log_info "Step 5/10: Generating shared CA certificate for multi-server TLS..."
    generate_shared_ca

    # Step 6: Configure Docker TLS
    log_info "Step 6/10: Configuring Docker TLS..."
    setup_docker_tls

    # Step 7: Configure UFW firewall
    log_info "Step 7/10: Configuring firewall..."
    ufw --force enable
    ufw allow ssh
    ufw allow 80
    ufw allow 443
    ufw allow 2376/tcp  # Docker TLS port
    log_success "Firewall configured"

    # Step 8: Configure automatic updates
    log_info "Step 8/10: Configuring automatic updates..."
    dpkg-reconfigure -f noninteractive unattended-upgrades

    # Step 9: Set proper ownership
    log_info "Step 9/10: Setting directory ownership..."
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/dockge

    # Step 10: Create Docker networks
    log_info "Step 10/10: Creating Docker networks..."
    docker network create homelab-network 2>/dev/null && log_success "Created homelab-network" || log_info "homelab-network already exists"
    docker network create traefik-network 2>/dev/null && log_success "Created traefik-network" || log_info "traefik-network already exists"
    docker network create media-network 2>/dev/null && log_success "Created media-network" || log_info "media-network already exists"

    log_success "System setup completed!"
    echo ""
    if [ "$NEEDS_LOGOUT" = true ]; then
        log_info "Please log out and back in for Docker group changes to take effect."
        echo ""
    fi
}

# Deploy Dockge function
deploy_dockge() {
    log_info "Deploying Dockge stack manager..."
    log_info "  - Dockge (Docker Compose Manager)"
    echo ""

    # Copy Dockge stack files
    sudo cp "$REPO_DIR/docker-compose/dockge/docker-compose.yml" /opt/dockge/docker-compose.yml
    sudo cp "$REPO_DIR/.env" /opt/dockge/.env

    # Replace placeholders in Dockge compose file
    replace_env_placeholders "/opt/dockge/docker-compose.yml"

    # Deploy Dockge stack
    cd /opt/dockge
    docker compose up -d
    log_success "Dockge deployed"
    echo ""
}

# Deploy core stack function
deploy_core() {
    log_info "Deploying core stack..."
    log_info "  - DuckDNS (Dynamic DNS)"
    log_info "  - Traefik (Reverse Proxy with SSL)"
    log_info "  - Authelia (Single Sign-On)"
    echo ""

    # Copy core stack files
    sudo cp "$REPO_DIR/docker-compose/core/docker-compose.yml" /opt/stacks/core/docker-compose.yml
    sudo cp "$REPO_DIR/.env" /opt/stacks/core/.env

    # Replace placeholders in core compose file
    replace_env_placeholders "/opt/stacks/core/docker-compose.yml"

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

    # Generate shared CA for multi-server TLS
    log_info "Generating shared CA certificate for multi-server TLS..."
    generate_shared_ca

    # Replace placeholders in core compose file
    replace_env_placeholders "/opt/stacks/core/docker-compose.yml"

    # Deploy core stack
    cd /opt/stacks/core
    docker compose up -d
    log_success "Core infrastructure deployed"
    echo ""
}

# Deploy infrastructure stack function
deploy_infrastructure() {
    log_info "Deploying infrastructure stack..."
    log_info "  - Pi-hole (DNS Ad Blocker)"
    log_info "  - Watchtower (Container Updates)"
    log_info "  - Dozzle (Log Viewer)"
    log_info "  - Glances (System Monitor)"
    log_info "  - Docker Proxy (Security)"
    echo ""

    # Copy infrastructure stack
    cp "$REPO_DIR/docker-compose/infrastructure/docker-compose.yml" /opt/stacks/infrastructure/docker-compose.yml
    cp "$REPO_DIR/.env" /opt/stacks/infrastructure/.env

    # Replace placeholders in infrastructure compose file
    replace_env_placeholders "/opt/stacks/infrastructure/docker-compose.yml"

    # Copy any additional config directories
    for config_dir in "$REPO_DIR/docker-compose/infrastructure"/*/; do
        if [ -d "$config_dir" ] && [ "$(basename "$config_dir")" != "." ]; then
            cp -r "$config_dir" /opt/stacks/infrastructure/
        fi
    done

    # If core is not deployed, remove Authelia middleware references
    if [ "$DEPLOY_CORE" = false ]; then
        log_info "Core infrastructure not deployed - removing Authelia middleware references..."
        sed -i '/middlewares=authelia@docker/d' /opt/stacks/infrastructure/docker-compose.yml
    fi

    # Replace placeholders in infrastructure compose file
    replace_env_placeholders "/opt/stacks/infrastructure/docker-compose.yml"

    # Deploy infrastructure stack
    cd /opt/stacks/infrastructure
    docker compose up -d
    log_success "Infrastructure stack deployed"
    echo ""
}

# Deploy dashboards stack function
deploy_dashboards() {
    log_info "Deploying dashboard stack..."
    log_info "  - Homepage (Application Dashboard)"
    log_info "  - Homarr (Modern Dashboard)"
    echo ""

    # Create dashboards directory
    sudo mkdir -p /opt/stacks/dashboards

    # Copy dashboards compose file
    cp "$REPO_DIR/docker-compose/dashboards/docker-compose.yml" /opt/stacks/dashboards/docker-compose.yml
    cp "$REPO_DIR/.env" /opt/stacks/dashboards/.env

    # Replace placeholders in dashboards compose file
    replace_env_placeholders "/opt/stacks/dashboards/docker-compose.yml"

    # Copy homepage config
    if [ -d "$REPO_DIR/docker-compose/dashboards/homepage" ]; then
        cp -r "$REPO_DIR/docker-compose/dashboards/homepage" /opt/stacks/dashboards/
    fi

    # Replace placeholders in dashboards compose file
    replace_env_placeholders "/opt/stacks/dashboards/docker-compose.yml"

    # Deploy dashboards stack
    cd /opt/stacks/dashboards
    docker compose up -d
    log_success "Dashboard stack deployed"
    echo ""
}

# Deployment function
perform_deployment() {
    log_info "Starting deployment..."

    # Initialize missing vars summary
    MISSING_VARS_SUMMARY=""
    TLS_ISSUES_SUMMARY=""

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
    sudo mkdir -p /opt/stacks/core || { log_error "Failed to create /opt/stacks/core"; exit 1; }
    sudo mkdir -p /opt/stacks/infrastructure || { log_error "Failed to create /opt/stacks/infrastructure"; exit 1; }
    sudo mkdir -p /opt/stacks/dashboards || { log_error "Failed to create /opt/stacks/dashboards"; exit 1; }
    sudo mkdir -p /opt/dockge || { log_error "Failed to create /opt/dockge"; exit 1; }
    sudo chown -R "$USER:$USER" /opt/stacks
    sudo chown -R "$USER:$USER" /opt/dockge
    log_success "Directories created"

    # Step 2: Setup multi-server TLS if needed
    if [ "$DEPLOY_CORE" = false ]; then
        setup_multi_server_tls
    fi

    # Step 3: Create Docker networks (if they don't exist)
    log_info "Step $([ "$DEPLOY_CORE" = false ] && echo "3" || echo "2"): Creating Docker networks..."
    docker network create homelab-network 2>/dev/null && log_success "Created homelab-network" || log_info "homelab-network already exists"
    docker network create traefik-network 2>/dev/null && log_success "Created traefik-network" || log_info "traefik-network already exists"
    docker network create media-network 2>/dev/null && log_success "Created media-network" || log_info "media-network already exists"
    echo ""

    # Step 4: Deploy Dockge (always deployed)
    deploy_dockge

    # Deploy core stack
    if [ "$DEPLOY_CORE" = true ]; then
        deploy_core
    fi

    # Deploy infrastructure stack
    if [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
        step_num=$([ "$DEPLOY_CORE" = true ] && echo "6" || echo "5")
        deploy_infrastructure
    fi

    # Deploy dashboard stack
    if [ "$DEPLOY_DASHBOARDS" = true ]; then
        if [ "$DEPLOY_CORE" = true ] && [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
            step_num=7
        elif [ "$DEPLOY_CORE" = true ] || [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
            step_num=6
        else
            step_num=5
        fi
        deploy_dashboards
    fi

    # Setup stacks for Dockge
    if [ "$SETUP_STACKS" = true ]; then
        setup_stacks_for_dockge
    fi

    # Report any missing variables
    if [ -n "$MISSING_VARS_SUMMARY" ]; then
        log_warning "The following environment variables were missing and may cause issues:"
        echo "$MISSING_VARS_SUMMARY"
        log_info "Please update your .env file and redeploy affected stacks."
    fi

    # Report any TLS issues
    if [ -n "$TLS_ISSUES_SUMMARY" ]; then
        echo ""
        log_warning "TLS Configuration Issues Detected:"
        echo "$TLS_ISSUES_SUMMARY"
        echo ""
    fi
}

# Setup Docker TLS function
setup_docker_tls() {
    local TLS_DIR="/home/$ACTUAL_USER/EZ-Homelab/docker-tls"
    
    # Create TLS directory
    mkdir -p "$TLS_DIR"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$TLS_DIR"
    
    # Use shared CA if available, otherwise generate local CA
    if [ -f "/opt/stacks/core/shared-ca/ca.pem" ] && [ -f "/opt/stacks/core/shared-ca/ca-key.pem" ]; then
        log_info "Using shared CA certificate for Docker TLS..."
        cp "/opt/stacks/core/shared-ca/ca.pem" "$TLS_DIR/ca.pem"
        cp "/opt/stacks/core/shared-ca/ca-key.pem" "$TLS_DIR/ca-key.pem"
    else
        log_info "Generating local CA certificate for Docker TLS..."
        # Generate CA
        openssl genrsa -out "$TLS_DIR/ca-key.pem" 4096
        openssl req -new -x509 -days 365 -key "$TLS_DIR/ca-key.pem" -sha256 -out "$TLS_DIR/ca.pem" -subj "/C=US/ST=State/L=City/O=Organization/CN=Docker-CA"
    fi
    
    # Generate server key and cert
    openssl genrsa -out "$TLS_DIR/server-key.pem" 4096
    openssl req -subj "/CN=$SERVER_IP" -new -key "$TLS_DIR/server-key.pem" -out "$TLS_DIR/server.csr"
    echo "subjectAltName = DNS:$SERVER_IP,IP:$SERVER_IP,IP:127.0.0.1" > "$TLS_DIR/extfile.cnf"
    openssl x509 -req -days 365 -in "$TLS_DIR/server.csr" -CA "$TLS_DIR/ca.pem" -CAkey "$TLS_DIR/ca-key.pem" -CAcreateserial -out "$TLS_DIR/server-cert.pem" -extfile "$TLS_DIR/extfile.cnf"
    
    # Generate client key and cert
    openssl genrsa -out "$TLS_DIR/client-key.pem" 4096
    openssl req -subj "/CN=client" -new -key "$TLS_DIR/client-key.pem" -out "$TLS_DIR/client.csr"
    openssl x509 -req -days 365 -in "$TLS_DIR/client.csr" -CA "$TLS_DIR/ca.pem" -CAkey "$TLS_DIR/ca-key.pem" -CAcreateserial -out "$TLS_DIR/client-cert.pem"
    
    # Configure Docker daemon
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "tls": true,
  "tlsverify": true,
  "tlscacert": "$TLS_DIR/ca.pem",
  "tlscert": "$TLS_DIR/server-cert.pem",
  "tlskey": "$TLS_DIR/server-key.pem"
}
EOF
    
    # Update systemd service
    sudo sed -i 's|-H fd://|-H fd:// -H tcp://0.0.0.0:2376|' /lib/systemd/system/docker.service
    
    # Reload and restart Docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    log_success "Docker TLS configured on port 2376"
}
setup_stacks_for_dockge() {
    log_info "Setting up all stacks for Dockge..."

    # List of stacks to setup
    STACKS=("vpn" "media" "media-management" "transcoders" "monitoring" "productivity" "wikis" "utilities" "alternatives" "homeassistant")

    for stack in "${STACKS[@]}"; do
        STACK_DIR="/opt/stacks/$stack"
        REPO_STACK_DIR="$REPO_DIR/docker-compose/$stack"

        if [ -d "$REPO_STACK_DIR" ]; then
            mkdir -p "$STACK_DIR"
            if [ -f "$REPO_STACK_DIR/docker-compose.yml" ]; then
                cp "$REPO_STACK_DIR/docker-compose.yml" "$STACK_DIR/docker-compose.yml"
                cp "$REPO_DIR/.env" "$STACK_DIR/.env"

                # Replace placeholders in the compose file
                replace_env_placeholders "$STACK_DIR/docker-compose.yml"

                # Copy any additional config directories
                for config_dir in "$REPO_STACK_DIR"/*/; do
                    if [ -d "$config_dir" ] && [ "$(basename "$config_dir")" != "." ]; then
                        cp -r "$config_dir" "$STACK_DIR/"
                    fi
                done

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
    echo "   - Configures TLS for remote Docker access (Sablier)"
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
            DEPLOY_DASHBOARDS=true
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

    # Ensure required directories exist
    log_info "Ensuring required directories exist..."
    if [ "$EUID" -eq 0 ]; then
        mkdir -p /opt/stacks/core
        mkdir -p /opt/stacks/infrastructure
        mkdir -p /opt/stacks/dashboards
        mkdir -p /opt/dockge
    else
        sudo mkdir -p /opt/stacks/core
        sudo mkdir -p /opt/stacks/infrastructure
        sudo mkdir -p /opt/stacks/dashboards
        sudo mkdir -p /opt/dockge
    fi
    log_success "Directories ready"

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
        echo "  📊 Homepage: https://homepage.${DOMAIN}"
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