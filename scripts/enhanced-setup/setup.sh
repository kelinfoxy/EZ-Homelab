#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - System Setup and Prerequisites
# Installs Docker and configures system prerequisites for EZ-Homelab

SCRIPT_NAME="setup"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================

# Docker version requirements
MIN_DOCKER_VERSION="20.10.0"
RECOMMENDED_DOCKER_VERSION="24.0.0"

# Required system packages
SYSTEM_PACKAGES=("curl" "wget" "git" "jq" "unzip" "software-properties-common" "apt-transport-https" "ca-certificates" "gnupg" "lsb-release")

# Python packages (for virtual environment)
PYTHON_PACKAGES=("docker-compose" "pyyaml" "requests")

# =============================================================================
# DOCKER INSTALLATION FUNCTIONS
# =============================================================================

# Remove old Docker installations
remove_old_docker() {
    print_info "Removing old Docker installations..."

    # Stop services
    sudo systemctl stop docker docker.socket containerd 2>/dev/null || true

    # Remove packages
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Remove Docker data
    sudo rm -rf /var/lib/docker /var/lib/containerd

    print_success "Old Docker installations removed"
}

# Install Docker using official method
install_docker_official() {
    print_info "Installing Docker Engine (official method)..."

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/"$(lsb_release -si | tr '[:upper:]' '[:lower:]')"/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -si | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package index
    sudo apt update

    # Install Docker Engine
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    print_success "Docker Engine installed"
}

# Install Docker using convenience script (fallback)
install_docker_convenience() {
    print_info "Installing Docker using convenience script..."

    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh

    print_success "Docker installed via convenience script"
}

# Configure Docker daemon
configure_docker_daemon() {
    print_info "Configuring Docker daemon..."

    local daemon_config='{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "iptables": false,
  "bridge": "none",
  "ip-masq": false
}'

    echo "$daemon_config" | sudo tee /etc/docker/daemon.json > /dev/null

    print_success "Docker daemon configured"
}

# Start and enable Docker service
start_docker_service() {
    print_info "Starting Docker service..."

    sudo systemctl enable docker
    sudo systemctl start docker

    # Wait for Docker to be ready
    local retries=30
    while ! docker info >/dev/null 2>&1 && (( retries > 0 )); do
        sleep 1
        ((retries--))
    done

    if ! docker info >/dev/null 2>&1; then
        print_error "Docker service failed to start"
        return 1
    fi

    print_success "Docker service started and enabled"
}

# Add user to docker group
configure_user_permissions() {
    print_info "Configuring user permissions..."

    if ! groups "$EZ_USER" | grep -q docker; then
        sudo usermod -aG docker "$EZ_USER"
        print_warning "User added to docker group. A reboot may be required for changes to take effect."
        print_info "Alternatively, run: newgrp docker"
    else
        print_success "User already in docker group"
    fi
}

# Test Docker installation
test_docker_installation() {
    print_info "Testing Docker installation..."

    # Run hello-world container
    if ! docker run --rm hello-world >/dev/null 2>&1; then
        print_error "Docker test failed"
        return 1
    fi

    # Check Docker version
    local docker_version
    docker_version=$(docker --version | grep -oP 'Docker version \K[^,]+')

    if [[ -z "$docker_version" ]]; then
        print_warning "Could not determine Docker version"
        return 2
    fi

    print_success "Docker $docker_version installed and working"

    # Check Docker Compose V2
    if docker compose version >/dev/null 2>&1; then
        local compose_version
        compose_version=$(docker compose version | grep -oP 'v\K[^ ]+')
        print_success "Docker Compose V2 $compose_version available"
    else
        print_warning "Docker Compose V2 not available"
    fi
}

# =============================================================================
# SYSTEM SETUP FUNCTIONS
# =============================================================================

# Install system packages
install_system_packages() {
    print_info "Installing system packages..."

    # Check if user has sudo access
    if ! sudo -n true 2>/dev/null; then
        print_error "This script requires sudo access to install system packages."
        print_error "Please run this script as a user with sudo privileges, or install the required packages manually:"
        print_error "  sudo apt update && sudo apt install -y ${SYSTEM_PACKAGES[*]}"
        return 1
    fi

    # Update package lists
    print_info "Updating package lists..."
    if ! sudo apt update; then
        print_error "Failed to update package lists. Please check your internet connection and apt configuration."
        return 1
    fi

    local missing_packages=()
    for package in "${SYSTEM_PACKAGES[@]}"; do
        if ! dpkg -l "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        print_info "Installing missing packages: ${missing_packages[*]}"
        if ! sudo apt install -y "${missing_packages[@]}"; then
            print_error "Failed to install required packages: ${missing_packages[*]}"
            print_error "Please install them manually: sudo apt install -y ${missing_packages[*]}"
            return 1
        fi
    else
        print_info "All required packages are already installed"
    fi

    print_success "System packages installed"
}

# Set up Python virtual environment
setup_python_environment() {
    print_info "Setting up Python virtual environment..."

    local venv_dir="$HOME/.ez-homelab-venv"

    # Create virtual environment
    if [[ ! -d "$venv_dir" ]]; then
        python3 -m venv "$venv_dir"
    fi

    # Activate and install packages
    source "$venv_dir/bin/activate"

    # Upgrade pip
    pip install --upgrade pip

    # Install required packages
    if $IS_ARM64; then
        # Use PiWheels for ARM64
        pip install --extra-index-url https://www.piwheels.org/simple "${PYTHON_PACKAGES[@]}"
    else
        pip install "${PYTHON_PACKAGES[@]}"
    fi

    # Deactivate
    deactivate

    print_success "Python virtual environment configured"
}

