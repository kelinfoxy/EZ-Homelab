# AI-Homelab

AI-Powered Homelab Administration with GitHub Copilot

## Overview

This repository provides a comprehensive, production-ready homelab infrastructure using Docker Compose with Dockge, featuring 40+ pre-configured services. Integrated AI assistance through GitHub Copilot helps you create, modify, and manage Docker services while maintaining consistency across your entire server stack.

The infrastructure uses Traefik for reverse proxy with automatic SSL, Authelia for Single Sign-On, Gluetun for VPN routing, and DuckDNS for dynamic DNS - all managed through file-based configurations that the AI can modify.

## Features

- **AI-Powered Management**: GitHub Copilot integration with specialized instructions for Docker service management
- **Dockge Structure**: All stacks organized in `/opt/stacks/` for easy management via Dockge
- **40+ Pre-configured Services**: Production-ready compose files across infrastructure, media, home automation, productivity, and monitoring
- **Traefik Reverse Proxy**: Automatic HTTPS with Let's Encrypt via file-based configuration (no web UI needed)
- **Authelia SSO**: Single Sign-On protection for all admin interfaces with smart bypass rules for media apps
- **Gluetun VPN**: Surfshark WireGuard integration for secure downloads
- **Homepage Dashboard**: AI-configurable dashboard with Docker integration and service widgets
- **External Host Proxying**: Proxy external services (Raspberry Pi, routers, NAS) through Traefik
- **Stack-Aware Changes**: AI considers the entire infrastructure when making changes
- **Comprehensive Documentation**: Detailed guidelines including proxying external hosts
- **File-Based Configuration**: Everything managed via YAML files - no web UI dependencies

## Quick Start

### Prerequisites

- Docker Engine 24.0+ installed
- Docker Compose V2
- Git
- VS Code with GitHub Copilot extension (for AI assistance)
- A domain from DuckDNS (free)
- Surfshark VPN account (optional, for VPN features)
- Sufficient disk space: 120GB+ system drive (NVMe or SSD highly recommended), 2TB+ for media & additional disks for services like Nextcloud that require lots of space

### Quick Setup (Dockge Structure)

1. **Clone the repository:**
   ```bash
   # Note: Replace 'kelinfoxy' with your username if you forked this repository
   git clone https://github.com/kelinfoxy/AI-Homelab.git
   cd AI-Homelab
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your values (domain, API keys, passwords)
   nano .env
   ```

3. **Create required directories:**
   ```bash
   sudo mkdir -p /opt/stacks
   sudo chown -R $USER:$USER /opt/stacks
   ```

4. **Create Docker networks:**
   ```bash
   docker network create homelab-network
   docker network create traefik-network
   docker network create media-network
   ```

5. **Deploy core infrastructure stack:**
   ```bash
   # Deploy the unified core stack (DuckDNS, Traefik, Authelia, Gluetun)
   mkdir -p /opt/stacks/core
   cp docker-compose/core.yml /opt/stacks/core/docker-compose.yml
   cp -r config-templates/traefik /opt/stacks/core/
   cp -r config-templates/authelia /opt/stacks/core/
   
   # From within the directory
   cd /opt/stacks/core && docker compose up -d
   
   # OR from anywhere with full path
   docker compose -f /opt/stacks/core/docker-compose.yml up -d
   ```

6. **Deploy infrastructure stack (includes Dockge):**
   ```bash
   mkdir -p /opt/stacks/infrastructure
   cp docker-compose/infrastructure.yml /opt/stacks/infrastructure/docker-compose.yml
   cd /opt/stacks/infrastructure && docker compose up -d
   ```

7. **Access Dockge:**
   Open `https://dockge.yourdomain.duckdns.org` (use Authelia login)
   
   Now deploy remaining stacks through Dockge's UI!

## Repository Structure

