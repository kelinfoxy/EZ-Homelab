#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Configuration Generalization
# Reverse localization by restoring template variables from backups

SCRIPT_NAME="generalize"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================

# Template variables that were replaced
TEMPLATE_VARS=("DOMAIN" "TZ" "PUID" "PGID" "DUCKDNS_TOKEN" "JWT_SECRET" "SESSION_SECRET" "ENCRYPTION_KEY" "AUTHELIA_ADMIN_PASSWORD" "AUTHELIA_ADMIN_EMAIL" "PLEX_CLAIM_TOKEN" "DEPLOYMENT_TYPE" "SERVER_HOSTNAME" "DOCKER_SOCKET_PATH")

# =============================================================================
# GENERALIZATION FUNCTIONS
# =============================================================================

# Load environment variables
load_environment() {
    local env_file="$EZ_HOME/.env"

    if [[ ! -f "$env_file" ]]; then
        print_error ".env file not found at $env_file"
        print_error "Cannot generalize without environment context"
        return 1
    fi

    # Source the .env file
    set -a
    source "$env_file"
    set +a

    print_success "Environment loaded from $env_file"
    return 0
}

# Find backup template files
find_backup_files() {
    local service="${1:-}"

    if [[ -n "$service" ]]; then
        # Process specific service
        local service_dir="$EZ_HOME/docker-compose/$service"
        if [[ -d "$service_dir" ]]; then
            find "$service_dir" -name "*.template" -type f 2>/dev/null
        else
            print_error "Service directory not found: $service_dir"
            return 1
        fi
    else
        # Process all services
        find "$EZ_HOME/docker-compose" -name "*.template" -type f 2>/dev/null
    fi
}

# Restore template file from backup
restore_template_file() {
    local backup_file="$1"
    local original_file="${backup_file%.template}"

    print_info "Restoring: $original_file"

    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi

    # Confirm destructive operation
    if ui_available; then
        if ! ui_yesno "Restore $original_file from backup? This will overwrite current changes."; then
            print_info "Skipped $original_file"
            return 0
        fi
    fi

    # Backup current version (safety)
    backup_file "$original_file"

    # Restore from template backup
    cp "$backup_file" "$original_file"

    print_success "Restored $original_file from $backup_file"
    return 0
}

# Generalize processed file (reverse engineer values)
generalize_processed_file() {
    local file="$1"
    local backup_file="${file}.template"

    print_info "Generalizing: $file"

    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi

    # Create backup if it doesn't exist
    if [[ ! -f "$backup_file" ]]; then
        cp "$file" "$backup_file"
        print_info "Created backup: $backup_file"
    fi

    # Process template variables in reverse
    local temp_file
    temp_file=$(mktemp)

    cp "$file" "$temp_file"

    for var in "${TEMPLATE_VARS[@]}"; do
        local value="${!var:-}"
        if [[ -n "$value" ]]; then
            # Escape special characters in value for sed
            local escaped_value
            escaped_value=$(printf '%s\n' "$value" | sed 's/[[\.*^$()+?{|]/\\&/g')

            # Replace actual values back to ${VAR} format
            sed -i "s|$escaped_value|\${$var}|g" "$temp_file"
            log_debug "Generalized \${$var} in $file"
        fi
    done

    # Move generalized file back
    mv "$temp_file" "$file"

    print_success "Generalized $file"
    return 0
}

