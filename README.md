# EZ-Homelab

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://docker.com)
[![Traefik](https://img.shields.io/badge/Traefik-24.0.0-24A1C6)](https://traefik.io)
[![Authelia](https://img.shields.io/badge/Authelia-4.38.0-113155)](https://www.authelia.com)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/kelinfoxy/EZ-Homelab)](https://github.com/kelinfoxy/EZ-Homelab/releases/latest)

>Homelab infrastructure with automated SSL, SSO authentication, and VPN routing.  
Deploy 50+ services through a file-based, AI-manageable architecture.  
Plus Dockge for visual management of containers, and Homepage dashboard to easily access deployed services.  

>The easy way to get a homelab up and running securely

>So simple anyone can do it in about an hour

## 🚀 Quick Start

### Prerequisites
- **Fresh Debian/Ubuntu server** (or existing system)
- **Root/sudo access**
- **Internet connection**
- **VS Code with GitHub Copilot** (recommended for AI assistance)

### Automated Setup
```bash
# Clone repository
git clone https://github.com/kelinfoxy/EZ-Homelab.git
cd EZ-Homelab

# Run the unified setup script (guided installation)
./scripts/ez-homelab.sh
```

**Multi-Server Support:**
- **Core Server**: Full deployment with ports 80/443 forwarded from router
- **Remote Servers**: Infrastructure-only setup (option 3 in script)
- Each server runs its own Traefik and Sablier for local container management
- Core server Traefik routes to all servers via Docker TLS providers

**What the script does:**
- Installs Docker and required system packages
- Guides you through configuration (domain, admin credentials, etc.)
- Deploys selected services based on your needs
- Sets up all stacks for Dockge management

**Access your homelab:**
- **Dockge**: `https://dockge.yourdomain.duckdns.org` (primary management interface)
- **Homepage**: `https://homepage.yourdomain.duckdns.org` (service dashboard)
- **Authelia**: `https://auth.yourdomain.duckdns.org` (SSO login)

## 📚 Documentation

- **[Getting Started Guide](docs/getting-started.md)** - Step-by-step deployment and configuration
- **[Automated Setup](docs/automated-setup.md)** - Guided installation with ez-homelab.sh script
- **[Manual Setup](docs/manual-setup.md)** - Step-by-step manual installation
- **[Docker Guidelines](docs/docker-guidelines.md)** - Service management patterns and best practices
- **[Services Reference](docs/services-overview.md)** - All 50+ available services
- **[Quick Reference](docs/quick-reference.md)** - Command cheat sheet and troubleshooting
- **[Proxying External Hosts](docs/proxying-external-hosts.md)** - Connect non-Docker services (Raspberry Pi, NAS, etc.)
- **[Multi-Server Setup](docs/Ondemand-Remote-Services.md)** - Deploy services across multiple servers

## 🚀 Quick Navigation

**New to EZ-Homelab?** → [Getting Started Guide](docs/getting-started.md)

**Need Help Deploying?** → [Automated Setup](docs/automated-setup.md)

**Want to Add Services?** → [Service Creation Guide](docs/docker-guidelines.md)

**Having Issues?** → [Troubleshooting](docs/quick-reference.md)

**Multi-Server Setup?** → [Remote Services Guide](docs/Ondemand-Remote-Services.md)

**Managing Services?** → Dockge Dashboard at `https://dockge.yourdomain.duckdns.org`

### Service Documentation
Individual service documentation is available in [docs/service-docs/](docs/service-docs/):
- [Authelia](docs/service-docs/authelia.md) - SSO authentication
- [Traefik](docs/service-docs/traefik.md) - Reverse proxy and SSL
- [Sablier](docs/service-docs/sablier.md) - Lazy loading for on-demand containers
- [DuckDNS](docs/service-docs/duckdns.md) - Dynamic DNS
- [Dockge](docs/service-docs/dockge.md) - Stack management
- [Homepage](docs/service-docs/homepage.md) - Service dashboard
- And 50+ more services in the docs/service-docs/ folder

## 🏗️ Architecture

### Core Infrastructure (Deploy on Main Server)
- **DuckDNS** - Dynamic DNS with wildcard SSL certificates
- **Traefik** - Reverse proxy with automatic HTTPS termination and multi-server routing
- **Authelia** - Single sign-on (SSO) authentication

### Per-Server Infrastructure (Deploy on Each Server)
- **Traefik** - Local reverse proxy instance for container discovery
- **Sablier** - Lazy loading service for on-demand local container startup

### Multi-Server Architecture
- **Core Server**: Only server with ports 80/443 forwarded from router
- **Remote Servers**: Connect to core via Docker TLS (port 2376)
- **Unified Access**: All services accessible through core server's domain
- **Automatic Routing**: Core Traefik discovers services on all servers
- **Lazy Loading**: Each server's Sablier manages local containers only

### VPN Services
- **Gluetun** - VPN client for secure downloads
- **qBittorrent** - Torrent client routed through VPN

### Service Categories
- **Media** - Plex, Jellyfin, Sonarr, Radarr
- **VPN** - qBittorrent (VPN-routed downloads)
- **Productivity** - Nextcloud, Gitea, BookStack, OnlyOffice
- **Monitoring** - Grafana, Prometheus, Uptime Kuma
- **Home Automation** - Home Assistant, Node-RED, Zigbee2MQTT
- **Utilities** - Backrest (backups), FreshRSS, Code Server

### Key Features
- **File-based configuration** - AI-manageable YAML files
- **Multi-server support** - Scale across multiple machines with unified access
- **Automated SSL** - Wildcard certificates via Let's Encrypt
- **Automatic routing** - Traefik discovers services across all servers
- **VPN routing** - Secure download clients through Gluetun
- **Resource limits** - Prevent resource exhaustion
- **SSO protection** - Authelia integration with bypass options
- **Lazy loading** - Per-server Sablier enables on-demand container startup
- **Automated backups** - Restic + Backrest for comprehensive data protection

## 🤖 AI Management

This homelab is designed to be managed by AI agents through VS Code with GitHub Copilot. The system uses:

- **Declarative configuration** - Services defined in Docker Compose files
- **Label-based routing** - Traefik discovers services automatically
- **Standardized patterns** - Consistent environment variables and volumes
- **Comprehensive documentation** - AI instructions in `.github/copilot-instructions.md`

## 📋 Requirements

- **OS**: Debian 11+, Ubuntu 20.04+
- **RAM**: 4GB minimum, 8GB+ recommended
- **Storage**: 50GB+ available space
- **Network**: Stable internet connection
- **Hardware**: x86_64 architecture (ARM support limited)

## 🔧 Manual Setup

If automated scripts fail, see:
- **[Manual Setup Guide](docs/manual-setup.md)** - Step-by-step manual installation
- **[Troubleshooting](docs/quick-reference.md)** - Common issues and solutions

## 🤝 Contributing

This project welcomes contributions! See individual service docs for configuration examples and deployment patterns.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Individual services may have their own licenses - please check the respective project repositories.

---

**Built with ❤️ for the homelab community**