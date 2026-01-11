# AI-Homelab

AI-Powered Homelab Administration with GitHub Copilot

## Overview

This repository provides a structured approach to managing a homelab infrastructure using Docker Compose, with integrated AI assistance through GitHub Copilot. The AI assistant is specifically trained to help you create, modify, and manage Docker services while maintaining consistency across your entire server stack.

## Features

- **AI-Powered Management**: GitHub Copilot integration with specialized instructions for Docker service management
- **Docker Compose First**: All persistent services defined in organized compose files
- **Consistent Structure**: Standardized naming conventions and patterns across all services
- **Stack-Aware Changes**: AI considers the entire infrastructure when making changes
- **Comprehensive Documentation**: Detailed guidelines and examples for all operations
- **Example Services**: Ready-to-use compose files for common homelab services

## Quick Start

### Prerequisites

- Docker Engine 24.0+ installed
- Docker Compose V2
- Git
- VS Code with GitHub Copilot extension (for AI assistance)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kelinfoxy/AI-Homelab.git
   cd AI-Homelab
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your values
   nano .env
   ```

3. **Create the main network:**
   ```bash
   docker network create homelab-network
   ```

4. **Create config directories:**
   ```bash
   mkdir -p config
   ```

5. **Start your first service:**
   ```bash
   # Example: Start Portainer for container management
   docker compose -f docker-compose/infrastructure.yml up -d portainer
   ```

6. **Access the service:**
   Open `http://your-server-ip:9000` in your browser

## Repository Structure

```
AI-Homelab/
├── .github/
│   └── copilot-instructions.md    # AI assistant guidelines
├── docker-compose/
│   ├── infrastructure.yml         # Core services (proxy, DNS, Portainer)
│   ├── media.yml                  # Media services (Plex, Sonarr, Radarr)
│   ├── monitoring.yml             # Observability (Prometheus, Grafana)
│   ├── development.yml            # Dev tools (code-server, databases)
│   └── README.md                  # Docker Compose documentation
├── docs/
│   └── docker-guidelines.md       # Comprehensive Docker guidelines
├── config/                        # Service configurations (gitignored)
├── .env.example                   # Environment variable template
├── .gitignore                     # Git ignore patterns
└── README.md                      # This file
```

## Using the AI Assistant

### In VS Code

1. **Install GitHub Copilot** extension in VS Code
2. **Open this repository** in VS Code
3. **Start Copilot Chat** and ask questions like:
   - "Help me add a new media service to my homelab"
   - "Create a docker-compose file for Home Assistant"
   - "How do I configure GPU support for Plex?"
   - "Check my compose file for port conflicts"

The AI assistant automatically follows the guidelines in `.github/copilot-instructions.md` to:
- Maintain consistency with existing services
- Use Docker Compose for all persistent services
- Consider the entire stack when making changes
- Follow naming conventions and best practices

### Example Interactions

**Creating a new service:**
```
You: "I want to add Home Assistant to my homelab"

Copilot: [Analyzes existing stack, checks for conflicts, creates compose configuration]
- Checks available ports
- Uses consistent naming
- Connects to appropriate networks
- Follows established patterns
```

**Modifying a service:**
```
You: "Add GPU support to my Plex container"

Copilot: [Reviews current Plex configuration and updates it]
- Checks if NVIDIA runtime is available
- Updates device mappings
- Adds required environment variables
- Maintains existing configuration
```

## Available Service Stacks

### Infrastructure (`infrastructure.yml`)
- **Nginx Proxy Manager**: Web-based reverse proxy with SSL
- **Pi-hole**: Network-wide ad blocking and DNS
- **Portainer**: Docker container management UI
- **Watchtower**: Automatic container updates

### Media (`media.yml`)
- **Plex**: Media streaming server
- **Jellyfin**: Open-source media server alternative
- **Sonarr**: TV show automation
- **Radarr**: Movie automation
- **Prowlarr**: Indexer manager
- **qBittorrent**: Torrent client

### Monitoring (`monitoring.yml`)
- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization
- **Node Exporter**: Host metrics
- **cAdvisor**: Container metrics
- **Uptime Kuma**: Service uptime monitoring
- **Loki**: Log aggregation
- **Promtail**: Log shipping

### Development (`development.yml`)
- **Code Server**: VS Code in browser
- **GitLab CE**: Self-hosted Git repository
- **PostgreSQL**: SQL database
- **Redis**: In-memory data store
- **pgAdmin**: PostgreSQL UI
- **Jupyter Lab**: Interactive notebooks
- **Node-RED**: Visual automation

## Common Operations

### Starting Services

Start all services in a compose file:
```bash
docker compose -f docker-compose/infrastructure.yml up -d
```

Start specific services:
```bash
docker compose -f docker-compose/media.yml up -d plex sonarr radarr
```

### Stopping Services

Stop all services:
```bash
docker compose -f docker-compose/infrastructure.yml down
```

Stop specific service:
```bash
docker compose -f docker-compose/media.yml stop plex
```

### Viewing Logs

