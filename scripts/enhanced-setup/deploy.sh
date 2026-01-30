#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Deployment Engine
# Orchestrated deployment of services with proper sequencing and health checks

SCRIPT_NAME="deploy"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# DEPLOYMENT CONFIGURATION
# =============================================================================

# Service deployment order (dependencies must come first)
DEPLOYMENT_ORDER=(
    "core"           # Infrastructure services (Traefik, Authelia, etc.)
    "infrastructure" # Development tools (code-server, etc.)
    "dashboards"     # Homepage, monitoring dashboards
    "monitoring"     # Grafana, Prometheus, Loki
    "media"          # Plex, Jellyfin, etc.
    "media-management" # Sonarr, Radarr, etc.
    "home"           # Home Assistant, Node-RED
    "productivity"   # Nextcloud, Gitea, etc.
    "utilities"      # Duplicati, FreshRSS, etc.
    "vpn"            # VPN services
    "alternatives"   # Alternative services
    "wikis"          # Wiki services
)

# Core services that must be running for the system to function
CORE_SERVICES=("traefik" "authelia" "duckdns")

# Service health check timeouts (seconds)
HEALTH_CHECK_TIMEOUT=300
SERVICE_STARTUP_TIMEOUT=60

# =============================================================================
# DEPLOYMENT FUNCTIONS
# =============================================================================

