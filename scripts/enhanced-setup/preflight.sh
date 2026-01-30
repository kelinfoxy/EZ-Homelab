#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Pre-Flight System Validation
# Performs comprehensive system checks before EZ-Homelab deployment

SCRIPT_NAME="preflight"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================

# Minimum requirements
MIN_DISK_SPACE=20  # GB
MIN_MEMORY=1024    # MB
MIN_CPU_CORES=2

# Required packages (will be installed by setup.sh if missing)
REQUIRED_PACKAGES=("curl" "wget" "git" "jq")

# Optional packages (recommended but not required)
OPTIONAL_PACKAGES=("htop" "ncdu" "tmux" "unzip")

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Check OS compatibility
check_os_compatibility() {
    print_info "Checking OS compatibility..."

    if ! validate_os; then
        print_error "Unsupported OS: $OS_NAME $OS_VERSION"
        print_error "Supported: Ubuntu 20.04+, Debian 11+, Raspberry Pi OS"
        return 1
    fi

    print_success "OS: $OS_NAME $OS_VERSION ($ARCH)"
    return 0
}

# Check system resources
check_system_resources() {
    print_info "Checking system resources..."

    local errors=0

    # Check disk space
    local disk_space
    disk_space=$(get_disk_space)
    if (( disk_space < MIN_DISK_SPACE )); then
        print_error "Insufficient disk space: ${disk_space}GB available, ${MIN_DISK_SPACE}GB required"
        ((errors++))
    else
        print_success "Disk space: ${disk_space}GB available"
    fi

    # Check memory
    local total_memory
    total_memory=$(get_total_memory)
    if (( total_memory < MIN_MEMORY )); then
        print_error "Insufficient memory: ${total_memory}MB available, ${MIN_MEMORY}MB required"
        ((errors++))
    else
        print_success "Memory: ${total_memory}MB total"
    fi

    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    if (( cpu_cores < MIN_CPU_CORES )); then
        print_warning "Low CPU cores: ${cpu_cores} available, ${MIN_CPU_CORES} recommended"
    else
        print_success "CPU cores: $cpu_cores"
    fi

    return $errors
}

# Check network connectivity
check_network_connectivity() {
    print_info "Checking network connectivity..."

    if ! check_network; then
        print_error "No internet connection detected"
        print_error "Please check your network configuration"
        return 1
    fi

    print_success "Internet connection available"

    # Check DNS resolution
    if ! nslookup github.com >/dev/null 2>&1; then
        print_warning "DNS resolution may be slow or failing"
    else
        print_success "DNS resolution working"
    fi

    return 0
}

# Check required packages (will be installed by setup.sh if missing)
check_required_packages() {
    print_info "Checking required packages..."

    local missing=()
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! command_exists "$package"; then
            missing+=("$package")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_warning "Required packages missing: ${missing[*]}"
        print_info "These will be installed automatically by setup.sh"
        return 2  # Warning, not error
    fi

    print_success "All required packages installed"
    return 0
}

# Check optional packages
check_optional_packages() {
    print_info "Checking optional packages..."

    local missing=()
    for package in "${OPTIONAL_PACKAGES[@]}"; do
        if ! command_exists "$package"; then
            missing+=("$package")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_warning "Optional packages not installed: ${missing[*]}"
        print_info "Consider installing for better experience: sudo apt install -y ${missing[*]}"
    else
        print_success "All optional packages available"
    fi

    return 0
}