Follow logs for a service:
```bash
docker compose -f docker-compose/media.yml logs -f plex
```

View last 100 lines:
```bash
docker compose -f docker-compose/media.yml logs --tail=100 plex
```

### Updating Services

Pull latest images:
```bash
docker compose -f docker-compose/media.yml pull
```

Update specific service:
```bash
docker compose -f docker-compose/media.yml pull plex
docker compose -f docker-compose/media.yml up -d plex
```

### Testing with Docker Run

Test NVIDIA GPU support:
```bash
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

Test a new image:
```bash
docker run --rm -it alpine:latest /bin/sh
```

## Network Architecture

All services connect to networks for inter-service communication:

- **homelab-network**: Main network for all services
- **media-network**: Isolated network for media stack
- **monitoring-network**: Network for observability stack
- **database-network**: Isolated network for databases

Create networks manually:
```bash
docker network create homelab-network
docker network create media-network
docker network create monitoring-network
docker network create database-network
```

## Documentation

### Comprehensive Guides

- **[Docker Guidelines](docs/docker-guidelines.md)**: Complete guide to Docker service management
- **[Docker Compose README](docker-compose/README.md)**: Compose-specific documentation
- **[Copilot Instructions](.github/copilot-instructions.md)**: AI assistant guidelines

### Key Principles

1. **Docker Compose First**: Always use compose for persistent services
2. **Docker Run for Testing**: Only use `docker run` for temporary containers
3. **Consistency**: Follow established patterns and naming conventions
4. **Stack Awareness**: Consider dependencies and interactions
5. **Documentation**: Comment complex configurations
6. **Security**: Keep secrets in `.env` files, never commit them

## Configuration Management

### Environment Variables

All services use variables from `.env`:
- `PUID`/`PGID`: User/group IDs for file permissions
- `TZ`: Timezone for all services
- `SERVER_IP`: Your server's IP address
- Service-specific credentials and paths

### Config Files

Service configurations are stored in `config/service-name/`:
```
config/
├── plex/          # Plex configuration
├── sonarr/        # Sonarr configuration
├── grafana/       # Grafana dashboards
└── ...
```

**Note**: Config directories are gitignored to prevent committing sensitive data.

## Security Best Practices

1. **Pin Image Versions**: Never use `:latest` in production
2. **Use Environment Variables**: Store secrets in `.env` (gitignored)
3. **Run as Non-Root**: Set PUID/PGID to match your user
4. **Limit Exposure**: Bind ports to localhost when possible
5. **Regular Updates**: Keep images updated via Watchtower
6. **Scan Images**: Use `docker scan` to check for vulnerabilities

## Troubleshooting

### Service Won't Start

1. Check logs: `docker compose -f file.yml logs service-name`
2. Validate config: `docker compose -f file.yml config`
3. Check port conflicts: `sudo netstat -tlnp | grep PORT`
4. Verify network exists: `docker network ls`

### Permission Issues

1. Check PUID/PGID match your user: `id -u` and `id -g`
2. Fix ownership: `sudo chown -R 1000:1000 ./config/service-name`

### Network Issues

1. Verify network exists: `docker network inspect homelab-network`
2. Test connectivity: `docker compose exec service1 ping service2`

### Getting Help

- Review the [Docker Guidelines](docs/docker-guidelines.md)
- Ask GitHub Copilot in VS Code
- Check service-specific documentation
- Review Docker logs for error messages

## Backup Strategy

### What to Backup

1. **Docker Compose files** (version controlled in git)
2. **Config directories**: `./config/*`
3. **Named volumes**: `docker volume ls`
4. **Environment file**: `.env` (securely, not in git)

### Backup Named Volumes

```bash
# Backup a volume
docker run --rm \
  -v volume-name:/data \
  -v $(pwd)/backups:/backup \
  busybox tar czf /backup/volume-backup.tar.gz /data
```

### Restore Named Volumes

```bash
# Restore a volume
docker run --rm \
  -v volume-name:/data \
  -v $(pwd)/backups:/backup \
  busybox tar xzf /backup/volume-backup.tar.gz -C /
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Follow existing patterns and conventions
4. Test your changes
5. Submit a pull request

## License

This project is provided as-is for personal homelab use.

## Acknowledgments

- Docker and Docker Compose communities
- LinuxServer.io for excellent container images
- GitHub Copilot for AI assistance capabilities
- All the open-source projects used in example compose files

## Getting Started Checklist

- [ ] Install Docker and Docker Compose
- [ ] Clone this repository
- [ ] Copy `.env.example` to `.env` and configure
- [ ] Create `homelab-network`: `docker network create homelab-network`
- [ ] Start infrastructure services: `docker compose -f docker-compose/infrastructure.yml up -d`
- [ ] Access Portainer at `http://server-ip:9000`
- [ ] Install VS Code with GitHub Copilot extension
- [ ] Open repository in VS Code and start using AI assistance
- [ ] Add more services as needed using AI guidance

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Consult the comprehensive [documentation](docs/docker-guidelines.md)
- Use GitHub Copilot in VS Code for real-time assistance
