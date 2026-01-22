# Quick Reference Guide

## Stack Overview

Your homelab uses separate stacks for organization:

**Deployed by default (12 containers):**
- **`core.yml`** - Essential infrastructure (Traefik, Authelia, DuckDNS, Gluetun) - 4 services
- **`infrastructure.yml`** - Management tools (Dockge, Pi-hole, Dozzle, Glances, Docker Proxy) - 6 services  
  _Note: Watchtower temporarily disabled due to Docker API compatibility_
- **`dashboards.yml`** - Dashboard services (Homepage, Homarr) - 2 services

**Available in Dockge (deploy as needed):**
- **`media.yml`** - Media services (Plex, Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent)
- **`media-extended.yml`** - Additional media tools (Readarr, Lidarr, Mylar, Calibre)
- **`homeassistant.yml`** - Home automation (Home Assistant, Node-RED, Zigbee2MQTT, ESPHome)
- **`productivity.yml`** - Productivity apps (Nextcloud, Gitea, Bookstack, Outline, Excalidraw)
- **`monitoring.yml`** - Monitoring stack (Grafana, Prometheus, Uptime Kuma, Netdata)
- **`utilities.yml`** - Utility services (Duplicati, Code Server, FreshRSS, Wallabag)
- **`alternatives.yml`** - Alternative tools (Portainer, Authentik)

> All stacks can be modified by the AI to suit your preferences.

## Deployment Scripts

For detailed information about the deployment scripts, their features, and usage, see [scripts/README.md](../scripts/README.md).

**Quick summary:**
- `setup-homelab.sh` - First-run system setup and Authelia configuration
- `deploy-homelab.sh` - Deploy all core services and prepare additional stacks
- `reset-test-environment.sh` - Testing/development only - removes all deployed services
- `reset-ondemand-services.sh` - Reload services for Sablier lazy loading

## Common Commands

### Service Management

```bash
# Start all services in a stack (from stack directory)
cd /opt/stacks/stack-name/
docker compose up -d

# Start all services (from anywhere, using full path)
docker compose -f /opt/stacks/stack-name/docker-compose.yml up -d

# Start specific service (from stack directory)
cd /opt/stacks/stack-name/
docker compose up -d service-name

# Start specific service (from anywhere)
docker compose -f /opt/stacks/stack-name/docker-compose.yml up -d service-name

# Stop all services (from stack directory)
cd /opt/stacks/stack-name/
docker compose down

# Stop all services (from anywhere)
docker compose -f /opt/stacks/stack-name/docker-compose.yml down

# Stop specific service (from stack directory)
cd /opt/stacks/stack-name/
docker compose stop service-name

# Stop specific service (from anywhere)
docker compose -f /opt/stacks/stack-name/docker-compose.yml stop service-name

# Restart service (from stack directory)
cd /opt/stacks/stack-name/
docker compose restart service-name

# Restart service (from anywhere)
docker compose -f /opt/stacks/stack-name/docker-compose.yml restart service-name

# Remove service and volumes (from stack directory)
cd /opt/stacks/stack-name/
docker compose down -v

# Remove service and volumes (from anywhere)
docker compose -f /opt/stacks/stack-name/docker-compose.yml down -v
```

### Monitoring

> Tip: install the Dozzle service for viewing live logs

```bash
# View logs for entire stack
cd /opt/stacks/stack-name/
docker compose logs -f

# View logs for specific service
cd /opt/stacks/stack-name/
docker compose logs -f service-name

# View last 100 lines
cd /opt/stacks/stack-name/
docker compose logs --tail=100 service-name

# Check service status
docker compose -f /opt/stacks/stack-name/docker-compose.yml ps

# View resource usage
docker stats

# Inspect service
docker inspect container-name
```

### Updates

> Tip: Install the Watchtower service for automatic updates

```bash
# Pull latest images for stack
cd /opt/stacks/stack-name/
docker compose pull

# Pull and update specific service
cd /opt/stacks/stack-name/
docker compose pull service-name
docker compose up -d service-name
```

### Network Management

