#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Multi-Purpose Validation
# Validate configurations, compose files, and deployment readiness

SCRIPT_NAME="validate"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Validate .env file
validate_env_file() {
    local env_file="$EZ_HOME/.env"

    if [[ ! -f "$env_file" ]]; then
        print_error ".env file not found at $env_file"
        return 1
    fi

    return 0
}

# Validate Docker Compose files
validate_compose_files() {
    local service="${1:-}"

    print_info "Validating Docker Compose files..."

    local compose_files
    if [[ -n "$service" ]]; then
        compose_files=("$EZ_HOME/docker-compose/$service/docker-compose.yml")
    else
        mapfile -t compose_files < <(find "$EZ_HOME/docker-compose" -name "docker-compose.yml" -type f 2>/dev/null)
    fi

    if [[ ${#compose_files[@]} -eq 0 ]]; then
        print_error "No Docker Compose files found"
        return 1
    fi

    local errors=0
    for file in "${compose_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Compose file not found: $file"
            errors=$((errors + 1))
            continue
        fi

        # Validate YAML syntax
        if ! validate_yaml "$file"; then
            print_error "Invalid YAML in $file"
            errors=$((errors + 1))
            continue
        fi

        # Validate with docker compose config
        if command_exists docker && docker compose version >/dev/null 2>&1; then
            if ! docker compose -f "$file" config >/dev/null 2>&1; then
                print_error "Invalid Docker Compose configuration in $file"
                errors=$((errors + 1))
                continue
            fi
        fi

        print_success "Validated: $file"
    done

    if [[ $errors -gt 0 ]]; then
        print_error "Found $errors error(s) in compose files"
        return 1
    fi

    print_success "All compose files validated"
    return 0
}

# Validate Docker networks
validate_networks() {
    print_info "Validating Docker networks..."

    if ! docker_available; then
        print_warning "Docker not available, skipping network validation"
        return 2
    fi

    local required_networks=("traefik-network" "homelab-network")
    local missing_networks=()

    for network in "${required_networks[@]}"; do
        if ! docker network ls --format "{{.Name}}" | grep -q "^${network}$"; then
            missing_networks+=("$network")
        fi
    done

    if [[ ${#missing_networks[@]} -gt 0 ]]; then
        print_error "Missing Docker networks: ${missing_networks[*]}"
        print_error "Run ./pre-deployment-wizard.sh to create networks"
        return 1
    fi

    print_success "All required networks exist"
    return 0
}

# Validate SSL certificates
validate_ssl_certificates() {
    print_info "Validating SSL certificates..."

    # Check if Traefik is running and has certificates
    if ! docker_available; then
        print_warning "Docker not available, skipping SSL validation"
        return 2
    fi

    if ! service_running traefik 2>/dev/null; then
        print_warning "Traefik not running, skipping SSL validation"
        return 2
    fi

    # Check acme.json exists
    local acme_file="$STACKS_DIR/core/traefik/acme.json"
    if [[ ! -f "$acme_file" ]]; then
        print_warning "SSL certificate file not found: $acme_file"
        print_warning "Certificates will be obtained on first Traefik run"
        return 2
    fi

    print_success "SSL certificate file found"
    return 0
}

# Validate service dependencies
validate_service_dependencies() {
    local service="${1:-}"

    print_info "Validating service dependencies..."

    # This is a basic implementation - could be expanded
    # to check for specific service requirements

    if [[ -n "$service" ]]; then
        local service_dir="$EZ_HOME/docker-compose/$service"
        if [[ ! -d "$service_dir" ]]; then
            print_error "Service directory not found: $service_dir"
            return 1
        fi

        local compose_file="$service_dir/docker-compose.yml"
        if [[ ! -f "$compose_file" ]]; then
            print_error "Compose file not found: $compose_file"
            return 1
        fi

        print_success "Service $service dependencies validated"
    else
        print_success "Service dependencies validation skipped (no specific service)"
    fi

    return 0
}

# =============================================================================
# REPORT GENERATION
# =============================================================================

# Generate validation report
generate_validation_report() {
    local report_file="$LOG_DIR/validation-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "EZ-Homelab Validation Report"
        echo "============================"
        echo "Date: $(date)"
        echo "System: $OS_NAME $OS_VERSION ($ARCH)"
        echo ""
        echo "Validation Results:"
        echo "- Environment: $(validate_env_file >/dev/null 2>&1 && echo "PASS" || echo "FAIL")"
        echo "- Compose Files: $(validate_compose_files >/dev/null 2>&1 && echo "PASS" || echo "FAIL")"
        echo "- Networks: $(validate_networks >/dev/null 2>&1; case $? in 0) echo "PASS";; 1) echo "FAIL";; 2) echo "SKIP";; esac)"
        echo "- SSL Certificates: $(validate_ssl_certificates >/dev/null 2>&1; case $? in 0) echo "PASS";; 1) echo "FAIL";; 2) echo "SKIP";; esac)"
        echo ""
        echo "Log file: $LOG_FILE"
    } > "$report_file"

    print_info "Report saved to: $report_file"
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local service=""
    local check_env=true
    local check_compose=true
    local check_networks=true
    local check_ssl=true
    local non_interactive=false
    local verbose=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat << EOF
EZ-Homelab Multi-Purpose Validation

USAGE:
    $SCRIPT_NAME [OPTIONS] [SERVICE]

ARGUMENTS:
    SERVICE    Specific service to validate (optional)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose logging
    --no-env           Skip .env file validation
    --no-compose       Skip compose file validation
    --no-networks      Skip network validation
    --no-ssl          Skip SSL certificate validation
    --no-ui           Run without interactive UI

EXAMPLES:
    $SCRIPT_NAME                    # Validate everything
    $SCRIPT_NAME traefik           # Validate only Traefik
    $SCRIPT_NAME --no-ssl          # Skip SSL validation

EOF
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                ;;
            --no-env)
                check_env=false
                ;;
            --no-compose)
                check_compose=false
                ;;
            --no-networks)
                check_networks=false
                ;;
            --no-ssl)
                check_ssl=false
                ;;
            --no-ui)
                non_interactive=true
                ;;
            -*)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                if [[ -z "$service" ]]; then
                    service="$1"
                else
                    print_error "Multiple services specified. Use only one service name."
                    exit 1
                fi
                ;;
        esac
        shift
    done

    # Initialize script
    init_script "$SCRIPT_NAME"

    if $verbose; then
        set -x
    fi

    print_info "Starting EZ-Homelab validation..."

    local total_checks=0
    local passed=0
    local warnings=0
    local failed=0

    # Run validations
    if $check_env; then
        total_checks=$((total_checks + 1))
        # Run check and capture exit code
        local exit_code=0
        validate_env_file || exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
        fi
    fi

    if $check_compose; then
        ((total_checks++))
        # Run check and capture exit code
        local exit_code=0
        validate_compose_files "$service" || exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            ((passed++))
        else
            ((failed++))
        fi
    fi

    if $check_networks; then
        total_checks=$((total_checks + 1))
        # Run check and capture exit code
        local exit_code=0
        validate_networks || exit_code=$?
        
        case $exit_code in
            0) passed=$((passed + 1)) ;;
            1) failed=$((failed + 1)) ;;
            2) warnings=$((warnings + 1)) ;;
        esac
    fi

    if $check_ssl; then
        total_checks=$((total_checks + 1))
        # Run check and capture exit code
        local exit_code=0
        validate_ssl_certificates || exit_code=$?
        
        case $exit_code in
            0) passed=$((passed + 1)) ;;
            1) failed=$((failed + 1)) ;;
            2) warnings=$((warnings + 1)) ;;
        esac
    fi

    # Service-specific validation
    if [[ -n "$service" ]]; then
        total_checks=$((total_checks + 1))
        # Run check and capture exit code
        local exit_code=0
        validate_service_dependencies "$service" || exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
        fi
    fi

    echo ""
    print_info "Validation complete: $passed passed, $warnings warnings, $failed failed"

    # Generate report
    generate_validation_report

    # Determine exit code
    if [[ $failed -gt 0 ]]; then
        print_error "Validation failed. Check the log file: $LOG_FILE"
        exit 1
    elif [[ $warnings -gt 0 ]]; then
        print_warning "Validation passed with warnings"
        exit 2
    else
        print_success "All validations passed!"
        exit 0
    fi
}

# Run main function
main "$@"