#!/bin/bash
# EZ-Homelab Enhanced Setup - Main Menu
# Unified interface for all EZ-Homelab setup and management operations

SCRIPT_NAME="ez-homelab"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# MENU CONFIGURATION
# =============================================================================

# Menu options
MAIN_MENU_OPTIONS=(
    "System Setup & Validation"
    "Configuration Management"
    "Deployment & Services"
    "Monitoring & Maintenance"
    "Backup & Recovery"
    "Updates & Maintenance"
    "Advanced Options"
    "Exit"
)

SYSTEM_MENU_OPTIONS=(
    "Run System Preflight Check"
    "Install & Configure Docker"
    "Validate Docker Installation"
    "Check System Resources"
    "Back to Main Menu"
)

CONFIG_MENU_OPTIONS=(
    "Interactive Pre-deployment Wizard"
    "Localize Configuration Templates"
    "Generalize Configuration Files"
    "Validate All Configurations"
    "Show Current Configuration Status"
    "Back to Main Menu"
)

DEPLOY_MENU_OPTIONS=(
    "Deploy Core Services"
    "Deploy Infrastructure Services"
    "Deploy Monitoring Stack"
    "Deploy Media Services"
    "Deploy Productivity Services"
    "Deploy All Services"
    "Show Deployment Status"
    "Back to Main Menu"
)

MONITOR_MENU_OPTIONS=(
    "Show Monitoring Dashboard"
    "Monitor Service Health"
    "Monitor System Resources"
    "View Service Logs"
    "Continuous Monitoring Mode"
    "Back to Main Menu"
)

BACKUP_MENU_OPTIONS=(
    "Backup Configuration Files"
    "Backup Docker Volumes"
    "Backup System Logs"
    "Backup Everything"
    "List Available Backups"
    "Restore from Backup"
    "Setup Automated Backups"
    "Back to Main Menu"
)

UPDATE_MENU_OPTIONS=(
    "Check for Service Updates"
    "Update Individual Service"
    "Update All Services"
    "Show Update History"
    "Monitor Update Progress"
    "Setup Automated Updates"
    "Back to Main Menu"
)

ADVANCED_MENU_OPTIONS=(
    "Service Management Console"
    "Docker Compose Operations"
    "Network Configuration"
    "SSL Certificate Management"
    "System Maintenance"
    "Troubleshooting Tools"
    "View Logs"
    "Back to Main Menu"
)

# =============================================================================
# MENU DISPLAY FUNCTIONS
# =============================================================================

# Show main menu
show_main_menu() {
    echo
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                     EZ-HOMELAB SETUP                        ║"
    echo "║                   Enhanced Management System                ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  Welcome to EZ-Homelab! Choose an option below:             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Show system status header
show_system_status() {
    echo "System Status:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Docker status
    if docker_available; then
        echo "✅ Docker: Running"
    else
        echo "❌ Docker: Not available"
    fi

    # EZ-Homelab status
    if [[ -f "$EZ_HOME/.env" ]]; then
        echo "✅ Configuration: Found"
    else
        echo "⚠️  Configuration: Not found (run wizard first)"
    fi

    # Service count
    local service_count
    service_count=$(find_all_services | wc -l)
    if (( service_count > 0 )); then
        local running_count
        running_count=$(find_all_services | while read -r service; do is_service_running "$service" && echo "1"; done | wc -l)
        echo "✅ Services: $running_count/$service_count running"
    else
        echo "ℹ️  Services: None deployed yet"
    fi

    echo
}

# Generic menu display function
show_menu() {
    local title="$1"
    local options=("${@:2}")

    echo "╔══════════════════════════════════════════════════════════════╗"
    printf "║ %-60s ║\n" "$title"
    echo "╠══════════════════════════════════════════════════════════════╣"

    local i=1
    for option in "${options[@]}"; do
        printf "║  %-2d. %-55s ║\n" "$i" "$option"
        ((i++))
    done

    echo "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# =============================================================================
# MENU HANDLER FUNCTIONS
# =============================================================================

# Handle main menu selection
handle_main_menu() {
    local choice="$1"

    case "$choice" in
        1) show_system_menu ;;
        2) show_config_menu ;;
        3) show_deploy_menu ;;
        4) show_monitor_menu ;;
        5) show_backup_menu ;;
        6) show_update_menu ;;
        7) show_advanced_menu ;;
        8)
            echo
            print_info "Thank you for using EZ-Homelab!"
            echo "For documentation, visit: https://github.com/kelinfoxy/EZ-Homelab"
            echo
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please select 1-8."
            return 1
            ;;
    esac
}

