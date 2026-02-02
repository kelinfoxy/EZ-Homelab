#!/bin/bash
# EZ-Homelab Unified Setup & Deployment Script

# Removed set -e to allow graceful error handling

# Debug logging configuration
DEBUG=${DEBUG:-false}
VERBOSE=${VERBOSE:-false}  # New verbosity toggle
DEBUG_LOG_FILE="/tmp/ez-homelab-debug.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Debug logging function
debug_log() {
    if [ "$DEBUG" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $1" >> "$DEBUG_LOG_FILE"
    fi
}

# Initialize debug log
if [ "$DEBUG" = true ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] ===== EZ-HOMELAB DEBUG LOG STARTED =====" > "$DEBUG_LOG_FILE"
    debug_log "Script started with DEBUG=true"
    debug_log "User: $USER, EUID: $EUID, PWD: $PWD"
fi

# Log functions
log_info() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
    debug_log "[INFO] $1"
}

log_success() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    fi
    debug_log "[SUCCESS] $1"
}

log_warning() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${YELLOW}[WARNING]${NC} $1"
    fi
    debug_log "[WARNING] $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    debug_log "[ERROR] $1"
}

# Safely load environment variables from .env file
load_env_file_safely() {
    local env_file="$1"
    debug_log "Loading env file safely: $env_file"

    if [ ! -f "$env_file" ]; then
        debug_log "Env file does not exist: $env_file"
        return 1
    fi

    # Read the .env file line by line and export variables safely
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ $line =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Parse KEY=VALUE, handling quoted values
        if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            # Strip inline comments
            value=${value%%#*}

            # Trim whitespace from key and value
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Strip carriage return if present (DOS line endings)
            value=${value%$'\r'}
            
            # Export the variable
            export "$key"="$value"
            
            debug_log "Exported $key=[HIDDEN]"  # Don't log actual values for security
        fi
    done < "$env_file"

    debug_log "Env file loaded successfully"
}
load_env_file() {
    load_env_file_safely "$REPO_DIR/.env"
}
localize_yml_file() {
    local file_path="$1"
    local fail_on_missing="${2:-false}"  # New parameter to control failure behavior
    local missing_vars=""
    local replaced_count=0

    debug_log "localize_yml_file called for file: $file_path, fail_on_missing: $fail_on_missing"

    if [ ! -f "$file_path" ]; then
        log_warning "File $file_path does not exist, skipping YAML localization"
        debug_log "File $file_path does not exist"
        return
    fi

    # Check if file is writable
    if [ ! -w "$file_path" ]; then
        log_error "File $file_path is not writable, cannot localize"
        debug_log "Permission denied for $file_path"
        if [ "$fail_on_missing" = true ]; then
            exit 1
        fi
        return
    fi

    # Backup only if target file already exists (not for repo sources)
    if [[ "$file_path" != "$REPO_DIR"* ]] && [ -f "$file_path" ]; then
        cp "$file_path" "$file_path.backup.$(date +%Y%m%d_%H%M%S)"
        debug_log "Backed up $file_path"
    fi

    # Use envsubst to replace all ${VAR} with environment values, handling nested variables
    if command -v envsubst >/dev/null 2>&1; then
        log_info "DEBUG: DEFAULT_EMAIL=$DEFAULT_EMAIL"
        temp_file="$file_path.tmp"
        cp "$file_path" "$temp_file"
        changed=true
        while [ "$changed" = true ]; do
            changed=false
            new_content=$(envsubst < "$temp_file")
            if [ "$new_content" != "$(cat "$temp_file")" ]; then
                changed=true
                echo "$new_content" > "$temp_file"
            fi
        done
        mv "$temp_file" "$file_path"
        debug_log "Replaced variables in $file_path using envsubst with nested expansion"
        replaced_count=$(grep -o '\${[^}]*}' "$file_path" | wc -l)
        replaced_count=$((replaced_count / 2))  # Approximate
    else
        log_warning "envsubst not available, cannot localize $file_path"
        if [ "$fail_on_missing" = true ]; then
            exit 1
        fi
        return
    fi

    # Post-replacement validation: check for remaining ${VAR} (except skipped)
    local remaining_vars=$(grep -v '^[ \t]*#' "$file_path" | grep -o '\${[^}]*}' | sed 's/\${//' | sed 's/}//' | sort | uniq)
    local invalid_remaining=""
    for rvar in $remaining_vars; do
        rvar=$(echo "$rvar" | xargs)
        case "$rvar" in
            "ACME_EMAIL"|"AUTHELIA_ADMIN_EMAIL"|"SMTP_USERNAME"|"SMTP_PASSWORD")
                continue
                ;;
            *)
                invalid_remaining="$invalid_remaining $rvar"
                ;;
        esac
    done
    if [ -n "$invalid_remaining" ]; then
        log_error "Failed to replace variables in $file_path: $invalid_remaining"
        debug_log "Unreplaced variables: $invalid_remaining"
        if [ "$fail_on_missing" = true ]; then
            exit 1
        fi
    fi

    # Handle missing variables
    if [ -n "$missing_vars" ]; then
        GLOBAL_MISSING_VARS="${GLOBAL_MISSING_VARS}${missing_vars}"
        if [ "$fail_on_missing" = true ]; then
            log_error "Critical environment variables missing: $missing_vars"
            debug_log "Failing deployment due to missing critical variables: $missing_vars"
            exit 1
        fi
    fi
}

# Enhanced placeholder replacement for all configuration files
localize_deployment() {
    log_info "Starting deployment localization..."

    local processed_files=0
    GLOBAL_MISSING_VARS=""

    # Process docker-compose files
    if [ -d "$REPO_DIR/docker-compose" ]; then
        while IFS= read -r -d '' file_path; do
            if [ -f "$file_path" ]; then
                debug_log "Processing docker-compose file: $file_path"
                localize_yml_file "$file_path" false
                processed_files=$((processed_files + 1))
            fi
        done < <(find "$REPO_DIR/docker-compose" -name "*.yml" -o -name "*.yaml" -print0 2>/dev/null)
    fi

    # Process config-templates files
    if [ -d "$REPO_DIR/config-templates" ]; then
        while IFS= read -r -d '' file_path; do
            if [ -f "$file_path" ]; then
                debug_log "Processing config template file: $file_path"
                localize_yml_file "$file_path" false
                processed_files=$((processed_files + 1))
            fi
        done < <(find "$REPO_DIR/config-templates" -name "*.yml" -o -name "*.yaml" -print0 2>/dev/null)
    fi

    log_success "Deployment localization completed - processed $processed_files files"
    debug_log "Localization completed for $processed_files files"

    # Report aggregated missing variables
    if [ -n "$GLOBAL_MISSING_VARS" ]; then
        log_warning "Aggregated missing environment variables across all files: $GLOBAL_MISSING_VARS"
        debug_log "Global missing vars: $GLOBAL_MISSING_VARS"
    fi
}

# Function to generate shared CA for multi-server TLS
generate_shared_ca() {
    local ca_dir="/opt/stacks/core/shared-ca"
    mkdir -p "$ca_dir"
    openssl genrsa -out "$ca_dir/ca-key.pem" 4096
    openssl req -new -x509 -days 365 -key "$ca_dir/ca-key.pem" -sha256 -out "$ca_dir/ca.pem" -subj "/C=US/ST=State/L=City/O=Homelab/CN=Homelab-CA"
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ca_dir"
    log_success "Shared CA generated"
}

