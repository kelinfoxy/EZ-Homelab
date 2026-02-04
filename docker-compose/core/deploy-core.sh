#!/bin/bash
# Deploy core stack script
# Run from /opt/stacks/core/

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$HOME/EZ-Homelab"  
source "$REPO_DIR/scripts/common.sh"

log_info "Deploying core stack..."

# Load environment
load_env_file_safely "$REPO_DIR/.env"

# Copy fresh templates
# cp "$REPO_DIR/docker-compose/core/authelia/secrets/users_database.yml" "./authelia/secrets/users_database.yml"

# Localize labels in compose file (only replaces variables in labels, not environment sections)
localize_compose_labels docker-compose.yml

# Localize config files - Process all YAML config files (excluding docker-compose.yml)
# This performs FULL variable replacement on config files like:
# - authelia/config/configuration.yml
# - authelia/config/users_database.yml <- HANDLED SPECIALLY to preserve password hashes
# - traefik/dynamic/*.yml
#
# Why exclude docker-compose.yml?
# - It was already processed above with localize_compose_labels (labels-only replacement)
# - Config files need full replacement (including nested variables) while compose labels
#   should only have selective replacement to avoid Docker interpreting $ characters
#
# The localize_config_file function uses envsubst with recursive expansion to handle
# nested variables like ${AUTHELIA_ADMIN_PASSWORD_HASH} or ${SERVICE_NAME}.${DOMAIN}
# The localize_users_database_file function handles password hashes specially to avoid corruption
for config_file in $(find . -name "*.yml" -o -name "*.yaml" | grep -v docker-compose.yml); do
    # Only process files that contain variables (have ${ in them)
    if grep -q '\${' "$config_file"; then
        if [[ "$config_file" == *"users_database.yml" ]]; then
            localize_users_database_file "$config_file"
        else
            localize_config_file "$config_file"
        fi
    fi
done

# Deploy
run_cmd docker compose up -d

# Validate
if docker ps | grep -q traefik && docker ps | grep -q authelia; then
    log_success "Core stack deployed successfully"
    exit 0
else
    log_error "Core stack deployment failed"
    exit 1
fi
