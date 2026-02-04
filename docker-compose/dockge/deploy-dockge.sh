#!/bin/bash
# Deploy Dockge stack script
# Run from /opt/dockge/

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="/home/kelin/EZ-Homelab"  # Fixed repo path since script runs from /opt/dockge
source "$REPO_DIR/scripts/common.sh"

log_info "Deploying Dockge stack..."

# Load environment
load_env_file_safely .env

# Remove sensitive variables from dockge .env (Dockge doesn't need them)
sed -i '/^AUTHELIA_ADMIN_PASSWORD_HASH=/d' .env
sed -i '/^AUTHELIA_JWT_SECRET=/d' .env
sed -i '/^AUTHELIA_SESSION_SECRET=/d' .env
sed -i '/^AUTHELIA_STORAGE_ENCRYPTION_KEY=/d' .env

# Localize labels in compose file
localize_compose_labels docker-compose.yml

# Deploy
run_cmd docker compose up -d

# Validate
if docker ps | grep -q dockge; then
    log_success "Dockge stack deployed successfully"
    exit 0
else
    log_error "Dockge stack deployment failed"
    exit 1
fi