# Function to setup multi-server TLS for remote servers
setup_multi_server_tls() {
    local ca_dir="/opt/stacks/core/shared-ca"
    sudo mkdir -p "$ca_dir"
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" "$ca_dir"

    if [ -n "$CORE_SERVER_IP" ]; then
        log_info "Setting up multi-server TLS using shared CA from core server $CORE_SERVER_IP..."
    else
        # Prompt for core server IP if not set
        read -p "Enter the IP address of your core server: " CORE_SERVER_IP
        while [ -z "$CORE_SERVER_IP" ]; do
            log_warning "Core server IP is required for shared TLS"
            read -p "Enter the IP address of your core server: " CORE_SERVER_IP
        done
        log_info "Setting up multi-server TLS using shared CA from core server $CORE_SERVER_IP..."
    fi

    # Prompt for SSH username if not set
    if [ -z "$SSH_USER" ]; then
        DEFAULT_SSH_USER="${DEFAULT_USER:-$USER}"
        read -p "SSH username for core server [$DEFAULT_SSH_USER]: " SSH_USER
        SSH_USER="${SSH_USER:-$DEFAULT_SSH_USER}"
    fi

    # Test SSH connection - try key authentication first
    log_info "Testing SSH connection to core server ($SSH_USER@$CORE_SERVER_IP)..."
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes "$SSH_USER@$CORE_SERVER_IP" "echo 'SSH connection successful'" 2>/dev/null; then
        log_success "SSH connection established using key authentication"
        USE_SSHPASS=false
    else
        # Key authentication failed, try password authentication
        log_info "Key authentication failed, trying password authentication..."
        read -s -p "Enter SSH password for $SSH_USER@$CORE_SERVER_IP: " SSH_PASSWORD
        echo ""

        if sshpass -p "$SSH_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "echo 'SSH connection successful'" 2>/dev/null; then
            log_success "SSH connection established using password authentication"
            USE_SSHPASS=true
        else
            log_error "Cannot connect to core server via SSH. Please check:"
            echo "  1. SSH is running on the core server"
            echo "  2. SSH keys are properly configured, or username/password are correct"
            echo "  3. The core server IP is correct"
            echo ""
            TLS_ISSUES_SUMMARY="⚠️  TLS Configuration Issue: Cannot connect to core server $CORE_SERVER_IP via SSH
   This will prevent Sablier from connecting to remote Docker daemons.
   
   To fix this:
   1. Ensure SSH is running on the core server
   2. Configure SSH keys or provide correct password
   3. Verify the core server IP is correct
   4. Test SSH connection: ssh $SSH_USER@$CORE_SERVER_IP
   
   Without SSH access, shared CA cannot be fetched for secure multi-server TLS."
            return
        fi
    fi

    # Fetch shared CA certificates from core server
    log_info "Fetching shared CA certificates from core server..."
    SHARED_CA_EXISTS=false

    # Check if shared CA exists on core server (check both old and new locations)
    if [ "$USE_SSHPASS" = true ] && [ -n "$SSH_PASSWORD" ]; then
        if sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "[ -f /opt/stacks/core/shared-ca/ca.pem ] && [ -f /opt/stacks/core/shared-ca/ca-key.pem ] && [ -r /opt/stacks/core/shared-ca/ca.pem ] && [ -r /opt/stacks/core/shared-ca/ca-key.pem ]" 2>/dev/null; then
            SHARED_CA_EXISTS=true
            SHARED_CA_PATH="/opt/stacks/core/shared-ca"
            log_info "Detected CA certificate and key in shared-ca location"
        elif sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "[ -f /opt/stacks/core/docker-tls/ca.pem ] && [ -f /opt/stacks/core/docker-tls/ca-key.pem ] && [ -r /opt/stacks/core/docker-tls/ca.pem ] && [ -r /opt/stacks/core/docker-tls/ca-key.pem ]" 2>/dev/null; then
            SHARED_CA_EXISTS=true
            SHARED_CA_PATH="/opt/stacks/core/docker-tls"
            log_info "Detected CA certificate and key in docker-tls location"
        fi
    else
        if ssh -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "[ -f /opt/stacks/core/shared-ca/ca.pem ] && [ -f /opt/stacks/core/shared-ca/ca-key.pem ] && [ -r /opt/stacks/core/shared-ca/ca.pem ] && [ -r /opt/stacks/core/shared-ca/ca-key.pem ]" 2>/dev/null; then
            SHARED_CA_EXISTS=true
            SHARED_CA_PATH="/opt/stacks/core/shared-ca"
            log_info "Detected CA certificate and key in shared-ca location"
        elif ssh -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP" "[ -f /opt/stacks/core/docker-tls/ca.pem ] && [ -f /opt/stacks/core/docker-tls/ca-key.pem ] && [ -r /opt/stacks/core/docker-tls/ca.pem ] && [ -r /opt/stacks/core/docker-tls/ca-key.pem ]" 2>/dev/null; then
            SHARED_CA_EXISTS=true
            SHARED_CA_PATH="/opt/stacks/core/docker-tls"
            log_info "Detected CA certificate and key in docker-tls location"
        fi
    fi

    if [ "$SHARED_CA_EXISTS" = true ]; then
        # Copy existing shared CA from core server
        set +e
        scp_output=$(scp -o StrictHostKeyChecking=no "$SSH_USER@$CORE_SERVER_IP:$SHARED_CA_PATH/ca.pem" "$SSH_USER@$CORE_SERVER_IP:$SHARED_CA_PATH/ca-key.pem" "$ca_dir/" 2>&1)
        scp_exit_code=$?
        set -e
        if [ $scp_exit_code -eq 0 ]; then
            log_success "Shared CA certificate and key fetched from core server"
            setup_docker_tls
        else
            log_error "Failed to fetch shared CA certificate and key from core server"
            TLS_ISSUES_SUMMARY="⚠️  TLS Configuration Issue: Could not copy shared CA from core server $CORE_SERVER_IP
   SCP Error: $scp_output
   
   To fix this:
   1. Ensure SSH key authentication works: ssh $ACTUAL_USER@$CORE_SERVER_IP
   2. Verify core server has: $SHARED_CA_PATH/ca.pem and ca-key.pem
   3. Check file permissions on core server: ls -la $SHARED_CA_PATH/
   4. Manually copy CA: scp $ACTUAL_USER@$CORE_SERVER_IP:$SHARED_CA_PATH/ca.pem $ca_dir/
      scp $ACTUAL_USER@$CORE_SERVER_IP:$SHARED_CA_PATH/ca-key.pem $ca_dir/
   5. Regenerate server certificates: run setup_docker_tls after copying
   6. Restart Docker: sudo systemctl restart docker
   
   Then restart Sablier on the core server to reconnect."
            return
        fi
    else
        log_warning "Shared CA certificates not found on core server."
        log_info "Please ensure the core server has been set up first and has generated the shared CA certificates."
        TLS_ISSUES_SUMMARY="⚠️  TLS Configuration Issue: Shared CA certificates not found on core server $CORE_SERVER_IP
   This will prevent Sablier from connecting to remote Docker daemons.
   
   To fix this:
   1. Ensure the core server is set up and has generated shared CA certificates
   2. Verify SSH access: ssh $ACTUAL_USER@$CORE_SERVER_IP
   3. Check core server locations: /opt/stacks/core/shared-ca/ or /opt/stacks/core/docker-tls/
   4. Manually copy CA certificates if needed
   5. Re-run the infrastructure deployment
   
   Without shared CA, remote Docker access will not work securely."
        return
    fi
}

# Get script directory and repo directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Get actual user
if [ "$EUID" -eq 0 ]; then
    ACTUAL_USER=${SUDO_USER:-$USER}
else
    ACTUAL_USER=$USER
fi

# Default values
DOMAIN=""
SERVER_IP=""
CORE_SERVER_IP=""
ADMIN_USER=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
DEPLOY_CORE=false
DEPLOY_INFRASTRUCTURE=false
DEPLOY_DASHBOARDS=false
SETUP_STACKS=false
TLS_ISSUES_SUMMARY=""

# Required variables for configuration
REQUIRED_VARS=("SERVER_IP" "SERVER_HOSTNAME" "DUCKDNS_SUBDOMAINS" "DUCKDNS_TOKEN" "DOMAIN" "DEFAULT_USER" "DEFAULT_PASSWORD" "DEFAULT_EMAIL")

# Load existing .env file if it exists
load_env_file() {
    if [ -f "$REPO_DIR/.env" ]; then
        log_info "Found existing .env file, loading current configuration..."
        load_env_file_safely "$REPO_DIR/.env"
        return 0
    else
        log_info "No existing .env file found. We'll create one during setup."
        return 1
    fi
}

