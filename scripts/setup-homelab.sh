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

log_info "Setting up AI-Homelab for user: $ACTUAL_USER"
echo ""

# Step 0: Pre-flight validation
log_info "Step 0/10: Running pre-flight checks..."

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
echo ""

# Step 1: System Update
log_info "Step 1/10: Updating system packages..."
apt-get update && apt-get upgrade -y
log_success "System updated successfully"
echo ""

# Step 2: Install Required Packages
log_info "Step 2/10: Installing required packages..."
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

    log_success "Docker installed successfully ($(docker --version))"
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
# Step 7: Generate Authelia Secrets
log_info "Step 7/10: Generating Authelia authentication secrets..."
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

# Generate hash and write DIRECTLY to file to avoid bash variable expansion of $ characters
# The argon2 hash contains multiple $ characters that bash would try to expand as variables
timeout 60 docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password "$ADMIN_PASSWORD" 2>&1 | \
    grep -oP 'Digest: \K\$argon2.*' > /tmp/authelia_password_hash.tmp

HASH_EXIT_CODE=$?

if [ $HASH_EXIT_CODE -eq 124 ]; then
    log_error "Password hash generation timed out after 60 seconds"
    log_info "This is unusual. Please check:"
    log_info "  1. System resources: top or htop"
    log_info "  2. Docker status: docker ps"
    log_info "  3. Try manually: docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2"
    exit 1
elif [ $HASH_EXIT_CODE -ne 0 ] || [ ! -s /tmp/authelia_password_hash.tmp ]; then
    log_error "Failed to generate password hash"
    log_info "You can generate the hash manually after setup:"
    log_info "  docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2"
    log_info "  Then edit: /opt/stacks/core/authelia/users_database.yml"
    exit 1
fi

chmod 600 /tmp/authelia_password_hash.tmp
log_success "Password hash generated successfully"

# Read admin email from .env or prompt
ADMIN_EMAIL=$(grep "^ADMIN_EMAIL=" "$REPO_ENV_FILE" | cut -d'=' -f2)
if [ -z "$ADMIN_EMAIL" ] || [ "$ADMIN_EMAIL" = "admin@example.com" ]; then
    read -p "Enter admin email address: " ADMIN_EMAIL
    sed -i "s|^ADMIN_EMAIL=.*|ADMIN_EMAIL=${ADMIN_EMAIL}|" "$REPO_ENV_FILE"
fi

log_success "Admin user configured: $ADMIN_USER"
log_success "Password hash generated and will be applied during deployment"

# Store the admin credentials for the deployment script
# Password hash is already in /tmp/authelia_password_hash.tmp (written directly from Docker)
# This avoids bash variable expansion issues with $ characters in argon2 hashes
{
    echo "ADMIN_USER=$ADMIN_USER"
    echo "ADMIN_EMAIL=$ADMIN_EMAIL"
    echo "ADMIN_PASSWORD=$ADMIN_PASSWORD"
} > /tmp/authelia_admin_credentials.tmp
chmod 600 /tmp/authelia_admin_credentials.tmp

log_info "Credentials saved for deployment script"
echo ""

# Step 8: Create Directory Structure
log_info "Step 8/10: Creating directory structure..."
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
log_info "Step 9/10: Creating Docker networks..."
su - "$ACTUAL_USER" -c "docker network create homelab-network 2>/dev/null || true"
su - "$ACTUAL_USER" -c "docker network create traefik-network 2>/dev/null || true"
su - "$ACTUAL_USER" -c "docker network create media-network 2>/dev/null || true"
su - "$ACTUAL_USER" -c "docker network create dockerproxy-network 2>/dev/null || true"
log_success "Docker networks created"
echo ""

# Step 10: Optional - Detect and Install NVIDIA Drivers
log_info "Step 10/10 (Optional): Checking for NVIDIA GPU..."

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
echo "  3. After reboot, run the deployment script to deploy your homelab"
else
echo "  2. Run the deployment script to deploy your homelab"
fi
echo ""
echo "=========================================="
echo ""
log_info "Setup complete!"
echo ""

# Prompt to run deployment script
if [ "${NVIDIA_REBOOT_NEEDED:-false}" != true ]; then
    echo ""
    read -p "Would you like to run the deployment script now? [Y/n]: " -n 1 -r RUN_DEPLOY
    echo ""
    
    # Default to yes if empty
    RUN_DEPLOY=${RUN_DEPLOY:-Y}
    
    if [[ $RUN_DEPLOY =~ ^[Yy]$ ]]; then
        log_info "Starting deployment script..."
        echo ""
        
        # Check if user needs to log out first for Docker group
        if ! groups "$ACTUAL_USER" | grep -q docker; then
            log_warning "You need to log out and back in for Docker group permissions."
            log_info "Run this command after logging back in:"
            echo ""
            echo "  cd ~/AI-Homelab && ./scripts/deploy-homelab.sh"
            echo ""
        else
            # Run deployment script as the actual user
            cd "$(dirname "$0")/.." || exit 1
            su - "$ACTUAL_USER" -c "cd $PWD && ./scripts/deploy-homelab.sh"
        fi
    else
        log_info "Deployment skipped. Run it manually when ready:"
        echo ""
        echo "  cd ~/AI-Homelab"
        echo "  ./scripts/deploy-homelab.sh"
        echo ""
    fi
else
    log_info "Please reboot your system for NVIDIA drivers, then run:"
    echo ""
    echo "  cd ~/AI-Homelab"
    echo "  ./scripts/deploy-homelab.sh"
    echo ""
fi

