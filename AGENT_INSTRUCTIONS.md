# AI Agent Instructions for Homelab Management

## Primary Directive
You are an AI agent specialized in managing Docker-based homelab infrastructure using Dockge. Always prioritize security, consistency, and stability across the entire server stack.

## Repository Context
- **Repository Location**: `~/EZ-Homelab/`
- **Purpose**: Production-ready Docker homelab infrastructure managed through GitHub Copilot in VS Code
- **User**: `kelin` (PUID=1000, PGID=1000)
- **Critical**: All file operations must respect user ownership - avoid permission escalation issues

## Repository Structure
```
~/EZ-Homelab/
├── .github/
│   └── copilot-instructions.md      # GitHub Copilot guidelines
├── docker-compose/                  # Compose file templates
│   ├── core/                        # Core infrastructure (deploy first)
│   ├── infrastructure/              # Management tools
│   ├── dashboards/                  # Dashboard services
│   ├── media/                       # Media server stack
│   ├── monitoring/                  # Monitoring stack
│   ├── productivity/                # Productivity tools
│   └── *.yml                        # Individual service stacks
├── config-templates/                # Service configuration templates
├── docs/                           # Comprehensive documentation
│   ├── getting-started.md
│   ├── services-reference.md
│   ├── docker-guidelines.md
│   ├── proxying-external-hosts.md
│   └── troubleshooting/
├── scripts/                        # Automation scripts
│   ├── setup-homelab.sh           # First-run setup
│   └── deploy-homelab.sh          # Automated deployment
├── .env.example                   # Environment template
├── .env                           # User-created environment file (not in git)
├── AGENT_INSTRUCTIONS.md          # This file
└── README.md                      # Project overview
```

## Core Operating Principles

### 1. Docker Compose First
- **ALWAYS** use Docker Compose for persistent services
- Store all compose files in `/opt/stacks/stack-name/` directories
- Use `docker run` only for temporary testing
- Maintain services in organized docker-compose.yml files

