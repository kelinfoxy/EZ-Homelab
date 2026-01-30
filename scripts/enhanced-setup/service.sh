#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Service Management
# Individual service control, monitoring, and maintenance

SCRIPT_NAME="service"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# SERVICE MANAGEMENT CONFIGURATION
# =============================================================================

# Service action timeouts (seconds)
SERVICE_START_TIMEOUT=60
SERVICE_STOP_TIMEOUT=30
LOG_TAIL_LINES=100
HEALTH_CHECK_RETRIES=3

# =============================================================================
# SERVICE DISCOVERY FUNCTIONS
# =============================================================================

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

# =============================================================================
# SERVICE CONTROL FUNCTIONS
# =============================================================================

# Start a specific service
start_service() {
    local service="$1"
    local compose_file
    
    compose_file=$(get_service_compose_file "$service")
    if [[ -z "$compose_file" ]]; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    if is_service_running "$service"; then
        print_warning "Service '$service' is already running"
        return 0
    fi
    
    print_info "Starting service: $service"
    
    local compose_dir=$(dirname "$compose_file")
    local compose_base=$(basename "$compose_file")
    
    if (cd "$compose_dir" && docker compose -f "$compose_base" up -d "$service"); then
        print_info "Waiting for service to start..."
        sleep "$SERVICE_START_TIMEOUT"
        
        if is_service_running "$service"; then
            print_success "Service '$service' started successfully"
            return 0
        else
            print_error "Service '$service' failed to start"
            return 1
        fi
    else
        print_error "Failed to start service '$service'"
        return 1
    fi
}

# Stop a specific service
stop_service() {
    local service="$1"
    local compose_file
    
    compose_file=$(get_service_compose_file "$service")
    if [[ -z "$compose_file" ]]; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    if ! is_service_running "$service"; then
        print_warning "Service '$service' is not running"
        return 0
    fi
    
    print_info "Stopping service: $service"
    
    local compose_dir=$(dirname "$compose_file")
    local compose_base=$(basename "$compose_file")
    
    if (cd "$compose_dir" && docker compose -f "$compose_base" stop "$service"); then
        local count=0
        while ((count < SERVICE_STOP_TIMEOUT)) && is_service_running "$service"; do
            sleep 1
            ((count++))
        done
        
        if ! is_service_running "$service"; then
            print_success "Service '$service' stopped successfully"
            return 0
        else
            print_warning "Service '$service' did not stop gracefully, forcing..."
            (cd "$compose_dir" && docker compose -f "$compose_base" kill "$service")
            return 0
        fi
    else
        print_error "Failed to stop service '$service'"
        return 1
    fi
}

# Restart a specific service
restart_service() {
    local service="$1"
    
    print_info "Restarting service: $service"
    
    if stop_service "$service" && start_service "$service"; then
        print_success "Service '$service' restarted successfully"
        return 0
    else
        print_error "Failed to restart service '$service'"
        return 1
    fi
}

# Get service logs
show_service_logs() {
    local service="$1"
    local lines="${2:-$LOG_TAIL_LINES}"
    local follow="${3:-false}"
    
    local compose_file
    compose_file=$(get_service_compose_file "$service")
    if [[ -z "$compose_file" ]]; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    print_info "Showing logs for service: $service"
    
    local compose_dir=$(dirname "$compose_file")
    local compose_base=$(basename "$compose_file")
    
    if $follow; then
        (cd "$compose_dir" && docker compose -f "$compose_base" logs -f --tail="$lines" "$service")
    else
        (cd "$compose_dir" && docker compose -f "$compose_base" logs --tail="$lines" "$service")
    fi
}

