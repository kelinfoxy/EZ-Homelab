#!/bin/bash
# AI-Homelab Test Environment Reset Script
# Safe cleanup for testing between rounds
# Run as: sudo ./reset-test-environment.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
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
    log_error "Please run as root (use: sudo ./reset-test-environment.sh)"
    exit 1
fi

# Get the actual user who invoked sudo
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ "$ACTUAL_USER" = "root" ]; then
    log_error "Please run this script with sudo, not as root user"
    exit 1
fi

echo "=========================================="
log_warning "AI-Homelab Test Environment Reset"
echo "=========================================="
echo ""
log_warning "This will safely remove all deployed services and data"
log_warning "This is intended for testing - DO NOT use in production!"
echo ""
read -p "Are you sure you want to reset? (type 'yes' to continue): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log_info "Reset cancelled"
    exit 0
fi

echo ""
log_info "Starting safe cleanup process..."
echo ""

# Step 1: Stop all Docker Compose stacks gracefully
log_info "Step 1/6: Stopping all Docker Compose stacks..."

if [ -d "/opt/stacks/dashboards" ]; then
    cd /opt/stacks/dashboards && docker compose down 2>/dev/null || true
    log_success "Dashboards stack stopped"
fi

if [ -d "/opt/stacks/infrastructure" ]; then
    cd /opt/stacks/infrastructure && docker compose down 2>/dev/null || true
    log_success "Infrastructure stack stopped"
fi

if [ -d "/opt/stacks/core" ]; then
    cd /opt/stacks/core && docker compose down 2>/dev/null || true
    log_success "Core stack stopped"
fi

# Wait for containers to fully stop
sleep 3
log_success "All stacks stopped gracefully"
echo ""

# Step 2: Remove Docker volumes (data will be lost)
log_info "Step 2/6: Removing Docker volumes..."

# List volumes to remove
VOLUMES=$(docker volume ls -q | grep -E "^(core_|infrastructure_|dashboards_)" 2>/dev/null || true)

if [ -n "$VOLUMES" ]; then
    echo "$VOLUMES" | while read vol; do
        docker volume rm "$vol" 2>/dev/null && log_success "Removed volume: $vol" || log_warning "Could not remove volume: $vol"
    done
else
    log_info "No homelab volumes found"
fi

echo ""

# Step 3: Remove stack directories (configs will be regenerated)
log_info "Step 3/6: Removing stack configuration directories..."

if [ -d "/opt/stacks" ]; then
    rm -rf /opt/stacks/core
    rm -rf /opt/stacks/infrastructure  
    rm -rf /opt/stacks/dashboards
    log_success "Stack directories removed"
else
    log_info "No stack directories found"
fi

if [ -d "/opt/dockge/data" ]; then
    rm -rf /opt/dockge/data/*
    log_success "Dockge data cleared"
fi

echo ""

# Step 4: Clean up temporary files
log_info "Step 4/6: Cleaning temporary files..."

rm -f /tmp/authelia_admin_credentials.tmp
rm -f /tmp/nvidia*.log
log_success "Temporary files cleaned"
echo ""

# Step 5: Remove Docker networks
log_info "Step 5/6: Removing Docker networks..."

docker network rm homelab-network 2>/dev/null && log_success "Removed homelab-network" || log_info "homelab-network not found"
docker network rm traefik-network 2>/dev/null && log_success "Removed traefik-network" || log_info "traefik-network not found"
docker network rm dockerproxy-network 2>/dev/null && log_success "Removed dockerproxy-network" || log_info "dockerproxy-network not found"
docker network rm media-network 2>/dev/null && log_success "Removed media-network" || log_info "media-network not found"

echo ""

# Step 6: Prune unused Docker resources
log_info "Step 6/6: Pruning unused Docker resources..."

docker system prune -f --volumes 2>&1 | grep -E "(Deleted|Total reclaimed)" || true
log_success "Docker cleanup complete"
echo ""

# Final summary
echo "=========================================="
log_success "Test environment reset complete!"
echo "=========================================="
echo ""
log_info "System is ready for next round of testing"
log_info ""
log_info "Next steps:"
echo "  1. Ensure .env file is properly configured"
echo "  2. Run: sudo ./setup-homelab.sh"
echo "  3. Run: sudo ./deploy-homelab.sh"
echo ""
log_info "Note: Docker and system packages are NOT removed"
log_info "User groups and firewall settings are preserved"
echo ""
