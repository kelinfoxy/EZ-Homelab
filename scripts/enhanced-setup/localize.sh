#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Configuration Localization
# Replace template variables in service configurations with environment values

SCRIPT_NAME="localize"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================

# Template variables to replace
TEMPLATE_VARS=("DOMAIN" "TZ" "PUID" "PGID" "DUCKDNS_TOKEN" "DUCKDNS_SUBDOMAINS" "AUTHELIA_JWT_SECRET" "AUTHELIA_SESSION_SECRET" "AUTHELIA_STORAGE_ENCRYPTION_KEY" "DEFAULT_EMAIL" "SERVER_IP" "JWT_SECRET" "SESSION_SECRET" "ENCRYPTION_KEY" "AUTHELIA_ADMIN_PASSWORD" "AUTHELIA_ADMIN_EMAIL" "PLEX_CLAIM_TOKEN" "DEPLOYMENT_TYPE" "SERVER_HOSTNAME" "DOCKER_SOCKET_PATH")

# File extensions to process
TEMPLATE_EXTENSIONS=("yml" "yaml" "json" "conf" "cfg" "env")

# =============================================================================
# LOCALIZATION FUNCTIONS
# =============================================================================

# Load environment variables
load_environment() {
    local env_file="$EZ_HOME/.env"

    if [[ ! -f "$env_file" ]]; then
        print_error ".env file not found at $env_file"
        print_error "Run ./pre-deployment-wizard.sh first"
        return 1
    fi

    # Source the .env file
    set -a
    source "$env_file"
    set +a

    print_success "Environment loaded from $env_file"
    return 0
}

# Find template files
find_template_files() {
    local service="${1:-}"
    local files=()

    if [[ -n "$service" ]]; then
        # Process specific service
        local service_dir="$EZ_HOME/docker-compose/$service"
        if [[ -d "$service_dir" ]]; then
            while IFS= read -r -d '' file; do
                files+=("$file")
            done < <(find "$service_dir" -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.conf" -o -name "*.cfg" -o -name "*.env" \) -print0 2>/dev/null)
        else
            print_error "Service directory not found: $service_dir"
            return 1
        fi
    else
        # Process all services
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$EZ_HOME/docker-compose" -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.conf" -o -name "*.cfg" -o -name "*.env" \) -print0 2>/dev/null)
    fi

    printf '%s\n' "${files[@]}"
}

# Check if file contains template variables
file_has_templates() {
    local file="$1"

    for var in "${TEMPLATE_VARS[@]}"; do
        if grep -q "\${$var}" "$file" 2>/dev/null; then
            return 0
        fi
    done

    return 1
}

# Process template file
process_template_file() {
    local file="$1"
    local backup="${file}.template"

    print_info "Processing: $file"

    # Check if file has templates
    if ! file_has_templates "$file"; then
        print_info "No templates found in $file"
        return 0
    fi

    # Backup original if not already backed up
    if [[ ! -f "$backup" ]]; then
        cp "$file" "$backup"
        print_info "Backed up original to $backup"
    fi

    # Process template variables
    local temp_file
    temp_file=$(mktemp)

    cp "$file" "$temp_file"

    for var in "${TEMPLATE_VARS[@]}"; do
        local value="${!var:-}"
        if [[ -n "$value" ]]; then
            # Use sed to replace ${VAR} with value
            sed -i "s|\${$var}|$value|g" "$temp_file"
            log_debug "Replaced \${$var} with $value in $file"
        else
            log_warn "Variable $var not set, leaving template as-is"
        fi
    done

    # Move processed file back
    mv "$temp_file" "$file"

    print_success "Processed $file"
    return 0
}

# Validate processed files
validate_processed_files() {
    local files=("$@")
    local errors=0

    print_info "Validating processed files..."

    for file in "${files[@]}"; do
        if [[ "$file" =~ \.(yml|yaml)$ ]]; then
            if ! validate_yaml "$file"; then
                print_error "Invalid YAML in $file"
                errors=$((errors + 1))
            fi
        fi
    done

    if [[ $errors -gt 0 ]]; then
        print_error "Validation failed for $errors file(s)"
        return 1
    fi

    print_success "All files validated successfully"
    return 0
}

# =============================================================================
# UI FUNCTIONS
# =============================================================================

# Show progress for batch processing
show_localization_progress() {
    local total="$1"
    local current="$2"
    local file="$3"

    local percent=$(( current * 100 / total ))
    ui_gauge "Processing templates... ($current/$total)" "$percent"
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local service=""
    local non_interactive=false
    local verbose=false
    local dry_run=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat << EOF
EZ-Homelab Configuration Localization

USAGE:
    $SCRIPT_NAME [OPTIONS] [SERVICE]

ARGUMENTS:
    SERVICE    Specific service to localize (optional, processes all if not specified)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose logging
    --dry-run          Show what would be processed without making changes
    --no-ui            Run without interactive UI

EXAMPLES:
    $SCRIPT_NAME                    # Process all services
    $SCRIPT_NAME traefik           # Process only Traefik
    $SCRIPT_NAME --dry-run         # Show what would be changed

EOF
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                ;;
            --dry-run)
                dry_run=true
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

    print_info "Starting EZ-Homelab configuration localization..."

    # Load environment
    if ! load_environment; then
        exit 1
    fi

    # Find template files
    local files
    mapfile -t files < <(find_template_files "$service")
    if [[ ${#files[@]} -eq 0 ]]; then
        print_warning "No template files found"
        exit 0
    fi

    print_info "Found ${#files[@]} template file(s) to process"

    if $dry_run; then
        print_info "DRY RUN - Would process the following files:"
        printf '%s\n' "${files[@]}"
        exit 0
    fi

    # Process files
    local processed=0
    local total=${#files[@]}

    for file in "${files[@]}"; do
        if ui_available && ! $non_interactive; then
            show_localization_progress "$total" "$processed" "$file"
        fi

        if process_template_file "$file"; then
            processed=$((processed + 1))
        fi
    done

    # Close progress gauge
    if ui_available && ! $non_interactive; then
        ui_gauge "Processing complete!" 100
        sleep 1
    fi

    # Validate processed files
    if ! validate_processed_files "${files[@]}"; then
        print_error "Some processed files failed validation"
        print_error "Check the log file: $LOG_FILE"
        exit 1
    fi

    echo ""
    print_success "Configuration localization complete!"
    print_info "Processed $processed file(s)"
    print_info "Templates backed up with .template extension"
    print_info "Next step: ./validate.sh"

    exit 0
}

# Run main function
main "$@"