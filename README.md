# AI Homelab

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://docker.com)
[![Traefik](https://img.shields.io/badge/Traefik-24.0.0-24A1C6)](https://traefik.io)
[![Authelia](https://img.shields.io/badge/Authelia-4.38.0-113155)](https://www.authelia.com)

> **Production-ready homelab infrastructure** with automated SSL, SSO authentication, and VPN routing. Deploy 50+ services through a file-based, AI-manageable architecture using Dockge for visual management.

## 🚀 Quick Start

### Prerequisites
- **Fresh Debian/Ubuntu server** (or existing system)
- **Root/sudo access**
- **Internet connection**
- **VS Code with GitHub Copilot** (recommended for AI assistance)

### Automated Setup
```bash
# Clone repository
git clone https://github.com/kelinfoxy/AI-Homelab.git
cd AI-Homelab

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
- **Homepage**: `https://home.yourdomain.duckdns.org` (service dashboard)
- **Authelia**: `https://auth.yourdomain.duckdns.org` (SSO login)

## 📚 Documentation

For comprehensive documentation, see:

- **[Getting Started Guide](docs/getting-started.md)** - Step-by-step deployment and configuration
- **[Docker Guidelines](docs/docker-guidelines.md)** - Service management patterns and best practices
- **[Quick Reference](docs/quick-reference.md)** - Command cheat sheet and troubleshooting
- **[Services Reference](docs/services-overview.md)** - All 70+ available services
- **[Proxying External Hosts](docs/proxying-external-hosts.md)** - Connect non-Docker services (Raspberry Pi, NAS, etc.)

## 🚀 Quick Navigation

**New to AI-Homelab?** → [Getting Started Guide](docs/getting-started.md)

**Need Help Deploying?** → [Automated Setup](docs/getting-started.md#simple-setup)

**Want to Add Services?** → [Service Creation Guide](docs/docker-guidelines.md#service-creation-guidelines)

**Having Issues?** → [Troubleshooting](docs/quick-reference.md#troubleshooting)

**Managing Services?** → [Dockge Dashboard](https://dockge.yourdomain.duckdns.org)

### Service Documentation
Individual service documentation is available in [`docs/service-docs/`](docs/service-docs/):
- [Authelia](docs/service-docs/authelia.md) - SSO authentication
- [Traefik](docs/service-docs/traefik.md) - Reverse proxy and SSL
- [Dockge](docs/service-docs/dockge.md) - Stack management
- [Homepage](docs/service-docs/homepage.md) - Service dashboard
- And 50+ more services...

## 🏗️ Architecture

### Core Infrastructure
- **Traefik** - Reverse proxy with automatic HTTPS termination
- **Authelia** - Single sign-on (SSO) authentication
- **DuckDNS** - Dynamic DNS with wildcard SSL certificates
- **Gluetun** - VPN client for secure downloads
- **Sablier** - Lazy loading service for on-demand containers

### Service Categories
- **Media** - Plex, Jellyfin, Sonarr, Radarr, qBittorrent
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
- **[Manual Setup Guide](docs/manual-setup.md)** - Step-by-step manual installation
- **[Troubleshooting](docs/troubleshooting/)** - Common issues and solutions

## 🤝 Contributing

This project welcomes contributions! See individual service docs for configuration examples and deployment patterns.

## 📄 License

This project is open source. See individual service licenses for details.

---

**Built with ❤️ for the homelab community**