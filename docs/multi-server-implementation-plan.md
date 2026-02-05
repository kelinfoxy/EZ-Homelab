# Multi-Server Traefik and Sablier Implementation Plan

## Executive Summary

This document outlines the implementation plan for enabling label-based automatic routing and lazy loading across multiple servers in the EZ-Homelab infrastructure. The goals are to:

1. **Traefik Multi-Server Setup**: Enable Traefik on the core server to automatically discover and route to Docker services on remote servers using labels, eliminating manual YAML file maintenance.
2. **Per-Server Sablier Deployment**: Deploy Sablier instances on each server to control local lazy loading, eliminating docker-proxy dependencies for Sablier control.

## System Constraints

**Development/Test Environment**: Raspberry Pi 4 (4GB RAM)
- **Critical**: Avoid memory-intensive operations that could hang the system
- **Strategy**: Use lightweight validation, avoid large file operations in memory, implement timeouts
- **Monitoring**: Check process resource usage before long-running operations

## Current State Analysis

### Working Components (DO NOT MODIFY)
- ✅ Prerequisites installation (Docker, packages)
- ✅ Core stack deployment (DuckDNS, Traefik, Authelia)
- ✅ TLS certificate generation for docker-proxy
- ✅ Variable replacement in labels (`localize_compose_labels`)
- ✅ Variable replacement in config files (`localize_config_file`, `localize_users_database_file`)
- ✅ Image tags and service configurations

### Current Architecture

#### Traefik Configuration
- **Static Config** (`traefik.yml`): Single Docker provider (local socket)
- **Dynamic Config** (`dynamic/*.yml`): Manual YAML files for external hosts
- **Problem**: Each non-local service requires manual YAML file creation in `/opt/stacks/core/traefik/dynamic/external-host-*.yml`

#### Sablier Configuration
- **Current**: Single Sablier instance on core server
- **Remote Control**: Uses `DOCKER_HOST=tcp://remote-ip:2376` with TLS
- **Problem**: Centralized control requires docker-proxy on all servers; single point of failure

#### TLS Infrastructure
- **Already Working**: `setup_docker_tls()` function generates:
  - CA certificates
  - Server certificates
  - Client certificates
  - Configures Docker daemon for TLS on port 2376

## Proposed Architecture

### Overview
```
┌─────────────────────────────────────────────────────────────────┐
│  Router (Ports 80/443 forwarded to Core Server)                 │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  CORE SERVER                                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Traefik (Multiple Docker Providers)                        │ │
│  │  • Local Docker Provider: /var/run/docker.sock            │ │
│  │  • Remote Provider 1: tcp://remote1-ip:2376 (TLS)         │ │
│  │  • Remote Provider 2: tcp://remote2-ip:2376 (TLS)         │ │
│  │  • Auto-discovers all containers with traefik.enable=true │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Sablier (Local Control Only)                               │ │
│  │  • DOCKER_HOST: unix:///var/run/docker.sock               │ │
│  │  • Controls only core server containers                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Shared CA: /opt/stacks/core/shared-ca/                     │ │
│  │  • ca.pem, ca-key.pem (distributed to all servers)        │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           │
                ┌──────────┴──────────┐
                ▼                     ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│  REMOTE SERVER 1         │  │  REMOTE SERVER 2         │
│  ┌────────────────────┐  │  │  ┌────────────────────┐  │
│  │ Docker Daemon      │  │  │  │ Docker Daemon      │  │
│  │ Port: 2376 (TLS)   │  │  │  │ Port: 2376 (TLS)   │  │
│  │ Uses shared CA     │  │  │  │ Uses shared CA     │  │
│  └────────────────────┘  │  │  └────────────────────┘  │
│  ┌────────────────────┐  │  │  ┌────────────────────┐  │
│  │ Sablier (Local)    │  │  │  │ Sablier (Local)    │  │
│  │ Controls local     │  │  │  │ Controls local     │  │
│  │ containers only    │  │  │  │ containers only    │  │
│  └────────────────────┘  │  │  └────────────────────┘  │
└──────────────────────────┘  └──────────────────────────┘
```

### Key Changes

#### 1. Traefik Multi-Provider Configuration
**Location**: `/opt/stacks/core/traefik/config/traefik.yml`

**Change**: Modify `providers.docker` section to support multiple endpoints

```yaml
providers:
  docker:
    # Local Docker provider (always present)
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: "traefik-network"
    watch: true
    
  # Additional remote Docker providers (added dynamically)
  docker-remote1:
    endpoint: "tcp://REMOTE1_IP:2376"
    exposedByDefault: false
    network: "traefik-network"
    watch: true
    tls:
      ca: "/certs/ca.pem"
      cert: "/certs/client-cert.pem"
      key: "/certs/client-key.pem"
      insecureSkipVerify: false
      
  # Pattern repeats for each remote server
```

**Note**: Traefik v3 supports multiple Docker providers with different names. Each remote server gets its own provider definition.

#### 2. Sablier Per-Server Deployment
**Current**: One Sablier in core stack with remote docker-proxy  
**Proposed**: Sablier as separate stack, deployed on each server (core, remote1, remote2, etc.)

**Sablier Stack** (identical on all servers):
```yaml
# /opt/stacks/sablier/docker-compose.yml
services:
  sablier:
    image: sablierapp/sablier:latest
    container_name: sablier
    restart: unless-stopped
    networks:
      - traefik-network
    environment:
      - SABLIER_PROVIDER=docker
      - DOCKER_HOST=unix:///var/run/docker.sock  # Local only
      - SABLIER_DOCKER_NETWORK=traefik-network
      - SABLIER_LOG_LEVEL=info
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - 10000:10000  # Accessible from core Traefik for middleware

networks:
  traefik-network:
    external: true
```

**Key Change**: Sablier moved from core stack to dedicated stack for consistency across servers

**Sablier Middleware Labels** (per service):
```yaml
labels:
  - "sablier.enable=true"
  - "sablier.group=${SERVER_HOSTNAME}-servicename"
  - "traefik.http.routers.service.middlewares=sablier-${SERVER_HOSTNAME}-servicename@file,authelia@docker"
```

