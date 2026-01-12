# AI-Homelab Setup Scripts

This directory contains two scripts for automated AI-Homelab deployment:

1. **setup-homelab.sh** - System preparation (optional, for fresh installations)
2. **deploy-homelab.sh** - Core infrastructure deployment

## setup-homelab.sh

Automated first-run setup script for preparing a fresh Debian installation for AI-Homelab deployment. **This is optional** - skip if Docker is already installed and configured.

### What It Does

1. **System Update** - Updates all system packages
2. **Install Dependencies** - Installs required packages (curl, git, etc.)
3. **Install Docker** - Adds Docker repository and installs Docker Engine with Compose V2
4. **Configure User Groups** - Adds user to sudo and docker groups
5. **Configure SSH** - Enables and starts SSH server for remote access
6. **Detect NVIDIA GPU** - Checks for NVIDIA graphics card and provides manual driver installation instructions
7. **Create Directories** - Sets up `/opt/stacks`, `/opt/dockge`, `/mnt/media`, `/mnt/downloads`
8. **Create Docker Networks** - Creates homelab-network, traefik-network, and media-network

### Usage

```bash
# Download the repository
git clone https://github.com/kelinfoxy/AI-Homelab.git
cd AI-Homelab

# Make the script executable (if needed)
chmod +x scripts/setup-homelab.sh

# Run with sudo
sudo ./scripts/setup-homelab.sh
```

### After Running

1. Log out and log back in for group changes to take effect
2. Edit `.env` file with your configuration
3. Run `deploy-homelab.sh` to deploy core infrastructure and Dockge

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

- Fresh Debian installation (Debian 11 or 12)
- Root access (via sudo)
- Internet connection

### Tested On

- Debian 11 (Bullseye)
- Debian 12 (Bookworm)

### Notes

- The script is idempotent - safe to run multiple times
- Creates directories with proper ownership
- Configures Docker networks automatically
- SSH is enabled for remote management
- NVIDIA driver installation requires manual intervention for reliability

---

## deploy-homelab.sh

Automated deployment script that deploys the core infrastructure and Dockge. Run this after editing your `.env` file.

### What It Does

1. **Validate Prerequisites** - Checks for Docker, .env file, and proper configuration
2. **Create Directories** - Sets up `/opt/stacks/core` and `/opt/stacks/infrastructure`
3. **Create Docker Networks** - Ensures homelab-network, traefik-network, and media-network exist
4. **Deploy Core Stack** - Deploys DuckDNS, Traefik, Authelia, and Gluetun
5. **Deploy Infrastructure Stack** - Deploys Dockge, Portainer, Pi-hole, and monitoring tools
6. **Wait for Dockge** - Waits for Dockge web UI to become accessible
7. **Open Browser** - Automatically opens Dockge in your default browser

### Usage

```bash
# From the AI-Homelab directory
cd AI-Homelab

# Ensure .env is configured
cp .env.example .env
nano .env  # Edit with your values

# Make the script executable (if needed)
chmod +x scripts/deploy-homelab.sh

# Run WITHOUT sudo (run as your regular user)
./scripts/deploy-homelab.sh
```

### After Running

The script will automatically open `https://dockge.yourdomain.duckdns.org` in your browser when Dockge is ready.

1. Log in to Dockge using your Authelia credentials (configured in `/opt/stacks/core/authelia/users_database.yml`)
2. Deploy additional stacks through Dockge's web UI:
   - `dashboards.yml` - Homepage and Homarr
   - `media.yml` - Plex, Jellyfin, Sonarr, Radarr, etc.
   - `media-extended.yml` - Readarr, Lidarr, etc.
   - `homeassistant.yml` - Home Assistant and accessories
   - `productivity.yml` - Nextcloud, Gitea, wikis
   - `monitoring.yml` - Grafana, Prometheus
   - `utilities.yml` - Backups, password manager

### Requirements

- Docker and Docker Compose installed
- `.env` file configured with your domain and credentials
- User must be in docker group (handled by setup-homelab.sh)

### Browser Detection

The script will attempt to open Dockge using:
- `xdg-open` (default on most Linux desktops)
- `gnome-open` (GNOME desktop)
- `firefox` or `google-chrome` (direct browser launch)

If no browser is detected, it will display the URL for manual access.

### Manual Deployment Alternative

If you prefer to deploy manually instead of using the script:

```bash
# Deploy core stack
mkdir -p /opt/stacks/core
cp docker-compose/core.yml /opt/stacks/core/docker-compose.yml
cp -r config-templates/traefik /opt/stacks/core/
cp -r config-templates/authelia /opt/stacks/core/
cp .env /opt/stacks/core/
cd /opt/stacks/core && docker compose up -d

# Deploy infrastructure stack
mkdir -p /opt/stacks/infrastructure
cp docker-compose/infrastructure.yml /opt/stacks/infrastructure/docker-compose.yml
cp .env /opt/stacks/infrastructure/
cd /opt/stacks/infrastructure && docker compose up -d

# Manually open: https://dockge.yourdomain.duckdns.org
```

### Troubleshooting

**Script says "Docker daemon is not running":**
- Run: `sudo systemctl start docker`
- Or log out and back in if you just added yourself to docker group

**Script says ".env file not found":**
- Run: `cp .env.example .env` and edit with your values

**Dockge doesn't open automatically:**
- The script will display the URL to open manually
- Wait a minute for services to fully start
- Check logs: `docker compose -f /opt/stacks/infrastructure/docker-compose.yml logs dockge`

**Traefik SSL certificate errors:**
- Initial certificate generation can take a few minutes
- Check DuckDNS token is correct in .env
- Verify your domain is accessible from the internet

### Notes

- Run as regular user (NOT with sudo)
- Validates .env configuration before deployment
- Waits up to 60 seconds for Dockge to become ready
- Automatically copies .env to stack directories
- Safe to run multiple times (idempotent)
