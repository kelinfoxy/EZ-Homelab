# EZ-Homelab

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://docker.com)
[![Traefik](https://img.shields.io/badge/Traefik-24.0.0-24A1C6)](https://traefik.io)
[![Authelia](https://img.shields.io/badge/Authelia-4.38.0-113155)](https://www.authelia.com)

>Production-ready homelab infrastructure with automated SSL, SSO authentication, and VPN routing.  
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

# Configure environment
cp .env.example .env
nano .env  # Add your domain and tokens

# Run setup script (installs Docker, generates secrets)
sudo ./scripts/setup-homelab.sh

# Deploy all services
sudo ./scripts/deploy-homelab.sh
```

**Access your homelab:**
- **Dockge**: `https://dockge.yourdomain.duckdns.org` (primary management interface)
- **Homepage**: `https://homepage.yourdomain.duckdns.org` (service dashboard)
- **Authelia**: `https://auth.yourdomain.duckdns.org` (SSO login)

## 📚 Documentation

For comprehensive documentation, see the [GitHub Wiki](https://github.com/kelinfoxy/EZ-Homelab/wiki):

- **[Getting Started Guide](https://github.com/kelinfoxy/EZ-Homelab/wiki/Getting-Started-Guide)** - Step-by-step deployment and configuration
- **[Docker Guidelines](https://github.com/kelinfoxy/EZ-Homelab/wiki/Docker-Guidelines)** - Service management patterns and best practices
- **[Quick Reference](https://github.com/kelinfoxy/EZ-Homelab/wiki/Quick-Reference)** - Command cheat sheet and troubleshooting
- **[Services Reference](https://github.com/kelinfoxy/EZ-Homelab/wiki/Services-Overview)** - All 70+ available services
- **[Proxying External Hosts](https://github.com/kelinfoxy/EZ-Homelab/wiki/Proxying-External-Hosts)** - Connect non-Docker services (Raspberry Pi, NAS, etc.)

## 🚀 Quick Navigation

**New to EZ-Homelab?** → [Getting Started Guide](https://github.com/kelinfoxy/EZ-Homelab/wiki/Getting-Started-Guide)

**Need Help Deploying?** → [Automated Setup](https://github.com/kelinfoxy/EZ-Homelab/wiki/Getting-Started-Guide#automated-setup)

**Want to Add Services?** → [Service Creation Guide](https://github.com/kelinfoxy/EZ-Homelab/wiki/Docker-Guidelines#service-creation-guidelines)

**Having Issues?** → [Troubleshooting](https://github.com/kelinfoxy/EZ-Homelab/wiki/Quick-Reference#troubleshooting)

**Managing Services?** → [Dockge Dashboard](https://dockge.yourdomain.duckdns.org)

### Service Documentation
Individual service documentation is available in the [GitHub Wiki](https://github.com/kelinfoxy/EZ-Homelab/wiki):
- [Authelia](https://github.com/kelinfoxy/EZ-Homelab/wiki/Authelia) - SSO authentication
- [Traefik](https://github.com/kelinfoxy/EZ-Homelab/wiki/Traefik) - Reverse proxy and SSL
- [Dockge](https://github.com/kelinfoxy/EZ-Homelab/wiki/Dockge) - Stack management
- [Homepage](https://github.com/kelinfoxy/EZ-Homelab/wiki/Homepage) - Service dashboard
- And 50+ more services...

## 🏗️ Architecture

### Core Infrastructure
- **Traefik** - Reverse proxy with automatic HTTPS termination
- **Authelia** - Single sign-on (SSO) authentication
- **DuckDNS** - Dynamic DNS with wildcard SSL certificates
- **Sablier** - Lazy loading service for on-demand containers

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
- **Automated SSL** - Wildcard certificates via Let's Encrypt
- **VPN routing** - Secure download clients through Gluetun
- **Resource limits** - Prevent resource exhaustion
- **SSO protection** - Authelia integration with bypass options
- **Lazy loading** - Sablier enables on-demand container startup
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
- **[Manual Setup Guide](https://github.com/kelinfoxy/EZ-Homelab/wiki/Manual-Setup)** - Step-by-step manual installation
- **[Troubleshooting](https://github.com/kelinfoxy/EZ-Homelab/wiki/Troubleshooting)** - Common issues and solutions

## 🤝 Contributing

This project welcomes contributions! See individual service docs for configuration examples and deployment patterns.

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Individual services may have their own licenses - please check the respective project repositories.

---

**Built with ❤️ for the homelab community**