# Services Overview

This document provides a comprehensive overview of all 60+ pre-configured services available in the AI-Homelab repository.

## Services Overview

| Stacks (10) | Services (70 + 6db) | SSO | Storage | Access URLs |
|-------|----------|-----|---------|-------------|
| **📦 core.yaml (4)** | **Deploy First** | | | |
| ├─ [DuckDNS](service-docs/duckdns.md) | Dynamic DNS updater | - | /opt/stacks/core/duckdns | No UI |
| ├─ [Traefik](service-docs/traefik.md) | Reverse proxy + SSL | ✓ | /opt/stacks/core/traefik | traefik.${DOMAIN} |
| ├─ [Authelia](service-docs/authelia.md) | SSO authentication | - | /opt/stacks/core/authelia | auth.${DOMAIN} |
| └─ [Gluetun](service-docs/gluetun.md) | VPN (Surfshark) | - | /opt/stacks/core/gluetun | No UI |
| **🔧 infrastructure.yaml (6+5)** | **Deployed: 6** | | | |
| ├─ [Dockge](service-docs/dockge.md) | Stack manager (PRIMARY) | ✓ | /opt/stacks/infrastructure | dockge.${DOMAIN} |
| ├─ [Pi-hole](service-docs/pihole.md) | DNS + Ad blocking | ✓ | /opt/stacks/infrastructure | pihole.${DOMAIN} |
| ├─ [Dozzle](service-docs/dozzle.md) | Docker log viewer | ✓ | /opt/stacks/infrastructure | dozzle.${DOMAIN} |
| ├─ [Glances](service-docs/glances.md) | System monitoring | ✓ | /opt/stacks/infrastructure | glances.${DOMAIN} |
| └─ [Docker Proxy](service-docs/docker-proxy.md) | Secure socket access | - | /opt/stacks/infrastructure | No UI |
| **📦 alternatives.yaml (5)** | **Not deployed** | | | |
| ├─ Portainer | Container management | ✓ | /opt/stacks/alternatives | portainer.${DOMAIN} |
| ├─ Authentik Server | SSO with web UI | ✓ | /opt/stacks/alternatives | authentik.${DOMAIN} |
| │  ├─ authentik-worker | Background tasks | - | /opt/stacks/alternatives | No UI |
| │  ├─ authentik-db | PostgreSQL | - | /opt/stacks/alternatives | No UI |
| │  └─ authentik-redis | Cache/messaging | - | /opt/stacks/alternatives | No UI |
| **📊 dashboards.yaml** (2) | | | | |
| ├─ Homepage | App dashboard (AI cfg) | ✓ | /opt/stacks/dashboards | home.${DOMAIN} |
| └─ Homarr | Modern dashboard | ✓ | /opt/stacks/dashboards | homarr.${DOMAIN} |
| **🎬 media** (6) | | | | |
| ├─ Plex | Media server | ✗ | /mnt/media, /mnt/transcode | plex.${DOMAIN} |
| ├─ Jellyfin | Media server (OSS) | ✗ | /mnt/media, /mnt/transcode | jellyfin.${DOMAIN} |
| ├─ Sonarr | TV automation | ✓ | /opt/stacks/media, /mnt/media | sonarr.${DOMAIN} |
| ├─ Radarr | Movie automation | ✓ | /opt/stacks/media, /mnt/media | radarr.${DOMAIN} |
| ├─ Prowlarr | Indexer manager | ✓ | /opt/stacks/media | prowlarr.${DOMAIN} |
| └─ qBittorrent | Torrent (via VPN) | ✓ | /mnt/downloads | qbit.${DOMAIN} |
| **📚 media-extended.yaml** (10) | | | | |
| ├─ Readarr | Ebooks/Audiobooks | ✓ | /opt/stacks/media-ext, /mnt/media | readarr.${DOMAIN} |
| ├─ Lidarr | Music manager | ✓ | /opt/stacks/media-ext, /mnt/media | lidarr.${DOMAIN} |
| ├─ Lazy Librarian | Book automation | ✓ | /opt/stacks/media-ext, /mnt/media | lazylibrarian.${DOMAIN} |
| ├─ Mylar3 | Comic manager | ✓ | /opt/stacks/media-ext, /mnt/media | mylar.${DOMAIN} |
| ├─ Calibre-Web | Ebook reader | ✓ | /opt/stacks/media-ext, /mnt/media | calibre.${DOMAIN} |
| ├─ Jellyseerr | Media requests | ✓ | /opt/stacks/media-ext | jellyseerr.${DOMAIN} |
| ├─ FlareSolverr | Cloudflare bypass | - | /opt/stacks/media-ext | No UI |
| ├─ Tdarr Server | Transcoding server | ✓ | /opt/stacks/media-ext, /mnt/transcode | tdarr.${DOMAIN} |
| ├─ Tdarr Node | Transcoding worker | - | /mnt/transcode-cache | No UI |
| └─ Unmanic | Library optimizer | ✓ | /opt/stacks/media-ext, /mnt/transcode | unmanic.${DOMAIN} |
| **🏠 homeassistant.yaml** (7) | | | | |
| ├─ Home Assistant | HA platform | ✗ | /opt/stacks/homeassistant | ha.${DOMAIN} |
| ├─ ESPHome | ESP firmware mgr | ✓ | /opt/stacks/homeassistant | esphome.${DOMAIN} |
| ├─ TasmoAdmin | Tasmota device mgr | ✓ | /opt/stacks/homeassistant | tasmoadmin.${DOMAIN} |
| ├─ Node-RED | Automation flows | ✓ | /opt/stacks/homeassistant | nodered.${DOMAIN} |
| ├─ Mosquitto | MQTT broker | - | /opt/stacks/homeassistant | Ports 1883, 9001 |
| ├─ Zigbee2MQTT | Zigbee bridge | ✓ | /opt/stacks/homeassistant | zigbee2mqtt.${DOMAIN} |
| └─ MotionEye | Video surveillance | ✓ | /opt/stacks/homeassistant, /mnt/surveillance | motioneye.${DOMAIN} |
| **💼 productivity.yaml** (8 + 6 DBs) | | | | |
| ├─ Nextcloud | File sync platform | ✓ | /opt/stacks/productivity, /mnt/nextcloud | nextcloud.${DOMAIN} |
| │  └─ nextcloud-db | MariaDB | - | /opt/stacks/productivity | No UI |
| ├─ Mealie | Recipe manager | ✗ | /opt/stacks/productivity | mealie.${DOMAIN} |
| ├─ WordPress | Blog platform | ✗ | /opt/stacks/productivity | blog.${DOMAIN} |
| │  └─ wordpress-db | MariaDB | - | /opt/stacks/productivity | No UI |
| ├─ Gitea | Git service | ✓ | /opt/stacks/productivity, /mnt/git | git.${DOMAIN} |
| │  └─ gitea-db | PostgreSQL | - | /opt/stacks/productivity | No UI |
| ├─ DokuWiki | File-based wiki | ✓ | /opt/stacks/productivity | wiki.${DOMAIN} |
| ├─ BookStack | Documentation | ✓ | /opt/stacks/productivity | docs.${DOMAIN} |
| │  └─ bookstack-db | MariaDB | - | /opt/stacks/productivity | No UI |
| ├─ MediaWiki | Wiki platform | ✓ | /opt/stacks/productivity | mediawiki.${DOMAIN} |
| │  └─ mediawiki-db | MariaDB | - | /opt/stacks/productivity | No UI |
| └─ Form.io | Form builder | ✓ | /opt/stacks/productivity | forms.${DOMAIN} |
|    └─ formio-mongo | MongoDB | - | /opt/stacks/productivity | No UI |
| **🛠️ utilities.yaml** (7) | | | | |
| ├─ Vaultwarden | Password manager | ✗ | /opt/stacks/utilities | bitwarden.${DOMAIN} |
| ├─ Backrest | Backup (restic) | ✓ | /opt/stacks/utilities, /mnt/backups | backrest.${DOMAIN} |
| ├─ Duplicati | Encrypted backups | ✓ | /opt/stacks/utilities, /mnt/backups | duplicati.${DOMAIN} |
| ├─ Code Server | VS Code in browser | ✓ | /opt/stacks/utilities | code.${DOMAIN} |
| ├─ Form.io | Form platform | ✓ | /opt/stacks/utilities | forms.${DOMAIN} |
| │  └─ formio-mongo | MongoDB | - | /opt/stacks/utilities | No UI |
| └─ Authelia-Redis | Session storage | - | /opt/stacks/utilities | No UI |
| **📈 monitoring.yaml** (8) | | | | |
| ├─ Prometheus | Metrics collection | ✓ | /opt/stacks/monitoring | prometheus.${DOMAIN} |
| ├─ Grafana | Visualization | ✓ | /opt/stacks/monitoring | grafana.${DOMAIN} |
| ├─ Loki | Log aggregation | - | /opt/stacks/monitoring | Via Grafana |
| ├─ Promtail | Log shipper | - | /opt/stacks/monitoring | No UI |
| ├─ Node Exporter | Host metrics | - | /opt/stacks/monitoring | No UI |
| ├─ cAdvisor | Container metrics | - | /opt/stacks/monitoring | Internal :8080 |
| └─ Uptime Kuma | Uptime monitoring | ✓ | /opt/stacks/monitoring | status.${DOMAIN} |
| **👨‍💻 development.yaml** (6) | | | | |
| ├─ GitLab CE | Git + CI/CD | ✓ | /opt/stacks/development, /mnt/git | gitlab.${DOMAIN} |
| ├─ PostgreSQL | SQL database | - | /opt/stacks/development | Port 5432 |
| ├─ Redis | In-memory store | - | /opt/stacks/development | Port 6379 |
| ├─ pgAdmin | PostgreSQL UI | ✓ | /opt/stacks/development | pgadmin.${DOMAIN} |
| ├─ Jupyter Lab | Notebooks | ✓ | /opt/stacks/development | jupyter.${DOMAIN} |
| └─ Code Server | VS Code | ✓ | /opt/stacks/development | code.${DOMAIN} |