# Get list of available service stacks
get_available_stacks() {
    local stacks=()
    local stack_dir="$EZ_HOME/docker-compose"

    if [[ -d "$stack_dir" ]]; then
        while IFS= read -r -d '' dir; do
            local stack_name="$(basename "$dir")"
            if [[ -f "$dir/docker-compose.yml" ]]; then
                stacks+=("$stack_name")
            fi
        done < <(find "$stack_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi

    printf '%s\n' "${stacks[@]}"
}

# Check if a service stack exists
stack_exists() {
    local stack="$1"
    local stack_dir="$EZ_HOME/docker-compose/$stack"

    [[ -d "$stack_dir" && -f "$stack_dir/docker-compose.yml" ]]
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

# Check service health
check_service_health() {
    local service="$1"
    local timeout="${2:-$HEALTH_CHECK_TIMEOUT}"
    local start_time=$(date +%s)

    print_info "Checking health of service: $service"

    while (( $(date +%s) - start_time < timeout )); do
        if is_service_running "$service"; then
            # Additional health checks could be added here
            # For now, just check if container is running
            print_success "Service $service is healthy"
            return 0
        fi
        sleep 5
    done

    print_error "Service $service failed health check (timeout: ${timeout}s)"
    return 1
}

# Deploy a single service stack
deploy_stack() {
    local stack="$1"
    local compose_file="$EZ_HOME/docker-compose/$stack/docker-compose.yml"

    if [[ ! -f "$compose_file" ]]; then
        print_error "Compose file not found: $compose_file"
        return 1
    fi

    print_info "Deploying stack: $stack"

    # Validate the compose file first
    if ! validate_yaml "$compose_file"; then
        print_error "Invalid YAML in $compose_file"
        return 1
    fi

    # Pull images first
    print_info "Pulling images for stack: $stack"
    if ! docker compose -f "$compose_file" pull; then
        print_warning "Failed to pull some images for $stack, continuing..."
    fi

    # Deploy the stack
    print_info "Starting services in stack: $stack"
    if ! docker compose -f "$compose_file" up -d; then
        print_error "Failed to deploy stack: $stack"
        return 1
    fi

    # Get list of services in this stack
    local services
    mapfile -t services < <(get_stack_services "$stack")

    # Wait for services to start and check health
    for service in "${services[@]}"; do
        print_info "Waiting for service to start: $service"
        sleep "$SERVICE_STARTUP_TIMEOUT"

        if ! check_service_health "$service"; then
            print_error "Service $service in stack $stack failed health check"
            return 1
        fi
    done

    print_success "Successfully deployed stack: $stack"
    return 0
}

# Stop a service stack
stop_stack() {
    local stack="$1"
    local compose_file="$EZ_HOME/docker-compose/$stack/docker-compose.yml"

    if [[ ! -f "$compose_file" ]]; then
        print_warning "Compose file not found: $compose_file"
        return 0
    fi

    print_info "Stopping stack: $stack"

    if docker compose -f "$compose_file" down; then
        print_success "Successfully stopped stack: $stack"
        return 0
    else
        print_error "Failed to stop stack: $stack"
        return 1
    fi
}

# Rollback deployment
rollback_deployment() {
    local failed_stack="$1"
    local deployed_stacks=("${@:2}")

    print_warning "Rolling back deployment due to failure in: $failed_stack"

    # Stop the failed stack first
    stop_stack "$failed_stack" || true

    # Stop all previously deployed stacks in reverse order
    for ((i=${#deployed_stacks[@]}-1; i>=0; i--)); do
        local stack="${deployed_stacks[i]}"
        if [[ "$stack" != "$failed_stack" ]]; then
            stop_stack "$stack" || true
        fi
    done

    print_info "Rollback completed"
}

# Deploy all stacks in order
deploy_all() {
    local deployed_stacks=()
    local total_stacks=${#DEPLOYMENT_ORDER[@]}
    local current_stack=0

    print_info "Starting full deployment of $total_stacks stacks"

    for stack in "${DEPLOYMENT_ORDER[@]}"; do
        current_stack=$((current_stack + 1))
        local percent=$(( current_stack * 100 / total_stacks ))

        if ui_available && ! $non_interactive; then
            ui_gauge "Deploying $stack... ($current_stack/$total_stacks)" "$percent"
        fi

        print_info "[$current_stack/$total_stacks] Deploying stack: $stack"

        if ! stack_exists "$stack"; then
            print_warning "Stack $stack not found, skipping"
            continue
        fi

        if deploy_stack "$stack"; then
            deployed_stacks+=("$stack")
        else
            print_error "Failed to deploy stack: $stack"
            rollback_deployment "$stack" "${deployed_stacks[@]}"
            return 1
        fi
    done

    print_success "All stacks deployed successfully!"
    return 0
}

# Deploy specific stacks
deploy_specific() {
    local stacks=("$@")
    local deployed_stacks=()
    local total_stacks=${#stacks[@]}
    local current_stack=0

    print_info "Starting deployment of $total_stacks specific stacks"

    for stack in "${stacks[@]}"; do
        current_stack=$((current_stack + 1))
        local percent=$(( current_stack * 100 / total_stacks ))

        if ui_available && ! $non_interactive; then
            ui_gauge "Deploying $stack... ($current_stack/$total_stacks)" "$percent"
        fi

        print_info "[$current_stack/$total_stacks] Deploying stack: $stack"

        if ! stack_exists "$stack"; then
            print_error "Stack $stack not found"
            rollback_deployment "$stack" "${deployed_stacks[@]}"
            return 1
        fi

        if deploy_stack "$stack"; then
            deployed_stacks+=("$stack")
        else
            print_error "Failed to deploy stack: $stack"
            rollback_deployment "$stack" "${deployed_stacks[@]}"
            return 1
        fi
    done

    print_success "Specified stacks deployed successfully!"
    return 0
}

# Stop all stacks
stop_all() {
    local stacks
    mapfile -t stacks < <(get_available_stacks)
    local total_stacks=${#stacks[@]}
    local current_stack=0

    print_info "Stopping all $total_stacks stacks"

    for stack in "${stacks[@]}"; do
        current_stack=$((current_stack + 1))
        local percent=$(( current_stack * 100 / total_stacks ))

        if ui_available && ! $non_interactive; then
            ui_gauge "Stopping $stack... ($current_stack/$total_stacks)" "$percent"
        fi

        stop_stack "$stack" || true
    done

    print_success "All stacks stopped"
}

# Show deployment status
show_status() {
    print_info "EZ-Homelab Deployment Status"
    echo

    local stacks
    mapfile -t stacks < <(get_available_stacks)

    for stack in "${stacks[@]}"; do
        echo "Stack: $stack"

        local services
        mapfile -t services < <(get_stack_services "$stack")

        for service in "${services[@]}"; do
            if is_service_running "$service"; then
                echo "  ✅ $service - Running"
            else
                echo "  ❌ $service - Stopped"
            fi
        done
        echo
    done
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local action="deploy"
    local stacks=()
    local non_interactive=false
    local verbose=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat << EOF
EZ-Homelab Deployment Engine

USAGE:
    deploy [OPTIONS] [ACTION] [STACKS...]

ACTIONS:
    deploy     Deploy all stacks (default)
    stop       Stop all stacks
    status     Show deployment status
    restart    Restart all stacks

ARGUMENTS:
    STACKS     Specific stacks to deploy (optional, deploys all if not specified)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose logging
    --no-ui            Run without interactive UI
    --no-rollback      Skip rollback on deployment failure

EXAMPLES:
    deploy                    # Deploy all stacks
    deploy core media         # Deploy only core and media stacks
    deploy stop               # Stop all stacks
    deploy status             # Show status of all services

EOF
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --no-ui)
                non_interactive=true
                shift
                ;;
            --no-rollback)
                NO_ROLLBACK=true
                shift
                ;;
            deploy|stop|status|restart)
                action="$1"
                shift
                break
                ;;
            *)
                stacks+=("$1")
                shift
                ;;
        esac
    done

    # Handle remaining arguments as stacks
    while [[ $# -gt 0 ]]; do
        stacks+=("$1")
        shift
    done

    # Initialize script
    init_script "$SCRIPT_NAME" "$SCRIPT_VERSION"
    init_logging "$SCRIPT_NAME"

    # Check prerequisites
    if ! docker_available; then
        print_error "Docker is not available. Please run setup.sh first."
        exit 1
    fi

    # Execute action
    case "$action" in
        deploy)
            if [[ ${#stacks[@]} -eq 0 ]]; then
                deploy_all
            else
                deploy_specific "${stacks[@]}"
            fi
            ;;
        stop)
            stop_all
            ;;
        status)
            show_status
            ;;
        restart)
            print_info "Restarting all stacks..."
            stop_all
            sleep 5
            deploy_all
            ;;
        *)
            print_error "Unknown action: $action"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"