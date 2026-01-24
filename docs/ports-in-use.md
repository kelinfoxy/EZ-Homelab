# Ports in Use

This document tracks all ports used by services in the EZ-Homelab. Update this document whenever services are added or ports are changed.

| Stack | Service | External Port | Internal Port | Protocol | Purpose |
|-------|---------|---------------|---------------|----------|---------|
| **Core** | [Traefik](../service-docs/traefik.md) | 80 | 80 | TCP | HTTP (redirects to HTTPS) |
| **Core** | [Traefik](../service-docs/traefik.md) | 443 | 443 | TCP | HTTPS |
| **Core** | [Traefik](../service-docs/traefik.md) | 8080 | 8080 | TCP | Dashboard (protected) |
| **Infrastructure** | [Dockge](../service-docs/dockge.md) | 5001 | 5001 | TCP | Web UI |
| **Infrastructure** | [Pi-hole](../service-docs/pihole.md) | 53 | 53 | TCP/UDP | DNS |
| **Infrastructure** | [Docker Proxy](../service-docs/docker-proxy.md) | 127.0.0.1:2375 | 2375 | TCP | Docker API proxy |
| **Home Assistant** | [ESPHome](../service-docs/esphome.md) | 6052 | 6052 | TCP | Web UI |
| **Home Assistant** | [TasmoAdmin](../service-docs/tasmoadmin.md) | 8084 | 80 | TCP | Web UI |
| **Home Assistant** | [MotionEye](../service-docs/motioneye.md) | 8765 | 8765 | TCP | Web UI |
| **Home Assistant** | [Node-RED](../service-docs/nodered.md) | 1880 | 1880 | TCP | Web UI |
| **Home Assistant** | [Mosquitto](../service-docs/mosquitto.md) | 1883 | 1883 | TCP | MQTT |
| **Home Assistant** | [Mosquitto](../service-docs/mosquitto.md) | 9001 | 9001 | TCP | MQTT Websockets |
| **Media** | [Jellyfin](../service-docs/jellyfin.md) | 8096 | 8096 | TCP | Web UI |
| **Media** | [Calibre-Web](../service-docs/calibre-web.md) | 8083 | 8083 | TCP | Web UI |
| **Media Management** | [Sonarr](../service-docs/sonarr.md) | 8989 | 8989 | TCP | Web UI |
| **Media Management** | [Radarr](../service-docs/radarr.md) | 7878 | 7878 | TCP | Web UI |
| **Media Management** | [Prowlarr](../service-docs/prowlarr.md) | 9696 | 9696 | TCP | Web UI |
| **Media Management** | [Readarr](../service-docs/readarr.md) | 8787 | 8787 | TCP | Web UI |
| **Media Management** | [Lidarr](../service-docs/lidarr.md) | 8686 | 8686 | TCP | Web UI |
| **Media Management** | [Lazylibrarian](../service-docs/lazylibrarian.md) | 5299 | 5299 | TCP | Web UI |
| **Media Management** | [Mylar3](../service-docs/mylar3.md) | 8090 | 8090 | TCP | Web UI |
| **Media Management** | [Jellyseerr](../service-docs/jellyseerr.md) | 5055 | 5055 | TCP | Web UI |
| **Media Management** | [Unmanic](../service-docs/unmanic.md) | 8888 | 8888 | TCP | Web UI |
| **Media Management** | [Tdarr Server](../service-docs/tdarr.md) | 8266 | 8266 | TCP | Web UI |
| **Media Management** | [Tdarr Node](../service-docs/tdarr.md) | 8267 | 8267 | TCP | Worker port |
| **Media Management** | [Flaresolverr](../service-docs/flaresolverr.md) | 8191 | 8191 | TCP | HTTP proxy |
| **Monitoring** | [Prometheus](../service-docs/prometheus.md) | 9090 | 9090 | TCP | Web UI/Metrics |
| **Monitoring** | [Grafana](../service-docs/grafana.md) | 3000 | 3000 | TCP | Web UI |
| **Monitoring** | [cAdvisor](../service-docs/cadvisor.md) | 8082 | 8080 | TCP | Web UI |
| **Monitoring** | [Uptime Kuma](../service-docs/uptime-kuma.md) | 3001 | 3001 | TCP | Web UI |
| **Monitoring** | [Loki](../service-docs/loki.md) | 3100 | 3100 | TCP | Web UI |
| **Monitoring** | [Node Exporter](../service-docs/node-exporter.md) | 9100 | 9100 | TCP | Metrics |
| **Utilities** | [Backrest](../service-docs/backrest.md) | 9898 | 9898 | TCP | Web UI |
| **Utilities** | [Duplicati](../service-docs/duplicati.md) | 8200 | 8200 | TCP | Web UI |
| **Utilities** | [Form.io](../service-docs/formio.md) | 3002 | 3001 | TCP | Web UI |
| **Utilities** | [Vaultwarden](../service-docs/vaultwarden.md) | 80 | 80 | TCP | Internal port |
| **VPN** | [Gluetun](../service-docs/gluetun.md) | 8888 | 8888 | TCP | HTTP proxy |
| **VPN** | [Gluetun](../service-docs/gluetun.md) | 8388 | 8388 | TCP/UDP | Shadowsocks |
| **VPN** | [Gluetun](../service-docs/gluetun.md) | 8081 | 8080 | TCP | qBittorrent Web UI |
| **VPN** | [Gluetun](../service-docs/gluetun.md) | 6881 | 6881 | TCP/UDP | qBittorrent |
| **VPN** | [qBittorrent](../service-docs/qbittorrent.md) | N/A | N/A | N/A | Routed through Gluetun |
| **Productivity** | [DokuWiki](../service-docs/dokuwiki.md) | 80 | 80 | TCP | Internal port |
| **Productivity** | [Nextcloud](../service-docs/nextcloud.md) | 80 | 80 | TCP | Internal port |
| **Productivity** | [Gitea](../service-docs/gitea.md) | 3010 | 3000 | TCP | Web UI |
| **Productivity** | [MinIO](../service-docs/minio.md) | 9000 | 9000 | TCP | API |
| **Productivity** | [MinIO](../service-docs/minio.md) | 9001 | 9001 | TCP | Web UI |
| **Productivity** | [MediaWiki](../service-docs/mediawiki.md) | 8086 | 80 | TCP | Web UI |

