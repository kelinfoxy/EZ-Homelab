# AI Homelab Management Assistant

You are an AI assistant for the **AI-Homelab** project - a production-ready Docker homelab infrastructure managed through GitHub Copilot in VS Code. This system deploys 60+ services with automated SSL, SSO authentication, and VPN routing using a file-based, AI-manageable architecture.

## Project Architecture

### Core Infrastructure (Deploy First)
The **core stack** (`/opt/stacks/core/`) contains essential services that must run before others:
- **DuckDNS**: Dynamic DNS with Let's Encrypt DNS challenge for wildcard SSL (`*.yourdomain.duckdns.org`)
- **Traefik**: Reverse proxy with automatic HTTPS termination (labels-based routing, file provider for external hosts)
- **Authelia**: SSO authentication (auto-generated secrets, file-based user database)
- **Gluetun**: VPN client (Surfshark WireGuard/OpenVPN) for download services

### Deployment Model
- **Two-script setup**: `setup-homelab.sh` (system prep, Docker install, secrets generation) → `deploy-homelab.sh` (automated deployment)
- **Dockge-based management**: All stacks in `/opt/stacks/`, managed via web UI at `dockge.${DOMAIN}`
- **Automated workflows**: Scripts create directories, configure networks, deploy stacks, wait for health checks
- **Repository location**: `/home/kelin/AI-Homelab/` (templates in `docker-compose/`, docs in `docs/`)

### File Structure Standards
```
/opt/stacks/
├── core/                      # DuckDNS, Traefik, Authelia, Gluetun (deploy FIRST)
├── infrastructure/            # Dockge, Pi-hole, monitoring tools
├── dashboards/                # Homepage (AI-configured), Homarr
├── media/                     # Plex, Jellyfin, Calibre-web, qBittorrent
├── media-management/          # *arr services (Sonarr, Radarr, etc.)
├── homeassistant/             # Home Assistant, Node-RED, Zigbee2MQTT
├── productivity/              # Nextcloud, Gitea, Bookstack
├── monitoring/                # Grafana, Prometheus, Uptime Kuma
└── utilities/                 # Duplicati, FreshRSS, Wallabag
```

### Network Architecture
- **traefik-network**: Primary network for all services behind Traefik
- **Gluetun network mode**: Download clients use `network_mode: "service:gluetun"` for VPN routing
- **Port mapping**: Only core services expose ports (80/443 for Traefik); others route via Traefik labels

## Critical Operational Principles

