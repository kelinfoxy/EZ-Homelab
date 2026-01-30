#!/bin/bash
# EZ-Homelab Enhanced Setup Scripts - Backup Management
# Automated backup orchestration and restore operations

SCRIPT_NAME="backup"
SCRIPT_VERSION="1.0.0"

# Load common library
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# =============================================================================
# BACKUP CONFIGURATION
# =============================================================================

# Backup directories
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.ez-homelab/backups}"
BACKUP_CONFIG="${BACKUP_CONFIG:-$BACKUP_ROOT/config}"
BACKUP_DATA="${BACKUP_DATA:-$BACKUP_ROOT/data}"
BACKUP_LOGS="${BACKUP_LOGS:-$BACKUP_ROOT/logs}"

# Backup retention (days)
CONFIG_RETENTION_DAYS=30
DATA_RETENTION_DAYS=7
LOG_RETENTION_DAYS=7

# Backup schedule (cron format)
CONFIG_BACKUP_SCHEDULE="0 2 * * *"    # Daily at 2 AM
DATA_BACKUP_SCHEDULE="0 3 * * 0"     # Weekly on Sunday at 3 AM
LOG_BACKUP_SCHEDULE="0 1 * * *"      # Daily at 1 AM

# Compression settings
COMPRESSION_LEVEL=6
COMPRESSION_TYPE="gzip"

# =============================================================================
# BACKUP UTILITY FUNCTIONS
# =============================================================================

# Initialize backup directories
init_backup_dirs() {
    mkdir -p "$BACKUP_CONFIG" "$BACKUP_DATA" "$BACKUP_LOGS"
    
    # Create .gitkeep files to ensure directories are tracked
    touch "$BACKUP_CONFIG/.gitkeep" "$BACKUP_DATA/.gitkeep" "$BACKUP_LOGS/.gitkeep"
}

# Generate backup filename with timestamp
generate_backup_filename() {
    local prefix="$1"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    echo "${prefix}_${timestamp}.tar.${COMPRESSION_TYPE}"
}

# Compress directory
compress_directory() {
    local source_dir="$1"
    local archive_path="$2"
    
    print_info "Compressing $source_dir to $archive_path"
    
    case "$COMPRESSION_TYPE" in
        gzip)
            tar -czf "$archive_path" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
            ;;
        bzip2)
            tar -cjf "$archive_path" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
            ;;
        xz)
            tar -cJf "$archive_path" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
            ;;
        *)
            print_error "Unsupported compression type: $COMPRESSION_TYPE"
            return 1
            ;;
    esac
}

# Extract archive
extract_archive() {
    local archive_path="$1"
    local dest_dir="$2"
    
    print_info "Extracting $archive_path to $dest_dir"
    
    mkdir -p "$dest_dir"
    
    case "$COMPRESSION_TYPE" in
        gzip)
            tar -xzf "$archive_path" -C "$dest_dir"
            ;;
        bzip2)
            tar -xjf "$archive_path" -C "$dest_dir"
            ;;
        xz)
            tar -xJf "$archive_path" -C "$dest_dir"
            ;;
        *)
            print_error "Unsupported compression type: $COMPRESSION_TYPE"
            return 1
            ;;
    esac
}

# Clean old backups
cleanup_old_backups() {
    local backup_dir="$1"
    local retention_days="$2"
    local prefix="$3"
    
    print_info "Cleaning up backups older than ${retention_days} days in $backup_dir"
    
    # Find and remove old backups
    find "$backup_dir" -name "${prefix}_*.tar.${COMPRESSION_TYPE}" -type f -mtime +"$retention_days" -exec rm {} \; -print
}

# Get backup size
get_backup_size() {
    local backup_path="$1"
    
    if [[ -f "$backup_path" ]]; then
        du -h "$backup_path" | cut -f1
    else
        echo "N/A"
    fi
}

# List backups
list_backups() {
    local backup_dir="$1"
    local prefix="$2"
    
    echo "Backups in $backup_dir:"
    echo "----------------------------------------"
    
    local count=0
    while IFS= read -r -d '' file; do
        local size
        size=$(get_backup_size "$file")
        local mtime
        mtime=$(stat -c %y "$file" 2>/dev/null | cut -d'.' -f1 || echo "Unknown")
        
        printf "  %-40s %-8s %s\n" "$(basename "$file")" "$size" "$mtime"
        ((count++))
    done < <(find "$backup_dir" -name "${prefix}_*.tar.${COMPRESSION_TYPE}" -type f -print0 | sort -z)
    
    if (( count == 0 )); then
        echo "  No backups found"
    fi
    echo
}

# =============================================================================
# CONFIGURATION BACKUP FUNCTIONS
# =============================================================================

