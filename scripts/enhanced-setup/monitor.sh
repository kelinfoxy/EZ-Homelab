#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Service Monitoring
# Real-time service monitoring and alerting

SCRIPT_NAME="monitor"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# MONITORING CONFIGURATION
# =============================================================================

# Monitoring intervals (seconds)
HEALTH_CHECK_INTERVAL=30
RESOURCE_CHECK_INTERVAL=60
LOG_CHECK_INTERVAL=300

# Alert thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=90

# Alert cooldown (seconds) - prevent alert spam
ALERT_COOLDOWN=300

# Monitoring state file
MONITOR_STATE_FILE="$LOG_DIR/monitor_state.json"

# =============================================================================
# MONITORING STATE MANAGEMENT
# =============================================================================

# Initialize monitoring state
init_monitor_state() {
    if [[ ! -f "$MONITOR_STATE_FILE" ]]; then
        cat > "$MONITOR_STATE_FILE" << EOF
{
  "services": {},
  "alerts": {},
  "last_check": $(date +%s),
  "system_stats": {}
}
EOF
    fi
}

# Update service state
update_service_state() {
    local service="$1"
    local status="$2"
    local timestamp
    timestamp=$(date +%s)
    
    # Use jq if available, otherwise use sed
    if command_exists "jq"; then
        jq --arg service "$service" --arg status "$status" --argjson timestamp "$timestamp" \
           '.services[$service] = {"status": $status, "last_update": $timestamp}' \
           "$MONITOR_STATE_FILE" > "${MONITOR_STATE_FILE}.tmp" && mv "${MONITOR_STATE_FILE}.tmp" "$MONITOR_STATE_FILE"
    else
        # Simple fallback without jq
        log_warn "jq not available, using basic state tracking"
    fi
}

# Check if alert should be sent (cooldown check)
should_alert() {
    local alert_key="$1"
    local current_time
    current_time=$(date +%s)
    
    if command_exists "jq"; then
        local last_alert
        last_alert=$(jq -r ".alerts[\"$alert_key\"] // 0" "$MONITOR_STATE_FILE")
        local time_diff=$((current_time - last_alert))
        
        if (( time_diff >= ALERT_COOLDOWN )); then
            # Update last alert time
            jq --arg alert_key "$alert_key" --argjson timestamp "$current_time" \
               '.alerts[$alert_key] = $timestamp' \
               "$MONITOR_STATE_FILE" > "${MONITOR_STATE_FILE}.tmp" && mv "${MONITOR_STATE_FILE}.tmp" "$MONITOR_STATE_FILE"
            return 0
        else
            return 1
        fi
    else
        # Without jq, always alert (no cooldown)
        return 0
    fi
}

# =============================================================================
# HEALTH MONITORING FUNCTIONS
# =============================================================================

# Check service health
check_service_health() {
    local service="$1"
    
    if ! is_service_running "$service"; then
        if should_alert "service_down_$service"; then
            print_error "ALERT: Service '$service' is down"
            log_error "Service '$service' is down"
        fi
        update_service_state "$service" "down"
        return 1
    fi
    
    # Check container health status
    local health_status
    health_status=$(docker inspect "$service" --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    
    case "$health_status" in
        "healthy")
            update_service_state "$service" "healthy"
            ;;
        "unhealthy")
            if should_alert "service_unhealthy_$service"; then
                print_warning "ALERT: Service '$service' is unhealthy"
                log_warn "Service '$service' is unhealthy"
            fi
            update_service_state "$service" "unhealthy"
            return 1
            ;;
        "starting")
            update_service_state "$service" "starting"
            ;;
        *)
            update_service_state "$service" "unknown"
            ;;
    esac
    
    return 0
}

# Check all services health
check_all_services_health() {
    print_info "Checking service health..."
    
    local services
    mapfile -t services < <(find_all_services)
    local unhealthy_count=0
    
    for service in "${services[@]}"; do
        if ! check_service_health "$service"; then
            ((unhealthy_count++))
        fi
    done
    
    if (( unhealthy_count == 0 )); then
        print_success "All services are healthy"
    else
        print_warning "$unhealthy_count service(s) have issues"
    fi
}

# =============================================================================
# RESOURCE MONITORING FUNCTIONS
# =============================================================================

# Check system resources
check_system_resources() {
    print_info "Checking system resources..."
    
    # CPU usage
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    cpu_usage=$(printf "%.0f" "$cpu_usage")
    
    if (( cpu_usage > CPU_THRESHOLD )); then
        if should_alert "high_cpu"; then
            print_error "ALERT: High CPU usage: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
            log_error "High CPU usage: ${cpu_usage}%"
        fi
    fi
    
    # Memory usage
    local memory_usage
    memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    
    if (( memory_usage > MEMORY_THRESHOLD )); then
        if should_alert "high_memory"; then
            print_error "ALERT: High memory usage: ${memory_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
            log_error "High memory usage: ${memory_usage}%"
        fi
    fi
    
    # Disk usage
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if (( disk_usage > DISK_THRESHOLD )); then
        if should_alert "high_disk"; then
            print_error "ALERT: High disk usage: ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
            log_error "High disk usage: ${disk_usage}%"
        fi
    fi
    
    print_info "CPU: ${cpu_usage}%, Memory: ${memory_usage}%, Disk: ${disk_usage}%"
}

