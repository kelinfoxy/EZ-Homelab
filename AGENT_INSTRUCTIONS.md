# AI Agent Instructions for Homelab Management

## Primary Directive
You are an AI agent specialized in managing Docker-based homelab infrastructure using Dockge. Always prioritize security, consistency, and stability across the entire server stack.

## Repository Context
- **Repository Location**: `/home/kelin/AI-Homelab/`
- **Purpose**: Development and testing of automated homelab management via GitHub Copilot
- **Testing Phase**: Round 6 - Focus on script reliability, error handling, and deployment robustness
- **User**: `kelin` (PUID=1000, PGID=1000)
- **Critical**: All file operations must respect user ownership - avoid permission escalation issues

## Repository Structure
```
~/AI-Homelab/
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
    restart: unless-stopped
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

## Critical Deployment Order

1. **Core Stack First**: Deploy `/opt/stacks/core/docker-compose.yml`
   - DuckDNS, Traefik, Authelia, Gluetun
   - All other services depend on this
2. **Infrastructure**: Dockge, Portainer, monitoring
3. **Applications**: Media services, dashboards, etc.

## VPN Integration Rules

Use Gluetun for services requiring VPN:
```yaml
services:
  download-client:
    network_mode: "service:gluetun"
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

### Permission Safety (CRITICAL - Established in Round 4)
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

### Development Workflow (Current Focus - Round 6)
1. **Repository Testing**
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
1. Create stack directory: `/opt/stacks/stack-name/`
2. Write docker-compose.yml with template
3. Create `.env` file for secrets
4. Deploy: `docker compose up -d`
5. Verify Traefik routing
6. Test SSO protection

### Update Existing Service
1. Read current configuration
2. Make minimal necessary changes
3. Validate dependencies still work
4. Redeploy: `docker compose up -d service-name`
5. Check logs for errors

### Enable/Disable VPN
1. For VPN: Add `network_mode: "service:gluetun"`
2. Move port mapping to Gluetun service
3. Add `depends_on: gluetun`
4. For no VPN: Remove network_mode, add ports directly

### Toggle SSO
1. Enable: Add authelia middleware label
2. Disable: Comment out middleware label
3. Redeploy service
4. Verify access works as expected

## Error Prevention

### Port Conflicts
- Check existing services before assigning ports
- Use Traefik instead of port mapping when possible
- Document port usage in comments

### Permission Issues
- Always set PUID=1000, PGID=1000
- Check directory ownership on host
- Use consistent user/group across services

### Network Issues
- Verify shared networks exist
- Use service names for inter-service communication
- Ensure Traefik can reach services

## Key Configurations to Monitor

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
   chown -R kelin:kelin ~/AI-Homelab  # No sudo needed in home dir
   
   # For Docker-managed directories, leave as root
   # (e.g., /opt/stacks/*/data/ created by containers)
   ```

3. **Prevent Future Issues**
   - Edit files in `~/AI-Homelab/` without sudo
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
- Read existing configurations first
- Test changes in isolation when possible
- Document complex configurations
- Follow established naming patterns
- Prioritize security over convenience
- Maintain consistency across the stack
- **Check file permissions before operations**
- **Respect user ownership boundaries**
- **Ask before modifying system directories**

## Testing and Development Guidelines (Round 6)

### Repository Development
- Work within `~/AI-Homelab/` for all development
- Test scripts in isolated environment before production
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
ls -la ~/AI-Homelab/
```

### Deployment Testing Checklist
- [ ] Fresh system: Test `setup-homelab.sh`
- [ ] Core stack: Deploy and verify DuckDNS, Traefik, Authelia, Gluetun
- [ ] Infrastructure: Deploy Dockge and verify web UI access
- [ ] Additional stacks: Test individual stack deployment
- [ ] SSO: Verify authentication works
- [ ] SSL: Check certificate generation
- [ ] VPN: Test Gluetun routing
- [ ] Documentation: Validate all steps in docs/

### Round 6 Success Criteria
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