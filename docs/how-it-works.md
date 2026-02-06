# How Your AI Homelab Works

Welcome to your AI-powered homelab! This guide explains how all the components work together to create a production-ready, self-managing infrastructure. Don't worry if it seems complex at first - the AI assistant handles most of the technical details for you.

## Quick Overview

Your homelab is a **Docker-based infrastructure** that automatically:
- Provides secure HTTPS access to all services
- Manages user authentication and authorization
- Routes traffic intelligently
- Updates itself
- Backs up your data
- Monitors system health
- **Scales across multiple servers**

Everything runs in **containers** - like lightweight virtual machines - that are orchestrated by **Docker Compose** and managed through the **Dockge** web interface.

## Single-Server vs Multi-Server

EZ-Homelab supports two deployment architectures:

### Single Server
- All services run on one machine
- Traefik and Sablier manage local services only
- Simplest setup for homelab beginners
- Ideal for: Single desktop/server, all services in one place

### Multi-Server
- **Core Server**: Handles external traffic (ports 80/443), runs DuckDNS/Traefik/Authelia
- **Remote Servers**: Run their own Traefik/Sablier for local container management
- Unified domain access: All services through `service.yourdomain.com`
- Servers communicate via HTTP/HTTPS (no Docker API TLS needed)
- Ideal for: Raspberry Pi clusters, NAS + desktop, distributed workloads

**This guide covers both architectures**, with multi-server notes where relevant.

## Core Components

### 🏠 **Homepage Dashboard** (`https://homepage.yourdomain.duckdns.org`)
Your central hub for accessing all services. Think of it as the "start menu" for your homelab.
- **What it does**: Shows all your deployed services with quick links
- **AI Integration**: The AI can automatically add new services and configure widgets
- **Customization**: Add weather, system stats, and service-specific widgets
- **Configuration**: [docker-compose/dashboards/](docker-compose/dashboards/) | [service-docs/homepage.md](service-docs/homepage.md)

### 🐳 **Dockge** (`https://dockge.servername.yourdomain.duckdns.org`)
Your primary management interface for deploying and managing services.
- **What it does**: Web-based Docker Compose manager
- **Stacks**: Groups services into logical units (media, monitoring, productivity)
- **One-Click Deploy**: Upload compose files and deploy instantly
- **Multi-Server**: Deploy on core or remote servers from one interface
- **Configuration**: [docker-compose/dockge/](docker-compose/dockge/) | [service-docs/dockge.md](service-docs/dockge.md)

### 🔐 **Authelia** (`https://auth.yourdomain.duckdns.org`)
Your security gatekeeper that protects sensitive services.
- **What it does**: Single sign-on (SSO) authentication
- **Security**: Two-factor authentication, session management
- **Smart Bypass**: Automatically bypasses auth for media apps (Plex, Jellyfin)
- **Multi-Server**: Core server only; protects all services across all servers
- **Configuration**: [docker-compose/core/](docker-compose/core/) | [service-docs/authelia.md](service-docs/authelia.md)

### 🌐 **Traefik** (`https://traefik.servername.yourdomain.duckdns.org`)
Your intelligent traffic director and SSL certificate manager.
- **What it does**: Reverse proxy that routes web traffic to the right services
- **SSL**: Automatically obtains and renews free HTTPS certificates
- **Labels**: Services "advertise" themselves to Traefik via Docker labels
- **Multi-Server**: Core uses multi-provider (labels + YAML files); remote servers use labels only
- **Configuration**: [docker-compose/core/](docker-compose/core/) | [service-docs/traefik.md](service-docs/traefik.md)

### 🦆 **DuckDNS**
Your dynamic DNS service that gives your homelab a consistent domain name.
- **What it does**: Updates `yourdomain.duckdns.org` to point to your home IP
- **Integration**: Works with Traefik to get wildcard SSL certificates
- **Multi-Server**: Core server only (one domain for all servers)
- **Configuration**: [docker-compose/core/](docker-compose/core/) | [service-docs/duckdns.md](service-docs/duckdns.md)

### 🛡️ **Gluetun (VPN)**
Your download traffic protector.
- **What it does**: Routes torrent and download traffic through VPN
- **Security**: Prevents ISP throttling and hides your IP for downloads
- **Integration**: Download services connect through Gluetun's network
- **Configuration**: [docker-compose/core/](docker-compose/core/) | [service-docs/gluetun.md](service-docs/gluetun.md)

## How Services Get Added

### The AI Way (Recommended)
1. **Tell the AI**: "Add Plex to my media stack"
2. **AI Creates**: Docker Compose file with proper configuration
3. **AI Configures**: Traefik routing, Authelia protection, resource limits
4. **AI Deploys**: Service goes live with HTTPS and SSO
5. **AI Updates**: Homepage dashboard automatically

### Manual Way
1. **Find Service**: Choose from 50+ pre-configured services
2. **Upload to Dockge**: Use the web interface
3. **Configure**: Set environment variables and volumes
4. **Deploy**: Click deploy and wait
5. **Access**: Service is immediately available at `https://servicename.yourdomain.duckdns.org`

## Network Architecture

