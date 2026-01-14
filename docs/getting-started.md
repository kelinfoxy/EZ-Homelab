# Getting Started Guide

Welcome to your AI-powered homelab! This guide will walk you through setting up your production-ready infrastructure with Dockge, Traefik, Authelia, and 40+ services.

## Quick Setup (Recommended)

For most users, the automated setup script handles everything:

### Prerequisites
- **Fresh Debian/Ubuntu server** (or existing system)
- **Root/sudo access**
- **Internet connection**
- **VS Code with GitHub Copilot** (for AI assistance)

### Simple Setup

1. **Connect to your server** via SSH
2. **Install git if needed**
   ```bash
      sudo apt update && sudo apt upgrade -y && sudo apt install git

3. **Clone the rep**:
   ```bash
   git clone https://github.com/kelinfoxy/AI-Homelab.git
   cd AI-Homelab

4. **Configure environment**:
   ```bash
   cp .env.example .env
   nano .env  # Edit with your settings and paste the Authelia secrets
   ```
   
   **Testing considerations: .env File Location**
   - The `.env` file should remain in the **repository folder** (`~/AI-Homelab/.env`)
   - The deploy script will automatically copy it to `/opt/stacks/*/` as needed
   - Always edit the repo copy, not the deployed copies
   - Changes to deployed copies will be overwritten on next deployment
   
   **Required variables in .env:**
   - `DOMAIN` - Your DuckDNS domain (e.g., yourdomain.duckdns.org)
   - `DUCKDNS_TOKEN` - Your DuckDNS token
   - `ACME_EMAIL` - Your email for Let's Encrypt certificates
   - `AUTHELIA_JWT_SECRET` - Generated in step 6
   - `AUTHELIA_SESSION_SECRET` - Generated in step 6
   - `AUTHELIA_STORAGE_ENCRYPTION_KEY` - Generated in step 6
   - `SURFSHARK_USERNAME` and `SURFSHARK_PASSWORD` - If using VPN

5. **Run the setup script**   
    ```bash
      sudo ./scripts/setup-homelab.sh
   
6. **Log out and back in** (or run `newgrp docker`)
   >Don't skip this step!

7. **Generate Authelia Secrets**:
   ```bash
   # Generate three required secrets for Authelia (128 characters each)
   echo "AUTHELIA_JWT_SECRET=$(openssl rand -hex 64)"
   echo "AUTHELIA_SESSION_SECRET=$(openssl rand -hex 64)"
   echo "AUTHELIA_STORAGE_ENCRYPTION_KEY=$(openssl rand -hex 64)"
   
   # Copy these values and add them to your .env file
   ```

8. **Deploy homelab**:
   ```bash
   ./scripts/deploy-homelab.sh
   ```
   
   **The deploy script automatically:**
   - Creates Docker networks
   - Configures Traefik with your email
   - Generates Authelia admin password (saved to `/opt/stacks/core/authelia/ADMIN_PASSWORD.txt`)
   - Deploys core stack (DuckDNS, Traefik, Authelia, Gluetun)
   - Deploys infrastructure stack (Dockge, Pi-hole, monitoring)
   - Deploys dashboards stack (Homepage, Homarr)
   - Opens Dockge in your browser
   
   **Login credentials:**
   - Username: `admin`
   - Password: Check `/opt/stacks/core/authelia/ADMIN_PASSWORD.txt` or see script output

**That's it!** Your homelab is ready. Access Dockge at `https://dockge.yourdomain.duckdns.org`

## What the Setup Script Does

The `setup-homelab.sh` script automatically:
- ✅ Updates system packages
- ✅ Installs Docker (if not present)
- ✅ Configures user permissions
- ✅ Sets up firewall (UFW)
- ✅ Enables SSH server
- ✅ Installs NVIDIA drivers (if GPU detected)
- ✅ Creates directory structure
- ✅ Sets up Docker networks

It safely skips steps that are already completed, so it's safe to run on partially configured systems.

## Manual Setup (Alternative)

If you prefer manual control or the script fails, follow these steps:

### Step 1: System Preparation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git ufw openssh-server

# Enable firewall
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

### Step 2: Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
sudo usermod -aG sudo $USER

# Log out and back in, or run: newgrp docker
```

### Step 3: Clone Repository
```bash
cd ~
git clone https://github.com/kelinfoxy/AI-Homelab.git
cd AI-Homelab
```

### Step 4: Configure Environment
```bash
cp .env.example .env
nano .env  # Edit all required variables
```

### Step 5: Create Infrastructure
```bash
# Create directories
sudo mkdir -p /opt/stacks /mnt/{media,database,downloads,backups}
sudo chown -R $USER:$USER /opt/stacks /mnt

