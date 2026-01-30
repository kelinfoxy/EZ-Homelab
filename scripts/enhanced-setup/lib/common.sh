#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Common Library
# Shared variables, utility functions, and constants

set -euo pipefail

# =============================================================================
# SHARED VARIABLES
# =============================================================================

# Repository and paths
EZ_HOME="${EZ_HOME:-/home/kelin/EZ-Homelab}"
STACKS_DIR="${STACKS_DIR:-/opt/stacks}"
LOG_DIR="${LOG_DIR:-$HOME/.ez-homelab/logs}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# User and system
EZ_USER="${EZ_USER:-$USER}"
EZ_UID="${EZ_UID:-$(id -u)}"
EZ_GID="${EZ_GID:-$(id -g)}"

# Architecture detection
ARCH="$(uname -m)"
IS_ARM64=false
[[ "$ARCH" == "aarch64" ]] && IS_ARM64=true

# System information
OS_NAME="$(lsb_release -si 2>/dev/null | tail -1 || echo "Unknown")"
OS_VERSION="$(lsb_release -sr 2>/dev/null | tail -1 || echo "Unknown")"
KERNEL_VERSION="$(uname -r)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Initialize logging
init_logging() {
    local script_name="${1:-unknown}"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/${script_name}.log"
    touch "$LOG_FILE"
}

# Log message with timestamp and level
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp [$SCRIPT_NAME] $level: $message" >> "$LOG_FILE"
    echo "$timestamp [$SCRIPT_NAME] $level: $message" >&2
}

# Convenience logging functions
log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }
log_debug() { log "DEBUG" "$1"; }

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Get available disk space in GB
get_disk_space() {
    local path="${1:-/}"
    df -BG "$path" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//' || echo "0"
}

# Get total memory in MB
get_total_memory() {
    free -m 2>/dev/null | awk 'NR==2{printf "%.0f", $2}' || echo "0"
}

# Get available memory in MB
get_available_memory() {
    free -m 2>/dev/null | awk 'NR==2{printf "%.0f", $7}' || echo "0"
}

# Check if service is running (systemd)
service_running() {
    local service="$1"
    systemctl is-active --quiet "$service" 2>/dev/null
}

# Check if Docker is installed and running
docker_available() {
    command_exists docker && service_running docker
}

# Check network connectivity
check_network() {
    ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1
}

# Validate YAML file syntax
validate_yaml() {
    local file="$1"
    if command_exists python3 && python3 -c "import yaml" 2>/dev/null; then
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
    elif command_exists yq; then
        yq eval '.' "$file" >/dev/null 2>/dev/null
    elif command_exists docker && docker compose version >/dev/null 2>&1; then
        # Fallback to docker compose config
        local dir=$(dirname "$file")
        local base=$(basename "$file")
        (cd "$dir" && docker compose -f "$base" config >/dev/null 2>&1)
    else
        # No validation tools available, assume valid
        return 0
    fi
}

# Backup file with timestamp
backup_file() {
    local file="$1"
    local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup"
    log_info "Backed up $file to $backup"
}

# Clean up old backups (keep last 5)
cleanup_backups() {
    local file="$1"
    local backups
    mapfile -t backups < <(ls -t "${file}.bak."* 2>/dev/null | tail -n +6)
    for backup in "${backups[@]}"; do
        rm -f "$backup"
        log_debug "Cleaned up old backup: $backup"
    done
}

# Display colored message
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Display success message
print_success() {
    print_color "$GREEN" "✓ $1"
}

# Display warning message
print_warning() {
    print_color "$YELLOW" "⚠ $1"
}

# Display error message
print_error() {
    print_color "$RED" "✗ $1"
}

# Display info message
print_info() {
    print_color "$BLUE" "ℹ $1"
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Validate OS compatibility
validate_os() {
    case "$OS_NAME" in
        "Ubuntu"|"Debian"|"Raspbian")
            if [[ "$OS_NAME" == "Ubuntu" && "$OS_VERSION" =~ ^(20|22|24) ]]; then
                return 0
            elif [[ "$OS_NAME" == "Debian" && "$OS_VERSION" =~ ^(11|12) ]]; then
                return 0
            elif [[ "$OS_NAME" == "Raspbian" ]]; then
                return 0
            fi
            ;;
    esac
    return 1
}

# Validate architecture
validate_arch() {
    [[ "$ARCH" == "x86_64" || "$ARCH" == "aarch64" ]]
}