**Note**: Container name changed from `sablier-service` to `sablier` for consistency

**Dynamic Sablier Middleware Config** (per server):
```yaml
# /opt/stacks/core/traefik/dynamic/sablier-remote1.yml
http:
  middlewares:
    sablier-remote1-service:
      plugin:
        sablier:
          sablierUrl: http://REMOTE1_IP:10000  # Points to remote Sablier
          group: remote1-service
          sessionDuration: 30m
```

## Implementation Plan

### Phase 1: Shared CA Infrastructure (Already Complete)

**Status**: ✅ Already implemented in `generate_shared_ca()` and `setup_multi_server_tls()`

**Components**:
- `generate_shared_ca()`: Creates `/opt/stacks/core/shared-ca/` with ca.pem and ca-key.pem
- `setup_multi_server_tls()`: Fetches shared CA from core server via SSH/SCP
- `setup_docker_tls()`: Uses shared CA to generate server/client certs

**No changes needed** - this infrastructure already supports multi-server TLS.

---

### Phase 2: Script Enhancements

#### 2.1 New Functions in `scripts/common.sh`

**Purpose**: Shared utilities for multi-server management

```bash
# Function: detect_server_role
# Purpose: Determine if this is a core server or remote server
# Logic:
#   - Checks if CORE_SERVER_IP is set in .env
#   - If empty or matches SERVER_IP: this is core
#   - If different: this is remote
# Returns: "core" or "remote"
detect_server_role() {
    local server_ip="${SERVER_IP}"
    local core_ip="${CORE_SERVER_IP:-}"
    
    if [ -z "$core_ip" ] || [ "$core_ip" == "$server_ip" ]; then
        echo "core"
    else
        echo "remote"
    fi
}

# Function: generate_traefik_provider_config
# Purpose: Generate a Traefik Docker provider block for a remote server
# Input: $1 = provider name (e.g., "docker-remote1")
#        $2 = remote server IP
#        $3 = TLS certs directory
# Output: YAML snippet for traefik.yml providers section
# Usage: Called when adding a new remote server to core
generate_traefik_provider_config() {
    local provider_name="$1"
    local remote_ip="$2"
    local tls_dir="$3"
    
    cat <<EOF
  ${provider_name}:
    endpoint: "tcp://${remote_ip}:2376"
    exposedByDefault: false
    network: "traefik-network"
    watch: true
    tls:
      ca: "${tls_dir}/ca.pem"
      cert: "${tls_dir}/client-cert.pem"
      key: "${tls_dir}/client-key.pem"
      insecureSkipVerify: false
EOF
}

# Function: generate_sablier_middleware_config
# Purpose: Generate Sablier middleware config for a remote server
# Input: $1 = server hostname
#        $2 = remote server IP
#        $3 = service name
# Output: YAML file in /opt/stacks/core/traefik/dynamic/
# Usage: Auto-generate middleware configs for remote Sablier instances
generate_sablier_middleware_config() {
    local server_hostname="$1"
    local remote_ip="$2"
    local service_name="$3"
    
    local output_file="/opt/stacks/core/traefik/dynamic/sablier-${server_hostname}-${service_name}.yml"
    
    cat > "$output_file" <<EOF
# Auto-generated Sablier middleware for ${server_hostname}
# Generated: $(date)
http:
  middlewares:
    sablier-${server_hostname}-${service_name}:
      plugin:
        sablier:
          sablierUrl: http://${remote_ip}:10000
          group: ${server_hostname}-${service_name}
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: ${service_name^}  # Capitalize first letter
            theme: ghost
            show-details-by-default: true
EOF
    
    log_success "Generated Sablier middleware: $output_file"
}

# Function: add_remote_server_to_traefik
# Purpose: Add a new remote server to core Traefik configuration
# Input: $1 = remote server hostname
#        $2 = remote server IP
# Process:
#   1. Generate provider config block
#   2. Append to traefik.yml (if not already present)
#   3. Generate Sablier middleware template
#   4. Restart Traefik to apply changes
# Usage: Called on core server when adding a new remote
add_remote_server_to_traefik() {
    local remote_hostname="$1"
    local remote_ip="$2"
    local traefik_config="/opt/stacks/core/traefik/config/traefik.yml"
    local provider_name="docker-${remote_hostname}"
    
    log_info "Adding remote server ${remote_hostname} (${remote_ip}) to Traefik..."
    
    # Check if provider already exists
    if grep -q "  ${provider_name}:" "$traefik_config"; then
        log_warning "Provider ${provider_name} already exists in Traefik config"
        return 0
    fi
    
    # Generate provider config
    local provider_config=$(generate_traefik_provider_config \
        "$provider_name" \
        "$remote_ip" \
        "/certs")
    
    # Append to traefik.yml under providers section
    # Note: Requires careful YAML formatting
    # Find the line with "providers:" and append after the last provider
    awk -v config="$provider_config" '
        /^providers:/ { in_providers=1; print; next }
        in_providers && /^[^ ]/ { print config; in_providers=0 }
        { print }
        END { if (in_providers) print config }
    ' "$traefik_config" > "${traefik_config}.tmp"
    
    mv "${traefik_config}.tmp" "$traefik_config"
    
    log_success "Added provider ${provider_name} to Traefik config"
    
    # Generate base Sablier middleware config
    generate_sablier_middleware_config "$remote_hostname" "$remote_ip" "example"
    
    log_warning "Restart Traefik for changes to take effect: docker compose -f /opt/stacks/core/docker-compose.yml restart traefik"
}
```

#### 2.2 Enhancements to Existing Functions in `scripts/ez-homelab.sh`

**Purpose**: Enhance existing validation and workflow functions

