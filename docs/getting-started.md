# Getting Started Guide

This guide will walk you through setting up your AI-powered homelab from scratch.

## Prerequisites

Before you begin, ensure you have:

- [ ] A Linux server (Ubuntu 22.04+ recommended)
- [ ] Docker Engine 24.0+ installed
- [ ] Docker Compose V2 installed
- [ ] Git installed
- [ ] At least 8GB RAM (16GB+ recommended)
- [ ] Sufficient disk space (100GB+ recommended)
- [ ] Static IP address for your server
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
git clone https://github.com/kelinfoxy/AI-Homelab.git

# Enter the directory
cd AI-Homelab
```

## Step 3: Configure Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Get your user and group IDs
id -u  # This is your PUID
id -g  # This is your PGID

# Edit the .env file
nano .env
```

**Update these values in `.env`:**
```bash
# Your user/group IDs
PUID=1000           # Replace with your user ID
PGID=1000           # Replace with your group ID

# Your timezone (find yours: timedatectl list-timezones)
TZ=America/New_York

# Your server's IP address
SERVER_IP=192.168.1.100  # Replace with your actual IP

# Directory paths
USERDIR=/home/yourusername/homelab  # Update username
MEDIADIR=/mnt/media                 # Update if different
DOWNLOADDIR=/mnt/downloads          # Update if different

# Set secure passwords for services
GRAFANA_ADMIN_PASSWORD=your-secure-password-here
CODE_SERVER_PASSWORD=your-secure-password-here
POSTGRES_PASSWORD=your-secure-password-here
PGADMIN_PASSWORD=your-secure-password-here
JUPYTER_TOKEN=your-secure-token-here
PIHOLE_PASSWORD=your-secure-password-here
```

**Save and exit** (Ctrl+X, Y, Enter in nano)

## Step 4: Create Docker Networks

```bash
# Create the main homelab network
docker network create homelab-network

# Create additional networks for better security
docker network create media-network
docker network create monitoring-network
docker network create database-network

# Verify networks were created
docker network ls
```

## Step 5: Create Configuration Directories

```bash
# Create the main config directory
mkdir -p config

# Create config directories for services you plan to use
mkdir -p config/{nginx-proxy-manager,pihole,portainer}
mkdir -p config/{plex,sonarr,radarr,prowlarr,qbittorrent,jellyfin}
mkdir -p config/{prometheus,grafana,loki,promtail}
mkdir -p config/{code-server,postgres,redis}

# Set proper permissions
sudo chown -R $(id -u):$(id -g) config/
```

## Step 6: Copy Configuration Templates (Optional)

For services that need config files:

```bash
# Prometheus
mkdir -p config/prometheus
cp config-templates/prometheus/prometheus.yml config/prometheus/

# Loki
mkdir -p config/loki
cp config-templates/loki/loki-config.yml config/loki/

# Promtail
mkdir -p config/promtail
cp config-templates/promtail/promtail-config.yml config/promtail/

# Redis
mkdir -p config/redis
cp config-templates/redis/redis.conf config/redis/
```

## Step 7: Start Your First Service (Portainer)

Portainer provides a web UI for managing Docker containers. It's a great first service to deploy.

```bash
# Start Portainer
docker compose -f docker-compose/infrastructure.yml up -d portainer

# Check if it's running
docker compose -f docker-compose/infrastructure.yml ps

# View logs
docker compose -f docker-compose/infrastructure.yml logs -f portainer
```

**Access Portainer:**
1. Open your browser
2. Navigate to `http://YOUR_SERVER_IP:9000`
3. Create an admin account on first login
4. Select "Get Started" and choose local Docker environment

## Step 8: Deploy Infrastructure Services

```bash
# Start all infrastructure services
docker compose -f docker-compose/infrastructure.yml up -d

# Check status
docker compose -f docker-compose/infrastructure.yml ps

# Services now running:
# - Nginx Proxy Manager: http://YOUR_SERVER_IP:81
# - Pi-hole: http://YOUR_SERVER_IP:8080/admin
# - Portainer: http://YOUR_SERVER_IP:9000
# - Watchtower: (runs in background, no UI)
```

### Configure Nginx Proxy Manager (Optional)

