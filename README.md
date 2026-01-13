# AI-Homelab

Leverage Github Copilot in VS Code as a complete homelab management interface.

## Overview

This repository provides a comprehensive, production-ready homelab infrastructure using Docker Compose with Dockge, featuring 40+ pre-configured services. Integrated AI assistance through GitHub Copilot helps you create, modify, and manage Docker services while maintaining consistency across your entire server stack.

The infrastructure uses Traefik for reverse proxy with automatic SSL, Authelia for Single Sign-On, Gluetun for VPN routing, and DuckDNS for dynamic DNS - all managed through file-based configurations that the AI can manage.

## Designed to be noob friendly

* simple install process
* Just tell the AI what you want
* doesn't require setting up a raid
* you can start with the hardware you have and add raid as your homelab grows
* The AI can guide you through advanced concepts
   * setting up a raid and transfering your data
   * adding a 2nd or 3rd server to your homelab

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

## Documentation

- **[Getting Started](docs/getting-started.md)**: Step-by-step setup guide
- **[Services Reference](docs/services-reference.md)**: Complete list of all 60+ pre-configured services
- **[Docker Guidelines](docs/docker-guidelines.md)**: Comprehensive guide to Docker service management with Dockge
- **[Quick Reference](docs/quick-reference.md)**: Command reference and troubleshooting
- **[Proxying External Hosts](docs/proxying-external-hosts.md)**: Guide for proxying Raspberry Pi, routers, NAS via Traefik
- **[Copilot Instructions](.github/copilot-instructions.md)**: AI assistant guidelines (Traefik, Authelia, Dockge aware)

# Quick Start

### Prerequisites

- Docker Engine 24.0+ installed
- Docker Compose V2
- Git
- VS Code with GitHub Copilot extension (for AI assistance)
- A domain from DuckDNS (free)
- Surfshark VPN account (optional, for VPN features)
- Sufficient disk space: 120GB+ system drive (NVMe or SSD highly recommended), 2TB+ for media & additional disks for services like Nextcloud that require lots of space

## Quick Setup (Dockge Structure)

1. **Clone the repository into your home folder:**
   ```bash
   cd ~
   git clone https://github.com/kelinfoxy/AI-Homelab.git
   cd AI-Homelab
   ```

2. **(Optional) Run first-run setup script:**
   
   For fresh Debian installations only, this automated script will install Docker Engine + Compose V2, configure user groups, detect NVIDIA GPU, and create directory structure.
   
   ```bash
   sudo ./scripts/setup-homelab.sh
   ```

3. **Create and configure environment file:**
   ```bash
   cp .env.example .env
   nano .env  # Edit with your domain, API keys, and passwords
   ```
   > Alternatively you can ssh in from VS Code using the Remote-SSH plugin and edit in a nice editor

   **Required variables:**
   - `DOMAIN` - Your DuckDNS domain (e.g., yourdomain.duckdns.org)
   - `DUCKDNS_TOKEN` - Your DuckDNS token
   - `ACME_EMAIL` - Your email for Let's Encrypt certificates
   - `AUTHELIA_JWT_SECRET` - Generate with: `openssl rand -hex 64`
   - `AUTHELIA_SESSION_SECRET` - Generate with: `openssl rand -hex 64`
   - `AUTHELIA_STORAGE_ENCRYPTION_KEY` - Generate with: `openssl rand -hex 64`
   - `SURFSHARK_USERNAME` and `SURFSHARK_PASSWORD` - If using VPN
   
   > See [Getting Started](docs/getting-started.md) for detailed instructions

4. **Run deployment script:**
   
   This automated script will:
   - Create Docker networks
   - Configure Traefik with your email
   - Generate Authelia admin password (saved to `/opt/stacks/core/authelia/ADMIN_PASSWORD.txt`)
   - Deploy core stack (DuckDNS, Traefik, Authelia, Gluetun)
   - Deploy infrastructure stack (Dockge, Pi-hole, monitoring tools)
   - Open Dockge in your browser
   
   ```bash
   ./scripts/deploy-homelab.sh
   ```
   
   **Login credentials:** Username: `admin` | Password: Check `/opt/stacks/core/authelia/ADMIN_PASSWORD.txt`

5. **Deploy additional stacks through Dockge:**
   
   Log in to Dockge at `https://dockge.yourdomain.duckdns.org` and deploy additional stacks from the repository's `docker-compose/` directory:
   - `dashboards.yml` - Homepage, Homarr
   - `media.yml` - Plex, Jellyfin, Sonarr, Radarr, etc.
   - `media-extended.yml` - Readarr, Lidarr, etc.
   - `homeassistant.yml` - Home Assistant and accessories
   - `productivity.yml` - Nextcloud, Gitea, wikis
   - `monitoring.yml` - Grafana, Prometheus, etc.
   - `utilities.yml` - Backups, code editors, etc.

6. **Configure VS Code to control the server via GitHub Copilot**
   
   Install and configure the GitHub Copilot extension in VS Code, then use the Copilot chat window to manage your homelab.
   
   > Tip: Use free models for simple tasks like starting/stopping services, and premium models for complex configurations.

# #

# AI Capabilities and Examples #

   Ask the AI to modify anything about the AI-Homelab folder to suit your purposes.  

   Want to change /opt/stacks to something else? Just tell the AI what you want.  
   Prefer Portainer over Dockge? Ask the AI to refactor the entire AI-Homelab folder to convert to Portainer as default instead of Dockge.  
   Don't like the selection of included services? Tell the AI exactly what services you want and what you don't.  
   Don't like how the services are arranged in the stacks?  
   Want to replace one service with a different service?  

   > Just tell the AI what you want.

   - "Help me add a new media service to my homelab"
   - "Configure Traefik routing for my new service"
   - "Add Authelia SSO protection to this service"
   - "How do I proxy my Raspberry Pi through Traefik?"
   - "Create a Homepage widget for this service"
   - "Help me reorganize or customize my Homepage"
   - "Route this download client through Gluetun VPN"
   - "Disable SSO for Wordpress"

The AI assistant automatically follows the guidelines in `.github/copilot-instructions.md`  
   * to use `/opt/stacks/` directory structure, 
   * configure Traefik labels, 
   * apply Authelia middleware where appropriate, 
   * suggest `/mnt/` for large data storage, 
   * add services to Homepage dashboard with widgets, 
   * maintain consistency with existing services, 
   * and consider the entire stack when making changes.

## License

This project is provided as-is for personal homelab use.

## Acknowledgments

- Docker and Docker Compose communities
- LinuxServer.io for excellent container images
- GitHub Copilot for AI assistance capabilities
- All the open-source projects used in example compose files

## Support

For issues, or questions:
- Use GitHub Copilot in VS Code for real-time assistance
- Consult the comprehensive documentation