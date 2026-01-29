# EZ-Homelab TUI Deployment Script

## Script Launch Options

**Command Line Arguments:**
- No arguments: Interactive TUI mode
- `--yes` or `-y`: Automated deployment using complete .env file
- `--save-only`: Answer questions and save .env without deploying
- `--help`: Show help information

## .env File Structure Enhancement

Add deployment configuration section to .env:

```bash
# ... existing configuration ...

##################################################
# DEPLOYMENT CONFIGURATION (Optional - for automated deployment)
# Set these values to skip the TUI and use --yes for automated install
##################################################

# Deployment Type: SINGLE_SERVER, CORE_SERVER, REMOTE_SERVER
DEPLOYMENT_TYPE=SINGLE_SERVER

# Service Selection (true/false)
DEPLOY_DOCKGE=true
DEPLOY_CORE=true
DEPLOY_INFRASTRUCTURE=true
DEPLOY_DASHBOARDS=true
PREPARE_VPN=true
PREPARE_MEDIA=true
PREPARE_MEDIA_MGMT=true
PREPARE_TRANSCODERS=true
PREPARE_HOMEASSISTANT=true
PREPARE_PRODUCTIVITY=true
PREPARE_MONITORING=true
PREPARE_UTILITIES=true
PREPARE_WIKIS=true
PREPARE_ALTERNATIVES=false

# System Configuration
INSTALL_DOCKER=true
INSTALL_NVIDIA=true
AUTO_REBOOT=true
```

## Pre-Flight Checks (Before TUI)

**System Prerequisites Check:**
- Check OS compatibility (Ubuntu/Debian)
- Check if running as root or with sudo
- Check internet connectivity
- Check available disk space (>10GB)
- Check system architecture (amd64/arm64)

**Docker Check:**
- Check if Docker is installed and running
- Check if user is in docker group
- If not installed: Prompt to install Docker
- If installed but user not in group: Add user to group

**NVIDIA GPU Detection:**
- Check for NVIDIA GPU presence (`lspci | grep -i nvidia`)
- If GPU detected: Check for existing drivers
- Check for NVIDIA Container Toolkit
- If missing: Prompt to install drivers and toolkit
- Detect GPU model for correct driver version

**Dependency Installation:**
- Install required packages: `curl wget git htop nano ufw fail2ban unattended-upgrades apt-listchanges sshpass`
- Update system packages
- Install Python dependencies for TUI: `rich questionary python-dotenv`

## Enhanced Question Flow

## Initial Setup Check

**Question 0: Environment File Check**
- Type: `confirm`
- Message: "Found existing .env file with configuration. Use existing values where available?"
- Default: true
- Condition: Only show if .env exists and has valid values

**Question 0.5: Complete Configuration Check**
- Type: `confirm`
- Message: "Your .env file appears to be complete. Skip questions and proceed with deployment?"
- Default: true
- Condition: Only show if all required values are present and valid

## System Setup Questions

**Question 0.6: Docker Installation**
- Type: `confirm`
- Message: "Docker is not installed. Install Docker now?"
- Default: true
- Condition: Only show if Docker not detected

**Question 0.7: NVIDIA Setup**
- Type: `confirm`
- Message: "NVIDIA GPU detected. Install NVIDIA drivers and Container Toolkit?"
- Default: true
- Condition: Only show if GPU detected but drivers/toolkit missing

**Question 0.8: Auto Reboot**
- Type: `confirm`
- Message: "Some installations require a system reboot. Reboot automatically when needed?"
- Default: false
- Note: Warns about potential logout requirement for docker group changes

## Initial Setup Check

## Deployment Scenario Selection

**Question 1: Deployment Type**
- Type: `select` (single choice)
- Message: "Choose your Deployment Scenario"
- Choices:
  - "🚀 Single Server Full Deployment - Deploy everything (Dockge, Core, Infrastructure, Dashboards) and prepare all stacks for Dockge"
  - "🏗️ Core Server Deployment - Deploy only core infrastructure (Dockge, Core, Dashboards) and prepare all stacks for Dockge"
  - "🔧 Remote Server Deployment - Deploy infrastructure tools (Dockge, Infrastructure, Dashboards) without core services and prepare all stacks for Dockge"
- Default: First option

## Basic Configuration (Conditional - skip if valid values exist)

**Question 2: Domain Setup**
- Type: `text`
- Message: "Enter your DuckDNS subdomain (without .duckdns.org)"
- Default: From .env or "example"
- Validation: Required, alphanumeric + hyphens only
- Condition: Skip if valid DOMAIN exists in .env