```bash
# Function: check_docker_installed (NEW)
# Purpose: Silently check if Docker is installed and running
# Returns: 0 if Docker ready, 1 if not
# Note: Lightweight check to avoid hanging on limited resources (Pi 4 4GB)
check_docker_installed() {
    # Quick check without spawning heavy processes
    if command -v docker >/dev/null 2>&1; then
        # Verify Docker daemon is responsive (with timeout)
        if timeout 3 docker ps >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Modification to REQUIRED_VARS (EXISTING - line 398)
# Purpose: Make REQUIRED_VARS dynamic based on deployment type
# Current: REQUIRED_VARS=("SERVER_IP" "SERVER_HOSTNAME" "DUCKDNS_SUBDOMAINS" "DUCKDNS_TOKEN" "DOMAIN" "DEFAULT_USER" "DEFAULT_PASSWORD" "DEFAULT_EMAIL")
# Enhancement: Add function to set required vars based on deployment choice
set_required_vars_for_deployment() {
    local deployment_type="${1:-core}"
    
    if [ "$deployment_type" == "core" ]; then
        # Core deployment requires DuckDNS and domain variables
        REQUIRED_VARS=("SERVER_IP" "SERVER_HOSTNAME" "DUCKDNS_SUBDOMAINS" "DUCKDNS_TOKEN" "DOMAIN" "DEFAULT_USER" "DEFAULT_PASSWORD" "DEFAULT_EMAIL")
    elif [ "$deployment_type" == "remote" ]; then
        # Remote deployment requires remote server connection variables
        REQUIRED_VARS=("SERVER_IP" "SERVER_HOSTNAME" "REMOTE_SERVER_IP" "REMOTE_SERVER_HOSTNAME" "REMOTE_SERVER_USER" "DEFAULT_USER" "DEFAULT_EMAIL")
    fi
}

# Enhancement to validate_and_prompt_variables() (EXISTING - line 562)
# Purpose: Existing function already validates and prompts for missing variables
# No changes needed - this function already:
#   1. Checks if each var in REQUIRED_VARS is valid
#   2. Prompts user for invalid/missing values
#   3. Loops until all valid
# Simply call set_required_vars_for_deployment() before calling this function

# Function: register_remote_server_with_core
# Purpose: After deploying remote server, register it with core Traefik
# Process:
#   1. Use variables from .env (REMOTE_SERVER_IP, REMOTE_SERVER_USER, etc.)
#   2. Only prompt for missing/invalid values
#   3. SSH to core server and run registration
#   4. Restart Traefik to apply changes
# Usage: Called at end of remote server deployment
# Note: Uses existing .env variables to minimize user interaction
register_remote_server_with_core() {
    log_info "Registering this server with core Traefik..."
    
    # Load variables from .env
    local remote_ip="${REMOTE_SERVER_IP:-}"
    local remote_hostname="${REMOTE_SERVER_HOSTNAME:-}"
    local remote_user="${REMOTE_SERVER_USER:-${ACTUAL_USER}}"
    local remote_password="${REMOTE_SERVER_PASSWORD:-}"
    
    # Validate and prompt only for missing values
    if [ -z "$remote_ip" ] || [[ "$remote_ip" == your.* ]]; then
        read -p "Core server IP address: " remote_ip
        sed -i "s|^REMOTE_SERVER_IP=.*|REMOTE_SERVER_IP=$remote_ip|" "$REPO_DIR/.env"
    fi
    
    if [ -z "$remote_hostname" ] || [[ "$remote_hostname" == your-* ]]; then
        read -p "Core server hostname [$(echo $remote_ip | tr '.' '-')]: " remote_hostname
        remote_hostname=${remote_hostname:-$(echo $remote_ip | tr '.' '-')}
        sed -i "s|^REMOTE_SERVER_HOSTNAME=.*|REMOTE_SERVER_HOSTNAME=$remote_hostname|" "$REPO_DIR/.env"
    fi
    
    if [ -z "$remote_user" ]; then
        read -p "SSH username for core server [${ACTUAL_USER}]: " remote_user
        remote_user=${remote_user:-$ACTUAL_USER}
        sed -i "s|^REMOTE_SERVER_USER=.*|REMOTE_SERVER_USER=$remote_user|" "$REPO_DIR/.env"
    fi
    
    echo ""
    echo "Registering with core server: ${remote_user}@${remote_ip} (${remote_hostname})"
    read -p "Proceed? (y/n) [y]: " register_choice
    register_choice=${register_choice:-y}
    
    if [ "$register_choice" != "y" ]; then
        log_warning "Skipping registration. Manual steps:"
        echo "  1. SSH to core: ssh ${remote_user}@${remote_ip}"
        echo "  2. Run: cd ~/EZ-Homelab && source scripts/common.sh"
        echo "  3. Run: add_remote_server_to_traefik ${SERVER_HOSTNAME} ${SERVER_IP}"
        echo "  4. Restart Traefik: docker compose -f /opt/stacks/core/docker-compose.yml restart traefik"
        return 0
    fi
    
    # Test SSH connection with timeout (Pi resource constraint)
    log_info "Testing SSH connection..."
    if ! timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
         "${remote_user}@${remote_ip}" "echo 'SSH OK'" 2>/dev/null; then
        log_error "Cannot connect to core server via SSH"
        log_warning "Check: SSH keys configured, core server reachable, user has access"
        return 1
    fi
    
    # Execute registration on core server (with timeout for Pi)
    log_info "Executing registration on core server..."
    timeout 30 ssh "${remote_user}@${remote_ip}" bash <<EOF
cd ~/EZ-Homelab
source scripts/common.sh
add_remote_server_to_traefik "${SERVER_HOSTNAME}" "${SERVER_IP}"
docker compose -f /opt/stacks/core/docker-compose.yml restart traefik
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Server registered with core Traefik"
        log_success "Services with traefik.enable=true will now auto-route"
    else
        log_error "Registration failed or timed out"
        log_warning "Try manual registration (see above)"
    fi
}
```

#### 2.3 Modifications to Core Stack Compose File

**Changes**: Remove Sablier from core stack (moved to separate stack)

**Location**: `docker-compose/core/docker-compose.yml`

**Action**: Delete the `sablier-service` section entirely from core compose file

