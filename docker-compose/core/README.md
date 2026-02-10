# Core Infrastructure Services

This directory contains the core infrastructure services that form the foundation of the homelab. These services should be deployed **on the core server only** and are critical for the operation of all other services across all servers.

## Services

### DuckDNS
- **Purpose**: Dynamic DNS service for domain resolution and wildcard SSL certificates
- **Subdomain**: Configurable via environment variables
- **Token**: Configured in environment variables
- **SSL Certificates**: Generates wildcard cert used by all services on all servers
- **Deploy**: Core server only

### Traefik (v3)
- **Purpose**: Reverse proxy and SSL termination with multi-server routing
- **Ports**: 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- **Configuration**: Located in `traefik/config/traefik.yml`
- **Multi-Server**: Discovers services on all servers via Docker providers
- **SSL**: Let's Encrypt with DNS-01 challenge (wildcard certificate)
- **Dashboard**: Available at configured domain
- **Deploy**: Core server only

### Authelia (v4.37.5)
- **Purpose**: Single sign-on authentication service for all services across all servers
- **Port**: 9091 (internal)
- **Access**: Configured authentication domain
- **Configuration**: Located in `authelia/config/`
- **Database**: SQLite database in `authelia/config/db.sqlite3`
- **Deploy**: Core server only

## Multi-Server Architecture

The core stack on the main server provides centralized services for the entire homelab:

**Core Server:**
- Receives all external traffic (ports 80/443 forwarded from router)
- Runs DuckDNS for domain management and SSL certificates
- Runs Authelia for centralized authentication
- Runs Sablier for lazyloading local containers
- Traefik lables route servies on the core server
- Traekif external-host-servername.yml defines routes for Remote Servers

**Remote Server:**
- Each container exposes ports
  - No port forwarding from router needed
- No Traefik lables
  - Traefik configured by an external-host yaml file on Core Server
- Runs Sablier for lazyloading local containers

**Service Access:**
- All services accessible via: `https://service.yourdomain.duckdns.org`
- Core Traefik routes to appropriate server (local or remote)
- Single wildcard SSL certificate used for all services
- Authelia provides SSO for all protected services

## ⚠️ Version Pinning & Breaking Changes

### Authelia Version Pinning
**Current Version**: `authelia/authelia:4.37.5`

**Breaking Changes Identified**:
- Authelia v4.39.15+ has breaking configuration changes that are incompatible with the current setup
- Database schema changes may require migration or recreation
- Configuration file format changes may break existing setups

**Action Taken**:
- Pinned to v4.37.5 which is confirmed working
- Database recreated from scratch to ensure compatibility
- Configuration files verified and working

**Upgrade Path**:
- Test upgrades in a separate environment first
- Backup configuration and database before upgrading
- Check Authelia changelog for breaking changes
- Consider using Authelia's migration tools if available

### Traefik Version Pinning
**Current Version**: `traefik:v3`

**Notes**:
- Traefik v3 is stable and working with current configuration
- Configuration format is compatible
- No breaking changes identified in current setup

## Configuration Requirements

### File Structure
```
core/
├── docker-compose.yml          # Main service definitions
├── .env                        # Environment variables
├── authelia/
│   ├── config/
│   |   ├── configuration.yml   # Authelia main config
│   |   └── notification.txt
|   └── secrets/
|       └── users_database.yml  # User credentials
├── duckdns/
│   └── config/                 # DuckDNS configuration
├── traefik/
│   ├── config/
│   │   └── traefik.yml         # Traefik static config
│   ├── dynamic/                # Dynamic configurations
│   │   ├── routes.yml
│   │   ├── sablier.yml
│   │   └── external-host-*.yml # Remote server routing
│   └── letsencrypt/
│       └── acme.json           # SSL certificates

```
