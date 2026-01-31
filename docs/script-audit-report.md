# EZ-Homelab Script Audit Report
## Generated: 30 January 2026

### Executive Summary
The `ez-homelab.sh` script is a comprehensive Bash-based deployment tool for the EZ-Homelab project. It handles system setup, Docker configuration, and multi-stage service deployment. The script supports three main deployment modes with varying complexity. While functional for infrastructure-only deployments (Option 3), the core-only deployment (Option 2) has critical issues with Authelia secret generation and configuration that prevent successful deployment.

### Script Architecture

#### Global Variables & Constants
- **Color codes**: RED, GREEN, YELLOW, BLUE, NC for console output formatting
- **Logging functions**: `log_info()`, `log_success()`, `log_warning()`, `log_error()`
- **Deployment flags**: DEPLOY_CORE, DEPLOY_INFRASTRUCTURE, DEPLOY_DASHBOARDS, SETUP_STACKS
- **Configuration variables**: DOMAIN, SERVER_IP, ADMIN_USER, etc.
- **Path variables**: SCRIPT_DIR, REPO_DIR, ACTUAL_USER

#### Core Functions

##### 1. `replace_env_placeholders()`
**Purpose**: Replaces `${VAR}` placeholders in files with actual environment variable values
**Process**:
- Takes file path as argument
- Uses `grep` to find all `${VAR}` patterns
- Checks if each variable exists in environment
- Uses `sed` for replacement: `s|\${VAR}|${!VAR}|g`
- Accumulates missing variables in `MISSING_VARS_SUMMARY`
**Issues**: 
- Only reports missing variables at end, doesn't fail deployment
- No validation of replacement success

##### 2. `generate_shared_ca()`
**Purpose**: Creates shared Certificate Authority for multi-server TLS
**Process**:
- Creates `/opt/stacks/core/shared-ca/` directory
- Generates 4096-bit RSA CA key and certificate (365 days validity)
- Sets ownership to `$ACTUAL_USER:$ACTUAL_USER`
**Output**: ca.pem, ca-key.pem files

##### 3. `setup_multi_server_tls()`
**Purpose**: Configures TLS for remote Docker access using shared CA
**Process**:
- Prompts for core server IP if not set
- Tests SSH connectivity (key auth first, then password)
- Fetches CA certificates from core server via SCP
- Calls `setup_docker_tls()` if successful
**Issues**:
- Complex SSH authentication logic
- No fallback if CA fetch fails
- TLS_ISSUES_SUMMARY populated but not always accurate

##### 4. `load_env_file()`
**Purpose**: Loads existing configuration from `.env` file
**Process**:
- Checks for `$REPO_DIR/.env` existence
- Sources the file if found
- Displays current configuration values
- Returns 0 if file exists, 1 if not
**Issues**: No validation of loaded values

##### 5. `save_env_file()`
**Purpose**: Persists configuration to `.env` file
**Process**:
- Creates `.env` from `.env.example` if needed
- Updates values using `sed` replacements
- For core deployment: generates Authelia secrets and password hash
**Critical Issue**: Authelia secret generation is here, but may not be called in all deployment paths

##### 6. `prompt_for_values()`
**Purpose**: Interactive configuration collection
**Process**:
- Shows current/default values
- Allows user to accept defaults or enter custom values
- Handles sensitive inputs (passwords) with `-s` flag
- Sets ADMIN_* variables for core deployment
**Issues**: Complex logic with many conditional branches

##### 7. `system_setup()`
**Purpose**: Performs initial system configuration (requires root)
**Process**:
1. System package updates
2. Installs prerequisites (curl, wget, git, etc.)
3. Installs/configures Docker and Docker Compose
4. Generates shared CA
5. Configures Docker TLS
6. Sets up UFW firewall
7. Configures automatic updates
8. Creates Docker networks
9. Sets directory ownership
**Issues**: 
- Requires logout/login for Docker group changes
- No rollback on failure

##### 8. `deploy_dockge()`
**Purpose**: Deploys Dockge stack management interface
**Process**:
- Copies compose file and .env to `/opt/dockge/`
- Replaces placeholders
- Runs `docker compose up -d`
**Output**: Dockge service running

##### 9. `deploy_core()`
**Purpose**: Deploys core infrastructure stack
**Process**:
1. Copies compose file and .env to `/opt/stacks/core/`
2. Copies Traefik and Authelia config templates
3. Replaces placeholders in all config files
4. Generates shared CA
5. Replaces Authelia-specific secrets and user data
6. Runs `docker compose up -d`
**Critical Issues**:
- Assumes Authelia secrets exist in environment
- No validation that secrets were generated
- Complex placeholder replacement logic

##### 10. `deploy_infrastructure()` / `deploy_dashboards()`
**Purpose**: Deploy additional service stacks
**Process**: Similar to deploy_core but simpler
- Copy files, replace placeholders, deploy
**Issues**: Conditional Authelia middleware removal when core not deployed

##### 11. `setup_docker_tls()`
**Purpose**: Configures Docker daemon for TLS
**Process**:
1. Creates TLS directory
2. Uses shared CA or generates local CA
3. Generates server and client certificates
4. Updates Docker daemon.json
5. Modifies systemd service for TCP 2376
6. Restarts Docker service

