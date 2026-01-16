#!/bin/bash
# AI-Homelab First-Run Setup Script
# This script prepares a fresh Debian installation for homelab deployment
# Run as: sudo ./setup-homelab.sh [--yes]
# Options:
#   --yes    Skip all confirmation prompts (for automated deployments)

set -e  # Exit on error

# Parse command line arguments
AUTO_YES=false
for arg in "$@"; do
    case $arg in
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        --help|-h)
            echo "Usage: sudo ./setup-homelab.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --yes, -y    Skip all confirmation prompts"
            echo "  --help, -h   Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Run with --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
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

log_progress() {
    echo -e "${CYAN}[PROGRESS]${NC} $1"
}

# Colorized prompt function
prompt_user() {
    local prompt_text="$1"
    local default="${2:-}"
    echo -e "${MAGENTA}${BOLD}[PROMPT]${NC} ${prompt_text}"
    if [ -n "$default" ]; then
        echo -e "${CYAN}(default: $default)${NC}"
    fi
}

# Confirmation function that respects --yes flag
confirm() {
    local prompt="$1"
    if [ "$AUTO_YES" = true ]; then
        log_info "Auto-confirmed: $prompt"
        return 0
    fi
    prompt_user "$prompt"
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check if running with elevated privileges
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run with sudo: sudo ./setup-homelab.sh"
    exit 1
fi

# Get the actual user who invoked sudo
ACTUAL_USER="${SUDO_USER:-$USER}"

#==========================================
# STEP FUNCTIONS
#==========================================

# Handle root user scenario - grant sudo and exit
handle_root_user() {
    log_info "Running as root - checking for non-root users..."
    echo ""
    
    # Find non-root users with home directories and UID >= 1000
    AVAILABLE_USERS=$(awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" {print $1}' /etc/passwd)
    
    if [ -z "$AVAILABLE_USERS" ]; then
        log_error "No non-root user found on this system"
        log_info "Please create a user first:"
        log_info "  adduser <username>"
        exit 1
    fi
    
    # If only one user, use that one
    USER_COUNT=$(echo "$AVAILABLE_USERS" | wc -l)
    if [ "$USER_COUNT" -eq 1 ]; then
        TARGET_USER="$AVAILABLE_USERS"
        log_info "Found user: $TARGET_USER"
    else
        # Multiple users found, let root choose
        log_info "Multiple users found:"
        echo "$AVAILABLE_USERS" | nl
        echo ""
        read -p "Enter username to grant sudo access: " TARGET_USER
        
        # Validate the entered username
        if ! echo "$AVAILABLE_USERS" | grep -q "^${TARGET_USER}$"; then
            log_error "Invalid username: $TARGET_USER"
            exit 1
        fi
    fi
    
    # Check if user already has sudo
    if groups "$TARGET_USER" | grep -q '\bsudo\b'; then
        log_success "User $TARGET_USER already has sudo access"
    else
        # Confirm before granting sudo
        echo ""
        read -p "Grant sudo access to $TARGET_USER? (y/N): " CONFIRM
        if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
            usermod -aG sudo "$TARGET_USER"
            log_success "Sudo access granted to $TARGET_USER"
        else
            log_error "Cannot proceed without sudo access"
            exit 1
        fi
    fi
    
    # Exit with instructions
    echo ""
    echo "=========================================="
    log_success "Setup preparation complete!"
    echo "=========================================="
    echo ""
    log_info "Next steps:"
    echo ""
    log_info "  1. Log in as $TARGET_USER:"
    echo "     su - $TARGET_USER"
    echo ""
    log_info "  2. Navigate to the AI-Homelab directory and run setup again:"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_DIR="$(dirname "$SCRIPT_DIR")"
    echo "     cd $REPO_DIR"
    echo "     sudo ./scripts/setup-homelab.sh"
    echo ""
    log_warning "Note: You may need to log out and back in for sudo access to take effect"
    echo ""
    exit 0
}

step_0_preflight_checks() {
    log_info "Step 0/$STEPS_TOTAL: Running pre-flight checks..."
    log_progress "Starting setup process"

    # Check internet connectivity
    if ! ping -c 1 -W 2 8.8.8.8 &> /dev/null && ! ping -c 1 -W 2 1.1.1.1 &> /dev/null; then
        log_error "No internet connectivity detected"
        log_info "Internet access is required for:"
        log_info "  - Installing packages"
        log_info "  - Downloading Docker images"
        log_info "  - Accessing Docker Hub"
        exit 1
    fi

    # Check disk space (require at least 5GB free)
    AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
    REQUIRED_SPACE=5000000  # 5GB in KB
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        log_error "Insufficient disk space on root partition"
        log_info "Available: $(($AVAILABLE_SPACE / 1024 / 1024))GB"
        log_info "Required: $(($REQUIRED_SPACE / 1024 / 1024))GB"
        exit 1
    fi

    log_success "Pre-flight checks passed"
    log_info "Internet: Connected"
    log_info "Disk space: $(($AVAILABLE_SPACE / 1024 / 1024))GB available"
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps"
    echo ""
}

step_1_update_system() {
    log_info "Step 1/$STEPS_TOTAL: Updating system packages..."
    apt-get update && apt-get upgrade -y
    log_success "System updated successfully"
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps"
    echo ""
}

step_2_install_packages() {
    log_info "Step 2/$STEPS_TOTAL: Installing required packages..."
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        git \
        openssh-server \
        sudo \
        pciutils \
        net-tools \
        ufw

    log_success "Required packages installed"
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps"
    echo ""
}

step_3_install_docker() {
    log_info "Step 3/$STEPS_TOTAL: Installing Docker..."
    if command -v docker &> /dev/null && docker --version &> /dev/null && docker compose version &> /dev/null 2>&1; then
        log_warning "Docker and Docker Compose are already installed ($(docker --version), $(docker compose version))"
    else
        # Add Docker's official GPG key
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Update and install Docker
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        log_success "Docker installed successfully ($(docker --version), $(docker compose version))"
    fi
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps"
    echo ""
}

step_4_configure_user_groups() {
    log_info "Step 4/$STEPS_TOTAL: Configuring user groups..."

    # Add user to sudo group if not already
    if groups "$ACTUAL_USER" | grep -q '\bsudo\b'; then
        log_warning "User $ACTUAL_USER is already in sudo group"
    else
        usermod -aG sudo "$ACTUAL_USER"
        log_success "User $ACTUAL_USER added to sudo group"
    fi

    # Add user to docker group
    if groups "$ACTUAL_USER" | grep -q '\bdocker\b'; then
        log_warning "User $ACTUAL_USER is already in docker group"
    else
        usermod -aG docker "$ACTUAL_USER"
        log_success "User $ACTUAL_USER added to docker group"
    fi
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps"
    echo ""
}

step_5_configure_firewall() {
    log_info "Step 5/$STEPS_TOTAL: Configuring firewall..."
    # Enable UFW if not already enabled
    if ufw status | grep -q "Status: active"; then
        log_warning "Firewall is already active"
    else
        ufw --force enable
        log_success "Firewall enabled"
    fi

    # Allow SSH if not already allowed
    if ufw status | grep -q "22/tcp"; then
        log_warning "SSH port 22 is already allowed"
    else
        ufw allow ssh
        log_success "SSH port allowed in firewall"
    fi

    # Allow HTTP/HTTPS for web services
    ufw allow 80/tcp
    ufw allow 443/tcp
    log_success "HTTP/HTTPS ports allowed in firewall"
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps"
    echo ""
}

step_6_configure_ssh() {
    log_info "Step 6/$STEPS_TOTAL: Configuring SSH server..."
    systemctl enable ssh
    systemctl start ssh

    # Check if SSH is running
    if systemctl is-active --quiet ssh; then
        SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
        SSH_PORT=${SSH_PORT:-22}
        log_success "SSH server is running on port $SSH_PORT"
    else
        log_warning "SSH server failed to start, check configuration"
    fi
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps"
    echo ""
}

step_7_generate_authelia_secrets() {
    log_info "Step 7/$STEPS_TOTAL: Generating Authelia authentication secrets..."
    echo ""

    # Validate Docker is available for password hash generation
    if ! docker info &> /dev/null 2>&1; then
        log_error "Docker is not available for password hash generation"
        log_info "Docker must be running to generate Authelia password hashes."
        log_info "Please ensure:"
        log_info "  1. Docker daemon is started: sudo systemctl start docker"
        log_info "  2. User can access Docker: docker ps"
        log_info "  3. Log out and log back in if recently added to docker group"
        echo ""
        log_info "After fixing, re-run: sudo ./setup-homelab.sh"
        exit 1
    fi

    log_success "Docker is available for password operations"
    echo ""

    # Check if .env file exists in the repo
    REPO_ENV_FILE="$REPO_DIR/.env"
    if [ ! -f "$REPO_ENV_FILE" ]; then
        log_error ".env file not found at $REPO_ENV_FILE"
        log_info "Please create .env file from .env.example first"
        exit 1
    fi

    # Load and validate essential environment variables
    log_info "Validating environment variables..."
    DOMAIN=$(get_env_value "DOMAIN" "")
    if is_placeholder "$DOMAIN" || [ -z "$DOMAIN" ]; then
        if [ "$AUTO_YES" = true ]; then
            log_error "DOMAIN not set in .env and running in --yes mode"
            log_info "Please set DOMAIN in .env file"
            exit 1
        else
            prompt_user "Enter your DuckDNS domain (e.g., yourname.duckdns.org)"
            read -p "> " DOMAIN
        fi
        escaped_domain=$(printf '%s\n' "$DOMAIN" | sed 's/|/\\|/g' | tr -d '\n')
        sed -i "s|^DOMAIN=.*|DOMAIN=$escaped_domain|" "$REPO_ENV_FILE"
    fi

    SERVER_IP=$(get_env_value "SERVER_IP" "")
    if is_placeholder "$SERVER_IP" || [ -z "$SERVER_IP" ]; then
        # Try to detect server IP
        DETECTED_IP=$(hostname -I | awk '{print $1}')
        if [ -n "$DETECTED_IP" ]; then
            SERVER_IP="$DETECTED_IP"
            log_info "Detected server IP: $SERVER_IP"
        else
            if [ "$AUTO_YES" = true ]; then
                log_error "SERVER_IP not set and could not detect"
                exit 1
            else
                prompt_user "Enter your server IP address"
                read -p "> " SERVER_IP
            fi
        fi
        escaped_ip=$(printf '%s\n' "$SERVER_IP" | sed 's/|/\\|/g' | tr -d '\n')
        sed -i "s|^SERVER_IP=.*|SERVER_IP=$escaped_ip|" "$REPO_ENV_FILE"
    fi

    # Load other variables with defaults
    PUID=$(get_env_value "PUID" "1000")
    PGID=$(get_env_value "PGID" "1000")
    TZ=$(get_env_value "TZ" "America/New_York")
    DUCKDNS_TOKEN=$(get_env_value "DUCKDNS_TOKEN" "")
    DUCKDNS_SUBDOMAINS=$(get_env_value "DUCKDNS_SUBDOMAINS" "")

    log_success "Environment variables validated"

    # Check if secrets are already set (not placeholder values)
    CURRENT_JWT=$(grep "^AUTHELIA_JWT_SECRET=" "$REPO_ENV_FILE" | cut -d'=' -f2)
    if [ -n "$CURRENT_JWT" ] && [ "$CURRENT_JWT" != "your-jwt-secret-here" ] && [ "$CURRENT_JWT" != "generate-with-openssl-rand-hex-64" ] && [ ${#CURRENT_JWT} -ge 64 ]; then
        log_warning "Authelia secrets appear to already be set in .env"
        if [ "$AUTO_YES" = true ]; then
            log_info "Auto-confirmed: Keeping existing secrets (--yes mode)"
        elif confirm "Regenerate Authelia secrets?"; then
            generate_new_secrets
        else
            log_info "Keeping existing secrets"
        fi
    else
        generate_new_secrets
    fi

    # Get or set admin credentials
    log_info "Setting up Authelia admin user..."
    echo ""

    # Get admin user from .env or default
    ADMIN_USER=$(get_env_value "AUTHELIA_ADMIN_USER" "admin")
    if is_placeholder "$ADMIN_USER"; then
        ADMIN_USER="admin"
    fi

    # Get admin email from .env or prompt
    ADMIN_EMAIL=$(get_env_value "AUTHELIA_ADMIN_EMAIL" "your-email@example.com")
    if is_placeholder "$ADMIN_EMAIL"; then
        prompt_user "Enter admin email address"
        read -p "> " ADMIN_EMAIL
    fi

    # Get admin password from .env or prompt
    ADMIN_PASSWORD=$(get_env_value "AUTHELIA_ADMIN_PASSWORD" "YourStrongPassword123!")
    if is_placeholder "$ADMIN_PASSWORD" || [ "$AUTO_YES" != true ]; then
        if [ "$AUTO_YES" = true ]; then
            if is_placeholder "$ADMIN_PASSWORD"; then
                log_warning "Admin password not set in .env, generating random password"
                ADMIN_PASSWORD=$(openssl rand -base64 12)
                log_info "Generated password: $ADMIN_PASSWORD"
            else
                log_info "Using password from .env"
            fi
        else
            if ! is_placeholder "$ADMIN_PASSWORD"; then
                if confirm "Use existing admin password from .env?"; then
                    log_info "Using existing password from .env"
                else
                    ADMIN_PASSWORD=""
                fi
            fi
            if [ -z "$ADMIN_PASSWORD" ] || is_placeholder "$ADMIN_PASSWORD"; then
                while true; do
                    read -sp "Enter password for $ADMIN_USER: " ADMIN_PASSWORD
                    echo ""
                    read -sp "Confirm password: " ADMIN_PASSWORD_CONFIRM
                    echo ""
                    
                    if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
                        if [ ${#ADMIN_PASSWORD} -lt 8 ]; then
                            log_warning "Password should be at least 8 characters long"
                            continue
                        fi
                        break
                    else
                        log_warning "Passwords do not match, please try again"
                    fi
                done
            fi
        fi
    else
        log_info "Using admin password from .env"
    fi

    # Generate password hash using Docker
    log_info "Generating password hash (this may take 30-60 seconds)..."
    log_info "Pulling Authelia image if not already present..."

    # Pull image first to show progress
    if ! docker pull authelia/authelia:4.37 2>&1 | grep -E '(Pulling|Downloaded|Already exists|Status)'; then
        log_error "Failed to pull Authelia Docker image"
        log_info "Please check:"
        log_info "  1. Internet connectivity: ping docker.io"
        log_info "  2. Docker Hub access: docker search authelia"
        log_info "  3. Disk space: df -h"
        exit 1
    fi

    echo ""
    log_info "Generating password hash..."

    # Generate hash and write DIRECTLY to file
    timeout 60 docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password "$ADMIN_PASSWORD" 2>&1 | \
        grep -oP 'Digest: \K\$argon2.*' > /tmp/authelia_password_hash.tmp

    HASH_EXIT_CODE=$?

    if [ $HASH_EXIT_CODE -eq 124 ]; then
        log_error "Password hash generation timed out after 60 seconds"
        exit 1
    elif [ $HASH_EXIT_CODE -ne 0 ] || [ ! -s /tmp/authelia_password_hash.tmp ]; then
        log_error "Failed to generate password hash"
        exit 1
    fi

    chmod 600 /tmp/authelia_password_hash.tmp
    log_success "Password hash generated successfully"

    log_success "Admin user configured: $ADMIN_USER"
    log_success "Password hash generated and will be applied during deployment"

    # Store credentials
    mkdir -p /opt/stacks/.setup-temp
    {
        echo "ADMIN_USER=$ADMIN_USER"
        echo "ADMIN_EMAIL=$ADMIN_EMAIL"
        echo "ADMIN_PASSWORD=$ADMIN_PASSWORD"
    } > /opt/stacks/.setup-temp/authelia_admin_credentials.tmp
    chmod 600 /opt/stacks/.setup-temp/authelia_admin_credentials.tmp

    cp /tmp/authelia_password_hash.tmp /opt/stacks/.setup-temp/authelia_password_hash.tmp
    chmod 600 /opt/stacks/.setup-temp/authelia_password_hash.tmp

    # Save to .env file for persistence
    log_info "Saving credentials to .env file for persistence..."
    # Escape | in variables for sed and remove newlines
    escaped_user=$(printf '%s\n' "$ADMIN_USER" | sed 's/|/\\|/g' | tr -d '\n')
    escaped_email=$(printf '%s\n' "$ADMIN_EMAIL" | sed 's/|/\\|/g' | tr -d '\n')
    escaped_password=$(printf '%s\n' "$ADMIN_PASSWORD" | sed 's/|/\\|/g' | tr -d '\n')
    sed -i "s|^AUTHELIA_ADMIN_USER=.*|AUTHELIA_ADMIN_USER=$escaped_user|" "$REPO_ENV_FILE"
    sed -i "s|^AUTHELIA_ADMIN_EMAIL=.*|AUTHELIA_ADMIN_EMAIL=$escaped_email|" "$REPO_ENV_FILE"
    sed -i "s|^AUTHELIA_ADMIN_PASSWORD=.*|AUTHELIA_ADMIN_PASSWORD=$escaped_password|" "$REPO_ENV_FILE"
    log_success "Credentials saved to .env file"

    log_info "Credentials saved for deployment script"
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps"
    echo ""
}

step_8_create_directories() {
    log_info "Step 8/$STEPS_TOTAL: Creating directory structure..."
    mkdir -p /opt/stacks
    mkdir -p /opt/dockge/data
    mkdir -p /mnt/media/{movies,tv,music,books,photos}
    mkdir -p /mnt/downloads/{complete,incomplete}
    mkdir -p /mnt/backups
    mkdir -p /mnt/surveillance
    mkdir -p /mnt/git

    # Set ownership
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/dockge
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/media
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/downloads
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/backups
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/surveillance
    chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/git

    log_success "Directory structure created"

    # Restore SSL certificates if available
    if [ -f "$REPO_DIR/acme.json" ]; then
        mkdir -p /opt/stacks/core/traefik
        cp "$REPO_DIR/acme.json" /opt/stacks/core/traefik/acme.json
        chmod 600 /opt/stacks/core/traefik/acme.json
        chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/core/traefik/acme.json
        log_success "SSL certificates restored from repository"
    else
        log_info "No SSL certificates found in repository (first-time setup)"
    fi

    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps"
    echo ""
}

step_9_create_networks() {
    log_info "Step 9/$STEPS_TOTAL: Creating Docker networks..."
    su - "$ACTUAL_USER" -c "docker network create homelab-network 2>/dev/null || true"
    su - "$ACTUAL_USER" -c "docker network create traefik-network 2>/dev/null || true"
    su - "$ACTUAL_USER" -c "docker network create media-network 2>/dev/null || true"
    su - "$ACTUAL_USER" -c "docker network create dockerproxy-network 2>/dev/null || true"
    log_success "Docker networks created"
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    log_progress "Completed: $STEPS_COMPLETED/$STEPS_TOTAL steps (core setup)"
    echo ""
}

step_10_nvidia_drivers() {
    log_info "Step 10/$STEPS_TOTAL (Optional): Checking for NVIDIA GPU..."

    # Detect NVIDIA GPU
    if lspci | grep -i nvidia > /dev/null; then
        log_info "NVIDIA GPU detected:"
        GPU_INFO=$(lspci | grep -i nvidia)
        echo "$GPU_INFO"
        echo ""
        
        # Check if NVIDIA drivers are already installed
        if nvidia-smi &> /dev/null; then
            log_warning "NVIDIA drivers are already installed"
            nvidia-smi
            NVIDIA_INSTALLED=true
            NVIDIA_REBOOT_NEEDED=false
        else
            log_warning "NVIDIA GPU detected but drivers not installed"
            echo ""
            
            if confirm "Install NVIDIA drivers now?"; then
                install_nvidia_drivers "$GPU_INFO"
            else
                log_info "Skipping NVIDIA driver installation"
                log_info "To install later, visit: https://www.nvidia.com/Download/index.aspx"
                NVIDIA_INSTALLED=false
                NVIDIA_REBOOT_NEEDED=false
            fi
        fi
        echo ""
    else
        log_info "No NVIDIA GPU detected, skipping driver installation"
        NVIDIA_REBOOT_NEEDED=false
        echo ""
    fi
}

show_final_summary() {
    echo ""
    echo "=========================================="
    log_success "AI-Homelab setup completed successfully!"
    log_progress "All $STEPS_TOTAL core steps completed!"
    echo "=========================================="
    echo ""

    if [ "${NVIDIA_REBOOT_NEEDED:-false}" = true ]; then
        log_warning "⚠️  REBOOT REQUIRED FOR NVIDIA DRIVERS  ⚠️"
        echo ""
        log_info "NVIDIA drivers were installed and require a system reboot."
        log_info "Please reboot before running the deployment script."
        echo ""
        echo "  After reboot, verify drivers with: nvidia-smi"
        echo ""
        echo "=========================================="
        echo ""
    fi

    log_info "Next steps:"
    echo ""
    if [ "${NVIDIA_REBOOT_NEEDED:-false}" = true ]; then
    echo "  1. REBOOT YOUR SYSTEM for NVIDIA drivers to load"
    echo "     Run: sudo reboot"
    echo ""
    echo "  2. After reboot, deploy your homelab services"
    else
    echo "  1. Deploy your homelab services"
    fi
    echo ""
    echo "=========================================="
    echo ""
    log_info "Setup complete!"
    echo ""

    # Instructions for deployment
    if [ "${NVIDIA_REBOOT_NEEDED:-false}" = true ]; then
        log_info "Please reboot your system for NVIDIA drivers, then run:"
    else
        log_info "Next step - deploy your homelab services:"
    fi
    echo ""
    echo "  cd ~/AI-Homelab"
    echo "  sudo ./scripts/deploy-homelab.sh"
    echo ""
}

# Helper function to check if a value is a placeholder
is_placeholder() {
    local value="$1"
    case "$value" in
        "your-generated-key"|"your-jwt-secret-here"|"generate-with-openssl-rand-hex-64"|"YourStrongPassword123!"|"your-email@example.com"|"your-subdomain.duckdns.org"|"192.168.x.x"|"kelin-casa"|"41ef7faa-fc93-41d2-a32f-340fd2b75b2f"|"admin"|"postgres"|"your-username"|"")
            return 0  # true, it's a placeholder
            ;;
        *)
            return 1  # false, it's a real value
            ;;
    esac
}

# Helper function to get value from .env, using default if placeholder
get_env_value() {
    local var_name="$1"
    local default_value="$2"
    local value
    value=$(grep "^${var_name}=" "$REPO_ENV_FILE" 2>/dev/null | cut -d'=' -f2-)
    if [ -n "$value" ] && ! is_placeholder "$value"; then
        echo "$value"
    else
        echo "$default_value"
    fi
}

# Helper function to generate secrets
generate_secret() {
    openssl rand -hex 64
}

# Helper function to generate new Authelia secrets
generate_new_secrets() {
    log_info "Generating new JWT secret..."
    JWT_SECRET=$(generate_secret)
    log_info "Generating new session secret..."
    SESSION_SECRET=$(generate_secret)
    log_info "Generating new storage encryption key..."
    ENCRYPTION_KEY=$(generate_secret)
    
    # Update .env file
    escaped_jwt=$(printf '%s\n' "$JWT_SECRET" | sed 's/|/\\|/g')
    escaped_session=$(printf '%s\n' "$SESSION_SECRET" | sed 's/|/\\|/g')
    escaped_encryption=$(printf '%s\n' "$ENCRYPTION_KEY" | sed 's/|/\\|/g')
    sed -i "s|^AUTHELIA_JWT_SECRET=.*|AUTHELIA_JWT_SECRET=$escaped_jwt|" "$REPO_ENV_FILE"
    sed -i "s|^AUTHELIA_SESSION_SECRET=.*|AUTHELIA_SESSION_SECRET=$escaped_session|" "$REPO_ENV_FILE"
    sed -i "s|^AUTHELIA_STORAGE_ENCRYPTION_KEY=.*|AUTHELIA_STORAGE_ENCRYPTION_KEY=$escaped_encryption|" "$REPO_ENV_FILE"
    
    log_success "New secrets generated and saved to .env"
}

# NVIDIA Driver Installation Function
install_nvidia_drivers() {
    local GPU_INFO="$1"
    
    log_info "Installing NVIDIA drivers using official installer..."
    echo ""
    
    # Extract GPU model for driver selection
    GPU_MODEL=$(echo "$GPU_INFO" | grep -oP 'NVIDIA.*' | head -1)
    log_info "GPU Model: $GPU_MODEL"
    
    # Determine recommended driver version
    log_info "Determining recommended driver version..."
    
    # Install prerequisites for NVIDIA installer
    log_info "Installing build prerequisites..."
    apt-get install -y build-essential linux-headers-$(uname -r) pkg-config libglvnd-dev 2>&1 | tee /tmp/nvidia-prereq.log
    
    # Disable nouveau driver
    log_info "Disabling nouveau driver..."
    if [ ! -f /etc/modprobe.d/blacklist-nouveau.conf ]; then
        cat > /etc/modprobe.d/blacklist-nouveau.conf << EOF
blacklist nouveau
options nouveau modeset=0
EOF
        update-initramfs -u
        log_success "Nouveau driver blacklisted (reboot required)"
    fi
    
    # Download latest NVIDIA driver
    NVIDIA_VERSION="550.127.05"  # Latest Production Branch as of script creation
    DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run"
    DRIVER_FILE="/tmp/NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run"
    
    log_info "Downloading NVIDIA driver version ${NVIDIA_VERSION}..."
    log_info "URL: $DRIVER_URL"
    
    if curl -fL -o "$DRIVER_FILE" "$DRIVER_URL" 2>&1 | tee /tmp/nvidia-download.log; then
        log_success "Driver downloaded successfully"
        chmod +x "$DRIVER_FILE"
        
        log_info "Running NVIDIA installer (this may take several minutes)..."
        log_info "The installer will compile kernel modules and configure the driver."
        echo ""
        
        # Run NVIDIA installer with appropriate flags
        if "$DRIVER_FILE" --silent --dkms --no-questions 2>&1 | tee /tmp/nvidia-install.log; then
            log_success "NVIDIA drivers installed successfully"
            NVIDIA_INSTALLED=true
            NVIDIA_REBOOT_NEEDED=true
        else
            log_error "NVIDIA driver installation failed"
            log_info "Installation log saved to: /tmp/nvidia-install.log"
            log_info "Common issues:"
            log_info "  - Secure Boot may need to be disabled in BIOS"
            log_info "  - You may need to sign the kernel modules for Secure Boot"
            log_info "  - Try running installer manually: sudo $DRIVER_FILE"
            log_info ""
            log_info "For latest driver, visit: https://www.nvidia.com/Download/index.aspx"
            NVIDIA_INSTALLED=false
            NVIDIA_REBOOT_NEEDED=true  # Still need reboot for nouveau blacklist
        fi
        
        # Cleanup installer
        rm -f "$DRIVER_FILE"
    else
        log_error "Failed to download NVIDIA driver"
        log_info "Download log saved to: /tmp/nvidia-download.log"
        log_info "You can download and install manually from:"
        log_info "  https://www.nvidia.com/Download/index.aspx"
        NVIDIA_INSTALLED=false
        NVIDIA_REBOOT_NEEDED=false
    fi
    
    # Install NVIDIA Container Toolkit if drivers installed successfully
    if [ "$NVIDIA_INSTALLED" = true ]; then
        if command -v nvidia-container-runtime &> /dev/null; then
            log_warning "NVIDIA Container Toolkit is already installed"
        else
            log_info "Installing NVIDIA Container Toolkit..."
            
            # Install NVIDIA Container Toolkit (with error handling)
            {
                curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
                curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
                  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
                apt-get update && \
                apt-get install -y nvidia-container-toolkit && \
                nvidia-ctk runtime configure --runtime=docker && \
                systemctl restart docker
            } 2>&1 | tee /tmp/nvidia-toolkit-install.log
            
            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                log_success "NVIDIA Container Toolkit installed and configured"
            else
                log_error "NVIDIA Container Toolkit installation failed"
                log_info "Installation log saved to: /tmp/nvidia-toolkit-install.log"
                log_info "Docker will work without GPU support"
                log_info "You can try installing manually later from:"
                log_info "  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
            fi
        fi
    fi
}

#==========================================
# MAIN EXECUTION
#==========================================

# Add trap for cleanup on error
cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Script failed with exit code: $exit_code"
        echo ""
        log_info "Partial setup may have occurred. To resume:"
        log_info "  1. Review error messages above"
        log_info "  2. Fix the issue if possible"
        log_info "  3. Re-run: sudo ./setup-homelab.sh"
        echo ""
        log_info "The script is designed to be idempotent (safe to re-run)"
    fi
}

trap cleanup_on_error EXIT

# Validate script is running from correct location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
if [ ! -f "$REPO_DIR/.env.example" ] || [ ! -d "$REPO_DIR/docker-compose" ]; then
    log_error "This script must be run from the AI-Homelab repository"
    log_info "Expected location: AI-Homelab/scripts/setup-homelab.sh"
    log_info "Current location: $SCRIPT_DIR"
    echo ""
    log_info "Please:"
    log_info "  1. Clone the repository: git clone https://github.com/kelinfoxy/AI-Homelab.git"
    log_info "  2. Enter the directory: cd AI-Homelab"
    log_info "  3. Run: sudo ./scripts/setup-homelab.sh"
    exit 1
fi

# If running as root (not via sudo), handle sudo grant and exit
if [ "$ACTUAL_USER" = "root" ]; then
    handle_root_user
fi

log_info "Setting up AI-Homelab for user: $ACTUAL_USER"
if [ "$AUTO_YES" = true ]; then
    log_info "Running in automated mode (--yes flag enabled)"
fi
echo ""

# Progress tracking
STEPS_TOTAL=9
STEPS_COMPLETED=0

# Execute setup steps in order
step_0_preflight_checks
step_1_update_system
step_2_install_packages
step_3_install_docker
step_4_configure_user_groups
step_5_configure_firewall
step_6_configure_ssh
step_7_generate_authelia_secrets
step_8_create_directories
step_9_create_networks
step_10_nvidia_drivers
show_final_summary

