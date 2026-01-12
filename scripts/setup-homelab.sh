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
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" = "root" ]; then
    log_error "Please run this script with sudo, not as root user"
    exit 1
fi

log_info "Setting up AI-Homelab for user: $ACTUAL_USER"
echo ""

# Step 1: System Update
log_info "Step 1/9: Updating system packages..."
apt-get update && apt-get upgrade -y
log_success "System updated successfully"
echo ""

# Step 2: Install Required Packages
log_info "Step 2/9: Installing required packages..."
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
echo ""

# Step 3: Install Docker
log_info "Step 3/9: Installing Docker..."
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

    log_success "Docker installed successfully ($(docker --version))"
fi
echo ""

# Step 4: Configure User Groups
log_info "Step 4/9: Configuring user groups..."

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
log_info "Step 5/9: Configuring firewall..."
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
log_info "Step 6/9: Configuring SSH server..."
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
log_info "Step 7/9: Checking for NVIDIA GPU..."

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
        # Install NVIDIA driver (non-interactive)
        apt-get install -y nvidia-driver
        log_success "NVIDIA drivers installed"
        NVIDIA_INSTALLED=false
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
log_info "Step 8/9: Creating directory structure..."
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
echo ""

# Step 9: Create Docker Networks
log_info "Step 9/9: Creating Docker networks..."
su - "$ACTUAL_USER" -c "docker network create homelab-network 2>/dev/null || true"
su - "$ACTUAL_USER" -c "docker network create traefik-network 2>/dev/null || true"
su - "$ACTUAL_USER" -c "docker network create media-network 2>/dev/null || true"
su - "$ACTUAL_USER" -c "docker network create dockerproxy-network 2>/dev/null || true"
log_success "Docker networks created"
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
echo "  2. Navigate to your AI-Homelab repository:"
echo "     cd ~/AI-Homelab"
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