```
AI-Homelab/
├── .github/
│   └── copilot-instructions.md    # AI assistant guidelines (Dockge, Traefik, Authelia aware)
├── docker-compose/
│   ├── traefik.yml                # Reverse proxy (deploy first)
│   ├── authelia.yml               # SSO authentication
│   ├── duckdns.yml                # Dynamic DNS
│   ├── gluetun.yml                # VPN client (Surfshark) + qBittorrent
│   ├── infrastructure.yml         # Dockge, Portainer, Pi-hole, Watchtower, Dozzle, Glances
│   ├── dashboards.yml             # Homepage, Homarr
│   ├── media.yml                  # Plex, Jellyfin, Sonarr, Radarr, Prowlarr
│   ├── media-extended.yml         # Readarr, Lidarr, Lazy Librarian, Mylar3, Calibre-Web, 
│   │                              # Jellyseerr, FlareSolverr, Tdarr, Unmanic
│   ├── homeassistant.yml          # Home Assistant, ESPHome, TasmoAdmin, Node-RED, 
│   │                              # Mosquitto, Zigbee2MQTT, MotionEye
│   ├── productivity.yml           # Nextcloud, Mealie, WordPress, Gitea, DokuWiki,
│   │                              # BookStack, MediaWiki (all with databases)
│   ├── utilities.yml              # Backrest, Duplicati, Uptime Kuma, Code Server, 
│   │                              # Form.io, Authelia-Redis
│   ├── monitoring.yml             # Prometheus, Grafana, Loki, Promtail, cAdvisor
│   ├── development.yml            # GitLab, PostgreSQL, Redis, pgAdmin, Jupyter
│   └── README-dockge.md           # Dockge deployment guide
├── config-templates/
│   ├── traefik/                   # Traefik static and dynamic configs
│   ├── authelia/                  # Authelia config and user database
│   ├── homepage/                  # Homepage dashboard configs (with widgets)
│   ├── prometheus/                # Prometheus scrape configs
│   ├── loki/                      # Loki log aggregation config
│   └── ...                        # Other service templates
├── docs/
│   ├── docker-guidelines.md       # Comprehensive Docker guidelines
│   ├── getting-started.md         # Step-by-step setup guide
│   ├── quick-reference.md         # Command reference
│   └── proxying-external-hosts.md # Guide for proxying Raspberry Pi, routers, etc.
├── .env.example                   # Environment variable template (40+ vars)
├── .gitignore                     # Git ignore patterns
└── README.md                      # This file
```

## Using the AI Assistant

### In VS Code

1. **Install GitHub Copilot** extension in VS Code
2. **Open this repository** in VS Code
3. **Start Copilot Chat** and ask questions like:
   - "Help me add a new media service to my homelab"
   - "Configure Traefik routing for my new service"
   - "Add Authelia SSO protection to this service"
   - "How do I proxy my Raspberry Pi through Traefik?"
   - "Create a Homepage widget for this service"
   - "Route this download client through Gluetun VPN"

The AI assistant automatically follows the guidelines in `.github/copilot-instructions.md` to:
- Use `/opt/stacks/` directory structure (Dockge compatible)
- Configure Traefik labels for automatic routing
- Apply Authelia middleware where appropriate
- Suggest `/mnt/` for large data storage
- Add services to Homepage dashboard with widgets
- Maintain consistency with existing services
- Consider the entire stack when making changes

### Example Interactions

**Adding a new service:**
```
You: "Add Tautulli to monitor my Plex server"

Copilot: [Creates compose configuration with]:
- /opt/stacks/tautulli/ directory structure
- Traefik labels for HTTPS access
- Authelia middleware for SSO protection
- Homepage dashboard entry with widget
- Connection to existing Plex service
```

**Proxying external service:**
```
You: "Proxy my Raspberry Pi Home Assistant through Traefik"

Copilot: [Creates Traefik route configuration]:
- File in /opt/stacks/traefik/dynamic/
- HTTPS with Let's Encrypt
- Authelia bypass (HA has its own auth)
- WebSocket support
- Homepage dashboard entry
```

**Configuring VPN routing:**
```
You: "Route SABnzbd through the VPN"

Copilot: [Updates compose to use Gluetun]:
- network_mode: "service:gluetun"
- Exposes ports through Gluetun
- Maintains Traefik routing
- Updates documentation
```

