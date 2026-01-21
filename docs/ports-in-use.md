# Ports in Use

This document tracks all ports used by services in the AI-Homelab. Update this document whenever services are added or ports are changed.

## Core Stack ([core.yml](../docker-compose/core.yml))

| Service | Port | Protocol | Purpose | Internal Port |
|---------|------|----------|---------|---------------|
| [Traefik](../service-docs/traefik.md) | 80 | TCP | HTTP (redirects to HTTPS) | 80 |
| [Traefik](../service-docs/traefik.md) | 443 | TCP | HTTPS | 443 |
| [Traefik](../service-docs/traefik.md) | 8080 | TCP | Dashboard (protected) | 8080 |

## Infrastructure Stack ([infrastructure.yml](../docker-compose/infrastructure.yml))

| Service | Port | Protocol | Purpose | Internal Port |
|---------|------|----------|---------|---------------|
| [Dockge](../service-docs/dockge.md) | 5001 | TCP | Web UI | 5001 |
| [Pi-hole](../service-docs/pihole.md) | 53 | TCP/UDP | DNS | 53 |
| [Docker Proxy](../service-docs/docker-proxy.md) | 127.0.0.1:2375 | TCP | Docker API proxy | 2375 |

## Development Stack ([development.yml](../docker-compose/development.yml))

| Service | Port | Protocol | Purpose | Internal Port |
|---------|------|----------|---------|---------------|
| [PostgreSQL](../service-docs/postgresql.md) | 5432 | TCP | Database | 5432 |
| [Redis](../service-docs/redis.md) | 6379 | TCP | Cache/Database | 6379 |

## Home Assistant Stack ([homeassistant.yml](../docker-compose/homeassistant.yml))

| Service | Port | Protocol | Purpose | Internal Port |
|---------|------|----------|---------|---------------|
| [MotionEye](../service-docs/motioneye.md) | 8765 | TCP | Web UI | 8765 |
| [Mosquitto](../service-docs/mosquitto.md) | 1883 | TCP | MQTT | 1883 |
| [Mosquitto](../service-docs/mosquitto.md) | 9001 | TCP | MQTT Websockets | 9001 |

## Monitoring Stack ([monitoring.yml](../docker-compose/monitoring.yml))

| Service | Port | Protocol | Purpose | Internal Port |
|---------|------|----------|---------|---------------|
| [Prometheus](../service-docs/prometheus.md) | 9090 | TCP | Web UI/Metrics | 9090 |

## VPN Stack ([vpn.yml](../docker-compose/vpn.yml))

| Service | Port | Protocol | Purpose | Internal Port |
|---------|------|----------|---------|---------------|
| [Gluetun](../service-docs/gluetun.md) | 8888 | TCP | HTTP proxy | 8888 |
| [Gluetun](../service-docs/gluetun.md) | 8388 | TCP/UDP | Shadowsocks | 8388 |
| [Gluetun](../service-docs/gluetun.md) | 8081 | TCP | qBittorrent Web UI | 8080 |
| [Gluetun](../service-docs/gluetun.md) | 6881 | TCP/UDP | qBittorrent | 6881 |

## Port Range Reference

| Range | Usage |
|-------|-------|
| 1-1023 | System ports (well-known) |
| 1024-49151 | Registered ports |
| 49152-65535 | Dynamic/private ports |

## Common Port Conflicts

- **Port 80/443**: Used by Traefik for HTTP/HTTPS
- **Port 53**: Used by Pi-hole for DNS
- **Port 2375**: Used by Docker Proxy (localhost only)
- **Port 5001**: Used by Dockge
- **Port 5432**: Used by PostgreSQL
- **Port 6379**: Used by Redis
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