```bash
# List all networks
docker network ls

# Inspect network
docker network inspect traefik-network

# Create network (if needed)
docker network create network-name

# Remove unused networks
docker network prune
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect volume-name

# Remove unused volumes
docker volume prune

# Backup volume
docker run --rm \
  -v volume-name:/data \
  -v $(pwd)/backups:/backup \
  busybox tar czf /backup/volume-backup.tar.gz /data

# Restore volume
docker run --rm \
  -v volume-name:/data \
  -v $(pwd)/backups:/backup \
  busybox tar xzf /backup/volume-backup.tar.gz -C /
```

### System Maintenance

```bash
# View disk usage
docker system df

# Clean up unused resources
docker system prune

# Clean up everything (use carefully!)
docker system prune -a --volumes

# Remove unused images
docker image prune -a
```

## Port Reference

### Core Infrastructure (core.yml)
- **80/443**: Traefik (reverse proxy)
- **8080**: Traefik dashboard
- **10000**: Sablier (lazy loading service)

### Infrastructure Services (infrastructure.yml)
- **5001**: Dockge (stack manager)
- **9000/9443**: Portainer (Docker UI)
- **53**: Pi-hole (DNS)
- **8082**: Pi-hole (web UI)
- **9999**: Watchtower (auto-updates)
- **8000**: Dozzle (log viewer)
- **61208**: Glances (system monitor)

### Dashboard Services (dashboards.yml)
- **3000**: Homepage dashboard
- **7575**: Homarr dashboard

### Media Services (media.yml)
- **32400**: Plex
- **8096**: Jellyfin
- **8989**: Sonarr
- **7878**: Radarr
- **9696**: Prowlarr
- **8081**: qBittorrent

### Extended Media (media-extended.yml)
- **8787**: Readarr
- **8686**: Lidarr
- **5299**: Lazy Librarian
- **8090**: Mylar3
- **8083**: Calibre-Web
- **5055**: Jellyseerr
- **9697**: FlareSolverr
- **7889**: Tdarr Server
- **8265**: Unmanic

### Home Automation (homeassistant.yml)
- **8123**: Home Assistant
- **6052**: ESPHome
- **8843**: TasmoAdmin
- **1880**: Node-RED
- **1883/9001**: Mosquitto (MQTT)
- **8124**: Zigbee2MQTT
- **8081**: MotionEye

### Productivity (productivity.yml)
- **8080**: Nextcloud
- **9929**: Mealie
- **8084**: WordPress
- **3000**: Gitea
- **8085**: DokuWiki
- **8086**: BookStack
- **8087**: MediaWiki
- **3030**: Form.io

### Monitoring (monitoring.yml)
- **9090**: Prometheus
- **3000**: Grafana
- **3100**: Loki
- **9080**: Promtail
- **9100**: Node Exporter
- **8080**: cAdvisor
- **3001**: Uptime Kuma

### Utilities (utilities.yml)
- **7979**: Backrest (backups)
- **8200**: Duplicati (backups)
- **8443**: Code Server
- **5000**: Form.io
- **3001**: Uptime Kuma

### Development (development.yml)
- **8929**: GitLab
- **5432**: PostgreSQL
- **6379**: Redis
- **5050**: pgAdmin
- **8888**: Jupyter Lab

## Environment Variables Quick Reference

```bash
# User IDs (get with: id -u and id -g)
PUID=1000              # Your user ID
PGID=1000              # Your group ID

# General
TZ=America/New_York    # Your timezone
DOMAIN=yourdomain.duckdns.org  # Your domain

# DuckDNS
DUCKDNS_TOKEN=your-token
DUCKDNS_SUBDOMAINS=yourdomain

# Authelia
AUTHELIA_JWT_SECRET=64-char-secret
AUTHELIA_SESSION_SECRET=64-char-secret
AUTHELIA_STORAGE_ENCRYPTION_KEY=64-char-secret

# Database passwords
MYSQL_ROOT_PASSWORD=secure-password
POSTGRES_PASSWORD=secure-password

# API Keys (service-specific)
SONARR_API_KEY=your-api-key
RADARR_API_KEY=your-api-key
```

