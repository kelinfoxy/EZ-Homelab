# Quick Reference Guide

## Common Commands

### Service Management

```bash
# Start all services in a file
docker compose -f docker-compose/file.yml up -d

# Start specific service
docker compose -f docker-compose/file.yml up -d service-name

# Stop all services
docker compose -f docker-compose/file.yml down

# Stop specific service
docker compose -f docker-compose/file.yml stop service-name

# Restart service
docker compose -f docker-compose/file.yml restart service-name

# Remove service and volumes
docker compose -f docker-compose/file.yml down -v
```

### Monitoring

```bash
# View logs
docker compose -f docker-compose/file.yml logs -f service-name

# Check service status
docker compose -f docker-compose/file.yml ps

# View resource usage
docker stats

# Inspect service
docker inspect container-name
```

### Updates

```bash
# Pull latest images
docker compose -f docker-compose/file.yml pull

# Pull and update specific service
docker compose -f docker-compose/file.yml pull service-name
docker compose -f docker-compose/file.yml up -d service-name
```

### Network Management

```bash
# List networks
docker network ls

# Inspect network
docker network inspect homelab-network

# Create network
docker network create network-name

# Remove network
docker network rm network-name
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect volume-name

# Remove volume
docker volume rm volume-name

# Backup volume
docker run --rm -v volume-name:/data -v $(pwd)/backups:/backup \
  busybox tar czf /backup/backup.tar.gz /data

# Restore volume
docker run --rm -v volume-name:/data -v $(pwd)/backups:/backup \
  busybox tar xzf /backup/backup.tar.gz -C /
```

### System Maintenance

```bash
# View disk usage
docker system df

# Clean up unused resources
docker system prune

# Clean up everything (careful!)
docker system prune -a --volumes

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune
```

## Port Reference

### Infrastructure Services
- **80**: Nginx Proxy Manager (HTTP)
- **443**: Nginx Proxy Manager (HTTPS)
- **81**: Nginx Proxy Manager (Admin)
- **53**: Pi-hole (DNS)
- **8080**: Pi-hole (Web UI)
- **9000**: Portainer
- **9443**: Portainer (HTTPS)

### Media Services
- **32400**: Plex
- **8096**: Jellyfin
- **8989**: Sonarr
- **7878**: Radarr
- **9696**: Prowlarr
- **8081**: qBittorrent

### Monitoring Services
- **9090**: Prometheus
- **3000**: Grafana
- **9100**: Node Exporter
- **8082**: cAdvisor
- **3001**: Uptime Kuma
- **3100**: Loki

### Development Services
- **8443**: Code Server
- **8929**: GitLab
- **2222**: GitLab SSH
- **5432**: PostgreSQL
- **6379**: Redis
- **5050**: pgAdmin
- **8888**: Jupyter Lab
- **1880**: Node-RED

## Environment Variables Quick Reference

```bash
# User/Group
PUID=1000              # Your user ID (get with: id -u)
PGID=1000              # Your group ID (get with: id -g)

# General
TZ=America/New_York    # Your timezone
SERVER_IP=192.168.1.100  # Server IP address

# Paths
USERDIR=/home/username/homelab
MEDIADIR=/mnt/media
DOWNLOADDIR=/mnt/downloads
PROJECTDIR=/home/username/projects
```

## Network Setup

```bash
# Create all networks at once
docker network create homelab-network
docker network create media-network
docker network create monitoring-network
docker network create database-network
```

## Service URLs

After starting services, access them at:

```
Infrastructure:
http://SERVER_IP:81        - Nginx Proxy Manager
http://SERVER_IP:8080      - Pi-hole
http://SERVER_IP:9000      - Portainer

Media:
http://SERVER_IP:32400/web - Plex
http://SERVER_IP:8096      - Jellyfin
http://SERVER_IP:8989      - Sonarr
http://SERVER_IP:7878      - Radarr
http://SERVER_IP:9696      - Prowlarr
http://SERVER_IP:8081      - qBittorrent

Monitoring:
http://SERVER_IP:9090      - Prometheus
http://SERVER_IP:3000      - Grafana
http://SERVER_IP:3001      - Uptime Kuma

Development:
http://SERVER_IP:8443      - Code Server
http://SERVER_IP:8929      - GitLab
http://SERVER_IP:5050      - pgAdmin
http://SERVER_IP:8888      - Jupyter Lab
http://SERVER_IP:1880      - Node-RED
```