**Legend:** ✓ = Protected by SSO | ✗ = Bypasses SSO | - = No web UI

## Toggling SSO (Authelia) On/Off

You can easily enable or disable SSO protection for any service by modifying its Traefik labels in the docker-compose.yml file.

### To Enable SSO on a Service

Add the Authelia middleware to the service's Traefik labels:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.servicename.rule=Host(`servicename.${DOMAIN}`)"
  - "traefik.http.routers.servicename.entrypoints=websecure"
  - "traefik.http.routers.servicename.tls.certresolver=letsencrypt"
  - "traefik.http.routers.servicename.middlewares=authelia@docker"  # ← Add this line
  - "traefik.http.services.servicename.loadbalancer.server.port=8080"
```

### To Disable SSO on a Service

Comment out (don't remove) the middleware line:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.servicename.rule=Host(`servicename.${DOMAIN}`)"
  - "traefik.http.routers.servicename.entrypoints=websecure"
  - "traefik.http.routers.servicename.tls.certresolver=letsencrypt"
  # - "traefik.http.routers.servicename.middlewares=authelia@docker"  # ← Commented out (not removed)
  - "traefik.http.services.servicename.loadbalancer.server.port=8080"
```

After making changes, redeploy the service:

```bash
# From inside the stack directory
cd /opt/stacks/stack-name/
docker compose up -d

# Or from anywhere, using the full path
docker compose -f /opt/stacks/stack-name/docker-compose.yml up -d
```