# Validate variable values
validate_variable() {
    local var_name="$1"
    local var_value="$2"
    
    case "$var_name" in
        "SERVER_IP")
            # Basic IP validation
            if [[ $var_value =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "DOMAIN")
            # Basic domain validation
            if [[ $var_value =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "DUCKDNS_SUBDOMAINS")
            # DuckDNS subdomain should be non-empty and contain only valid characters
            local trimmed_value=$(echo "$var_value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$trimmed_value" ] && [[ $trimmed_value =~ ^[a-zA-Z0-9.-]+$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "DEFAULT_PASSWORD")
            # Password should be at least 8 characters
            if [ ${#var_value} -ge 8 ]; then
                return 0
            else
                return 1
            fi
            ;;
        "DEFAULT_EMAIL")
            # Basic email validation
            if [[ $var_value =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            # For other variables, trim whitespace and check they're not empty
            local trimmed_value=$(echo "$var_value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$trimmed_value" ]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# Prompt for a single variable
prompt_for_variable() {
    local var="$1"
    local user_input=""
    local current_value="${!var:-}"
    local prompt_text=""
    
    while true; do
        # Build prompt text with current value if it exists
        if [ -n "$current_value" ]; then
            if [ "$var" = "DEFAULT_PASSWORD" ]; then
                prompt_text="🔒 ${var} ([HIDDEN]): "
            else
                prompt_text="${var} (${current_value}): "
            fi
        else
            prompt_text="${var}: "
        fi
        
        # Add icon prefix
        case "$var" in
            "SERVER_IP")
                prompt_text="🌐 ${prompt_text}"
                ;;
            "DOMAIN")
                prompt_text="🌍 ${prompt_text}"
                ;;
            "DUCKDNS_SUBDOMAINS")
                prompt_text="🦆 ${prompt_text}"
                ;;
            "DUCKDNS_TOKEN")
                prompt_text="🔑 ${prompt_text}"
                ;;
            "DEFAULT_USER")
                prompt_text="👤 ${prompt_text}"
                ;;
            "DEFAULT_PASSWORD")
                # Lock icon already added above for passwords
                ;;
            "DEFAULT_EMAIL")
                prompt_text="📧 ${prompt_text}"
                ;;
            "SERVER_HOSTNAME")
                prompt_text="🏠 ${prompt_text}"
                ;;
        esac
        
        # Get user input
        if [ "$var" = "DEFAULT_PASSWORD" ]; then
            read -s -p "$prompt_text" user_input
            echo ""
        else
            read -p "$prompt_text" user_input
        fi
        
        # Check for quit command
        if [ "$user_input" = "q" ] || [ "$user_input" = "Q" ]; then
            log_info "Setup cancelled by user"
            exit 0
        fi
        
        if [ -z "$user_input" ]; then
            if [ -n "$current_value" ]; then
                # Use existing value - overwrite prompt with status
                if [ "$var" != "DEFAULT_PASSWORD" ]; then
                    echo -e "\033[1A\033[K✅ ${var}: ${current_value}"
                fi
                return 0
            else
                log_warning "${var} cannot be empty. Please provide a value."
                continue
            fi
        fi
        
        if validate_variable "$var" "$user_input"; then
            eval "$var=\"$user_input\""
            # Overwrite prompt with status
            if [ "$var" != "DEFAULT_PASSWORD" ]; then
                echo -e "\033[1A\033[K✅ ${var}: ${user_input}"
            else
                echo -e "\033[1A\033[K✅ ${var}: [HIDDEN]"
            fi
            return 0
        else
            log_warning "Invalid value for ${var}. Please try again."
            continue
        fi
    done
}

# Validate and prompt for required variables with loop
validate_and_prompt_variables() {
    local all_valid=false
    local user_wants_to_review=false
    local first_display=true
    
    while true; do
        user_wants_to_review=false
        
        all_valid=true
        
        # Check validity without showing initial summary
        for var in "${REQUIRED_VARS[@]}"; do
            local display_value=$(echo "${!var:-}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -z "$display_value" ] || ! validate_variable "$var" "${!var}"; then
                all_valid=false
            fi
        done
        
        if [ "$all_valid" = true ]; then
            if [ "$first_display" = true ]; then
                echo "Current configuration:"
                for var in "${REQUIRED_VARS[@]}"; do
                    local display_value=$(echo "${!var:-}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    if [ "$var" = "DEFAULT_PASSWORD" ]; then
                        echo "  ✅ ${var}: [HIDDEN]"
                    else
                        echo "  ✅ ${var}: ${display_value}"
                    fi
                done
                echo ""
                first_display=false
            fi
            echo ""
            echo "Choose an option:"
            echo "  1) ✅ Deploy now"
            echo "  2) 🔄 Make Changes"
            echo "  q) ❌ Quit setup"
            echo ""
            read -p "Enter your choice (1, 2, or q): " user_choice
            
            case "$user_choice" in
                1|"p"|"proceed")
                    log_info "Proceeding with current configuration..."
                    return 0
                    ;;
                2|"r"|"review"|"change")
                    user_wants_to_review=true
                    echo ""
                    echo "Reviewing all variables - press Enter to keep current value or enter new value:"
                    echo ""
                    ;;
                [Qq]|[Qq]uit)
                    log_info "Setup cancelled by user"
                    exit 0
                    ;;
                *)
                    log_warning "Invalid choice. Please enter 1, 2, or q."
                    echo ""
                    continue
                    ;;
            esac
        else
            echo ""
            echo "Missing variables: ${missing_vars[*]}"
            echo "Some variables need configuration. Press Enter to continue or 'q' to quit."
            read -p "Press Enter to configure missing variables, or 'q' to quit: " user_choice
            
            case "$user_choice" in
                [Qq]|[Qq]uit)
                    log_info "Setup cancelled by user"
                    exit 0
                    ;;
                ""|"c"|"continue")
                    # Continue with prompting
                    ;;
                *)
                    log_warning "Invalid choice. Press Enter to continue or 'q' to quit."
                    continue
                    ;;
            esac
        fi
        
        # Prompt for variables (either missing ones or all if reviewing)
        if [ "$user_wants_to_review" = true ]; then
            # Review all variables one by one
            for var in "${REQUIRED_VARS[@]}"; do
                prompt_for_variable "$var"
            done
            # After review, continue the loop to show menu again
            continue
        else
            # Only prompt for missing/invalid variables
            for var in "${REQUIRED_VARS[@]}"; do
                if [ -z "${!var:-}" ] || ! validate_variable "$var" "${!var}"; then
                    prompt_for_variable "$var"
                fi
            done
        fi
    done
}

