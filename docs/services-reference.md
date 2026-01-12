# Complete Services Reference

This document lists all 40+ pre-configured services available in the AI-Homelab repository, organized by category.

## Core Infrastructure (4 services)

### Required - Deploy First

1. **DuckDNS** (`duckdns.yml`)
   - Dynamic DNS updater
   - Updates your public IP automatically
   - Integrates with Let's Encrypt for SSL
   - No web UI - runs silently
   - Stack: `/opt/stacks/duckdns/`

2. **Traefik** (`traefik.yml`)
   - Reverse proxy with automatic SSL
   - HTTP to HTTPS redirect
   - File-based and Docker label routing
   - Dashboard: `https://traefik.${DOMAIN}`
   - Stack: `/opt/stacks/traefik/`

3. **Authelia** (`authelia.yml`)
   - Single Sign-On (SSO) authentication
   - TOTP 2FA support
   - File-based or LDAP user database
   - Smart bypass rules for media apps
   - Login: `https://auth.${DOMAIN}`
   - Stack: `/opt/stacks/authelia/`

4. **Gluetun** (`gluetun.yml`)
   - VPN client (Surfshark WireGuard)
   - Includes qBittorrent
   - Control panel: `http://gluetun:8000`
   - qBittorrent: `https://qbit.${DOMAIN}`
   - Stack: `/opt/stacks/gluetun/`

## Infrastructure Tools (7 services)

From `infrastructure.yml` - Stack: `/opt/stacks/infrastructure/`

5. **Dockge** (PRIMARY management tool)
   - Docker Compose stack manager
   - Web UI for managing /opt/stacks/
   - Direct compose file editing
   - Access: `https://dockge.${DOMAIN}`
   - SSO: Yes

6. **Portainer** (Secondary)
   - Docker container management UI
   - Access: `https://portainer.${DOMAIN}`
   - SSO: Yes

7. **Pi-hole**
   - Network-wide ad blocking
   - DNS server
   - Access: `https://pihole.${DOMAIN}`
   - SSO: Yes

8. **Watchtower**
   - Automatic container updates
   - Runs 4 AM daily
   - No web UI

9. **Dozzle**
   - Real-time Docker log viewer
   - Access: `https://dozzle.${DOMAIN}`
   - SSO: Yes

10. **Glances**
    - System and Docker monitoring
    - Access: `https://glances.${DOMAIN}`
    - SSO: Yes

11. **Docker Proxy**
    - Secure Docker socket access
    - Backend service
    - No web UI

## Dashboards (2 services)

From `dashboards.yml` - Stack: `/opt/stacks/dashboards/`

12. **Homepage** (AI-configurable)
    - Application dashboard with Docker integration
    - Service widgets for 15+ services
    - 11 organized categories
    - Access: `https://home.${DOMAIN}`
    - SSO: No (landing page)

13. **Homarr**
    - Modern alternative dashboard
    - Access: `https://homarr.${DOMAIN}`
    - SSO: No

## Media Services (6 services)

From `media.yml` - Stack: `/opt/stacks/media/`

14. **Plex**
    - Media streaming server
    - Hardware transcoding support
    - Access: `https://plex.${DOMAIN}`
    - SSO: No (app access)

15. **Jellyfin**
    - Open-source media server
    - Hardware transcoding support
    - Access: `https://jellyfin.${DOMAIN}`
    - SSO: No (app access)

16. **Sonarr**
    - TV show automation
    - Access: `https://sonarr.${DOMAIN}`
    - SSO: Yes

17. **Radarr**
    - Movie automation
    - Access: `https://radarr.${DOMAIN}`
    - SSO: Yes

18. **Prowlarr**
    - Indexer manager
    - Integrates with Sonarr, Radarr, etc.
    - Access: `https://prowlarr.${DOMAIN}`
    - SSO: Yes

19. **qBittorrent**
    - Torrent client (routes through Gluetun VPN)
    - See gluetun.yml

## Extended Media (10 services)

From `media-extended.yml` - Stack: `/opt/stacks/media-extended/`

20. **Readarr**
    - Ebook and audiobook management
    - Access: `https://readarr.${DOMAIN}`
    - SSO: Yes

21. **Lidarr**
    - Music collection manager
    - Access: `https://lidarr.${DOMAIN}`
    - SSO: Yes

22. **Lazy Librarian**
    - Book download automation
    - Access: `https://lazylibrarian.${DOMAIN}`
    - SSO: Yes

23. **Mylar3**
    - Comic book collection manager
    - Access: `https://mylar.${DOMAIN}`
    - SSO: Yes