**Rationale**: 
- Sablier will be deployed as a separate stack (`/opt/stacks/sablier/`)
- Keeps core stack focused on routing/auth (DuckDNS, Traefik, Authelia)
- Allows consistent Sablier deployment across core and remote servers
- No script modifications needed - changes are in repo compose files

#### 2.4 New Sablier Stack

**Location**: `docker-compose/sablier/docker-compose.yml`

```yaml
# Sablier Stack - Lazy Loading Service
# Deploy on ALL servers (core and remote) for local container control
#
# This stack is identical on all servers - no configuration differences needed
# Sablier controls only containers on the local server via Docker socket

services:
  sablier:
    image: sablierapp/sablier:latest
    container_name: sablier
    restart: unless-stopped
    networks:
      - traefik-network
    environment:
      - SABLIER_PROVIDER=docker
      - SABLIER_DOCKER_API_VERSION=1.51
      - SABLIER_DOCKER_NETWORK=traefik-network
      - SABLIER_LOG_LEVEL=info
      # Local Docker socket only - no remote access needed
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "10000:10000"
    labels:
      - "homelab.category=infrastructure"
      - "homelab.description=Lazy loading service for local containers"

networks:
  traefik-network:
    external: true

x-dockge:
  urls:
    - http://${SERVER_IP}:10000
```

**Deployment**: 
- Core server: Deployed automatically after core stack
- Remote servers: Deployed automatically during remote setup
```

#### 2.5 New Deployment Function for Remote Server

**Purpose**: Deploy remote server infrastructure (Docker TLS + Sablier)

```bash
# Function: deploy_remote_server
# Purpose: Deploy Docker TLS and Sablier on remote servers
# Process:
#   1. Validate required variables using existing mechanism
#   2. Setup Docker TLS using shared CA from core
#   3. Deploy Sablier stack (from repo compose file)
#   4. Configure firewall for port 2376
#   5. Register with core Traefik
# Note: Optimized for Pi 4 - uses timeouts and lightweight operations
deploy_remote_server() {
    log_info "Deploying remote server infrastructure..."
    
    # Set required variables for remote deployment
    set_required_vars_for_deployment "remote"
    
    # Use existing validation and prompting function
    # This will check all variables in REQUIRED_VARS and prompt for missing/invalid ones
    validate_and_prompt_variables
    
    # Save updated configuration
    save_env_file
    
    log_info "  - Docker TLS (port 2376)"
    log_info "  - Sablier stack (lazy loading)"
    echo ""
    
    # Ensure shared CA is fetched from core
    if [ ! -f "/opt/stacks/core/shared-ca/ca.pem" ]; then
        log_info "Fetching shared CA from core server..."
        setup_multi_server_tls
        if [ $? -ne 0 ]; then
            log_error "Failed to fetch shared CA from core server"
            log_warning "Ensure core server is accessible and has shared CA"
            return 1
        fi
    fi
    
    # Setup Docker TLS with shared CA
    setup_docker_tls
    
    # Deploy Sablier stack (using repo compose file, not generated)
    log_info "Deploying Sablier stack..."
    sudo mkdir -p /opt/stacks/sablier
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/sablier
    
    # Copy compose file from repo
    sudo cp "$REPO_DIR/docker-compose/sablier/docker-compose.yml" /opt/stacks/sablier/docker-compose.yml
    sudo cp "$REPO_DIR/.env" /opt/stacks/sablier/.env
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/sablier/docker-compose.yml
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/sablier/.env
    
    # Remove sensitive variables from Sablier .env
    sed -i '/^AUTHELIA_/d' /opt/stacks/sablier/.env
    
    # Deploy (with timeout for Pi resource constraint)
    cd /opt/stacks/sablier
    timeout 60 docker compose up -d || {
        log_error "Sablier deployment timed out or failed"
        return 1
    }
    
    log_success "Sablier stack deployed"
    
    # Configure firewall for Docker API access
    if command -v ufw >/dev/null 2>&1; then
        log_info "Configuring firewall for Docker API access..."
        sudo ufw allow from "${CORE_SERVER_IP}" to any port 2376 proto tcp
        log_success "Firewall configured"
    fi
    
    # Register with core Traefik
    register_remote_server_with_core
    
    echo ""
    log_success "Remote server setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy additional stacks (media, productivity, etc.)"
    echo "  2. Use Traefik labels as usual - routing is automatic"
    echo "  3. Use Sablier labels for lazy loading local services"
    echo ""
}
```

#### 2.6 Enhanced Main Workflow in `scripts/ez-homelab.sh`

**Changes**: Keep existing menu, add smart pre-checks and use existing validation

```bash
# Main workflow enhancement - called at script start
main() {
    # ... existing args parsing ...
    
    # STEP 1: Silent Docker check (lightweight for Pi)
    if ! check_docker_installed; then
        # Docker not installed - only show prerequisites option
        echo ""
        echo "=================================================="
        echo "  EZ-Homelab Setup"
        echo "=================================================="
        echo ""
        echo "Docker is not installed or not running."
        echo ""
        echo "  1) Install Prerequisites (Docker, packages)"
        echo "  2) Exit"
        echo ""
        read -p "Selection: " pre_choice
        
        case $pre_choice in
            1)
                prepare_deployment
                # After install, restart script to show full menu
                exec "$0" "$@"
                ;;
            2)
                exit 0
                ;;
            *)
                log_error "Invalid selection"
                exit 1
                ;;
        esac
    fi
    
    # STEP 2: Docker installed - show existing main menu
    show_main_menu
    
    read -p "Selection: " DEPLOY_CHOICE
    
    case $DEPLOY_CHOICE in
        1)
            # Install prerequisites (if needed)
            ;;
        2)
            # Deploy Core
            # Set required variables for core deployment
            set_required_vars_for_deployment "core"
            # Use existing validation function - prompts for missing/invalid vars
            validate_and_prompt_variables
            # Save configuration
            save_env_file
            DEPLOY_CORE=true
            ;;
        3)
            # Deploy Additional Server (Remote)
            # Set required variables for remote deployment
            set_required_vars_for_deployment "remote"
            # Use existing validation function - prompts for all required remote vars
            validate_and_prompt_variables
            # Save configuration
            save_env_file
            # Deploy remote infrastructure
            deploy_remote_server
            ;;
        # ... rest of existing menu options ...
    esac
    
    # ... rest of existing main logic ...
}