# Validate minimum requirements
validate_requirements() {
    local min_disk=20  # GB
    local min_memory=1024  # MB

    local disk_space
    disk_space=$(get_disk_space)
    local total_memory
    total_memory=$(get_total_memory)

    if (( disk_space < min_disk )); then
        log_error "Insufficient disk space: ${disk_space}GB available, ${min_disk}GB required"
        return 1
    fi

    if (( total_memory < min_memory )); then
        log_error "Insufficient memory: ${total_memory}MB available, ${min_memory}MB required"
        return 1
    fi

    return 0
}

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================

# Check if required packages are installed
check_dependencies() {
    local deps=("curl" "wget" "jq" "git")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing dependencies: ${missing[*]}"
        return 1
    fi

    return 0
}

# Install missing dependencies
install_dependencies() {
    if ! check_dependencies; then
        log_info "Installing missing dependencies..."
        if is_root; then
            apt update && apt install -y curl wget jq git
        else
            sudo apt update && sudo apt install -y curl wget jq git
        fi
    fi
}

# =============================================================================
# SCRIPT INITIALIZATION
# =============================================================================

# Initialize script environment
init_script() {
    local script_name="$1"
    SCRIPT_NAME="$script_name"
    init_logging "$script_name"

    log_info "Starting $script_name on $OS_NAME $OS_VERSION ($ARCH)"

    # Set trap for cleanup
    trap 'log_error "Script interrupted"; exit 1' INT TERM

    # Validate basic requirements
    if ! validate_os; then
        print_error "Unsupported OS: $OS_NAME $OS_VERSION"
        log_error "Unsupported OS: $OS_NAME $OS_VERSION"
        exit 1
    fi

    if ! validate_arch; then
        print_error "Unsupported architecture: $ARCH"
        log_error "Unsupported architecture: $ARCH"
        exit 1
    fi
}

# =============================================================================
# DOCKER UTILITIES
# =============================================================================

# Check if Docker is available
docker_available() {
    command_exists "docker" && docker info >/dev/null 2>&1
}

# Get services in a stack
get_stack_services() {
    local stack="$1"
    local compose_file="$EZ_HOME/docker-compose/$stack/docker-compose.yml"

    if [[ ! -f "$compose_file" ]]; then
        return 1
    fi

    # Extract service names from docker-compose.yml
    # Look for lines that start at column 0 followed by a service name
    sed -n '/^services:/,/^[^ ]/p' "$compose_file" 2>/dev/null | \
    grep '^  [a-zA-Z0-9_-]\+:' | \
    sed 's/^\s*//' | sed 's/:.*$//' || true
}

# Check if a service is running
is_service_running() {
    local service="$1"

    docker ps --filter "name=$service" --filter "status=running" --format "{{.Names}}" | grep -q "^${service}$"
}

# Find all available services across all stacks
find_all_services() {
    local services=()
    
    # Get all docker-compose directories
    local compose_dirs
    mapfile -t compose_dirs < <(find "$EZ_HOME/docker-compose" -name "docker-compose.yml" -type f -exec dirname {} \; 2>/dev/null)
    
    for dir in "${compose_dirs[@]}"; do
        local stack_services
        mapfile -t stack_services < <(get_stack_services "$(basename "$dir")")
        
        for service in "${stack_services[@]}"; do
            # Avoid duplicates
            if [[ ! " ${services[*]} " =~ " ${service} " ]]; then
                services+=("$service")
            fi
        done
    done
    
    printf '%s\n' "${services[@]}" | sort
}

# Find which stack a service belongs to
find_service_stack() {
    local service="$1"
    
    local compose_dirs
    mapfile -t compose_dirs < <(find "$EZ_HOME/docker-compose" -name "docker-compose.yml" -type f -exec dirname {} \; 2>/dev/null)
    
    for dir in "${compose_dirs[@]}"; do
        local stack_services
        mapfile -t stack_services < <(get_stack_services "$(basename "$dir")")
        
        for stack_service in "${stack_services[@]}"; do
            if [[ "$stack_service" == "$service" ]]; then
                echo "$dir"
                return 0
            fi
        done
    done
    
    return 1
}

# Get service compose file
get_service_compose_file() {
    local service="$1"
    local stack_dir
    
    stack_dir=$(find_service_stack "$service")
    [[ -n "$stack_dir" ]] && echo "$stack_dir/docker-compose.yml"
}