# Handle system menu
handle_system_menu() {
    local choice="$1"

    case "$choice" in
        1)
            print_info "Running system preflight check..."
            ./preflight.sh
            ;;
        2)
            print_info "Installing and configuring Docker..."
            ./setup.sh
            ;;
        3)
            print_info "Validating Docker installation..."
            if docker_available; then
                print_success "Docker is properly installed and running"
                docker --version
                docker compose version
            else
                print_error "Docker is not available"
            fi
            ;;
        4)
            print_info "Checking system resources..."
            echo "CPU Cores: $(nproc)"
            echo "Total Memory: $(get_total_memory) MB"
            echo "Available Memory: $(get_available_memory) MB"
            echo "Disk Space: $(get_disk_space) GB available"
            echo "Architecture: $ARCH"
            echo "OS: $OS_NAME $OS_VERSION"
            ;;
        5) return 0 ;; # Back to main menu
        *)
            print_error "Invalid choice. Please select 1-5."
            return 1
            ;;
    esac

    echo
    read -rp "Press Enter to continue..."
}

# Handle configuration menu
handle_config_menu() {
    local choice="$1"

    case "$choice" in
        1)
            print_info "Starting interactive pre-deployment wizard..."
            ./pre-deployment-wizard.sh
            ;;
        2)
            print_info "Localizing configuration templates..."
            ./localize.sh
            ;;
        3)
            print_info "Generalizing configuration files..."
            ./generalize.sh
            ;;
        4)
            print_info "Validating all configurations..."
            ./validate.sh
            ;;
        5)
            print_info "Current configuration status:"
            if [[ -f "$EZ_HOME/.env" ]]; then
                echo "✅ Environment file found"
                grep -E "^[A-Z_]+" "$EZ_HOME/.env" | head -10
                echo "... (showing first 10 variables)"
            else
                echo "❌ No environment file found"
            fi

            if [[ -d "$EZ_HOME/docker-compose" ]]; then
                echo "✅ Docker compose directory found"
                local template_count
                template_count=$(find "$EZ_HOME/docker-compose" -name "*.template" | wc -l)
                echo "📄 Template files: $template_count"
            else
                echo "❌ Docker compose directory not found"
            fi
            ;;
        6) return 0 ;; # Back to main menu
        *)
            print_error "Invalid choice. Please select 1-6."
            return 1
            ;;
    esac

    echo
    read -rp "Press Enter to continue..."
}

# Handle deployment menu
handle_deploy_menu() {
    local choice="$1"

    case "$choice" in
        1)
            print_info "Deploying core services..."
            ./deploy.sh core
            ;;
        2)
            print_info "Deploying infrastructure services..."
            ./deploy.sh infrastructure
            ;;
        3)
            print_info "Deploying monitoring stack..."
            ./deploy.sh monitoring
            ;;
        4)
            print_info "Deploying media services..."
            ./deploy.sh media
            ;;
        5)
            print_info "Deploying productivity services..."
            ./deploy.sh productivity
            ;;
        6)
            print_info "Deploying all services..."
            ./deploy.sh all
            ;;
        7)
            print_info "Showing deployment status..."
            ./deploy.sh status
            ;;
        8) return 0 ;; # Back to main menu
        *)
            print_error "Invalid choice. Please select 1-8."
            return 1
            ;;
    esac

    echo
    read -rp "Press Enter to continue..."
}

# Handle monitoring menu
handle_monitor_menu() {
    local choice="$1"

    case "$choice" in
        1)
            print_info "Showing monitoring dashboard..."
            ./monitor.sh dashboard
            ;;
        2)
            print_info "Monitoring service health..."
            ./monitor.sh check
            ;;
        3)
            print_info "Monitoring system resources..."
            echo "System Resources:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ./monitor.sh check | grep -E "(CPU|Memory|Disk)"
            ;;
        4)
            echo "Available services:"
            ./service.sh list | grep "✅ Running" | head -10
            echo
            read -rp "Enter service name to view logs (or press Enter to skip): " service_name
            if [[ -n "$service_name" ]]; then
                ./service.sh logs "$service_name" -n 20
            fi
            ;;
        5)
            print_info "Starting continuous monitoring (Ctrl+C to stop)..."
            ./monitor.sh watch -i 30
            ;;
        6) return 0 ;; # Back to main menu
        *)
            print_error "Invalid choice. Please select 1-6."
            return 1
            ;;
    esac

    echo
    read -rp "Press Enter to continue..."
}