# Check Docker resource usage
check_docker_resources() {
    print_info "Checking Docker resources..."
    
    # Get container resource usage
    if command_exists "docker" && docker_available; then
        local containers
        mapfile -t containers < <(docker ps --format "{{.Names}}")
        
        for container in "${containers[@]}"; do
            local stats
            stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemPerc}}" "$container" 2>/dev/null | tail -n 1)
            
            if [[ -n "$stats" ]]; then
                local cpu_perc mem_perc
                cpu_perc=$(echo "$stats" | awk '{print $2}' | sed 's/%//')
                mem_perc=$(echo "$stats" | awk '{print $3}' | sed 's/%//')
                
                # Convert to numbers for comparison
                cpu_perc=${cpu_perc%.*}
                mem_perc=${mem_perc%.*}
                
                if [[ "$cpu_perc" =~ ^[0-9]+$ ]] && (( cpu_perc > CPU_THRESHOLD )); then
                    if should_alert "container_high_cpu_$container"; then
                        print_warning "ALERT: Container '$container' high CPU: ${cpu_perc}%"
                        log_warn "Container '$container' high CPU: ${cpu_perc}%"
                    fi
                fi
                
                if [[ "$mem_perc" =~ ^[0-9]+$ ]] && (( mem_perc > MEMORY_THRESHOLD )); then
                    if should_alert "container_high_memory_$container"; then
                        print_warning "ALERT: Container '$container' high memory: ${mem_perc}%"
                        log_warn "Container '$container' high memory: ${mem_perc}%"
                    fi
                fi
            fi
        done
    fi
}

# =============================================================================
# LOG MONITORING FUNCTIONS
# =============================================================================

