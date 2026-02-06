# Docker Compose Stacks

This directory contains Docker Compose templates for managing your homelab services. Each stack is organized in its own folder for better organization and maintainability.

## Structure

```
docker-compose/
├── core/              # Core infrastructure (MUST DEPLOY FIRST)
│   ├── docker-compose.yml
│   ├── authelia/      # SSO configuration
│   ├── duckdns/       # DNS configuration
│   └── traefik/       # Reverse proxy configuration
│       └── dynamic/   # External routing YAML files (multi-server)
├── sablier/           # Lazy loading service (per-server)
├── dockge/            # Docker management web UI
├── infrastructure/    # Additional infrastructure (Pi-hole, etc.)
├── dashboards/        # Dashboard services (Homepage, Homarr)
├── media/             # Media services (Plex, Jellyfin, etc.)
├── media-management/  # *arr services (Sonarr, Radarr, etc.)
├── monitoring/        # Observability stack (Prometheus, Grafana, etc.)
├── homeassistant/     # Home Assistant stack
├── productivity/      # Productivity tools (Nextcloud, Gitea, etc.)
├── utilities/         # Utility services (Duplicati, FreshRSS, etc.)
├── wikis/             # Mediawiki, Dokuwiki, Bookstacks
└── vpn/               # VPN services (Gluetun, qBittorrent)
```

## Multi-Server Architecture

EZ-Homelab supports two deployment models:

### **Single Server:**
- Core + all other stacks on one machine
- Simplest setup for beginners

### **Multi-Server:**
- **Core Server**: DuckDNS, Traefik (multi-provider), Authelia
- **Remote Servers**: Traefik (local-only), Sablier (local-only), application services
- All services accessed through unified domain

See [docs/Ondemand-Remote-Services.md](../docs/Ondemand-Remote-Services.md) for multi-server setup.

## Deployment

Use the unified setup script:
```bash
cd ~/EZ-Homelab
./scripts/ez-homelab.sh
```

## Single Server Traefik service labels

```yaml
services:
  myservice:
    labels:
      # TRAEFIK CONFIGURATION
      # ==========================================
      # Service metadata
      - "com.centurylinklabs.watchtower.enable=true"
      - "homelab.category=category-name"
      - "homelab.description=Brief service description"
      # Traefik labels
      - "traefik.enable=true"
      # Router configuration
      - "traefik.http.routers.myservice.rule=Host(`myservice.${DOMAIN}`)"
      - "traefik.http.routers.myservice.entrypoints=websecure"
      - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
      - "traefik.http.routers.myservice.middlewares=authelia@docker"  # SSO (remove to disable)
      # Service configuration
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"
      # Sablier configuration (lazy loading)
      - "sablier.enable=true"
      - "sablier.group=${SERVER_HOSTNAME}-myservice"
      - "sablier.start-on-demand=true"
```

## Multi-Server Traefik

### On Core Server


## On Remote Server


### Disabling SSO (Media Servers)

Remove or comment the authelia middleware line:
```yaml
# SSO enabled (default):
- "traefik.http.routers.myservice.middlewares=authelia@docker"

# SSO disabled (for Plex, Jellyfin, etc.):
# - "traefik.http.routers.myservice.middlewares=authelia@docker"
```

### Disabling Lazy Loading (Always-On Services)

Remove Sablier labels and use `restart: unless-stopped`:
```yaml
services:
  myservice:
    restart: unless-stopped  # Always running
    # No sablier labels
```

## Best Practices

1. **Pin Versions**: Always specify image versions (e.g., `nginx:1.25.3` not `nginx:latest`)
2. **Use Labels**: Add labels for organization and documentation
3. **Health Checks**: Define health checks for critical services
4. **Resource Limits**: Set memory and CPU limits for resource-intensive services
5. **Logging**: Configure log rotation to prevent disk space issues
6. **Restart Policies**: Use `unless-stopped` for most services
7. **Comments**: Document non-obvious configurations

## Template

When creating a new service, use this template:

```yaml
services:
  service-name:
    image: vendor/image:version
    container_name: service-name
    restart: unless-stopped
    networks:
      - homelab-network
      - traefik-network
    ports:
      - "host_port:container_port"
    volumes:
      - ./config/service-name:/config
      - service-data:/data
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:port/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    labels:
      - "homelab.category=category"
      - "homelab.description=Service description"

volumes:
  service-data:
    driver: local

networks:
  homelab-network:
    external: true
```
