# AI-Homelab Wiki

Welcome to the **AI-Homelab Wiki** - the comprehensive source of truth for deploying and managing a production-ready homelab infrastructure with 50+ services.

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://docker.com)
[![Traefik](https://img.shields.io/badge/Traefik-24.0.0-24A1C6)](https://traefik.io)
[![Authelia](https://img.shields.io/badge/Authelia-4.38.0-113155)](https://www.authelia.com)

## 📖 Wiki Overview

This wiki serves as the **single source of truth** for the AI-Homelab project, containing all documentation, guides, and reference materials needed to deploy and manage your homelab infrastructure.

### 🎯 Key Features

- **Production-Ready**: Automated SSL, SSO authentication, and VPN routing
- **AI-Manageable**: File-based architecture designed for AI assistance
- **Comprehensive**: 70+ services across 10 categories
- **Secure by Default**: Authelia SSO protection with bypass options
- **Easy Management**: Dockge web UI for visual stack management

### 🏗️ Architecture Overview

The AI-Homelab uses a layered architecture:

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
   - Development: GitLab, Jupyter, VS Code server

## 🚀 Quick Start

### Prerequisites
- Fresh Debian/Ubuntu server (or existing system)
- Root/sudo access
- Internet connection
- VS Code with GitHub Copilot (recommended)

### Automated Deployment
```bash
git clone https://github.com/kelinfoxy/AI-Homelab.git
cd AI-Homelab
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
- [[Network Architecture]] - Service communication patterns
- [[Security Model]] - Authentication and access control
- [[Storage Strategy]] - Data persistence and organization
- [[Docker Guidelines]] - Service management patterns

### 💾 Backup & Recovery
- [[Backup Strategy]] - Restic + Backrest comprehensive guide
- [[Backrest Service]] - Web UI backup management

### 📦 Services & Stacks
- [[Services Overview]] - All 70+ available services
- [[Core Infrastructure]] - Essential services (deploy first)
- [[Infrastructure Services]] - Management and monitoring
- [[Media Services]] - Streaming and automation
- [[Media Management]] - *Arr stack services
- [[Home Automation]] - Smart home integration
- [[Productivity Tools]] - Collaboration and organization
- [[Development Tools]] - Coding and deployment
- [[Monitoring Stack]] - Observability and alerting
- [[Utilities]] - Additional helpful services

### 🛠️ Operations & Management
- [[Quick Reference]] - Command cheat sheet
- [[Ports in Use]] - Complete port mapping reference
- [[Troubleshooting]] - Common issues and solutions
- [[SSL Certificates]] - HTTPS and certificate management
- [[Proxying External Hosts]] - Connect non-Docker services
- [[Resource Limits]] - Performance optimization

### 🤖 AI & Automation
- [[AI Management Guide]] - Using AI for homelab management
- [[Copilot Instructions]] - AI assistant configuration
- [[VS Code Setup]] - Development environment
- [[AI Prompt Examples]] - Sample AI interactions

### 📋 Reference Materials
- [[Service Documentation]] - Individual service guides
- [[Configuration Templates]] - Ready-to-use configs
- [[Script Reference]] - Automation scripts
- [[Action Reports]] - Deployment logs and reports

## 🔧 Development & Contribution

### For Contributors
- [[Development Notes]] - Technical implementation details
- [[Contributing Guide]] - How to contribute to the project
- [[Code Standards]] - Development best practices

### Repository Structure
```
AI-Homelab/
├── docs/                    # Documentation
├── docker-compose/          # Service definitions
├── config-templates/        # Configuration templates
├── scripts/                 # Deployment scripts
├── .github/                 # GitHub configuration
└── wiki/                    # This wiki (source of truth)
```

## 📞 Support & Community

- **Issues**: [GitHub Issues](https://github.com/kelinfoxy/AI-Homelab/issues)
- **Discussions**: [GitHub Discussions](https://github.com/kelinfoxy/AI-Homelab/discussions)
- **Documentation**: This wiki is the primary source of truth

## 📈 Project Status

- **Version**: 1.0.0 (Production Ready)
- **Services**: 70+ services across 10 categories
- **Architecture**: File-based, AI-manageable
- **Management**: Dockge web UI
- **Security**: Authelia SSO with VPN routing

---

*This wiki is automatically maintained and serves as the single source of truth for the AI-Homelab project. All information is kept current with the latest documentation.*</content>
<parameter name="filePath">c:\Users\kelin\Documents\Apps\GitHub\AI-Homelab\wiki\Home.md