#!/bin/bash
# AI-Homelab First-Run Setup Script
# This script prepares a fresh Debian installation for homelab deployment
# Run as: sudo ./setup-homelab.sh

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
    log_error "Please run as root (use: sudo ./setup-homelab.sh)"
    exit 1
fi

# Get the actual user who invoked sudo
ACTUAL_USER=${SUDO_USER:-$USER}

# Get script directory and repo directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Step 1: System Update
log_info "Step 1/10: Updating system packages..."
apt-get update && apt-get upgrade -y
log_success "System updated successfully"
echo ""

# Step 2: Install Required Packages
log_info "Step 2/10: Installing required packages..."
# Update package list first to avoid issues
apt-get update

# Install packages with error handling
if ! apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    openssh-server \
    sudo \
    pciutils \
    net-tools \
    ufw; then
    log_warning "Some packages may have failed to install. Attempting software-properties-common separately..."
    apt-get install -y software-properties-common || log_warning "software-properties-common installation failed - may need manual intervention"
else
    # Try to install software-properties-common separately as it sometimes causes issues
    apt-get install -y software-properties-common || log_warning "software-properties-common installation failed - continuing anyway"
fi

log_success "Required packages installed"
echo ""

# Step 3: Install Docker
log_info "Step 3/10: Installing Docker..."
if command -v docker &> /dev/null && docker --version &> /dev/null; then
    log_warning "Docker is already installed ($(docker --version))"
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

    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker

    log_success "Docker installed and service started ($(docker --version))"
fi
echo ""

# Step 4: Configure User Groups
log_info "Step 4/10: Configuring user groups..."

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
echo ""

# Step 5: Configure Firewall
log_info "Step 5/10: Configuring firewall..."
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
echo ""

# Step 6: Configure SSH
log_info "Step 6/10: Configuring SSH server..."
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
echo ""

# Step 7: Detect and Install NVIDIA Drivers (if applicable)
log_info "Step 7/10: Checking for NVIDIA GPU..."

# Detect NVIDIA GPU
if lspci | grep -i nvidia > /dev/null; then
    log_info "NVIDIA GPU detected:"
    lspci | grep -i nvidia
    echo ""
    
    # Check if NVIDIA drivers are already installed
    if nvidia-smi &> /dev/null; then
        log_warning "NVIDIA drivers are already installed"
        NVIDIA_INSTALLED=true
    else
        log_info "Installing NVIDIA drivers..."
        # Install kernel headers first (required for NVIDIA driver)
        apt-get install -y linux-headers-amd64
        # Install NVIDIA driver (non-interactive)
        if apt-get install -y nvidia-driver; then
            log_success "NVIDIA drivers installed"
            NVIDIA_INSTALLED=false
        else
            log_warning "NVIDIA driver installation failed. You may need to install manually after reboot."
            log_info "Try: sudo apt update && sudo apt install nvidia-driver"
            NVIDIA_INSTALLED=false  # Still set to false to trigger reboot reminder
        fi
    fi
    
    # Check if NVIDIA Container Toolkit is installed
    if command -v nvidia-container-runtime &> /dev/null; then
        log_warning "NVIDIA Container Toolkit is already installed"
    else
        log_info "Installing NVIDIA Container Toolkit..."
        # Install NVIDIA Container Toolkit
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
          sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
          tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        
        apt-get update
        apt-get install -y nvidia-container-toolkit
        
        # Configure Docker to use NVIDIA runtime
        nvidia-ctk runtime configure --runtime=docker
        systemctl restart docker
        
        log_success "NVIDIA Container Toolkit installed and configured"
    fi
    
    if [ "$NVIDIA_INSTALLED" = false ]; then
        log_warning "NVIDIA drivers were installed. A reboot may be required for changes to take effect."
    fi
    echo ""
else
    log_info "No NVIDIA GPU detected, skipping driver installation"
    echo ""
fi

# Step 8: Create Directory Structure
log_info "Step 8/10: Creating directory structure..."
mkdir -p /opt/stacks
mkdir -p /opt/dockge/data
mkdir -p /mnt/media/{movies,tv,music,books,photos}
mkdir -p /mnt/downloads/{complete,incomplete}
mkdir -p /mnt/backups
mkdir -p /mnt/surveillance
mkdir -p /mnt/git

