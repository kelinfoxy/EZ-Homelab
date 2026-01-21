# AI-Homelab Documentation

Welcome to the AI-Homelab documentation! This is your comprehensive guide to deploying and managing a production-ready homelab infrastructure with 50+ pre-configured services.

## 📚 Documentation Structure

### 🚀 Getting Started
- **[Quick Start Guide](getting-started.md)** - Step-by-step setup for new users
- **[Prerequisites & Requirements](getting-started.md#prerequisites)** - What you need before starting
- **[First Deployment](getting-started.md#simple-setup)** - Automated setup process

### 🏗️ Architecture & Design
- **[System Architecture](README.md#key-features)** - High-level overview of components
- **[Network Architecture](docker-guidelines.md#network-architecture)** - How services communicate
- **[Security Model](docker-guidelines.md#security-best-practices)** - Authentication, SSL, and access control
- **[Storage Strategy](docker-guidelines.md#volume-management)** - Data persistence and organization

### 💾 Backup & Recovery
- **[Backup Strategy](Restic-BackRest-Backup-Guide.md)** - Comprehensive Restic + Backrest guide (default strategy)
- **[Backrest Service](service-docs/backrest.md)** - Web UI for backup management

### 📦 Services & Stacks

#### Core Infrastructure (Deploy First)
Essential services that everything else depends on:
- **[DuckDNS](service-docs/duckdns.md)** - Dynamic DNS updates
- **[Traefik](service-docs/traefik.md)** - Reverse proxy & SSL termination
- **[Authelia](service-docs/authelia.md)** - Single Sign-On authentication
- **[Gluetun](service-docs/gluetun.md)** - VPN client for secure downloads
- **[Sablier](service-docs/sablier.md)** - Lazy loading service for on-demand containers

#### Management & Monitoring
- **[Dockge](service-docs/dockge.md)** - Primary stack management UI
- **[Homepage](service-docs/homepage.md)** - Service dashboard (AI-configurable)
- **[Homarr](service-docs/homarr.md)** - Alternative modern dashboard
- **[Dozzle](service-docs/dozzle.md)** - Real-time log viewer
- **[Glances](service-docs/glances.md)** - System monitoring
- **[Pi-hole](service-docs/pihole.md)** - DNS & ad blocking

#### Media Services
- **[Jellyfin](service-docs/jellyfin.md)** - Open-source media streaming
- **[Plex](service-docs/plex.md)** - Popular media server (alternative)
- **[qBittorrent](service-docs/qbittorrent.md)** - Torrent client (VPN-routed)
- **[Calibre-Web](service-docs/calibre-web.md)** - Ebook reader & server

#### Media Management (Arr Stack)
- **[Sonarr](service-docs/sonarr.md)** - TV show automation
- **[Radarr](service-docs/radarr.md)** - Movie automation
- **[Prowlarr](service-docs/prowlarr.md)** - Indexer management
- **[Readarr](service-docs/readarr.md)** - Ebook/audiobook automation
- **[Lidarr](service-docs/lidarr.md)** - Music library management
- **[Bazarr](service-docs/bazarr.md)** - Subtitle automation
- **[Jellyseerr](service-docs/jellyseerr.md)** - Media request interface

#### Home Automation
- **[Home Assistant](service-docs/home-assistant.md)** - Smart home platform
- **[Node-RED](service-docs/node-red.md)** - Flow-based programming
- **[Zigbee2MQTT](service-docs/zigbee2mqtt.md)** - Zigbee device integration
- **[ESPHome](service-docs/esphome.md)** - ESP device firmware
- **[TasmoAdmin](service-docs/tasmoadmin.md)** - Tasmota device management
- **[MotionEye](service-docs/motioneye.md)** - Video surveillance

#### Productivity & Collaboration
- **[Nextcloud](service-docs/nextcloud.md)** - Self-hosted cloud storage
- **[Gitea](service-docs/gitea.md)** - Git service (GitHub alternative)
- **[BookStack](service-docs/bookstack.md)** - Documentation/wiki platform
- **[WordPress](service-docs/wordpress.md)** - Blog/CMS platform
- **[MediaWiki](service-docs/mediawiki.md)** - Wiki platform
- **[DokuWiki](service-docs/dokuwiki.md)** - Simple wiki
- **[Excalidraw](service-docs/excalidraw.md)** - Collaborative drawing

#### Development Tools
- **[Code Server](service-docs/code-server.md)** - VS Code in the browser
- **[GitLab](service-docs/gitlab.md)** - Complete DevOps platform
- **[Jupyter](service-docs/jupyter.md)** - Interactive computing
- **[pgAdmin](service-docs/pgadmin.md)** - PostgreSQL administration

#### Monitoring & Observability
- **[Grafana](service-docs/grafana.md)** - Metrics visualization
- **[Prometheus](service-docs/prometheus.md)** - Metrics collection
- **[Uptime Kuma](service-docs/uptime-kuma.md)** - Uptime monitoring
- **[Loki](service-docs/loki.md)** - Log aggregation
- **[Promtail](service-docs/promtail.md)** - Log shipping
- **[Node Exporter](service-docs/node-exporter.md)** - System metrics
- **[cAdvisor](service-docs/cadvisor.md)** - Container metrics

#### Utilities & Tools
- **[Backrest](service-docs/backrest.md)** - Backup management (Restic-based, default)
- **[Duplicati](service-docs/duplicati.md)** - Alternative backup solution
- **[FreshRSS](service-docs/freshrss.md)** - RSS feed reader
- **[Wallabag](service-docs/wallabag.md)** - Read-it-later service
- **[Watchtower](service-docs/watchtower.md)** - Automatic updates
- **[Vaultwarden](service-docs/vaultwarden.md)** - Password manager

#### Alternative Services
Services that provide alternatives to the defaults:
- **[Portainer](service-docs/portainer.md)** - Alternative container management
- **[Authentik](service-docs/authentik.md)** - Alternative SSO with web UI

### 🛠️ Development & Operations

#### Docker & Container Management
- **[Docker Guidelines](docker-guidelines.md)** - Complete service management guide
- **[Service Creation](docker-guidelines.md#service-creation-guidelines)** - How to add new services
- **[Service Modification](docker-guidelines.md#service-modification-guidelines)** - Updating existing services
- **[Resource Limits](resource-limits-template.md)** - CPU/memory management
- **[Troubleshooting](docker-guidelines.md#troubleshooting)** - Common issues & fixes

#### External Service Integration
- **[Proxying External Hosts](proxying-external-hosts.md)** - Route non-Docker services through Traefik
- **[External Host Examples](proxying-external-hosts.md#common-external-services-to-proxy)** - Raspberry Pi, NAS, etc.

#### AI & Automation
- **[Copilot Instructions](.github/copilot-instructions.md)** - AI agent guidelines for this codebase
- **[AI Management Capabilities](.github/copilot-instructions.md#ai-management-capabilities)** - What the AI can help with

### 📋 Quick References

#### Commands & Operations
- **[Quick Reference](quick-reference.md)** - Essential commands and workflows
- **[Stack Management](quick-reference.md#service-management)** - Start/stop/restart services
- **[Deployment Scripts](quick-reference.md#deployment-scripts)** - Setup and deployment automation

#### Troubleshooting
- **[Common Issues](quick-reference.md#troubleshooting)** - SSL, networking, permissions
- **[Service Won't Start](quick-reference.md#service-wont-start)** - Debugging steps
- **[Traefik Routing](quick-reference.md#traefik-not-routing)** - Route configuration issues
- **[VPN Problems](quick-reference.md#vpn-not-working-gluetun)** - Gluetun troubleshooting

### 📖 Advanced Topics

#### SSL & Certificates
- **[Wildcard SSL Setup](getting-started.md#notes-about-ssl-certificates-from-letsencrypt-with-duckdns)** - How SSL certificates work
- **[Certificate Troubleshooting](getting-started.md#certificate-troubleshooting)** - SSL issues and fixes
- **[DNS Challenge Process](getting-started.md#dns-challenge-process)** - How domain validation works

#### Security & Access Control
- **[Authelia Configuration](service-docs/authelia.md)** - SSO setup and customization
- **[Bypass Rules](docker-guidelines.md#when-to-use-authelia-sso)** - When to skip authentication
- **[2FA Setup](getting-started.md#set-up-2fa-with-authelia)** - Two-factor authentication

#### Backup & Recovery
- **[Backup Strategies](service-docs/duplicati.md)** - Data protection approaches
- **[Service Backups](service-docs/backrest.md)** - Database backup solutions
- **[Configuration Backup](quick-reference.md#backup-commands)** - Config file preservation

### 🔧 Development & Contributing

#### Repository Structure
- **[File Organization](.github/copilot-instructions.md#file-structure-standards)** - How files are organized
- **[Service Documentation](service-docs/)** - Individual service guides
- **[Configuration Templates](config-templates/)** - Reusable configurations
- **[Scripts](scripts/)** - Automation and deployment tools

#### Development Workflow
- **[Adding Services](docker-guidelines.md#service-creation-guidelines)** - New service integration
- **[Testing Changes](.github/copilot-instructions.md#testing-changes)** - Validation procedures
- **[Resource Limits](resource-limits-template.md)** - Performance management

### 📚 Additional Resources

- **[GitHub Repository](https://github.com/kelinfoxy/AI-Homelab)** - Source code and issues
- **[Docker Hub](https://hub.docker.com)** - Container images
- **[Traefik Documentation](https://doc.traefik.io/traefik/)** - Official reverse proxy docs
- **[Authelia Documentation](https://www.authelia.com/)** - SSO documentation
- **[DuckDNS](https://www.duckdns.org/)** - Dynamic DNS service

---

## 🎯 Quick Navigation

**New to AI-Homelab?** → [Getting Started](getting-started.md)

**Need to add a service?** → [Service Creation Guide](docker-guidelines.md#service-creation-guidelines)

**Having issues?** → [Troubleshooting](quick-reference.md#troubleshooting)

**Want to contribute?** → [Development Workflow](docker-guidelines.md#service-creation-guidelines)

---

*This documentation is maintained by AI and community contributors. Last updated: January 20, 2026*