# Clean up backup files
cleanup_backups() {
    local service="${1:-}"

    print_info "Cleaning up backup files..."

    local backup_files
    mapfile -t backup_files < <(find_backup_files "$service")

    if [[ ${#backup_files[@]} -eq 0 ]]; then
        print_info "No backup files to clean up"
        return 0
    fi

    local cleaned=0
    for backup in "${backup_files[@]}"; do
        if ui_available; then
            if ui_yesno "Delete backup file: $backup?"; then
                rm -f "$backup"
                ((cleaned++))
                print_info "Deleted: $backup"
            fi
        else
            rm -f "$backup"
            ((cleaned++))
            log_info "Deleted backup: $backup"
        fi
    done

    print_success "Cleaned up $cleaned backup file(s)"
}

# =============================================================================
# UI FUNCTIONS
# =============================================================================

# Show generalization options
show_generalization_menu() {
    local text="Select generalization method:"
    local items=(
        "restore" "Restore from .template backups" "on"
        "reverse" "Reverse engineer from current files" "off"
        "cleanup" "Clean up backup files" "off"
    )

    ui_radiolist "$text" "$UI_HEIGHT" "$UI_WIDTH" "${items[@]}"
}

# Show progress for batch processing
show_generalization_progress() {
    local total="$1"
    local current="$2"
    local file="$3"

    local percent=$(( current * 100 / total ))
    ui_gauge "Generalizing configurations... ($current/$total)" "$percent"
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local service=""
    local method=""
    local non_interactive=false
    local verbose=false
    local cleanup=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat << EOF
EZ-Homelab Configuration Generalization

USAGE:
    $SCRIPT_NAME [OPTIONS] [SERVICE]

ARGUMENTS:
    SERVICE    Specific service to generalize (optional, processes all if not specified)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose logging
    --method METHOD    Generalization method: restore, reverse, cleanup
    --cleanup          Clean up backup files after generalization
    --no-ui            Run without interactive UI

METHODS:
    restore    Restore files from .template backups (safe)
    reverse    Reverse engineer template variables from current values (advanced)
    cleanup    Remove .template backup files

EXAMPLES:
    $SCRIPT_NAME --method restore           # Restore all from backups
    $SCRIPT_NAME --method reverse traefik  # Reverse engineer Traefik
    $SCRIPT_NAME --cleanup                 # Clean up all backups

WARNING:
    Generalization can be destructive. Always backup important data first.

EOF
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                ;;
            --method)
                shift
                method="$1"
                ;;
            --cleanup)
                cleanup=true
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

    print_info "Starting EZ-Homelab configuration generalization..."

    # Load environment
    if ! load_environment; then
        exit 1
    fi

    # Determine method
    if [[ -z "$method" ]]; then
        if ui_available && ! $non_interactive; then
            method=$(show_generalization_menu) || exit 1
        else
            print_error "Method must be specified with --method when running non-interactively"
            echo "Available methods: restore, reverse, cleanup"
            exit 1
        fi
    fi

    case "$method" in
        "restore")
            # Find backup files
            local backup_files
            mapfile -t backup_files < <(find_backup_files "$service")
            if [[ ${#backup_files[@]} -eq 0 ]]; then
                print_warning "No backup files found"
                exit 0
            fi

            print_info "Found ${#backup_files[@]} backup file(s)"

            # Restore files
            local restored=0
            local total=${#backup_files[@]}

            for backup in "${backup_files[@]}"; do
                if ui_available && ! $non_interactive; then
                    show_generalization_progress "$total" "$restored" "$backup"
                fi

                if restore_template_file "$backup"; then
                    ((restored++))
                fi
            done

            # Close progress gauge
            if ui_available && ! $non_interactive; then
                ui_gauge "Restoration complete!" 100
                sleep 1
            fi

            print_success "Restored $restored file(s) from backups"
            ;;

        "reverse")
            print_warning "Reverse engineering is experimental and may not be perfect"
            print_warning "Make sure you have backups of important data"

            if ui_available && ! $non_interactive; then
                if ! ui_yesno "Continue with reverse engineering? This may modify your configuration files."; then
                    print_info "Operation cancelled"
                    exit 0
                fi
            fi

            # Find processed files (those with actual values instead of templates)
            local processed_files
            mapfile -t processed_files < <(find "$EZ_HOME/docker-compose${service:+/$service}" -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.conf" -o -name "*.cfg" -o -name "*.env" 2>/dev/null)

            if [[ ${#processed_files[@]} -eq 0 ]]; then
                print_warning "No configuration files found"
                exit 0
            fi

            print_info "Found ${#processed_files[@]} file(s) to generalize"

            # Generalize files
            local generalized=0
            local total=${#processed_files[@]}

            for file in "${processed_files[@]}"; do
                if ui_available && ! $non_interactive; then
                    show_generalization_progress "$total" "$generalized" "$file"
                fi

                if generalize_processed_file "$file"; then
                    ((generalized++))
                fi
            done

            # Close progress gauge
            if ui_available && ! $non_interactive; then
                ui_gauge "Generalization complete!" 100
                sleep 1
            fi

            print_success "Generalized $generalized file(s)"
            ;;

        "cleanup")
            cleanup_backups "$service"
            ;;

        *)
            print_error "Unknown method: $method"
            echo "Available methods: restore, reverse, cleanup"
            exit 1
            ;;
    esac

    # Optional cleanup
    if $cleanup && [[ "$method" != "cleanup" ]]; then
        cleanup_backups "$service"
    fi

    echo ""
    print_success "Configuration generalization complete!"
    print_info "Use ./validate.sh to check the results"

    exit 0
}

# Run main function
main "$@"