# Save configuration to .env file
save_env_file() {
    debug_log "save_env_file() called, DEPLOY_CORE=$DEPLOY_CORE"
    log_info "Saving configuration to .env file..."

    # Create .env file if it doesn't exist
    if [ ! -f "$REPO_DIR/.env" ]; then
        sudo -u "$ACTUAL_USER" cp "$REPO_DIR/.env.example" "$REPO_DIR/.env"
    fi

    # Update only the required variables
    for var in "${REQUIRED_VARS[@]}"; do
        if [ -n "${!var:-}" ]; then
            sudo -u "$ACTUAL_USER" sed -i "s|^${var}=.*|${var}=${!var}|" "$REPO_DIR/.env"
        fi
    done

    # Update HOMEPAGE_ALLOWED_HOSTS dynamically
    if [ -n "${DOMAIN:-}" ] && [ -n "${SERVER_IP:-}" ]; then
        # Extract Homepage port from compose file
        HOMEPAGE_PORT=$(grep -A1 'ports:' "$REPO_DIR/docker-compose/dashboards/docker-compose.yml" | grep -o '"[0-9]*:3000"' | cut -d'"' -f2 | cut -d: -f1)
        if [ -z "$HOMEPAGE_PORT" ]; then
            HOMEPAGE_PORT=3003  # Fallback
        fi
        HOMEPAGE_ALLOWED_HOSTS="homepage.${DOMAIN},${SERVER_IP}:${HOMEPAGE_PORT}"
        sudo -u "$ACTUAL_USER" sed -i "s|HOMEPAGE_ALLOWED_HOSTS=.*|HOMEPAGE_ALLOWED_HOSTS=$HOMEPAGE_ALLOWED_HOSTS|" "$REPO_DIR/.env"
    fi

    # Authelia settings (only generate secrets if deploying core)
    if [ "$DEPLOY_CORE" = true ]; then
        # Ensure we have admin credentials
        if [ -z "$ADMIN_USER" ]; then
            ADMIN_USER="${DEFAULT_USER:-admin}"
        fi
        if [ -z "$ADMIN_EMAIL" ]; then
            ADMIN_EMAIL="${DEFAULT_EMAIL:-${ADMIN_USER}@${DOMAIN}}"
        fi
        if [ -z "$ADMIN_PASSWORD" ]; then
            ADMIN_PASSWORD="${DEFAULT_PASSWORD:-changeme123}"
            if [ "$ADMIN_PASSWORD" = "changeme123" ]; then
                log_info "Using default admin password (changeme123) - please change this after setup!"
            fi
        fi

        if [ -z "$AUTHELIA_JWT_SECRET" ]; then
            AUTHELIA_JWT_SECRET=$(openssl rand -hex 64)
        fi
        if [ -z "$AUTHELIA_SESSION_SECRET" ]; then
            AUTHELIA_SESSION_SECRET=$(openssl rand -hex 64)
        fi
        if [ -z "$AUTHELIA_STORAGE_ENCRYPTION_KEY" ]; then
            AUTHELIA_STORAGE_ENCRYPTION_KEY=$(openssl rand -hex 64)
        fi

        # Save Authelia settings to .env
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_JWT_SECRET=.*%AUTHELIA_JWT_SECRET=$AUTHELIA_JWT_SECRET%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_SESSION_SECRET=.*%AUTHELIA_SESSION_SECRET=$AUTHELIA_SESSION_SECRET%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_STORAGE_ENCRYPTION_KEY=.*%AUTHELIA_STORAGE_ENCRYPTION_KEY=$AUTHELIA_STORAGE_ENCRYPTION_KEY%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%# AUTHELIA_ADMIN_USER=.*%AUTHELIA_ADMIN_USER=$ADMIN_USER%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_ADMIN_USER=.*%AUTHELIA_ADMIN_USER=$ADMIN_USER%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%# AUTHELIA_ADMIN_EMAIL=.*%AUTHELIA_ADMIN_EMAIL=$ADMIN_EMAIL%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_ADMIN_EMAIL=.*%AUTHELIA_ADMIN_EMAIL=$ADMIN_EMAIL%" "$REPO_DIR/.env"

        # Generate password hash if needed
        if [ -z "$AUTHELIA_ADMIN_PASSWORD_HASH" ]; then
            log_info "Generating Authelia password hash..."
            # Pull Authelia image if needed
            if ! docker images | grep -q authelia/authelia; then
                docker pull authelia/authelia:latest > /dev/null 2>&1
            fi
            AUTHELIA_ADMIN_PASSWORD_HASH=$(docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password "$ADMIN_PASSWORD" 2>&1 | grep -o '\$argon2id.*')
            if [ -z "$AUTHELIA_ADMIN_PASSWORD_HASH" ]; then
                log_error "Failed to generate Authelia password hash. Please check that ADMIN_PASSWORD is set."
                exit 1
            fi
        fi

        # Save password hash
        sudo -u "$ACTUAL_USER" sed -i "s%# AUTHELIA_ADMIN_PASSWORD_HASH=.*%AUTHELIA_ADMIN_PASSWORD_HASH=\"$AUTHELIA_ADMIN_PASSWORD_HASH\"%" "$REPO_DIR/.env"
        sudo -u "$ACTUAL_USER" sed -i "s%AUTHELIA_ADMIN_PASSWORD_HASH=.*%AUTHELIA_ADMIN_PASSWORD_HASH=\"$AUTHELIA_ADMIN_PASSWORD_HASH\"%" "$REPO_DIR/.env"
    fi

    debug_log "Configuration saved to .env file"
    log_success "Configuration saved to .env file"
}

# Validate that required secrets are present for core deployment
validate_secrets() {
    debug_log "validate_secrets called, DEPLOY_CORE=$DEPLOY_CORE"

    if [ "$DEPLOY_CORE" = false ]; then
        debug_log "Core not being deployed, skipping secret validation"
        return 0
    fi

    log_info "Validating required secrets for core deployment..."
    debug_log "Checking Authelia secrets..."

    local missing_secrets=""

    # Check required Authelia secrets
    if [ -z "${AUTHELIA_JWT_SECRET:-}" ]; then
        missing_secrets="$missing_secrets AUTHELIA_JWT_SECRET"
        debug_log "AUTHELIA_JWT_SECRET is missing"
    fi

    if [ -z "${AUTHELIA_SESSION_SECRET:-}" ]; then
        missing_secrets="$missing_secrets AUTHELIA_SESSION_SECRET"
        debug_log "AUTHELIA_SESSION_SECRET is missing"
    fi

    if [ -z "${AUTHELIA_STORAGE_ENCRYPTION_KEY:-}" ]; then
        missing_secrets="$missing_secrets AUTHELIA_STORAGE_ENCRYPTION_KEY"
        debug_log "AUTHELIA_STORAGE_ENCRYPTION_KEY is missing"
    fi

    if [ -z "${AUTHELIA_ADMIN_PASSWORD_HASH:-}" ]; then
        missing_secrets="$missing_secrets AUTHELIA_ADMIN_PASSWORD_HASH"
        debug_log "AUTHELIA_ADMIN_PASSWORD_HASH is missing"
    fi

    # Check other required variables
    if [ -z "${DOMAIN:-}" ]; then
        missing_secrets="$missing_secrets DOMAIN"
        debug_log "DOMAIN is missing"
    fi

    if [ -z "${SERVER_IP:-}" ]; then
        missing_secrets="$missing_secrets SERVER_IP"
        debug_log "SERVER_IP is missing"
    fi

    if [ -n "$missing_secrets" ]; then
        log_error "Critical configuration missing: $missing_secrets"
        log_error "This will prevent Authelia and other services from starting correctly."
        debug_log "Failing deployment due to missing secrets: $missing_secrets"
        exit 1
    fi

    log_success "All required secrets validated"
    debug_log "Secret validation passed"
}

# Install NVIDIA drivers function
install_nvidia() {
    log_info "Installing NVIDIA drivers and Docker support..."

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_warning "NVIDIA installation requires root privileges. Running with sudo..."
        exec sudo "$0" "$@"
    fi

    # Check for NVIDIA GPU
    if ! lspci | grep -i nvidia > /dev/null; then
        log_warning "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
        return
    fi

    # Add NVIDIA repository
    log_info "Adding NVIDIA repository..."
    apt-get update
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:graphics-drivers/ppa
    apt-get update

    # Install NVIDIA drivers (latest)
    log_info "Installing NVIDIA drivers..."
    apt-get install -y nvidia-driver-470  # Adjust version as needed

    # Install NVIDIA Docker support
    log_info "Installing NVIDIA Docker support..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
    apt-get update && apt-get install -y nvidia-docker2
    systemctl restart docker

    log_success "NVIDIA drivers and Docker support installed. A reboot may be required."
}

# Deploy Dockge function
deploy_dockge() {
    log_info "Deploying Dockge stack manager..."
    log_info "  - Dockge (Docker Compose Manager)"
    echo ""

    # Copy Dockge stack files
    sudo cp "$REPO_DIR/docker-compose/dockge/docker-compose.yml" /opt/dockge/docker-compose.yml
    sudo cp "$REPO_DIR/.env" /opt/dockge/.env
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/dockge/docker-compose.yml
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/dockge/.env

    # Remove sensitive variables from dockge .env (Dockge doesn't need them)
    sed -i '/^AUTHELIA_ADMIN_PASSWORD_HASH=/d' /opt/dockge/.env
    sed -i '/^AUTHELIA_JWT_SECRET=/d' /opt/dockge/.env
    sed -i '/^AUTHELIA_SESSION_SECRET=/d' /opt/dockge/.env
    sed -i '/^AUTHELIA_STORAGE_ENCRYPTION_KEY=/d' /opt/dockge/.env

    # Replace placeholders in Dockge compose file
    localize_yml_file "/opt/dockge/docker-compose.yml"

    # Deploy Dockge stack
    cd /opt/dockge
    run_cmd docker compose up -d || true
    log_success "Dockge deployed"
    echo ""
}

