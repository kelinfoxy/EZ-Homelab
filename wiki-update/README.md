# EZ-Homelab Wiki

This directory contains the **complete wiki documentation** for the EZ-Homelab project, serving as the **single source of truth** for all project information.

## 📖 Wiki Structure

### Core Documentation
- **`Home.md`** - Main wiki page with overview and navigation
- **`_Sidebar.md`** - Wiki navigation sidebar
- **`_Footer.md`** - Footer with quick links and project info

### Getting Started
- **`Getting-Started-Guide.md`** - Complete setup instructions
- **`Environment-Configuration.md`** - Required settings and tokens
- **`Automated-Setup.md`** - One-click deployment process
- **`Manual-Setup.md`** - Step-by-step manual installation
- **`Post-Setup-Guide.md`** - Post-deployment configuration

### Architecture & Design
- **`System-Architecture.md`** - High-level component overview
- **`Docker-Guidelines.md`** - Service management patterns
- **`Ports-in-Use.md`** - Complete port mapping reference
- **`SSL-Certificates.md`** - HTTPS and certificate management

### Services & Documentation
- **`Services-Overview.md`** - All 50+ services catalog
- **`Service-Documentation.md`** - Individual service guides index
- **`service-docs/`** - Individual service documentation files
- **`Core-Infrastructure.md`** - Essential services guide
- **`Infrastructure-Services.md`** - Management tools guide

### Operations & Management
- **`Quick-Reference.md`** - Command cheat sheet
- **`Backup-Strategy.md`** - Restic + Backrest comprehensive guide
- **`Proxying-External-Hosts.md`** - Connect non-Docker services
- **`Resource-Limits-Template.md`** - Performance optimization
- **`troubleshooting/`** - Issue resolution guides

### AI & Automation
- **`AI-Management-Guide.md`** - Using AI for homelab management
- **`Copilot-Instructions.md`** - AI assistant configuration
- **`AI-VS-Code-Setup.md`** - Development environment setup
- **`AI-Management-Prompts.md`** - Sample AI interactions

### Additional Resources
- **`How-It-Works.md`** - System architecture explanation
- **`Authelia-Customization.md`** - SSO configuration options
- **`On-Demand-Remote-Services.md`** - Lazy loading configuration
- **`action-reports/`** - Deployment logs and reports

## 🎯 Purpose

This wiki serves as the **authoritative source of truth** for the EZ-Homelab project, containing:

- ✅ **Complete Documentation** - All setup guides, configuration options, and troubleshooting
- ✅ **Service Catalog** - Detailed information for all 50+ available services
- ✅ **Architecture Guides** - System design, network configuration, and security models
- ✅ **AI Integration** - Copilot instructions and AI management capabilities
- ✅ **Operational Guides** - Backup strategies, monitoring, and maintenance
- ✅ **Reference Materials** - Port mappings, resource limits, and quick references

## 📋 Wiki Standards

### Naming Convention
- Use `Title-Case-With-Dashes.md` for file names
- Match wiki link format: `[[Wiki Links]]`
- Descriptive, searchable titles

### Content Organization
- **Headers**: Use `# ## ###` hierarchy
- **Links**: Use `[[Wiki Links]]` for internal references
- **Code**: Use backticks for commands and file paths
- **Lists**: Use bullet points for features/options

### Maintenance
- **Single Source of Truth**: All information kept current
- **Comprehensive**: No missing critical information
- **Accurate**: Verified configurations and commands
- **Accessible**: Clear language, logical organization

## 🔄 Synchronization

This wiki is automatically synchronized with the main documentation in `../docs/` and should be updated whenever:

- New services are added
- Configuration changes are made
- Documentation is updated
- New features are implemented

## 📖 Usage

### For Users
- Start with `Home.md` for overview
- Use `_Sidebar.md` for navigation
- Search for specific topics or services
- Reference individual service documentation

### For Contributors
- Update wiki when modifying documentation
- Add new pages for new features
- Maintain link integrity
- Keep information current

### For AI Management
- Copilot uses this wiki as reference
- Contains complete system knowledge
- Provides context for AI assistance
- Enables intelligent homelab management

## 🤝 Contributing

When contributing to the wiki:

1. **Update Content**: Modify relevant pages with new information
2. **Check Links**: Ensure all internal links work
3. **Update Navigation**: Add new pages to `_Sidebar.md` if needed
4. **Verify Accuracy**: Test commands and configurations
5. **Maintain Standards**: Follow naming and formatting conventions

## 📊 Wiki Statistics

- **Total Pages**: 25+ main pages
- **Service Docs**: 50+ individual service guides
- **Categories**: 10 service categories
- **Topics Covered**: Setup, configuration, troubleshooting, architecture
- **Last Updated**: January 21, 2026

---

*This wiki represents the complete knowledge base for the EZ-Homelab project and serves as the primary reference for all users and contributors.*

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

- **[GitHub Repository](https://github.com/kelinfoxy/EZ-Homelab)** - Source code and issues
- **[Docker Hub](https://hub.docker.com)** - Container images
- **[Traefik Documentation](https://doc.traefik.io/traefik/)** - Official reverse proxy docs
- **[Authelia Documentation](https://www.authelia.com/)** - SSO documentation
- **[DuckDNS](https://www.duckdns.org/)** - Dynamic DNS service

---

## 🎯 Quick Navigation

**New to EZ-Homelab?** → [Getting Started](getting-started.md)

**Need to add a service?** → [Service Creation Guide](docker-guidelines.md#service-creation-guidelines)

**Having issues?** → [Troubleshooting](quick-reference.md#troubleshooting)

**Want to contribute?** → [Development Workflow](docker-guidelines.md#service-creation-guidelines)

---

*This documentation is maintained by AI and community contributors. Last updated: January 20, 2026*