1. Access: `http://YOUR_SERVER_IP:81`
2. Login with default credentials:
   - Email: `admin@example.com`
   - Password: `changeme`
3. Change password immediately
4. Add proxy hosts for your services

### Configure Pi-hole (Optional)

1. Access: `http://YOUR_SERVER_IP:8080/admin`
2. Login with password from `.env` (PIHOLE_PASSWORD)
3. Configure DNS settings
4. Update your router to use Pi-hole as DNS server

## Step 9: Deploy Media Services (Optional)

If you want a media server setup:

```bash
# Start media services
docker compose -f docker-compose/media.yml up -d

# Check status
docker compose -f docker-compose/media.yml ps

# Services now running:
# - Plex: http://YOUR_SERVER_IP:32400/web
# - Jellyfin: http://YOUR_SERVER_IP:8096
# - Sonarr: http://YOUR_SERVER_IP:8989
# - Radarr: http://YOUR_SERVER_IP:7878
# - Prowlarr: http://YOUR_SERVER_IP:9696
# - qBittorrent: http://YOUR_SERVER_IP:8081
```

### Initial Media Service Setup

**Plex:**
1. Access: `http://YOUR_SERVER_IP:32400/web`
2. Sign in with your Plex account
3. Add your media libraries

**Sonarr/Radarr:**
1. Access the web UI
2. Go to Settings → Profiles → Quality
3. Configure your quality preferences
4. Add Prowlarr as an indexer
5. Add qBittorrent as a download client

## Step 10: Deploy Monitoring Services (Optional)

For system and service monitoring:

```bash
# Start monitoring services
docker compose -f docker-compose/monitoring.yml up -d

# Check status
docker compose -f docker-compose/monitoring.yml ps

# Services now running:
# - Prometheus: http://YOUR_SERVER_IP:9090
# - Grafana: http://YOUR_SERVER_IP:3000
# - Node Exporter: http://YOUR_SERVER_IP:9100
# - cAdvisor: http://YOUR_SERVER_IP:8082
# - Uptime Kuma: http://YOUR_SERVER_IP:3001
```

### Configure Grafana

1. Access: `http://YOUR_SERVER_IP:3000`
2. Login with credentials from `.env`:
   - Username: `admin`
   - Password: `GRAFANA_ADMIN_PASSWORD` from .env
3. Add Prometheus as a data source:
   - URL: `http://prometheus:9090`
4. Import dashboards:
   - Dashboard ID 1860 for Node Exporter
   - Dashboard ID 893 for Docker metrics

### Configure Uptime Kuma

1. Access: `http://YOUR_SERVER_IP:3001`
2. Create an account on first login
3. Add monitors for your services

## Step 11: Deploy Development Services (Optional)

If you need development tools:

```bash
# Start development services
docker compose -f docker-compose/development.yml up -d

# Check status
docker compose -f docker-compose/development.yml ps

# Services now running:
# - Code Server: http://YOUR_SERVER_IP:8443
# - PostgreSQL: localhost:5432
# - Redis: localhost:6379
# - pgAdmin: http://YOUR_SERVER_IP:5050
# - Jupyter Lab: http://YOUR_SERVER_IP:8888
# - Node-RED: http://YOUR_SERVER_IP:1880
```

## Step 12: Set Up VS Code with GitHub Copilot

1. **Install VS Code** on your local machine (if not already installed)

2. **Install GitHub Copilot extension:**
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "GitHub Copilot"
   - Click Install
   - Sign in with your GitHub account

3. **Clone your repository in VS Code:**
   ```bash
   # On your local machine
   git clone https://github.com/kelinfoxy/AI-Homelab.git
   cd AI-Homelab
   code .
   ```

4. **Start using AI assistance:**
   - Open Copilot Chat (Ctrl+Shift+I or click the chat icon)
   - The AI assistant automatically follows the guidelines in `.github/copilot-instructions.md`
   - Ask questions like:
     - "Help me add Home Assistant to my homelab"
     - "Create a backup script for my Docker volumes"
     - "How do I configure GPU support for Plex?"

## Step 13: Verify Everything is Running

```bash
# Check all running containers
docker ps

# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# View resource usage
docker stats --no-stream

# Check disk usage
docker system df
```

## Step 14: Set Up Backups

Create a backup script:

```bash
# Create a backup directory
mkdir -p ~/backups

# Create a simple backup script
cat > ~/backup-homelab.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=~/backups
DATE=$(date +%Y%m%d)

# Backup config directories
tar czf $BACKUP_DIR/config-$DATE.tar.gz ~/AI-Homelab/config/

# Backup .env file
cp ~/AI-Homelab/.env $BACKUP_DIR/.env-$DATE

# Backup Docker volumes (example for Portainer)
docker run --rm \
  -v portainer-data:/data \
  -v $BACKUP_DIR:/backup \
  busybox tar czf /backup/portainer-data-$DATE.tar.gz /data

echo "Backup completed: $DATE"
EOF

# Make it executable
chmod +x ~/backup-homelab.sh

# Test the backup
~/backup-homelab.sh
```

Set up a cron job for automated backups:

```bash
# Open crontab
crontab -e

# Add this line to run backup daily at 2 AM
0 2 * * * /home/yourusername/backup-homelab.sh
```

## Step 15: Configure Firewall (Optional but Recommended)

If using UFW:

```bash
# Allow SSH (if not already allowed)
sudo ufw allow 22/tcp

# Allow web traffic (if exposing services to internet)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow specific services from local network only
# Replace 192.168.1.0/24 with your network
sudo ufw allow from 192.168.1.0/24 to any port 9000 proto tcp  # Portainer
sudo ufw allow from 192.168.1.0/24 to any port 81 proto tcp    # Nginx Proxy Manager
sudo ufw allow from 192.168.1.0/24 to any port 3000 proto tcp  # Grafana

# Enable firewall
sudo ufw enable
```

## Next Steps

Now that your homelab is running:

1. **Explore Services:**
   - Access each service's web UI
   - Configure settings as needed
   - Set up integrations between services

2. **Add More Services:**
   - Ask GitHub Copilot for help adding new services
   - Follow the patterns in existing compose files
   - Check [awesome-selfhosted](https://github.com/awesome-selfhosted/awesome-selfhosted) for ideas

3. **Optimize:**
   - Review logs for errors
   - Adjust resource limits
   - Set up proper monitoring and alerts

4. **Secure:**
   - Change all default passwords
   - Set up SSL certificates (use Nginx Proxy Manager)
   - Enable 2FA where available
   - Keep services updated

5. **Learn:**
   - Read the [Docker Guidelines](docker-guidelines.md)
   - Experiment with new services
   - Use AI assistance to understand and modify configurations

## Troubleshooting

### Can't access services

1. **Check if service is running:**
   ```bash
   docker ps
   ```

2. **Check service logs:**
   ```bash
   docker compose -f docker-compose/file.yml logs service-name
   ```

3. **Verify network connectivity:**
   ```bash
   ping YOUR_SERVER_IP
   ```

4. **Check firewall:**
   ```bash
   sudo ufw status
   ```

### Permission errors

```bash
# Fix config directory permissions
sudo chown -R $(id -u):$(id -g) config/

# Verify PUID/PGID in .env match your user
id -u  # Should match PUID in .env
id -g  # Should match PGID in .env
```

### Port already in use

```bash
# Find what's using the port
sudo netstat -tlnp | grep PORT_NUMBER

# Stop the conflicting service or change the port in docker-compose
```

### Out of disk space

```bash
# Check disk usage
df -h

# Clean up Docker resources
docker system prune -a

# Remove old logs
docker compose logs --tail=0 service-name
```

## Getting Help

- **Documentation:** Check the `docs/` directory for comprehensive guides
- **AI Assistance:** Use GitHub Copilot in VS Code for real-time help
- **Community:** Search for service-specific help in respective communities
- **Issues:** Open an issue on GitHub for problems with this repository

## Success Checklist

- [ ] Docker and Docker Compose installed
- [ ] Repository cloned
- [ ] `.env` file configured
- [ ] Networks created
- [ ] Config directories created
- [ ] Portainer running and accessible
- [ ] Infrastructure services deployed
- [ ] At least one service category deployed (media/monitoring/dev)
- [ ] VS Code with GitHub Copilot set up
- [ ] Backup strategy in place
- [ ] Firewall configured (if applicable)
- [ ] All services accessible and working

Congratulations! Your AI-powered homelab is now running! 🎉
