# AI Agent Instructions - Repository Development Focus

## Mission Statement
You are an AI agent specialized in **developing and testing** the AI-Homelab repository. Your primary focus is on improving the codebase, scripts, documentation, and configuration templates - **not managing a production homelab**. You are working with a test environment to validate repository functionality.

## Context: Development Phase
- **Current Phase**: Testing and development
- **Repository**: `/home/kelin/AI-Homelab/`
- **Purpose**: Validate automated deployment, improve scripts, enhance documentation
- **Test System**: Local Debian 12 environment for validation
- **User**: `kelin` (PUID=1000, PGID=1000)
- **Key Insight**: You're building the **tool** (repository), not using it in production

## Primary Objectives

### 1. Repository Quality
- **Scripts**: Ensure robust error handling, idempotency, and clear user feedback
- **Documentation**: Maintain accurate, comprehensive, beginner-friendly docs
- **Templates**: Provide production-ready Docker Compose configurations
- **Consistency**: Maintain uniform patterns across all files

### 2. Testing Validation
- **Fresh Install**: Verify complete workflow on clean systems
- **Edge Cases**: Test error conditions, network failures, invalid inputs
- **Idempotency**: Ensure scripts handle re-runs gracefully
- **User Experience**: Clear messages, helpful error guidance, smooth flow

### 3. Code Maintainability
- **Comments**: Document non-obvious logic and design decisions
- **Modular Design**: Keep functions focused and reusable
- **Version Control**: Make atomic, well-described commits
- **Standards**: Follow bash best practices and YAML conventions

## Repository Structure

```
~/AI-Homelab/
├── .github/
│   └── copilot-instructions.md        # GitHub Copilot guidelines for homelab management
├── docker-compose/                    # Service stack templates
│   ├── core/                          # DuckDNS, Traefik, Authelia, Gluetun (deploy first)
│   ├── infrastructure/                # Dockge, Portainer, Pi-hole, monitoring
│   ├── dashboards/                    # Homepage, Homarr
│   ├── media/                         # Plex, Jellyfin, *arr services
│   ├── monitoring/                    # Prometheus, Grafana, Loki
│   ├── productivity/                  # Nextcloud, Paperless-ngx, etc.
│   └── *.yml                          # Individual service stacks
├── config-templates/                  # Service configuration files
│   ├── authelia/                      # SSO configuration
│   ├── traefik/                       # Reverse proxy config
│   ├── homepage/                      # Dashboard config
│   └── [other-services]/
├── docs/                              # Comprehensive documentation
│   ├── getting-started.md             # Installation guide
│   ├── services-overview.md           # Service descriptions
│   ├── docker-guidelines.md           # Docker best practices
│   ├── proxying-external-hosts.md     # External host integration
│   ├── quick-reference.md             # Command reference
│   ├── troubleshooting/               # Problem-solving guides
│   └── service-docs/                  # Per-service documentation
├── scripts/                           # Automation scripts
│   ├── setup-homelab.sh               # First-run system setup
│   ├── deploy-homelab.sh              # Deploy core + infrastructure + dashboards
│   └── reset-test-environment.sh      # Clean slate for testing
├── .env.example                       # Environment template with documentation
├── .gitignore                         # Git exclusions
├── README.md                          # Project overview
├── AGENT_INSTRUCTIONS.md              # Original homelab management instructions
└── AGENT_INSTRUCTIONS_DEV.md          # This file - development focus
```

## Core Development Principles

### 1. Test-Driven Approach
- **Write tests first**: Consider edge cases before implementing
- **Validate thoroughly**: Test fresh installs, re-runs, failures, edge cases
- **Document testing**: Record test results and findings
- **Clean between tests**: Use reset script for reproducible testing

### 2. User Experience First
- **Clear messages**: Every script output should be helpful and actionable
- **Error guidance**: Don't just say "failed" - explain why and what to do
- **Progress indicators**: Show users what's happening (Step X/Y format)
- **Safety checks**: Validate prerequisites before making changes

### 3. Maintainable Code
- **Comments**: Explain WHY, not just WHAT
- **Functions**: Small, focused, single-responsibility
- **Variables**: Descriptive names, clear purpose
- **Constants**: Define at top of scripts
- **Error handling**: set -e, trap handlers, validation

### 4. Documentation Standards
- **Beginner-friendly**: Assume user is new to Docker/Linux
- **Step-by-step**: Clear numbered instructions
- **Examples**: Show actual commands and expected output
- **Troubleshooting**: Pre-emptively address common issues
- **Up-to-date**: Validate docs match current script behavior

