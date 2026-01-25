# Services Overview

This document provides a comprehensive overview of all 50+ pre-configured services available in the AI-Homelab repository.

## Services Overview

| Stacks (12) | Services (70 + 6db) | SSO | Storage | Access URLs |
|-------|----------|-----|---------|-------------|
| **📦 core.yaml (4)** | **Deploy First** | | | |
| ├─ DuckDNS | Dynamic DNS updater | - | /opt/stacks/core/duckdns | No UI |
| ├─ Traefik | Reverse proxy + SSL | ✓ | /opt/stacks/core/traefik | traefik.${DOMAIN} |
| ├─ Authelia | SSO authentication | - | /opt/stacks/core/authelia | auth.${DOMAIN} |
| └─ Sablier | Lazy loading service | - | /opt/stacks/core/sablier | No UI |
| **🔒 vpn.yaml (2)** | **VPN Services** | | | |
| ├─ Gluetun | VPN (Surfshark) | - | /opt/stacks/vpn/gluetun | No UI |
| └─ qBittorrent | Torrent (via VPN) | ✓ | /mnt/downloads | qbit.${DOMAIN} |
| **🔧 infrastructure.yaml** (6)** | | | | |
| ├─ Pi-hole | DNS + Ad blocking | ✓ | /opt/stacks/infrastructure | pihole.${DOMAIN} |
| ├─ Watchtower | Auto container updates | - | /opt/stacks/infrastructure | No UI |
| ├─ Dozzle | Docker log viewer | ✓ | /opt/stacks/infrastructure | dozzle.${DOMAIN} |
| ├─ Glances | System monitoring | ✓ | /opt/stacks/infrastructure | glances.${DOMAIN} |
| ├─ Code Server | VS Code in browser | ✓ | /opt/stacks/infrastructure | code.${DOMAIN} |
| └─ Docker Proxy | Secure socket access | - | /opt/stacks/infrastructure | No UI |
| **📊 dashboards.yaml** (2) | | | | |
| ├─ Homepage | App dashboard (AI cfg) | ✓ | /opt/stacks/dashboards | home.${DOMAIN} |
| └─ Homarr | Modern dashboard | ✓ | /opt/stacks/dashboards | homarr.${DOMAIN} |
| **🎬 media.yaml** (2) | | | | |
| ├─ Jellyfin | Media server (OSS) | ✗ | /mnt/media, /mnt/transcode | jellyfin.${DOMAIN} |
| └─ Calibre-Web | Ebook reader | ✓ | /opt/stacks/media, /mnt/media | calibre.${DOMAIN} |
| **📺 media-management.yaml** (9) | | | | |
| ├─ Sonarr | TV automation | ✓ | /opt/stacks/media-management, /mnt/media | sonarr.${DOMAIN} |
| ├─ Radarr | Movie automation | ✓ | /opt/stacks/media-management, /mnt/media | radarr.${DOMAIN} |
| ├─ Prowlarr | Indexer manager | ✓ | /opt/stacks/media-management | prowlarr.${DOMAIN} |
| ├─ Readarr | Ebooks/Audiobooks | ✓ | /opt/stacks/media-management, /mnt/media | readarr.${DOMAIN} |
| ├─ Lidarr | Music manager | ✓ | /opt/stacks/media-management, /mnt/media | lidarr.${DOMAIN} |
| ├─ Lazy Librarian | Book automation | ✓ | /opt/stacks/media-management, /mnt/media | lazylibrarian.${DOMAIN} |
| ├─ Mylar3 | Comic manager | ✓ | /opt/stacks/media-management, /mnt/media | mylar.${DOMAIN} |
| ├─ Jellyseerr | Media requests | ✓ | /opt/stacks/media-management | jellyseerr.${DOMAIN} |
| └─ FlareSolverr | Cloudflare bypass | - | /opt/stacks/media-management | No UI |
| **🔄 transcoders.yaml** (3) | | | | |
| ├─ Tdarr Server | Transcoding server | ✓ | /opt/stacks/transcoders, /mnt/transcode | tdarr.${DOMAIN} |
| ├─ Tdarr Node | Transcoding worker | - | /mnt/transcode-cache | No UI |
| └─ Unmanic | Library optimizer | ✓ | /opt/stacks/transcoders, /mnt/transcode | unmanic.${DOMAIN} |
| **📖 wikis.yaml** (4) | | | | |
| ├─ DokuWiki | File-based wiki | ✓ | /opt/stacks/wikis | dokuwiki.${DOMAIN} |
| ├─ BookStack | Documentation | ✓ | /opt/stacks/wikis | docs.${DOMAIN} |
| │  └─ bookstack-db | MariaDB | - | /opt/stacks/wikis | No UI |
| └─ MediaWiki | Wiki platform | ✓ | /opt/stacks/wikis | mediawiki.${DOMAIN} |
| **🏠 homeassistant.yaml** (6) | | | | |
| ├─ Home Assistant | HA platform | ✗ | /opt/stacks/homeassistant | ha.${DOMAIN} |
| ├─ ESPHome | ESP firmware mgr | ✓ | /opt/stacks/homeassistant | esphome.${DOMAIN} |
| ├─ TasmoAdmin | Tasmota device mgr | ✓ | /opt/stacks/homeassistant | tasmoadmin.${DOMAIN} |
| ├─ Node-RED | Automation flows | ✓ | /opt/stacks/homeassistant | nodered.${DOMAIN} |
| ├─ Mosquitto | MQTT broker | - | /opt/stacks/homeassistant | Ports 1883, 9001 |
| └─ Zigbee2MQTT | Zigbee bridge | ✓ | /opt/stacks/homeassistant | zigbee2mqtt.${DOMAIN} |
| **💼 productivity.yaml** (8 + 6 DBs) | | | | |
| ├─ Nextcloud | File sync platform | ✓ | /opt/stacks/productivity, /mnt/nextcloud | nextcloud.${DOMAIN} |
| │  └─ nextcloud-db | MariaDB | - | /opt/stacks/productivity | No UI |
| ├─ Mealie | Recipe manager | ✗ | /opt/stacks/productivity | mealie.${DOMAIN} |
| ├─ WordPress | Blog platform | ✗ | /opt/stacks/productivity | blog.${DOMAIN} |
| │  └─ wordpress-db | MariaDB | - | /opt/stacks/productivity | No UI |
| ├─ Gitea | Git service | ✓ | /opt/stacks/productivity, /mnt/git | git.${DOMAIN} |
| │  └─ gitea-db | PostgreSQL | - | /opt/stacks/productivity | No UI |
| └─ Jupyter Lab | Notebooks | ✓ | /opt/stacks/productivity | jupyter.${DOMAIN} |
| **🛠️ utilities.yaml** (5) | | | | |
| ├─ Vaultwarden | Password manager | ✗ | /opt/stacks/utilities | bitwarden.${DOMAIN} |
| ├─ Backrest | Backup (restic) | ✓ | /opt/stacks/utilities, /mnt/backups | backrest.${DOMAIN} |
| ├─ Duplicati | Encrypted backups | ✓ | /opt/stacks/utilities, /mnt/backups | duplicati.${DOMAIN} |
| ├─ Form.io | Form builder | ✓ | /opt/stacks/utilities | forms.${DOMAIN} |
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
| **🔧 alternatives.yaml** (6) | | | | |
| ├─ Dockge | Stack manager (PRIMARY) | ✓ | /opt/stacks/alternatives | dockge.${DOMAIN} |
| ├─ Portainer | Container management | ✓ | /opt/stacks/alternatives | portainer.${DOMAIN} |
| ├─ Authentik Server | SSO with web UI | ✓ | /opt/stacks/alternatives | authentik.${DOMAIN} |
| │  ├─ authentik-worker | Background tasks | - | /opt/stacks/alternatives | No UI |
| │  ├─ authentik-db | PostgreSQL | - | /opt/stacks/alternatives | No UI |
| │  └─ authentik-redis | Cache/messaging | - | /opt/stacks/alternatives | No UI |
| └─ Plex | Media server | ✗ | /mnt/media, /mnt/transcode | plex.${DOMAIN} |
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

## Quick Deployment Order

1. **Create Networks** (one-time setup)
   ```bash
   docker network create traefik-network
   docker network create homelab-network
   docker network create dockerproxy-network
   ```

2. **Deploy Core Stack** (required first)
   ```bash
   cd /opt/stacks/core/
   docker compose up -d
   ```

3. **Deploy Infrastructure**
   ```bash
   cd /opt/stacks/infrastructure/
   docker compose up -d
   ```

4. **Deploy Dashboards**
   ```bash
   cd /opt/stacks/dashboards/
   docker compose up -d
   ```

5. **Deploy Additional Stacks** (as needed)
   - Media: `/opt/stacks/media/`
   - Media Management: `/opt/stacks/media-management/`
   - Transcoders: `/opt/stacks/transcoders/`
   - Wikis: `/opt/stacks/wikis/`
   - Home Automation: `/opt/stacks/homeassistant/`
   - Productivity: `/opt/stacks/productivity/`
   - Utilities: `/opt/stacks/utilities/`
   - Monitoring: `/opt/stacks/monitoring/`
   - Alternatives: `/opt/stacks/alternatives/`

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