# Check service health
check_service_status() {
    local service="$1"
    
    local compose_file
    compose_file=$(get_service_compose_file "$service")
    if [[ -z "$compose_file" ]]; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    echo "Service: $service"
    
    if is_service_running "$service"; then
        echo "Status: ✅ Running"
        
        # Get container info
        local container_info
        container_info=$(docker ps --filter "name=^${service}$" --format "table {{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2)
        if [[ -n "$container_info" ]]; then
            echo "Container: $container_info"
        fi
        
        # Get health status if available
        local health_status
        health_status=$(docker inspect "$service" --format '{{.State.Health.Status}}' 2>/dev/null || echo "N/A")
        if [[ "$health_status" != "N/A" ]]; then
            echo "Health: $health_status"
        fi
    else
        echo "Status: ❌ Stopped"
    fi
    
    # Show stack info
    local stack_dir
    stack_dir=$(find_service_stack "$service")
    if [[ -n "$stack_dir" ]]; then
        echo "Stack: $(basename "$stack_dir")"
    fi
    
    echo
}

# Execute command in service container
exec_service_command() {
    local service="$1"
    shift
    local command="$*"
    
    if ! is_service_running "$service"; then
        print_error "Service '$service' is not running"
        return 1
    fi
    
    print_info "Executing command in $service: $command"
    docker exec -it "$service" $command
}

# =============================================================================
# BULK OPERATIONS
# =============================================================================

# Start all services in a stack
start_stack_services() {
    local stack="$1"
    local compose_file="$EZ_HOME/docker-compose/$stack/docker-compose.yml"
    
    if [[ ! -f "$compose_file" ]]; then
        print_error "Stack '$stack' not found"
        return 1
    fi
    
    print_info "Starting all services in stack: $stack"
    
    if docker compose -f "$compose_file" up -d; then
        print_success "Stack '$stack' started successfully"
        return 0
    else
        print_error "Failed to start stack '$stack'"
        return 1
    fi
}

# Stop all services in a stack
stop_stack_services() {
    local stack="$1"
    local compose_file="$EZ_HOME/docker-compose/$stack/docker-compose.yml"
    
    if [[ ! -f "$compose_file" ]]; then
        print_error "Stack '$stack' not found"
        return 1
    fi
    
    print_info "Stopping all services in stack: $stack"
    
    if docker compose -f "$compose_file" down; then
        print_success "Stack '$stack' stopped successfully"
        return 0
    else
        print_error "Failed to stop stack '$stack'"
        return 1
    fi
}

# Show status of all services
show_all_status() {
    print_info "EZ-Homelab Service Status"
    echo
    
    local services
    mapfile -t services < <(find_all_services)
    
    for service in "${services[@]}"; do
        check_service_status "$service"
    done
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# List all available services
list_services() {
    print_info "Available Services:"
    
    local services
    mapfile -t services < <(find_all_services)
    
    for service in "${services[@]}"; do
        local stack_dir=""
        stack_dir=$(find_service_stack "$service")
        local stack_name=""
        [[ -n "$stack_dir" ]] && stack_name="($(basename "$stack_dir"))"
        
        local status="❌ Stopped"
        is_service_running "$service" && status="✅ Running"
        
        printf "  %-20s %-12s %s\n" "$service" "$status" "$stack_name"
    done
}

# Clean up stopped containers and unused images
cleanup_services() {
    print_info "Cleaning up Docker resources..."
    
    # Remove stopped containers
    local stopped_containers
    stopped_containers=$(docker ps -aq -f status=exited)
    if [[ -n "$stopped_containers" ]]; then
        print_info "Removing stopped containers..."
        echo "$stopped_containers" | xargs docker rm
    fi
    
    # Remove unused images
    print_info "Removing unused images..."
    docker image prune -f
    
    # Remove unused volumes
    print_info "Removing unused volumes..."
    docker volume prune -f
    
    print_success "Cleanup completed"
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local action=""
    local service=""
    local stack=""
    local follow_logs=false
    local log_lines="$LOG_TAIL_LINES"
    local non_interactive=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat << EOF
EZ-Homelab Service Management

USAGE:
    service [OPTIONS] <ACTION> [SERVICE|STACK]

ACTIONS:
    start     Start a service or all services in a stack
    stop      Stop a service or all services in a stack  
    restart   Restart a service or all services in a stack
    status    Show status of a service or all services
    logs      Show logs for a service
    exec      Execute command in a running service container
    list      List all available services
    cleanup   Clean up stopped containers and unused resources

ARGUMENTS:
    SERVICE   Service name (for service-specific actions)
    STACK     Stack name (for stack-wide actions)

OPTIONS:
    -f, --follow         Follow logs (for logs action)
    -n, --lines NUM      Number of log lines to show (default: $LOG_TAIL_LINES)
    --no-ui             Run without interactive UI

EXAMPLES:
    service list                    # List all services
    service status                  # Show all service statuses
    service start traefik          # Start Traefik service
    service stop core              # Stop all core services
    service restart pihole         # Restart Pi-hole service
    service logs traefik           # Show Traefik logs
    service logs traefik --follow  # Follow Traefik logs
    service exec authelia bash     # Execute bash in Authelia container
    service cleanup                # Clean up Docker resources

EOF
                exit 0
                ;;
            -f|--follow)
                follow_logs=true
                shift
                ;;
            -n|--lines)
                log_lines="$2"
                shift 2
                ;;
            --no-ui)
                non_interactive=true
                shift
                ;;
            start|stop|restart|status|logs|exec|list|cleanup)
                if [[ -z "$action" ]]; then
                    action="$1"
                else
                    if [[ -z "$service" ]]; then
                        service="$1"
                    else
                        print_error "Too many arguments"
                        exit 1
                    fi
                fi
                shift
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
    
    # Initialize script
    init_script "$SCRIPT_NAME" "$SCRIPT_VERSION"
    init_logging "$SCRIPT_NAME"
    
    # Check prerequisites
    if ! docker_available; then
        print_error "Docker is not available"
        exit 1
    fi
    
    # Execute action
    case "$action" in
        start)
            if [[ -n "$service" ]]; then
                # Check if it's a stack or service
                if [[ -d "$EZ_HOME/docker-compose/$service" ]]; then
                    start_stack_services "$service"
                else
                    start_service "$service"
                fi
            else
                print_error "Service or stack name required"
                exit 1
            fi
            ;;
        stop)
            if [[ -n "$service" ]]; then
                # Check if it's a stack or service
                if [[ -d "$EZ_HOME/docker-compose/$service" ]]; then
                    stop_stack_services "$service"
                else
                    stop_service "$service"
                fi
            else
                print_error "Service or stack name required"
                exit 1
            fi
            ;;
        restart)
            if [[ -n "$service" ]]; then
                # Check if it's a stack or service
                if [[ -d "$EZ_HOME/docker-compose/$service" ]]; then
                    stop_stack_services "$service" && start_stack_services "$service"
                else
                    restart_service "$service"
                fi
            else
                print_error "Service or stack name required"
                exit 1
            fi
            ;;
        status)
            if [[ -n "$service" ]]; then
                check_service_status "$service"
            else
                show_all_status
            fi
            ;;
        logs)
            if [[ -n "$service" ]]; then
                show_service_logs "$service" "$log_lines" "$follow_logs"
            else
                print_error "Service name required"
                exit 1
            fi
            ;;
        exec)
            if [[ -n "$service" ]]; then
                if [[ $# -gt 0 ]]; then
                    exec_service_command "$service" "$@"
                else
                    exec_service_command "$service" bash
                fi
            else
                print_error "Service name required"
                exit 1
            fi
            ;;
        list)
            list_services
            ;;
        cleanup)
            cleanup_services
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