# Docker Compose Stacks - Dockge Structure

This directory contains Docker Compose files designed for use with Dockge. Each stack should be placed in `/opt/stacks/stack-name/` on your server.

## Structure

```
/opt/stacks/
├── traefik/
│   ├── docker-compose.yml     # Copy from traefik.yml
│   ├── traefik.yml           # Static configuration
│   ├── dynamic/              # Dynamic routes
│   ├── acme.json            # SSL certificates (chmod 600)
│   └── .env
├── authelia/
│   ├── docker-compose.yml     # Copy from authelia.yml
│   ├── configuration.yml     # Authelia config
│   ├── users_database.yml    # User definitions
│   └── .env
├── duckdns/
│   ├── docker-compose.yml     # Copy from duckdns.yml
│   └── .env
├── gluetun/
│   ├── docker-compose.yml     # Copy from gluetun.yml (includes qBittorrent)
│   └── .env
├── infrastructure/
│   ├── docker-compose.yml     # Copy from infrastructure.yml
│   └── .env
├── media/
│   ├── docker-compose.yml     # Copy from media.yml
│   └── .env
├── monitoring/
│   ├── docker-compose.yml     # Copy from monitoring.yml
│   └── .env
└── development/
    ├── docker-compose.yml     # Copy from development.yml
    └── .env
```

## Core Infrastructure Stacks

### 1. Traefik (REQUIRED - Deploy First)
**File**: `traefik.yml`  
**Location**: `/opt/stacks/traefik/`

Reverse proxy with automatic SSL certificates via Let's Encrypt.

**Features**:
- Automatic HTTPS with Let's Encrypt
- Docker service discovery via labels
- File-based configuration for AI management
- HTTP to HTTPS redirect

**Setup**:
```bash
mkdir -p /opt/stacks/traefik/dynamic
cd /opt/stacks/traefik
# Copy traefik.yml to docker-compose.yml
# Copy config templates from config-templates/traefik/
# Create acme.json and set permissions
touch acme.json && chmod 600 acme.json
# Edit .env with your domain and email
docker compose up -d
```

### 2. Authelia (REQUIRED - Deploy Second)
**File**: `authelia.yml`  
**Location**: `/opt/stacks/authelia/`

Single Sign-On (SSO) authentication for all services.

**Features**:
- Protects services with authentication
- Bypass rules for apps (Jellyfin, Plex)
- Integrates with Traefik via middleware
- TOTP 2FA support

**Setup**:
```bash
mkdir -p /opt/stacks/authelia
cd /opt/stacks/authelia
# Copy authelia.yml to docker-compose.yml
# Copy config templates from config-templates/authelia/
# Generate secrets: openssl rand -hex 64
# Edit configuration.yml and users_database.yml
# Hash password: docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'yourpassword'
docker compose up -d
```

### 3. DuckDNS (RECOMMENDED)
**File**: `duckdns.yml`  
**Location**: `/opt/stacks/duckdns/`

Dynamic DNS updater for your domain.

**Setup**:
```bash
mkdir -p /opt/stacks/duckdns
cd /opt/stacks/duckdns
# Copy duckdns.yml to docker-compose.yml
# Add DUCKDNS_TOKEN and DUCKDNS_SUBDOMAINS to .env
docker compose up -d
```

### 4. Gluetun VPN (REQUIRED for torrenting)
**File**: `gluetun.yml`  
**Location**: `/opt/stacks/gluetun/`

VPN client (Surfshark) for routing download clients securely.

**Includes**: qBittorrent configured to route through VPN

**Setup**:
```bash
mkdir -p /opt/stacks/gluetun
mkdir -p /opt/stacks/qbittorrent
cd /opt/stacks/gluetun
# Copy gluetun.yml to docker-compose.yml
# Add Surfshark WireGuard credentials to .env
# Get WireGuard config from Surfshark dashboard
docker compose up -d
```

## Application Stacks

### Infrastructure
**File**: `infrastructure.yml`  
**Location**: `/opt/stacks/infrastructure/`

- Pi-hole: Network-wide ad blocking
- Portainer: Docker management UI
- Watchtower: Automatic container updates

### Media
**File**: `media.yml`  
**Location**: `/opt/stacks/media/`

- Plex: Media streaming (NO Authelia - app access)
- Jellyfin: Open-source streaming (NO Authelia - app access)
- Sonarr: TV show automation (WITH Authelia)
- Radarr: Movie automation (WITH Authelia)
- Prowlarr: Indexer manager (WITH Authelia)

**Note**: qBittorrent is in gluetun.yml (VPN routing)

### Monitoring
**File**: `monitoring.yml`  
**Location**: `/opt/stacks/monitoring/`

- Prometheus: Metrics collection
- Grafana: Visualization
- Node Exporter: System metrics
- cAdvisor: Container metrics
- Uptime Kuma: Service monitoring
- Loki: Log aggregation
- Promtail: Log shipping

### Development
**File**: `development.yml`  
**Location**: `/opt/stacks/development/`

