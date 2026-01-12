# Docker Compose Stacks

This directory contains Docker Compose files for managing your homelab services. Each file is organized by functional area to maintain clarity and organization.

## Structure

```
docker-compose/
├── infrastructure.yml  # Core services (reverse proxy, DNS, etc.)
├── media.yml          # Media server services (Plex, Jellyfin, etc.)
├── monitoring.yml     # Observability stack (Prometheus, Grafana, etc.)
├── development.yml    # Development tools and services
└── README.md          # This file
```

## Usage

### Starting Services

Start all services in a compose file:
```bash
docker compose -f docker-compose/infrastructure.yml up -d
```

Start a specific service:
```bash
docker compose -f docker-compose/media.yml up -d plex
```

Start multiple compose files together:
```bash
docker compose -f docker-compose/infrastructure.yml -f docker-compose/media.yml up -d
```

### Stopping Services

Stop all services in a compose file:
```bash
docker compose -f docker-compose/infrastructure.yml down
```

Stop a specific service:
```bash
docker compose -f docker-compose/media.yml stop plex
```

### Viewing Status

Check running services:
```bash
docker compose -f docker-compose/media.yml ps
```

View logs:
```bash
docker compose -f docker-compose/media.yml logs -f plex
```

### Updating Services

Pull latest images:
```bash
docker compose -f docker-compose/media.yml pull
```

Update a specific service:
```bash
docker compose -f docker-compose/media.yml pull plex
docker compose -f docker-compose/media.yml up -d plex
```

## Networks

All services connect to a shared bridge network called `homelab-network`. Create it once:

```bash
docker network create homelab-network
```

Some services may use additional networks for security isolation:
- `monitoring-network` - For monitoring stack
- `database-network` - For database isolation
- `media-network` - For media services

Create them as needed:
```bash
docker network create monitoring-network
docker network create database-network
docker network create media-network
```

## Environment Variables

Create a `.env` file in the root of your homelab directory with common variables:

```bash
# .env
PUID=1000
PGID=1000
TZ=America/New_York
USERDIR=/home/username/homelab
DATADIR=/mnt/data
```

Never commit `.env` files to git! Use `.env.example` as a template instead.

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

## Troubleshooting

### Service won't start
1. Check logs: `docker compose -f file.yml logs service-name`
2. Validate config: `docker compose -f file.yml config`
3. Check for port conflicts: `sudo netstat -tlnp | grep PORT`
4. Verify volumes exist and have correct permissions

### Permission errors
1. Ensure PUID and PGID match your user: `id -u` and `id -g`
2. Fix directory ownership: `sudo chown -R 1000:1000 ./config/service-name`

### Network issues
1. Verify network exists: `docker network ls`
2. Check service is connected: `docker network inspect homelab-network`
3. Test connectivity: `docker compose exec service1 ping service2`

## Migration from Docker Run

If you have services running via `docker run`, migrate them to compose:

1. Get current configuration:
   ```bash
   docker inspect container-name > container-config.json
   ```

2. Convert to compose format (extract image, ports, volumes, environment)

3. Test the compose configuration

4. Stop old container:
   ```bash
   docker stop container-name
   docker rm container-name
   ```

5. Start with compose:
   ```bash
   docker compose -f file.yml up -d
   ```

## Backup Strategy

Regular backups are essential:

```bash
# Backup compose files (already in git)
git add docker-compose/*.yml
git commit -m "Update compose configurations"

# Backup volumes
docker run --rm \
  -v volume-name:/data \
  -v $(pwd)/backups:/backup \
  busybox tar czf /backup/volume-name-$(date +%Y%m%d).tar.gz /data

# Backup config directories
tar czf backups/config-$(date +%Y%m%d).tar.gz config/
```

## Getting Help

- Check the [Docker Guidelines](../docs/docker-guidelines.md) for detailed documentation
- Review the [GitHub Copilot Instructions](../.github/copilot-instructions.md) for AI assistance
- Consult service-specific documentation in `config/service-name/README.md`

## Examples

See the example compose files in this directory:
- `infrastructure.yml` - Essential services like reverse proxy
- `media.yml` - Media server stack
- `monitoring.yml` - Observability and monitoring
- `development.yml` - Development environments and tools
