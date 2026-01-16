#!/bin/bash
# AI-Homelab Resource Limits Application Script
# Applies researched resource limits to all Docker Compose stacks
# Run as: sudo ./apply-resource-limits.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (sudo ./apply-resource-limits.sh)"
    exit 1
fi

# Get actual user
ACTUAL_USER="${SUDO_USER:-$USER}"

log_info "Applying researched resource limits to all stacks..."
echo ""

# Function to add resource limits to a service in docker-compose.yml
add_resource_limits() {
    local compose_file="$1"
    local service_name="$2"
    local template="$3"

    # Define resource limits based on template
    case $template in
        "lightweight")
            limits="cpus: '0.25'\n        memory: 128M\n        pids: 256"
            reservations="cpus: '0.10'\n        memory: 64M"
            ;;
        "web")
            limits="cpus: '0.50'\n        memory: 256M\n        pids: 512"
            reservations="cpus: '0.25'\n        memory: 128M"
            ;;
        "database")
            limits="cpus: '1.0'\n        memory: 1G\n        pids: 1024"
            reservations="cpus: '0.50'\n        memory: 512M"
            ;;
        "media")
            limits="cpus: '2.0'\n        memory: 2G\n        pids: 2048"
            reservations="cpus: '1.0'\n        memory: 1G"
            ;;
        "downloader")
            limits="cpus: '1.0'\n        memory: 512M\n        pids: 1024"
            reservations="cpus: '0.50'\n        memory: 256M"
            ;;
        "heavy")
            limits="cpus: '1.5'\n        memory: 1G\n        pids: 2048"
            reservations="cpus: '0.75'\n        memory: 512M"
            ;;
        "monitoring")
            limits="cpus: '0.75'\n        memory: 512M\n        pids: 1024"
            reservations="cpus: '0.25'\n        memory: 256M"
            ;;
        *)
            log_warning "Unknown template: $template for $service_name"
            return
            ;;
    esac

    # Check if service already has deploy.resources
    if grep -A 10 "  $service_name:" "$compose_file" | grep -q "deploy:"; then
        log_warning "$service_name in $compose_file already has deploy section - skipping"
        return
    fi

    # Find the service definition and add deploy.resources after the image line
    if grep -q "^  $service_name:" "$compose_file"; then
        # Create a temporary file with the deploy section
        local deploy_section="    deploy:
      resources:
        limits:
          $limits
        reservations:
          $reservations"

        # Use awk to insert the deploy section after the image line
        awk -v service="$service_name" -v deploy="$deploy_section" '
        /^  '"$service_name"':/ { in_service=1 }
        in_service && /^    image:/ {
            print $0
            print deploy
            in_service=0
            next
        }
        { print }
        ' "$compose_file" > "${compose_file}.tmp" && mv "${compose_file}.tmp" "$compose_file"

        log_success "Added $template limits to $service_name in $(basename "$compose_file")"
    else
        log_warning "Service $service_name not found in $compose_file"
    fi
}

# Process each stack
STACKS_DIR="/opt/stacks"

# Core stack (already has some limits)
log_info "Processing core stack..."
if [ -f "$STACKS_DIR/core/docker-compose.yml" ]; then
    # DuckDNS is already done, check if others need limits
    if ! grep -A 5 "  authelia:" "$STACKS_DIR/core/docker-compose.yml" | grep -q "deploy:"; then
        add_resource_limits "$STACKS_DIR/core/docker-compose.yml" "authelia" "lightweight"
    fi
fi

# Infrastructure stack
log_info "Processing infrastructure stack..."
if [ -f "$STACKS_DIR/infrastructure/docker-compose.yml" ]; then
    add_resource_limits "$STACKS_DIR/infrastructure/docker-compose.yml" "pihole" "lightweight"
    add_resource_limits "$STACKS_DIR/infrastructure/docker-compose.yml" "dockge" "web"
    add_resource_limits "$STACKS_DIR/infrastructure/docker-compose.yml" "glances" "web"
fi

# Dashboard stack
log_info "Processing dashboard stack..."
if [ -f "$STACKS_DIR/dashboards/docker-compose.yml" ]; then
    add_resource_limits "$STACKS_DIR/dashboards/docker-compose.yml" "homepage" "web"
    add_resource_limits "$STACKS_DIR/dashboards/docker-compose.yml" "homarr" "web"
fi

# Media stack
log_info "Processing media stack..."
if [ -f "$STACKS_DIR/media/docker-compose.yml" ]; then
    add_resource_limits "$STACKS_DIR/media/docker-compose.yml" "jellyfin" "media"
    add_resource_limits "$STACKS_DIR/media/docker-compose.yml" "calibre-web" "web"
fi

# Downloaders stack
log_info "Processing downloaders stack..."
if [ -f "$STACKS_DIR/downloaders/docker-compose.yml" ]; then
    add_resource_limits "$STACKS_DIR/downloaders/docker-compose.yml" "qbittorrent" "downloader"
fi

# Home Assistant stack
log_info "Processing home assistant stack..."
if [ -f "$STACKS_DIR/homeassistant/docker-compose.yml" ]; then
    add_resource_limits "$STACKS_DIR/homeassistant/docker-compose.yml" "homeassistant" "heavy"
    add_resource_limits "$STACKS_DIR/homeassistant/docker-compose.yml" "esphome" "web"
    add_resource_limits "$STACKS_DIR/homeassistant/docker-compose.yml" "nodered" "web"
fi

# Productivity stack
log_info "Processing productivity stack..."
if [ -f "$STACKS_DIR/productivity/docker-compose.yml" ]; then
    add_resource_limits "$STACKS_DIR/productivity/docker-compose.yml" "nextcloud" "heavy"
    add_resource_limits "$STACKS_DIR/productivity/docker-compose.yml" "gitea" "web"
fi

# Monitoring stack
log_info "Processing monitoring stack..."
if [ -f "$STACKS_DIR/monitoring/docker-compose.yml" ]; then
    add_resource_limits "$STACKS_DIR/monitoring/docker-compose.yml" "prometheus" "monitoring"
    add_resource_limits "$STACKS_DIR/monitoring/docker-compose.yml" "grafana" "web"
    add_resource_limits "$STACKS_DIR/monitoring/docker-compose.yml" "loki" "monitoring"
    add_resource_limits "$STACKS_DIR/monitoring/docker-compose.yml" "uptime-kuma" "web"
fi

# Development stack
log_info "Processing development stack..."
if [ -f "$STACKS_DIR/development/docker-compose.yml" ]; then
    add_resource_limits "$STACKS_DIR/development/docker-compose.yml" "code-server" "heavy"
fi

# Fix ownership
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$STACKS_DIR"

echo ""
log_success "Resource limits application complete!"
echo ""
log_info "Next steps:"
echo "  1. Review the applied limits: docker compose config"
echo "  2. Deploy updated stacks: docker compose up -d"
echo "  3. Monitor usage: docker stats"
echo "  4. Adjust limits as needed based on real usage"
echo ""
log_info "Note: These are conservative defaults based on typical usage patterns."
log_info "Monitor actual resource usage and adjust limits accordingly."