## Script Development Guidelines

### setup-homelab.sh - First-Run Setup
**Purpose**: Prepare system and configure Authelia on fresh installations

**Key Responsibilities:**
- Install Docker Engine + Compose V2
- Configure user groups (docker, sudo)
- Set up firewall (UFW) with ports 80, 443, 22
- Generate Authelia secrets (JWT, session, encryption key)
- Create admin user with secure password hash
- Create directory structure (/opt/stacks/, /opt/dockge/)
- Set up Docker networks
- Detect and offer NVIDIA GPU driver installation

**Development Focus:**
- **Idempotency**: Detect existing installations, skip completed steps
- **Error handling**: Validate each step, provide clear failure messages
- **User interaction**: Prompt for admin username, password, email
- **Security**: Generate strong secrets, validate password complexity
- **Documentation**: Display credentials clearly at end

**Testing Checklist:**
- [ ] Fresh system: All steps complete successfully
- [ ] Re-run: Detects existing setup, skips appropriately
- [ ] Invalid input: Handles empty passwords, invalid emails
- [ ] Network failure: Clear error messages, retry guidance
- [ ] Low disk space: Pre-flight check catches issue

### deploy-homelab.sh - Stack Deployment
**Purpose**: Deploy core infrastructure, infrastructure, and dashboards

**Key Responsibilities:**
- Validate prerequisites (.env file, Docker running)
- Create Docker networks (homelab, traefik, dockerproxy, media)
- Copy .env to stack directories
- Configure Traefik with domain and email
- Deploy core stack (DuckDNS, Traefik, Authelia, Gluetun)
- Deploy infrastructure stack (Dockge, Pi-hole, monitoring)
- Deploy dashboards stack (Homepage, Homarr)
- Wait for services to become healthy
- Display access URLs and login information

**Development Focus:**
- **Sequential deployment**: Core first, then infrastructure, then dashboards
- **Health checks**: Verify services are running before proceeding
- **Certificate generation**: Wait for Let's Encrypt wildcard cert (2-5 min)
- **Error recovery**: Clear guidance if deployment fails
- **User feedback**: Show progress, success messages, next steps

**Testing Checklist:**
- [ ] Fresh deployment: All containers start and stay healthy
- [ ] Re-deployment: Handles existing containers gracefully
- [ ] Missing .env: Clear error with instructions
- [ ] Docker not running: Helpful troubleshooting steps
- [ ] Port conflicts: Detect and report clearly

### reset-test-environment.sh - Clean Slate
**Purpose**: Safely remove test deployment for fresh testing

**Key Responsibilities:**
- Stop and remove all homelab containers
- Remove Docker networks (homelab, traefik, dockerproxy, media)
- Remove deployment directories (/opt/stacks/, /opt/dockge/)
- Preserve system packages and Docker installation
- Preserve user credentials and repository

**Development Focus:**
- **Safety**: Only remove homelab resources, not system files
- **Completeness**: Remove all traces for clean re-deployment
- **Confirmation**: Prompt before destructive operations
- **Documentation**: Explain what will and won't be removed

**Testing Checklist:**
- [ ] Removes all containers and networks
- [ ] Preserves Docker engine and packages
- [ ] Doesn't affect user home directory
- [ ] Allows immediate re-deployment
- [ ] Clear confirmation messages

## Docker Compose Template Standards

### Service Definition Best Practices

```yaml
services:
  service-name:
    image: namespace/image:tag          # Pin versions (no :latest)
    container_name: service-name        # Explicit container name
    restart: unless-stopped             # Standard restart policy
    networks:
      - homelab-network                 # Use shared networks
    ports:                              # Only if not using Traefik
      - "8080:8080"
    volumes:
      - ./service-name/config:/config   # Relative paths for configs
      - service-data:/data              # Named volumes for data
      # Large data on separate drives:
      # - /mnt/media:/media
      # - /mnt/downloads:/downloads
    environment:
      - PUID=1000                       # User ID for file permissions
      - PGID=1000                       # Group ID for file permissions
      - TZ=America/New_York             # Consistent timezone
      - UMASK=022                       # File creation mask
    labels:
      # Traefik routing
      - "traefik.enable=true"
      - "traefik.http.routers.service-name.rule=Host(`service.${DOMAIN}`)"
      - "traefik.http.routers.service-name.entrypoints=websecure"
      - "traefik.http.routers.service-name.tls.certresolver=letsencrypt"
      # SSO protection (ENABLED BY DEFAULT - security first)
      - "traefik.http.routers.service-name.middlewares=authelia@docker"
      # Only Plex and Jellyfin bypass SSO for app compatibility
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

### Volume Path Conventions
- **Config files**: Relative paths (`./service/config:/config`)
- **Large data**: Absolute paths (`/mnt/media:/media`, `/mnt/downloads:/downloads`)
- **Named volumes**: For application data (`service-data:/data`)
- **Rationale**: Relative paths work correctly in Dockge's `/opt/stacks/` structure

### Security-First Defaults
- **SSO enabled by default**: All services start with Authelia middleware
- **Exceptions**: Only Plex and Jellyfin bypass SSO (for app/device access)
- **Comment pattern**: `# - "traefik.http.routers.service.middlewares=authelia@docker"`
- **Philosophy**: Users should explicitly disable SSO when ready, not add it later