# Handle backup menu
handle_backup_menu() {
    local choice="$1"

    case "$choice" in
        1)
            print_info "Backing up configuration files..."
            ./backup.sh config
            ;;
        2)
            print_info "Backing up Docker volumes..."
            ./backup.sh volumes
            ;;
        3)
            print_info "Backing up system logs..."
            ./backup.sh logs
            ;;
        4)
            print_info "Backing up everything..."
            ./backup.sh all
            ;;
        5)
            echo "Available backups:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            ./backup.sh list config
            ./backup.sh list volumes
            ./backup.sh list logs
            ;;
        6)
            echo "Available backups:"
            ./backup.sh list config | grep -E "\.tar\.gzip$" | tail -5
            echo
            read -rp "Enter backup filename to restore (or press Enter to skip): " backup_file
            if [[ -n "$backup_file" ]]; then
                ./backup.sh config --restore "$backup_file"
            fi
            ;;
        7)
            print_info "Setting up automated backups..."
            ./backup.sh schedule
            ;;
        8) return 0 ;; # Back to main menu
        *)
            print_error "Invalid choice. Please select 1-8."
            return 1
            ;;
    esac

    echo
    read -rp "Press Enter to continue..."
}

# Handle update menu
handle_update_menu() {
    local choice="$1"

    case "$choice" in
        1)
            print_info "Checking for service updates..."
            ./update.sh check
            ;;
        2)
            echo "Available services:"
            ./service.sh list | grep "✅ Running" | head -10
            echo
            read -rp "Enter service name to update (or press Enter to skip): " service_name
            if [[ -n "$service_name" ]]; then
                ./update.sh update "$service_name"
            fi
            ;;
        3)
            print_warning "This will update all services. Continue? (y/N): "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                ./update.sh update all
            fi
            ;;
        4)
            print_info "Showing update history..."
            ./update.sh status
            ;;
        5)
            print_info "Monitoring update progress..."
            ./update.sh monitor
            ;;
        6)
            print_info "Setting up automated updates..."
            ./update.sh schedule
            ;;
        7) return 0 ;; # Back to main menu
        *)
            print_error "Invalid choice. Please select 1-7."
            return 1
            ;;
    esac

    echo
    read -rp "Press Enter to continue..."
}