### 2. Security-First Approach
- **All services start with SSO protection enabled by default**
- Only Plex and Jellyfin bypass SSO for app compatibility
- Comment out (don't remove) Authelia middleware when disabling SSO
- Store secrets in `.env` files, never in compose files

### 3. File Structure Standards
```
/opt/stacks/
├── core/                    # Deploy FIRST (DuckDNS, Traefik, Authelia, Gluetun)
├── infrastructure/          # Dockge, Portainer, Pi-hole
├── dashboards/             # Homepage, Homarr
├── media/                  # Plex, Jellyfin, *arr services
└── [other-stacks]/
```

### 4. Storage Strategy
- **Config files**: Use relative paths `./service/config:/config` in compose files
- **Large data**: Separate drives (`/mnt/media`, `/mnt/downloads`)
- **Small data**: Docker named volumes
- **Secrets**: `.env` files (never commit)

## Service Creation Template

```yaml
services:
  service-name:
    image: image:tag  # Always pin versions
    container_name: service-name
    restart: unless-stopped  # Use 'no' if ondemand (Sablier) is enabled
    networks:
      - homelab-network
    ports:
      - "host:container"  # Only if not using Traefik
    volumes:
      - ./service-name/config:/config  # Relative to stack directory
      - service-data:/data
      # Large data on separate drives:
      # - /mnt/media:/media
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    labels:
      # Traefik routing
      - "traefik.enable=true"
      - "traefik.http.routers.service-name.rule=Host(`service.${DOMAIN}`)"
      - "traefik.http.routers.service-name.entrypoints=websecure"
      - "traefik.http.routers.service-name.tls.certresolver=letsencrypt"
      # SSO protection (ENABLED BY DEFAULT)
      - "traefik.http.routers.service-name.middlewares=authelia@docker"
      # Organization
      - "homelab.category=category-name"
      - "homelab.description=Service description"

volumes:
  service-data:
    driver: local

networks:
  homelab-network:
    external: true
```

**Important Volume Path Convention:**
- Use **relative paths** (`./<service>/config`) for service configs within the stack directory
- Use **absolute paths** (`/mnt/media`) only for large shared data on separate drives
- This allows stacks to be portable and work correctly in Dockge's `/opt/stacks/` structure

## Service Creation with Traefik on a different server Template

For services not running on the same server as Traefik, use this template. Does not require Traefik labels in compose file.

>From Traekif's perspective the service is on a remote host

**Remote Server Setup:**
1. Deploy service on the target server using standard Docker Compose
2. Note the target server's IP address and service port
3. Create/update Traefik dynamic configuration file: `/opt/stacks/core/traefik/dynamic/external-host-servername.yml` on the server with Traefik

**Traefik Dynamic Configuration Template:**
```yaml
http:
  routers:
    # Remote service on servername
    remote-service:
      rule: "Host(`remote-service.${DOMAIN}`)"
      entryPoints:
        - websecure
      service: remote-service
      tls:
        certResolver: letsencrypt
      # Optional: Add Authelia protection
      middlewares:
        - authelia@docker

  services:
    remote-service:
      loadBalancer:
        servers:
          - url: "http://remote-server-ip:service-port"  # Replace with actual IP/port
        passHostHeader: true

  middlewares:
    # Optional: Add headers for WebSocket support if needed
    remote-service-headers:
      headers:
        customRequestHeaders:
          X-Forwarded-Proto: "https"
        customResponseHeaders:
          X-Frame-Options: "SAMEORIGIN"
```

**File Naming Convention:**
- External host files named: `external-host-servername.yml`
- Example: `external-host-raspberry-pi.yml`, `external-host-nas.yml`
- See `docs/proxying-external-hosts.md` for detailed examples

## Critical Deployment Order

>The core stack should only be deployed on one server in the homelab  
The dashboards stack is intended to be deployed on the same server as the core stack, for better UX

Skip step 1 if the homelab already has the core stack on another server.

1. **Core Stack First**: Deploy `/opt/stacks/core/docker-compose.yml`
   - DuckDNS, Traefik, Authelia
   - All other services depend on this
2. **VPN Stack**: Deploy `/opt/stacks/vpn/docker-compose.yml`
   - Gluetun VPN client, qBittorrent
   - Optional but recommended for secure downloads
3. **Infrastructure**: Dockge, docker-proxy, code-server, etc.
4. **Applications**: Media services, dashboards, etc.

## VPN Integration Rules

**All VPN-related services must be in the VPN stack** (`/opt/stacks/vpn/`), including Gluetun itself. This ensures proper network isolation and management.

Use Gluetun for services requiring VPN:
```yaml
services:
  # Gluetun VPN client (must be in vpn stack)
  gluetun:
    # VPN configuration here

  download-client:
    network_mode: "service:gluetun"  # Routes through VPN
    depends_on:
      - gluetun
    # No ports section - use Gluetun's ports
```

Map ports in Gluetun service:
```yaml
gluetun:
  ports:
    - 8080:8080  # Download client web UI
```

**Important**: Never place VPN-dependent services in other stacks. All VPN routing must happen within the dedicated VPN stack.

## SSO Management

### Enable SSO (Default)
```yaml
labels:
  - "traefik.http.routers.service.middlewares=authelia@docker"
```

### Disable SSO (Only for Plex/Jellyfin/Apps)
```yaml
labels:
  # - "traefik.http.routers.service.middlewares=authelia@docker"
```

## Agent Actions Checklist

### Permission Safety (CRITICAL)
- [ ] **NEVER** use sudo for file operations in user directories
- [ ] Always check file ownership before modifying: `ls -la`
- [ ] Respect existing ownership - files should be owned by `kelin:kelin`
- [ ] If permission denied, diagnose first - don't escalate privileges blindly
- [ ] Docker operations may need sudo, but file edits in `/home/kelin/` should not

### Before Any Change
- [ ] Read existing compose files for context
- [ ] Check port availability
- [ ] Verify network dependencies
- [ ] Ensure core stack is deployed
- [ ] Backup current configuration

### When Creating Services
- [ ] Use LinuxServer.io images when available
- [ ] Pin image versions (no `:latest`)
- [ ] Apply consistent naming conventions
- [ ] Enable Authelia middleware by default
- [ ] Configure proper volume mounts
- [ ] Set PUID/PGID for file permissions

### When Modifying Services
- [ ] Maintain existing patterns
- [ ] Consider stack-wide impact
- [ ] Update only necessary components
- [ ] Validate YAML syntax
- [ ] Test service restart

### File Management
- [ ] Store configs in `/opt/stacks/stack-name/`
- [ ] Use relative paths for configs: `./service/config`
- [ ] Use `/mnt/` for large data (>50GB)
- [ ] Create `.env.example` templates
- [ ] Document non-obvious configurations

## Common Agent Tasks

### Development Workflow
1. **Repository Maintenance**
   - Test deployment scripts: `./scripts/setup-homelab.sh`, `./scripts/deploy-homelab.sh`
   - Verify compose file syntax across all stacks
   - Validate `.env.example` completeness
   - Check documentation accuracy

2. **Configuration Updates**
   - Modify compose files in `docker-compose/` directory
   - Update config templates in `config-templates/`
   - Ensure changes maintain backward compatibility

3. **Documentation Maintenance**
   - Keep `docs/` synchronized with compose changes
   - Update service lists when adding new services
   - Document new features or configuration patterns

### Deploy New Service
**Research Protocol:**
1. **Check existing services**: Search `docs/services-overview.md` and compose files for similar services
2. **Read official documentation**: Visit Docker Hub, LinuxServer.io, or official project docs
3. **Check awesome-docker-compose**: Review https://awesome-docker-compose.com/apps for compose templates
4. **Prefer LinuxServer.io**: Use lscr.io images when available for consistency
5. **Check port availability**: Review `docs/ports-in-use.md` for conflicts
6. **Determine SSO requirements**: Media services (Plex/Jellyfin) bypass SSO, admin tools require it
7. **Check VPN needs**: Download clients need `network_mode: "service:gluetun"`
8. **Review resource limits**: Apply CPU/memory limits following existing patterns

**Deployment Steps:**
1. Create stack directory: `/opt/stacks/stack-name/`
2. Write docker-compose.yml using LinuxServer.io template with Traefik labels
3. Create `.env` file for secrets (copy from `~/EZ-Homelab/.env`)
4. **Ask user**: Enable SSO protection? (Default: Yes, unless media service like Plex/Jellyfin)
5. **Ask user**: Enable lazy loading (Sablier)? (Default: Yes for resource conservation) - **Note**: Requires `restart: no` instead of `unless-stopped`
6. Add service to Homepage dashboard config
7. Deploy: `docker compose up -d`
8. Verify Traefik routing at `https://service.${DOMAIN}`
9. Test SSO protection (or bypass for media services)
10. Check logs: `docker compose logs -f`

### Update Existing Service
**Verification Protocol:**
1. **Read current config**: `docker compose -f /opt/stacks/stack/docker-compose.yml config`
2. **Check dependencies**: Identify linked services, networks, volumes
3. **Backup current state**: Copy compose file before changes
4. **Test in isolation**: Use `docker run` for image testing if needed
5. **Check breaking changes**: Review changelog for new versions
6. **Validate environment**: Ensure `.env` has required variables

**Update Steps:**
1. Read current configuration and dependencies
2. **If modifying core services**: Verify integrity of `/opt/stacks/core/traefik/dynamic/` files and `sablier.yml`
3. Make minimal necessary changes (version, config, ports)
4. Validate YAML syntax: `docker compose config`
5. Check for port conflicts with `docs/ports-in-use.md`
6. Pull new image: `docker compose pull service-name`
7. Redeploy: `docker compose up -d service-name`
8. Monitor logs: `docker compose logs -f service-name`
9. Test functionality and verify dependent services still work
10. Update documentation if behavior changed

### Enable/Disable VPN
**Enable VPN Routing:**
1. **Check Gluetun status**: Verify VPN stack is running with VPN configured
2. **Move service to VPN stack**: All VPN-dependent services must be in `/opt/stacks/vpn/` with Gluetun
3. **Modify service config**: Change from `ports:` to `network_mode: "service:gluetun"`
4. **Move port mappings**: Add exposed ports to Gluetun service in VPN stack
5. **Add dependency**: Include `depends_on: - gluetun`
6. **Remove direct ports**: Delete any `ports:` section from service
7. **Update documentation**: Note VPN routing in service docs
8. **Test connectivity**: Verify service routes through VPN IP

**Disable VPN Routing:**
1. **Check port availability**: Review `docs/ports-in-use.md` for conflicts
2. **Move service out of VPN stack**: Relocate to appropriate non-VPN stack
3. **Remove network_mode**: Delete `network_mode: "service:gluetun"`
4. **Add direct ports**: Add appropriate `ports:` mapping
5. **Remove dependency**: Delete `depends_on: gluetun`
6. **Remove Gluetun ports**: Clean up port mappings from Gluetun service
7. **Test direct access**: Verify service accessible without VPN
8. **Update documentation**: Remove VPN routing notes

### Toggle SSO
**Enable Authelia SSO (Default for Security):**
1. **Verify Authelia running**: Check core stack status
2. **Uncomment middleware label**: Change `# - "traefik.http.routers.service.middlewares=authelia@docker"` to active
3. **Remove bypass rules**: Delete domain exception from `authelia/configuration.yml` if present
4. **Test authentication**: Access service and verify login prompt
5. **Document protection**: Note SSO requirement in service docs

**Disable Authelia SSO (Media Services Only):**
1. **Justify bypass**: Confirm service needs direct app access (Plex, Jellyfin, etc.)
2. **Comment middleware**: Change to `# - "traefik.http.routers.service.middlewares=authelia@docker"`
3. **Add bypass rule**: Update `authelia/configuration.yml` with domain exception
4. **Test direct access**: Verify no authentication required
5. **Document exception**: Explain why SSO bypassed in service docs
6. **Monitor security**: Regular review of bypass justifications

**Note**: Authelia middleware label should ALWAYS be present in compose files - comment out to disable, never remove entirely.

## Error Prevention

### Port Conflicts
**Prevention Protocol:**
1. **Check existing ports**: Review `docs/ports-in-use.md` before assigning new ports
2. **Use Traefik routing**: Prefer host-based routing over direct port exposure
3. **Standardize ports**: Follow LinuxServer.io defaults when possible
4. **Document usage**: Add port comments in compose files
5. **Test conflicts**: Use `netstat -tlnp | grep :PORT` to check availability

**AI Usage of ports-in-use.md:**
- Always consult `docs/ports-in-use.md` before suggesting new port assignments
- Update the document whenever ports are changed or new services added
- Cross-reference with service documentation links in the ports file
- Verify port availability across all stacks before deployment

**Resolution Steps:**
1. **Identify conflict**: Check `docker ps --format "table {{.Names}}\t{{.Ports}}"` for port usage
2. **Reassign port**: Choose unused port following service conventions
3. **Update Traefik labels**: Modify `loadbalancer.server.port` if changed
4. **Update documentation**: Reflect port changes in `docs/ports-in-use.md`
5. **Test access**: Verify service accessible at new port
6. **Update dependent services**: Check for hardcoded port references

### Permission Issues
- Always set PUID=1000, PGID=1000
- Check directory ownership on host
- Use consistent user/group across services

### Network Issues
- Verify shared networks exist
- Use service names for inter-service communication
- Ensure Traefik can reach services

## Key Configurations to Monitor

### Sablier Configurations
- Lazy loading enabled: `sablier.enable=true`
- Proper group naming: `sablier.group=stack-service`
- On-demand startup: `sablier.start-on-demand=true`
- **Critical**: Set `restart: no` when ondemand is enabled (cannot use `unless-stopped`)
- Group consistency across related services

### Traefik's Dynamic Folder Configurations
- File provider configuration in `/opt/stacks/core/traefik/dynamic/`
- External host routing rules in `external.yml`
- Middleware definitions and routing rules
- Certificate resolver settings for wildcard domains

### Traefik Labels
- Correct hostname format: `service.${DOMAIN}`
- Proper entrypoint: `websecure`
- Certificate resolver: `letsencrypt`
- Port specification if needed

### Authelia Integration
- Middleware applied to protected services
- Bypass rules for apps requiring direct access
- User database and access rules updated

### Volume Mounts
- Config files in stack directories
- Large data on separate drives
- Named volumes for persistent data
- Proper permissions and ownership

## Emergency Procedures

### Permission-Related Crashes (Recent Issue)
1. **Diagnose**: Check recent file operations
   - Review which files were modified
   - Check ownership: `ls -la /path/to/files`
   - Identify what triggered permission errors

2. **Fix Ownership Issues**
   ```bash
   # For /opt/ directory (if modified during testing)
   sudo chown -R kelin:kelin /opt/stacks
   
   # For repository files
   chown -R kelin:kelin ~/EZ-Homelab  # No sudo needed in home dir
   
   # For Docker-managed directories, leave as root
   # (e.g., /opt/stacks/*/data/ created by containers)
   ```

3. **Prevent Future Issues**
   - Edit files in `~/EZ-Homelab/` without sudo
   - Only use sudo for Docker commands
   - Don't change ownership of Docker-created volumes

### Service Won't Start
1. Check logs: `docker compose logs service-name`
2. Verify YAML syntax
3. Check file permissions
4. Validate environment variables
5. Ensure dependencies are running

### SSL Certificate Issues
- Verify DuckDNS is updating IP
- Check Traefik logs
- Ensure port 80/443 accessible
- Validate domain DNS resolution

### Authentication Problems
- Check Authelia logs
- Verify user database format
- Test bypass rules
- Validate Traefik middleware configuration

## Success Metrics

- All services accessible via HTTPS
- SSO working for protected services
- No port conflicts
- Proper file permissions
- Services restart automatically
- Logs show no persistent errors
- Certificates auto-renew
- VPN routing working for download clients

## Agent Limitations

### Never Do
- Use `docker run` for permanent services
- Commit secrets to compose files
- Use `:latest` tags in production
- Bypass security without explicit request
- Modify core stack without understanding dependencies
- **Use sudo for operations in `/home/kelin/` directory**
- **Change file ownership without explicit permission**
- **Blindly escalate privileges when encountering errors**

### Always Do
- Read documentation and service-docs files and follow established practices
- Read existing configurations first
- Test changes in isolation when possible
- Document complex configurations
- Follow established naming patterns
- Prioritize security over convenience
- Maintain consistency across the stack
- **Check file permissions before operations**
- **Respect user ownership boundaries**
- **Ask before modifying system directories**

## Repository Management Guidelines

### Repository Maintenance
- Work within `~/EZ-Homelab/` for all operations
- Validate all YAML files before committing
- Ensure `.env.example` stays updated with new variables
- Document breaking changes in commit messages

### Permission Best Practices
- Repository files: Owned by `kelin:kelin`
- Docker socket: Requires docker group membership
- `/opt/stacks/`: Owned by user, some subdirs by containers
- Never use sudo for editing files in home directory

### Pre-deployment Validation
```bash
# Validate compose files
docker compose -f docker-compose/core.yml config

# Check environment variables
grep -v '^#' .env | grep -v '^$'

# Test script syntax
bash -n scripts/deploy-homelab.sh

# Verify file permissions
ls -la ~/EZ-Homelab/
```

### Deployment Checklist
- [ ] Fresh system: Test `setup-homelab.sh`
- [ ] Core stack: Deploy and verify DuckDNS, Traefik, Authelia, Gluetun
- [ ] Infrastructure: Deploy Dockge and verify web UI access
- [ ] Additional stacks: Test individual stack deployment
- [ ] SSO: Verify authentication works
- [ ] SSL: Check certificate generation
- [ ] VPN: Test Gluetun routing
- [ ] Documentation: Validate all steps in docs/

### Production Success Criteria
- [ ] No permission-related crashes
- [ ] All deployment scripts work on fresh Debian install
- [ ] Documentation matches actual implementation
- [ ] All 60+ services deploy successfully
- [ ] Traefik routes all services correctly
- [ ] Authelia protects appropriate services
- [ ] Gluetun routes download clients through VPN
- [ ] No sudo required for repository file editing

## Communication Guidelines

- Explain what you're doing and why
- Highlight security implications
- Warn about service dependencies
- Provide rollback instructions
- Document any manual steps required
- Ask for clarification on ambiguous requests

This framework ensures reliable, secure, and maintainable homelab infrastructure while enabling automated management through AI agents.