24. **Calibre-Web**
    - Ebook reader and library management
    - Access: `https://calibre.${DOMAIN}`
    - SSO: Yes

25. **Jellyseerr**
    - Media request management
    - Integrates with Plex/Jellyfin
    - Access: `https://jellyseerr.${DOMAIN}`
    - SSO: No (family access)

26. **FlareSolverr**
    - Cloudflare bypass for indexers
    - Used by Prowlarr
    - No web UI

27. **Tdarr Server**
    - Distributed transcoding server
    - Access: `https://tdarr.${DOMAIN}`
    - SSO: Yes

28. **Tdarr Node**
    - Transcoding worker
    - No web UI

29. **Unmanic**
    - Library optimization and transcoding
    - Access: `https://unmanic.${DOMAIN}`
    - SSO: Yes

## Home Automation (7 services)

From `homeassistant.yml` - Stack: `/opt/stacks/homeassistant/`

30. **Home Assistant**
    - Home automation platform
    - Uses host networking
    - Access: `https://ha.${DOMAIN}` (or via proxying external host)
    - SSO: No (has own auth)

31. **ESPHome**
    - ESP8266/ESP32 firmware manager
    - Access: `https://esphome.${DOMAIN}`
    - SSO: Yes

32. **TasmoAdmin**
    - Tasmota device management
    - Access: `https://tasmoadmin.${DOMAIN}`
    - SSO: Yes

33. **Node-RED**
    - Flow-based automation programming
    - Access: `https://nodered.${DOMAIN}`
    - SSO: Yes

34. **Mosquitto**
    - MQTT message broker
    - Ports: 1883, 9001
    - No web UI

35. **Zigbee2MQTT**
    - Zigbee to MQTT bridge
    - Access: `https://zigbee2mqtt.${DOMAIN}`
    - SSO: Yes

36. **MotionEye**
    - Video surveillance system
    - Access: `https://motioneye.${DOMAIN}`
    - SSO: Yes

## Productivity (8 services + 6 databases)

From `productivity.yml` - Stack: `/opt/stacks/productivity/`

37. **Nextcloud**
    - File sync and collaboration platform
    - Access: `https://nextcloud.${DOMAIN}`
    - SSO: Yes
    - Database: nextcloud-db (MariaDB)

38. **Mealie**
    - Recipe manager and meal planner
    - Access: `https://mealie.${DOMAIN}`
    - SSO: No (family access)

39. **WordPress**
    - Blog and website platform
    - Access: `https://blog.${DOMAIN}`
    - SSO: No (public blog)
    - Database: wordpress-db (MariaDB)

40. **Gitea**
    - Self-hosted Git service
    - Access: `https://git.${DOMAIN}`
    - SSO: Yes
    - Database: gitea-db (PostgreSQL)

41. **DokuWiki**
    - File-based wiki (no database)
    - Access: `https://wiki.${DOMAIN}`
    - SSO: Yes

42. **BookStack**
    - Documentation platform
    - Access: `https://docs.${DOMAIN}`
    - SSO: Yes
    - Database: bookstack-db (MariaDB)

43. **MediaWiki**
    - Wiki platform
    - Access: `https://mediawiki.${DOMAIN}`
    - SSO: Yes
    - Database: mediawiki-db (MariaDB)

## Utilities (7 services)

From `utilities.yml` - Stack: `/opt/stacks/utilities/`

44. **Backrest**
    - Backup management with restic
    - Access: `https://backrest.${DOMAIN}`
    - SSO: Yes

45. **Duplicati**
    - Backup software with encryption
    - Access: `https://duplicati.${DOMAIN}`
    - SSO: Yes

46. **Uptime Kuma**
    - Uptime monitoring and status page
    - Access: `https://status.${DOMAIN}`
    - SSO: No (public status)

47. **Code Server**
    - VS Code in browser
    - Full stack access
    - Access: `https://code.${DOMAIN}`
    - SSO: Yes

48. **Form.io**
    - Form builder platform
    - Access: `https://forms.${DOMAIN}`
    - SSO: Yes
    - Database: formio-mongo (MongoDB)

49. **Authelia-Redis**
    - Session storage for Authelia
    - No web UI

## Monitoring (7 services)

From `monitoring.yml` - Stack: `/opt/stacks/monitoring/`

50. **Prometheus**
    - Metrics collection
    - Access: `https://prometheus.${DOMAIN}`
    - SSO: Yes

51. **Grafana**
    - Metrics visualization
    - Access: `https://grafana.${DOMAIN}`
    - SSO: Yes

52. **Loki**
    - Log aggregation
    - No web UI (accessed via Grafana)

