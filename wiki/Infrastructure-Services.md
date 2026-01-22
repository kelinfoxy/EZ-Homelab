# Infrastructure Services

## Overview

The **Infrastructure Services** stack provides the management, monitoring, and operational tools needed to maintain your homelab. These services enhance the core infrastructure with advanced management capabilities.

## Services Included

### 🐳 Dockge
**Purpose**: Primary stack management interface

- **URL**: `https://dockge.yourdomain.duckdns.org`
- **Function**: Visual Docker Compose stack management
- **Features**: Web UI for deploying/managing stacks
- **Authentication**: Protected by Authelia SSO

### 🐳 Portainer
**Purpose**: Advanced container management

- **URL**: `https://portainer.yourdomain.duckdns.org`
- **Function**: Detailed container and image management
- **Features**: Container logs, exec, resource monitoring
- **Authentication**: Protected by Authelia SSO

### 🛡️ Authentik (Alternative SSO)
**Purpose**: Advanced identity management system

- **URL**: `https://authentik.yourdomain.duckdns.org`
- **Function**: Full-featured SSO with web UI management
- **Components**: Server, Worker, PostgreSQL, Redis
- **Features**: User groups, policies, integrations

### 🛡️ Pi-hole
**Purpose**: Network-wide ad blocking and DNS

- **URL**: `http://pihole.yourdomain.duckdns.org`
- **Function**: DNS server with ad blocking
- **Features**: Query logging, client management
- **Authentication**: Protected by Authelia SSO

### 👁️ Dozzle
**Purpose**: Real-time Docker log viewer

- **URL**: `https://dozzle.yourdomain.duckdns.org`
- **Function**: Live container log streaming
- **Features**: Multi-container log viewing, search
- **Authentication**: Protected by Authelia SSO

### 👁️ Glances
**Purpose**: System monitoring dashboard

- **URL**: `https://glances.yourdomain.duckdns.org`
- **Function**: Real-time system resource monitoring
- **Features**: CPU, memory, disk, network stats
- **Authentication**: Protected by Authelia SSO

### 🔄 Watchtower
**Purpose**: Automatic container updates

- **URL**: No web interface (background service)
- **Function**: Monitors and updates Docker containers
- **Features**: Scheduled updates, notifications
- **Configuration**: Cron-based update scheduling

### 🔌 Docker Proxy
**Purpose**: Secure Docker socket access

- **URL**: No web interface (background service)
- **Function**: Provides secure API access to Docker
- **Features**: Token-based authentication
- **Security**: Protects Docker socket from unauthorized access

## Deployment Strategy

### Recommended Order
1. **Dockge** (primary management interface)
2. **Portainer** (advanced container management)
3. **Pi-hole** (network services)
4. **Monitoring** (Dozzle, Glances)
5. **Automation** (Watchtower, Docker Proxy)

### Stack Location
```
/opt/stacks/infrastructure/
├── docker-compose.yml
├── dockge/
├── portainer/
├── pihole/
├── dozzle/
├── glances/
└── .env
```

## Configuration

### Environment Variables
```bash
# User permissions
PUID=1000
PGID=1000
TZ=America/New_York

# Pi-hole configuration
PIHOLE_PASSWORD=secure-admin-password

# Watchtower settings
WATCHTOWER_CLEANUP=true
WATCHTOWER_POLL_INTERVAL=3600
```

### Network Integration
- **traefik-network**: Web interface access
- **dockerproxy-network**: Secure Docker API access
- **homelab-network**: Internal communication

## Security Features

### Authentication Integration
- **Authelia SSO**: All web interfaces protected
- **Role-based Access**: Different permission levels
- **Session Management**: Secure session handling

### Network Security
- **Internal Access**: Services not exposed externally
- **Firewall Rules**: Restricted network access
- **API Security**: Token-based Docker access

## Management Workflows

### Stack Deployment
```bash
# Deploy infrastructure stack
cd /opt/stacks/infrastructure
docker compose up -d

# Access management interfaces
# Dockge: https://dockge.yourdomain.duckdns.org
# Portainer: https://portainer.yourdomain.duckdns.org
```

### Container Monitoring
```bash
# View logs with Dozzle
# https://dozzle.yourdomain.duckdns.org

# System monitoring with Glances
# https://glances.yourdomain.duckdns.org
```

### Updates Management
```bash
# Watchtower handles automatic updates
# Manual update check
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once
```

## Performance Considerations

### Resource Allocation
```yaml
# Recommended resource limits
dockge:
  cpus: '0.5'
  memory: 256M

portainer:
  cpus: '0.5'
  memory: 512M

pihole:
  cpus: '0.25'
  memory: 128M

dozzle:
  cpus: '0.25'
  memory: 128M

glances:
  cpus: '0.25'
  memory: 128M
```

### Scaling Guidelines
- **CPU**: Portainer may need more CPU for large deployments
- **Memory**: Pi-hole benefits from additional memory for query logging
- **Storage**: Minimal storage requirements for configurations

## Integration Points

### Core Infrastructure
- **Traefik**: Provides routing and SSL termination
- **Authelia**: Handles authentication for all services
- **Networks**: Connected to traefik-network for access

### Other Stacks
- **All Stacks**: Can be managed through Dockge interface
- **Monitoring**: Provides monitoring for all services
- **Security**: Enhances security through Pi-hole ad blocking

## Troubleshooting

### Common Issues

#### Dockge Not Accessible
```bash
# Check container status
docker compose -f /opt/stacks/infrastructure/docker-compose.yml ps

# View logs
docker compose -f /opt/stacks/infrastructure/docker-compose.yml logs dockge
```

#### Portainer Connection Issues
```bash
# Verify Docker socket access
docker exec portainer docker version

# Check Docker Proxy logs
docker logs dockerproxy
```

#### Pi-hole DNS Issues
```bash
# Check DNS resolution
nslookup google.com 127.0.0.1

# View Pi-hole logs
docker logs pihole
```

#### Watchtower Not Updating
```bash
# Check Watchtower logs
docker logs watchtower

# Manual update test
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once --debug
```

## Backup & Recovery

### Configuration Backup
- **Dockge**: Stack configurations in `/opt/stacks/`
- **Portainer**: Settings stored in named volumes
- **Pi-hole**: Configuration in `/etc/pihole/`
- **All Services**: YAML configurations in stack directories

### Automated Backups
- **Watchtower**: No persistent data to backup
- **Monitoring Data**: Logs and metrics (ephemeral)
- **Settings**: Include in regular backup strategy

## Best Practices

### Operational Guidelines
1. **Use Dockge** as primary management interface
2. **Monitor regularly** with Glances and Dozzle
3. **Keep updated** via Watchtower automation
4. **Secure access** through Authelia SSO
5. **Network protection** via Pi-hole ad blocking

### Maintenance Schedule
- **Daily**: Check system monitoring
- **Weekly**: Review container logs
- **Monthly**: Update base images manually
- **Quarterly**: Security audit and cleanup

This infrastructure stack provides comprehensive management and monitoring capabilities for your homelab environment.</content>
<parameter name="filePath">c:\Users\kelin\Documents\Apps\GitHub\AI-Homelab\wiki\Infrastructure-Services.md