# Deploy core stack function
deploy_core() {
    debug_log "deploy_core called"
    log_info "Deploying core stack..."
    log_info "  - DuckDNS (Dynamic DNS)"
    log_info "  - Traefik (Reverse Proxy with SSL)"
    log_info "  - Authelia (Single Sign-On)"
    echo ""

    # Copy core stack files
    debug_log "Copying core stack files"
    sudo cp "$REPO_DIR/docker-compose/core/docker-compose.yml" /opt/stacks/core/docker-compose.yml
    sudo cp "$REPO_DIR/.env" /opt/stacks/core/.env
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/core/docker-compose.yml
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/core/.env

    # Remove variables that core stack doesn't need
    sed -i '/^QBITTORRENT_/d' /opt/stacks/core/.env
    sed -i '/^GRAFANA_/d' /opt/stacks/core/.env
    sed -i '/^CODE_SERVER_/d' /opt/stacks/core/.env
    sed -i '/^JUPYTER_/d' /opt/stacks/core/.env
    sed -i '/^POSTGRES_/d' /opt/stacks/core/.env
    sed -i '/^NEXTCLOUD_/d' /opt/stacks/core/.env
    sed -i '/^GITEA_/d' /opt/stacks/core/.env
    sed -i '/^WORDPRESS_/d' /opt/stacks/core/.env
    sed -i '/^BOOKSTACK_/d' /opt/stacks/core/.env
    sed -i '/^MEDIAWIKI_/d' /opt/stacks/core/.env
    sed -i '/^BITWARDEN_/d' /opt/stacks/core/.env
    sed -i '/^FORMIO_/d' /opt/stacks/core/.env
    sed -i '/^HOMEPAGE_VAR_/d' /opt/stacks/core/.env

    # Replace placeholders in core compose file (fail on missing critical vars)
    localize_yml_file "/opt/stacks/core/docker-compose.yml" true

    # Copy and configure Traefik config
    debug_log "Setting up Traefik configuration"
    if [ -d "/opt/stacks/core/traefik" ]; then
        mv /opt/stacks/core/traefik /opt/stacks/core/traefik.backup.$(date +%Y%m%d_%H%M%S)
    fi
    cp -r "$REPO_DIR/config-templates/traefik" /opt/stacks/core/
    sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/core/traefik

    # Move Traefik config file to the correct location for Docker mount
    debug_log "Moving Traefik config file to config directory"
    mkdir -p /opt/stacks/core/traefik/config
    mv /opt/stacks/core/traefik/traefik.yml /opt/stacks/core/traefik/config/

    # Only copy external host files on core server (where Traefik runs)
    if [ "$DEPLOY_CORE" = true ]; then
        log_info "Core server detected - copying external host routing files"
        # Remove local-host-production.yml if no remote server hostname is set (single-server setup)
        if [ -z "${REMOTE_SERVER_HOSTNAME:-}" ]; then
            rm -f /opt/stacks/core/traefik/dynamic/local-host-production.yml
            # Remove remote server sections from sablier.yml for single-server setup
            sed -i '335,$d' /opt/stacks/core/traefik/dynamic/sablier.yml
            log_info "Single-server setup - removed remote server sections from sablier.yml"
        fi
    else
        log_info "Remote server detected - removing external host routing files"
        rm -f /opt/stacks/core/traefik/dynamic/external-host-*.yml
    fi

    # Replace all placeholders in Traefik config files
    debug_log "Replacing placeholders in Traefik config files"
    for config_file in $(find /opt/stacks/core/traefik -name "*.yml" -type f); do
        # Don't fail on missing variables for external host files (they're optional)
        if [[ "$config_file" == *external-host* ]]; then
            localize_yml_file "$config_file" false
        else
            localize_yml_file "$config_file" true
        fi
    done

    # Rename external-host-production.yml to use remote server hostname (only for multi-server setups)
    if [ -n "${REMOTE_SERVER_HOSTNAME:-}" ] && [ -f "/opt/stacks/core/traefik/dynamic/external-host-production.yml" ]; then
        mv "/opt/stacks/core/traefik/dynamic/external-host-production.yml" "/opt/stacks/core/traefik/dynamic/external-host-${REMOTE_SERVER_HOSTNAME}.yml"
        log_info "Renamed external-host-production.yml to external-host-${REMOTE_SERVER_HOSTNAME}.yml"
    fi

    # Copy and configure Authelia config
    debug_log "Setting up Authelia configuration"
    if [ -d "/opt/stacks/core/authelia" ]; then
        mv /opt/stacks/core/authelia /opt/stacks/core/authelia.backup.$(date +%Y%m%d_%H%M%S)
    fi
    cp -r "$REPO_DIR/config-templates/authelia" /opt/stacks/core/
    sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/core/authelia

    # Replace all placeholders in Authelia config files
    debug_log "Replacing placeholders in Authelia config files"
    for config_file in $(find /opt/stacks/core/authelia -name "*.yml" -type f); do
        localize_yml_file "$config_file" true
    done

    # Remove invalid session.cookies section from Authelia config (not supported in v4.37.5)
    debug_log "Removing invalid session.cookies section from Authelia config"
    sed -i '/^  cookies:/,/^$/d' /opt/stacks/core/authelia/configuration.yml

    # Move config files to the correct location for Docker mount
    debug_log "Moving Authelia config files to config directory"
    mkdir -p /opt/stacks/core/authelia/config
    mv /opt/stacks/core/authelia/configuration.yml /opt/stacks/core/authelia/config/
    mv /opt/stacks/core/authelia/users_database.yml /opt/stacks/core/authelia/config/
    sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/core/authelia

    # Generate shared CA for multi-server TLS
    debug_log "Generating shared CA"
    log_info "Generating shared CA certificate for multi-server TLS..."
    generate_shared_ca

    # Deploy core stack
    debug_log "Deploying core stack with docker compose"
    cd /opt/stacks/core
    run_cmd docker compose up -d || true
    log_success "Core infrastructure deployed"
    echo ""
}