**Key Points**:
- **Reuses existing code**: `validate_and_prompt_variables()` already handles validation and prompting
- **Dynamic requirements**: `set_required_vars_for_deployment()` adjusts REQUIRED_VARS based on deployment type
- **No manual .env editing**: Script always prompts for missing/invalid variables
- **Existing logic preserved**: No changes to prompt_for_variable() or validation logic
```

**Key Changes**:
- **Pre-check**: Silent Docker check before showing menu
- **Minimal Menu**: If no Docker, only show "Install Prerequisites"
- **Keep Existing**: Main menu unchanged (user's requirement)
- **Smart Validation**: Check .env before core/remote deployments
- **Existing Prompts**: Reuse `validate_and_prompt_variables` function
- **Pi-Friendly**: All checks use timeouts and lightweight operations
```

---

### Phase 3: Configuration Files

#### 3.1 Updated `docker-compose/core/traefik/traefik.yml`

**Changes**: Add commented template for remote providers

**Note**: The `config-templates/` folder is deprecated. All working configs are in `docker-compose/` folder.

```yaml
# Traefik Static Configuration
# Source: docker-compose/core/traefik/traefik.yml

experimental:
  plugins:
    sablier:
      moduleName: github.com/sablierapp/sablier-traefik-plugin
      version: v1.1.0

providers:
  # Local Docker provider (always enabled)
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: "traefik-network"
    watch: true
  
  # REMOTE DOCKER PROVIDERS
  # Uncomment and configure for each remote server in your homelab
  # These are auto-added by the add_remote_server_to_traefik function
  # when deploying remote servers
  
  # Example remote provider (auto-generated):
  # docker-remote1:
  #   endpoint: "tcp://192.168.1.100:2376"
  #   exposedByDefault: false
  #   network: "traefik-network"
  #   watch: true
  #   tls:
  #     ca: "/certs/ca.pem"
  #     cert: "/certs/client-cert.pem"
  #     key: "/certs/client-key.pem"
  #     insecureSkipVerify: false

  # File provider for dynamic configuration
  file:
    directory: /dynamic
    watch: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
  traefik:
    address: ":8080"

certificatesResolvers:
  letsencrypt:
    acme:
      dnsChallenge:
        provider: duckdns
      email: ${DEFAULT_EMAIL}
      storage: /letsencrypt/acme.json

log:
  level: DEBUG

accessLog:
  format: json

api:
  dashboard: true
  insecure: true

ping:
  manualRouting: true
```

#### 3.2 Updated Core `docker-compose.yml`

**Changes**: Remove Sablier section entirely (moved to separate stack)

**Action**: Delete the entire `sablier-service` section from `docker-compose/core/docker-compose.yml`

**Rationale**: 
- Sablier is now a separate, reusable stack
- Core stack focuses on: DuckDNS, Traefik, Authelia only
- Sablier deployed separately on all servers (core and remote)

#### 3.3 New Sablier Stack Template

**Location**: `docker-compose/sablier/docker-compose.yml`

```yaml
# Sablier Stack - Lazy Loading Service
# Deploy on ALL servers (core and remote) for local container control
#
# This stack is identical on all servers - no configuration differences needed
# Sablier controls only containers on the local server via Docker socket
#
# Deployment:
#   - Core server: Deployed automatically after core stack
#   - Remote servers: Deployed automatically during remote setup

services:
  sablier:
    image: sablierapp/sablier:latest
    container_name: sablier
    restart: unless-stopped
    networks:
      - traefik-network
    environment:
      - SABLIER_PROVIDER=docker
      - SABLIER_DOCKER_API_VERSION=1.51
      - SABLIER_DOCKER_NETWORK=traefik-network
      - SABLIER_LOG_LEVEL=info
      # Local Docker socket only - no remote Docker access needed
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "10000:10000"
    labels:
      - "homelab.category=infrastructure"
      - "homelab.description=Lazy loading service for local containers"
      # No Traefik routing labels - accessed directly by Traefik plugin

networks:
  traefik-network:
    external: true

x-dockge:
  urls:
    - http://${SERVER_IP}:10000
```

**Key Change**: Container name `sablier` (not `sablier-service`) for consistency

---

### Phase 4: Deployment Workflow

#### 4.1 Core Server Setup (First Server)

**User Actions**:
```bash
# 1. Clone repository and run setup
cd ~/EZ-Homelab
./scripts/ez-homelab.sh

# 2. If Docker not installed:
#    - Script shows limited menu: "1) Install Prerequisites"
#    - Select option 1, script installs Docker
#    - Script restarts and shows full menu

# 3. Select "2) Deploy Core"
#    - Script validates .env
#    - If invalid/missing: runs configuration wizard
#    - Deploys: DuckDNS, Traefik, Authelia
#    - Generates shared CA in /opt/stacks/core/shared-ca/
#    - Automatically deploys Sablier stack

# 4. Select "3) Infrastructure" (optional)
#    - Dockge, Portainer, etc.

# 5. Deploy other stacks as needed
```

**Script Behavior**:
- Pre-check: Silently checks Docker (lightweight, Pi-safe)
- If no Docker: Shows only "Install Prerequisites" option
- If Docker present: Shows full existing menu (unchanged)
- Option 2 (Deploy Core):
  - Validates .env for core variables
  - Runs existing prompt function if needed
  - Deploys core stack (DuckDNS, Traefik, Authelia)
  - Automatically deploys Sablier stack after core
  - Role detection: REMOTE_SERVER_IP empty or equals SERVER_IP → Core server

#### 4.2 Remote Server Setup (Additional Servers)