## Available Service Stacks

### Core Infrastructure (Required)

#### 1. Traefik (`traefik.yml`)
**Reverse proxy with automatic SSL** - Deploy first!
- Automatic HTTPS via Let's Encrypt
- File-based and Docker label routing
- HTTP to HTTPS redirect
- Dashboard at `https://traefik.${DOMAIN}`

#### 2. Authelia (`authelia.yml`)
**Single Sign-On authentication**
- TOTP 2FA support
- LDAP/file-based user database
- Smart bypass rules for media apps
- Login at `https://auth.${DOMAIN}`

#### 3. DuckDNS (`duckdns.yml`)
**Dynamic DNS updater**
- Automatic IP updates
- Integrates with Let's Encrypt
- No web UI - runs silently

#### 4. Gluetun (`gluetun.yml`)
**VPN client (Surfshark WireGuard)**
- Includes qBittorrent
- Download via `https://qbit.${DOMAIN}`
- Easy to route other services through VPN

### Infrastructure Tools (`infrastructure.yml`)

- **Dockge**: Docker Compose stack manager (PRIMARY) - `https://dockge.${DOMAIN}`
- **Portainer**: Docker management UI (secondary) - `https://portainer.${DOMAIN}`
- **Pi-hole**: Network-wide ad blocking - `https://pihole.${DOMAIN}`
- **Watchtower**: Automatic container updates
- **Dozzle**: Real-time Docker logs - `https://dozzle.${DOMAIN}`
- **Glances**: System monitoring - `https://glances.${DOMAIN}`
- **Docker Proxy**: Secure Docker socket access

### Dashboards (`dashboards.yml`)

- **Homepage**: AI-configurable dashboard with widgets - `https://home.${DOMAIN}`
  - Docker integration (container status)
  - Service widgets (Sonarr, Radarr, Plex, Jellyfin, etc.)
  - 11 organized categories
- **Homarr**: Modern alternative dashboard - `https://homarr.${DOMAIN}`

### Media Services (`media.yml`)

- **Plex**: Media streaming server - `https://plex.${DOMAIN}` (no SSO - app access)
- **Jellyfin**: Open-source media server - `https://jellyfin.${DOMAIN}` (no SSO - app access)
- **Sonarr**: TV show automation - `https://sonarr.${DOMAIN}`
- **Radarr**: Movie automation - `https://radarr.${DOMAIN}`
- **Prowlarr**: Indexer manager - `https://prowlarr.${DOMAIN}`
- **qBittorrent**: Torrent client (via VPN) - See gluetun.yml

### Extended Media (`media-extended.yml`)

- **Readarr**: Ebook/audiobook management - `https://readarr.${DOMAIN}`
- **Lidarr**: Music collection manager - `https://lidarr.${DOMAIN}`
- **Lazy Librarian**: Book download automation - `https://lazylibrarian.${DOMAIN}`
- **Mylar3**: Comic book manager - `https://mylar.${DOMAIN}`
- **Calibre-Web**: Ebook reader and server - `https://calibre.${DOMAIN}`
- **Jellyseerr**: Media request management - `https://jellyseerr.${DOMAIN}` (no SSO)
- **FlareSolverr**: Cloudflare bypass (no UI)
- **Tdarr**: Distributed transcoding - `https://tdarr.${DOMAIN}`
- **Unmanic**: Library optimizer - `https://unmanic.${DOMAIN}`

### Home Automation (`homeassistant.yml`)

- **Home Assistant**: Home automation hub - `https://ha.${DOMAIN}` (uses host network)
- **ESPHome**: ESP device manager - `https://esphome.${DOMAIN}`
- **TasmoAdmin**: Tasmota device manager - `https://tasmoadmin.${DOMAIN}`
- **Node-RED**: Flow automation - `https://nodered.${DOMAIN}`
- **Mosquitto**: MQTT broker (no UI)
- **Zigbee2MQTT**: Zigbee bridge - `https://zigbee2mqtt.${DOMAIN}`
- **MotionEye**: Video surveillance - `https://motioneye.${DOMAIN}`