# Deploy infrastructure stack function
deploy_infrastructure() {
    log_info "Deploying infrastructure stack..."
    log_info "  - Pi-hole (DNS Ad Blocker)"
    log_info "  - Watchtower (Container Updates)"
    log_info "  - Dozzle (Log Viewer)"
    log_info "  - Glances (System Monitor)"
    log_info "  - Docker Proxy (Security)"
    echo ""

    # Copy infrastructure stack
    cp "$REPO_DIR/docker-compose/infrastructure/docker-compose.yml" /opt/stacks/infrastructure/docker-compose.yml
    cp "$REPO_DIR/.env" /opt/stacks/infrastructure/.env
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/infrastructure/docker-compose.yml
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/infrastructure/.env

    # Remove variables that infrastructure stack doesn't need
    sed -i '/^AUTHELIA_/d' /opt/stacks/infrastructure/.env
    sed -i '/^QBITTORRENT_/d' /opt/stacks/infrastructure/.env
    sed -i '/^GRAFANA_/d' /opt/stacks/infrastructure/.env
    sed -i '/^CODE_SERVER_/d' /opt/stacks/infrastructure/.env
    sed -i '/^JUPYTER_/d' /opt/stacks/infrastructure/.env
    sed -i '/^POSTGRES_/d' /opt/stacks/infrastructure/.env
    sed -i '/^NEXTCLOUD_/d' /opt/stacks/infrastructure/.env
    sed -i '/^GITEA_/d' /opt/stacks/infrastructure/.env
    sed -i '/^WORDPRESS_/d' /opt/stacks/infrastructure/.env
    sed -i '/^BOOKSTACK_/d' /opt/stacks/infrastructure/.env
    sed -i '/^MEDIAWIKI_/d' /opt/stacks/infrastructure/.env
    sed -i '/^BITWARDEN_/d' /opt/stacks/infrastructure/.env
    sed -i '/^FORMIO_/d' /opt/stacks/infrastructure/.env
    sed -i '/^HOMEPAGE_VAR_/d' /opt/stacks/infrastructure/.env

    # Replace placeholders in infrastructure compose file
    localize_yml_file "/opt/stacks/infrastructure/docker-compose.yml"

    # Copy any additional config directories
    for config_dir in "$REPO_DIR/docker-compose/infrastructure"/*/; do
        if [ -d "$config_dir" ] && [ "$(basename "$config_dir")" != "." ]; then
            cp -r "$config_dir" /opt/stacks/infrastructure/
        fi
    done

    # If core is not deployed, remove Authelia middleware references
    if [ "$DEPLOY_CORE" = false ]; then
        log_info "Core infrastructure not deployed - removing Authelia middleware references..."
        sed -i '/middlewares=authelia@docker/d' /opt/stacks/infrastructure/docker-compose.yml
    fi

    # Replace placeholders in infrastructure compose file
    localize_yml_file "/opt/stacks/infrastructure/docker-compose.yml"

    # Deploy infrastructure stack
    cd /opt/stacks/infrastructure
    run_cmd docker compose up -d || true
    log_success "Infrastructure stack deployed"
    echo ""
}

# Deploy dashboards stack function
deploy_dashboards() {
    log_info "Deploying dashboard stack..."
    log_info "  - Homepage (Application Dashboard)"
    log_info "  - Homarr (Modern Dashboard)"
    echo ""

    # Create dashboards directory
    sudo mkdir -p /opt/stacks/dashboards

    # Copy dashboards compose file
    cp "$REPO_DIR/docker-compose/dashboards/docker-compose.yml" /opt/stacks/dashboards/docker-compose.yml
    cp "$REPO_DIR/.env" /opt/stacks/dashboards/.env
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/dashboards/docker-compose.yml
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/dashboards/.env

    # Remove variables that dashboards stack doesn't need
    sed -i '/^AUTHELIA_/d' /opt/stacks/dashboards/.env
    sed -i '/^QBITTORRENT_/d' /opt/stacks/dashboards/.env
    sed -i '/^CODE_SERVER_/d' /opt/stacks/dashboards/.env
    sed -i '/^JUPYTER_/d' /opt/stacks/dashboards/.env
    sed -i '/^POSTGRES_/d' /opt/stacks/dashboards/.env
    sed -i '/^NEXTCLOUD_/d' /opt/stacks/dashboards/.env
    sed -i '/^GITEA_/d' /opt/stacks/dashboards/.env
    sed -i '/^WORDPRESS_/d' /opt/stacks/dashboards/.env
    sed -i '/^BOOKSTACK_/d' /opt/stacks/dashboards/.env
    sed -i '/^MEDIAWIKI_/d' /opt/stacks/dashboards/.env
    sed -i '/^BITWARDEN_/d' /opt/stacks/dashboards/.env
    sed -i '/^FORMIO_/d' /opt/stacks/dashboards/.env

    # Replace placeholders in dashboards compose file
    localize_yml_file "/opt/stacks/dashboards/docker-compose.yml"

    # Copy homepage config
    if [ -d "$REPO_DIR/docker-compose/dashboards/homepage" ]; then
        cp -r "$REPO_DIR/docker-compose/dashboards/homepage" /opt/stacks/dashboards/
        sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks/dashboards/homepage
        
        # Replace placeholders in homepage config files
        find /opt/stacks/dashboards/homepage -name "*.yaml" -type f | while read -r config_file; do
            localize_yml_file "$config_file"
        done
        
        # Remove remote server entries from homepage services for single-server setup
        if [ -z "${REMOTE_SERVER_HOSTNAME:-}" ]; then
            sed -i '/\${REMOTE_SERVER_HOSTNAME}/d' /opt/stacks/dashboards/homepage/services.yaml
            log_info "Single-server setup - removed remote server entries from homepage services"
        fi
        
        # Process template files and rename them
        find /opt/stacks/dashboards/homepage -name "*.template" -type f | while read -r template_file; do
            localize_yml_file "$template_file"
            # Rename template file to remove .template extension
            new_file="${template_file%.template}"
            mv "$template_file" "$new_file"
            log_info "Processed and renamed $template_file to $new_file"
        done
    fi

    # Replace placeholders in dashboards compose file
    localize_yml_file "/opt/stacks/dashboards/docker-compose.yml"

    # Deploy dashboards stack
    cd /opt/stacks/dashboards
    run_cmd docker compose up -d || true
    log_success "Dashboard stack deployed"
    echo ""
}

# Deployment function
perform_deployment() {
    debug_log "perform_deployment() called with DEPLOY_CORE=$DEPLOY_CORE, DEPLOY_INFRASTRUCTURE=$DEPLOY_INFRASTRUCTURE, DEPLOY_DASHBOARDS=$DEPLOY_DASHBOARDS, SETUP_STACKS=$SETUP_STACKS"
    log_info "Starting deployment..."

    # Initialize missing vars summary
    GLOBAL_MISSING_VARS=""
    TLS_ISSUES_SUMMARY=""

    # Switch back to regular user if we were running as root
    if [ "$EUID" -eq 0 ]; then
        ACTUAL_USER=${SUDO_USER:-$USER}
        debug_log "Running as root, switching to user $ACTUAL_USER"
        log_info "Switching to user $ACTUAL_USER for deployment..."
        exec sudo -u "$ACTUAL_USER" "$0" "$@"
    fi

    # Source the .env file safely
    debug_log "Sourcing .env file from $REPO_DIR/.env"
    load_env_file_safely "$REPO_DIR/.env"
    debug_log "Environment loaded, DOMAIN=$DOMAIN, SERVER_IP=$SERVER_IP"

    # Generate Authelia password hash if needed
    if [ "$AUTHELIA_ADMIN_PASSWORD_HASH" = "generate-with-openssl-rand-hex-64" ] || [ -z "$AUTHELIA_ADMIN_PASSWORD_HASH" ]; then
        log_info "Generating Authelia password hash..."
        if ! docker images | grep -q authelia/authelia; then
            docker pull authelia/authelia:latest > /dev/null 2>&1
        fi
        AUTHELIA_ADMIN_PASSWORD_HASH=$(docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password "$DEFAULT_PASSWORD" 2>&1 | grep -o '\$argon2id.*')
        if [ -z "$AUTHELIA_ADMIN_PASSWORD_HASH" ]; then
            log_error "Failed to generate Authelia password hash."
            exit 1
        fi
        # Save it back to .env
        sed -i "s%AUTHELIA_ADMIN_PASSWORD_HASH=.*%AUTHELIA_ADMIN_PASSWORD_HASH=\"$AUTHELIA_ADMIN_PASSWORD_HASH\"%" "$REPO_DIR/.env"
        log_success "Authelia password hash generated and saved"
    fi

    # Reload .env to get updated secrets
    load_env_file_safely "$REPO_DIR/.env"

    # Step 1: Create required directories
    log_info "Step 1: Creating required directories..."
    sudo mkdir -p /opt/stacks/core || { log_error "Failed to create /opt/stacks/core"; exit 1; }
    sudo mkdir -p /opt/stacks/infrastructure || { log_error "Failed to create /opt/stacks/infrastructure"; exit 1; }
    sudo mkdir -p /opt/stacks/dashboards || { log_error "Failed to create /opt/stacks/dashboards"; exit 1; }
    sudo mkdir -p /opt/dockge || { log_error "Failed to create /opt/dockge"; exit 1; }
    sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/stacks
    sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt/dockge
    log_success "Directories created"

    # Step 2: Setup multi-server TLS if needed
    if [ "$DEPLOY_CORE" = false ]; then
        setup_multi_server_tls
    fi

    # Step 3: Create Docker networks (if they don't exist)
    log_info "Step $([ "$DEPLOY_CORE" = false ] && echo "3" || echo "2"): Creating Docker networks..."
    docker network create homelab-network 2>/dev/null && log_success "Created homelab-network" || log_info "homelab-network already exists"
    docker network create traefik-network 2>/dev/null && log_success "Created traefik-network" || log_info "traefik-network already exists"
    docker network create media-network 2>/dev/null && log_success "Created media-network" || log_info "media-network already exists"
    echo ""

    # Step 4: Deploy Dockge (always deployed)
    deploy_dockge

    # Deploy core stack
    if [ "$DEPLOY_CORE" = true ]; then
        deploy_core
    fi

    # Deploy infrastructure stack
    if [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
        step_num=$([ "$DEPLOY_CORE" = true ] && echo "6" || echo "5")
        deploy_infrastructure
    fi

    # Deploy dashboard stack
    if [ "$DEPLOY_DASHBOARDS" = true ]; then
        if [ "$DEPLOY_CORE" = true ] && [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
            step_num=7
        elif [ "$DEPLOY_CORE" = true ] || [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
            step_num=6
        else
            step_num=5
        fi
        deploy_dashboards
    fi

    # Setup stacks for Dockge
    if [ "$SETUP_STACKS" = true ]; then
        setup_stacks_for_dockge
    fi

    # Report any missing variables
    if [ -n "$GLOBAL_MISSING_VARS" ]; then
        log_warning "The following environment variables were missing and may cause issues:"
        echo "$GLOBAL_MISSING_VARS"
        log_info "Please update your .env file and redeploy affected stacks."
    fi

    # TLS issues will be reported in the final summary
}

# Setup Docker TLS function
setup_docker_tls() {
    local TLS_DIR="/home/$ACTUAL_USER/EZ-Homelab/docker-tls"
    
    # Create TLS directory
    sudo mkdir -p "$TLS_DIR"
    sudo chown "$ACTUAL_USER:$ACTUAL_USER" "$TLS_DIR"
    
    # Use shared CA if available, otherwise generate local CA
    if [ -f "/opt/stacks/core/shared-ca/ca.pem" ] && [ -f "/opt/stacks/core/shared-ca/ca-key.pem" ]; then
        log_info "Using shared CA certificate for Docker TLS..."
        cp "/opt/stacks/core/shared-ca/ca.pem" "$TLS_DIR/ca.pem"
        cp "/opt/stacks/core/shared-ca/ca-key.pem" "$TLS_DIR/ca-key.pem"
    else
        log_info "Generating local CA certificate for Docker TLS..."
        # Generate CA
        openssl genrsa -out "$TLS_DIR/ca-key.pem" 4096
        openssl req -new -x509 -days 365 -key "$TLS_DIR/ca-key.pem" -sha256 -out "$TLS_DIR/ca.pem" -subj "/C=US/ST=State/L=City/O=Organization/CN=Docker-CA"
    fi
    
    # Generate server key and cert
    openssl genrsa -out "$TLS_DIR/server-key.pem" 4096
    openssl req -subj "/CN=$SERVER_IP" -new -key "$TLS_DIR/server-key.pem" -out "$TLS_DIR/server.csr"
    echo "subjectAltName = DNS:$SERVER_IP,IP:$SERVER_IP,IP:127.0.0.1" > "$TLS_DIR/extfile.cnf"
    openssl x509 -req -days 365 -in "$TLS_DIR/server.csr" -CA "$TLS_DIR/ca.pem" -CAkey "$TLS_DIR/ca-key.pem" -CAcreateserial -out "$TLS_DIR/server-cert.pem" -extfile "$TLS_DIR/extfile.cnf"
    
    # Generate client key and cert
    openssl genrsa -out "$TLS_DIR/client-key.pem" 4096
    openssl req -subj "/CN=client" -new -key "$TLS_DIR/client-key.pem" -out "$TLS_DIR/client.csr"
    openssl x509 -req -days 365 -in "$TLS_DIR/client.csr" -CA "$TLS_DIR/ca.pem" -CAkey "$TLS_DIR/ca-key.pem" -CAcreateserial -out "$TLS_DIR/client-cert.pem"
    
    # Configure Docker daemon
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "tls": true,
  "tlsverify": true,
  "tlscacert": "$TLS_DIR/ca.pem",
  "tlscert": "$TLS_DIR/server-cert.pem",
  "tlskey": "$TLS_DIR/server-key.pem"
}
EOF
    
    # Update systemd service
    sudo sed -i 's|-H fd://|-H fd:// -H tcp://0.0.0.0:2376|' /lib/systemd/system/docker.service
    
    # Reload and restart Docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    log_success "Docker TLS configured on port 2376"
}
setup_stacks_for_dockge() {
    log_info "Setting up all stacks for Dockge..."

    # List of stacks to setup
    STACKS=("vpn" "media" "media-management" "transcoders" "monitoring" "productivity" "wikis" "utilities" "alternatives" "homeassistant")

    for stack in "${STACKS[@]}"; do
        STACK_DIR="/opt/stacks/$stack"
        REPO_STACK_DIR="$REPO_DIR/docker-compose/$stack"

        if [ -d "$REPO_STACK_DIR" ]; then
            mkdir -p "$STACK_DIR"
            if [ -f "$REPO_STACK_DIR/docker-compose.yml" ]; then
                cp "$REPO_STACK_DIR/docker-compose.yml" "$STACK_DIR/docker-compose.yml"
                cp "$REPO_DIR/.env" "$STACK_DIR/.env"
                sudo chown "$ACTUAL_USER:$ACTUAL_USER" "$STACK_DIR/docker-compose.yml"
                sudo chown "$ACTUAL_USER:$ACTUAL_USER" "$STACK_DIR/.env"

                # Remove sensitive/unnecessary variables from stack .env
                sed -i '/^AUTHELIA_ADMIN_PASSWORD_HASH=/d' "$STACK_DIR/.env"
                sed -i '/^AUTHELIA_JWT_SECRET=/d' "$STACK_DIR/.env"
                sed -i '/^AUTHELIA_SESSION_SECRET=/d' "$STACK_DIR/.env"
                sed -i '/^AUTHELIA_STORAGE_ENCRYPTION_KEY=/d' "$STACK_DIR/.env"
                sed -i '/^SURFSHARK_/d' "$STACK_DIR/.env"
                sed -i '/^SMTP_/d' "$STACK_DIR/.env"
                sed -i '/^REMOTE_SERVER_/d' "$STACK_DIR/.env"
                sed -i '/^PIHOLE_/d' "$STACK_DIR/.env"
                sed -i '/^WATCHTOWER_/d' "$STACK_DIR/.env"
                sed -i '/^QBITTORRENT_/d' "$STACK_DIR/.env"
                sed -i '/^GRAFANA_/d' "$STACK_DIR/.env"
                sed -i '/^CODE_SERVER_/d' "$STACK_DIR/.env"
                sed -i '/^JUPYTER_/d' "$STACK_DIR/.env"
                sed -i '/^POSTGRES_/d' "$STACK_DIR/.env"
                sed -i '/^PGADMIN_/d' "$STACK_DIR/.env"
                sed -i '/^NEXTCLOUD_/d' "$STACK_DIR/.env"
                sed -i '/^GITEA_/d' "$STACK_DIR/.env"
                sed -i '/^WORDPRESS_/d' "$STACK_DIR/.env"
                sed -i '/^BOOKSTACK_/d' "$STACK_DIR/.env"
                sed -i '/^MEDIAWIKI_/d' "$STACK_DIR/.env"
                sed -i '/^BITWARDEN_/d' "$STACK_DIR/.env"
                sed -i '/^FORMIO_/d' "$STACK_DIR/.env"
                sed -i '/^HOMEPAGE_VAR_/d' "$STACK_DIR/.env"

                # Replace placeholders in the compose file
                localize_yml_file "$STACK_DIR/docker-compose.yml"

                # Copy any additional config directories
                for config_dir in "$REPO_STACK_DIR"/*/; do
                    if [ -d "$config_dir" ] && [ "$(basename "$config_dir")" != "." ]; then
                        cp -r "$config_dir" "$STACK_DIR/"
                        sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" "$STACK_DIR/$(basename "$config_dir")"
                        
                        # Replace placeholders in config files
                        find "$STACK_DIR/$(basename "$config_dir")" -name "*.yml" -o -name "*.yaml" | while read -r config_file; do
                            localize_yml_file "$config_file"
                        done
                    fi
                done

                log_success "Prepared $stack stack for Dockge"
            else
                log_warning "$stack stack docker-compose.yml not found, skipping..."
            fi
        else
            log_warning "$stack stack directory not found in repo, skipping..."
        fi
    done

    log_success "All stacks prepared for Dockge deployment"
    echo ""
}

