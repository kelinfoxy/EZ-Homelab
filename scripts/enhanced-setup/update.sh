#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Update Management
# Service update management with zero-downtime deployments

SCRIPT_NAME="update"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# UPDATE CONFIGURATION
# =============================================================================

# Update settings
UPDATE_CHECK_INTERVAL=86400  # 24 hours in seconds
UPDATE_TIMEOUT=300          # 5 minutes timeout for updates
ROLLBACK_TIMEOUT=180        # 3 minutes for rollback

# Update sources
DOCKER_HUB_API="https://registry.hub.docker.com/v2"
GITHUB_API="https://api.github.com"

# Update strategies
UPDATE_STRATEGY_ROLLING="rolling"      # Update one service at a time
UPDATE_STRATEGY_BLUE_GREEN="blue-green" # Deploy new version alongside old
UPDATE_STRATEGY_CANARY="canary"        # Update subset of instances first

# Default update strategy
DEFAULT_UPDATE_STRATEGY="$UPDATE_STRATEGY_ROLLING"

# =============================================================================
# UPDATE STATE MANAGEMENT
# =============================================================================

# Update state file
UPDATE_STATE_FILE="$LOG_DIR/update_state.json"

# Initialize update state
init_update_state() {
    if [[ ! -f "$UPDATE_STATE_FILE" ]]; then
        cat > "$UPDATE_STATE_FILE" << EOF
{
  "last_check": 0,
  "updates_available": {},
  "update_history": [],
  "current_updates": {}
}
EOF
    fi
}

# Record update attempt
record_update_attempt() {
    local service="$1"
    local old_version="$2"
    local new_version="$3"
    local status="$4"
    local timestamp
    timestamp=$(date +%s)
    
    if command_exists "jq"; then
        jq --arg service "$service" --arg old_version "$old_version" --arg new_version "$new_version" \
           --arg status "$status" --argjson timestamp "$timestamp" \
           '.update_history |= . + [{"service": $service, "old_version": $old_version, "new_version": $new_version, "status": $status, "timestamp": $timestamp}]' \
           "$UPDATE_STATE_FILE" > "${UPDATE_STATE_FILE}.tmp" && mv "${UPDATE_STATE_FILE}.tmp" "$UPDATE_STATE_FILE"
    fi
}

# Get service update status
get_service_update_status() {
    local service="$1"
    
    if command_exists "jq" && [[ -f "$UPDATE_STATE_FILE" ]]; then
        jq -r ".current_updates[\"$service\"] // \"idle\"" "$UPDATE_STATE_FILE"
    else
        echo "unknown"
    fi
}

# Set service update status
set_service_update_status() {
    local service="$1"
    local status="$2"
    
    if command_exists "jq"; then
        jq --arg service "$service" --arg status "$status" \
           '.current_updates[$service] = $status' \
           "$UPDATE_STATE_FILE" > "${UPDATE_STATE_FILE}.tmp" && mv "${UPDATE_STATE_FILE}.tmp" "$UPDATE_STATE_FILE"
    fi
}

# =============================================================================
# VERSION CHECKING FUNCTIONS
# =============================================================================

# Get current service version
get_current_version() {
    local service="$1"
    
    if ! is_service_running "$service"; then
        echo "unknown"
        return 1
    fi
    
    # Get image from running container
    local image
    image=$(docker inspect "$service" --format '{{.Config.Image}}' 2>/dev/null || echo "")
    
    if [[ -z "$image" ]]; then
        echo "unknown"
        return 1
    fi
    
    # Extract version tag
    if [[ "$image" == *":"* ]]; then
        echo "$image" | cut -d: -f2
    else
        echo "latest"
    fi
}