**User Actions**:
```bash
# 1. Clone repository and run setup on remote server
cd ~/EZ-Homelab
./scripts/ez-homelab.sh

# 2. If Docker not installed:
#    - Script shows limited menu: "1) Install Prerequisites"
#    - Select option 1, script installs Docker
#    - Script restarts and shows full menu

# 3. Select "3) Deploy Additional Server"
#    - Script prompts for all required variables:
#      * SERVER_IP (this server's IP)
#      * SERVER_HOSTNAME (this server's hostname)
#      * REMOTE_SERVER_IP (core server IP)
#      * REMOTE_SERVER_HOSTNAME (core server hostname)
#      * REMOTE_SERVER_USER (SSH user on core)
#      * DEFAULT_USER (default user)
#      * DEFAULT_EMAIL (default email)
#    - Script validates each value
#    - Saves to .env file

# Note: Editing .env manually is optional - script will prompt for everything

# 4. After configuration:
#    - Script validates .env for remote variables
#    - If missing/invalid: prompts only for those variables
#    - Fetches shared CA from core server via SSH (with timeout)
#    - Configures Docker TLS (port 2376)
#    - Deploys Sablier stack (local control)
#    - Prompts to register with core Traefik

# 5. Registration (semi-automatic):
#    - Uses REMOTE_SERVER_* variables from .env
#    - Only prompts for missing values
#    - SSH to core server (with 10s timeout - Pi-safe)
#    - Runs add_remote_server_to_traefik on core
#    - Restarts Traefik on core

# 6. Deploy additional stacks via Dockge
#    - Use standard Traefik labels
#    - Services auto-route through core
```

**Script Behavior**:
- Pre-check: Docker installed (same as core)
- Option 3 (Deploy Additional Server):
  - Sets REQUIRED_VARS to include remote server variables:
    * SERVER_IP, SERVER_HOSTNAME (this server)
    * REMOTE_SERVER_IP, REMOTE_SERVER_HOSTNAME, REMOTE_SERVER_USER (core server)
    * DEFAULT_USER, DEFAULT_EMAIL
  - Calls existing `validate_and_prompt_variables()` function
  - Prompts for ALL variables in REQUIRED_VARS (validates and prompts if missing/invalid)
  - Saves complete configuration to .env
  - Fetches shared CA via SSH (timeout 30s for Pi)
  - Configures Docker TLS with shared CA
  - Deploys Sablier stack from repo compose file
  - Registration: uses saved .env variables
  - All operations have timeouts (Pi resource constraint)

#### 4.3 Label-Based Service Deployment

**Example Service on Remote Server**:

```yaml
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    restart: unless-stopped
    networks:
      - traefik-network
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ./sonarr/config:/config
      - /mnt/media:/media
    labels:
      # TRAEFIK ROUTING (automatic via core Traefik)
      - "traefik.enable=true"
      - "traefik.http.routers.sonarr.rule=Host(`sonarr.${DOMAIN}`)"
      - "traefik.http.routers.sonarr.entrypoints=websecure"
      - "traefik.http.routers.sonarr.tls.certresolver=letsencrypt"
      - "traefik.http.routers.sonarr.middlewares=authelia@docker"
      - "traefik.http.services.sonarr.loadbalancer.server.port=8989"
      
      # SABLIER LAZY LOADING (local Sablier control)
      - "sablier.enable=true"
      - "sablier.group=${SERVER_HOSTNAME}-arr"
      # Middleware points to remote Sablier via dynamic config
      # Generated by add_remote_server_to_traefik function

networks:
  traefik-network:
    external: true
```

