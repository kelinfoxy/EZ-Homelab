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
log_warning "This will COMPLETELY remove all deployed services, containers, images, volumes, and data"
log_warning "This includes removing /opt/stacks and /opt/dockge directories"
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

# Step 1: Stop all running containers
log_info "Step 1/6: Stopping all running containers..."

# Get list of running containers
RUNNING_CONTAINERS=$(docker ps -q 2>/dev/null || true)

if [ -n "$RUNNING_CONTAINERS" ]; then
    log_info "Found running containers, stopping them..."
    docker stop $RUNNING_CONTAINERS 2>/dev/null && log_success "All containers stopped" || log_warning "Some containers may not have stopped cleanly"
else
    log_info "No running containers found"
fi

echo ""

# Step 2: Remove all containers
log_info "Step 2/6: Removing all containers..."

# Get list of all containers (running and stopped)
ALL_CONTAINERS=$(docker ps -a -q 2>/dev/null || true)

if [ -n "$ALL_CONTAINERS" ]; then
    log_info "Found containers to remove..."
    docker rm -f $ALL_CONTAINERS 2>/dev/null && log_success "All containers removed" || log_warning "Some containers may not have been removed"
else
    log_info "No containers found to remove"
fi

echo ""

# Step 3: Remove all Docker images (optional but thorough cleanup)
log_info "Step 3/6: Removing all Docker images..."

ALL_IMAGES=$(docker images -q 2>/dev/null || true)

if [ -n "$ALL_IMAGES" ]; then
    log_info "Found Docker images to remove..."
    docker rmi -f $ALL_IMAGES 2>/dev/null && log_success "All Docker images removed" || log_warning "Some images may not have been removed"
else
    log_info "No Docker images found to remove"
fi

echo ""

# Step 4: Remove Docker volumes
log_info "Step 4/6: Removing all Docker volumes..."

ALL_VOLUMES=$(docker volume ls -q 2>/dev/null || true)

if [ -n "$ALL_VOLUMES" ]; then
    log_info "Found Docker volumes to remove..."
    docker volume rm -f $ALL_VOLUMES 2>/dev/null && log_success "All Docker volumes removed" || log_warning "Some volumes may not have been removed"
else
    log_info "No Docker volumes found to remove"
fi

echo ""

# Step 5: Remove Docker networks
log_info "Step 5/6: Removing all Docker networks..."

ALL_NETWORKS=$(docker network ls -q 2>/dev/null | grep -v -E "(bridge|host|none)" || true)

if [ -n "$ALL_NETWORKS" ]; then
    log_info "Found Docker networks to remove..."
    docker network rm $ALL_NETWORKS 2>/dev/null && log_success "All custom Docker networks removed" || log_warning "Some networks may not have been removed"
else
    log_info "No custom Docker networks found to remove"
fi

echo ""

# Step 6: Remove deployment directories
log_info "Step 6/6: Removing deployment directories..."

if [ -d "/opt/stacks" ]; then
    rm -rf /opt/stacks
    log_success "Removed /opt/stacks directory"
else
    log_info "/opt/stacks directory not found"
fi

if [ -d "/opt/dockge" ]; then
    rm -rf /opt/dockge
    log_success "Removed /opt/dockge directory"
else
    log_info "/opt/dockge directory not found"
fi

echo ""

# Clean up temporary files
log_info "Cleaning up temporary files..."
rm -f /tmp/authelia_admin_credentials.tmp
rm -f /tmp/authelia_password_hash.tmp
rm -f /tmp/nvidia*.log
log_success "Temporary files cleaned"

echo ""

# Final Docker system cleanup
log_info "Performing final Docker system cleanup..."
docker system prune -f --volumes 2>&1 | grep -E "(Deleted|Total reclaimed)" || true
log_success "Docker system cleanup complete"

echo ""

# Final summary
echo "=========================================="
log_success "Test environment reset complete!"
echo "=========================================="
echo ""
log_info "System is ready for next round of testing"
echo ""
log_info "Next steps:"
echo "  1. Ensure .env file is properly configured"
echo "  2. Run: sudo ./setup-homelab.sh"
echo "  3. Run: sudo ./deploy-homelab.sh"
echo ""
log_info "Note: Docker and system packages are NOT removed"
log_info "User groups and firewall settings are preserved"
log_warning "WARNING: All containers, images, volumes, and deployment directories have been removed"
echo ""
