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
# Step 7: Generate Authelia Secrets
log_info "Step 7/9: Generating Authelia authentication secrets..."
echo ""

# Function to generate a secure random secret
generate_secret() {
    openssl rand -hex 64
}

# Check if .env file exists in the repo
ACTUAL_USER_HOME=$(eval echo ~$ACTUAL_USER)
REPO_ENV_FILE="$ACTUAL_USER_HOME/AI-Homelab/.env"
if [ ! -f "$REPO_ENV_FILE" ]; then
    log_error ".env file not found at $REPO_ENV_FILE"
    log_info "Please create .env file from .env.example first"
    exit 1
fi

# Check if secrets are already set (not placeholder values)
CURRENT_JWT=$(grep "^AUTHELIA_JWT_SECRET=" "$REPO_ENV_FILE" | cut -d'=' -f2)
if [ -n "$CURRENT_JWT" ] && [ "$CURRENT_JWT" != "your-jwt-secret-here" ] && [ ${#CURRENT_JWT} -ge 64 ]; then
    log_warning "Authelia secrets appear to already be set in .env"
    read -p "Do you want to regenerate them? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Keeping existing secrets"
    else
        # Generate new secrets
        log_info "Generating new JWT secret..."
        JWT_SECRET=$(generate_secret)
        log_info "Generating new session secret..."
        SESSION_SECRET=$(generate_secret)
        log_info "Generating new storage encryption key..."
        ENCRYPTION_KEY=$(generate_secret)
        
        # Update .env file
        sed -i "s|^AUTHELIA_JWT_SECRET=.*|AUTHELIA_JWT_SECRET=${JWT_SECRET}|" "$REPO_ENV_FILE"
        sed -i "s|^AUTHELIA_SESSION_SECRET=.*|AUTHELIA_SESSION_SECRET=${SESSION_SECRET}|" "$REPO_ENV_FILE"
        sed -i "s|^AUTHELIA_STORAGE_ENCRYPTION_KEY=.*|AUTHELIA_STORAGE_ENCRYPTION_KEY=${ENCRYPTION_KEY}|" "$REPO_ENV_FILE"
        
        log_success "New secrets generated and saved to .env"
    fi
else
    # Generate secrets for first time
    log_info "Generating new JWT secret..."
    JWT_SECRET=$(generate_secret)
    log_info "Generating new session secret..."
    SESSION_SECRET=$(generate_secret)
    log_info "Generating new storage encryption key..."
    ENCRYPTION_KEY=$(generate_secret)
    
    # Update .env file
    sed -i "s|^AUTHELIA_JWT_SECRET=.*|AUTHELIA_JWT_SECRET=${JWT_SECRET}|" "$REPO_ENV_FILE"
    sed -i "s|^AUTHELIA_SESSION_SECRET=.*|AUTHELIA_SESSION_SECRET=${SESSION_SECRET}|" "$REPO_ENV_FILE"
    sed -i "s|^AUTHELIA_STORAGE_ENCRYPTION_KEY=.*|AUTHELIA_STORAGE_ENCRYPTION_KEY=${ENCRYPTION_KEY}|" "$REPO_ENV_FILE"
    
    log_success "Secrets generated and saved to .env"
fi

# Prompt for admin password
echo ""
log_info "Setting up Authelia admin user..."
echo ""
read -p "Enter admin username (default: admin): " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

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

# Generate password hash using Docker
log_info "Generating password hash (this may take a moment)..."
PASSWORD_HASH=$(docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password "$ADMIN_PASSWORD" | grep '^\$argon2')

if [ -z "$PASSWORD_HASH" ]; then
    log_error "Failed to generate password hash"
    exit 1
fi

# Read admin email from .env or prompt
ADMIN_EMAIL=$(grep "^ADMIN_EMAIL=" "$REPO_ENV_FILE" | cut -d'=' -f2)
if [ -z "$ADMIN_EMAIL" ] || [ "$ADMIN_EMAIL" = "admin@example.com" ]; then
    read -p "Enter admin email address: " ADMIN_EMAIL
    sed -i "s|^ADMIN_EMAIL=.*|ADMIN_EMAIL=${ADMIN_EMAIL}|" "$REPO_ENV_FILE"
fi

log_success "Admin user configured: $ADMIN_USER"
log_success "Password hash generated and will be applied during deployment"

# Store the admin credentials for the deployment script
cat > /tmp/authelia_admin_credentials.tmp << EOF
ADMIN_USER=$ADMIN_USER
ADMIN_EMAIL=$ADMIN_EMAIL
PASSWORD_HASH=$PASSWORD_HASH
EOF
chmod 600 /tmp/authelia_admin_credentials.tmp

echo ""

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

# Optional: Detect and Install NVIDIA Drivers (if applicable)
log_info "Optional: Checking for NVIDIA GPU..."

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
        read -p "Do you want to install NVIDIA drivers now? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
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
        else
            log_info "Skipping NVIDIA driver installation"
            log_info "To install later, visit: https://www.nvidia.com/Download/index.aspx"
            NVIDIA_INSTALLED=false
            NVIDIA_REBOOT_NEEDED=false
        fi
    fi
    
    # Check if NVIDIA Container Toolkit is installed
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
    echo ""
else
    log_info "No NVIDIA GPU detected, skipping driver installation"
    NVIDIA_REBOOT_NEEDED=false
    echo ""
fi


# Final Summary
echo ""
echo "=========================================="
log_success "AI-Homelab setup completed successfully!"
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
echo "  1. Log out and log back in for group changes to take effect"
echo "     (or run: newgrp docker)"
echo ""
if [ "${NVIDIA_REBOOT_NEEDED:-false}" = true ]; then
echo "  2. REBOOT YOUR SYSTEM for NVIDIA drivers to load"
echo "     Run: sudo reboot"
echo ""
echo "  3. After reboot, navigate to your AI-Homelab repository:"
else
echo "  2. Navigate to your AI-Homelab repository:"
fi
echo "     cd ~/AI-Homelab"
echo ""
if [ "${NVIDIA_REBOOT_NEEDED:-false}" = true ]; then
echo "  4. Run the deployment script:"
else
echo "  3. Run the deployment script:"
fi
echo "     ./scripts/deploy-homelab.sh"
echo ""
if [ "${NVIDIA_REBOOT_NEEDED:-false}" = true ]; then
echo "  5. Access Dockge at: https://dockge.yourdomain.duckdns.org"
else
echo "  4. Access Dockge at: https://dockge.yourdomain.duckdns.org"
fi
echo "     (Use your configured domain and Authelia credentials)"
echo ""
echo "=========================================="
echo ""
log_info "Setup complete!"
if [ "${NVIDIA_REBOOT_NEEDED:-false}" != true ]; then
    log_info "Please log out and log back in."
fi