##### 12. `setup_stacks_for_dockge()`
**Purpose**: Prepares all service stacks for Dockge management
**Process**:
- Iterates through predefined stack list
- Copies compose files and configs
- Replaces placeholders
- Prepares but doesn't deploy stacks

### Deployment Flow Analysis

#### Option 1: Default Setup
**Flags**: DEPLOY_CORE=true, DEPLOY_INFRASTRUCTURE=true, DEPLOY_DASHBOARDS=true, SETUP_STACKS=true
**Flow**:
1. System setup (if needed)
2. Prompt for values
3. Save env file (generates Authelia secrets)
4. Deploy Dockge
5. Deploy core (uses generated secrets)
6. Deploy infrastructure
7. Deploy dashboards
8. Setup stacks for Dockge

#### Option 2: Core Only
**Flags**: DEPLOY_CORE=true, DEPLOY_INFRASTRUCTURE=false, DEPLOY_DASHBOARDS=true, SETUP_STACKS=true
**Flow**:
1. System setup (if needed)
2. Prompt for values
3. Save env file (generates Authelia secrets)
4. Deploy Dockge
5. Deploy core (uses generated secrets)
6. Deploy dashboards
7. Setup stacks for Dockge

#### Option 3: Infrastructure Only
**Flags**: DEPLOY_CORE=false, DEPLOY_INFRASTRUCTURE=true, DEPLOY_DASHBOARDS=false, SETUP_STACKS=true
**Flow**:
1. System setup (if needed)
2. Prompt for values
3. Save env file (no Authelia secrets generated)
4. Setup multi-server TLS
5. Deploy Dockge
6. Deploy infrastructure
7. Setup stacks for Dockge

### Critical Issues Identified

#### 1. Authelia Secret Generation Timing (Option 2)
**Problem**: In Option 2, `save_env_file()` is called and should generate Authelia secrets, but the deployment may fail if secrets aren't properly set.
**Root Cause**: The `save_env_file()` function generates secrets only when `DEPLOY_CORE=true`, but the generation logic may not execute or persist correctly.
**Impact**: Authelia container fails to start due to missing JWT_SECRET, SESSION_SECRET, or STORAGE_ENCRYPTION_KEY

#### 2. Environment Variable Persistence
**Problem**: After `save_env_file()`, the script sources the .env file, but there may be a timing issue where variables aren't available for `deploy_core()`.
**Evidence**: The script does `source "$REPO_DIR/.env"` in `perform_deployment()`, but if secrets weren't saved properly, they'll be empty.

#### 3. Placeholder Replacement Order
**Problem**: `replace_env_placeholders()` is called during deployment, but if environment variables are missing, replacements fail silently.
**Impact**: Configuration files contain literal `${VAR}` strings instead of actual values.

#### 4. Authelia Password Hash Generation
**Problem**: Password hash generation happens in `save_env_file()`, but requires Docker to be running and Authelia image to be available.
**Issues**: 
- May fail if Docker isn't ready
- Uses complex docker run command that could timeout
- No fallback if hash generation fails

#### 5. Multi-Server TLS Complexity
**Problem**: `setup_multi_server_tls()` has complex SSH logic that can fail in multiple ways.
**Issues**:
- SSH key vs password detection unreliable
- No retry logic for connection failures
- Error reporting doesn't clearly indicate resolution steps

#### 6. Directory Creation Race Conditions
**Problem**: Script creates directories with sudo, then tries to write files as regular user.
**Potential Issue**: Permission conflicts if ownership isn't set correctly.

### Recommendations

#### Immediate Fixes for Option 2
1. **Add Secret Validation**: After `save_env_file()`, validate that all required Authelia secrets exist before proceeding with deployment.

2. **Improve Error Handling**: Make `replace_env_placeholders()` fail deployment if critical variables are missing.

3. **Add Authelia Health Check**: After core deployment, verify Authelia container is running and healthy.

#### Structural Improvements
1. **Separate Secret Generation**: Move Authelia secret generation to a dedicated function called before deployment.

2. **Add Pre-deployment Validation**: Create a validation function that checks all required environment variables and Docker state before starting deployment.

3. **Simplify TLS Setup**: Reduce complexity in multi-server TLS setup with better error handling and user guidance.

4. **Add Rollback Capability**: Implement cleanup functions for failed deployments.

#### Code Quality
1. **Reduce Function Complexity**: Break down large functions like `deploy_core()` into smaller, testable units.

2. **Add Logging**: Increase verbosity for debugging deployment issues.

3. **Configuration Management**: Consider using a configuration file format (YAML/JSON) instead of .env for complex setups.

### Testing Recommendations
1. **Unit Test Functions**: Test individual functions like `replace_env_placeholders()` and `generate_shared_ca()` in isolation.

2. **Integration Testing**: Test each deployment option in a clean environment.

3. **Error Scenario Testing**: Test failure modes (missing Docker, network issues, invalid credentials).

### Conclusion
The `ez-homelab.sh` script is a solid foundation for automated homelab deployment, but Option 2 (Core Only) has critical issues with Authelia secret management that prevent reliable deployment. The script needs focused improvements in error handling, validation, and secret generation to achieve the reliability required for critical infrastructure deployment.