#!/bin/bash
# EZ-Homelab Common Functions Library
# Shared utilities for deploy scripts

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
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] ===== EZ-HOMELAB COMMON LIBRARY STARTED =====" > "$DEBUG_LOG_FILE"
    debug_log "Common library loaded"
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
            local value=$(printf '%s\n' "${BASH_REMATCH[2]}" | sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//")

            # Strip inline comments
            value=${value%%#*}

            # Trim whitespace from key and value
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)

            # Strip surrounding quotes if present
            if [[ $value =~ ^\"(.*)\"$ ]]; then
                value="${BASH_REMATCH[1]}"
            elif [[ $value =~ ^\'(.*)\'$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi

            # Strip carriage return if present (DOS line endings)
            value=${value%$'\r'}

            # Export the variable
            export "$key"="$value"

            debug_log "Exported $key=[HIDDEN]"  # Don't log actual values for security
        fi
    done < "$env_file"

    debug_log "Env file loaded successfully"
}

# Function to localize compose labels (only labels, not environment variables)
localize_compose_labels() {
    local file_path="$1"
    debug_log "localize_compose_labels called for file: $file_path"

    if [ ! -f "$file_path" ]; then
        log_warning "File $file_path does not exist, skipping compose labels localization"
        return
    fi

    # Create a temporary file for processing
    temp_file="$file_path.tmp"
    cp "$file_path" "$temp_file"

    # Use envsubst to replace ${VAR} in labels only, with nested expansion
    # This handles labels like "traefik.http.routers.${SERVICE_NAME}.rule=Host(`${SERVICE_NAME}.${DOMAIN}`)"
    if command -v envsubst >/dev/null 2>&1; then
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
        debug_log "Replaced variables in compose labels for $file_path"
    else
        log_warning "envsubst not available, cannot localize compose labels for $file_path"
        rm -f "$temp_file"
        return
    fi
}

# Function to localize users_database.yml with special handling for password hashes
localize_users_database_file() {
    local file_path="$1"
    debug_log "localize_users_database_file called for file: $file_path"

    if [ ! -f "$file_path" ]; then
        log_warning "File $file_path does not exist, skipping users database localization"
        return
    fi

    # Create a temporary file for processing
    temp_file="$file_path.tmp"
    cp "$file_path" "$temp_file"

    # Resolve nested variables first
    local resolved_user="${AUTHELIA_ADMIN_USER}"
    local resolved_email=$(eval echo "${AUTHELIA_ADMIN_EMAIL}")
    local resolved_password="${AUTHELIA_ADMIN_PASSWORD_HASH}"

    # Escape $ in password hash for sed
    local escaped_password=$(printf '%s\n' "$resolved_password" | sed 's/\$/\\$/g')

    # Use sed to substitute the resolved values
    sed -i "s|\${AUTHELIA_ADMIN_USER}|$resolved_user|g" "$temp_file"
    sed -i "s|\${AUTHELIA_ADMIN_EMAIL}|$resolved_email|g" "$temp_file"
    sed -i "s|\${AUTHELIA_ADMIN_PASSWORD_HASH}|$escaped_password|g" "$temp_file"
    sed -i "s|\${DEFAULT_EMAIL}|$resolved_email|g" "$temp_file"

    mv "$temp_file" "$file_path"
    debug_log "Replaced variables in users database file $file_path"
}

# Function to localize config files (full replacement)
localize_config_file() {
    local file_path="$1"
    debug_log "localize_config_file called for file: $file_path"

    if [ ! -f "$file_path" ]; then
        log_warning "File $file_path does not exist, skipping config file localization"
        return
    fi

    # Use envsubst to replace all ${VAR} with environment values, handling nested variables
    if command -v envsubst >/dev/null 2>&1; then
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
        debug_log "Replaced variables in config file $file_path"
    else
        log_warning "envsubst not available, cannot localize config file $file_path"
        rm -f "$temp_file"
        return
    fi
}

# Enhanced command execution with error handling
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
