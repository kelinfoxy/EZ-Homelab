# Portainer - Docker Management Platform

## Table of Contents
- [Overview](#overview)
- [What is Portainer?](#what-is-portainer)
- [Why Use Portainer?](#why-use-portainer)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Using Portainer](#using-portainer)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Infrastructure Management  
**Docker Image:** [portainer/portainer-ce](https://hub.docker.com/r/portainer/portainer-ce)  
**Default Stack:** `infrastructure.yml`  
**Web UI:** `https://portainer.${DOMAIN}`  
**Authentication:** Built-in (admin/password) + Authelia protection  
**Role:** Secondary management tool (Dockge is primary)

## What is Portainer?

Portainer is a comprehensive Docker and Kubernetes management platform with an intuitive web interface. It provides enterprise-grade features for managing containers, images, networks, volumes, and more across single hosts or entire clusters.

### Key Features
- **Full Docker Management:** Containers, images, networks, volumes, stacks
- **User Management:** Multi-user support with role-based access control (RBAC)
- **Kubernetes Support:** Manage K8s clusters (Community Edition)
- **App Templates:** One-click deployment of popular applications
- **Registry Management:** Connect to Docker registries
- **Resource Monitoring:** CPU, memory, network usage
- **Container Console:** Web-based terminal access
- **Webhooks:** Automated deployments via webhooks
- **Environment Management:** Manage multiple Docker hosts
- **Team Collaboration:** Share environments with teams

## Why Use Portainer?

1. **Backup Management Tool:** When Dockge has issues
2. **Advanced Features:** User management, registries, templates
3. **Detailed Information:** More comprehensive stats and info
4. **Image Management:** Better interface for managing images
5. **Network Visualization:** See container networking
6. **Volume Management:** Easy volume backup/restore
7. **Established Platform:** Mature, well-documented, large community
8. **Enterprise Option:** Can upgrade to Business Edition if needed

## How It Works

```
User → Web Browser → Portainer UI
                         ↓
                   Docker Socket
                         ↓
                   Docker Engine
                         ↓
              All Docker Resources
         (Containers, Images, Networks, Volumes)
```

### Architecture

Portainer consists of:
1. **Portainer Server:** Main application with web UI
2. **Docker Socket:** Connection to Docker Engine
3. **Portainer Agent:** Optional, for managing remote hosts
4. **Database:** Stores configuration, users, settings

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/infrastructure/portainer/
└── data/          # Portainer database and config (auto-created)
```

### Initial Setup

**First Login:**
1. Access `https://portainer.yourdomain.com`
2. Create admin account (username: admin)
3. Choose "Docker" environment
4. Select "Connect via Docker socket"

### Environment Variables

```bash
# No environment variables typically needed
# Configuration done through Web UI
```

## Official Resources

- **Website:** https://www.portainer.io
- **Documentation:** https://docs.portainer.io
- **Community Edition:** https://www.portainer.io/portainer-ce
- **GitHub:** https://github.com/portainer/portainer
- **Docker Hub:** https://hub.docker.com/r/portainer/portainer-ce
- **Forum:** https://community.portainer.io
- **YouTube:** https://www.youtube.com/c/portainerio

## Educational Resources

### Videos
- [Portainer - Docker Management Made Easy (Techno Tim)](https://www.youtube.com/watch?v=ljDI5jykjE8)
- [Portainer Full Tutorial (NetworkChuck)](https://www.youtube.com/watch?v=iX0HbrfRyvc)
- [Portainer vs Dockge Comparison](https://www.youtube.com/results?search_query=portainer+vs+dockge)
- [Advanced Portainer Features (DB Tech)](https://www.youtube.com/watch?v=8q9k1qzXRk4)

### Articles & Guides
- [Portainer Official Documentation](https://docs.portainer.io)
- [Getting Started with Portainer](https://docs.portainer.io/start/install-ce)
- [Portainer vs Dockge](https://www.reddit.com/r/selfhosted/comments/17kp3d7/dockge_vs_portainer/)
- [Docker Management Best Practices](https://docs.docker.com/config/daemon/)

### Concepts to Learn
- **Docker Management:** Centralized control of Docker resources
- **RBAC:** Role-Based Access Control for teams
- **Stacks:** Docker Compose deployments via UI
- **Templates:** Pre-configured app deployments
- **Registries:** Docker image repositories
- **Environments:** Multiple Docker hosts managed together
- **Agents:** Remote Docker host management

## Docker Configuration

### Complete Service Definition

```yaml
portainer:
  image: portainer/portainer-ce:latest
  container_name: portainer
  restart: unless-stopped
  security_opt:
    - no-new-privileges:true
  networks:
    - traefik-network
  ports:
    - "9443:9443"   # HTTPS UI
    - "8000:8000"   # Edge agent (optional)
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - /opt/stacks/infrastructure/portainer/data:/data
  environment:
    - TZ=America/New_York
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.portainer.rule=Host(`portainer.${DOMAIN}`)"
    - "traefik.http.routers.portainer.entrypoints=websecure"
    - "traefik.http.routers.portainer.tls.certresolver=letsencrypt"
    - "traefik.http.routers.portainer.middlewares=authelia@docker"
    - "traefik.http.services.portainer.loadbalancer.server.port=9443"
    - "traefik.http.services.portainer.loadbalancer.server.scheme=https"
```

### Important Notes

1. **Port 9443:** HTTPS UI (Portainer uses self-signed cert internally)
2. **Docker Socket:** Read-only mount recommended for security
3. **Data Volume:** Stores all Portainer configuration
4. **Edge Agent Port:** 8000 for remote agent connections (optional)

## Using Portainer

### Dashboard Overview

**Home Dashboard Shows:**
- Total containers (running, stopped)
- Total images
- Total volumes
- Total networks
- Stack count
- Resource usage (CPU, memory)

### Container Management

**View Containers:**
- Home → Containers
- See all containers with status
- Quick actions: start, stop, restart, remove

**Container Details:**
- Logs (real-time and download)
- Stats (CPU, memory, network)
- Console (terminal access)
- Inspect (full container JSON)
- Recreate (update container)

**Container Actions:**
1. **Start/Stop/Restart:** One-click control
2. **Logs:** View stdout/stderr output
3. **Stats:** Real-time resource usage
4. **Exec Console:** Access container shell
5. **Duplicate:** Create copy with same config
6. **Recreate:** Pull new image and restart

### Stack Management

**Deploy Stack:**
1. Stacks → Add Stack
2. Name your stack
3. Choose method:
   - Web editor (paste compose)
   - Upload compose file
   - Git repository
4. Click "Deploy the stack"

**Manage Existing Stacks:**
- View all services in stack
- Edit compose configuration
- Stop/Start entire stack
- Remove stack (keep/delete volumes)

### Image Management

**Images View:**
- All local images
- Size and tags
- Pull new images
- Remove unused images
- Build from Dockerfile
- Import/Export images

**Common Operations:**
```
Pull Image: Images → Pull → Enter image:tag
Remove Image: Images → Select → Remove
Build Image: Images → Build → Upload Dockerfile
```

### Network Management

**View Networks:**
- All Docker networks
- Connected containers
- Network driver type
- Subnet information

**Create Network:**
1. Networks → Add Network
2. Name and driver (bridge, overlay)
3. Configure subnet/gateway
4. Attach containers

### Volume Management

**View Volumes:**
- All Docker volumes
- Size and mount points
- Containers using volume

**Volume Operations:**
- Create new volumes
- Remove unused volumes
- Browse volume contents
- Backup/restore volumes

### App Templates

**Quick Deploy:**
1. App Templates
2. Select application
3. Configure settings
4. Deploy

**Popular Templates:**
- WordPress, MySQL, Redis
- Nginx, Apache
- PostgreSQL, MongoDB
- And many more...

## Advanced Topics

### User Management

**Create Users:**
1. Users → Add User
2. Username and password
3. Assign role
4. Set team membership (if teams exist)

**Roles:**
- **Administrator:** Full access
- **Operator:** Manage containers, no settings
- **User:** Limited access to assigned resources
- **Read-only:** View only

### Team Collaboration

**Create Team:**
1. Teams → Add Team
2. Name team
3. Add members
4. Assign resource access

**Use Case:**
- Family team: Access to media services
- Admin team: Full access
- Guest team: Limited access

### Registry Management

**Add Private Registry:**
1. Registries → Add Registry
2. Choose type (Docker Hub, GitLab, custom)
3. Enter credentials
4. Test connection

**Use Cases:**
- Private Docker Hub repos
- GitHub Container Registry
- Self-hosted registry
- GitLab Registry

### Webhooks

**Automated Deployments:**
1. Select container/stack
2. Create webhook
3. Copy webhook URL
4. Configure in CI/CD pipeline

**Example:**
```bash
# Trigger container update
curl -X POST https://portainer.domain.com/api/webhooks/abc123
```

### Multiple Environments

**Add Remote Docker Host:**
1. Environments → Add Environment
2. Choose "Docker" or "Agent"
3. Enter connection details
4. Test and save

**Agent Deployment:**
```yaml
portainer-agent:
  image: portainer/agent:latest
  ports:
    - "9001:9001"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - /var/lib/docker/volumes:/var/lib/docker/volumes
```

### Custom Templates

**Create Template:**
1. App Templates → Custom Templates
2. Add template
3. Define compose configuration
4. Set categories and logo
5. Save

### Resource Limits

Set container limits in Portainer UI:
1. Edit container
2. Resources & Runtime
3. Set CPU/memory limits
4. Apply changes

## Troubleshooting

### Can't Access Portainer

```bash
# Check if running
docker ps | grep portainer

# View logs
docker logs portainer

# Check port
curl -k https://localhost:9443

# Verify Traefik routing
docker logs traefik | grep portainer
```

### Forgot Admin Password

```bash
# Stop Portainer
docker stop portainer

# Remove admin user from DB
docker run --rm -v portainer_data:/data portainer/portainer-ce \
  --admin-password 'NewPassword123!'

# Or reset completely (deletes all data)
docker stop portainer
docker rm portainer
docker volume rm portainer_data
docker compose up -d portainer
```

### Stacks Not Visible

```bash
# Portainer looks for compose files in specific location
# It doesn't automatically detect all stacks like Dockge

# Import existing stacks:
# Stacks → Add Stack → Web Editor → Paste compose content
```

### Container Terminal Not Working

```bash
# Ensure container has shell
docker exec container-name which bash

# Check Portainer logs
docker logs portainer | grep console

# Try different shell
# In Portainer: Console → Command → /bin/sh
```

### High Memory Usage

```bash
# Portainer uses more resources than Dockge
# Check stats
docker stats portainer

# If too high:
# - Close unused browser tabs
# - Restart Portainer
# - Reduce polling frequency (Settings)
```

### Database Corruption

```bash
# Backup first
cp -r /opt/stacks/infrastructure/portainer/data /opt/backups/

# Stop and recreate
docker stop portainer
docker rm portainer
docker volume rm portainer_data
docker compose up -d portainer
```

## Security Considerations

### Best Practices

1. **Strong Admin Password:** Use complex password
2. **Enable HTTPS:** Always use SSL/TLS
3. **Use Authelia:** Add extra authentication layer
4. **Limit Docker Socket:** Use read-only when possible
5. **Regular Updates:** Keep Portainer updated
6. **User Management:** Create separate users, avoid sharing admin
7. **RBAC:** Use role-based access for teams
8. **Audit Logs:** Review activity logs regularly
9. **Network Isolation:** Don't expose to internet without protection
10. **Backup Configuration:** Regular backups of `/data` volume

### Docker Socket Security

**Risk:** Full socket access = root on host

**Mitigations:**
- Use Docker Socket Proxy (see docker-proxy.md)
- Read-only mount when possible
- Limit user access to Portainer
- Monitor audit logs
- Use Authelia for additional authentication

## Portainer vs Dockge

### When to Use Portainer

- Need user management (teams, RBAC)
- Managing multiple Docker hosts
- Want app templates
- Need detailed image management
- Enterprise features required
- More established, proven platform

### When to Use Dockge

- Simple stack management
- Direct file manipulation preferred
- Lighter resource usage
- Faster for compose operations
- Better terminal experience
- Cleaner, modern UI

### AI-Homelab Approach

- **Primary:** Dockge (daily operations)
- **Secondary:** Portainer (backup, advanced features)
- **Use Both:** They complement each other

## Tips & Tricks

### Quick Container Recreate

To update a container with new image:
1. Containers → Select container
2. Click "Recreate"
3. Check "Pull latest image"
4. Click "Recreate"

### Volume Backup

1. Volumes → Select volume
2. Export/Backup
3. Download tar archive
4. Store safely

### Stack Migration

Export from one host, import to another:
1. Select stack
2. Copy compose content
3. On new host: Add Stack → Paste
4. Deploy

### Environment Variables

Set globally for all stacks:
1. Stacks → Select stack → Editor
2. Environment variables section
3. Add key=value pairs
4. Update stack

## Summary

Portainer is your backup Docker management platform. It provides:
- Comprehensive Docker management
- User and team collaboration
- Advanced features for complex setups
- Reliable, established platform
- Detailed resource monitoring

While Dockge is the primary tool for daily stack management, Portainer excels at:
- User management and RBAC
- Multiple environment management
- Detailed image and volume operations
- Template-based deployments
- Enterprise-grade features

Keep both running - they serve different purposes and complement each other well. Use Dockge for quick stack operations and Portainer for advanced features and user management.

**Remember:**
- Portainer is backup/secondary tool in AI-Homelab
- Different interface philosophy than Dockge
- More features, higher resource usage
- Excellent for multi-user scenarios
- Always protect with Authelia
- Regular backups of `/data` volume
