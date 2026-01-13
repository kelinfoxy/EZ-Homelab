# Docker Service Management Guidelines

## Overview

This document provides comprehensive guidelines for managing Docker services in your AI-powered homelab using Dockge, Traefik, and Authelia. These guidelines ensure consistency, maintainability, and reliability across your entire infrastructure.

## Table of Contents

1. [Philosophy](#philosophy)
2. [Dockge Structure](#dockge-structure)
3. [Traefik and Authelia Integration](#traefik-and-authelia-integration)
4. [Docker Compose vs Docker Run](#docker-compose-vs-docker-run)
5. [Service Creation Guidelines](#service-creation-guidelines)
6. [Service Modification Guidelines](#service-modification-guidelines)
7. [Naming Conventions](#naming-conventions)
8. [Network Architecture](#network-architecture)
9. [Volume Management](#volume-management)
10. [Security Best Practices](#security-best-practices)
11. [Monitoring and Logging](#monitoring-and-logging)
12. [Troubleshooting](#troubleshooting)

## Philosophy

### Core Principles

1. **Dockge First**: Manage all stacks through Dockge in `/opt/stacks/`
2. **Infrastructure as Code**: All services defined in Docker Compose files
3. **File-Based Configuration**: Traefik labels and Authelia YAML (AI-manageable)
4. **Reproducibility**: Any service should be rebuildable from compose files
5. **Automatic HTTPS**: All services routed through Traefik with Let's Encrypt
6. **Smart SSO**: Authelia protects admin interfaces, bypasses media apps
7. **Documentation**: Every non-obvious configuration must be commented
8. **Consistency**: Use the same patterns across all services
9. **Safety First**: Always test changes in isolation before deploying

### The Stack Mindset

Think of your homelab as an interconnected stack where:
- Services depend on networks (especially traefik-network)
- Traefik routes all traffic with automatic SSL
- Authelia protects sensitive services
- VPN (Gluetun) secures downloads
- Changes ripple through the system

Always ask: "How does this change affect other services and routing?"

## Dockge Structure

### Directory Organization

All stacks live in `/opt/stacks/stack-name/`:

```
/opt/stacks/
├── traefik/
│   ├── docker-compose.yml
│   ├── traefik.yml           # Static config
│   ├── dynamic/              # Dynamic routes
│   │   ├── routes.yml
│   │   └── external.yml      # External host proxying
│   ├── acme.json            # SSL certificates (chmod 600)
│   └── .env
├── authelia/
│   ├── docker-compose.yml
│   ├── configuration.yml     # Authelia settings
│   ├── users_database.yml    # User accounts
│   └── .env
├── media/
│   ├── docker-compose.yml
│   └── .env
└── ...
```

### Why Dockge?

- **Visual Management**: Web UI at `https://dockge.${DOMAIN}`
- **Direct File Editing**: Edit compose files in-place
- **Stack Organization**: Each service stack is independent
- **AI Compatible**: Files can be managed by AI
- **Git Integration**: Easy to version control

### Storage Strategy

**Small Data** (configs, DBs < 10GB): `/opt/stacks/stack-name/`
```yaml
volumes:
  - /opt/stacks/sonarr/config:/config
```

**Large Data** (media, downloads, backups): `/mnt/`
```yaml
volumes:
  - /mnt/media/movies:/movies
  - /mnt/media/tv:/tv
  - /mnt/downloads:/downloads
  - /mnt/backups:/backups
```

AI will suggest `/mnt/` when data may exceed 50GB or grow continuously.

## Traefik and Authelia Integration

### Every Service Needs Traefik Labels

Standard pattern for all services:

```yaml
services:
  myservice:
    image: myimage:latest
    container_name: myservice
    networks:
      - homelab-network
      - traefik-network    # Required for Traefik
    labels:
      # Enable Traefik
      - "traefik.enable=true"
      
      # Define routing rule
      - "traefik.http.routers.myservice.rule=Host(`myservice.${DOMAIN}`)"
      
      # Use websecure entrypoint (HTTPS)
      - "traefik.http.routers.myservice.entrypoints=websecure"
      
      # Enable Let's Encrypt
      - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
      
      # Add Authelia SSO (if needed)
      - "traefik.http.routers.myservice.middlewares=authelia@docker"
      
      # Specify port (if not default 80)
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

### When to Use Authelia SSO

**Protect with Authelia**:
- Admin interfaces (Sonarr, Radarr, Prowlarr, etc.)
- Infrastructure tools (Portainer, Dockge, Grafana)
- Personal data (Nextcloud, Mealie, wikis)
- Development tools (code-server, GitLab)
- Monitoring dashboards

**Bypass Authelia**:
- Media servers (Plex, Jellyfin) - need app access
- Request services (Jellyseerr) - family-friendly access
- Public services (WordPress, status pages)
- Services with their own auth (Home Assistant)

Configure bypasses in `/opt/stacks/authelia/configuration.yml`:

```yaml
access_control:
  rules:
    - domain: jellyfin.yourdomain.duckdns.org
      policy: bypass
    
    - domain: plex.yourdomain.duckdns.org
      policy: bypass
```

### Routing Through VPN (Gluetun)

For services that need VPN (downloads):

```yaml
services:
  mydownloader:
    image: downloader:latest
    container_name: mydownloader
    network_mode: "service:gluetun"  # Route through VPN
    depends_on:
      - gluetun
```

Expose ports through Gluetun's compose file:
```yaml
# In gluetun.yml
gluetun:
  ports:
    - "8080:8080"  # mydownloader web UI
```

## Docker Compose vs Docker Run

### Docker Compose: For Everything Persistent

Use Docker Compose for:
- All production services
- Services that need to restart automatically
- Multi-container applications
- Services with complex configurations
- Anything you want to keep long-term

**Example:**
```yaml
# docker-compose/plex.yml
services:
  plex:
    image: plexinc/pms-docker:1.40.0.7998-f68041501
    container_name: plex
    restart: unless-stopped
    networks:
      - media-network
    ports:
      - "32400:32400"
    volumes:
      - ./config/plex:/config
      - /media:/media:ro
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
```

### Docker Run: For Temporary Operations Only

Use `docker run` for:
- Testing new images
- One-off commands
- Debugging
- Verification tasks (like GPU testing)

**Examples:**
```bash
# Test if NVIDIA GPU is accessible
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# Quick test of a new image
docker run --rm -it alpine:latest /bin/sh

# One-off database backup
docker run --rm -v mydata:/data busybox tar czf /backup/data.tar.gz /data
```

## Service Creation Guidelines

### Step-by-Step Process

#### 1. Planning Phase

**Before writing any YAML:**

- [ ] What problem does this service solve?
- [ ] Does a similar service already exist?
- [ ] What are the dependencies?
- [ ] What ports are needed?
- [ ] What data needs to persist?
- [ ] What environment variables are required?
- [ ] What networks should it connect to?
- [ ] Are there any security considerations?

#### 2. Research Phase

- Read the official image documentation
- Check example configurations
- Review resource requirements
- Understand health check requirements
- Note any special permissions needed

#### 3. Implementation Phase

**Start with a minimal configuration:**

```yaml
services:
  service-name:
    image: vendor/image:specific-version
    container_name: service-name
    restart: unless-stopped
```

**Add networks:**
```yaml
    networks:
      - homelab-network
```

**Add ports (if externally accessible):**
```yaml
    ports:
      - "8080:8080"  # Web UI
```

**Add volumes:**
```yaml
    volumes:
      - ./config/service-name:/config
      - service-data:/data
```

**Add environment variables:**
```yaml
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TIMEZONE}
```

**Add health checks (if applicable):**
```yaml
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

#### 4. Testing Phase

```bash
# Validate syntax
docker compose -f docker-compose/service.yml config

# Start in foreground to see logs
docker compose -f docker-compose/service.yml up

# If successful, restart in background
docker compose -f docker-compose/service.yml down
docker compose -f docker-compose/service.yml up -d
```

#### 5. Documentation Phase

Add comments to your compose file:
```yaml
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:4.0.0
    container_name: sonarr
    # Sonarr - TV Show management and automation
    # Web UI: http://server-ip:8989
    # Connects to: Prowlarr (indexers), qBittorrent (downloads)
    restart: unless-stopped
```

Update your main README or service-specific README with:
- Service purpose
- Access URLs
- Default credentials (if any)
- Configuration notes
- Backup instructions

## Service Modification Guidelines

### Before Modifying

1. **Back up current configuration:**
   ```bash
   cp docker-compose/service.yml docker-compose/service.yml.backup
   ```

2. **Document why you're making the change**
   - Create a comment in the compose file
   - Note in your changelog or docs

3. **Understand the current state:**
   ```bash
   # Check if service is running
   docker compose -f docker-compose/service.yml ps
   
   # Review current configuration
   docker compose -f docker-compose/service.yml config
   
   # Check logs for any existing issues
   docker compose -f docker-compose/service.yml logs --tail=50
   ```

### Making the Change

1. **Edit the compose file**
   - Make minimal, targeted changes
   - Keep existing structure when possible
   - Add comments for new configurations

2. **Validate syntax:**
   ```bash
   docker compose -f docker-compose/service.yml config
   ```

3. **Apply the change:**
   ```bash
   # Pull new image if version changed
   docker compose -f docker-compose/service.yml pull
   
   # Recreate the service
   docker compose -f docker-compose/service.yml up -d
   ```

4. **Verify the change:**
   ```bash
   # Check service is running
   docker compose -f docker-compose/service.yml ps
   
   # Watch logs for errors
   docker compose -f docker-compose/service.yml logs -f
   
   # Test functionality
   curl http://localhost:port/health
   ```

### Rollback Plan

If something goes wrong:
```bash
# Stop the service
docker compose -f docker-compose/service.yml down

# Restore backup
mv docker-compose/service.yml.backup docker-compose/service.yml

# Restart with old configuration
docker compose -f docker-compose/service.yml up -d
```

## Naming Conventions

### Service Names

Use lowercase with hyphens:
- ✅ `plex-media-server`
- ✅ `home-assistant`
- ❌ `PlexMediaServer`
- ❌ `home_assistant`

### Container Names

Match service names or be descriptive:
```yaml
services:
  plex:
    container_name: plex  # Simple match
  
  database:
    container_name: media-database  # Descriptive
```

### Network Names

Use purpose-based naming:
- `homelab-network` - Main network
- `media-network` - Media services
- `monitoring-network` - Observability stack
- `isolated-network` - Untrusted services

### Volume Names

Use `service-purpose` pattern:
```yaml
volumes:
  plex-config:
  plex-metadata:
  database-data:
  nginx-certs:
```

### File Names

Organize by function:
- `docker-compose/media.yml` - Media services (Plex, Jellyfin, etc.)
- `docker-compose/monitoring.yml` - Monitoring stack
- `docker-compose/infrastructure.yml` - Core services (DNS, reverse proxy)
- `docker-compose/development.yml` - Dev tools

## Network Architecture

### Network Types

1. **Bridge Networks** (Most Common)
   ```yaml
   networks:
     homelab-network:
       driver: bridge
       ipam:
         config:
           - subnet: 172.20.0.0/16
   ```

2. **Host Network** (When Performance Critical)
   ```yaml
   services:
     performance-critical:
       network_mode: host
   ```

3. **Overlay Networks** (For Swarm/Multi-host)
   ```yaml
   networks:
     swarm-network:
       driver: overlay
   ```

### Network Design Patterns

#### Pattern 1: Single Shared Network
Simplest approach for small homelabs:
```yaml
networks:
  homelab-network:
    external: true
```

Create once manually:
```bash
docker network create homelab-network
```

#### Pattern 2: Segmented Networks
Better security through isolation:
```yaml
networks:
  frontend-network:  # Web-facing services
  backend-network:   # Databases, internal services
  monitoring-network:  # Observability
```

#### Pattern 3: Service-Specific Networks
Each service group has its own network:
```yaml
services:
  web:
    networks:
      - frontend
      - backend
  
  database:
    networks:
      - backend  # Not exposed to frontend
```

### Network Security

- Place databases on internal networks only
- Use separate networks for untrusted services
- Expose minimal ports to the host
- Use reverse proxies for web services

## Volume Management

### Volume Types

#### Named Volumes (Managed by Docker)
```yaml
volumes:
  database-data:
    driver: local
```

**Use for:**
- Database files
- Application data
- Anything Docker should manage

**Advantages:**
- Docker handles permissions
- Easy to backup/restore
- Portable across systems

#### Bind Mounts (Direct Host Paths)
```yaml
volumes:
  - ./config/app:/config
  - /media:/media:ro
```

**Use for:**
- Configuration files you edit directly
- Large media libraries
- Shared data with host

**Advantages:**
- Direct file access
- Easy to edit
- Can share with host applications

#### tmpfs Mounts (RAM)
```yaml
tmpfs:
  - /tmp
```

**Use for:**
- Temporary data
- Cache that doesn't need persistence
- Sensitive data that shouldn't touch disk

### Volume Best Practices

1. **Consistent Paths:**
   ```yaml
   volumes:
     - ./config/service:/config  # Always use /config inside container
     - service-data:/data         # Always use /data for application data
   ```

2. **Read-Only When Possible:**
   ```yaml
   volumes:
     - /media:/media:ro  # Media library is read-only
   ```

3. **Separate Config from Data:**
   ```yaml
   volumes:
     - ./config/plex:/config      # Editable configuration
     - plex-metadata:/metadata    # Application-managed data
   ```

4. **Backup Strategy:**
   ```bash
   # Backup named volume
   docker run --rm \
     -v plex-metadata:/data \
     -v $(pwd)/backups:/backup \
     busybox tar czf /backup/plex-metadata.tar.gz /data
   ```

## Security Best Practices

### 1. Image Security

**Pin Specific Versions:**
```yaml
# ✅ Good - Specific version
image: nginx:1.25.3-alpine

# ❌ Bad - Latest tag
image: nginx:latest
```

**Use Official or Trusted Images:**
- Official Docker images
- LinuxServer.io (lscr.io)
- Trusted vendors

**Scan Images:**
```bash
docker scan vendor/image:tag
```

### 2. Secret Management

**Never Commit Secrets:**
```yaml
# .env file (gitignored)
DB_PASSWORD=super-secret-password
API_KEY=sk-1234567890

# docker-compose.yml
environment:
  - DB_PASSWORD=${DB_PASSWORD}
  - API_KEY=${API_KEY}
```

**Provide Templates:**
```bash
# .env.example (committed)
DB_PASSWORD=changeme
API_KEY=your-api-key-here
```

### 3. User Permissions

**Run as Non-Root:**
```yaml
environment:
  - PUID=1000  # Your user ID
  - PGID=1000  # Your group ID
```

**Check Current User:**
```bash
id -u  # Gets your UID
id -g  # Gets your GID
```

### 4. Network Security

**Minimal Exposure:**
```yaml
# ✅ Good - Only expose what's needed
ports:
  - "127.0.0.1:8080:8080"  # Only accessible from localhost

# ❌ Bad - Exposed to all interfaces
ports:
  - "8080:8080"
```

**Use Reverse Proxy:**
```yaml
# Don't expose services directly
# Use Nginx/Traefik to proxy with SSL
```

### 5. Resource Limits

**Prevent Resource Exhaustion:**
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

## Monitoring and Logging

### Logging Configuration

**Standard Logging:**
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

**Centralized Logging:**
```yaml
logging:
  driver: "syslog"
  options:
    syslog-address: "tcp://192.168.1.100:514"
```

### Health Checks

**HTTP Health Check:**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

**TCP Health Check:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "nc -z localhost 5432 || exit 1"]
  interval: 30s
  timeout: 5s
  retries: 3
```

**Custom Script:**
```yaml
healthcheck:
  test: ["CMD", "/healthcheck.sh"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Monitoring Stack Example

```yaml
# docker-compose/monitoring.yml
services:
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./config/prometheus:/etc/prometheus
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - monitoring-network

  grafana:
    image: grafana/grafana:10.2.2
    container_name: grafana
    restart: unless-stopped
    volumes:
      - grafana-data:/var/lib/grafana
    ports:
      - "3000:3000"
    networks:
      - monitoring-network
    depends_on:
      - prometheus

volumes:
  prometheus-data:
  grafana-data:

networks:
  monitoring-network:
    driver: bridge
```

## Troubleshooting

### Common Issues

#### Service Won't Start

**1. Check logs:**
```bash
docker compose -f docker-compose/service.yml logs
```

**2. Validate configuration:**
```bash
docker compose -f docker-compose/service.yml config
```

**3. Check for port conflicts:**
```bash
# See what's using a port
sudo netstat -tlnp | grep :8080
```

**4. Verify image exists:**
```bash
docker images | grep service-name
```

#### Permission Errors

**1. Check PUID/PGID:**
```bash
# Your user ID
id -u

# Your group ID
id -g
```

**2. Fix directory permissions:**
```bash
sudo chown -R 1000:1000 ./config/service-name
```

**3. Check volume permissions:**
```bash
docker compose -f docker-compose/service.yml exec service-name ls -la /config
```

#### Network Connectivity Issues

**1. Verify network exists:**
```bash
docker network ls
docker network inspect homelab-network
```

**2. Check if services are on same network:**
```bash
docker network inspect homelab-network | grep Name
```

**3. Test connectivity:**
```bash
docker compose -f docker-compose/service.yml exec service1 ping service2
```

#### Container Keeps Restarting

**1. Watch logs:**
```bash
docker compose -f docker-compose/service.yml logs -f
```

**2. Check health status:**
```bash
docker compose -f docker-compose/service.yml ps
```

**3. Inspect container:**
```bash
docker inspect container-name
```

### Debugging Commands

```bash
# Enter running container
docker compose -f docker-compose/service.yml exec service-name /bin/sh

# View full container configuration
docker inspect container-name

# See resource usage
docker stats container-name

# View recent events
docker events --since 10m

# Check disk space
docker system df
```

### Recovery Procedures

#### Service Corrupted

```bash
# Stop service
docker compose -f docker-compose/service.yml down

# Remove container and volumes (backup first!)
docker compose -f docker-compose/service.yml down -v

# Recreate from scratch
docker compose -f docker-compose/service.yml up -d
```

#### Network Issues

```bash
# Remove and recreate network
docker network rm homelab-network
docker network create homelab-network

# Restart services
docker compose -f docker-compose/*.yml up -d
```

#### Full System Reset (Nuclear Option)

```bash
# ⚠️ WARNING: This removes everything!
# Backup first!

# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all volumes (careful!)
docker volume rm $(docker volume ls -q)

# Remove all networks (except defaults)
docker network prune -f

# Rebuild from compose files
docker compose -f docker-compose/*.yml up -d
```

## Maintenance

### Regular Tasks

**Weekly:**
- Review logs for errors
- Check disk space: `docker system df`
- Update security patches on images

**Monthly:**
- Update images to latest versions
- Review and prune unused resources
- Backup volumes
- Review and optimize compose files

**Quarterly:**
- Full stack review
- Documentation update
- Performance optimization
- Security audit

### Update Procedure

```bash
# 1. Backup current state
docker compose -f docker-compose/service.yml config > backup/service-config.yml

# 2. Update image version in compose file
# Edit docker-compose/service.yml

# 3. Pull new image
docker compose -f docker-compose/service.yml pull

# 4. Recreate service
docker compose -f docker-compose/service.yml up -d

# 5. Verify
docker compose -f docker-compose/service.yml logs -f

# 6. Test functionality
# Access service and verify it works
```

## AI Automation Guidelines

### Homepage Dashboard Management

**Automatic Configuration Updates**

Homepage configuration must be kept synchronized with deployed services. The AI assistant handles this automatically:

**Template Location:**
- Config templates: `/home/kelin/AI-Homelab/config-templates/homepage/`
- Active configs: `/opt/stacks/homepage/config/`

**Key Principles:**

1. **Hard-Coded URLs Required**: Homepage does NOT support variables in href links
   - Template uses `{{HOMEPAGE_VAR_DOMAIN}}` as placeholder
   - Active config uses `kelin-hass.duckdns.org` hard-coded
   - AI must replace placeholders when deploying configs

2. **No Container Restart Needed**: Homepage picks up config changes instantly
   - Simply edit YAML files in `/opt/stacks/homepage/config/`
   - Refresh browser to see changes
   - DO NOT restart the container

3. **Stack-Based Organization**: Services grouped by their compose file
   - **Currently Installed**: Shows running services grouped by stack
   - **Available to Install**: Shows undeployed services from repository

4. **Automatic Updates Required**: AI must update Homepage configs when:
   - New service is deployed → Add to appropriate stack section
   - Service is removed → Remove from stack section
   - Domain/subdomain changes → Update all affected href URLs
   - Stack file is renamed → Update section headers

**Configuration Structure:**

```yaml
# services.yaml
- Stack Name (compose-file.yml):
    - Service Name:
        icon: service.png
        href: https://subdomain.kelin-hass.duckdns.org  # Hard-coded!
        description: Service description
```

**Deployment Workflow:**

```bash
# When deploying from template:
cp /home/kelin/AI-Homelab/config-templates/homepage/*.yaml /opt/stacks/homepage/config/
sed -i 's/{{HOMEPAGE_VAR_DOMAIN}}/kelin-hass.duckdns.org/g' /opt/stacks/homepage/config/services.yaml

# No restart needed - configs load instantly
```

**Critical Reminder:** Homepage is the single source of truth for service inventory. Keep it updated or users won't know what's deployed.

---

## Conclusion

Following these guidelines ensures:
- Consistent infrastructure
- Easy troubleshooting
- Reproducible deployments
- Maintainable system
- Better security

Remember: **Infrastructure as Code** means treating your Docker Compose files as critical documentation. Keep them clean, commented, and version-controlled.
