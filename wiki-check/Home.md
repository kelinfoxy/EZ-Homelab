# EZ-Homelab Wiki

Welcome to the **EZ-Homelab Wiki** - the complete guide for deploying and managing a production-ready homelab server with SSO, Reverse Proxy, DuckNS & LetsEncrypt.  

Deploy a secure homelab in Minutes!

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://docker.com)
[![Traefik](https://img.shields.io/badge/Traefik-24.0.0-24A1C6)](https://traefik.io)
[![Authelia](https://img.shields.io/badge/Authelia-4.38.0-113155)](https://www.authelia.com)

## 📖 Wiki Overview

This wiki serves as the **single source of truth** for the EZ-Homelab project, containing all documentation, guides, and reference materials needed to deploy and manage your homelab infrastructure.

### 🎯 Key Features

- **Production-Ready**: Automated SSL, SSO authentication, and VPN routing
- **AI-Manageable**: File-based architecture designed for AI assistance
- **Comprehensive**: 70+ services across 12 stacks
- **Secure by Default**: Authelia SSO protection with bypass options
- **Easy Management**: Dockge web UI for visual stack management

### 🏗️ Architecture Overview

The EZ-Homelab uses a layered architecture:

1. **Core Infrastructure** (Deploy First)
   - DuckDNS: Dynamic DNS with wildcard SSL
   - Traefik: Reverse proxy with automatic HTTPS
   - Authelia: Single Sign-On authentication
   - Gluetun: VPN client for secure downloads
   - Sablier: Lazy loading for resource efficiency

2. **Service Layers**
   - Infrastructure: Management and monitoring tools
   - Dashboards: Homepage and Homarr interfaces
   - Media: Plex, Jellyfin, and automation tools
   - Productivity: Nextcloud, Gitea, documentation tools
   - Home Automation: Home Assistant ecosystem
   - Monitoring: Grafana, Prometheus, alerting
   - Transcoders: Tdarr, Unmanic for media processing
   - Wikis: DokuWiki, BookStack, MediaWiki platforms
   - Utilities: Backup, security, and development tools

## 🚀 Quick Start

### Prerequisites
- Fresh Debian/Ubuntu server (or existing system)
- Root/sudo access
- Internet connection
- VS Code with GitHub Copilot (recommended)

### Automated Deployment
```bash
git clone https://github.com/kelinfoxy/EZ-Homelab.git
cd EZ-Homelab
cp .env.example .env
nano .env  # Configure your domain and tokens
sudo ./scripts/setup-homelab.sh
sudo ./scripts/deploy-homelab.sh
```

**Access your homelab:**
- **Dockge**: `https://dockge.yourdomain.duckdns.org` (primary management)
- **Homepage**: `https://homepage.yourdomain.duckdns.org` (service dashboard)
- **Authelia**: `https://auth.yourdomain.duckdns.org` (SSO login)

## 📚 Documentation Structure

### 🏁 Getting Started
- [[Getting Started Guide]] - Complete setup and deployment
- [[Environment Configuration]] - Required settings and tokens
- [[Automated Setup]] - One-click deployment process
- [[Manual Setup]] - Step-by-step manual installation
- [[Post-Setup Guide]] - What to do after deployment

### 🏗️ Architecture & Design
- [[System Architecture]] - High-level component overview
- [[System Architecture#Network Architecture]] - Service communication patterns
- [[System Architecture#Security Model]] - Authentication and access control
- [[System Architecture#Storage Strategy]] - Data persistence and organization
- [[Docker Guidelines]] - Service management patterns

### 💾 Backup & Recovery
- [[Backup Strategy]] - Restic + Backrest comprehensive guide

### 📦 Services & Stacks
- [[Services Overview]] - All 70+ available services across 12 stacks
- [[Core Infrastructure]] - Essential services (deploy first)
- [[Infrastructure Services]] - Management and monitoring
- [[Service Documentation]] - Individual service guides

### 🛠️ Operations & Management
- [[Quick Reference]] - Command cheat sheet
- [[Ports in Use]] - Complete port mapping reference
- [[Troubleshooting]] - Common issues and solutions
- [[SSL Certificates]] - HTTPS and certificate management
- [[Proxying External Hosts]] - Connect non-Docker services
- [[Resource Limits Template]] - Performance optimization

### 🤖 AI & Automation
- [[AI Management Guide]] - Using AI for homelab management
- [[Copilot Instructions]] - AI assistant configuration
- [[AI VS Code Setup]] - Development environment
- [[AI Management Prompts]] - Sample AI interactions

### 📋 Reference Materials
- [[Service Documentation]] - Individual service guides
- [[Quick Reference]] - Command cheat sheet
- [[Resource Limits Template]] - Performance optimization

## 🔧 Development & Contribution

### For Contributors
- [[Copilot Instructions]] - AI assistant configuration
- [[AI Management Guide]] - Development best practices

### Repository Structure
```
EZ-Homelab/
├── docs/                    # Documentation
├── docker-compose/          # Service definitions
├── config-templates/        # Configuration templates
├── scripts/                 # Deployment scripts
├── .github/                 # GitHub configuration
└── wiki/                    # This wiki (source of truth)
```

## 📞 Support & Community

- **Issues**: [GitHub Issues](https://github.com/kelinfoxy/EZ-Homelab/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kelinfoxy/EZ-Homelab/discussions)
- **Documentation**: This wiki is the primary source of truth

## 📈 Project Status

- **Version**: 1.0.0 (Production Ready)
- **Services**: 70+ services across 12 stacks
- **Architecture**: File-based, AI-manageable
- **Management**: Dockge web UI
- **Security**: Authelia SSO with VPN routing

---

*This wiki is automatically maintained and serves as the single source of truth for the EZ-Homelab project. All information is kept current with the latest documentation.*</content>
<parameter name="filePath">c:\Users\kelin\Documents\Apps\GitHub\AI-Homelab\wiki\Home.md