**Question 3: DuckDNS Token**
- Type: `password`
- Message: "Enter your DuckDNS token"
- Validation: Required
- Condition: Skip if valid DUCKDNS_TOKEN exists in .env

**Question 4: Server IP Address**
- Type: `text`
- Message: "Enter this server's IP address"
- Default: From .env or auto-detected local IP
- Validation: Valid IP address format
- Condition: Skip if valid SERVER_IP exists in .env

**Question 5: Server Hostname**
- Type: `text`
- Message: "Enter this server's hostname"
- Default: From .env or auto-detected hostname
- Validation: Required
- Condition: Skip if valid SERVER_HOSTNAME exists in .env

**Question 6: Timezone**
- Type: `text`
- Message: "Enter your timezone"
- Default: From .env or "America/New_York"
- Validation: Valid timezone format
- Condition: Skip if valid TZ exists in .env

## Admin Credentials (Conditional - only for deployments with Core, skip if valid)

**Question 7: Admin Username**
- Type: `text`
- Message: "Enter admin username for Authelia SSO"
- Default: From .env or "admin"
- Validation: Required, alphanumeric only
- Condition: Only show if deployment includes core services AND no valid AUTHELIA_ADMIN_USER exists

**Question 8: Admin Email**
- Type: `text`
- Message: "Enter admin email for Authelia SSO"
- Default: From .env or "admin@{domain}"
- Validation: Valid email format
- Condition: Only show if deployment includes core services AND no valid AUTHELIA_ADMIN_EMAIL exists

**Question 9: Admin Password**
- Type: `password`
- Message: "Enter admin password for Authelia SSO (will be hashed)"
- Validation: Minimum 8 characters
- Condition: Only show if deployment includes core services AND no valid AUTHELIA_ADMIN_PASSWORD exists

## Multi-Server Configuration (Conditional - only for Remote Server Deployment, skip if valid)

**Question 10: Core Server IP**
- Type: `text`
- Message: "Enter the IP address of your core server (for shared TLS CA)"
- Default: From .env
- Validation: Valid IP address format
- Condition: Only show for Remote Server Deployment AND no valid REMOTE_SERVER_IP exists

**Question 11: Core Server SSH User**
- Type: `text`
- Message: "Enter SSH username for core server access"
- Default: From .env or current user
- Validation: Required
- Condition: Only show for Remote Server Deployment AND no valid REMOTE_SERVER_USER exists

**Question 12: Core Server SSH Password**
- Type: `password`
- Message: "Enter SSH password for core server (leave empty if using SSH keys)"
- Validation: Optional
- Condition: Only show for Remote Server Deployment AND no valid REMOTE_SERVER_PASSWORD exists

## Optional Advanced Configuration (skip if valid values exist)

**Question 13: VPN Setup**
- Type: `confirm`
- Message: "Would you like to configure VPN for download services?"
- Default: true if VPN credentials exist in .env, false otherwise
- Condition: Skip if user explicitly chooses to configure later

**Question 14: Surfshark Username** (Conditional)
- Type: `text`
- Message: "Enter your Surfshark VPN username"
- Default: From .env
- Validation: Required
- Condition: Only show if VPN setup = true AND no valid SURFSHARK_USERNAME exists

**Question 15: Surfshark Password** (Conditional)
- Type: `password`
- Message: "Enter your Surfshark VPN password"
- Validation: Required
- Condition: Only show if VPN setup = true AND no valid SURFSHARK_PASSWORD exists

**Question 16: VPN Server Country**
- Type: `text`
- Message: "Preferred VPN server country"
- Default: From .env or "Netherlands"
- Condition: Only show if VPN setup = true AND no valid VPN_SERVER_COUNTRIES exists

**Question 17: Custom User/Group IDs**
- Type: `confirm`
- Message: "Use custom PUID/PGID for file permissions? (Default: 1000/1000)"
- Default: true if custom PUID/PGID exist in .env, false otherwise

**Question 18: PUID** (Conditional)
- Type: `text`
- Message: "Enter PUID (user ID)"
- Default: From .env or "1000"
- Validation: Numeric
- Condition: Only show if custom IDs = true AND no valid PUID exists

**Question 19: PGID** (Conditional)
- Type: `text`
- Message: "Enter PGID (group ID)"
- Default: From .env or "1000"
- Validation: Numeric
- Condition: Only show if custom IDs = true AND no valid PGID exists

## Service Selection Summary (for all deployment types)

**Question 20: Core Services Selection**
- Type: `checkbox` (multi-select)
- Message: "Select which core services to deploy:"
- Choices: (based on deployment type)
  - Single Server: [✓] DuckDNS, [✓] Traefik, [✓] Authelia, [✓] Sablier, [✓] Dockge
  - Core Server: [✓] DuckDNS, [✓] Traefik, [✓] Authelia, [✓] Sablier, [✓] Dockge
  - Remote Server: [ ] DuckDNS, [ ] Traefik, [ ] Authelia, [ ] Sablier, [✓] Dockge
