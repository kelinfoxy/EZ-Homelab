# Getting Started Guide

This guide will walk you through setting up your AI-powered homelab with Dockge, Traefik, Authelia, and 40+ services from scratch.

## Prerequisites

Before you begin, ensure you have:

- [ ] A Linux server (Ubuntu 22.04+ recommended)
- [ ] Docker Engine 24.0+ installed
- [ ] Docker Compose V2 installed
- [ ] Git installed
- [ ] At least 8GB RAM (16GB+ recommended)
- [ ] Sufficient disk space: 120GB+ system drive (NVMe or SSD highly recommended), 2TB+ for media & additional disks for services like Nextcloud that require lots of space
- [ ] Static IP address for your server (or DHCP reservation)
- [ ] DuckDNS account (free) with a domain
- [ ] Surfshark VPN account (optional, for VPN features)
- [ ] VS Code with GitHub Copilot extension (for AI assistance)

## Step 1: Verify Docker Installation

```bash
# Check Docker version
docker --version
# Should show: Docker version 24.0.0 or higher

# Check Docker Compose version
docker compose version
# Should show: Docker Compose version v2.x.x

# Test Docker works
docker run --rm hello-world
# Should download and run successfully
```

## Step 2: Clone the Repository

```bash
# Navigate to your home directory
cd ~

# Clone the repository
# Note: Replace 'kelinfoxy' with your username if you forked this repository
git clone https://github.com/kelinfoxy/AI-Homelab.git

# Enter the directory
cd AI-Homelab
```

## Step 3: Sign Up for DuckDNS

1. Go to https://www.duckdns.org/
2. Sign in with your preferred method
3. Create a domain (e.g., `myhomelab`)
4. Copy your token - you'll need it for `.env`
5. Your domain will be: `myhomelab.duckdns.org`

## Step 4: Configure Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Get your user and group IDs
id -u  # This is your PUID
id -g  # This is your PGID

# Edit the .env file
nano .env
```

**Critical values to update in `.env`:**
```bash
# Your user/group IDs
PUID=1000           # Replace with your user ID
PGID=1000           # Replace with your group ID

# Your timezone (find yours: timedatectl list-timezones)
TZ=America/New_York

# Your server's IP address
SERVER_IP=192.168.1.100  # Replace with your actual IP

# DuckDNS Configuration
DOMAIN=myhomelab.duckdns.org  # Your DuckDNS domain
DUCKDNS_TOKEN=your-duckdns-token-here
DUCKDNS_SUBDOMAINS=myhomelab  # Without .duckdns.org

# Let's Encrypt Email
ACME_EMAIL=your-email@example.com

# Authelia Secrets (generate with: openssl rand -hex 64)
AUTHELIA_JWT_SECRET=$(openssl rand -hex 64)
AUTHELIA_SESSION_SECRET=$(openssl rand -hex 64)
AUTHELIA_STORAGE_ENCRYPTION_KEY=$(openssl rand -hex 64)

# Surfshark VPN (if using)
SURFSHARK_PRIVATE_KEY=your-wireguard-private-key
SURFSHARK_ADDRESSES=10.14.0.2/16

# Set secure passwords for all services
PIHOLE_PASSWORD=your-secure-password
GRAFANA_ADMIN_PASSWORD=your-secure-password
CODE_SERVER_PASSWORD=your-secure-password
# ... (see .env.example for complete list)
```

**Save and exit** (Ctrl+X, Y, Enter in nano)

## Step 5: Create Dockge Directory Structure

```bash
# Create main stacks directory
sudo mkdir -p /opt/stacks
sudo chown -R $USER:$USER /opt/stacks

# Create mount points for large data (adjust as needed)
sudo mkdir -p /mnt/media/{movies,tv,music,books,photos}
sudo mkdir -p /mnt/downloads/{complete,incomplete}
sudo mkdir -p /mnt/backups
sudo chown -R $USER:$USER /mnt/media /mnt/downloads /mnt/backups
```

## Step 6: Create Docker Networks

```bash
# Create required external networks
docker network create traefik-network
docker network create homelab-network
docker network create media-network
docker network create dockerproxy-network

# Verify networks were created
docker network ls | grep -E "traefik|homelab|media|dockerproxy"
```

## Step 7: Deploy Core Infrastructure Stack

The **core** stack contains all essential services that must be deployed first: DuckDNS, Traefik, Authelia, and Gluetun.

```bash
# Create core stack directory
mkdir -p /opt/stacks/core/{duckdns,traefik/dynamic,authelia,gluetun}