# Set ownership with error handling
log_info "Setting directory ownership to user: $ACTUAL_USER..."
if ! chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks 2>/dev/null; then
    log_warning "Failed to set ownership for /opt/stacks - you may need to run: sudo chown -R $ACTUAL_USER:$ACTUAL_USER /opt/stacks"
fi
if ! chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/dockge 2>/dev/null; then
    log_warning "Failed to set ownership for /opt/dockge - you may need to run: sudo chown -R $ACTUAL_USER:$ACTUAL_USER /opt/dockge"
fi
if ! chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/media 2>/dev/null; then
    log_warning "Failed to set ownership for /mnt/media - you may need to run: sudo chown -R $ACTUAL_USER:$ACTUAL_USER /mnt/media"
fi
if ! chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/downloads 2>/dev/null; then
    log_warning "Failed to set ownership for /mnt/downloads - you may need to run: sudo chown -R $ACTUAL_USER:$ACTUAL_USER /mnt/downloads"
fi
if ! chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/backups 2>/dev/null; then
    log_warning "Failed to set ownership for /mnt/backups - you may need to run: sudo chown -R $ACTUAL_USER:$ACTUAL_USER /mnt/backups"
fi
if ! chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/surveillance 2>/dev/null; then
    log_warning "Failed to set ownership for /mnt/surveillance - you may need to run: sudo chown -R $ACTUAL_USER:$ACTUAL_USER /mnt/surveillance"
fi
if ! chown -R "$ACTUAL_USER:$ACTUAL_USER" /mnt/git 2>/dev/null; then
    log_warning "Failed to set ownership for /mnt/git - you may need to run: sudo chown -R $ACTUAL_USER:$ACTUAL_USER /mnt/git"
fi

log_success "Directory structure created"
echo ""

# Step 9: Create Docker Networks
log_info "Step 9/10: Creating Docker networks..."
su - "$ACTUAL_USER" -c "docker network create homelab-network 2>/dev/null || true"
su - "$ACTUAL_USER" -c "docker network create traefik-network 2>/dev/null || true"
su - "$ACTUAL_USER" -c "docker network create media-network 2>/dev/null || true"
su - "$ACTUAL_USER" -c "docker network create dockerproxy-network 2>/dev/null || true"
log_success "Docker networks created"
echo ""

# Step 10: Generate Authelia Secrets
log_info "Step 10/10: Generating Authelia secrets..."

# Check if .env file exists, create from example if needed
if [ ! -f "$REPO_DIR/.env" ]; then
    if [ -f "$REPO_DIR/.env.example" ]; then
        cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
        log_info ".env file created from .env.example"
    else
        log_error ".env and .env.example files not found in $REPO_DIR"
        exit 1
    fi
fi

# Generate cryptographic secrets
log_info "Generating Authelia JWT secret..."
AUTHELIA_JWT_SECRET=$(openssl rand -hex 64)

log_info "Generating Authelia session secret..."
AUTHELIA_SESSION_SECRET=$(openssl rand -hex 64)

log_info "Generating Authelia storage encryption key..."
AUTHELIA_STORAGE_ENCRYPTION_KEY=$(openssl rand -hex 64)

# Check for existing default credentials in .env
source "$REPO_DIR/.env"
USE_DEFAULTS=false
if [ -n "$DEFAULT_USER" ] && [ -n "$DEFAULT_PASSWORD" ] && [ -n "$DEFAULT_EMAIL" ]; then
    echo ""
    echo "Found existing default credentials in .env:"
    echo "  User: $DEFAULT_USER"
    echo "  Email: $DEFAULT_EMAIL"
    echo "  Password: [hidden]"
    echo ""
    read -p "Use these for Authelia admin? (Y/n): " USE_DEFAULT
    USE_DEFAULT=${USE_DEFAULT:-y}
    if [[ "$USE_DEFAULT" =~ ^[Yy]$ ]]; then
        USE_DEFAULTS=true
        ADMIN_USER=$DEFAULT_USER
        ADMIN_EMAIL=$DEFAULT_EMAIL
        ADMIN_PASSWORD=$DEFAULT_PASSWORD
    fi
fi