## Troubleshooting Quick Fixes

### Service won't start
```bash
# 1. Check logs
docker compose -f docker-compose/file.yml logs service-name

# 2. Validate configuration
docker compose -f docker-compose/file.yml config

# 3. Check what's using the port
sudo netstat -tlnp | grep PORT_NUMBER
```

### Permission errors
```bash
# Check your IDs
id -u  # Should match PUID in .env
id -g  # Should match PGID in .env

# Fix ownership
sudo chown -R 1000:1000 ./config/service-name
```

### Network issues
```bash
# Check network exists
docker network inspect homelab-network

# Recreate network
docker network rm homelab-network
docker network create homelab-network
docker compose -f docker-compose/file.yml up -d
```

### Container keeps restarting
```bash
# Watch logs in real-time
docker compose -f docker-compose/file.yml logs -f service-name

# Check resource usage
docker stats container-name

# Inspect container
docker inspect container-name | less
```

## Testing GPU Support (NVIDIA)

```bash
# Test if nvidia-container-toolkit works
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# If successful, you should see your GPU info
```

## Backup Commands

```bash
# Backup all config directories
tar czf backup-config-$(date +%Y%m%d).tar.gz config/

# Backup a specific volume
docker run --rm \
  -v volume-name:/data \
  -v $(pwd)/backups:/backup \
  busybox tar czf /backup/volume-name-$(date +%Y%m%d).tar.gz /data

# Backup .env file (store securely!)
cp .env .env.backup
```

## Health Checks

```bash
# Check all container health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check specific service health
docker inspect --format='{{json .State.Health}}' container-name | jq
```

## Resource Limits

Add to service definition if needed:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
    reservations:
      cpus: '0.5'
      memory: 1G
```

## Common Patterns

### Add a new service
1. Choose the appropriate compose file
2. Add service definition following existing patterns
3. Use environment variables from .env
4. Connect to homelab-network
5. Pin specific image version
6. Add labels for organization
7. Test: `docker compose -f file.yml config`
8. Deploy: `docker compose -f file.yml up -d service-name`

### Update a service version
1. Edit compose file with new version
2. Pull new image: `docker compose -f file.yml pull service-name`
3. Recreate: `docker compose -f file.yml up -d service-name`
4. Check logs: `docker compose -f file.yml logs -f service-name`

### Remove a service
1. Stop service: `docker compose -f file.yml stop service-name`
2. Remove service: `docker compose -f file.yml rm service-name`
3. Remove from compose file
4. Optional: Remove volumes: `docker volume rm volume-name`
5. Optional: Remove config: `rm -rf config/service-name`

## AI Assistant Usage in VS Code

### Ask for help:
- "Add Jellyfin to my media stack"
- "Configure GPU for Plex"
- "Create monitoring dashboard setup"
- "Help me troubleshoot port conflicts"
- "Generate a compose file for Home Assistant"

### The AI will:
- Check existing services
- Follow naming conventions
- Avoid port conflicts
- Use proper network configuration
- Include health checks
- Add documentation comments
- Suggest related services

## Quick Deployment

### Minimal setup
```bash
# 1. Clone and configure
# Note: Replace 'kelinfoxy' with your username if you forked this repository
git clone https://github.com/kelinfoxy/AI-Homelab.git
cd AI-Homelab
cp .env.example .env
nano .env  # Edit values

# 2. Create network
docker network create homelab-network

# 3. Start Portainer (for container management)
docker compose -f docker-compose/infrastructure.yml up -d portainer

# 4. Access at http://SERVER_IP:9000
```

### Full stack deployment
```bash
# After minimal setup, deploy everything:
docker compose -f docker-compose/infrastructure.yml up -d
docker compose -f docker-compose/media.yml up -d
docker compose -f docker-compose/monitoring.yml up -d
docker compose -f docker-compose/development.yml up -d
```

## Maintenance Schedule

### Daily (automated)
- Watchtower checks for updates at 4 AM

### Weekly
- Review logs: `docker compose -f docker-compose/*.yml logs --tail=100`
- Check disk space: `docker system df`

### Monthly
- Update pinned versions in compose files
- Backup volumes and configs
- Review security updates

### Quarterly
- Full system audit
- Documentation review
- Performance optimization
