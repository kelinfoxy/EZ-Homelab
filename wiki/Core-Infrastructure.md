# Core Infrastructure

## Overview

The **Core Infrastructure** stack contains the essential services that must be deployed **first** and run continuously. These services form the foundation that all other services depend on.

## Services Included

### 🦆 DuckDNS
**Purpose**: Dynamic DNS updates with wildcard SSL certificate support

- **URL**: No web interface (background service)
- **Function**: Updates DuckDNS with your IP address
- **SSL**: Enables `*.yourdomain.duckdns.org` wildcard certificates
- **Configuration**: Requires `DUCKDNS_TOKEN` and subdomain list

### 🌐 Traefik
**Purpose**: Reverse proxy with automatic HTTPS termination

- **URL**: `https://traefik.yourdomain.duckdns.org`
- **Function**: Routes all traffic to internal services
- **SSL**: Automatic Let's Encrypt certificates via DNS challenge
- **Configuration**: Label-based routing, middleware support

### 🔐 Authelia
**Purpose**: Single Sign-On (SSO) authentication service

- **URL**: `https://auth.yourdomain.duckdns.org`
- **Function**: Centralized authentication for all services
- **Features**: 2FA support, user management, access rules
- **Configuration**: File-based users, auto-generated secrets

### 🔒 Gluetun
**Purpose**: VPN client for secure download routing

- **URL**: No web interface (background service)
- **Function**: Routes download traffic through VPN
- **Providers**: Surfshark WireGuard/OpenVPN support
- **Configuration**: `SURFSHARK_PRIVATE_KEY` required

### ⚡ Sablier
**Purpose**: Lazy loading service for on-demand container startup

- **URL**: `http://sablier.yourdomain.duckdns.org:10000`
- **Function**: Starts containers only when accessed (saves resources)
- **Integration**: Traefik middleware for automatic startup
- **Configuration**: Group-based service management

## Deployment Order

### Critical Dependencies
1. **DuckDNS** must start first (DNS updates)
2. **Traefik** requires DuckDNS (SSL certificates)
3. **Authelia** requires Traefik (web interface)
4. **Gluetun** can start independently (VPN)
5. **Sablier** requires Traefik (middleware integration)

### Automated Deployment
```bash
# Core stack deploys in correct order
cd /opt/stacks/core
docker compose up -d
```

## Network Configuration

### Required Networks
- **traefik-network**: All services connect here for routing
- **homelab-network**: Internal service communication

### Port Exposure
- **80/443**: Traefik (external access only)
- **8080**: Traefik dashboard (internal)
- **10000**: Sablier (internal)

## Security Considerations

### Authentication Flow
1. User accesses `service.yourdomain.duckdns.org`
2. Traefik routes to Authelia for authentication
3. Authelia redirects back to service after login
4. Service receives authenticated user context

### VPN Integration
- Download services use `network_mode: "service:gluetun"`
- All torrent/Usenet traffic routes through VPN
- Prevents IP leaks and ISP throttling

### Certificate Security
- Wildcard certificate covers all subdomains
- Automatic renewal via Let's Encrypt
- DNS challenge prevents port 80 exposure

## Configuration Files

### Environment Variables (.env)
```bash
# Domain and DNS
DOMAIN=yourdomain.duckdns.org
DUCKDNS_TOKEN=your-duckdns-token
DUCKDNS_SUBDOMAINS=yourdomain

# Authelia Secrets (auto-generated)
AUTHELIA_JWT_SECRET=64-char-secret
AUTHELIA_SESSION_SECRET=64-char-secret
AUTHELIA_STORAGE_ENCRYPTION_KEY=64-char-secret

# VPN (optional)
SURFSHARK_PRIVATE_KEY=your-vpn-key
```

### Traefik Configuration
- **Static**: `traefik.yml` (entrypoints, providers)
- **Dynamic**: `dynamic/` directory (routes, middleware)
- **Certificates**: `acme.json` (auto-managed)

### Authelia Configuration
- **Users**: `users_database.yml` (user accounts)
- **Settings**: `configuration.yml` (authentication rules)
- **Secrets**: Auto-generated during setup

## Monitoring & Maintenance

### Health Checks
- **DuckDNS**: IP update verification
- **Traefik**: Route configuration validation
- **Authelia**: Authentication service status
- **Gluetun**: VPN connection status
- **Sablier**: Lazy loading functionality

### Log Locations
- **Traefik**: `/opt/stacks/core/traefik/logs/`
- **Authelia**: Container logs via `docker logs authelia`
- **Gluetun**: Connection status in container logs

### Backup Requirements
- **Configuration**: All YAML files in `/opt/stacks/core/`
- **Certificates**: `acme.json` (contains private keys)
- **User Database**: `users_database.yml` (contains hashed passwords)

## Troubleshooting

### Common Issues

#### Traefik Not Routing
```bash
# Check Traefik logs
docker logs traefik

# Verify routes
curl -k https://traefik.yourdomain.duckdns.org/api/http/routers
```

#### Authelia Authentication Failing
```bash
# Check configuration
docker exec authelia authelia validate-config /config/configuration.yml

# Verify user database
docker exec authelia authelia validate-config /config/users_database.yml
```

#### VPN Connection Issues
```bash
# Check Gluetun status
docker logs gluetun

# Test VPN IP
docker exec gluetun curl -s ifconfig.me
```

#### DNS Not Updating
```bash
# Check DuckDNS logs
docker logs duckdns

# Manual IP check
curl https://www.duckdns.org/update?domains=yourdomain&token=YOUR_TOKEN&ip=
```

## Performance Optimization

### Resource Limits
```yaml
# Recommended limits for core services
duckdns:
  cpus: '0.1'
  memory: 64M

traefik:
  cpus: '0.5'
  memory: 256M

authelia:
  cpus: '0.25'
  memory: 128M

gluetun:
  cpus: '0.5'
  memory: 256M

sablier:
  cpus: '0.1'
  memory: 64M
```

### Scaling Considerations
- **CPU**: Traefik may need more CPU with many services
- **Memory**: Authelia caches user sessions
- **Network**: VPN throughput affects download speeds

## Integration Points

### Service Dependencies
All other stacks depend on core infrastructure:
- **Infrastructure**: Requires Traefik for routing
- **Dashboards**: Requires Authelia for authentication
- **Media**: May use VPN routing through Gluetun
- **All Services**: Use wildcard SSL certificates

### External Access
- **Port Forwarding**: Router must forward 80/443 to server
- **Firewall**: Allow inbound 80/443 traffic
- **DNS**: DuckDNS provides dynamic DNS resolution

This core infrastructure provides a solid, secure foundation for your entire homelab ecosystem.</content>
<parameter name="filePath">c:\Users\kelin\Documents\Apps\GitHub\AI-Homelab\wiki\Core-Infrastructure.md