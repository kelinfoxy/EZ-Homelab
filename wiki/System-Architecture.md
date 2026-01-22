# System Architecture

## Overview

The EZ-Homelab implements a **layered, production-ready architecture** designed for reliability, security, and ease of management. The system is built around Docker containers orchestrated through Traefik reverse proxy with Authelia SSO authentication.

## Core Principles

### 1. **Infrastructure as Code**
- All services defined in Docker Compose files
- File-based configuration (AI-manageable)
- Version-controlled infrastructure
- Reproducible deployments

### 2. **Security First**
- **Default Deny**: All services start with Authelia SSO protection
- **Explicit Bypass**: Only media apps (Plex, Jellyfin) bypass SSO for app compatibility
- **VPN Routing**: Download services route through Gluetun VPN client
- **Wildcard SSL**: Single certificate covers all subdomains

### 3. **Layered Architecture**
```
┌─────────────────┐
│   Dashboards    │  ← User Interface Layer
│ (Homepage, UI)  │
└─────────────────┘
        │
┌─────────────────┐
│ Infrastructure  │  ← Management Layer
│ (Dockge, Auth)  │
└─────────────────┘
        │
┌─────────────────┐
│    Core Stack   │  ← Foundation Layer
│ (DNS, Proxy, VPN)│
└─────────────────┘
```

## Component Architecture

### Core Infrastructure Layer
The foundation that everything else depends on:

- **DuckDNS**: Dynamic DNS with Let's Encrypt DNS challenge
- **Traefik**: Reverse proxy with automatic HTTPS termination
- **Authelia**: SSO authentication with file-based user database
- **Gluetun**: VPN client for secure download routing
- **Sablier**: Lazy loading service for resource efficiency

### Service Categories

#### Infrastructure Services
- **Management**: Dockge (primary), Portainer (secondary)
- **Monitoring**: Dozzle (logs), Glances (system), Pi-hole (DNS)
- **Security**: Authelia (SSO), VPN routing via Gluetun

#### Media Services
- **Streaming**: Plex, Jellyfin (with app compatibility bypass)
- **Automation**: Sonarr, Radarr, Prowlarr (*Arr stack)
- **Downloads**: qBittorrent (VPN-routed)

#### Productivity & Collaboration
- **File Sync**: Nextcloud with MariaDB
- **Version Control**: Gitea with PostgreSQL
- **Documentation**: BookStack, DokuWiki, MediaWiki
- **Communication**: Various collaboration tools

#### Home Automation
- **Core**: Home Assistant with database
- **Development**: ESPHome, Node-RED
- **Connectivity**: Mosquitto (MQTT), Zigbee2MQTT
- **Surveillance**: MotionEye

#### Monitoring & Observability
- **Metrics**: Prometheus, Node Exporter, cAdvisor
- **Visualization**: Grafana with Loki logging
- **Alerting**: Alertmanager, Uptime Kuma

## Network Architecture

### Docker Networks
- **traefik-network**: Primary network for all web-facing services
- **homelab-network**: Internal service communication
- **dockerproxy-network**: Secure Docker socket access

### Routing Patterns
- **Traefik Labels**: Declarative routing configuration
- **Authelia Middleware**: SSO protection with bypass rules
- **VPN Routing**: `network_mode: "service:gluetun"` for downloads

### Port Management
- **External Ports**: Only 80/443 exposed (Traefik)
- **Internal Ports**: Services communicate via Docker networks
- **VPN Ports**: Download services mapped through Gluetun

## Storage Strategy

### Configuration Storage
- **Location**: `/opt/stacks/{stack-name}/config/`
- **Purpose**: Application configuration and settings
- **Backup**: Included in backup strategy

### Data Storage
- **Small Data**: Named Docker volumes (< 50GB)
- **Large Data**: External mounts `/mnt/media`, `/mnt/downloads`
- **Databases**: Containerized with persistent volumes

### Backup Architecture
- **Primary**: Restic + Backrest for comprehensive backups
- **Secondary**: Service-specific backup tools (Duplicati)
- **Strategy**: 3-2-1 rule (3 copies, 2 media types, 1 offsite)

## Security Model

### Authentication Layers
1. **Network Level**: Firewall rules and VPN routing
2. **Application Level**: Authelia SSO with 2FA support
3. **Service Level**: Individual service authentication

### Access Control
- **Default Protected**: All services require authentication
- **Bypass Rules**: Configured in Authelia for specific domains
- **VPN Enforcement**: Download traffic routed through VPN

### Certificate Management
- **Wildcard Certificates**: `*.yourdomain.duckdns.org`
- **Automatic Renewal**: Traefik handles Let's Encrypt
- **DNS Challenge**: DuckDNS token-based validation

## Deployment Model

### Automated Setup
1. **System Preparation**: `setup-homelab.sh`
   - Docker installation
   - System configuration
   - Authelia secrets generation

2. **Service Deployment**: `deploy-homelab.sh`
   - Core stack deployment
   - Infrastructure services
   - Dashboard configuration

### Management Interface
- **Primary**: Dockge web UI at `dockge.yourdomain.duckdns.org`
- **Secondary**: Portainer for advanced container management
- **AI Integration**: File-based configuration for AI assistance

## Scalability & Performance

### Resource Management
- **Limits**: Configured per service based on requirements
- **Reservations**: Guaranteed minimum resources
- **Monitoring**: System resource tracking

### Service Categories by Resource Usage
- **Lightweight**: DNS, monitoring, authentication
- **Standard**: Web applications, dashboards
- **Heavy**: Media servers, databases
- **Specialized**: GPU-enabled services, high-I/O applications

## Maintenance & Operations

### Update Strategy
- **Automated**: Watchtower for container updates
- **Manual**: Service-specific update procedures
- **Testing**: Validation before production deployment

### Monitoring & Alerting
- **System**: Glances, Prometheus, Grafana
- **Services**: Health checks and log aggregation
- **Uptime**: Uptime Kuma for external monitoring

### Backup & Recovery
- **Automated**: Scheduled backups with Restic
- **Manual**: On-demand backups via Backrest UI
- **Testing**: Regular backup validation and restore testing

## AI Integration

### Copilot Instructions
- **File-Based**: All configuration in editable files
- **Documentation**: Comprehensive guides for AI assistance
- **Templates**: Ready-to-use configuration templates

### Management Patterns
- **Declarative**: Define desired state in YAML
- **Automated**: Scripts handle complex deployment logic
- **Validated**: Health checks and verification steps

This architecture provides a robust, secure, and maintainable foundation for a production homelab environment.</content>
<parameter name="filePath">c:\Users\kelin\Documents\Apps\GitHub\AI-Homelab\wiki\System-Architecture.md