### Productivity (`productivity.yml`)

- **Nextcloud**: File sync & collaboration - `https://nextcloud.${DOMAIN}`
  - Includes MariaDB database
- **Mealie**: Recipe manager - `https://mealie.${DOMAIN}` (no SSO)
- **WordPress**: Blog platform - `https://blog.${DOMAIN}` (no SSO - public)
  - Includes MariaDB database
- **Gitea**: Self-hosted Git - `https://git.${DOMAIN}`
  - Includes PostgreSQL database
- **DokuWiki**: File-based wiki - `https://wiki.${DOMAIN}`
- **BookStack**: Documentation platform - `https://docs.${DOMAIN}`
  - Includes MariaDB database
- **MediaWiki**: Wiki platform - `https://mediawiki.${DOMAIN}`
  - Includes MariaDB database

### Utilities (`utilities.yml`)

- **Backrest**: Backup manager (restic) - `https://backrest.${DOMAIN}`
- **Duplicati**: Backup software - `https://duplicati.${DOMAIN}`
- **Uptime Kuma**: Status monitoring - `https://status.${DOMAIN}` (no SSO - public)
- **Code Server**: VS Code in browser - `https://code.${DOMAIN}`
- **Form.io**: Form builder - `https://forms.${DOMAIN}`
  - Includes MongoDB database
- **Authelia-Redis**: Session storage (no UI)

### Monitoring (`monitoring.yml`)

- **Prometheus**: Metrics collection - `https://prometheus.${DOMAIN}`
- **Grafana**: Metrics visualization - `https://grafana.${DOMAIN}`
- **Loki**: Log aggregation
- **Promtail**: Log shipping
- **Node Exporter**: Host metrics
- **cAdvisor**: Container metrics

### Development (`development.yml`)

- **GitLab CE**: Git with CI/CD - `https://gitlab.${DOMAIN}`
- **PostgreSQL**: SQL database
- **Redis**: In-memory store
- **pgAdmin**: PostgreSQL UI - `https://pgadmin.${DOMAIN}`
- **Jupyter Lab**: Interactive notebooks - `https://jupyter.${DOMAIN}`

## Common Operations

### Managing Stacks via Dockge

Access Dockge at `https://dockge.${DOMAIN}` to:
- View all stacks and their status
- Start/stop/restart stacks
- Edit compose files directly
- View logs
- Deploy new stacks

### Command Line Operations

#### Starting Services (Dockge Structure)

```bash
# Start entire stack
cd /opt/stacks/media
docker compose up -d

# Start specific services
cd /opt/stacks/media
docker compose up -d sonarr radarr

# Start with rebuild
cd /opt/stacks/infrastructure
docker compose up -d --build
```

#### Stopping Services

```bash
# Stop entire stack
cd /opt/stacks/media
docker compose down

# Stop but keep volumes
cd /opt/stacks/media
docker compose stop

# Stop specific service
cd /opt/stacks/media
docker compose stop plex
```

#### Viewing Logs

```bash
# Follow logs for entire stack
cd /opt/stacks/media
docker compose logs -f

# Follow logs for specific service
cd /opt/stacks/media
docker compose logs -f plex

# View last 100 lines
cd /opt/stacks/media
docker compose logs --tail=100 plex

# Or use Dozzle web UI at https://dozzle.${DOMAIN}
```

#### Updating Services

```bash
# Pull latest images
cd /opt/stacks/media
docker compose pull

# Update specific service
cd /opt/stacks/media
docker compose pull plex
docker compose up -d plex

# Or enable Watchtower for automatic updates
```

### Testing with Docker Run

Use `docker run` only for temporary testing:

```bash
# Test NVIDIA GPU support
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# Test a new image
docker run --rm -it alpine:latest /bin/sh

# Test VPN connection through Gluetun
docker run --rm --network container:gluetun curlimages/curl ifconfig.me
```

## Network Architecture

Services connect to multiple networks for organization and security:

- **traefik-network**: For Traefik to reach services (external)
- **homelab-network**: Main network for inter-service communication (external)
- **media-network**: Isolated network for media stack (external)
- **monitoring-network**: Network for observability stack (created per stack)
- **database-network**: Isolated networks for database services (created per stack)
- **dockerproxy-network**: Secure Docker socket access (created in infrastructure)

### Creating Required Networks

```bash
# Create external networks (do this once)
docker network create traefik-network
docker network create homelab-network
docker network create media-network

# Stack-specific networks are created automatically by compose files
```

### Traefik Routing

All services accessed via Traefik with automatic HTTPS:
- Pattern: `https://service.yourdomain.duckdns.org`
- Configured via Docker labels on each service
- SSL certificates automatically managed
- No port exposure needed (except Traefik 80/443)

## Documentation

### Comprehensive Guides

- **[Docker Guidelines](docs/docker-guidelines.md)**: Complete guide to Docker service management with Dockge
- **[Getting Started](docs/getting-started.md)**: Step-by-step setup walkthrough
- **[Quick Reference](docs/quick-reference.md)**: Command reference and troubleshooting
- **[Dockge Deployment](docker-compose/README-dockge.md)**: Dockge-specific deployment guide
- **[Proxying External Hosts](docs/proxying-external-hosts.md)**: Guide for proxying Raspberry Pi, routers, NAS via Traefik
- **[Copilot Instructions](.github/copilot-instructions.md)**: AI assistant guidelines (Traefik, Authelia, Dockge aware)

### Key Principles

1. **Dockge Structure**: All stacks in `/opt/stacks/stack-name/`
2. **Docker Compose First**: Always use compose for persistent services
3. **Docker Run for Testing**: Only use `docker run` for temporary containers
4. **File-Based Configuration**: Traefik labels and Authelia YAML (AI-manageable)
5. **Traefik for All**: Every service routed through Traefik with automatic SSL
6. **Smart SSO**: Authelia protects admin interfaces, bypasses media apps for device access
7. **VPN When Needed**: Route download clients through Gluetun
8. **Large Data Separate**: Use `/mnt/` for media, downloads, large databases
9. **Stack Awareness**: Consider dependencies and interactions
10. **Security**: Keep secrets in `.env` files, never commit them

## Configuration Management

### Environment Variables

All services use variables from `.env` in each stack directory:
- `PUID`/`PGID`: User/group IDs for file permissions
- `TZ`: Timezone for all services
- `DOMAIN`: Your DuckDNS domain (e.g., yourdomain.duckdns.org)
- `SERVER_IP`: Your server's IP address
- Service-specific credentials and API keys
- Homepage widget API keys (40+ variables)

See `.env.example` for complete list.

### Storage Strategy

**Small Data** (configs, databases < 10GB): `/opt/stacks/stack-name/`
```yaml
volumes:
  - /opt/stacks/sonarr/config:/config
```

**Large Data** (media, downloads, backups): `/mnt/`
```yaml
volumes:
  - /mnt/media:/media
  - /mnt/downloads:/downloads
  - /mnt/backups:/backups
```

The AI will suggest when to use `/mnt/` based on expected data size.

### Configuration Files

Service configurations stored in stack directories:
```
/opt/stacks/
├── traefik/
│   ├── docker-compose.yml
│   ├── traefik.yml           # Static config
│   ├── dynamic/              # Dynamic routes
│   │   └── routes.yml
│   └── acme.json            # SSL certificates
├── authelia/
│   ├── docker-compose.yml
│   ├── configuration.yml     # Authelia settings
│   └── users_database.yml    # User accounts
├── homepage/
│   ├── docker-compose.yml
│   └── config/
│       ├── services.yaml     # Service definitions
│       ├── docker.yaml       # Docker integration
│       ├── settings.yaml     # Dashboard settings
│       └── widgets.yaml      # Homepage widgets
└── ...
```

Templates available in `config-templates/` directory.

## Security Best Practices