- Code Server: VS Code in browser
- GitLab: Git repository manager
- PostgreSQL: Database
- Redis: In-memory store
- pgAdmin: Database UI
- Jupyter Lab: Data science notebooks
- Node-RED: Automation

## Networks

Create these networks before deploying stacks:

```bash
docker network create traefik-network
docker network create homelab-network
```

## Environment Variables

Each stack needs a `.env` file. Use `/home/runner/work/AI-Homelab/AI-Homelab/.env.example` as a template.

**Required variables**:
- `DOMAIN`: Your DuckDNS domain (e.g., `yourdomain.duckdns.org`)
- `DUCKDNS_TOKEN`: Your DuckDNS token
- `ACME_EMAIL`: Email for Let's Encrypt
- `AUTHELIA_JWT_SECRET`: Generate with `openssl rand -hex 64`
- `AUTHELIA_SESSION_SECRET`: Generate with `openssl rand -hex 64`
- `AUTHELIA_STORAGE_ENCRYPTION_KEY`: Generate with `openssl rand -hex 64`
- `SURFSHARK_PRIVATE_KEY`: From Surfshark WireGuard config
- `SURFSHARK_ADDRESSES`: From Surfshark WireGuard config

## Deployment Order

1. **Create networks**:
   ```bash
   docker network create traefik-network
   docker network create homelab-network
   ```

2. **Deploy Traefik** (reverse proxy):
   ```bash
   cd /opt/stacks/traefik
   docker compose up -d
   ```

3. **Deploy Authelia** (SSO):
   ```bash
   cd /opt/stacks/authelia
   docker compose up -d
   ```

4. **Deploy DuckDNS** (optional but recommended):
   ```bash
   cd /opt/stacks/duckdns
   docker compose up -d
   ```

5. **Deploy Gluetun** (VPN for downloads):
   ```bash
   cd /opt/stacks/gluetun
   docker compose up -d
   ```

6. **Deploy other stacks** as needed:
   ```bash
   cd /opt/stacks/infrastructure
   docker compose up -d
   
   cd /opt/stacks/media
   docker compose up -d
   ```

## Accessing Services

All services are accessible via your domain:

- **With Authelia (SSO required)**:
  - `https://traefik.yourdomain.duckdns.org` - Traefik dashboard
  - `https://portainer.yourdomain.duckdns.org` - Portainer
  - `https://sonarr.yourdomain.duckdns.org` - Sonarr
  - `https://radarr.yourdomain.duckdns.org` - Radarr
  - `https://prowlarr.yourdomain.duckdns.org` - Prowlarr
  - `https://qbit.yourdomain.duckdns.org` - qBittorrent
  - `https://grafana.yourdomain.duckdns.org` - Grafana
  - And more...

- **Without Authelia (direct app access)**:
  - `https://plex.yourdomain.duckdns.org` - Plex
  - `https://jellyfin.yourdomain.duckdns.org` - Jellyfin

- **Authentication page**:
  - `https://auth.yourdomain.duckdns.org` - Authelia login

## AI Management

The AI assistant (GitHub Copilot) can:

1. **Add new services**: Creates compose files with proper Traefik labels and Authelia middleware
2. **Modify routes**: Updates Docker labels to change proxy routing
3. **Manage SSO**: Adds or removes Authelia middleware as needed
4. **Configure VPN**: Sets up services to route through Gluetun
5. **Update configurations**: Modifies config files in `/opt/stacks/*/config/`

All configuration is file-based, allowing the AI to manage everything without web UI dependencies.

## Storage Strategy

- **Config files**: `/opt/stacks/stack-name/config/` (on system drive)
- **Small data**: Docker named volumes
- **Large data**: 
  - Media: `/mnt/media` (separate drive)
  - Downloads: `/mnt/downloads` (separate drive)
  - Backups: `/mnt/backups` (separate drive)

## Troubleshooting

### Service won't start
```bash
cd /opt/stacks/stack-name
docker compose logs -f
```

### Check Traefik routing
```bash
docker logs traefik
# Or visit: https://traefik.yourdomain.duckdns.org
```

### Test VPN connection
```bash
docker exec gluetun sh -c "curl ifconfig.me"
# Should show VPN IP, not your home IP
```

### Authelia issues
```bash
cd /opt/stacks/authelia
docker compose logs -f authelia
# Check configuration.yml for syntax errors
```

## Backup Important Files

Regular backups of:
- `/opt/stacks/` (all compose files and configs)
- `/opt/stacks/traefik/acme.json` (SSL certificates)
- `/opt/stacks/authelia/users_database.yml` (user accounts)
- Environment files (`.env` - store securely, not in git!)

## Security Notes

1. **Secrets**: Never commit `.env` files or `acme.json` to git
2. **Authelia**: Use strong passwords, hash them properly
3. **VPN**: Always route download clients through Gluetun
4. **Updates**: Watchtower keeps containers updated automatically
5. **Firewall**: Only expose ports 80 and 443 to the internet

## Getting Help

- Check the main [README.md](../README.md)
- Review [Docker Guidelines](../docs/docker-guidelines.md)
- Use GitHub Copilot in VS Code for AI assistance
- Check service-specific logs