## Network Setup

```bash
# Create all required networks (setup script does this)
docker network create traefik-network
docker network create homelab-network
docker network create media-network
docker network create dockerproxy-network
```

## Service URLs

After deployment, access services at:

```
Core Infrastructure:
https://traefik.${DOMAIN}     - Traefik dashboard
https://auth.${DOMAIN}        - Authelia login
http://sablier.${DOMAIN}:10000 - Sablier lazy loading (internal)

Infrastructure:
https://dockge.${DOMAIN}       - Stack manager (PRIMARY)
https://portainer.${DOMAIN}    - Docker UI (secondary)
http://pihole.${DOMAIN}        - Pi-hole admin
https://dozzle.${DOMAIN}       - Log viewer
https://glances.${DOMAIN}      - System monitor

Dashboards:
https://homepage.${DOMAIN}         - Homepage dashboard
https://homarr.${DOMAIN}       - Homarr dashboard

Media:
https://plex.${DOMAIN}         - Plex (no auth)
https://jellyfin.${DOMAIN}     - Jellyfin (no auth)
https://sonarr.${DOMAIN}       - TV automation
https://radarr.${DOMAIN}       - Movie automation
https://prowlarr.${DOMAIN}     - Indexer manager
https://torrents.${DOMAIN}         - Torrent client

Productivity:
https://nextcloud.${DOMAIN}    - Cloud Storage
https://gitea.${DOMAIN}        - Gitea

Monitoring:
https://grafana.${DOMAIN}      - Metrics dashboard
https://prometheus.${DOMAIN}   - Metrics collection
https://status.${DOMAIN}       - Uptime monitoring

Utilities:
https://backrest.${DOMAIN}     - Backup management (Restic)
```

## Troubleshooting

### SSL Certificates

```bash
# Check wildcard certificate status
python3 -c "import json; d=json.load(open('/opt/stacks/core/traefik/acme.json')); print(f'Certificates: {len(d[\"letsencrypt\"][\"Certificates\"])}')"

# Verify certificate being served
echo | openssl s_client -connect auth.yourdomain.duckdns.org:443 -servername auth.yourdomain.duckdns.org 2>/dev/null | openssl x509 -noout -subject -issuer

# Check DNS TXT records (for DNS challenge)
dig +short TXT _acme-challenge.yourdomain.duckdns.org

# View Traefik certificate logs
docker exec traefik tail -50 /var/log/traefik/traefik.log | grep -E "acme|certificate"

# Reset certificates (if needed)
docker compose -f /opt/stacks/core/docker-compose.yml down
rm /opt/stacks/core/traefik/acme.json
touch /opt/stacks/core/traefik/acme.json
chmod 600 /opt/stacks/core/traefik/acme.json
sleep 60  # Wait for DNS to clear
docker compose -f /opt/stacks/core/docker-compose.yml up -d
```

**Important:** With DuckDNS, only Traefik should request certificates (wildcard cert covers all subdomains). Other services use `tls=true` without `certresolver`.

## Troubleshooting Quick Fixes

### Service won't start
```bash
# Check logs
docker compose -f /opt/stacks/stack-name/docker-compose.yml logs service-name

# Validate configuration
docker compose -f /opt/stacks/stack-name/docker-compose.yml config

# Check port conflicts
sudo netstat -tlnp | grep :PORT

# Restart Docker
sudo systemctl restart docker
```

### Permission errors
```bash
# Check your IDs match .env
id -u  # Should match PUID
id -g  # Should match PGID

# Fix ownership
sudo chown -R $USER:$USER /opt/stacks/stack-name/
```

### Network issues
```bash
# Check network exists
docker network inspect traefik-network

# Recreate network
docker network rm traefik-network
docker network create traefik-network
```

### Container keeps restarting
```bash
# Watch logs in real-time
docker compose -f /opt/stacks/stack-name/docker-compose.yml logs -f service-name

# Check resource usage
docker stats container-name

# Inspect container
docker inspect container-name | jq .State
```