# Check service logs for errors
check_service_logs() {
    local service="$1"
    local since="${2:-1m}"  # Default to last minute
    
    if ! is_service_running "$service"; then
        return 0
    fi
    
    local compose_file
    compose_file=$(get_service_compose_file "$service")
    if [[ -z "$compose_file" ]]; then
        return 1
    fi
    
    local compose_dir=$(dirname "$compose_file")
    local compose_base=$(basename "$compose_file")
    
    # Check for error patterns in recent logs
    local error_patterns=("ERROR" "error" "Exception" "failed" "Failed" "panic" "PANIC")
    local errors_found=()
    
    for pattern in "${error_patterns[@]}"; do
        local error_count
        error_count=$(cd "$compose_dir" && docker compose logs --since="$since" "$service" 2>&1 | grep -c "$pattern" || true)
        
        if (( error_count > 0 )); then
            errors_found+=("$pattern: $error_count")
        fi
    done
    
    if [[ ${#errors_found[@]} -gt 0 ]]; then
        if should_alert "log_errors_$service"; then
            print_warning "ALERT: Service '$service' has errors in logs: ${errors_found[*]}"
            log_warn "Service '$service' log errors: ${errors_found[*]}"
        fi
    fi
}

# Check all services logs
check_all_logs() {
    print_info "Checking service logs for errors..."
    
    local services
    mapfile -t services < <(find_all_services)
    
    for service in "${services[@]}"; do
        check_service_logs "$service"
    done
}

# =============================================================================
# MONITORING DISPLAY FUNCTIONS
# =============================================================================

# Display monitoring dashboard
show_monitoring_dashboard() {
    print_info "EZ-Homelab Monitoring Dashboard"
    echo
    
    # System resources
    echo "=== System Resources ==="
    local cpu_usage memory_usage disk_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' || echo "0")
    memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}' || echo "0")
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")
    
    echo "CPU Usage:    ${cpu_usage}%"
    echo "Memory Usage: ${memory_usage}%"
    echo "Disk Usage:   ${disk_usage}%"
    echo
    
    # Service status summary
    echo "=== Service Status ==="
    local services=()
    mapfile -t services < <(find_all_services)
    local total_services=${#services[@]}
    local running_services=0
    local unhealthy_services=0
    
    for service in "${services[@]}"; do
        if is_service_running "$service"; then
            running_services=$((running_services + 1))
            
            local health_status
            health_status=$(docker inspect "$service" --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
            if [[ "$health_status" == "unhealthy" ]]; then
                unhealthy_services=$((unhealthy_services + 1))
            fi
        fi
    done
    
    echo "Total Services: $total_services"
    echo "Running:        $running_services"
    echo "Unhealthy:      $unhealthy_services"
    echo
    
    # Recent alerts
    echo "=== Recent Alerts ==="
    if command_exists "jq" && [[ -f "$MONITOR_STATE_FILE" ]]; then
        local recent_alerts
        recent_alerts=$(jq -r '.alerts | to_entries[] | select(.value > (now - 3600)) | "\(.key): \(.value | strftime("%H:%M:%S"))"' "$MONITOR_STATE_FILE" 2>/dev/null || echo "")
        
        if [[ -n "$recent_alerts" ]]; then
            echo "$recent_alerts"
        else
            echo "No recent alerts (last hour)"
        fi
    else
        echo "Alert history not available (jq not installed)"
    fi
}

# Display detailed service status
show_detailed_status() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        print_error "Service name required"
        return 1
    fi
    
    print_info "Detailed Status for: $service"
    echo
    
    if ! is_service_running "$service"; then
        echo "Status: ❌ Stopped"
        return 0
    fi
    
    echo "Status: ✅ Running"
    
    # Container details
    local container_info
    container_info=$(docker ps --filter "name=^${service}$" --format "table {{.Image}}\t{{.Status}}\t{{.Ports}}" | tail -n +2)
    if [[ -n "$container_info" ]]; then
        echo "Container: $container_info"
    fi
    
    # Health status
    local health_status
    health_status=$(docker inspect "$service" --format '{{.State.Health.Status}}' 2>/dev/null || echo "N/A")
    echo "Health: $health_status"
    
    # Resource usage
    local stats
    stats=$(docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" "$service" 2>/dev/null | tail -n +2)
    if [[ -n "$stats" ]]; then
        echo "Resources: $stats"
    fi
    
    # Recent logs
    echo
    echo "Recent Logs:"
    local compose_file
    compose_file=$(get_service_compose_file "$service")
    if [[ -n "$compose_file" ]]; then
        local compose_dir=$(dirname "$compose_file")
        local compose_base=$(basename "$compose_file")
        (cd "$compose_dir" && docker compose logs --tail=5 "$service" 2>/dev/null || echo "No logs available")
    fi
}

# =============================================================================
# CONTINUOUS MONITORING FUNCTIONS
# =============================================================================

# Run continuous monitoring
run_continuous_monitoring() {
    local interval="${1:-$HEALTH_CHECK_INTERVAL}"
    
    print_info "Starting continuous monitoring (interval: ${interval}s)"
    print_info "Press Ctrl+C to stop"
    
    # Initialize state
    init_monitor_state
    
    # Main monitoring loop
    while true; do
        local start_time
        start_time=$(date +%s)
        
        # Run all checks
        check_all_services_health
        check_system_resources
        check_docker_resources
        check_all_logs
        
        # Update timestamp
        if command_exists "jq"; then
            jq --argjson timestamp "$(date +%s)" '.last_check = $timestamp' \
               "$MONITOR_STATE_FILE" > "${MONITOR_STATE_FILE}.tmp" && mv "${MONITOR_STATE_FILE}.tmp" "$MONITOR_STATE_FILE"
        fi
        
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        print_info "Monitoring cycle completed in ${duration}s. Next check in $((interval - duration))s..."
        
        # Sleep for remaining time
        local sleep_time=$((interval - duration))
        if (( sleep_time > 0 )); then
            sleep "$sleep_time"
        fi
    done
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local action=""
    local service=""
    local interval="$HEALTH_CHECK_INTERVAL"
    local continuous=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat << EOF
EZ-Homelab Service Monitoring

USAGE:
    monitor [OPTIONS] <ACTION> [SERVICE]

ACTIONS:
    dashboard     Show monitoring dashboard
    status        Show detailed status for a service
    check         Run all monitoring checks once
    watch         Continuous monitoring mode

OPTIONS:
    -i, --interval SEC    Monitoring interval in seconds (default: $HEALTH_CHECK_INTERVAL)
    -c, --continuous      Run in continuous mode (same as 'watch')

EXAMPLES:
    monitor dashboard           # Show monitoring dashboard
    monitor status traefik      # Show detailed status for Traefik
    monitor check               # Run all checks once
    monitor watch               # Start continuous monitoring
    monitor watch -i 60         # Continuous monitoring every 60 seconds

EOF
                exit 0
                ;;
            -i|--interval)
                interval="$2"
                shift 2
                ;;
            -c|--continuous)
                continuous=true
                shift
                ;;
            dashboard|status|check|watch)
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
    init_monitor_state
    
    # Check prerequisites
    if ! docker_available; then
        print_error "Docker is not available"
        exit 1
    fi
    
    # Execute action
    case "$action" in
        dashboard)
            show_monitoring_dashboard
            ;;
        status)
            if [[ -n "$service" ]]; then
                show_detailed_status "$service"
            else
                print_error "Service name required for status action"
                exit 1
            fi
            ;;
        check)
            check_all_services_health
            check_system_resources
            check_docker_resources
            check_all_logs
            ;;
        watch)
            run_continuous_monitoring "$interval"
            ;;
        "")
            # Default action: show dashboard
            show_monitoring_dashboard
            ;;
        *)
            print_error "Unknown action: $action"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"