## Port Range Reference

| Range | Usage |
|-------|-------|
| 1-1023 | System ports (well-known) |
| 1024-49151 | Registered ports |
| 49152-65535 | Dynamic/private ports |

## Common Port Conflicts

- **Port 80**: Used by Traefik for HTTP (conflicts with internal services only)
- **Port 3000**: Used by Grafana
- **Port 3001**: Used by Uptime Kuma
- **Port 8888**: Used by Gluetun HTTP proxy
- **Port 53**: Used by Pi-hole for DNS
- **Port 2375**: Used by Docker Proxy (localhost only)
- **Port 5001**: Used by Dockge
- **Port 8080**: Used by Traefik dashboard
- **Port 9090**: Used by Prometheus

## Adding New Services

When adding new services:

1. Check this document for available ports
2. Choose ports that don't conflict with existing services
3. Update this document with new port mappings
4. Consider using Traefik labels instead of direct port exposure for web services

## Port Planning Guidelines

- **Web services**: Use Traefik labels (no direct ports needed)
- **Databases**: Use internal networking only (no external ports)
- **VPN services**: Route through Gluetun for security
- **Development tools**: Consider localhost-only binding (127.0.0.1:port)
- **Monitoring**: Use high-numbered ports (9000+ range)

## Updating This Document

This document should be updated whenever:
- New services are added to any stack
- Existing services change their port mappings
- Services are removed from stacks
- Network configurations change

Run this command to find all port mappings in compose files:
```bash
grep -r "ports:" docker-compose/ | grep -v "^#" | sort
```
