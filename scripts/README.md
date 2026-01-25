# EZ-Homelab Setup Scripts

This directory contains scripts for automated EZ-Homelab deployment and management:

1. **ez-homelab.sh** - Unified setup and deployment script
2. **reset-test-environment.sh** - Safe test environment cleanup
3. **reset-ondemand-services.sh** - Reload services for Sablier lazy loading

## ez-homelab.sh

Unified guided setup and deployment script that handles both system preparation and service deployment in a single interactive session.

### What It Does

**System Preparation (when needed):**
1. **System Update** - Updates all system packages
2. **Install Dependencies** - Installs required packages (curl, git, etc.)
3. **Install Docker** - Adds Docker repository and installs Docker Engine with Compose V2
4. **Configure User Groups** - Adds user to sudo and docker groups
5. **Configure SSH** - Enables and starts SSH server for remote access
6. **Detect NVIDIA GPU** - Checks for NVIDIA graphics card and provides manual driver installation instructions
7. **Create Directories** - Sets up `/opt/stacks`, `/opt/dockge`, `/mnt/media`, `/mnt/downloads`
8. **Create Docker Networks** - Creates homelab-network, traefik-network, and media-network

**Configuration & Deployment:**
1. **Interactive Setup** - Guides you through domain, admin credentials, and service selection
2. **Authelia Secrets Generation** - Generates JWT, session, and encryption keys
3. **Admin User Creation** - Prompts for admin username, email, and password
4. **Service Deployment** - Deploys selected stacks based on your choices
5. **SSL Certificate Setup** - Obtains wildcard certificate via DNS challenge
6. **Dockge Access** - Opens Dockge web UI when ready

### Usage

```bash
cd ~/EZ-Homelab

# Make the script executable (if needed)
chmod +x scripts/ez-homelab.sh

# Run the script (will use sudo when needed)
./scripts/ez-homelab.sh
```

### Interactive Options

The script will prompt you to:
- Enter your domain (e.g., yourdomain.duckdns.org)
- Provide DuckDNS token
- Set admin credentials for Authelia
- Choose which service stacks to deploy
- Configure additional settings as needed

### After Running

1. Access Dockge at `https://dockge.yourdomain.duckdns.org`
2. Log in with your configured Authelia credentials
3. Deploy additional stacks through Dockge's web UI

### NVIDIA GPU Support

If an NVIDIA GPU is detected, the script will provide instructions for manual driver installation:

1. Identify your GPU model from the output
2. Visit https://www.nvidia.com/Download/index.aspx
3. Download the official driver for your GPU
4. Run the installer: `sudo bash NVIDIA-Linux-x86_64-XXX.XX.run`
5. Install container toolkit:
   ```bash
   sudo apt-get install -y nvidia-container-toolkit
   sudo nvidia-ctk runtime configure --runtime=docker
   sudo systemctl restart docker
   ```

This manual approach avoids driver conflicts that often occur with automated installation methods.

### Requirements

- Fresh Debian/Ubuntu installation (or existing system)
- Root access (via sudo)
- Internet connection
- Ports 80 and 443 forwarded to your server

### Tested On

- Debian 11 (Bullseye)
- Debian 12 (Bookworm)
- Ubuntu 20.04/22.04

### Notes

- The script is idempotent - safe to run multiple times
- Creates directories with proper ownership
- Configures Docker networks automatically
- SSH is enabled for remote management
- NVIDIA driver installation requires manual intervention for reliability

---

## reset-test-environment.sh

Safe cleanup script for testing environments. Completely removes all deployed services, data, and configurations while preserving the underlying system setup. Intended for development and testing scenarios only.

### What It Does

1. **Stop All Stacks** - Gracefully stops dashboards, infrastructure, and core stacks
2. **Preserve SSL Certificates** - Backs up `acme.json` to the repository folder for reuse
3. **Remove Docker Volumes** - Deletes all homelab-related named volumes (data will be lost)
4. **Clean Stack Directories** - Removes `/opt/stacks/core`, `/opt/stacks/infrastructure`, `/opt/stacks/dashboards`
5. **Clear Dockge Data** - Removes Dockge's persistent data directory
6. **Clean Temporary Files** - Removes temporary files and setup artifacts
7. **Remove Networks** - Deletes homelab-network, traefik-network, dockerproxy-network, media-network
8. **Prune Resources** - Runs Docker system prune to clean up unused resources

### Usage

```bash
cd ~/AI-Homelab

# Make the script executable (if needed)
chmod +x scripts/reset-test-environment.sh

# Run with sudo (required for system cleanup)
sudo ./scripts/reset-test-environment.sh
```

### Safety Features

- **Confirmation Required** - Must type "yes" to confirm reset
- **Root Check** - Ensures running with sudo but not as root user
- **Colored Output** - Clear visual feedback for each step
- **Error Handling** - Continues with warnings if some operations fail
- **Preserves System** - Docker, packages, user groups, and firewall settings remain intact

### After Running

The system will be returned to a clean state ready for re-deployment:

1. Ensure `.env` file is properly configured
2. Run: `./scripts/ez-homelab.sh`

### Requirements

- Docker and Docker Compose installed
- Root access (via sudo)
- Existing AI-Homelab deployment

### Warnings

- **DATA LOSS** - All application data, databases, and configurations will be permanently deleted
- **SSL Certificates** - Preserved in repository folder but must be manually restored if needed
- **Production Use** - This script is for testing only - DO NOT use in production environments

### Notes

- Preserves Docker installation and system packages
- Maintains user group memberships and firewall rules
- SSL certificates are backed up to `~/AI-Homelab/acme.json`
- Safe to run multiple times
- Provides clear next steps after completion

---

## reset-ondemand-services.sh

Service management script for Sablier lazy loading. Restarts stacks to reload configuration changes and stops web services so Sablier can control them on-demand, while keeping databases running.

### What It Does

1. **Restart Stacks** - Brings down and back up various service stacks to reload compose file changes
2. **Stop Web Services** - Stops containers with `sablier.enable=true` label so Sablier can start them on-demand
3. **Preserve Databases** - Leaves database containers running for data persistence

### Supported Stacks

The script manages the following stacks:
- arr-stack (Sonarr, Radarr, Prowlarr)
- backrest (backup management)
- bitwarden (password manager)
- bookstack (documentation)
- code-server (VS Code server)
- dokuwiki (wiki)
- dozzle (log viewer)
- duplicati (alternative backup)
- formio (form builder)
- gitea (git server)
- glances (system monitor)
- mealie (recipe manager)
- mediawiki (wiki)
- nextcloud (cloud storage)
- tdarr (media processing)
- unmanic (media optimization)
- wordpress (blog/CMS)

### Usage

```bash
cd ~/AI-Homelab

# Make the script executable (if needed)
chmod +x scripts/reset-ondemand-services.sh

# Run as regular user (docker group membership required)
./scripts/reset-ondemand-services.sh
```

### When to Use

- After modifying compose files for Sablier lazy loading configuration
- When services need to reload configuration changes
- To ensure Sablier has control over web service startup
- During initial setup of lazy loading for multiple services

### Requirements

- Docker and Docker Compose installed
- User must be in docker group
- Sablier must be running in core stack
- Service stacks must be deployed

### Notes

- Handles different compose file naming conventions (.yml vs .yaml)
- Stops only services with Sablier labels enabled
- Databases remain running to preserve data
- Safe to run multiple times
- Provides clear feedback on operations performed