### 1. Security-First SSO Strategy
- **Default stance**: ALL services start with Authelia middleware enabled
- **Bypass exceptions**: Only Plex and Jellyfin (for device/app compatibility)
- **Disabling SSO**: Comment (don't delete) the middleware line: `# - "traefik.http.routers.SERVICE.middlewares=authelia@docker"`
- **Rationale**: Security by default; users explicitly opt-out for specific services

### 2. Traefik Label Patterns
Standard routing configuration for new services:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.SERVICE.rule=Host(`SERVICE.${DOMAIN}`)"
  - "traefik.http.routers.SERVICE.entrypoints=websecure"
  - "traefik.http.routers.SERVICE.tls.certresolver=letsencrypt"  # Uses wildcard cert
  - "traefik.http.routers.SERVICE.middlewares=authelia@docker"    # SSO protection
  - "traefik.http.services.SERVICE.loadbalancer.server.port=PORT"  # If not default
```

### 3. Storage Strategy
- **Configs**: Bind mount `./service/config:/config` relative to stack directory
- **Small data**: Named volumes (databases, app data <50GB)
- **Large data**: External mounts `/mnt/media`, `/mnt/downloads` (user must configure)
- **Secrets**: `.env` files in stack directories (auto-copied from `~/AI-Homelab/.env`)

### 4. LinuxServer.io Preference
- Use `lscr.io/linuxserver/*` images when available (PUID/PGID support for permissions)
- Standard environment: `PUID=1000`, `PGID=1000`, `TZ=${TZ}`

### 5. External Host Proxying
Proxy non-Docker services (Raspberry Pi, NAS) via Traefik file provider:
- Create routes in `/opt/stacks/core/traefik/dynamic/external.yml`
- Example pattern documented in `docs/proxying-external-hosts.md`
- AI can manage these YAML files directly

## Developer Workflows

### First-Time Deployment
```bash
cd ~/AI-Homelab
sudo ./scripts/setup-homelab.sh     # System prep, Docker install, Authelia secrets
# Reboot if NVIDIA drivers installed
sudo ./scripts/deploy-homelab.sh    # Deploy core+infrastructure stacks, open Dockge
```

### Managing Services via Scripts
- **setup-homelab.sh**: Idempotent system preparation (skips completed steps, runs on bare Debian)
  - Steps: Update system → Install Docker → Configure firewall → Generate Authelia secrets → Create directories/networks → NVIDIA driver detection
  - Auto-generates: JWT secret (64 hex), session secret (64 hex), encryption key (64 hex), admin password hash
  - Creates `homelab-network` and `traefik-network` Docker networks
- **deploy-homelab.sh**: Automated stack deployment (requires `.env` configured first)
  - Steps: Validate prerequisites → Create directories → Deploy core → Deploy infrastructure → Deploy dashboards → Prepare additional stacks → Wait for Dockge
  - Copies `.env` to `/opt/stacks/core/.env` and `/opt/stacks/infrastructure/.env`
  - Waits for service health checks before proceeding

### Testing Changes
```bash
# Test in isolation before modifying stacks
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi  # GPU test
docker compose -f docker-compose.yml config  # Validate YAML syntax
docker compose -f docker-compose.yml up -d SERVICE  # Deploy single service
docker compose logs -f SERVICE  # Monitor logs
```

### Common Operations
```bash
cd /opt/stacks/STACK_NAME
docker compose up -d              # Start stack
docker compose restart SERVICE    # Restart service
docker compose logs -f SERVICE    # Tail logs
docker compose pull && docker compose up -d  # Update images
```

## Creating a New Docker Service

## Creating a New Docker Service

### Service Definition Template
```yaml
services:
  service-name:
    image: linuxserver/service:latest  # Pin versions in production; prefer LinuxServer.io
    container_name: service-name
    restart: unless-stopped
    networks:
      - traefik-network
    volumes:
      - ./service-name/config:/config    # Config in stack directory
      - service-data:/data               # Named volume for persistent data
      # Large data on separate drives:
      # - /mnt/media:/media
      # - /mnt/downloads:/downloads
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.service-name.rule=Host(`service.${DOMAIN}`)"
      - "traefik.http.routers.service-name.entrypoints=websecure"
      - "traefik.http.routers.service-name.tls.certresolver=letsencrypt"
      - "traefik.http.routers.service-name.middlewares=authelia@docker"  # SSO enabled by default
      - "traefik.http.services.service-name.loadbalancer.server.port=8080"  # If non-standard port
      - "homelab.category=category-name"
      - "homelab.description=Service description"

volumes:
  service-data:
    driver: local

networks:
  traefik-network:
    external: true
```

### VPN-Routed Service (Downloads)
Route through Gluetun for VPN protection:
```yaml
services:
  # Gluetun already running in core stack
  
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    network_mode: "service:gluetun"  # Routes through VPN
    depends_on:
      - gluetun
    volumes:
      - ./qbittorrent/config:/config
      - /mnt/downloads:/downloads
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
    # No ports needed - mapped in Gluetun service
    # No Traefik labels - access via Gluetun's network
```

Add ports to Gluetun in core stack:
```yaml
gluetun:
  ports:
    - 8080:8080  # qBittorrent WebUI
```

### Authelia Bypass Example (Jellyfin)
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.${DOMAIN}`)"
  - "traefik.http.routers.jellyfin.entrypoints=websecure"
  - "traefik.http.routers.jellyfin.tls.certresolver=letsencrypt"
  # NO authelia middleware - direct access for apps/devices
```

## Modifying Existing Services

## Modifying Existing Services

### Safe Modification Process
1. **Read entire compose file** - understand dependencies (networks, volumes, depends_on)
2. **Check for impacts** - search for service references across other compose files
3. **Validate YAML** - `docker compose config` before deploying
4. **Test in place** - restart single service: `docker compose up -d SERVICE`
5. **Monitor logs** - `docker compose logs -f SERVICE` to verify functionality

### Common Modifications
- **Toggle SSO**: Comment/uncomment `middlewares=authelia@docker` label
- **Change port**: Update `loadbalancer.server.port` label
- **Add VPN routing**: Change to `network_mode: "service:gluetun"`, map ports in Gluetun
- **Update subdomain**: Modify `Host()` rule in Traefik labels
- **Environment changes**: Update in `.env`, redeploy: `docker compose up -d`

## Project-Specific Conventions

### Why Traefik vs Nginx Proxy Manager
- **File-based configuration**: AI can modify labels/YAML directly (no web UI clicks)
- **Docker label discovery**: Services auto-register routes when deployed
- **Let's Encrypt automation**: Wildcard cert via DuckDNS DNS challenge (single cert for all services)
- **Dynamic reloading**: Changes apply without container restarts

### Authelia Password Generation
Secrets auto-generated by `setup-homelab.sh`:
- JWT secret: `openssl rand -hex 64`
- Session secret: `openssl rand -hex 64`
- Encryption key: `openssl rand -hex 64`
- Admin password: Hashed with `docker run authelia/authelia:latest authelia crypto hash generate argon2`
- Stored in `.env` file, never committed to git

### DuckDNS Wildcard Certificate
- **Single certificate**: `*.yourdomain.duckdns.org` covers all subdomains
- **DNS challenge**: Traefik uses DuckDNS token for Let's Encrypt validation
- **Certificate storage**: `/opt/stacks/core/traefik/acme.json` (600 permissions)
- **Renewal**: Traefik handles automatically (90-day Let's Encrypt certs)
- **Usage**: Services use `tls.certresolver=letsencrypt` label (no per-service cert requests)

### Homepage Dashboard AI Configuration
Homepage (`/opt/stacks/dashboards/`) uses dynamic variable replacement:
- Services configured in `homepage/config/services.yaml`
- URLs use `${DOMAIN}` variable replaced at runtime
- AI can add/remove service entries by editing YAML
- Bookmarks, widgets configured similarly in separate YAML files

## Key Documentation References

- **[Getting Started](../docs/getting-started.md)**: Step-by-step deployment guide
- **[Docker Guidelines](../docs/docker-guidelines.md)**: Comprehensive service management patterns (1000+ lines)
- **[Services Reference](../docs/services-reference.md)**: All 60+ pre-configured services
- **[Proxying External Hosts](../docs/proxying-external-hosts.md)**: Traefik file provider patterns for non-Docker services
- **[Quick Reference](../docs/quick-reference.md)**: Command cheat sheet and troubleshooting

## Pre-Deployment Safety Checks

Before deploying any service changes:
- [ ] YAML syntax valid (`docker compose config`)
- [ ] No port conflicts (check `docker ps --format "table {{.Names}}\t{{.Ports}}"`)
- [ ] Networks exist (`docker network ls | grep -E 'traefik-network|homelab-network'`)
- [ ] Volume paths correct (`/opt/stacks/` for configs, `/mnt/` for large data)
- [ ] `.env` variables populated (source stack `.env` and check `echo $DOMAIN`)
- [ ] Traefik labels complete (enable, rule, entrypoint, tls, middleware)
- [ ] SSO appropriate (default enabled, bypass only for Plex/Jellyfin)
- [ ] VPN routing configured if download service (network_mode + Gluetun ports)
- [ ] LinuxServer.io image available (check hub.docker.com/u/linuxserver)

## Troubleshooting Common Issues

### Service Won't Start
```bash
docker compose logs SERVICE  # Check error messages
docker compose config        # Validate YAML syntax
docker ps -a | grep SERVICE  # Check exit code
```
Common causes: Port conflict, missing `.env` variable, network not found, volume permission denied

### Traefik Not Routing
```bash
docker logs traefik | grep SERVICE  # Check if route registered
curl -k https://traefik.${DOMAIN}/api/http/routers  # Inspect routes (if API enabled)
```
Verify: Service on `traefik-network`, labels correctly formatted, `traefik.enable=true`, Traefik restarted after label changes

### Authelia SSO Not Prompting
Check middleware: `docker compose config | grep -A5 SERVICE | grep authelia`
Verify: Authelia container running, middleware label present, no bypass rule in `authelia/configuration.yml`

### VPN Not Working (Gluetun)
```bash
docker exec gluetun sh -c "curl -s ifconfig.me"  # Check VPN IP
docker logs gluetun | grep -i wireguard           # Verify connection
```
Verify: `SURFSHARK_PRIVATE_KEY` set in `.env`, service using `network_mode: "service:gluetun"`, ports mapped in Gluetun

### Wildcard Certificate Issues
```bash
docker logs traefik | grep -i certificate
ls -lh /opt/stacks/core/traefik/acme.json  # Should be 600 permissions
```
Verify: DuckDNS token valid, `DUCKDNS_TOKEN` in `.env`, DNS propagation (wait 2-5 min), acme.json writable by Traefik

## AI Management Capabilities

You can manage this homelab by:
- **Creating services**: Generate compose files in `/opt/stacks/` with proper Traefik labels
- **Modifying routes**: Edit Traefik labels in compose files
- **Managing external hosts**: Update `/opt/stacks/core/traefik/dynamic/external.yml`
- **Configuring Homepage**: Edit `services.yaml`, `bookmarks.yaml` in homepage config
- **Toggling SSO**: Add/remove Authelia middleware labels
- **Adding VPN routing**: Change network_mode and update Gluetun ports
- **Environment management**: Update `.env` (but remind users to manually copy to stacks)

### What NOT to Do
- Never commit `.env` files to git (contain secrets)
- Don't use `docker run` for persistent services (use compose in `/opt/stacks/`)
- Don't manually request Let's Encrypt certs (Traefik handles via wildcard)
- Don't edit Authelia/Traefik config via web UI (use YAML files)
- Don't expose download clients without VPN (route through Gluetun)

## Quick Command Reference

```bash
# View all running containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check service logs
cd /opt/stacks/STACK && docker compose logs -f SERVICE

# Restart specific service
cd /opt/stacks/STACK && docker compose restart SERVICE

# Update images and redeploy
cd /opt/stacks/STACK && docker compose pull && docker compose up -d

# Validate compose file
docker compose -f /opt/stacks/STACK/docker-compose.yml config

# Check Traefik routes
docker logs traefik | grep -i "Creating router\|Adding route"

# Check network connectivity
docker exec SERVICE ping -c 2 traefik

# View environment variables
cd /opt/stacks/STACK && docker compose config | grep -A20 "environment:"

# Test NVIDIA GPU access
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

## User Context Notes

- **User**: kelin (PUID=1000, PGID=1000)
- **Repository**: `/home/kelin/AI-Homelab/`
- **Testing Phase**: Round 6+ (focus on reliability, error handling, deployment robustness)
- **Recent work**: Script automation, idempotent setup, health checks, automated secret generation

When interacting with users, prioritize **security** (SSO by default), **consistency** (follow existing patterns), and **stack-awareness** (consider service dependencies). Always explain the "why" behind architectural decisions and reference specific files/paths when describing changes.
