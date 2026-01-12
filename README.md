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
   > Alternativly you can ssh in from VS Code using the Remote-ssh plugin and edit in a nice editor

   Required variables: DOMAIN, DUCKDNS_TOKEN, TZ, Authelia user credentials, API keys for services you plan to use.
   > See [Getting Started](docs/getting-started.md) for more details
4. **Run deployment script:**
   
   This automated script will create required directories, verify Docker networks exist, deploy core stack (DuckDNS, Traefik, Authelia, Gluetun), deploy the infrastructure stack and open Dockge in your browser when ready.
   
   ```bash
   ./scripts/deploy-homelab.sh
   ```
   

5. **Deploy additional stacks through Dockge:**
   
   Log in to Dockge with your Authelia credentials and deploy additional stacks: dashboards.yml, media.yml, media-extended.yml, homeassistant.yml, productivity.yml, monitoring.yml, utilities.yml.

6. **Configure VS Code to control the server via Github Copilot**
   
   Log into VS Code, install and configure the Github Copilot extension with your api key. 
   Use the Copilot chat window to manage your homelab
   
   > Tip: If you have a paid account use the free models to perform simple tasks like starting/stopping a service, and premium models to do more advanced tasks.

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