### SSL certificate issues
```bash
# Check Traefik logs
docker logs traefik

# Check acme.json permissions
ls -la /opt/stacks/core/traefik/acme.json

# Force certificate renewal
# Remove acme.json and restart Traefik
```

## Testing GPU Support (NVIDIA)

```bash
# Test if nvidia-container-toolkit works
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# Should show your GPU info if working
```

## Backup Commands

```bash
# Backup all config directories
tar czf backup-config-$(date +%Y%m%d).tar.gz /opt/stacks/

# Backup specific volume
docker run --rm \
  -v volume-name:/data \
  -v /mnt/backups:/backup \
  busybox tar czf /backup/volume-name-$(date +%Y%m%d).tar.gz /data

# Backup .env file securely
cp .env .env.backup
```

## Health Checks

```bash
# Check all container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check specific service health
docker inspect --format='{{json .State.Health}}' container-name | jq

# Test service connectivity
curl -k https://service.${DOMAIN}
```

## Resource Limits

Add to service definition if needed:

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 4G
    reservations:
      cpus: '0.5'
      memory: 1G
```

## Common Patterns

### Add a new service to existing stack
1. Edit `/opt/stacks/stack-name/docker-compose.yml`
2. Add service definition following existing patterns
3. Use environment variables from `.env`
4. Connect to appropriate networks
5. Add Traefik labels for routing
6. Test: `docker compose config`
7. Deploy: `docker compose up -d`

### Create a new stack
1. Create directory: `mkdir /opt/stacks/new-stack`
2. Copy compose file: `cp docker-compose/template.yml /opt/stacks/new-stack/docker-compose.yml`
3. Copy env: `cp .env /opt/stacks/new-stack/`
4. Edit configuration
5. Deploy: `cd /opt/stacks/new-stack && docker compose up -d`

### Update service version
1. Edit compose file with new image tag
2. Pull new image: `docker compose pull service-name`
3. Recreate: `docker compose up -d service-name`
4. Check logs: `docker compose logs -f service-name`

### Remove a service
1. Stop service: `docker compose stop service-name`
2. Remove from compose file
3. Remove service: `docker compose rm service-name`
4. Optional: Remove volumes: `docker volume rm volume-name`

## AI Assistant Usage in VS Code

### Ask for help:
- "Add Jellyfin to my media stack"
- "Configure GPU for Plex"
- "Create monitoring dashboard setup"
- "Help me troubleshoot port conflicts"
- "Generate a compose file for Home Assistant"

### The AI will:
- Check existing services and avoid conflicts
- Follow naming conventions and patterns
- Configure Traefik labels automatically
- Apply Authelia middleware appropriately
- Suggest proper volume mounts
- Add services to Homepage dashboard

## Quick Deployment

### Minimal setup
```bash
# Clone and configure
git clone https://github.com/kelinfoxy/AI-Homelab.git
cd AI-Homelab
sudo ./scripts/setup-homelab.sh
cp .env.example .env
nano .env

# Deploy core only
mkdir -p /opt/stacks/core
cp docker-compose/core.yml /opt/stacks/core/docker-compose.yml
cp -r config-templates/traefik /opt/stacks/core/
cp -r config-templates/authelia /opt/stacks/core/
cp .env /opt/stacks/core/
cd /opt/stacks/core && docker compose up -d
```

### Full stack deployment
```bash
# After core is running, deploy all stacks
# Use Dockge UI at https://dockge.yourdomain.duckdns.org
# Or deploy manually:
docker compose -f docker-compose/infrastructure.yml up -d
docker compose -f docker-compose/dashboards.yml up -d
docker compose -f docker-compose/media.yml up -d
# etc.
```

## Maintenance Schedule

### Daily (automated)
- Watchtower checks for updates at 4 AM

### Weekly
- Review logs for each stack
- Check disk space: `docker system df`

### Monthly
- Update pinned versions in compose files
- Backup volumes and configs
- Review security updates

### Quarterly
- Full system audit
- Documentation review
- Performance optimization

## Emergency Commands

```bash
# Stop all containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Reset Docker (nuclear option)
sudo systemctl stop docker
sudo rm -rf /var/lib/docker
sudo systemctl start docker
```