# Create networks
docker network create traefik-network
docker network create homelab-network
docker network create media-network
```

### Step 6: Deploy Services
```bash
# Deploy core infrastructure
sudo mkdir -p /opt/stacks/core
cp docker-compose/core.yml /opt/stacks/core/
cp -r config-templates/traefik /opt/stacks/core/
cp -r config-templates/authelia /opt/stacks/core/
cp .env /opt/stacks/core/
cd /opt/stacks/core
docker compose up -d

# Deploy infrastructure stack
sudo mkdir -p /opt/stacks/infrastructure
cp ../docker-compose/infrastructure.yml /opt/stacks/infrastructure/
cp ../.env /opt/stacks/infrastructure/
cd /opt/stacks/infrastructure
docker compose up -d
```

## Post-Setup Configuration

### Access Your Services
- **Dockge**: `https://dockge.yourdomain.duckdns.org`
- **Authelia**: `https://auth.yourdomain.duckdns.org`
- **Traefik**: `https://traefik.yourdomain.duckdns.org`

### Configure Authelia
1. Access `https://auth.yourdomain.duckdns.org`
2. Set up your admin user
3. Configure 2FA for security

### Deploy Additional Stacks
Use Dockge to deploy stacks like:
- `dashboards.yml` - Homepage and Homarr
- `media.yml` - Plex, Jellyfin, Sonarr, Radarr
- `productivity.yml` - Nextcloud, Gitea, wikis

### Set Up Homepage Widgets
1. Access Homepage dashboard
2. Get API keys from services
3. Configure widgets in `/opt/stacks/dashboards/homepage/config/`

## VS Code Integration

1. Install VS Code and GitHub Copilot
2. Open the AI-Homelab repository
3. Use AI assistance for:
   - Adding new services
   - Configuring Traefik routing
   - Managing Docker stacks

## Troubleshooting

### Script Issues
- **Permission denied**: Run with `sudo`
- **Docker not found**: Log out/in or run `newgrp docker`
- **Network conflicts**: Check existing networks with `docker network ls`

### Service Issues
- **Can't access services**: Check Traefik dashboard at `https://traefik.yourdomain.duckdns.org`
- **SSL certificate errors**: Wait 2-5 minutes for wildcard certificate to be obtained from Let's Encrypt
  - Check status: `python3 -c "import json; d=json.load(open('/opt/stacks/core/traefik/acme.json')); print(f'Certificates: {len(d[\"letsencrypt\"][\"Certificates\"])}')"`
  - View logs: `docker exec traefik tail -50 /var/log/traefik/traefik.log | grep certificate`
- **Authelia login fails**: Check user database configuration at `/opt/stacks/core/authelia/users_database.yml`
- **"Not secure" warnings**: Clear browser cache or wait for DNS propagation (up to 5 minutes)

### Common Fixes
```bash
# Restart Docker
sudo systemctl restart docker

# Check service logs
cd /opt/stacks/stack-name
docker compose logs -f

# Rebuild service
docker compose up -d --build service-name
```

## Getting Started Checklist

- [ ] Run setup script or manual setup
- [ ] Configure `.env` file
- [ ] Deploy core infrastructure
- [ ] Access Dockge web UI
- [ ] Set up Authelia authentication
- [ ] Deploy additional stacks as needed
- [ ] Configure Homepage dashboard
- [ ] Install VS Code with Copilot

## Next Steps

1. **Explore services** through Dockge
2. **Configure backups** with Backrest/Duplicati
3. **Set up monitoring** with Grafana/Prometheus
4. **Add external services** via Traefik proxying
5. **Use AI assistance** for custom configurations

Happy homelabbing! 🚀

## Deployment Improvements (Round 4)

The repository has been enhanced with the following improvements for better user experience:

### Automated Configuration
- **Email Substitution**: Deploy script automatically configures Traefik with your ACME_EMAIL
- **Password Generation**: Authelia admin password is auto-generated and saved to `/opt/stacks/core/authelia/ADMIN_PASSWORD.txt`
- **Network Creation**: Docker networks are created automatically before deployment

### Volume Path Standardization
- All compose files now use **relative paths** (e.g., `./service/config`) for portability
- Stacks work correctly when deployed via Dockge or docker compose
- Large shared data still uses absolute paths (`/mnt/media`, `/mnt/downloads`)

### SSL Certificate Configuration
- **Default**: HTTP challenge (simple setup, works immediately)
- **Optional**: DNS challenge for wildcard certificates (see comments in traefik.yml)
- Certificates are automatically requested and renewed by Traefik

### What's Automated
✅ Docker network creation  
✅ Traefik email configuration  
✅ Authelia password generation  
✅ Domain configuration in Authelia  
✅ Directory structure creation  
✅ Service deployment  

### What You Configure
📝 `.env` file with your domain and API keys  
📝 DuckDNS token  
📝 VPN credentials (if using Gluetun)  
📝 Service-specific settings via Dockge  