# Main menu
show_main_menu() {
    echo ""
    echo "╔═════════════════════════════════════════════════════════════╗"
    echo "║          EZ-HOMELAB           SETUP & DEPLOYMENT            ║"
    echo "║                                                             ║"
    echo "║                1)  Install Prerequisites                    ║"
    echo "║                2)  Deploy Core Server                       ║"
    echo "║                3)  Deploy Additional Server                 ║"
    echo "║                4)  Install NVIDIA Drivers                   ║"
    echo "║                                                             ║"
    echo "║                q)  Quit                                     ║"
    echo "╚═════════════════════════════════════════════════════════════╝"
    echo ""
}

# Show help function
show_help() {
    echo "EZ-Homelab Setup & Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -d, --dry-run           Enable dry-run mode (show commands without executing)"
    echo "  -c, --config FILE       Specify configuration file (default: .env)"
    echo "  -t, --test              Run in test mode (validate configs without deploying)"
    echo "  -v, --validate-only     Only validate configuration and exit"
    echo "      --verbose           Enable verbose console logging"
    echo ""
    echo "If no options are provided, the interactive menu will be shown."
    echo ""
}

# Validate configuration function
validate_configuration() {
    log_info "Validating configuration..."

    # Check if .env file exists
    if [ ! -f ".env" ]; then
        log_error "Configuration file .env not found."
        return 1
    fi

    # Load and check required environment variables
    if ! load_env_file; then
        log_error "Failed to load .env file."
        return 1
    fi

    # Check for critical variables
    local required_vars=("DOMAIN" "SERVER_IP" "DUCKDNS_TOKEN" "AUTHELIA_ADMIN_PASSWORD_HASH")
    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi

    # Check Docker Compose files syntax
    log_info "Checking Docker Compose file syntax..."
    if command -v docker-compose &> /dev/null; then
        if ! docker-compose -f docker-compose/core/docker-compose.yml config -q; then
            log_error "Invalid syntax in core docker-compose.yml"
            return 1
        fi
        log_success "Core docker-compose.yml syntax is valid"
    else
        log_warning "docker-compose not available for syntax check"
    fi

    # Check network connectivity (basic)
    log_info "Checking network connectivity..."
    if ! ping -c 1 google.com &> /dev/null; then
        log_warning "No internet connectivity detected"
    else
        log_success "Internet connectivity confirmed"
    fi

    log_success "Configuration validation completed successfully"
}

