#!/bin/bash
# EZ-Homelab Prerequisites Installation Script

# This script must be run as root or with sudo
# It performs system setup for Docker, networking, and security

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

# Function to generate shared CA for multi-server TLS
generate_shared_ca() {
    local ca_dir="/opt/stacks/core/shared-ca"
    mkdir -p "$ca_dir"
    openssl genrsa -out "$ca_dir/ca-key.pem" 4096
    openssl req -new -x509 -days 365 -key "$ca_dir/ca-key.pem" -sha256 -out "$ca_dir/ca.pem" -subj "/C=US/ST=State/L=City/O=Homelab/CN=Homelab-CA"
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ca_dir"
    log_success "Shared CA generated"
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
    tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "tls": true,
  "tlsverify": true,
  "tlscacert": "$TLS_DIR/ca.pem",
  "tlscert": "$TLS_DIR/server-cert.pem",
  "tlskey": "$TLS_DIR/server-key.pem"
}
EOF
    
    # Update systemd service
    sed -i 's|-H fd://|-H fd:// -H tcp://0.0.0.0:2376|' /lib/systemd/system/docker.service
    
    # Reload and restart Docker
    systemctl daemon-reload
    systemctl restart docker
    
    log_success "Docker TLS configured on port 2376"
}

# Main system setup function
system_setup() {
    echo "║    Installing Prerequisites"
    echo "║"

    # Check if running as root for system setup
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root or with sudo."
        exit 1
    fi

    # Get the actual user who invoked sudo
    ACTUAL_USER=${SUDO_USER:-$USER}

    # Get SERVER_IP from environment or prompt
    if [ -z "$SERVER_IP" ]; then
        read -p "║    Enter the server IP address: " SERVER_IP
    fi

    # Step 1: System Update
    echo -n "║      Step 1/10: Updating system packages...  "
    if apt-get update >/dev/null 2>&1 && apt-get upgrade -y >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        log_error "Failed to update system packages"
    fi

    # Step 2: Install required packages
    echo -n "║      Step 2/10: Installing required packages...  "
    if apt-get install -y curl wget git htop nano vim ufw fail2ban unattended-upgrades apt-listchanges sshpass gettext-base python3 >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        log_error "Failed to install required packages"
    fi

    # Step 3: Install Docker
    echo -n "║      Step 3/10: Installing Docker...  "
    if command -v docker &> /dev/null && docker --version &> /dev/null; then
        echo "✓ (already installed)"
        # Check if user is in docker group
        if ! groups "$ACTUAL_USER" 2>/dev/null | grep -q docker; then
            usermod -aG docker "$ACTUAL_USER" >/dev/null 2>&1
            NEEDS_LOGOUT=true
        fi
        # Check if Docker service is running
        if ! systemctl is-active --quiet docker; then
            systemctl start docker >/dev/null 2>&1
            systemctl enable docker >/dev/null 2>&1
        fi
    else
        if curl -fsSL https://get.docker.com -o /tmp/get-docker.sh >/dev/null 2>&1 && sh /tmp/get-docker.sh >/dev/null 2>&1; then
            usermod -aG docker "$ACTUAL_USER" >/dev/null 2>&1
            NEEDS_LOGOUT=true
            echo "✓"
        else
            echo "✗"
            log_error "Failed to install Docker"
        fi
    fi

    # Step 4: Install Docker Compose
    echo -n "║      Step 4/10: Installing Docker Compose...  "
    if command -v docker-compose &> /dev/null && docker-compose --version &> /dev/null; then
        echo "✓ (already installed)"
    else
        if curl -sL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >/dev/null 2>&1 && chmod +x /usr/local/bin/docker-compose; then
            echo "✓"
        else
            echo "✗"
            log_error "Failed to install Docker Compose"
        fi
    fi

    # Step 5: Generate shared CA for multi-server TLS
    echo -n "║      Step 5/10: Generating shared CA certificate...  "
    if generate_shared_ca >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        log_error "Failed to generate shared CA"
    fi

    # Step 6: Configure Docker TLS
    echo -n "║      Step 6/10: Configuring Docker TLS...  "
    if setup_docker_tls >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        log_error "Failed to configure Docker TLS"
    fi

    # Step 7: Configure UFW firewall
    echo -n "║      Step 7/10: Configuring firewall...  "
    if ufw --force enable >/dev/null 2>&1 && \
       ufw allow ssh >/dev/null 2>&1 && \
       ufw allow 80 >/dev/null 2>&1 && \
       ufw allow 443 >/dev/null 2>&1 && \
       ufw allow 2376/tcp >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        log_error "Failed to configure firewall"
    fi

    # Step 8: Configure automatic updates
    echo -n "║      Step 8/10: Configuring automatic updates...  "
    if dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        log_error "Failed to configure automatic updates"
    fi

    # Step 9: Set proper ownership
    echo -n "║      Step 9/10: Setting directory ownership...  "
    if chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗"
        log_error "Failed to set directory ownership"
    fi

    # Step 10: Create Docker networks
    echo -n "║      Step 10/10: Creating Docker networks...  "
    docker network create homelab-network >/dev/null 2>&1 || true
    docker network create traefik-network >/dev/null 2>&1 || true
    docker network create media-network >/dev/null 2>&1 || true
    echo "✓"

    echo "║"
    echo "║    Prerequisites installation complete!"
    echo "║"

    if [ "$NEEDS_LOGOUT" = true ]; then
        echo "║  ⚠️  Please log out and back in then rerun the script."
        echo "║"
    fi
        echo "╚════════════════════════════════════════════════════════════"
}

# Run the setup
system_setup "$@"