# Backup configuration files
backup_config() {
    print_info "Starting configuration backup"
    
    local temp_dir
    temp_dir=$(mktemp -d)
    local config_dir="$temp_dir/config"
    
    mkdir -p "$config_dir"
    
    # Backup EZ-Homelab configuration
    if [[ -d "$EZ_HOME" ]]; then
        print_info "Backing up EZ-Homelab configuration"
        cp -r "$EZ_HOME/docker-compose" "$config_dir/" 2>/dev/null || true
        cp -r "$EZ_HOME/templates" "$config_dir/" 2>/dev/null || true
        cp "$EZ_HOME/.env" "$config_dir/" 2>/dev/null || true
    fi
    
    # Backup Docker daemon config
    if [[ -f "/etc/docker/daemon.json" ]]; then
        print_info "Backing up Docker daemon configuration"
        mkdir -p "$config_dir/docker"
        cp "/etc/docker/daemon.json" "$config_dir/docker/" 2>/dev/null || true
    fi
    
    # Backup system configuration
    print_info "Backing up system configuration"
    mkdir -p "$config_dir/system"
    cp "/etc/hostname" "$config_dir/system/" 2>/dev/null || true
    cp "/etc/hosts" "$config_dir/system/" 2>/dev/null || true
    cp "/etc/resolv.conf" "$config_dir/system/" 2>/dev/null || true
    
    # Create backup archive
    local backup_file
    backup_file=$(generate_backup_filename "config")
    local backup_path="$BACKUP_CONFIG/$backup_file"
    
    if compress_directory "$config_dir" "$backup_path"; then
        print_success "Configuration backup completed: $backup_file"
        print_info "Backup size: $(get_backup_size "$backup_path")"
        
        # Cleanup old backups
        cleanup_old_backups "$BACKUP_CONFIG" "$CONFIG_RETENTION_DAYS" "config"
        
        # Cleanup temp directory
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Configuration backup failed"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Restore configuration
restore_config() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        print_error "Backup file name required"
        return 1
    fi
    
    local backup_path="$BACKUP_CONFIG/$backup_file"
    
    if [[ ! -f "$backup_path" ]]; then
        print_error "Backup file not found: $backup_path"
        return 1
    fi
    
    print_warning "This will overwrite existing configuration files. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Configuration restore cancelled"
        return 0
    fi
    
    print_info "Restoring configuration from $backup_file"
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if extract_archive "$backup_path" "$temp_dir"; then
        local extracted_dir="$temp_dir/config"
        
        # Restore EZ-Homelab configuration
        if [[ -d "$extracted_dir/docker-compose" ]]; then
            print_info "Restoring EZ-Homelab configuration"
            cp -r "$extracted_dir/docker-compose" "$EZ_HOME/" 2>/dev/null || true
        fi
        
        if [[ -d "$extracted_dir/templates" ]]; then
            cp -r "$extracted_dir/templates" "$EZ_HOME/" 2>/dev/null || true
        fi
        
        if [[ -f "$extracted_dir/.env" ]]; then
            cp "$extracted_dir/.env" "$EZ_HOME/" 2>/dev/null || true
        fi
        
        # Restore Docker configuration
        if [[ -f "$extracted_dir/docker/daemon.json" ]]; then
            print_info "Restoring Docker daemon configuration"
            sudo cp "$extracted_dir/docker/daemon.json" "/etc/docker/" 2>/dev/null || true
        fi
        
        # Restore system configuration
        if [[ -f "$extracted_dir/system/hostname" ]]; then
            print_info "Restoring system hostname"
            sudo cp "$extracted_dir/system/hostname" "/etc/" 2>/dev/null || true
        fi
        
        print_success "Configuration restore completed"
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Configuration restore failed"
        rm -rf "$temp_dir"
        return 1
    fi
}

# =============================================================================
# DATA BACKUP FUNCTIONS
# =============================================================================