- Default: All enabled for selected deployment type
- Note: Core services are required for the selected deployment type

**Question 21: Infrastructure Services Selection**
- Type: `checkbox` (multi-select)
- Message: "Select which infrastructure services to deploy:"
- Choices:
  - [✓] Pi-hole (DNS + Ad blocking)
  - [✓] Watchtower (Auto container updates)
  - [✓] Dozzle (Docker log viewer)
  - [✓] Glances (System monitoring)
  - [✓] Code Server (VS Code in browser)
  - [✓] Docker Proxy (Secure socket access)
- Default: All enabled
- Condition: Always shown, but some may be pre-selected based on deployment type

**Question 22: Dashboard Services Selection**
- Type: `checkbox` (multi-select)
- Message: "Select which dashboard services to deploy:"
- Choices:
  - [✓] Homepage (App dashboard)
  - [ ] Homarr (Modern dashboard)
- Default: Homepage enabled, Homarr disabled
- Condition: Always shown

**Question 23: Additional Stacks to Prepare**
- Type: `checkbox` (multi-select)
- Message: "Select which additional service stacks to prepare for Dockge:"
- Choices:
  - [✓] VPN (qBittorrent with VPN)
  - [✓] Media (Jellyfin, Calibre-Web)
  - [✓] Media Management (*arr services, Prowlarr)
  - [✓] Transcoders (Tdarr, Unmanic)
  - [✓] Home Automation (Home Assistant, Node-RED, Zigbee2MQTT)
  - [✓] Productivity (Nextcloud, Gitea, Mealie)
  - [✓] Monitoring (Prometheus, Grafana, Uptime Kuma)
  - [✓] Utilities (Vaultwarden, Backrest, Duplicati)
  - [✓] Wikis (DokuWiki, BookStack, MediaWiki)
  - [ ] Alternatives (Portainer, Authentik, Plex)
- Default: All enabled except Alternatives
- Note: These stacks will be copied to /opt/stacks/ but not started

## Confirmation and Summary

**Question 24: Configuration Review**
- Type: `confirm`
- Message: "Review and confirm the following configuration:\n\n[Display formatted summary of all settings and selected services]\n\nProceed with deployment?"
- Default: true

**Question 25: Deployment Action**
- Type: `select`
- Message: "What would you like to do?"
- Choices:
  - "🚀 Proceed with deployment"
  - "💾 Save configuration to .env and exit (no deployment)"
  - "🔄 Change configuration values"
  - "❌ Exit without saving"
- Default: First option
- Condition: Only show if user declines deployment confirmation in Question 24

**Question 26: Save Location** (Conditional)
- Type: `text`
- Message: "Enter filename to save configuration (leave empty for .env)"
- Default: ".env"
- Validation: Valid filename
- Condition: Only show if user chooses "Save configuration" in Question 25

## Post-Deployment Options

**Auto-Reboot Handling:**
- If AUTO_REBOOT=true and reboot required: Automatically reboot at end
- If AUTO_REBOOT=false and reboot required: Display manual reboot instructions
- If no reboot required: Display success message and access URLs

## One-Step Installation Strategy

**Installation Order (to minimize reboots):**
1. System updates and package installation (no reboot needed)
2. Docker installation and user group addition (may require logout)
3. NVIDIA driver installation (requires reboot)
4. NVIDIA Container Toolkit (no additional reboot)
5. Python dependencies (no reboot)
6. EZ-Homelab deployment (no reboot)

**Reboot Optimization:**
- Detect what requires reboot vs logout vs nothing
- Perform all non-reboot actions first
- Group reboot-requiring actions together
- Use `newgrp docker` or similar to avoid logout for group changes
- Only reboot once at the end if needed

**Logout Avoidance Techniques:**
- Use `sg docker -c "command"` to run commands as docker group member
- Reload systemd without full reboot for some services
- Update environment variables in current session
- Use `exec su -l $USER` to reload user environment

This approach ensures maximum convenience for users while handling all the complex system setup requirements.

This question flow ensures:
- **Logical progression**: Basic setup first, then conditional advanced options
- **Clear validation**: Each question validates input appropriately
- **Conditional logic**: Questions only appear when relevant to the selected deployment type
- **Security**: Passwords are properly masked
- **User experience**: Clear messages and sensible defaults
- **Error prevention**: Validation prevents common configuration mistakes

The TUI would then proceed to perform the actual deployment based on the collected configuration.