# Check Docker installation
check_docker_installation() {
    print_info "Checking Docker installation..."

    if ! command_exists docker; then
        print_warning "Docker not installed"
        print_info "Docker will be installed by setup.sh"
        return 2  # Warning
    fi

    if ! service_running docker; then
        print_warning "Docker service not running"
        print_info "Docker will be started by setup.sh"
        return 2
    fi

    # Check Docker version
    local docker_version
    docker_version=$(docker --version | grep -oP 'Docker version \K[^,]+')
    if [[ -z "$docker_version" ]]; then
        print_warning "Could not determine Docker version"
        return 2
    fi

    # Compare version (simplified check)
    if [[ "$docker_version" =~ ^([0-9]+)\.([0-9]+) ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        if (( major < 20 || (major == 20 && minor < 10) )); then
            print_warning "Docker version $docker_version may be outdated (20.10+ recommended)"
            return 2
        fi
    fi

    print_success "Docker $docker_version installed and running"
    return 0
}

# Check NVIDIA GPU
check_nvidia_gpu() {
    print_info "Checking for NVIDIA GPU..."

    if ! command_exists nvidia-smi; then
        print_info "No NVIDIA GPU detected or drivers not installed"
        return 0
    fi

    local gpu_info
    gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)
    if [[ -z "$gpu_info" ]]; then
        print_warning "NVIDIA GPU detected but not accessible"
        return 2
    fi

    print_success "NVIDIA GPU: $gpu_info"
    return 0
}

# Check EZ-Homelab repository
check_repository() {
    print_info "Checking EZ-Homelab repository..."

    if [[ ! -d "$EZ_HOME" ]]; then
        print_error "EZ-Homelab repository not found at $EZ_HOME"
        print_error "Please clone the repository first"
        return 1
    fi

    if [[ ! -f "$EZ_HOME/docker-compose/core/docker-compose.yml" ]]; then
        print_error "Repository structure incomplete"
        print_error "Please ensure you have the full EZ-Homelab repository"
        return 1
    fi

    print_success "EZ-Homelab repository found at $EZ_HOME"
    return 0
}

# Check user permissions
check_user_permissions() {
    print_info "Checking user permissions..."

    if is_root; then
        print_warning "Running as root - not recommended for normal usage"
        print_info "Consider running as regular user with sudo access"
        return 2
    fi

    if ! sudo -n true 2>/dev/null && ! sudo -l >/dev/null 2>&1; then
        print_error "User does not have sudo access"
        print_error "Please ensure your user can run sudo commands"
        return 1
    fi

    print_success "User has appropriate permissions"
    return 0
}

# =============================================================================
# REPORT GENERATION
# =============================================================================

# Generate validation report
generate_report() {
    local report_file="$LOG_DIR/preflight-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "EZ-Homelab Pre-Flight Validation Report"
        echo "======================================="
        echo "Date: $(date)"
        echo "System: $OS_NAME $OS_VERSION ($ARCH)"
        echo "Kernel: $KERNEL_VERSION"
        echo "User: $EZ_USER (UID: $EZ_UID, GID: $EZ_GID)"
        echo ""
        echo "Results:"
        echo "- OS Compatibility: $(check_os_compatibility >/dev/null 2>&1 && echo "PASS" || echo "FAIL")"
        echo "- System Resources: $(check_system_resources >/dev/null 2>&1 && echo "PASS" || echo "WARN/FAIL")"
        echo "- Network: $(check_network_connectivity >/dev/null 2>&1 && echo "PASS" || echo "FAIL")"
        echo "- Required Packages: $(check_required_packages >/dev/null 2>&1 && echo "PASS" || echo "FAIL")"
        echo "- Docker: $(check_docker_installation >/dev/null 2>&1; case $? in 0) echo "PASS";; 1) echo "FAIL";; 2) echo "WARN";; esac)"
        echo "- NVIDIA GPU: $(check_nvidia_gpu >/dev/null 2>&1 && echo "PASS" || echo "N/A")"
        echo "- Repository: $(check_repository >/dev/null 2>&1 && echo "PASS" || echo "FAIL")"
        echo "- Permissions: $(check_user_permissions >/dev/null 2>&1; case $? in 0) echo "PASS";; 1) echo "FAIL";; 2) echo "WARN";; esac)"
        echo ""
        echo "Log file: $LOG_FILE"
    } > "$report_file"

    print_info "Report saved to: $report_file"
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local non_interactive=false
    local verbose=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                ui_show_help "$SCRIPT_NAME"
                exit 0
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

    print_info "Starting EZ-Homelab pre-flight validation..."
    print_info "This will check your system readiness for EZ-Homelab deployment."

    local total_checks=9
    local passed=0
    local warnings=0
    local failed=0

    # Run all checks (disable strict error checking for this loop)
    set +e
    local checks=(
        "check_os_compatibility"
        "check_system_resources"
        "check_network_connectivity"
        "check_required_packages"
        "check_optional_packages"
        "check_docker_installation"
        "check_nvidia_gpu"
        "check_repository"
        "check_user_permissions"
    )

    for check in "${checks[@]}"; do
        echo ""
        # Run check and capture exit code
        local exit_code=0
        $check || exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            ((passed++))
        elif [[ $exit_code -eq 2 ]]; then
            ((warnings++))
        else
            ((failed++))
        fi
    done
    set -e  # Re-enable strict error checking

    echo ""
    print_info "Pre-flight validation complete!"
    print_info "Summary: $passed passed, $warnings warnings, $failed failed"

    # Generate report
    generate_report

    # Determine exit code
    if [[ $failed -gt 0 ]]; then
        print_error "Critical issues found. Please resolve before proceeding."
        print_info "Check the log file: $LOG_FILE"
        print_info "Run this script again after fixing issues."
        exit 1
    elif [[ $warnings -gt 0 ]]; then
        print_warning "Some warnings detected. You may proceed but consider addressing them."
        exit 2
    else
        print_success "All checks passed! Your system is ready for EZ-Homelab deployment."
        exit 0
    fi
}

# Run main function
main "$@"