# Backup Docker volumes
backup_docker_volumes() {
    print_info "Starting Docker volumes backup"
    
    local temp_dir
    temp_dir=$(mktemp -d)
    local volumes_dir="$temp_dir/volumes"
    
    mkdir -p "$volumes_dir"
    
    # Get all Docker volumes
    local volumes
    mapfile -t volumes < <(docker volume ls --format "{{.Name}}" 2>/dev/null | grep -E "^ez-homelab|^homelab" || true)
    
    if [[ ${#volumes[@]} -eq 0 ]]; then
        print_warning "No EZ-Homelab volumes found to backup"
        rm -rf "$temp_dir"
        return 0
    fi
    
    print_info "Found ${#volumes[@]} volumes to backup"
    
    for volume in "${volumes[@]}"; do
        print_info "Backing up volume: $volume"
        
        # Create a temporary container to backup the volume
        local container_name="ez_backup_${volume}_$(date +%s)"
        
        if docker run --rm -d --name "$container_name" -v "$volume:/data" alpine sleep 30 >/dev/null 2>&1; then
            # Copy volume data
            mkdir -p "$volumes_dir/$volume"
            docker cp "$container_name:/data/." "$volumes_dir/$volume/" 2>/dev/null || true
            
            # Clean up container
            docker stop "$container_name" >/dev/null 2>&1 || true
        else
            print_warning "Failed to backup volume: $volume"
        fi
    done
    
    # Create backup archive
    local backup_file
    backup_file=$(generate_backup_filename "volumes")
    local backup_path="$BACKUP_DATA/$backup_file"
    
    if compress_directory "$volumes_dir" "$backup_path"; then
        print_success "Docker volumes backup completed: $backup_file"
        print_info "Backup size: $(get_backup_size "$backup_path")"
        
        # Cleanup old backups
        cleanup_old_backups "$BACKUP_DATA" "$DATA_RETENTION_DAYS" "volumes"
        
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Docker volumes backup failed"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Restore Docker volumes
restore_docker_volumes() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        print_error "Backup file name required"
        return 1
    fi
    
    local backup_path="$BACKUP_DATA/$backup_file"
    
    if [[ ! -f "$backup_path" ]]; then
        print_error "Backup file not found: $backup_path"
        return 1
    fi
    
    print_warning "This will overwrite existing Docker volumes. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Docker volumes restore cancelled"
        return 0
    fi
    
    print_info "Restoring Docker volumes from $backup_file"
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if extract_archive "$backup_path" "$temp_dir"; then
        local volumes_dir="$temp_dir/volumes"
        
        # Restore each volume
        for volume_dir in "$volumes_dir"/*/; do
            if [[ -d "$volume_dir" ]]; then
                local volume_name
                volume_name=$(basename "$volume_dir")
                
                print_info "Restoring volume: $volume_name"
                
                # Create volume if it doesn't exist
                docker volume create "$volume_name" >/dev/null 2>&1 || true
                
                # Create temporary container to restore data
                local container_name="ez_restore_${volume_name}_$(date +%s)"
                
                if docker run --rm -d --name "$container_name" -v "$volume_name:/data" alpine sleep 30 >/dev/null 2>&1; then
                    # Copy data back
                    docker cp "$volume_dir/." "$container_name:/data/" 2>/dev/null || true
                    
                    # Clean up container
                    docker stop "$container_name" >/dev/null 2>&1 || true
                    
                    print_success "Volume restored: $volume_name"
                else
                    print_error "Failed to restore volume: $volume_name"
                fi
            fi
        done
        
        print_success "Docker volumes restore completed"
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Docker volumes restore failed"
        rm -rf "$temp_dir"
        return 1
    fi
}

# =============================================================================
# LOG BACKUP FUNCTIONS
# =============================================================================

# Backup logs
backup_logs() {
    print_info "Starting logs backup"
    
    local temp_dir
    temp_dir=$(mktemp -d)
    local logs_dir="$temp_dir/logs"
    
    mkdir -p "$logs_dir"
    
    # Backup EZ-Homelab logs
    if [[ -d "$LOG_DIR" ]]; then
        print_info "Backing up EZ-Homelab logs"
        cp -r "$LOG_DIR"/* "$logs_dir/" 2>/dev/null || true
    fi
    
    # Backup Docker logs
    print_info "Backing up Docker container logs"
    mkdir -p "$logs_dir/docker"
    
    # Get logs from running containers
    local containers
    mapfile -t containers < <(docker ps --format "{{.Names}}" 2>/dev/null || true)
    
    for container in "${containers[@]}"; do
        docker logs "$container" > "$logs_dir/docker/${container}.log" 2>&1 || true
    done
    
    # Backup system logs
    print_info "Backing up system logs"
    mkdir -p "$logs_dir/system"
    cp "/var/log/syslog" "$logs_dir/system/" 2>/dev/null || true
    cp "/var/log/auth.log" "$logs_dir/system/" 2>/dev/null || true
    cp "/var/log/kern.log" "$logs_dir/system/" 2>/dev/null || true
    
    # Create backup archive
    local backup_file
    backup_file=$(generate_backup_filename "logs")
    local backup_path="$BACKUP_LOGS/$backup_file"
    
    if compress_directory "$logs_dir" "$backup_path"; then
        print_success "Logs backup completed: $backup_file"
        print_info "Backup size: $(get_backup_size "$backup_path")"
        
        # Cleanup old backups
        cleanup_old_backups "$BACKUP_LOGS" "$LOG_RETENTION_DAYS" "logs"
        
        rm -rf "$temp_dir"
        return 0
    else
        print_error "Logs backup failed"
        rm -rf "$temp_dir"
        return 1
    fi
}

# =============================================================================
# SCHEDULED BACKUP FUNCTIONS
# =============================================================================

# Setup cron jobs for automated backups
setup_backup_schedule() {
    print_info "Setting up automated backup schedule"
    
    # Create backup script
    local backup_script="$BACKUP_ROOT/backup.sh"
    cat > "$backup_script" << 'EOF'
#!/bin/bash
# Automated backup script for EZ-Homelab

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts/enhanced-setup" && pwd)"

# Run backups
"$SCRIPT_DIR/backup.sh" config --quiet
"$SCRIPT_DIR/backup.sh" volumes --quiet
"$SCRIPT_DIR/backup.sh" logs --quiet

# Log completion
echo "$(date): Automated backup completed" >> "$HOME/.ez-homelab/logs/backup.log"
EOF
    
    chmod +x "$backup_script"
    
    # Add to crontab
    local cron_entry
    
    # Config backup (daily at 2 AM)
    cron_entry="$CONFIG_BACKUP_SCHEDULE $backup_script config"
    if ! crontab -l 2>/dev/null | grep -q "$backup_script config"; then
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        print_info "Added config backup to crontab: $cron_entry"
    fi
    
    # Data backup (weekly on Sunday at 3 AM)
    cron_entry="$DATA_BACKUP_SCHEDULE $backup_script volumes"
    if ! crontab -l 2>/dev/null | grep -q "$backup_script volumes"; then
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        print_info "Added volumes backup to crontab: $cron_entry"
    fi
    
    # Logs backup (daily at 1 AM)
    cron_entry="$LOG_BACKUP_SCHEDULE $backup_script logs"
    if ! crontab -l 2>/dev/null | grep -q "$backup_script logs"; then
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        print_info "Added logs backup to crontab: $cron_entry"
    fi
    
    print_success "Automated backup schedule configured"
}

# Remove backup schedule
remove_backup_schedule() {
    print_info "Removing automated backup schedule"
    
    # Remove from crontab
    crontab -l 2>/dev/null | grep -v "backup.sh" | crontab -
    
    print_success "Automated backup schedule removed"
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    local action=""
    local backup_file=""
    local quiet=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat << EOF
EZ-Homelab Backup Management

USAGE:
    backup [OPTIONS] <ACTION> [BACKUP_FILE]

ACTIONS:
    config          Backup/restore configuration files
    volumes         Backup/restore Docker volumes
    logs            Backup logs
    list            List available backups
    schedule        Setup automated backup schedule
    unschedule      Remove automated backup schedule
    all             Run all backup types

OPTIONS:
    -q, --quiet     Suppress non-error output
    --restore       Restore from backup (requires BACKUP_FILE)

EXAMPLES:
    backup config                           # Backup configuration
    backup config --restore config_20240129_020000.tar.gz
    backup volumes                          # Backup Docker volumes
    backup logs                             # Backup logs
    backup list config                      # List config backups
    backup schedule                         # Setup automated backups
    backup all                              # Run all backup types

EOF
                exit 0
                ;;
            -q|--quiet)
                quiet=true
                shift
                ;;
            --restore)
                action="restore"
                shift
                ;;
            config|volumes|logs|list|schedule|unschedule|all)
                action="$1"
                shift
                break
                ;;
            *)
                if [[ -z "$backup_file" ]]; then
                    backup_file="$1"
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
        if [[ -z "$backup_file" ]]; then
            backup_file="$1"
        else
            print_error "Too many arguments"
            exit 1
        fi
        shift
    done
    
    # Initialize script
    init_script "$SCRIPT_NAME" "$SCRIPT_VERSION"
    init_logging "$SCRIPT_NAME"
    init_backup_dirs
    
    # Check prerequisites
    if ! command_exists "tar"; then
        print_error "tar command not found. Please install tar."
        exit 1
    fi
    
    # Execute action
    case "$action" in
        config)
            if [[ "$action" == "restore" ]]; then
                restore_config "$backup_file"
            else
                backup_config
            fi
            ;;
        volumes)
            if [[ "$action" == "restore" ]]; then
                restore_docker_volumes "$backup_file"
            else
                backup_docker_volumes
            fi
            ;;
        logs)
            backup_logs
            ;;
        list)
            case "$backup_file" in
                config|"")
                    list_backups "$BACKUP_CONFIG" "config"
                    ;;
                volumes)
                    list_backups "$BACKUP_DATA" "volumes"
                    ;;
                logs)
                    list_backups "$BACKUP_LOGS" "logs"
                    ;;
                *)
                    print_error "Unknown backup type: $backup_file"
                    exit 1
                    ;;
            esac
            ;;
        schedule)
            setup_backup_schedule
            ;;
        unschedule)
            remove_backup_schedule
            ;;
        all)
            print_info "Running all backup types"
            backup_config && backup_docker_volumes && backup_logs
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