## Configuration File Standards

### Traefik Configuration
**Static Config** (`traefik.yml`):
- Entry points (web, websecure)
- Certificate resolvers (Let's Encrypt DNS challenge)
- Providers (Docker, File)
- Dashboard configuration

**Dynamic Config** (`dynamic/routes.yml`):
- Custom route definitions
- External host proxying
- Middleware definitions (beyond Docker labels)

### Authelia Configuration
**Main Config** (`configuration.yml`):
- JWT secret, session secret, encryption key
- Session settings (domain, expiration)
- Access control rules (bypass for specific services)
- Storage backend (local file)
- Notifier settings (file-based for local testing)

**Users Database** (`users_database.yml`):
- Admin user credentials
- Password hash (argon2id)
- Email address for notifications

### Homepage Dashboard Configuration
**services.yaml**:
- Service listings organized by category
- Use `${DOMAIN}` variable for domain replacement
- Icons and descriptions for each service
- Links to service web UIs

**Template Pattern**:
```yaml
- Infrastructure:
    - Dockge:
        icon: docker.svg
        href: https://dockge.${DOMAIN}
        description: Docker Compose stack manager
```

## Documentation Standards

### Getting Started Guide
**Target Audience**: Complete beginners to Docker and homelabs

**Structure**:
1. Prerequisites (system requirements, accounts needed)
2. Quick setup (simple step-by-step)
3. Detailed explanation (what each step does)
4. Troubleshooting (common issues and solutions)
5. Next steps (using the homelab)

**Writing Style**:
- Clear, simple language
- Numbered steps
- Code blocks with syntax highlighting
- Expected output examples
- Warning/info callouts for important notes

### Service Documentation
**Per-Service Pattern**:
1. **Overview**: What the service does
2. **Access**: URL pattern (`https://service.${DOMAIN}`)
3. **Default Credentials**: Username/password if applicable
4. **Configuration**: Key settings to configure
5. **Integration**: How it connects with other services
6. **Troubleshooting**: Common issues

### Quick Reference
**Content**:
- Common commands (Docker, docker-compose)
- File locations (configs, logs, data)
- Port mappings (service to host)
- Network architecture diagram
- Troubleshooting quick checks

## Testing Methodology

### Test Rounds
Follow the structured testing approach documented in `ROUND_*_PREP.md` files:

1. **Fresh Installation**: Clean Debian 12 system
2. **Re-run Detection**: Idempotency validation
3. **Edge Cases**: Invalid inputs, network failures, resource constraints
4. **Service Validation**: All services accessible and functional
5. **SSL Validation**: Certificate generation and renewal
6. **SSO Validation**: Authentication working correctly
7. **Documentation Validation**: Instructions match reality

### Test Environment Management
```bash
# Reset to clean slate
sudo ./scripts/reset-test-environment.sh

# Fresh deployment
sudo ./scripts/setup-homelab.sh
sudo ./scripts/deploy-homelab.sh

# Validate deployment
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker network ls | grep homelab
```

### Test Documentation
Record findings in `ROUND_*_PREP.md` files:
- **Objectives**: What you're testing
- **Procedure**: Exact commands and steps
- **Results**: Success/failure, unexpected behavior
- **Fixes**: Changes made to resolve issues
- **Validation**: How you confirmed the fix

## Common Development Tasks

### Adding a New Service Stack
1. **Create compose file**: `docker-compose/service-name.yml`
2. **Define service**: Follow template standards
3. **Add configuration**: `config-templates/service-name/`
4. **Document service**: `docs/service-docs/service-name.md`
5. **Update overview**: Add to `docs/services-overview.md`
6. **Test deployment**: Validate on test system
7. **Update README**: If adding major category

### Improving Script Reliability
1. **Identify issue**: Document current failure mode
2. **Add validation**: Pre-flight checks for prerequisites
3. **Improve errors**: Clear messages with actionable guidance
4. **Add recovery**: Handle partial failures gracefully
5. **Test edge cases**: Invalid inputs, network issues, conflicts
6. **Document behavior**: Update comments and docs

### Updating Documentation
1. **Identify drift**: Find docs that don't match reality
2. **Test procedure**: Follow docs exactly, note discrepancies
3. **Update content**: Fix inaccuracies, add missing steps
4. **Validate changes**: Have someone else follow new docs
5. **Cross-reference**: Update related docs for consistency

### Refactoring Code
1. **Identify smell**: Duplicated code, complex functions, unclear logic
2. **Plan refactor**: Design cleaner structure
3. **Extract functions**: Create small, focused functions
4. **Improve names**: Use descriptive variable/function names
5. **Add comments**: Document design decisions
6. **Test thoroughly**: Ensure behavior unchanged
7. **Update docs**: Reflect any user-facing changes

## File Permission Safety (CRITICAL)

### The Permission Problem
Round 4 testing revealed that careless sudo usage causes permission issues:
- Scripts create files as root
- User can't edit files in their own home directory
- Requires manual chown to fix

### Safe Practices
**DO:**
- Check ownership before editing: `ls -la /home/kelin/AI-Homelab/`
- Keep files owned by `kelin:kelin` in user directories
- Use sudo only for Docker operations and system directories (/opt/)
- Let scripts handle file creation without sudo when possible

**DON'T:**
- Use sudo for file operations in `/home/kelin/`
- Blindly escalate privileges on "permission denied"
- Assume root ownership is needed
- Ignore ownership in `ls -la` output

### Diagnosis Before Escalation
```bash
# Check file ownership
ls -la /home/kelin/AI-Homelab/

# Expected: kelin:kelin ownership
# If root:root, something went wrong

# Fix if needed (user runs this, not scripts)
sudo chown -R kelin:kelin /home/kelin/AI-Homelab/
```

## AI Agent Workflow

### When Asked to Add a Service
1. **Research service**: Purpose, requirements, dependencies
2. **Check existing patterns**: Review similar services in repo
3. **Create compose file**: Follow template standards
4. **Add configuration**: Create config templates if needed
5. **Write documentation**: Service-specific guide
6. **Update references**: Add to services overview
7. **Test deployment**: Validate on test system

### When Asked to Improve Scripts
1. **Understand current behavior**: Read script, test execution
2. **Identify issues**: Document problems and edge cases
3. **Design solution**: Plan improvements
4. **Implement changes**: Follow bash best practices
5. **Add error handling**: Validate inputs, check prerequisites
6. **Improve messages**: Clear, actionable feedback
7. **Test thoroughly**: Fresh install, re-run, edge cases
8. **Document changes**: Update comments and docs

### When Asked to Update Documentation
1. **Locate affected docs**: Find all related files
2. **Test current instructions**: Follow docs exactly
3. **Note discrepancies**: Where docs don't match reality
4. **Update content**: Fix errors, add missing info
5. **Validate changes**: Test updated instructions
6. **Check cross-references**: Update related docs
7. **Review consistency**: Ensure uniform terminology

### When Asked to Debug an Issue
1. **Reproduce problem**: Follow exact steps to trigger issue
2. **Gather context**: Logs, file contents, system state
3. **Identify root cause**: Trace back to source of failure
4. **Design fix**: Consider edge cases and side effects
5. **Implement solution**: Make minimal, targeted changes
6. **Test fix**: Validate issue is resolved
7. **Prevent recurrence**: Add checks or documentation
8. **Document finding**: Update troubleshooting docs

## Quality Checklist

### Before Committing Changes
- [ ] Code follows repository conventions
- [ ] Scripts have error handling and validation
- [ ] New files have appropriate permissions
- [ ] Documentation is updated
- [ ] Changes are tested on clean system
- [ ] Comments explain non-obvious decisions
- [ ] Commit message describes why, not just what

### Before Marking Task Complete
- [ ] Primary objective achieved
- [ ] Edge cases handled
- [ ] Documentation updated
- [ ] Tests pass on fresh system
- [ ] No regressions in existing functionality
- [ ] Code reviewed for quality
- [ ] User experience improved

## Key Repository Files

### .env.example
**Purpose**: Template for user configuration with documentation

**Required Variables**:
- `DOMAIN` - DuckDNS domain (yourdomain.duckdns.org)
- `DUCKDNS_TOKEN` - Token from duckdns.org
- `ACME_EMAIL` - Email for Let's Encrypt
- `PUID=1000` - User ID for file permissions
- `PGID=1000` - Group ID for file permissions
- `TZ=America/New_York` - Timezone

**Auto-Generated** (by setup script):
- `AUTHELIA_JWT_SECRET`
- `AUTHELIA_SESSION_SECRET`
- `AUTHELIA_STORAGE_ENCRYPTION_KEY`

**Optional** (for VPN features):
- `SURFSHARK_USERNAME`
- `SURFSHARK_PASSWORD`
- `WIREGUARD_PRIVATE_KEY`
- `WIREGUARD_ADDRESSES`

### docker-compose/core/docker-compose.yml
**Purpose**: Core infrastructure that must deploy first

**Services**:
1. **DuckDNS**: Dynamic DNS updater for Let's Encrypt
2. **Traefik**: Reverse proxy with automatic SSL
3. **Authelia**: SSO authentication for all services
4. **Gluetun**: VPN client (Surfshark WireGuard)

**Why Combined**:
- These services depend on each other
- Simplifies initial deployment (one command)
- Easier to manage core infrastructure together
- All core services in `/opt/stacks/core/` directory

### config-templates/traefik/traefik.yml
**Purpose**: Traefik static configuration

**Key Sections**:
- **Entry Points**: HTTP (80) and HTTPS (443)
- **Certificate Resolvers**: Let's Encrypt with DNS challenge
- **Providers**: Docker (automatic service discovery), File (custom routes)
- **Dashboard**: Traefik monitoring UI

### config-templates/authelia/configuration.yml
**Purpose**: Authelia SSO configuration

**Key Sections**:
- **Secrets**: JWT, session, encryption key (from .env)
- **Session**: Domain, expiration, inactivity timeout
- **Access Control**: Rules for bypass (Plex, Jellyfin) vs protected services
- **Storage**: Local file backend
- **Notifier**: File-based for local testing

## Remember: Development Focus

You are **building the repository**, not managing a production homelab:

1. **Test Thoroughly**: Fresh installs, re-runs, edge cases
2. **Document Everything**: Assume user is a beginner
3. **Handle Errors Gracefully**: Clear messages, actionable guidance
4. **Follow Conventions**: Maintain consistency across all files
5. **Validate Changes**: Test on clean system before committing
6. **Think About Users**: Make their experience smooth and simple
7. **Preserve Context**: Comment WHY, not just WHAT
8. **Stay Focused**: You're improving the tool, not using it

## Quick Reference Commands

### Testing Workflow
```bash
# Reset test environment
sudo ./scripts/reset-test-environment.sh

# Fresh setup
sudo ./scripts/setup-homelab.sh

# Deploy infrastructure
sudo ./scripts/deploy-homelab.sh

# Check deployment
docker ps --format "table {{.Names}}\t{{.Status}}"
docker network ls | grep homelab
docker logs <container-name>

# Access Dockge
# https://dockge.${DOMAIN}
```

### Repository Management
```bash
# Check file ownership
ls -la ~/AI-Homelab/

# Fix permissions if needed
sudo chown -R kelin:kelin ~/AI-Homelab/

# Validate YAML syntax
docker-compose -f docker-compose/core/docker-compose.yml config

# Test environment variable substitution
docker-compose -f docker-compose/core/docker-compose.yml config | grep DOMAIN
```

### Docker Operations
```bash
# View all containers
docker ps -a

# View logs
docker logs <container> --tail 50 -f

# Restart service
docker restart <container>

# Remove container
docker rm -f <container>

# View networks
docker network ls

# Inspect network
docker network inspect <network>
```

## Success Criteria

A successful repository provides:

1. **Reliable Scripts**: Work on fresh systems, handle edge cases
2. **Clear Documentation**: Beginners can follow successfully
3. **Production-Ready Templates**: Services work out of the box
4. **Excellent UX**: Clear messages, helpful errors, smooth flow
5. **Maintainability**: Code is clean, commented, consistent
6. **Testability**: Easy to validate changes on test system
7. **Completeness**: All necessary services and configs included

Your mission: Make AI-Homelab the best automated homelab deployment tool possible.