# Copy the core compose file
cp ~/AI-Homelab/docker-compose/core.yml /opt/stacks/core/docker-compose.yml

# Copy configuration templates
cp ~/AI-Homelab/config-templates/traefik/traefik.yml /opt/stacks/core/traefik/
cp ~/AI-Homelab/config-templates/traefik/dynamic/*.yml /opt/stacks/core/traefik/dynamic/
cp ~/AI-Homelab/config-templates/authelia/*.yml /opt/stacks/core/authelia/

# Create acme.json for SSL certificates
touch /opt/stacks/core/traefik/acme.json
chmod 600 /opt/stacks/core/traefik/acme.json

# Generate password hash for Authelia user
docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password 'yourpassword'
# Copy the output hash

# Edit users_database.yml with your username and password hash
cd /opt/stacks/core/authelia
nano users_database.yml
# Replace the password hash with your generated one
# Example:
# users:
#   admin:
#     displayname: "Admin User"
#     password: "$argon2id$v=19$m=65536..." # Your generated hash
#     email: admin@example.com
#     groups:
#       - admins

# Copy .env file to core stack
cp ~/AI-Homelab/.env /opt/stacks/core/.env

# Deploy the entire core stack - use either method:
# Method 1: From within directory
cd /opt/stacks/core
docker compose up -d

# Method 2: From anywhere with full path
docker compose -f /opt/stacks/core/docker-compose.yml up -d

# Check logs to ensure everything is running
docker compose logs -f

# You should see:
# - DuckDNS updating your IP
# - Traefik starting and acquiring SSL certificates
# - Authelia initializing
# - Gluetun connecting to VPN
```

**Verify Core Services:**
- Traefik dashboard: `https://traefik.yourdomain.duckdns.org` (login with Authelia)
- Authelia login: `https://auth.yourdomain.duckdns.org`
- All services should have valid SSL certificates

**Troubleshooting:**
- If Traefik can't get certificates, check DuckDNS is updating your IP
- If Authelia won't start, check your password hash and configuration.yml
- If Gluetun fails, verify your Surfshark credentials in .env

## Step 8: Deploy Infrastructure Services (Dockge)

```bash
# Create stack directory
mkdir -p /opt/stacks/infrastructure

# Copy compose file
cp ~/AI-Homelab/docker-compose/infrastructure.yml /opt/stacks/infrastructure/docker-compose.yml

# Create necessary subdirectories
mkdir -p /opt/dockge/data
mkdir -p /opt/stacks/pihole/{etc-pihole,etc-dnsmasq.d}
mkdir -p /opt/stacks/glances/config

# Copy .env
cp ~/AI-Homelab/.env /opt/stacks/infrastructure/.env

# Deploy Dockge first
cd /opt/stacks/infrastructure
docker compose up -d dockge

# Access Dockge at https://dockge.yourdomain.duckdns.org (login with Authelia)

# Deploy remaining infrastructure services
docker compose up -d
```

## Step 9: Deploy Dashboards (Homepage & Homarr)

```bash
# Create stack directory
mkdir -p /opt/stacks/dashboards/{homepage,homarr}

# Copy compose file
cp ~/AI-Homelab/docker-compose/dashboards.yml /opt/stacks/dashboards/docker-compose.yml

# Copy Homepage configuration templates
cp ~/AI-Homelab/config-templates/homepage/* /opt/stacks/dashboards/homepage/

# Copy .env
cp ~/AI-Homelab/.env /opt/stacks/dashboards/.env

# Deploy
cd /opt/stacks/dashboards
docker compose up -d

# Access Homepage at https://home.yourdomain.duckdns.org (login with Authelia)
# Access Homarr at https://homarr.yourdomain.duckdns.org (login with Authelia)
```

## Step 10: Deploy Additional Stacks

Now use Dockge UI at `https://dockge.yourdomain.duckdns.org` to deploy additional stacks, or continue with command line:

### 8.1 Gluetun + qBittorrent (VPN)

```bash
mkdir -p /opt/stacks/gluetun
cp ~/AI-Homelab/docker-compose/gluetun.yml /opt/stacks/gluetun/docker-compose.yml
cp ~/AI-Homelab/.env /opt/stacks/gluetun/.env

cd /opt/stacks/gluetun
docker compose up -d

# Test VPN
docker exec gluetun curl ifconfig.me
# Should show VPN IP
```

### 8.2 Homepage Dashboard

```bash
mkdir -p /opt/stacks/homepage/config
cp ~/AI-Homelab/docker-compose/dashboards.yml /opt/stacks/homepage/docker-compose.yml
cp ~/AI-Homelab/config-templates/homepage/* /opt/stacks/homepage/config/
cp ~/AI-Homelab/.env /opt/stacks/homepage/.env

cd /opt/stacks/homepage
docker compose up -d homepage

# Access at https://home.yourdomain.duckdns.org
```

### 8.3 Media Stack

```bash
mkdir -p /opt/stacks/media
cp ~/AI-Homelab/docker-compose/media.yml /opt/stacks/media/docker-compose.yml
cp ~/AI-Homelab/.env /opt/stacks/media/.env

cd /opt/stacks/media
docker compose up -d
```

### 8.4 Additional Stacks

Deploy as needed:
- `media-extended.yml` → `/opt/stacks/media-extended/`
- `homeassistant.yml` → `/opt/stacks/homeassistant/`
- `productivity.yml` → `/opt/stacks/productivity/`
- `utilities.yml` → `/opt/stacks/utilities/`
- `monitoring.yml` → `/opt/stacks/monitoring/`
- `development.yml` → `/opt/stacks/development/`

## Step 9: Configure Homepage Widgets

Get API keys from each service and add to Homepage config:

```bash
cd /opt/stacks/homepage/config
nano services.yaml

# Get API keys:
# - Sonarr/Radarr/etc: Settings → General → API Key
# - Plex: https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/
# - Jellyfin: Dashboard → API Keys

# Add to .env:
nano /opt/stacks/homepage/.env
# HOMEPAGE_VAR_SONARR_KEY=...
# HOMEPAGE_VAR_RADARR_KEY=...
# etc.

# Restart Homepage
cd /opt/stacks/homepage
docker compose restart
```

## Step 10: Install VS Code and GitHub Copilot

```bash
# Install VS Code (if not already installed)
# Download from https://code.visualstudio.com/

# Install GitHub Copilot extension
# In VS Code: Extensions → Search "GitHub Copilot" → Install

# Open the repository
code ~/AI-Homelab

# Start using AI assistance!
```

## Next Steps

1. Explore Dockge at `https://dockge.yourdomain.duckdns.org`
2. Check Homepage dashboard at `https://home.yourdomain.duckdns.org`
3. Configure services through their web UIs
4. Set up Authelia users in `/opt/stacks/authelia/users_database.yml`
5. Configure Homepage widgets with API keys
6. Use VS Code with Copilot to ask questions and make changes
7. Review [proxying-external-hosts.md](proxying-external-hosts.md) to proxy your Raspberry Pi

## Troubleshooting

### Can't access services via HTTPS

Check Traefik logs:
```bash
cd /opt/stacks/traefik
docker compose logs -f
```

Verify DNS is resolving:
```bash
nslookup dockge.yourdomain.duckdns.org
```

Check certificate generation:
```bash
docker exec traefik cat /acme.json
```

### Authelia login not working

Check Authelia logs:
```bash
cd /opt/stacks/authelia
docker compose logs -f
```

Verify password hash in `users_database.yml`

### Service not accessible

1. Check Traefik dashboard: `https://traefik.yourdomain.duckdns.org`
2. Verify service has correct Traefik labels
3. Check service is on `traefik-network`
4. Review service logs

### Port forwarding

Ensure your router forwards ports 80 and 443 to your server IP.

## Security Checklist

- [ ] All passwords in `.env` are strong and unique
- [ ] Authelia 2FA is enabled for admin accounts
- [ ] `.env` file permissions are 600 (`chmod 600 .env`)
- [ ] acme.json permissions are 600
- [ ] Firewall is configured (only 80, 443 open to internet)
- [ ] Pi-hole is configured as your DNS server
- [ ] Watchtower is monitoring for updates
- [ ] Backrest/Duplicati configured for backups

## Congratulations!

Your AI-powered homelab is now running with:
- ✅ Automatic HTTPS via Traefik + Let's Encrypt
- ✅ SSO protection via Authelia
- ✅ 40+ services ready to deploy
- ✅ Dashboard with service widgets
- ✅ AI assistance via GitHub Copilot
- ✅ Centralized management via Dockge

Continue exploring with VS Code and Copilot to add more services, customize configurations, and proxy external devices!