# Handle advanced menu
handle_advanced_menu() {
    local choice="$1"

    case "$choice" in
        1)
            print_info "Service Management Console"
            echo "Available commands: start, stop, restart, status, logs, exec"
            echo "Example: start traefik, logs pihole, exec authelia bash"
            echo
            while true; do
                read -rp "service> " cmd
                if [[ "$cmd" == "exit" || "$cmd" == "quit" ]]; then
                    break
                fi
                if [[ -n "$cmd" ]]; then
                    ./service.sh $cmd
                fi
            done
            ;;
        2)
            print_info "Docker Compose Operations"
            echo "Available stacks:"
            find "$EZ_HOME/docker-compose" -name "docker-compose.yml" -exec dirname {} \; | xargs basename -a | sort
            echo
            read -rp "Enter stack name for compose operations (or press Enter to skip): " stack_name
            if [[ -n "$stack_name" ]]; then
                echo "Available operations: up, down, restart, logs, ps"
                read -rp "Operation: " operation
                if [[ -n "$operation" ]]; then
                    (cd "$EZ_HOME/docker-compose/$stack_name" && docker compose "$operation")
                fi
            fi
            ;;
        3)
            print_info "Network Configuration"
            echo "Docker Networks:"
            docker network ls
            echo
            echo "Container Ports:"
            docker ps --format "table {{.Names}}\t{{.Ports}}" | head -10
            ;;
        4)
            print_info "SSL Certificate Management"
            if docker ps | grep -q traefik; then
                echo "Traefik SSL Certificates:"
                docker exec traefik traefik healthcheck 2>/dev/null || echo "Traefik health check failed"
            else
                echo "Traefik is not running"
            fi
            ;;
        5)
            print_info "System Maintenance"
            echo "Docker System Cleanup:"
            docker system df
            echo
            read -rp "Run cleanup? (y/N): " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                ./service.sh cleanup
            fi
            ;;
        6)
            print_info "Troubleshooting Tools"
            echo "1. Test network connectivity"
            echo "2. Check Docker logs"
            echo "3. Validate configurations"
            echo "4. Show system information"
            read -rp "Choose option (1-4): " tool_choice
            case "$tool_choice" in
                1) ping -c 3 8.8.8.8 ;;
                2) docker logs $(docker ps -q | head -1) 2>/dev/null || echo "No containers running" ;;
                3) ./validate.sh ;;
                4) uname -a && docker --version ;;
            esac
            ;;
        7)
            print_info "Viewing logs..."
            echo "Available log files:"
            ls -la "$LOG_DIR"/*.log 2>/dev/null || echo "No log files found"
            echo
            read -rp "Enter log file to view (or press Enter to skip): " log_file
            if [[ -n "$log_file" && -f "$LOG_DIR/$log_file" ]]; then
                tail -50 "$LOG_DIR/$log_file"
            fi
            ;;
        8) return 0 ;; # Back to main menu
        *)
            print_error "Invalid choice. Please select 1-8."
            return 1
            ;;
    esac

    echo
    read -rp "Press Enter to continue..."
}

# =============================================================================
# MENU NAVIGATION FUNCTIONS
# =============================================================================

# Show system menu
show_system_menu() {
    while true; do
        show_menu "System Setup & Validation" "${SYSTEM_MENU_OPTIONS[@]}"
        read -rp "Choose an option (1-${#SYSTEM_MENU_OPTIONS[@]}): " choice

        if [[ "$choice" == "${#SYSTEM_MENU_OPTIONS[@]}" ]]; then
            break
        fi

        handle_system_menu "$choice"
    done
}

# Show configuration menu
show_config_menu() {
    while true; do
        show_menu "Configuration Management" "${CONFIG_MENU_OPTIONS[@]}"
        read -rp "Choose an option (1-${#CONFIG_MENU_OPTIONS[@]}): " choice

        if [[ "$choice" == "${#CONFIG_MENU_OPTIONS[@]}" ]]; then
            break
        fi

        handle_config_menu "$choice"
    done
}

# Show deployment menu
show_deploy_menu() {
    while true; do
        show_menu "Deployment & Services" "${DEPLOY_MENU_OPTIONS[@]}"
        read -rp "Choose an option (1-${#DEPLOY_MENU_OPTIONS[@]}): " choice

        if [[ "$choice" == "${#DEPLOY_MENU_OPTIONS[@]}" ]]; then
            break
        fi

        handle_deploy_menu "$choice"
    done
}

# Show monitoring menu
show_monitor_menu() {
    while true; do
        show_menu "Monitoring & Maintenance" "${MONITOR_MENU_OPTIONS[@]}"
        read -rp "Choose an option (1-${#MONITOR_MENU_OPTIONS[@]}): " choice

        if [[ "$choice" == "${#MONITOR_MENU_OPTIONS[@]}" ]]; then
            break
        fi

        handle_monitor_menu "$choice"
    done
}

# Show backup menu
show_backup_menu() {
    while true; do
        show_menu "Backup & Recovery" "${BACKUP_MENU_OPTIONS[@]}"
        read -rp "Choose an option (1-${#BACKUP_MENU_OPTIONS[@]}): " choice

        if [[ "$choice" == "${#BACKUP_MENU_OPTIONS[@]}" ]]; then
            break
        fi

        handle_backup_menu "$choice"
    done
}

# Show update menu
show_update_menu() {
    while true; do
        show_menu "Updates & Maintenance" "${UPDATE_MENU_OPTIONS[@]}"
        read -rp "Choose an option (1-${#UPDATE_MENU_OPTIONS[@]}): " choice

        if [[ "$choice" == "${#UPDATE_MENU_OPTIONS[@]}" ]]; then
            break
        fi

        handle_update_menu "$choice"
    done
}

# Show advanced menu
show_advanced_menu() {
    while true; do
        show_menu "Advanced Options" "${ADVANCED_MENU_OPTIONS[@]}"
        read -rp "Choose an option (1-${#ADVANCED_MENU_OPTIONS[@]}): " choice

        if [[ "$choice" == "${#ADVANCED_MENU_OPTIONS[@]}" ]]; then
            break
        fi

        handle_advanced_menu "$choice"
    done
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    # Initialize script
    init_script "$SCRIPT_NAME" "$SCRIPT_VERSION"
    init_logging "$SCRIPT_NAME"

    # Clear screen for clean menu display
    clear

    # Main menu loop
    while true; do
        show_main_menu
        show_system_status
        show_menu "Main Menu" "${MAIN_MENU_OPTIONS[@]}"

        read -rp "Choose an option (1-${#MAIN_MENU_OPTIONS[@]}): " choice

        if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#MAIN_MENU_OPTIONS[@]} )); then
            print_error "Invalid choice. Please enter a number between 1 and ${#MAIN_MENU_OPTIONS[@]}."
            echo
            read -rp "Press Enter to continue..."
            continue
        fi

        handle_main_menu "$choice"
    done
}

# Run main function
main "$@"