# Configure system settings
configure_system_settings() {
    print_info "Configuring system settings..."

    # Increase file watchers (for large deployments)
    echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf >/dev/null
    sudo sysctl -p >/dev/null 2>&1

    # Configure journald for better logging
    sudo mkdir -p /etc/systemd/journald.conf.d
    cat << EOF | sudo tee /etc/systemd/journald.conf.d/ez-homelab.conf >/dev/null
[Journal]
Storage=persistent
SystemMaxUse=100M
RuntimeMaxUse=50M
EOF

    print_success "System settings configured"
}

# Create required directories
create_directories() {
    print_info "Creating required directories..."

    sudo mkdir -p /opt/stacks
    sudo chown "$EZ_USER:$EZ_USER" /opt/stacks

    mkdir -p "$LOG_DIR"

    print_success "Directories created"
}

# =============================================================================
# NVIDIA GPU SETUP (OPTIONAL)
# =============================================================================

# Check if NVIDIA setup is needed
check_nvidia_setup_needed() {
    command_exists nvidia-smi && nvidia-smi >/dev/null 2>&1
}

# Install NVIDIA drivers (if requested)
install_nvidia_drivers() {
    if $non_interactive; then
        print_info "Skipping NVIDIA setup (non-interactive mode)"
        return 0
    fi

    if ! ui_yesno "NVIDIA GPU detected. Install NVIDIA drivers and Docker GPU support?"; then
        print_info "Skipping NVIDIA setup"
        return 0
    fi

    print_info "Installing NVIDIA drivers..."

    # Add NVIDIA repository
    wget https://developer.download.nvidia.com/compute/cuda/repos/"$(lsb_release -si | tr '[:upper:]' '[:lower:]')""$(lsb_release -sr | tr -d '.')"/x86_64/cuda-keyring_1.0-1_all.deb
    sudo dpkg -i cuda-keyring_1.0-1_all.deb
    rm cuda-keyring_1.0-1_all.deb

    sudo apt update

    # Install NVIDIA driver
    sudo apt install -y nvidia-driver-525 nvidia-docker2

    # Configure Docker for NVIDIA
    sudo systemctl restart docker

    print_success "NVIDIA drivers installed"
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local skip_docker=false
    local skip_nvidia=false
    local non_interactive=false
    local verbose=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                ui_show_help "$SCRIPT_NAME"
                exit 0
                ;;
            --skip-docker)
                skip_docker=true
                ;;
            --skip-nvidia)
                skip_nvidia=true
                ;;
            --no-ui)
                non_interactive=true
                ;;
            -v|--verbose)
                verbose=true
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
        shift
    done

    # Initialize script
    init_script "$SCRIPT_NAME"

    if $verbose; then
        set -x
    fi

    print_info "Starting EZ-Homelab system setup..."
    print_info "This will install Docker and configure your system for EZ-Homelab."

    # Run pre-flight checks first (allow warnings)
    local preflight_exit=0
    "$(dirname "${BASH_SOURCE[0]}")/preflight.sh" --no-ui || preflight_exit=$?
    if [[ $preflight_exit -eq 1 ]]; then
        print_error "Pre-flight checks failed with critical errors. Please resolve issues before proceeding."
        exit 1
    elif [[ $preflight_exit -eq 2 ]]; then
        print_warning "Pre-flight checks completed with warnings. Setup will proceed and install missing dependencies."
    fi

    # Install system packages
    if ! run_with_progress "Installing system packages" "install_system_packages"; then
        print_error "Failed to install system packages. This is required for Docker installation."
        print_error "Please resolve the issue and re-run this script."
        print_error "Common solutions:"
        print_error "  - Ensure you have sudo access: sudo -l"
        print_error "  - Check internet connection: ping 8.8.8.8"
        print_error "  - Update package lists: sudo apt update"
        print_error "  - Install packages manually: sudo apt install -y ${SYSTEM_PACKAGES[*]}"
        exit 1
    fi

    # Set up Python environment
    run_with_progress "Setting up Python environment" "setup_python_environment"

    # Configure system settings
    run_with_progress "Configuring system settings" "configure_system_settings"

    # Create directories
    run_with_progress "Creating directories" "create_directories"

    # Install Docker (unless skipped)
    if ! $skip_docker; then
        run_with_progress "Removing old Docker installations" "remove_old_docker"
        run_with_progress "Installing Docker" "install_docker_official"
        run_with_progress "Configuring Docker daemon" "configure_docker_daemon"
        run_with_progress "Starting Docker service" "start_docker_service"
        run_with_progress "Configuring user permissions" "configure_user_permissions"
        run_with_progress "Testing Docker installation" "test_docker_installation"
    else
        print_info "Skipping Docker installation (--skip-docker)"
    fi

    # NVIDIA setup (if applicable and not skipped)
    if ! $skip_nvidia && check_nvidia_setup_needed; then
        run_with_progress "Installing NVIDIA drivers" "install_nvidia_drivers"
    fi

    echo ""
    print_success "EZ-Homelab system setup complete!"

    if ! $skip_docker && ! groups "$EZ_USER" | grep -q docker; then
        print_warning "IMPORTANT: Please reboot your system for Docker group changes to take effect."
        print_info "Alternatively, run: newgrp docker"
        print_info "Then re-run this script or proceed to the next step."
    else
        print_info "You can now proceed to the pre-deployment wizard:"
        print_info "  ./pre-deployment-wizard.sh"
    fi

    exit 0
}

# Run main function
main "$@"