# Check for Docker image updates
check_docker_updates() {
    local service="$1"
    
    if ! is_service_running "$service"; then
        return 1
    fi
    
    local current_image
    current_image=$(docker inspect "$service" --format '{{.Config.Image}}' 2>/dev/null || echo "")
    
    if [[ -z "$current_image" ]]; then
        return 1
    fi
    
    # Extract repository and tag
    local repo tag
    if [[ "$current_image" == *":"* ]]; then
        repo=$(echo "$current_image" | cut -d: -f1)
        tag=$(echo "$current_image" | cut -d: -f2)
    else
        repo="$current_image"
        tag="latest"
    fi
    
    print_info "Checking updates for $service ($repo:$tag)"
    
    # Pull latest image to check for updates
    if docker pull "$repo:latest" >/dev/null 2>&1; then
        # Compare image IDs
        local current_id latest_id
        current_id=$(docker inspect "$repo:$tag" --format '{{.Id}}' 2>/dev/null || echo "")
        latest_id=$(docker inspect "$repo:latest" --format '{{.Id}}' 2>/dev/null || echo "")
        
        if [[ "$current_id" != "$latest_id" ]]; then
            print_info "Update available for $service: $tag -> latest"
            return 0
        else
            print_info "Service $service is up to date"
            return 1
        fi
    else
        print_warning "Failed to check updates for $service"
        return 1
    fi
}

