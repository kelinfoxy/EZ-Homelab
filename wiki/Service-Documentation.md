# Service Documentation

## Overview

This section contains detailed documentation for all 70+ services available in the AI-Homelab. Each service has its own documentation page with setup instructions, configuration options, and troubleshooting guides.

## Service Categories

### Core Infrastructure (Essential - Deploy First)
- [[DuckDNS]] - Dynamic DNS with wildcard SSL
- [[Traefik]] - Reverse proxy and SSL termination
- [[Authelia]] - Single Sign-On authentication
- [[Gluetun]] - VPN client for secure downloads
- [[Sablier]] - Lazy loading service

### Infrastructure & Management
- [[Dockge]] - Primary stack management UI
- [[Portainer]] - Advanced container management
- [[Authentik]] - Alternative SSO with web UI
- [[Pi-hole]] - DNS and ad blocking
- [[Dozzle]] - Real-time log viewer
- [[Glances]] - System monitoring
- [[Watchtower]] - Automatic updates
- [[Docker Proxy]] - Secure Docker API access

### Dashboards & Interfaces
- [[Homepage]] - Service dashboard (AI-configurable)
- [[Homarr]] - Modern dashboard alternative

### Media Services
- [[Plex]] - Popular media server
- [[Jellyfin]] - Open-source media streaming
- [[Calibre-Web]] - Ebook reader and server

### Media Management (*Arr Stack)
- [[Sonarr]] - TV show automation
- [[Radarr]] - Movie automation
- [[Prowlarr]] - Indexer management
- [[Readarr]] - Ebook/audiobook automation
- [[Lidarr]] - Music management
- [[Bazarr]] - Subtitle management
- [[Mylar3]] - Comic book management
- [[Lazy Librarian]] - Book automation

### Download Services
- [[qBittorrent]] - Torrent client (VPN-routed)
- [[FlareSolverr]] - Cloudflare bypass for indexers

### Home Automation
- [[Home Assistant]] - Smart home platform
- [[ESPHome]] - ESP device firmware
- [[TasmoAdmin]] - Tasmota device management
- [[Node-RED]] - Automation workflows
- [[Mosquitto]] - MQTT broker
- [[Zigbee2MQTT]] - Zigbee bridge
- [[MotionEye]] - Video surveillance

### Productivity & Collaboration
- [[Nextcloud]] - File sync and collaboration
- [[Gitea]] - Git service
- [[BookStack]] - Documentation platform
- [[DokuWiki]] - Wiki platform
- [[MediaWiki]] - Advanced wiki
- [[WordPress]] - Blog platform
- [[Form.io]] - Form builder

### Development Tools
- [[GitLab]] - Complete DevOps platform
- [[PostgreSQL]] - SQL database
- [[Redis]] - In-memory data store
- [[pgAdmin]] - PostgreSQL management
- [[Jupyter Lab]] - Interactive notebooks
- [[Code Server]] - VS Code in browser

### Monitoring & Observability
- [[Prometheus]] - Metrics collection
- [[Grafana]] - Visualization and dashboards
- [[Loki]] - Log aggregation
- [[Promtail]] - Log shipping
- [[Node Exporter]] - System metrics
- [[cAdvisor]] - Container metrics
- [[Alertmanager]] - Alert management
- [[Uptime Kuma]] - Uptime monitoring

### Utilities & Tools
- [[Vaultwarden]] - Password manager
- [[Duplicati]] - Encrypted backups
- [[Backrest]] - Restic backup UI
- [[FreshRSS]] - RSS feed reader
- [[Wallabag]] - Read-it-later service
- [[Unmanic]] - Media optimization
- [[Tdarr]] - Video transcoding
- [[Jellyseerr]] - Media requests

## Documentation Structure

Each service documentation page includes:

### 📋 Service Information
- **Purpose**: What the service does
- **URL**: Access URL after deployment
- **Authentication**: SSO protection status
- **Dependencies**: Required services or configurations