1. **Pin Image Versions**: Never use `:latest` in production
2. **Use Environment Variables**: Store secrets in `.env` (gitignored)
3. **Run as Non-Root**: Set PUID/PGID to match your user
4. **Limit Exposure**: Bind ports to localhost when possible
5. **Regular Updates**: Keep images updated via Watchtower
6. **Scan Images**: Use `docker scan` to check for vulnerabilities

## Troubleshooting

### Service Won't Start

1. Check logs: `docker compose -f file.yml logs service-name`
2. Validate config: `docker compose -f file.yml config`
3. Check port conflicts: `sudo netstat -tlnp | grep PORT`
4. Verify network exists: `docker network ls`

### Permission Issues

1. Check PUID/PGID match your user: `id -u` and `id -g`
2. Fix ownership: `sudo chown -R 1000:1000 ./config/service-name`

### Network Issues

1. Verify network exists: `docker network inspect homelab-network`
2. Test connectivity: `docker compose exec service1 ping service2`

### Getting Help

- Review the [Docker Guidelines](docs/docker-guidelines.md)
- Ask GitHub Copilot in VS Code
- Check service-specific documentation
- Review Docker logs for error messages

## Backup Strategy

### What to Backup

1. **Docker Compose files** (version controlled in git)
2. **Config directories**: `./config/*`
3. **Named volumes**: `docker volume ls`
4. **Environment file**: `.env` (securely, not in git)

### Backup Named Volumes

```bash
# Backup a volume
docker run --rm \
  -v volume-name:/data \
  -v $(pwd)/backups:/backup \
  busybox tar czf /backup/volume-backup.tar.gz /data
```

### Restore Named Volumes

```bash
# Restore a volume
docker run --rm \
  -v volume-name:/data \
  -v $(pwd)/backups:/backup \
  busybox tar xzf /backup/volume-backup.tar.gz -C /
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Follow existing patterns and conventions
4. Test your changes
5. Submit a pull request

## License

This project is provided as-is for personal homelab use.

## Acknowledgments

- Docker and Docker Compose communities
- LinuxServer.io for excellent container images
- GitHub Copilot for AI assistance capabilities
- All the open-source projects used in example compose files

## Getting Started Checklist

- [ ] Install Docker and Docker Compose V2
- [ ] Sign up for DuckDNS (free) and get your domain
- [ ] Get Surfshark VPN credentials (optional, for VPN features)
- [ ] Clone this repository
- [ ] Copy `.env.example` to `.env` and configure all values
- [ ] Create `/opt/stacks` directory: `sudo mkdir -p /opt/stacks && sudo chown $USER:$USER /opt/stacks`
- [ ] Create Docker networks: `docker network create traefik-network homelab-network media-network`
- [ ] Deploy DuckDNS stack
- [ ] Deploy Traefik stack (with config templates)
- [ ] Deploy Authelia stack (with config templates)
- [ ] Deploy infrastructure stack (Dockge)
- [ ] Access Dockge at `https://dockge.${DOMAIN}` and deploy remaining stacks
- [ ] Configure Homepage dashboard (copy templates to /opt/stacks/homepage/config/)
- [ ] Install VS Code with GitHub Copilot extension
- [ ] Open repository in VS Code and start using AI assistance

## Proxying External Hosts

You can proxy services running on other devices (Raspberry Pi, routers, NAS) through Traefik:

**Example: Raspberry Pi Home Assistant**
```yaml
# In /opt/stacks/traefik/dynamic/external.yml
http:
  routers:
    ha-pi:
      rule: "Host(`ha.yourdomain.duckdns.org`)"
      entryPoints:
        - websecure
      service: ha-pi
      tls:
        certResolver: letsencrypt
  
  services:
    ha-pi:
      loadBalancer:
        servers:
          - url: "http://192.168.1.50:8123"
```

See [docs/proxying-external-hosts.md](docs/proxying-external-hosts.md) for complete guide including:
- Three methods (file provider, Docker labels, hybrid)
- Authelia bypass configuration
- WebSocket support
- Examples for routers, NAS, cameras, Proxmox

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Consult the comprehensive [documentation](docs/docker-guidelines.md)
- Use GitHub Copilot in VS Code for real-time assistance
