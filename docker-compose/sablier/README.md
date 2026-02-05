# Sablier Stack

This stack deploys [Sablier](https://github.com/acouvreur/sablier), a service that provides lazy loading (on-demand startup) for Docker containers.

## Overview

Sablier monitors Docker containers and can automatically start them when they receive traffic through Traefik, then stop them after a period of inactivity. This is useful for:
- Reducing resource usage on servers with limited RAM/CPU
- Managing seasonal or infrequently-used services
- Extending the capacity of small servers (like Raspberry Pi)

## Multi-Server Architecture

Each server in your homelab should have its own Sablier instance:
- **Core Server**: Manages lazy loading for core services
- **Remote Servers**: Each runs Sablier to control local containers

Sablier only connects to the local Docker socket (`/var/run/docker.sock`) on its own server.

## Features

- **Web Dashboard**: Access at `https://sablier.yourdomain.duckdns.org`
- **Protected by Authelia**: SSO authentication required
- **Local Control**: Only manages containers on the same server
- **Traefik Integration**: Uses Traefik middlewares for automatic container startup

## Usage

### Enable Lazy Loading on a Container

Add these labels to any service in your docker-compose files:

```yaml
services:
  myservice:
    image: myapp:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.yourdomain.duckdns.org`)"
      - "traefik.http.routers.myservice.entrypoints=websecure"
      - "traefik.http.routers.myservice.tls=true"
      - "traefik.http.routers.myservice.middlewares=sablier-myservice@docker"
      
      # Sablier middleware configuration
      - "traefik.http.middlewares.sablier-myservice.plugin.sablier.names=myservice"
      - "traefik.http.middlewares.sablier-myservice.plugin.sablier.sablierUrl=http://sablier:10000"
      - "traefik.http.middlewares.sablier-myservice.plugin.sablier.sessionDuration=5m"
```

### Configuration Options

- `names`: Container name(s) to manage (comma-separated for multiple)
- `sablierUrl`: URL of the Sablier service (use `http://sablier:10000` for local)
- `sessionDuration`: How long to keep the container running after last request (e.g., `5m`, `1h`)

## Deployment

This stack is automatically deployed:
- On the **core server** after core infrastructure deployment
- On **remote servers** during remote server setup

Manual deployment:
```bash
cd /opt/stacks/sablier
docker compose up -d
```

## Resources

- CPU: ~10-20 MB RAM per instance
- Storage: Minimal (~50 MB)
- Network: Internal Docker network only

## Documentation

- [Sablier GitHub](https://github.com/acouvreur/sablier)
- [Sablier Documentation](https://acouvreur.github.io/sablier/)
- [Traefik Plugin Configuration](https://doc.traefik.io/traefik/plugins/sablier/)
