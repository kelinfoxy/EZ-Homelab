# Core Infrastructure Services

This directory contains the core infrastructure services that form the foundation of the homelab. These services should always be running and are critical for the operation of other services.

## Services

### Traefik (v3)
- **Purpose**: Reverse proxy and SSL termination
- **Ports**: 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- **Configuration**: Located in `traefik/config/traefik.yml`
- **SSL**: Let's Encrypt with DNS-01 challenge (configurable provider)
- **Dashboard**: Available at configured domain

### Authelia (v4.37.5)
- **Purpose**: Single sign-on authentication service
- **Port**: 9091 (internal)
- **Access**: Configured authentication domain
- **Configuration**: Located in `authelia/config/`
- **Database**: SQLite database in `authelia/config/db.sqlite3`

### DuckDNS
- **Purpose**: Dynamic DNS service for domain resolution
- **Subdomain**: Configurable via environment variables
- **Token**: Configured in environment variables

## ⚠️ Version Pinning & Breaking Changes

### Authelia Version Pinning
**Current Version**: `authelia/authelia:4.37.5`

**Breaking Changes Identified**:
- Authelia v4.39.15+ has breaking configuration changes that are incompatible with the current setup
- Database schema changes may require migration or recreation
- Configuration file format changes may break existing setups

**Action Taken**:
- Pinned to v4.37.5 which is confirmed working
- Database recreated from scratch to ensure compatibility
- Configuration files verified and working

**Upgrade Path**:
- Test upgrades in a separate environment first
- Backup configuration and database before upgrading
- Check Authelia changelog for breaking changes
- Consider using Authelia's migration tools if available

### Traefik Version Pinning
**Current Version**: `traefik:v3`

**Notes**:
- Traefik v3 is stable and working with current configuration
- Configuration format is compatible
- No breaking changes identified in current setup

## Configuration Requirements

### File Structure
```
core/
├── docker-compose.yml          # Main service definitions
├── .env                        # Environment variables
├── authelia/
│   └── config/
│       ├── configuration.yml   # Authelia main config
│       ├── users_database.yml  # User credentials
│       └── db.sqlite3          # SQLite database
└── traefik/
    ├── config/
    │   └── traefik.yml         # Traefik static config
    ├── dynamic/                # Dynamic configurations
    │   ├── routes.yml
    │   ├── sablier.yml
    │   └── external-host-*.yml
    └── letsencrypt/
        └── acme.json           # SSL certificates
```

### Environment Variables (.env)
```bash
# Required for proper operation
DUCKDNS_TOKEN=your_duckdns_token_here
DUCKDNS_SUBDOMAINS=your_subdomain
DOMAIN=yourdomain.duckdns.org
TZ=America/New_York
PUID=1000
PGID=1000
```

### Network Requirements
- Docker network: `traefik-network`
- External ports: 80, 443 must be accessible
- DNS resolution: Domain must point to server IP

## Deployment

### Prerequisites
1. Docker and Docker Compose installed
2. Ports 80/443 forwarded to server
3. DuckDNS account with valid token
4. Domain configured in DuckDNS

### Startup Order
1. `duckdns` - For DNS updates
2. `traefik` - Reverse proxy
3. `authelia` - Authentication service

### Commands
```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Restart specific service
docker-compose restart [service-name]
```

## Troubleshooting

### Common Issues
1. **Connection Refused**: Check if Traefik config file is in correct location (`traefik/config/traefik.yml`)
2. **SSL Certificate Issues**: Verify DuckDNS token and domain configuration
3. **Authelia Login Issues**: Check database file exists and configuration is valid
4. **Service Not Starting**: Check Docker logs for error messages

### Backup Strategy
- Configuration files are backed up automatically (see backup directories)
- Database should be backed up regularly
- SSL certificates are stored in `letsencrypt/acme.json`
- Use `backup.sh` script for automated backups

## Security Notes
- Authelia provides authentication for protected services
- All external traffic goes through Traefik with SSL termination
- Internal services communicate via Docker networks
- Dashboard access is protected by Authelia middleware

## Maintenance
- Monitor SSL certificate expiration (Let's Encrypt auto-renews)
- Keep Authelia version pinned until tested upgrades are available
- Regularly backup configuration and database files
- Check logs for security issues or errors
- Run `./backup.sh` regularly to backup critical files

## Customization

### Domain Configuration
Update the following files with your domain:
- `docker-compose.yml`: Traefik labels and Authelia configuration
- `authelia/config/configuration.yml`: Domain settings
- `.env`: Domain environment variables

### SSL Certificate Provider
Modify `traefik/config/traefik.yml` to use different DNS providers:
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      dnsChallenge:
        provider: cloudflare  # or other supported provider
```

### Adding New Services
1. Add service definition to `docker-compose.yml`
2. Configure Traefik labels for routing
3. Add middleware for authentication if needed
4. Update network configuration
