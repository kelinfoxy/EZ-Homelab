# Dockge - Docker Compose Stack Manager

## Table of Contents
- [Overview](#overview)
- [What is Dockge?](#what-is-dockge)
- [Why Use Dockge?](#why-use-dockge)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Managing Stacks](#managing-stacks)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Infrastructure Management  
**Docker Image:** [louislam/dockge](https://hub.docker.com/r/louislam/dockge)  
**Default Stack:** `infrastructure.yml`  
**Web UI:** `https://dockge.${DOMAIN}`  
**Authentication:** SSO via Authelia (automatic login)

## What is Dockge?

Dockge is a modern, self-hosted Docker Compose stack manager with a beautiful web UI. Created by the developer of Uptime Kuma, it provides a user-friendly interface for managing Docker Compose stacks with features like terminal access, log viewing, and real-time editing.

### Key Features
- **Visual Stack Management:** View all stacks, services, and containers at a glance
- **Interactive Compose Editor:** Edit docker-compose.yml files with syntax highlighting
- **Built-in Terminal:** Execute commands directly in containers
- **Real-time Logs:** Stream and search container logs
- **One-Click Actions:** Start, stop, restart, update services easily
- **Agent Mode:** Manage Docker on remote servers
- **File-based Storage:** All stacks stored as compose files on disk
- **Git Integration:** Push/pull stacks to Git repositories
- **No Database Required:** Lightweight, direct file manipulation
- **Modern UI:** Clean, responsive interface

## Why Use Dockge?

1. **Primary Management Tool:** AI-Homelab's main stack manager
2. **User-Friendly:** Much simpler than Portainer for compose stacks
3. **Direct File Access:** Edit compose files directly (no abstraction)
4. **Quick Deployment:** Create and deploy stacks in seconds
5. **Visual Feedback:** See container status, resource usage
6. **Terminal Access:** Execute commands without SSH
7. **Log Management:** View, search, and download logs easily
8. **Lightweight:** Minimal resource usage
9. **Active Development:** Regular updates and improvements

## How It Works

```
User → Web Browser → Dockge UI
                         ↓
                   Compose Files
                (/opt/stacks/...)
                         ↓
                   Docker Engine
                         ↓
              Running Containers
```

### Stack Management Flow

1. **Create/Edit** compose file in Dockge UI or text editor
2. **Deploy** stack with one click
3. **Monitor** services, logs, and resources
4. **Update** services by pulling new images
5. **Manage** individual containers (start/stop/restart)
6. **Access** terminals for troubleshooting

### File Structure

Dockge uses a simple directory structure:
```
/opt/stacks/
├── core/
│   └── compose.yaml
├── infrastructure/
│   └── compose.yaml
├── media/
│   └── compose.yaml
└── dashboards/
    └── compose.yaml
```

Each folder is a "stack" with its compose file and volumes.

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/
├── core/              # Core infrastructure stack
├── infrastructure/    # Management and monitoring
├── dashboards/        # Homepage, Homarr
├── media/             # Plex, Sonarr, Radarr, etc.
├── media-extended/    # Additional media services
├── homeassistant/     # Home automation
├── productivity/      # Nextcloud, Gitea, etc.
├── utilities/         # Vaultwarden, backups
├── monitoring/        # Prometheus, Grafana
└── development/       # GitLab, dev tools
```

### Environment Variables

```bash
# Dockge Configuration
DOCKGE_STACKS_DIR=/opt/stacks
DOCKGE_ENABLE_CONSOLE=true

# SSO Integration with Authelia
DOCKGE_AUTH_PROXY_HEADER=Remote-User
DOCKGE_AUTH_PROXY_AUTO_CREATE=true
DOCKGE_AUTH_PROXY_LOGOUT_URL=https://auth.${DOMAIN}/logout
```

### SSO Authentication

Dockge integrates with Authelia for Single Sign-On (SSO) authentication:

**How it works:**
1. Traefik forwards requests to Authelia for authentication
2. Authelia sets the `Remote-User` header with authenticated username
3. Dockge reads this header and automatically logs in the user
4. Users are created automatically on first login
5. Logout redirects to Authelia's logout page

**Benefits:**
- No separate Dockge login required
- Centralized user management through Authelia
- Automatic user provisioning
- Secure logout handling

**Configuration:**
- `DOCKGE_AUTH_PROXY_HEADER=Remote-User`: Header set by Authelia
- `DOCKGE_AUTH_PROXY_AUTO_CREATE=true`: Create users automatically
- `DOCKGE_AUTH_PROXY_LOGOUT_URL`: Redirect to Authelia logout

## Official Resources

- **Website:** https://dockge.kuma.pet
- **GitHub:** https://github.com/louislam/dockge
- **Docker Hub:** https://hub.docker.com/r/louislam/dockge
- **Documentation:** https://github.com/louislam/dockge/wiki
- **Discord Community:** https://discord.gg/3xBrKN66
- **Related:** Uptime Kuma (by same developer)

## Educational Resources

### Videos
- [Dockge - BEST Docker Compose Manager? (Techno Tim)](https://www.youtube.com/watch?v=AWAlOQeNpgU)
- [Dockge vs Portainer - Which is Better?](https://www.youtube.com/results?search_query=dockge+vs+portainer)
- [Docker Compose Tutorial (NetworkChuck)](https://www.youtube.com/watch?v=DM65_JyGxCo)
- [Dockge Setup and Features (DB Tech)](https://www.youtube.com/watch?v=FY7-KpTbkI8)

### Articles & Guides
- [Dockge Official Documentation](https://github.com/louislam/dockge/wiki)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockge vs Portainer Comparison](https://www.reddit.com/r/selfhosted/comments/17kp3d7/dockge_vs_portainer/)
- [Why You Need a Docker UI](https://www.smarthomebeginner.com/docker-gui-portainer-vs-dockge/)

### Concepts to Learn
- **Docker Compose:** Tool for defining multi-container applications
- **Stacks:** Collection of services defined in compose file
- **Services:** Individual containers within a stack
- **Volumes:** Persistent storage for containers
- **Networks:** Container networking and communication
- **Environment Variables:** Configuration passed to containers
- **Health Checks:** Automated service monitoring

## Docker Configuration

### Complete Service Definition

```yaml
dockge:
  image: louislam/dockge:latest
  container_name: dockge
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "5001:5001"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - /opt/stacks:/opt/stacks
    - /opt/dockge/data:/app/data
  environment:
    - DOCKGE_STACKS_DIR=/opt/stacks
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.dockge.rule=Host(`dockge.${DOMAIN}`)"
    - "traefik.http.routers.dockge.entrypoints=websecure"
    - "traefik.http.routers.dockge.tls.certresolver=letsencrypt"
    - "traefik.http.routers.dockge.middlewares=authelia@docker"
    - "traefik.http.services.dockge.loadbalancer.server.port=5001"
```

### Important Volumes

1. **Docker Socket:**
   ```yaml
   - /var/run/docker.sock:/var/run/docker.sock
   ```
   Required for Docker control. Security consideration: grants full Docker access.

2. **Stacks Directory:**
   ```yaml
   - /opt/stacks:/opt/stacks
   ```
   Where all compose files are stored. Must match DOCKGE_STACKS_DIR.

3. **Data Directory:**
   ```yaml
   - /opt/dockge/data:/app/data
   ```
   Stores Dockge configuration and settings.

## Managing Stacks

### Creating a New Stack

1. **Via Dockge UI:**
   - Click "Compose" button
   - Name your stack (e.g., "myapp")
   - Paste or write compose configuration
   - Click "Deploy"

2. **Via File System:**
   ```bash
   mkdir /opt/stacks/myapp
   nano /opt/stacks/myapp/compose.yaml
   # Dockge will auto-detect the new stack
   ```

### Stack Operations

**From Dockge UI:**
- **Start:** Green play button
- **Stop:** Red stop button
- **Restart:** Circular arrow
- **Update:** Pull latest images and recreate
- **Delete:** Remove stack (keeps volumes unless specified)
- **Edit:** Modify compose file
- **Terminal:** Access container shell
- **Logs:** View real-time logs

### Editing Stacks

1. Click on stack name
2. Click "Edit Compose" button
3. Modify yaml configuration
4. Click "Save & Update" or "Save"
5. Dockge will apply changes automatically

### Accessing Container Terminals

1. Click on stack
2. Click on service/container
3. Click "Terminal" button
4. Execute commands in interactive shell

### Viewing Logs

1. Click on stack
2. Click on service/container
3. Click "Logs" button
4. Real-time log streaming
5. Search logs with filter box

## Advanced Topics

### Agent Mode (Remote Management)

Manage Docker on remote servers from single Dockge instance:

**On Remote Server:**
```yaml
dockge-agent:
  image: louislam/dockge:latest
  container_name: dockge-agent
  restart: unless-stopped
  ports:
    - "5002:5002"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - /opt/stacks:/opt/stacks
  environment:
    - DOCKGE_AGENT_HOST=0.0.0.0
    - DOCKGE_AGENT_PORT=5002
```

**In Main Dockge:**
Settings → Agents → Add Agent
- Host: remote-server-ip
- Port: 5002

### Git Integration

Sync stacks with Git repository:

1. **Initialize Git in stack directory:**
   ```bash
   cd /opt/stacks/mystack
   git init
   git remote add origin https://github.com/user/repo.git
   ```

2. **Use Dockge UI:**
   - Click "Git" button in stack view
   - Pull/Push changes
   - View commit history

### Environment File Management

Store secrets in `.env` files:

```bash
# /opt/stacks/mystack/.env
MYSQL_ROOT_PASSWORD=supersecret
API_KEY=abc123xyz
```

Reference in compose file:
```yaml
services:
  myapp:
    environment:
      - DB_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - API_KEY=${API_KEY}
```

### Stack Dependencies

Order stack startup:
```yaml
services:
  webapp:
    depends_on:
      - database
      - redis
```

### Health Checks

Monitor service health:
```yaml
services:
  webapp:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Resource Limits

Prevent services from consuming too many resources:
```yaml
services:
  webapp:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
```

## Troubleshooting

### Dockge Won't Start

```bash
# Check if port 5001 is in use
sudo lsof -i :5001

# Check Docker socket permissions
ls -la /var/run/docker.sock

# View Dockge logs
docker logs dockge

# Verify stacks directory exists
ls -la /opt/stacks
```

### Stack Won't Deploy

```bash
# Check compose file syntax
cd /opt/stacks/mystack
docker compose config

# View detailed deployment logs
docker logs dockge

# Check for port conflicts
docker ps | grep PORT_NUMBER

# Verify network exists
docker network ls | grep traefik-network
```

### Can't Access Container Terminal

```bash
# Check if container is running
docker ps | grep container-name

# Verify container has shell
docker exec container-name which bash
docker exec container-name which sh

# Try manual terminal access
docker exec -it container-name /bin/bash
```

### Stack Shows Wrong Status

```bash
# Refresh Dockge
# Click the refresh icon in UI

# Or restart Dockge
docker restart dockge

# Check actual container status
docker ps -a
```

### Changes Not Applying

```bash
# Force recreate containers
cd /opt/stacks/mystack
docker compose up -d --force-recreate

# Or in Dockge UI:
# Click "Update" button (pulls images and recreates)
```

### Permission Issues

```bash
# Fix stacks directory permissions
sudo chown -R 1000:1000 /opt/stacks

# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
# Or add user to docker group:
sudo usermod -aG docker $USER
```

### High Memory Usage

```bash
# Check container resource usage
docker stats

# Add resource limits to services (see Advanced Topics)

# Prune unused resources
docker system prune -a
```

## Security Considerations

### Docker Socket Access

**Risk:** Full Docker socket access = root access to host
```yaml
- /var/run/docker.sock:/var/run/docker.sock
```

**Mitigations:**
1. **Use Authelia:** Always protect Dockge with authentication
2. **Use Docker Socket Proxy:** Limit socket access (see docker-proxy.md)
3. **Restrict Access:** Only trusted admins should access Dockge
4. **Network Security:** Never expose Dockge to internet without VPN/Authelia

### Best Practices

1. **Authentication:** Always use Authelia or similar
2. **HTTPS Only:** Never access Dockge over plain HTTP
3. **Strong Passwords:** Use strong credentials for all services
4. **Environment Files:** Store secrets in `.env` files, not compose
5. **Regular Updates:** Keep Dockge and services updated
6. **Backup Stacks:** Regular backups of `/opt/stacks`
7. **Log Monitoring:** Review logs for suspicious activity
8. **Least Privilege:** Don't run containers as root when possible
9. **Network Isolation:** Use separate networks for different stacks
10. **Audit Access:** Know who has access to Dockge

## Comparison with Alternatives

### Dockge vs Portainer

**Dockge Advantages:**
- Simpler interface
- Direct file manipulation
- Built-in terminal
- Faster for compose stacks
- No database required
- Better for small/medium deployments

**Portainer Advantages:**
- More features (users, teams, rbac)
- Kubernetes support
- Better for large enterprises
- More established project
- Advanced networking UI

### Dockge vs CLI (docker compose)

**Dockge Advantages:**
- Visual feedback
- Easier for beginners
- Quick access to logs/terminals
- One-click operations
- Remote management

**CLI Advantages:**
- Scriptable
- Faster for experts
- No additional resource usage
- More control

## Tips & Tricks

### Quick Stack Creation

Use templates for common services:
```bash
# Create template directory
mkdir /opt/stacks/templates

# Copy common compose files
cp /opt/stacks/media/compose.yaml /opt/stacks/templates/media-template.yaml
```

### Bulk Operations

```bash
# Start all stacks
cd /opt/stacks
for dir in */; do cd "$dir" && docker compose up -d && cd ..; done

# Stop all stacks
for dir in */; do cd "$dir" && docker compose down && cd ..; done

# Update all stacks
for dir in */; do cd "$dir" && docker compose pull && docker compose up -d && cd ..; done
```

### Stack Naming

Use clear, descriptive names:
- ✅ `media`, `dashboards`, `productivity`
- ❌ `stack1`, `test`, `mystack`

### Organize by Function

Group related services in stacks:
- **Core:** Essential infrastructure
- **Media:** Entertainment services
- **Productivity:** Work-related tools
- **Development:** Dev environments

## Summary

Dockge is AI-Homelab's primary management interface. It provides:
- Visual stack management with modern UI
- Direct compose file editing
- Real-time logs and terminals
- Simple deployment workflow
- Lightweight and fast
- Perfect balance of simplicity and power

As the main tool you'll use to manage your homelab, take time to familiarize yourself with Dockge's interface. It makes complex Docker operations simple and provides visual feedback that helps understand your infrastructure at a glance.

**Remember:**
- Dockge is for stack management, Portainer is backup
- Always use Authelia protection
- Keep compose files organized
- Regular backups of `/opt/stacks`
- Monitor resource usage
- Review logs regularly