# Parse command line arguments function
parse_args() {
    DRY_RUN=false
    CONFIG_FILE=".env"
    TEST_MODE=false
    VALIDATE_ONLY=false
    VERBOSE=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -t|--test)
                TEST_MODE=true
                shift
                ;;
            -v|--validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Prepare deployment environment
prepare_deployment() {
    # Handle special menu options
    if [ "$FORCE_SYSTEM_SETUP" = true ]; then
        log_info "Installing prerequisites..."
        # Run the prerequisites script as root
        if [ "$EUID" -eq 0 ]; then
            ./scripts/install-prerequisites.sh
        else
            sudo ./scripts/install-prerequisites.sh
        fi
        log_success "Prerequisites installed successfully."
        exit 0
    fi

    if [ "$INSTALL_NVIDIA" = true ]; then
        log_info "Installing NVIDIA drivers..."
        install_nvidia
        exit 0
    fi

    # Check if system setup is needed
    # Only run system setup if Docker is not installed OR if running as root and Docker setup hasn't been done
    DOCKER_INSTALLED=false
    if command -v docker &> /dev/null && docker --version &> /dev/null; then
        DOCKER_INSTALLED=true
    fi

    # Check if current user is in docker group (or if we're root and will add them)
    USER_IN_DOCKER_GROUP=false
    if groups "$USER" 2>/dev/null | grep -q docker; then
        USER_IN_DOCKER_GROUP=true
    fi

    if [ "$EUID" -eq 0 ]; then
        # Running as root - check if we need to do system setup
        if [ "$DOCKER_INSTALLED" = false ] || [ "$USER_IN_DOCKER_GROUP" = false ]; then
            log_info "Docker not fully installed or user not in docker group. Performing system setup..."
            ./scripts/install-prerequisites.sh
            echo ""
            log_info "System setup complete. Please log out and back in, then run this script again."
            exit 0
        else
            log_info "Docker is already installed and user is in docker group. Skipping system setup."
        fi
    else
        # Not running as root
        if [ "$DOCKER_INSTALLED" = false ]; then
            log_error "Docker is not installed. Please run this script with sudo to perform system setup."
            exit 1
        fi
        if [ "$USER_IN_DOCKER_GROUP" = false ]; then
            log_error "Current user is not in the docker group. Please log out and back in, or run with sudo to fix group membership."
            exit 1
        fi
    fi

    # Ensure required directories exist
    log_info "Ensuring required directories exist..."
    if [ "$EUID" -eq 0 ]; then
        ACTUAL_USER=${SUDO_USER:-$USER}
        mkdir -p /opt/stacks /opt/dockge
        chown -R "$ACTUAL_USER:$ACTUAL_USER" /opt
    else
        mkdir -p /opt/stacks /opt/dockge
    fi
    log_success "Directories prepared"
}

# Run command function (handles dry-run and test modes)
run_cmd() {
    if [ "$DRY_RUN" = true ] || [ "$TEST_MODE" = true ]; then
        echo "[DRY-RUN/TEST] $@"
        return 0
    else
        if "$@"; then
            return 0
        else
            log_error "Command failed: $@"
            return 1
        fi
    fi
}

# Main logic
main() {
    debug_log "main() called with arguments: $@"
    log_info "EZ-Homelab Unified Setup & Deployment Script"
    clear
    echo ""

    # Parse command line arguments
    parse_args "$@"

    if [ "$DRY_RUN" = true ]; then
        log_info "Dry-run mode enabled. Commands will be displayed but not executed."
    fi

    if [ "$VALIDATE_ONLY" = true ]; then
        log_info "Validation mode enabled. Checking configuration..."
        validate_configuration
        exit 0
    fi

    if [ "$TEST_MODE" = true ]; then
        log_info "Test mode enabled. Will validate and simulate deployment."
    fi

    # Load existing configuration
    ENV_EXISTS=false
    if load_env_file; then
        ENV_EXISTS=true
        debug_log "Existing .env file loaded"
    else
        debug_log "No existing .env file found"
    fi

    # Menu selection loop
    while true; do
        # Show main menu
        show_main_menu
        read -p "Choose an option (1-4 or q): " MAIN_CHOICE

        case $MAIN_CHOICE in
            1)
                log_info "Selected: Install Prerequisites"
                FORCE_SYSTEM_SETUP=true
                DEPLOY_CORE=false
                DEPLOY_INFRASTRUCTURE=false
                DEPLOY_DASHBOARDS=false
                SETUP_STACKS=false
                break
                ;;
            2)
                log_info "Selected: Deploy Core Server"
                DEPLOY_CORE=true
                DEPLOY_INFRASTRUCTURE=true
                DEPLOY_DASHBOARDS=true
                SETUP_STACKS=true
                break
                ;;
            3)
                log_info "Selected: Deploy Additional Server"
                echo ""
                echo "⚠️  IMPORTANT: Deploying an additional server requires an existing core server to be already deployed."
                echo "The core server provides essential services like Traefik, Authelia, and shared TLS certificates."
                echo ""
                read -p "Do you have an existing core server deployed? (y/N): " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    log_info "Returning to main menu. Please deploy a core server first using Option 2."
                    echo ""
                    sleep 2
                    continue
                fi
                DEPLOY_CORE=false
                DEPLOY_INFRASTRUCTURE=true
                DEPLOY_DASHBOARDS=false
                SETUP_STACKS=true
                break
                ;;
            4)
                log_info "Selected: Install NVIDIA Drivers"
                INSTALL_NVIDIA=true
                DEPLOY_CORE=false
                DEPLOY_INFRASTRUCTURE=false
                DEPLOY_DASHBOARDS=false
                SETUP_STACKS=false
                break
                ;;
            [Qq]|[Qq]uit)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_warning "Invalid choice '$MAIN_CHOICE'. Please select 1-4 or q to quit."
                echo ""
                sleep 2
                continue
                ;;
        esac
    done

    echo ""

    # Prepare deployment environment
    prepare_deployment

    # Prompt for configuration values
    validate_and_prompt_variables

    # Save configuration
    save_env_file

    # Validate secrets for core deployment
    validate_secrets

    # Perform deployment
    perform_deployment

    # Show completion message
    echo ""
    echo "╔═════════════════════════════════════════════════════════════╗"
    echo "║                  Deployment Complete!                       ║"
    echo "║  SSL Certificates may take a few minutes to be issued.      ║"
    echo "║                                                             ║"
    echo "║  https://dockge.${DOMAIN}                                   ║"
    echo "║  http://${SERVER_IP}:5001                                   ║"
    echo "║                                                             ║"
    echo "║  https://homepage.${DOMAIN}                                 ║"
    echo "║  http://${SERVER_IP}:3003                                    ║"
    echo "║                                                             ║"
    echo "╚═════════════════════════════════════════════════════════════╝"

    # Show consolidated warnings if any
    if [ -n "$GLOBAL_MISSING_VARS" ] || [ -n "$TLS_ISSUES_SUMMARY" ]; then
        echo "╔═════════════════════════════════════════════════════════════╗"
        echo "║                     ⚠️  WARNING  ⚠️                        ║"
        echo "║       The following variables were not defined              ║"
        echo "║  If something isn't working as expected check these first   ║"
        echo "║                                                             ║"
        
        if [ -n "$GLOBAL_MISSING_VARS" ]; then
            log_warning "Missing Environment Variables:"
            echo "$GLOBAL_MISSING_VARS"
            echo "║                                                             ║"
        fi
                
        if [ -n "$TLS_ISSUES_SUMMARY" ]; then
            log_warning "TLS Configuration Issues:"
            echo "$TLS_ISSUES_SUMMARY"
            echo "║                                                             ║"
        fi
    fi
    echo "╚═════════════════════════════════════════════════════════════╝"

    echo "╔══════════════════════════════════════════╗"
    echo "║              📚 RESOURCES                 ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    echo "  📖 Documentation: $REPO_DIR/docs/"
    echo "  🔧 Quick Reference: $REPO_DIR/docs/quick-reference.md"
    echo "  🐙 Repository: https://github.com/your-repo/ez-homelab"
    echo "  📋 Wiki: https://github.com/your-repo/ez-homelab/wiki"
    echo ""
    debug_log "Script completed successfully"
    echo ""
}

# Run main function
main "$@"