### ⚙️ Configuration
- **Environment Variables**: Required settings
- **Volumes**: Data persistence configuration
- **Networks**: Docker network connections
- **Ports**: Internal port mappings

### 🚀 Deployment
- **Stack Location**: Where to deploy
- **Compose File**: Docker Compose configuration
- **Resource Limits**: Recommended CPU/memory limits
- **Health Checks**: Service health verification

### 🔧 Management
- **Updates**: How to update the service
- **Backups**: Data backup procedures
- **Monitoring**: Health check commands
- **Logs**: Log location and viewing

### 🐛 Troubleshooting
- **Common Issues**: Frequent problems and solutions
- **Error Messages**: Specific error resolution
- **Performance**: Optimization tips
- **Recovery**: Service restoration procedures

## Quick Reference

### By Port Number
- **3000**: Grafana, Homarr, Gitea
- **3001**: Uptime Kuma
- **5050**: pgAdmin
- **5055**: Jellyseerr
- **8080**: Code Server, Nextcloud, Traefik dashboard
- **8081**: qBittorrent, MotionEye
- **8083**: Calibre-Web
- **8096**: Jellyfin
- **8123**: Home Assistant, Zigbee2MQTT
- **8200**: Duplicati
- **8888**: Jupyter Lab
- **8989**: Sonarr
- **9090**: Prometheus
- **9696**: Prowlarr
- **9700**: FlareSolverr

### By Category
- **Media Streaming**: Plex (32400), Jellyfin (8096)
- **Automation**: Sonarr (8989), Radarr (7878), Prowlarr (9696)
- **Databases**: PostgreSQL (5432), MariaDB (3306), Redis (6379)
- **Development**: GitLab (80/443), Gitea (3000), Code Server (8080)
- **Monitoring**: Grafana (3000), Prometheus (9090), Uptime Kuma (3001)

## Deployment Guidelines

### Service Dependencies
Some services require others to be running first:

**Required First:**
- Core Infrastructure (DuckDNS, Traefik, Authelia)

**Common Dependencies:**
- **Databases**: PostgreSQL, MariaDB, Redis for data persistence
- **VPN**: Gluetun for download services
- **Reverse Proxy**: Traefik for all web services
- **Authentication**: Authelia for SSO protection

### Resource Requirements
- **Lightweight** (< 256MB RAM): DNS, monitoring, authentication
- **Standard** (256MB - 1GB RAM): Web apps, dashboards, simple services
- **Heavy** (> 1GB RAM): Media servers, databases, development tools
- **Specialized**: GPU-enabled services, high-I/O applications

### Network Security
- **SSO Protected**: Most services require Authelia authentication
- **Bypass Allowed**: Media services (Plex, Jellyfin) for app access
- **VPN Routed**: Download services for IP protection
- **Internal Only**: Databases and supporting services

## Finding Service Documentation

### By Service Name
Use the alphabetical list above or search for the specific service.

### By Function
- **Want to stream media?** → [[Plex]], [[Jellyfin]]
- **Need automation?** → [[Sonarr]], [[Radarr]], [[Prowlarr]]
- **File sharing?** → [[Nextcloud]], [[Gitea]]
- **Monitoring?** → [[Grafana]], [[Prometheus]], [[Uptime Kuma]]
- **Development?** → [[GitLab]], [[Code Server]], [[Jupyter Lab]]

### By Complexity
- **Beginner**: Homepage, Dozzle, Glances
- **Intermediate**: Nextcloud, Gitea, BookStack
- **Advanced**: GitLab, Home Assistant, Prometheus

Each service page provides complete setup instructions and is designed to work with the AI-Homelab's file-based, AI-manageable architecture.</content>
<parameter name="filePath">c:\Users\kelin\Documents\Apps\GitHub\AI-Homelab\wiki\Service-Documentation.md