**How it works**:
1. Container starts on remote server (e.g., `remote1`)
2. Traefik on core server discovers it via `docker-remote1` provider
3. Traefik reads labels and creates router: `sonarr.domain.com` → `http://remote1-ip:8989`
4. SSL certificate issued by core Traefik (Let's Encrypt)
5. Sablier middleware points to `http://remote1-ip:10000` for lazy loading
6. User accesses `sonarr.domain.com` → Routes through core → Reaches remote container

**No manual YAML files required** - everything is label-driven!

---

### Phase 5: Testing Strategy

#### 5.1 Unit Tests

**Test 1: Server Role Detection**
```bash
# Test: Core server detection
export SERVER_IP="192.168.1.10"
export CORE_SERVER_IP=""
result=$(detect_server_role)
assert_equals "$result" "core"

# Test: Remote server detection
export CORE_SERVER_IP="192.168.1.10"
export SERVER_IP="192.168.1.20"
result=$(detect_server_role)
assert_equals "$result" "remote"
```

**Test 2: Traefik Provider Generation**
```bash
# Test: Provider config generation
config=$(generate_traefik_provider_config "docker-remote1" "192.168.1.20" "/certs")
assert_contains "$config" "docker-remote1:"
assert_contains "$config" "tcp://192.168.1.20:2376"
```

#### 5.2 Integration Tests

**Test 1: Core Server Deployment**
1. Deploy core stack on fresh Debian VM
2. Verify Traefik has single local Docker provider
3. Verify Sablier uses local Docker socket
4. Check shared CA exists: `/opt/stacks/core/shared-ca/ca.pem`

**Test 2: Remote Server Deployment**
1. Deploy remote infrastructure on second VM
2. Verify Docker TLS listening on port 2376
3. Verify Sablier uses local Docker socket
4. Verify registration added provider to core Traefik
5. Test: `docker -H tcp://remote-ip:2376 --tlsverify ps` from core

**Test 3: Label-Based Routing**
1. Deploy test service on remote with Traefik labels
2. Verify Traefik discovers service (check dashboard)
3. Verify DNS resolves: `nslookup test.domain.com`
4. Verify HTTPS access: `curl https://test.domain.com`
5. Check certificate issued by core Traefik

**Test 4: Lazy Loading**
1. Deploy service with Sablier labels on remote
2. Stop service manually
3. Access via browser
4. Verify Sablier loading page appears
5. Verify service starts within 30 seconds
6. Verify service accessible after start

#### 5.3 Rollback Testing

**Test: Manual Provider Removal**
```bash
# Remove provider from traefik.yml
sed -i '/docker-remote1:/,/insecureSkipVerify: false/d' \
    /opt/stacks/core/traefik/config/traefik.yml

# Restart Traefik
docker compose -f /opt/stacks/core/docker-compose.yml restart traefik

# Verify remote services no longer accessible
curl -I https://remote-service.domain.com  # Should fail
```

---

## Migration Path

### For Existing Deployments

**Scenario**: User has existing EZ-Homelab with manual external host YAML files

#### Step 1: Verify Automatic Backups

**Important**: The deploy scripts should automatically backup configurations before making changes.

**Current Backup Location Check**:
```bash
# Verify deploy-core.sh backs up from /opt/stacks/core/ (correct)
# NOT from ~/EZ-Homelab/docker-compose/core/ (incorrect - repo source files)

# Expected backup in deploy_core():
# cp -r /opt/stacks/core/traefik /opt/stacks/core/traefik.backup.$(date +%Y%m%d-%H%M%S)
```

**Action Required**: Review `scripts/ez-homelab.sh` deploy functions to ensure:
- Backups are created from `/opt/stacks/*/` (deployed location)
- NOT from `~/EZ-Homelab/docker-compose/*/` (repo source)
- Timestamped backups for rollback capability

**If Backups Not Working**:
```bash
# Manual backup as safety measure
cp -r /opt/stacks/core/traefik /opt/stacks/core/traefik.backup.$(date +%Y%m%d-%H%M%S)
```

#### Step 2: Update Core Server
```bash
# Pull latest repository changes
cd ~/EZ-Homelab
git pull

# Important: Traefik dynamic folder files need replacement
# Old method files (external-host-*.yml) will be replaced with:
#   - Updated sablier.yml (with per-server middleware configs)
#   - Auto-generated provider-specific configs

# Run deployment to update configs
./scripts/ez-homelab.sh
# Select: 2) Deploy Core (will update all configs)
```

#### Step 3: Configure Remote Servers
For each remote server that currently has manual YAML entries:

```bash
# 1. SSH to remote server
ssh remote-server

# 2. Setup Docker TLS
./scripts/ez-homelab.sh
# Select: Install Prerequisites → Configure Docker TLS

# 3. Deploy remote infrastructure
./scripts/ez-homelab.sh
# Select: Deploy Remote Infrastructure

# 4. Verify registration
# Check core Traefik logs for provider discovery
```

#### Step 4: Migrate Services
For each service currently using external YAML:

```bash
# 1. Add Traefik labels to docker-compose.yml on remote
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.service.rule=Host(`service.${DOMAIN}`)"
  # ... other labels

# 2. Redeploy service
docker compose up -d

# 3. Verify Traefik discovers service
# Check Traefik dashboard

# 4. Remove manual YAML file
rm /opt/stacks/core/traefik/dynamic/external-host-service.yml

# 5. Restart Traefik
docker compose -f /opt/stacks/core/docker-compose.yml restart traefik
```

#### Step 5: Cleanup and Verification
```bash
# Note: Old external-host-*.yml files are replaced during core deployment
# The deploy script should:
#   1. Backup existing /opt/stacks/core/traefik/dynamic/
#   2. Copy new config files from repo: docker-compose/core/traefik/dynamic/
#   3. Process variables in new configs

# Verify new config structure:
ls -la /opt/stacks/core/traefik/dynamic/
# Expected files:
#   - sablier.yml (updated with new middleware format)
#   - Any auto-generated provider configs

# Old backups available at:
# /opt/stacks/core/traefik.backup.TIMESTAMP/

# Restart Traefik to apply changes
docker compose -f /opt/stacks/core/docker-compose.yml restart traefik

# Verify Traefik discovers local services
docker logs traefik | grep -i "provider.docker"
```

---

## Documentation Updates

### Files to Update

1. **AGENT_INSTRUCTIONS.md**
   - Update "Service Creation with Traefik on a different server Template" section
   - Remove manual YAML instructions
   - Add "Multi-Server Label-Based Routing" section

2. **docs/getting-started.md**
   - Add "Multi-Server Setup" section
   - Document core vs remote server deployment

3. **docs/proxying-external-hosts.md**
   - Update title: "Multi-Server Docker Services"
   - Remove manual YAML method (legacy section)
   - Document label-based routing

4. **README.md**
   - Update architecture diagram
   - Add multi-server features to feature list

5. **New Documentation**
   - Create: `docs/multi-server-setup.md`
   - Create: `docs/troubleshooting-multi-server.md`

---

## Risk Assessment and Mitigation

### Risk 1: Breaking Existing Deployments
**Impact**: High  
**Probability**: Medium  
**Mitigation**:
- Maintain backward compatibility
- Keep manual YAML method functional
- Provide migration script with rollback
- Test on fresh VMs before release

### Risk 2: TLS Certificate Issues
**Impact**: High (Docker API inaccessible)  
**Probability**: Low (already tested)  
**Mitigation**:
- Shared CA already working
- Detailed error messages in scripts
- Fallback to local CA if core unavailable
- Documentation for manual cert generation

### Risk 3: Network Connectivity Issues
**Impact**: Medium  
**Probability**: Medium  
**Mitigation**:
- Test SSH connectivity before operations
- Provide manual registration steps
- Firewall configuration warnings
- Network troubleshooting guide

### Risk 4: Traefik Configuration Corruption
**Impact**: High (all routing broken)  
**Probability**: Low  
**Mitigation**:
- Backup traefik.yml before modifications
- Validate YAML syntax before applying
- Atomic file operations (write to .tmp, then mv)
- Automatic rollback on validation failure

### Risk 5: Sablier Cross-Server Confusion
**Impact**: Low (services don't wake up)  
**Probability**: Medium  
**Mitigation**:
- Clear naming: `sablier-${SERVER_HOSTNAME}-service`
- Separate middleware configs per server
- Documentation on group naming conventions
- Validation function to check Sablier reachability

---

## Success Criteria

### Phase 1: Core Functionality
- ✅ Core server deploys with local Traefik + Sablier
- ✅ Remote server deploys with Docker TLS + local Sablier
- ✅ Remote server auto-registers with core Traefik
- ✅ Service with Traefik labels on remote auto-routes
- ✅ Service with Sablier labels on remote lazy loads

### Phase 2: User Experience
- ✅ Zero manual YAML editing for standard services
- ✅ One-time registration per remote server
- ✅ Clear error messages and recovery steps
- ✅ Migration path for existing deployments

### Phase 3: Documentation
- ✅ Updated AGENT_INSTRUCTIONS.md
- ✅ Multi-server setup guide
- ✅ Troubleshooting documentation
- ✅ Example service configurations

### Phase 4: Testing
- ✅ Fresh deployment on 2-server lab passes all tests
- ✅ Migration from single-server passes all tests
- ✅ Rollback procedures validated
- ✅ No regression in existing functionality

---

## Implementation Timeline

### Week 1: Core Functions
- Day 1-2: Implement `common.sh` functions
- Day 3-4: Update `ez-homelab.sh` with role detection
- Day 5: Test core and remote deployments separately

### Week 2: Integration
- Day 1-2: Implement registration workflow
- Day 3: Update config templates
- Day 4-5: Integration testing (2-server setup)

### Week 3: Documentation and Polish
- Day 1-2: Update all documentation
- Day 3: Create migration guide
- Day 4: User acceptance testing
- Day 5: Bug fixes and refinement

### Week 4: Release
- Day 1-2: Final testing on fresh VMs
- Day 3: Create release notesfrom .env |
| `generate_traefik_provider_config()` | common.sh | Generate provider YAML |
| `generate_sablier_middleware_config()` | common.sh | Generate middleware YAML |
| `add_remote_server_to_traefik()` | common.sh | Register remote with core |
| `check_docker_installed()` | ez-homelab.sh | Check Docker (with timeout for Pi) |
| `validate_env_file()` | ez-homelab.sh | Validate .env for deployment type |
| `register_remote_server_with_core()` | ez-homelab.sh | SSH registration (uses .env vars) |
| `deploy_remote_server()` | ez-homelab.sh | Deploy remote server (TLS + Sablier)

### A. Function Reference

**New Functions**:

| Function | File | Purpose |
|----------|------|---------|
| `detect_server_role()` | common.sh | Determine core vs remote |
| `generate_traefik_provider_config()` | common.sh | Generate provider YAML |
| `generate_sablier_middleware_config()` | common.sh | Generate middleware YAML |
| `add_remote_server_to_traefik()` | common.sh | Register remote with core |
| `prompt_for_server_role()` | ez-homelab.sh | Interactive role selection |
| `register_remote_server_with_core()` | ez-homelab.sh | SSH registration workflow |
| `deploy_remote_infrastructure()` | ez-homelab.sh | Deploy remote stack |

### B. File Locations Reference

| File | Purpose | Server |
|------|---------|--------|
| `/opt/stacks/core/shared-ca/ca.pem` | Shared CA certificate | Core |
| `/opt/stacks/core/traefik/config/traefik.yml` | Traefik static config | Core |
| `/opt/stacks/core/traefik/dynamic/sablier-*.yml` | Sablier middlewares | Core |
| `/home/user/EZ-Homelab/docker-tls/` | TLS certs for Docker API | All |
| `/opt/stacks/sablier/` | Sablier stack | All servers |

### C. Port Reference

| Port | Service | Direction |
|------|---------|-----------|
| 80 | Traefik HTTP | Inbound (core) |
| 443 | Traefik HTTPS | Inbound (core) |
| 2376 | Docker API (TLS) | Core → Remote |
| 10000 | Sablier API | Traefik → Sablier |
| 9091 | Authelia | Internal (core) |

---

## Conclusion

This implementation plan provides a comprehensive roadmap for achieving label-based automatic routing and lazy loading across multiple servers. The approach maintains backward compatibility, leverages existing working infrastructure (TLS setup), and provides clear migration paths for existing deployments.

**Key Benefits**:
- ✅ Zero manual YAML editing for standard services
- ✅ Scalable to unlimited remote servers
- ✅ Decentralized Sablier (no single point of failure)
- ✅ Minimal core server changes (one-time per remote)
- ✅ Full label-driven automation
- ✅ Pi-friendly: Timeouts and lightweight checks prevent system hangs
- ✅ Reuses existing menu structure and prompting logic
- ✅ .env-driven: Minimal user interaction via smart defaults

**Next Steps**:
1. Review and approve this plan
2. Begin Phase 1 implementation (core functions)
3. Test on development VMs
4. Iterate based on testing results
5. Document and release
## Summary of Key Changes from Initial Plan

### Simplified Workflow
1. **Removed `prompt_for_server_role()`**: Uses existing menu options 2 & 3 instead
2. **Sablier Stack Separation**: Moved from core to dedicated stack for consistency
3. **Container Naming**: `sablier` (not `sablier-service`) across all deployments
4. **Compose Changes in Repo**: No script overrides, changes made to source files

### Enhanced User Experience
1. **Docker Pre-Check**: Silent check before menu display
2. **Smart Menu**: Limited menu if Docker missing, full menu if present
3. **.env Validation**: Check required variables before each deployment type
4. **Minimal Prompting**: Only ask for missing/invalid values
5. **Use .env Variables**: REMOTE_SERVER_IP, REMOTE_SERVER_HOSTNAME, etc.

### Pi 4 Optimizations
1. **Timeouts**: All network operations (SSH, Docker, SCP) have timeouts
2. **Lightweight Checks**: Avoid memory-heavy operations
3. **Efficient Validation**: Use grep instead of loading entire files
4. **Process Monitoring**: Prevent hanging processes on resource-constrained hardware

### Implementation Priority
1. ✅ Keep existing working code (prerequisites, core deployment)
2. ✅ Enhance with validation and smart checks
3. ✅ Add remote deployment as new option 3
4. ✅ Minimal changes to existing flows

---

*Plan Version: 2.0 (Revised)*  
*Date: February 4, 2026*  
*Updated: Based on user feedback and Pi 4 constraints

*Plan Version: 1.0*  
*Date: February 4, 2026*  
*Author: GitHub Copilot + User*