if [ "$USE_DEFAULTS" = false ]; then
    # Prompt for admin credentials
    log_info "Configuring Authelia admin user..."
    echo ""
    echo "Authelia Admin Configuration:"
    echo "=============================="

    read -p "Admin username (default: admin): " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}

    read -p "Admin email: " ADMIN_EMAIL
    while [ -z "$ADMIN_EMAIL" ]; do
        log_error "Email is required"
        read -p "Admin email: " ADMIN_EMAIL
    done

    # Prompt for password with confirmation
    while true; do
        read -s -p "Admin password: " ADMIN_PASSWORD
        echo ""
        read -s -p "Confirm password: " ADMIN_PASSWORD_CONFIRM
        echo ""
        if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
            break
        else
            log_error "Passwords do not match. Please try again."
        fi
    done
fi

# Generate password hash using Authelia Docker image
log_info "Generating password hash (this may take 30-60 seconds)..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running. Please check Docker installation."
    exit 1
fi

# Pull the Authelia image first
log_info "Pulling Authelia image..."
if ! docker pull authelia/authelia:latest > /dev/null 2>&1; then
    log_error "Failed to pull Authelia image. Please check internet connectivity."
    exit 1
fi

# Generate the hash
ADMIN_PASSWORD_HASH=$(docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password "$ADMIN_PASSWORD" 2>&1 | grep -o '"[^"]*"' | tr -d '"')

if [ -z "$ADMIN_PASSWORD_HASH" ]; then
    log_error "Failed to generate password hash. Please check Docker connectivity."
    log_info "Debug: Trying manual hash generation..."
    # Fallback: generate a basic hash using openssl (not recommended for production)
    ADMIN_PASSWORD_HASH=$(echo -n "$ADMIN_PASSWORD" | openssl dgst -sha256 | cut -d' ' -f2)
    if [ -n "$ADMIN_PASSWORD_HASH" ]; then
        log_warning "Using fallback hash method. Please regenerate with proper Authelia hash later."
    else
        exit 1
    fi
fi

# Update .env file with generated values
log_info "Updating .env file with generated secrets..."

# Use sed to replace the placeholder values
sed -i "s/AUTHELIA_JWT_SECRET=.*/AUTHELIA_JWT_SECRET=$AUTHELIA_JWT_SECRET/" "$REPO_DIR/.env"
sed -i "s/AUTHELIA_SESSION_SECRET=.*/AUTHELIA_SESSION_SECRET=$AUTHELIA_SESSION_SECRET/" "$REPO_DIR/.env"
sed -i "s/AUTHELIA_STORAGE_ENCRYPTION_KEY=.*/AUTHELIA_STORAGE_ENCRYPTION_KEY=$AUTHELIA_STORAGE_ENCRYPTION_KEY/" "$REPO_DIR/.env"

# Uncomment and set admin credentials
sed -i "s/# AUTHELIA_ADMIN_USER=.*/AUTHELIA_ADMIN_USER=$ADMIN_USER/" "$REPO_DIR/.env"
sed -i "s/# AUTHELIA_ADMIN_EMAIL=.*/AUTHELIA_ADMIN_EMAIL=$ADMIN_EMAIL/" "$REPO_DIR/.env"
sed -i "s/# AUTHELIA_ADMIN_PASSWORD=.*/AUTHELIA_ADMIN_PASSWORD=$ADMIN_PASSWORD_HASH/" "$REPO_DIR/.env"

log_success "Authelia secrets and admin credentials generated"
echo ""

# Final Summary
echo ""
echo "=========================================="
log_success "AI-Homelab setup completed successfully!"
echo "=========================================="
echo ""
log_info "Next steps:"
echo ""
echo "  1. Log out and log back in for group changes to take effect"
echo "     (or run: newgrp docker)"
echo ""
echo "  2. Navigate to your EZ-Homelab repository:"
echo "     cd ~/EZ-Homelab"
echo ""
echo "  3. Edit the .env file with your configuration:"
echo "     cp .env.example .env"
echo "     nano .env"
echo ""
echo "  4. Run the deployment script:"
echo "     ./scripts/deploy-homelab.sh"
echo ""
echo "  5. Access Dockge at: https://dockge.yourdomain.duckdns.org"
echo "     (Use your configured domain and Authelia credentials)"
echo ""
echo "=========================================="

if lspci | grep -i nvidia > /dev/null && [ "$NVIDIA_INSTALLED" = false ]; then
    echo ""
    log_warning "REMINDER: Reboot required for NVIDIA driver changes"
    echo "  Run: sudo reboot"
    echo "=========================================="
fi

echo ""
log_info "Setup complete! Please log out and log back in."