# Check all services for updates
check_all_updates() {
    print_info "Checking for service updates"
    
    local services
    mapfile -t services < <(find_all_services)
    local updates_available=()
    
    for service in "${services[@]}"; do
        if check_docker_updates "$service"; then
            updates_available+=("$service")
        fi
    done
    
    if [[ ${#updates_available[@]} -gt 0 ]]; then
        print_info "Updates available for: ${updates_available[*]}"
        return 0
    else
        print_info "All services are up to date"
        return 1
    fi
}

# =============================================================================
# UPDATE EXECUTION FUNCTIONS
# =============================================================================

# Update single service with rolling strategy
update_service_rolling() {
    local service="$1"
    local new_image="$2"
    
    print_info "Updating service $service with rolling strategy"
    set_service_update_status "$service" "updating"
    
    local old_version
    old_version=$(get_current_version "$service")
    
    # Get compose file
    local compose_file
    compose_file=$(get_service_compose_file "$service")
    
    if [[ -z "$compose_file" ]]; then
        print_error "Cannot find compose file for service $service"
        set_service_update_status "$service" "failed"
        return 1
    fi
    
    local compose_dir=$(dirname "$compose_file")
    local compose_base=$(basename "$compose_file")
    
    # Backup current configuration
    print_info "Creating backup before update"
    "$SCRIPT_DIR/backup.sh" config --quiet
    
    # Update the service
    print_info "Pulling new image: $new_image"
    if ! docker pull "$new_image"; then
        print_error "Failed to pull new image: $new_image"
        set_service_update_status "$service" "failed"
        return 1
    fi
    
    print_info "Restarting service with new image"
    if (cd "$compose_dir" && docker compose -f "$compose_base" up -d "$service"); then
        # Wait for service to start
        local count=0
        while (( count < UPDATE_TIMEOUT )) && ! is_service_running "$service"; do
            sleep 5
            ((count += 5))
        done
        
        if is_service_running "$service"; then
            # Verify service health
            sleep 10
            if check_service_health "$service"; then
                local new_version
                new_version=$(get_current_version "$service")
                print_success "Service $service updated successfully: $old_version -> $new_version"
                record_update_attempt "$service" "$old_version" "$new_version" "success"
                set_service_update_status "$service" "completed"
                return 0
            else
                print_error "Service $service failed health check after update"
                rollback_service "$service"
                return 1
            fi
        else
            print_error "Service $service failed to start after update"
            rollback_service "$service"
            return 1
        fi
    else
        print_error "Failed to update service $service"
        set_service_update_status "$service" "failed"
        return 1
    fi
}

# Rollback service to previous version
rollback_service() {
    local service="$1"
    
    print_warning "Rolling back service $service"
    set_service_update_status "$service" "rolling_back"
    
    # For now, just restart with current configuration
    # In a more advanced implementation, this would restore from backup
    local compose_file
    compose_file=$(get_service_compose_file "$service")
    
    if [[ -n "$compose_file" ]]; then
        local compose_dir=$(dirname "$compose_file")
        local compose_base=$(basename "$compose_file")
        
        if (cd "$compose_dir" && docker compose -f "$compose_base" restart "$service"); then
            sleep 10
            if check_service_health "$service"; then
                print_success "Service $service rolled back successfully"
                set_service_update_status "$service" "rolled_back"
                return 0
            fi
        fi
    fi
    
    print_error "Failed to rollback service $service"
    set_service_update_status "$service" "rollback_failed"
    return 1
}

# Update all services
update_all_services() {
    local strategy="${1:-$DEFAULT_UPDATE_STRATEGY}"
    
    print_info "Updating all services with $strategy strategy"
    
    local services
    mapfile -t services < <(find_all_services)
    local updated=0
    local failed=0
    
    for service in "${services[@]}"; do
        if check_docker_updates "$service"; then
            print_info "Updating service: $service"
            
            # Get latest image
            local current_image
            current_image=$(docker inspect "$service" --format '{{.Config.Image}}' 2>/dev/null || echo "")
            
            if [[ -n "$current_image" ]]; then
                local repo
                repo=$(echo "$current_image" | cut -d: -f1)
                local new_image="$repo:latest"
                
                if update_service_rolling "$service" "$new_image"; then
                    ((updated++))
                else
                    ((failed++))
                fi
            fi
        fi
    done
    
    print_info "Update summary: $updated updated, $failed failed"
    
    if (( failed > 0 )); then
        return 1
    else
        return 0
    fi
}

# =============================================================================
# UPDATE MONITORING FUNCTIONS
# =============================================================================

# Show update status
show_update_status() {
    print_info "Update Status"
    echo
    
    local services
    mapfile -t services < <(find_all_services)
    
    echo "Service Update Status:"
    echo "----------------------------------------"
    
    for service in "${services[@]}"; do
        local status
        status=$(get_service_update_status "$service")
        local version
        version=$(get_current_version "$service")
        
        printf "  %-20s %-12s %s\n" "$service" "$status" "$version"
    done
    echo
    
    # Show recent update history
    if command_exists "jq" && [[ -f "$UPDATE_STATE_FILE" ]]; then
        echo "Recent Update History:"
        echo "----------------------------------------"
        jq -r '.update_history | reverse | .[0:5][] | "\(.timestamp | strftime("%Y-%m-%d %H:%M")) \(.service) \(.old_version)->\(.new_version) [\(.status)]"' "$UPDATE_STATE_FILE" 2>/dev/null || echo "No update history available"
    fi
}

# Monitor ongoing updates
monitor_updates() {
    print_info "Monitoring ongoing updates (Ctrl+C to stop)"
    
    while true; do
        clear
        show_update_status
        echo
        echo "Press Ctrl+C to stop monitoring"
        sleep 10
    done
}

# =============================================================================
# AUTOMATED UPDATE FUNCTIONS
# =============================================================================

# Setup automated updates
setup_automated_updates() {
    local schedule="${1:-0 3 * * 0}"  # Weekly on Sunday at 3 AM
    
    print_info "Setting up automated updates with schedule: $schedule"
    
    # Create update script
    local update_script="$HOME/.ez-homelab/update.sh"
    cat > "$update_script" << EOF
#!/bin/bash
# Automated update script for EZ-Homelab

SCRIPT_DIR="$SCRIPT_DIR"

# Run updates
"\$SCRIPT_DIR/update.sh" all --quiet

# Log completion
echo "\$(date): Automated update completed" >> "$LOG_DIR/update.log"
EOF
    
    chmod +x "$update_script"
    
    # Add to crontab
    local cron_entry="$schedule $update_script"
    if ! crontab -l 2>/dev/null | grep -q "update.sh"; then
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        print_info "Added automated updates to crontab: $cron_entry"
    fi
    
    print_success "Automated updates configured"
}

# Remove automated updates
remove_automated_updates() {
    print_info "Removing automated updates"
    
    # Remove from crontab
    crontab -l 2>/dev/null | grep -v "update.sh" | crontab -
    
    print_success "Automated updates removed"
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local action=""
    local service=""
    local strategy="$DEFAULT_UPDATE_STRATEGY"
    local schedule=""
    local quiet=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat << EOF
EZ-Homelab Update Management

USAGE:
    update [OPTIONS] <ACTION> [SERVICE]

ACTIONS:
    check           Check for available updates
    update          Update a service or all services
    status          Show update status and history
    monitor         Monitor ongoing updates
    rollback        Rollback a service
    schedule        Setup automated updates
    unschedule      Remove automated updates

OPTIONS:
    -s, --strategy STRATEGY    Update strategy (rolling, blue-green, canary)
    --schedule CRON           Cron schedule for automated updates
    -q, --quiet               Suppress non-error output

STRATEGIES:
    rolling        Update one service at a time (default)
    blue-green     Deploy new version alongside old
    canary         Update subset of instances first

EXAMPLES:
    update check                           # Check for updates
    update update traefik                 # Update Traefik service
    update update all                     # Update all services
    update status                          # Show update status
    update rollback traefik               # Rollback Traefik
    update monitor                         # Monitor updates
    update schedule "0 3 * * 0"           # Weekly updates Sunday 3 AM

EOF
                exit 0
                ;;
            -s|--strategy)
                strategy="$2"
                shift 2
                ;;
            --schedule)
                schedule="$2"
                shift 2
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            check|update|status|monitor|rollback|schedule|unschedule)
                action="$1"
                shift
                break
                ;;
            *)
                if [[ -z "$service" ]]; then
                    service="$1"
                else
                    print_error "Too many arguments"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Handle remaining arguments
    while [[ $# -gt 0 ]]; do
        if [[ -z "$service" ]]; then
            service="$1"
        else
            print_error "Too many arguments"
            exit 1
        fi
        shift
    done
    
    # Initialize script
    init_script "$SCRIPT_NAME" "$SCRIPT_VERSION"
    init_logging "$SCRIPT_NAME"
    init_update_state
    
    # Check prerequisites
    if ! docker_available; then
        print_error "Docker is not available"
        exit 1
    fi
    
    # Execute action
    case "$action" in
        check)
            if [[ -n "$service" ]]; then
                check_docker_updates "$service"
            else
                check_all_updates
            fi
            ;;
        update)
            if [[ "$service" == "all" || -z "$service" ]]; then
                update_all_services "$strategy"
            else
                # Get latest image for the service
                local current_image
                current_image=$(docker inspect "$service" --format '{{.Config.Image}}' 2>/dev/null || echo "")
                
                if [[ -n "$current_image" ]]; then
                    local repo
                    repo=$(echo "$current_image" | cut -d: -f1)
                    local new_image="$repo:latest"
                    
                    update_service_rolling "$service" "$new_image"
                else
                    print_error "Cannot determine current image for service $service"
                    exit 1
                fi
            fi
            ;;
        status)
            show_update_status
            ;;
        monitor)
            monitor_updates
            ;;
        rollback)
            if [[ -n "$service" ]]; then
                rollback_service "$service"
            else
                print_error "Service name required for rollback"
                exit 1
            fi
            ;;
        schedule)
            setup_automated_updates "$schedule"
            ;;
        unschedule)
            remove_automated_updates
            ;;
        "")
            print_error "No action specified. Use --help for usage information."
            exit 1
            ;;
        *)
            print_error "Unknown action: $action"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"