### Internal Networks (Per Server)
- **`traefik-network`**: All web-facing services connect here
- **`homelab-network`**: Internal service communication
- **`media-network`**: Media services (Plex, Jellyfin, etc.)
- **VPN Networks**: Download services route through Gluetun

### External Access

**Single Server:**
- **Port 80/443**: Only Traefik exposes these to the internet
- **Domain**: `*.yourdomain.duckdns.org` points to your home
- **SSL**: Wildcard certificate covers all subdomains automatically

**Multi-Server:**
- **Core Server Ports**: Only core forwards 80/443 to internet
- **Remote Servers**: No port forwarding needed; accessed through core
- **Traffic Flow**: Internet → Core Traefik → Remote Traefik → Service
- **SSL**: Core handles all SSL termination
- **Unified Domain**: `service.yourdomain.com` works for all servers

## Storage Strategy

### Configuration Files
- **Location**: `/opt/stacks/stack-name/config/`
- **Purpose**: Service settings, databases, user data
- **Backup**: Included in automatic backups

### Media & Large Data
- **Location**: `/mnt/media/`, `/mnt/downloads/`
- **Purpose**: Movies, TV shows, music, downloads
- **Performance**: Direct mounted drives for speed

### Secrets & Environment
- **Location**: `.env` files in each stack directory
- **Security**: Never committed to git
- **Management**: AI can help update variables

## AI Features

### VS Code Integration
- **Copilot Chat**: Natural language commands for infrastructure management
- **File Editing**: AI modifies Docker Compose files, configuration YAML
- **Troubleshooting**: AI analyzes logs and suggests fixes
- **Documentation**: AI keeps docs synchronized with deployed services

### OpenWebUI (Future)
- **Web Interface**: Chat with AI directly in your browser
- **API Tools**: AI can interact with your services' APIs
- **Workflows**: Automated service management and monitoring
- **Status**: Currently in development phase

## Lazy Loading (Sablier)

Some services start **on-demand** to save resources:
- **How it works**: Service starts when you first access it
- **Benefits**: Saves RAM and CPU when services aren't in use
- **Configuration**: AI manages the lazy loading rules
- **Multi-Server**: Each server runs its own Sablier for LOCAL container management

## Multi-Server Architecture (Optional)

If you deploy across multiple servers:

### Core Server Responsibilities
- **External Traffic**: Only server with ports 80/443 forwarded
- **SSL Termination**: Handles all HTTPS certificates
- **SSO Gateway**: Authelia protects all services across servers
- **DNS Updates**: DuckDNS points domain to this server
- **Route Configuration**: Traefik YAML files route to remote servers

### Remote Server Responsibilities
- **Local Services**: Runs media, downloads, or specialized workloads
- **Local Management**: Own Traefik and Sablier instances
- **Internal Access**: Services listen on Docker networks only
- **Lazy Loading**: Sablier starts/stops containers locally

### Traffic Flow Example
```
User requests: https://sonarr.yourdomain.com
    ↓
1. Internet → Core Server (ports 80/443)
2. Core Traefik → Authelia (check login)
3. Core Traefik → Remote Server (http://192.168.1.100:8989)
4. Remote Traefik → Sablier (is service running?)
5. Remote Sablier → Starts Container (if needed)
6. Service Response → Back through chain to user
```

### Setup Process
1. **Core**: Deploy with `ez-homelab.sh` option 1 or 2
2. **Remote**: Deploy with `ez-homelab.sh` option 3 per server
3. **Configure**: Add external YAML files on core for remote services
4. **Access**: All services available through core domain

See [Ondemand-Remote-Services.md](Ondemand-Remote-Services.md) for detailed setup.

## Monitoring & Maintenance

### Built-in Monitoring
- **Grafana/Prometheus**: System metrics and dashboards
- **Uptime Kuma**: Service uptime monitoring
- **Dozzle**: Live container log viewing
- **Node Exporter**: Hardware monitoring

### Automatic Updates
- **Watchtower**: Updates Docker images automatically
- **Backrest**: Scheduled backups using Restic
- **Certificate Renewal**: SSL certificates renew automatically

## Security Model

### Defense in Depth
1. **Network Level**: Firewall blocks unauthorized access
2. **SSL/TLS**: All traffic encrypted with valid certificates
3. **Authentication**: Authelia protects admin interfaces
4. **Authorization**: User roles and permissions
5. **Container Security**: Services run as non-root users

### VPN for Downloads
- **Purpose**: Hide IP address for torrenting
- **Implementation**: Download containers route through VPN
- **Provider**: Surfshark (configurable)

## Scaling & Customization

### Adding Services

**Single Server:**
- **Pre-built**: [50+ services](services-overview.md) ready to deploy
- **Custom**: AI can create configurations for any Docker service
- **External Devices**: Proxy services on Raspberry Pi, NAS via Traefik YAML files

**Multi-Server:**
- **Remote Services**: Deploy on any server with Traefik labels
- **Core Routing**: Add external YAML file on core to route traffic
- **Unified Access**: All services appear under same domain
- **See**: [Ondemand-Remote-Services.md](Ondemand-Remote-Services.md) for patterns

### Resource Management
- **Limits**: CPU, memory, and I/O limits prevent resource exhaustion
- **Reservations**: Guaranteed minimum resources
- **GPU Support**: Automatic NVIDIA GPU detection and configuration