53. **Promtail**
    - Log shipping to Loki
    - No web UI

54. **Node Exporter**
    - Host metrics exporter
    - No web UI

55. **cAdvisor**
    - Container metrics
    - Access: Port 8080 (internal)

## Development (6 services)

From `development.yml` - Stack: `/opt/stacks/development/`

56. **GitLab CE**
    - Git repository with CI/CD
    - Access: `https://gitlab.${DOMAIN}`
    - SSO: Yes

57. **PostgreSQL**
    - SQL database
    - Port: 5432
    - No web UI

58. **Redis**
    - In-memory data store
    - Port: 6379
    - No web UI

59. **pgAdmin**
    - PostgreSQL management UI
    - Access: `https://pgadmin.${DOMAIN}`
    - SSO: Yes

60. **Jupyter Lab**
    - Interactive notebooks
    - Access: `https://jupyter.${DOMAIN}`
    - SSO: Yes

## Summary by Stack

| Stack | File | Services Count | Description |
|-------|------|----------------|-------------|
| Core Infrastructure | Multiple files | 4 | Traefik, Authelia, DuckDNS, Gluetun |
| Infrastructure | infrastructure.yml | 7 | Dockge, Portainer, Pi-hole, etc. |
| Dashboards | dashboards.yml | 2 | Homepage, Homarr |
| Media | media.yml | 6 | Plex, Jellyfin, *arr apps |
| Media Extended | media-extended.yml | 10 | Books, comics, music, transcoding |
| Home Automation | homeassistant.yml | 7 | HA, ESPHome, Node-RED, MQTT, etc. |
| Productivity | productivity.yml | 14 | Nextcloud, wikis, Git (includes DBs) |
| Utilities | utilities.yml | 7 | Backups, monitoring, Code Server |
| Monitoring | monitoring.yml | 7 | Prometheus, Grafana, Loki |
| Development | development.yml | 6 | GitLab, databases, Jupyter |

**Total: 60+ services (including databases)**

## Access Patterns

### With SSO (Authelia Required)
- Admin tools (Sonarr, Radarr, Prowlarr, etc.)
- Infrastructure management (Dockge, Portainer, Grafana)
- Development tools (GitLab, Code Server, pgAdmin)
- Personal data (Nextcloud, wikis, BookStack)

### Without SSO (Direct Access)
- Media streaming (Plex, Jellyfin) - for app access
- Public services (WordPress, Uptime Kuma, Homepage)
- Services with own auth (Home Assistant)
- Family-friendly (Mealie, Jellyseerr)

### Via VPN (Gluetun)
- qBittorrent
- Other download clients (add with network_mode: "service:gluetun")

## Storage Recommendations

### Keep on System Drive (/opt/stacks/)
- All configuration files
- Small databases (< 10GB)
- Application data

### Move to Separate Drive (/mnt/)
- Media files (movies, TV, music, photos) → /mnt/media/
- Downloads → /mnt/downloads/
- Backups → /mnt/backups/
- Surveillance footage → /mnt/surveillance/
- Large databases → /mnt/databases/
- Transcoding cache → /mnt/transcode-cache/

## Quick Deployment Guide

1. **Core (Required)**
   ```bash
   # Deploy in this order:
   /opt/stacks/duckdns/
   /opt/stacks/traefik/
   /opt/stacks/authelia/
   /opt/stacks/infrastructure/ (dockge)
   ```

2. **VPN + Downloads**
   ```bash
   /opt/stacks/gluetun/
   ```

3. **Dashboard**
   ```bash
   /opt/stacks/homepage/
   ```

4. **Choose Your Stacks**
   - Media: `/opt/stacks/media/` + `/opt/stacks/media-extended/`
   - Home Automation: `/opt/stacks/homeassistant/`
   - Productivity: `/opt/stacks/productivity/`
   - Monitoring: `/opt/stacks/monitoring/`
   - Development: `/opt/stacks/development/`
   - Utilities: `/opt/stacks/utilities/`

## Configuration Files

All configuration templates available in `config-templates/`:
- `traefik/` - Static and dynamic configs
- `authelia/` - Config and user database
- `homepage/` - Dashboard services and widgets
- `prometheus/` - Scrape configurations
- `loki/` - Log aggregation config
- And more...

## Next Steps

1. Deploy core infrastructure
2. Configure Homepage with API keys
3. Set up Authelia users
4. Deploy service stacks as needed
5. Use VS Code + Copilot for AI assistance
6. Proxy external hosts via Traefik (see docs/proxying-external-hosts.md)

For detailed deployment instructions, see [docs/getting-started.md](../docs/getting-started.md)
