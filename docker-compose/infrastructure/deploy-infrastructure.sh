#!/bin/bash
# Deploy infrastructure stack script
# Run from /opt/stacks/infrastructure/

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="/home/kelin/EZ-Homelab"  # Fixed repo path since script runs from /opt/stacks/infrastructure
source "$REPO_DIR/scripts/common.sh"

log_info "Deploying infrastructure stack..."

# Load environment
load_env_file_safely .env

# Localize labels in compose file
localize_compose_labels docker-compose.yml

# Localize config files
for config_file in $(find . -name "*.yml" -o -name "*.yaml" | grep -v docker-compose.yml); do
    localize_config_file "$config_file"
done

# Deploy
run_cmd docker compose up -d

# Validate
if docker ps | grep -q pihole && docker ps | grep -q watchtower; then
    log_success "Infrastructure stack deployed successfully"
    exit 0
else
    log_error "Infrastructure stack deployment failed"
    exit 1
fi