**Stopping a Service:**

```bash
# From inside the stack directory
cd /opt/stacks/stack-name/
docker compose down

# Or from anywhere, using the full path
docker compose -f /opt/stacks/stack-name/docker-compose.yml down
```

**Use Cases for Development/Production:**
- **Security First**: All services start with SSO enabled by default for maximum security
- **Development**: Keep SSO enabled to protect services during testing
- **Production**: Disable SSO only for services needing direct app/API access (Plex, Jellyfin)
- **Gradual Exposure**: Comment out SSO only when ready to expose a service
- **Quick Toggle**: AI assistant can modify these labels automatically when you ask

## Storage Recommendations

| Data Type | Recommended Location | Reason |
|-----------|---------------------|--------|
| Configuration files | `/opt/stacks/stack-name/` | Easy access, version control |
| Small databases (< 10GB) | `/opt/stacks/stack-name/db/` | Manageable on system drive |
| Media files (movies, TV, music) | `/mnt/media/` | Large, continuous growth |
| Downloads | `/mnt/downloads/` | Temporary, high throughput |
| Backups | `/mnt/backups/` | Large, separate from system |
| Surveillance footage | `/mnt/surveillance/` | Continuous recording |
| Large databases (> 10GB) | `/mnt/databases/` | Growth over time |
| Transcoding cache | `/mnt/transcode-cache/` | High I/O, large temporary files |
| Git repositories | `/mnt/git/` | Can grow large |
| Nextcloud data | `/mnt/nextcloud/` | User files, photos |

## Configuration Templates

All configuration templates are available in `config-templates/`:
- `traefik/` - Static and dynamic Traefik configuration
- `authelia/` - Complete Authelia setup with user database
- `homepage/` - Dashboard services, widgets, and Docker integration
- `prometheus/` - Metrics scrape configurations
- `loki/` - Log aggregation settings
- `promtail/` - Log shipping configuration
- `redis/` - Redis server configuration

## Additional Resources

- **Getting Started**: See [docs/getting-started.md](getting-started.md) for detailed deployment
- **Docker Guidelines**: See [docs/docker-guidelines.md](docker-guidelines.md) for management patterns
- **Quick Reference**: See [docs/quick-reference.md](quick-reference.md) for common commands
- **Proxying External Hosts**: See [docs/proxying-external-hosts.md](proxying-external-hosts.md) for Raspberry Pi, NAS, etc.
- **AI Assistant**: Use GitHub Copilot in VS Code with `.github/copilot-instructions.md` for intelligent homelab management
