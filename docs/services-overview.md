# Services Overview

This document provides a comprehensive overview of all 50+ pre-configured services available in the AI-Homelab repository.

## Services Overview

| Stacks (12) | Services (50 + 6db) | SSO | Storage | Access URLs |
|-------|----------|-----|---------|-------------|
| **📦 core.yaml (3)** | **Deploy First** | | | |
| ├─ DuckDNS | Dynamic DNS updater | - | /opt/stacks/core/duckdns | No UI |
| ├─ Traefik | Reverse proxy + SSL | ✓ | /opt/stacks/core/traefik | traefik.${DOMAIN} |
| └─ Authelia | SSO authentication | - | /opt/stacks/core/authelia | auth.${DOMAIN} |
| &nbsp;
| **🔄 sablier.yaml (1)** | **Deploy on Each Server** | | | |
| └─ Sablier | Lazy loading service | - | /opt/stacks/sablier | sablier.${DOMAIN} |
| &nbsp;
| **📊 dashboards.yaml** (2) | | | | |
| ├─ Homepage | App dashboard (AI cfg) | ✓ | /opt/stacks/dashboards | home.${DOMAIN} |
| └─ Homarr | Modern dashboard | ✓ | /opt/stacks/dashboards | homarr.${DOMAIN} |
| &nbsp;
| **🏠 homeassistant.yaml** (7) | | | | |
| ├─ Home Assistant | HA platform | ✗ | /opt/stacks/homeassistant | ha.${DOMAIN} |
| ├─ ESPHome | ESP firmware mgr | ✓ | /opt/stacks/homeassistant | esphome.${DOMAIN} |
| ├─ TasmoAdmin | Tasmota device mgr | ✓ | /opt/stacks/homeassistant | tasmoadmin.${DOMAIN} |
| ├─ Node-RED | Automation flows | ✓ | /opt/stacks/homeassistant | nodered.${DOMAIN} |
| ├─ Mosquitto | MQTT broker | - | /opt/stacks/homeassistant | Ports 1883, 9001 |
| ├─ Zigbee2MQTT | Zigbee bridge | ✓ | /opt/stacks/homeassistant | zigbee2mqtt.${DOMAIN} |
| └─ MotionEye | Video surveillance | ✓ | /opt/stacks/homeassistant, /mnt/surveillance | motioneye.${DOMAIN} |
| &nbsp;
| **🔧 infrastructure.yaml** (6)** | | | | |
| ├─ Pi-hole | DNS + Ad blocking | ✓ | /opt/stacks/infrastructure | pihole.${DOMAIN} |
| ├─ Watchtower | Auto container updates | - | /opt/stacks/infrastructure | No UI |
| ├─ Dozzle | Docker log viewer | ✓ | /opt/stacks/infrastructure | dozzle.${DOMAIN} |
| ├─ Glances | System monitoring | ✓ | /opt/stacks/infrastructure | glances.${DOMAIN} |
| ├─ Code Server | VS Code in browser | ✓ | /opt/stacks/infrastructure | code.${DOMAIN} |
| └─ Docker Proxy | Secure socket access | - | /opt/stacks/infrastructure | No UI |
| &nbsp;
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
| &nbsp;
| **🎬 media.yaml** (2) | | | | |
| ├─ Jellyfin | Media server (OSS) | ✗ | /mnt/media, /mnt/transcode | jellyfin.${DOMAIN} |
| └─ Calibre-Web | Ebook reader | ✓ | /opt/stacks/media, /mnt/media | calibre.${DOMAIN} |
| &nbsp;
| **📈 monitoring.yaml** (8) | | | | |
| ├─ Prometheus | Metrics collection | ✓ | /opt/stacks/monitoring | prometheus.${DOMAIN} |
| ├─ Grafana | Visualization | ✓ | /opt/stacks/monitoring | grafana.${DOMAIN} |
| ├─ Loki | Log aggregation | - | /opt/stacks/monitoring | Via Grafana |
| ├─ Promtail | Log shipper | - | /opt/stacks/monitoring | No UI |
| ├─ Node Exporter | Host metrics | - | /opt/stacks/monitoring | No UI |
| ├─ cAdvisor | Container metrics | - | /opt/stacks/monitoring | Internal :8080 |
| └─ Uptime Kuma | Uptime monitoring | ✓ | /opt/stacks/monitoring | status.${DOMAIN} |
| &nbsp;
| **💼 productivity.yaml** (5 + 4 DBs) | | | | |
| ├─ Nextcloud | File sync platform | ✓ | /opt/stacks/productivity, /mnt/nextcloud | nextcloud.${DOMAIN} |
| │  └─ nextcloud-db | MariaDB | - | /opt/stacks/productivity | No UI |
| ├─ Mealie | Recipe manager | ✗ | /opt/stacks/productivity | mealie.${DOMAIN} |
| ├─ WordPress | Blog platform | ✗ | /opt/stacks/productivity | blog.${DOMAIN} |
| │  └─ wordpress-db | MariaDB | - | /opt/stacks/productivity | No UI |
| ├─ Gitea | Git service | ✓ | /opt/stacks/productivity, /mnt/git | git.${DOMAIN} |
| │  └─ gitea-db | PostgreSQL | - | /opt/stacks/productivity | No UI |
| └─ Jupyter Lab | Notebooks | ✓ | /opt/stacks/productivity | jupyter.${DOMAIN} |
| &nbsp;
| **🔄 transcoders.yaml** (3) | | | | |
| ├─ Tdarr Server | Transcoding server | ✓ | /opt/stacks/transcoders, /mnt/transcode | tdarr.${DOMAIN} |
| ├─ Tdarr Node | Transcoding worker | - | /mnt/transcode-cache | No UI |
| └─ Unmanic | Library optimizer | ✓ | /opt/stacks/transcoders, /mnt/transcode | unmanic.${DOMAIN} |
| &nbsp;
| **🛠️ utilities.yaml** (7) | | | | |
| ├─ Vaultwarden | Password manager | ✗ | /opt/stacks/utilities | bitwarden.${DOMAIN} |
| ├─ Backrest | Backup (restic) | ✓ | /opt/stacks/utilities, /mnt/backups | backrest.${DOMAIN} |
| ├─ Duplicati | Encrypted backups | ✓ | /opt/stacks/utilities, /mnt/backups | duplicati.${DOMAIN} |
| ├─ Code Server | VS Code in browser | ✓ | /opt/stacks/utilities | code.${DOMAIN} |
| ├─ Form.io | Form platform | ✓ | /opt/stacks/utilities | forms.${DOMAIN} |
| │  └─ formio-mongo | MongoDB | - | /opt/stacks/utilities | No UI |
| └─ Authelia-Redis | Session storage | - | /opt/stacks/utilities | No UI |
| &nbsp;
| **🔒 vpn.yaml (2)** | **VPN Services** | | | |
| ├─ Gluetun | VPN (Surfshark) | - | /opt/stacks/vpn/gluetun | No UI |
| └─ qBittorrent | Torrent (via VPN) | ✓ | /mnt/downloads | qbit.${DOMAIN} |
| &nbsp;
| **📖 wikis.yaml** (4) | | | | |
| ├─ DokuWiki | File-based wiki | ✓ | /opt/stacks/wikis | dokuwiki.${DOMAIN} |
| ├─ BookStack | Documentation | ✓ | /opt/stacks/wikis | docs.${DOMAIN} |
| │  └─ bookstack-db | MariaDB | - | /opt/stacks/wikis | No UI |
| └─ MediaWiki | Wiki platform | ✓ | /opt/stacks/wikis | mediawiki.${DOMAIN} |
| &nbsp;
| **🔀 alternatives.yaml** (6 + 3 DBs) | | | | |
| ├─ Portainer | Container management | ✓ | /opt/stacks/alternatives | portainer.${DOMAIN} |
| ├─ Authentik Server | SSO with web UI | ✓ | /opt/stacks/alternatives | authentik.${DOMAIN} |
| │  ├─ authentik-worker | Background tasks | - | /opt/stacks/alternatives | No UI |
| │  ├─ authentik-db | PostgreSQL | - | /opt/stacks/alternatives | No UI |
| │  └─ authentik-redis | Cache/messaging | - | /opt/stacks/alternatives | No UI |
| └─ Plex | Media server | ✗ | /mnt/media, /mnt/transcode | plex.${DOMAIN} |

**Legend:** ✓ = Protected by SSO | ✗ = Bypasses SSO | - = No web UI

## Service Configuration

Some services require no initial configuration (ie. creates it on first run if needed)

### Other services have config files/folders in the stack folder for easy deployment.  
* These typicaly use values from variables in .env however **can not access the variables.**  
* `ez-homelab.sh` handles variable replacement on deployment.    
* Each stack folder contains a `deploy-stacksname.sh` that will do the same for that stack.


## Multi-Server Deployment Notes

### Core Server `There can be only one`

`Forward ports 80 & 443 from your router`

- **DuckDNS**: Dynamic DNS and SSL certificate management
- **Authelia**: Centralized SSO authentication for all servers
- **Traefik** (core): Multi-provider configuration to route to all servers

### Remote Server Services (Deploy on Each Server)
- **Traefik** (local): Discovers containers through labels
- **Sablier**: Manages lazy loading for local containers only
- **Dockge**: Stack management interface

### Architecture Overview
- **TLS Communication**: Remote servers connect via Docker TLS (port 2376)
- **Unified Access**: All services accessible through core server domain
- **Service Routing**: Having Traefik on every server enables label based service discovery
- **Lazy Loading**: Having Sablier on every server enables label based lazy loading configuration 

