# Implementation Plan Corrections

## User Feedback Summary

### 1. Remove `prompt_for_server_role()` Function
**Issue**: Unnecessary function - should integrate with existing validation  
**Solution**: Use existing menu structure (Option 2: Deploy Core, Option 3: Deploy Additional Server) and integrate role detection into existing `validate_and_prompt_variables()` function via dynamic REQUIRED_VARS

### 2. Remove `validate_env_file()` Function  
**Issue**: Duplicates existing REQUIRED_VARS mechanism  
**Solution**: Enhance existing system:
- Add `set_required_vars_for_deployment(type)` function to dynamically set REQUIRED_VARS
- Reuse existing `validate_and_prompt_variables()` (line 562) - already validates and prompts
- No new validation function needed

### 3. config-templates Folder is Deprecated
**Issue**: Plan references `config-templates/` which should be deleted  
**Solution**: All working configs are in `docker-compose/` folder
- Update references: `docker-compose/core/traefik/traefik.yml` (not config-templates)
- Delete config-templates folder if still exists

### 4. .env Editing Should Be Optional
**Issue**: Plan suggests users manually edit .env in step 4.2  
**Solution**: 
- Script ALWAYS prompts for ALL required variables for the deployment option
- When user selects Option 3 (Deploy Additional Server):
  - Call `set_required_vars_for_deployment("remote")`
  - Sets REQUIRED_VARS to include: REMOTE_SERVER_IP, REMOTE_SERVER_HOSTNAME, REMOTE_SERVER_USER
  - Call `validate_and_prompt_variables()` - prompts for all
  - Save complete .env via `save_env_file()`

### 5. Deploy Scripts Should Auto-Backup
**Issue**: Migration path has manual backup steps  
**Solution**:
- Deploy scripts MUST backup automatically before changes
- **Critical**: Verify backups are from `/opt/stacks/*/` (deployed location), NOT `~/EZ-Homelab/docker-compose/*/` (repo source)
- Expected backup pattern: `/opt/stacks/core/traefik.backup.TIMESTAMP/`
  where TIMESTAMP is like YY_MM_DD_hh_mm 
- Review all deploy functions for correct backup logic

### 6. Traefik Dynamic Folder Files Need Replacement
**Issue**: Existing `external-host-*.yml` files are for old method  
**Solution**:
- During core deployment, replace entire `traefik/dynamic/` folder contents
- New files:
  - `sablier.yml` (updated middleware format)
  - Auto-generated provider-specific configs
- Deploy script should:
  1. Backup `/opt/stacks/core/traefik/dynamic/` to timestamped folder
  2. Copy new configs from `docker-compose/core/traefik/dynamic/`
  3. Process variables via `localize_config_file()`

---

## Corrected Function List

### Functions to ADD (New):

**In common.sh:**
- `detect_server_role()` - Check .env to determine core vs remote
- `generate_traefik_provider_config()` - Generate YAML for remote provider
- `generate_sablier_middleware_config()` - Generate YAML for remote Sablier
- `add_remote_server_to_traefik()` - Register remote server with core

**In ez-homelab.sh:**
- `check_docker_installed()` - Silent Docker check with timeout (Pi-safe)
- `set_required_vars_for_deployment(type)` - Set REQUIRED_VARS dynamically
- `deploy_remote_server()` - Deploy Docker TLS + Sablier on remote servers

### Functions to MODIFY (Existing):

**In ez-homelab.sh:**
- `REQUIRED_VARS` (line 398) - Make dynamic via `set_required_vars_for_deployment()`
- `main()` - Add Docker pre-check, call `set_required_vars_for_deployment()` before validation
- `deploy_core()` - Auto-deploy Sablier stack after core stack
- `validate_and_prompt_variables()` (line 562) - NO CHANGES (already does what we need)

### Functions NOT NEEDED:
- ~~`prompt_for_server_role()`~~ - Use existing menu structure
- ~~`validate_env_file()`~~ - Use existing REQUIRED_VARS mechanism

---

## Corrected Workflow

### Option 2: Deploy Core (Existing Option)
```bash
main() {
    case $DEPLOY_CHOICE in
        2)
            # Deploy Core
            set_required_vars_for_deployment "core"  # NEW
            validate_and_prompt_variables            # EXISTING - reuse
            save_env_file                            # EXISTING
            DEPLOY_CORE=true
            # In deploy_core(): auto-deploy Sablier after core
            ;;
```

### Option 3: Deploy Additional Server (New Option)
```bash
        3)
            # Deploy Additional Server
            set_required_vars_for_deployment "remote"  # NEW - sets REQUIRED_VARS
            validate_and_prompt_variables              # EXISTING - prompts for all
            save_env_file                              # EXISTING
            deploy_remote_server                       # NEW function
            ;;
```

### REQUIRED_VARS Dynamic Setting
```bash
set_required_vars_for_deployment() {
    local deployment_type="${1:-core}"
    
    if [ "$deployment_type" == "core" ]; then
        REQUIRED_VARS=("SERVER_IP" "SERVER_HOSTNAME" "DUCKDNS_SUBDOMAINS" "DUCKDNS_TOKEN" "DOMAIN" "DEFAULT_USER" "DEFAULT_PASSWORD" "DEFAULT_EMAIL")
    elif [ "$deployment_type" == "remote" ]; then
        REQUIRED_VARS=("SERVER_IP" "SERVER_HOSTNAME" "REMOTE_SERVER_IP" "REMOTE_SERVER_HOSTNAME" "REMOTE_SERVER_USER" "DEFAULT_USER" "DEFAULT_EMAIL")
    fi
}
```

---

## Corrected File Structure

### Repo Source Files (docker-compose/):
```
docker-compose/
├── core/
│   ├── docker-compose.yml          # Remove Sablier section
│   ├── traefik/
│   │   ├── traefik.yml             # Static config with provider template
│   │   └── dynamic/
│   │       ├── sablier.yml         # Updated middleware configs
│   │       └── (other dynamic configs)
│   └── authelia/
├── sablier/                        # NEW STACK
│   ├── docker-compose.yml          # Container name: sablier
│   └── README.md                   # Stack documentation
└── (other stacks)/
```

### Deployed Files (/opt/stacks/):
```
/opt/stacks/
├── core/                           # Core stack only (no Sablier)
│   ├── docker-compose.yml
│   ├── traefik/
│   │   ├── config/traefik.yml
│   │   └── dynamic/
│   │       ├── sablier.yml
│   │       └── (auto-generated provider configs)
│   └── shared-ca/                  # Shared CA certificates
├── sablier/                        # Sablier stack (all servers)
│   ├── docker-compose.yml
│   └── .env                        # Environment variables (copied from repo)
└── (other stacks)/
```

---

## Critical Backup Check

**Problem**: Deploy scripts may backup from repo instead of deployed location

**Incorrect (if found)**:
```bash
# DON'T do this - backs up repo source, not deployed config
cp -r ~/EZ-Homelab/docker-compose/core/traefik ~/backups/
```

**Correct**:
```bash
# DO this - backs up deployed configuration
# Format: traefik.backup.YY_MM_DD_hh_mm
cp -r /opt/stacks/core/traefik /opt/stacks/core/traefik.backup.$(date +%y_%m_%d_%H_%M)
```

**Action**: Review `deploy_core()` and all deploy functions for correct backup paths

---

## Implementation Priority

1. ✅ **Delete** `config-templates/` folder
2. ✅ **Verify** deploy scripts backup from `/opt/stacks/` not repo
3. ✅ **Add** `set_required_vars_for_deployment()` function
4. ✅ **Add** `check_docker_installed()` function
5. ✅ **Modify** `main()` to use dynamic REQUIRED_VARS
6. ✅ **Create** `docker-compose/sablier/` stack
7. ✅ **Remove** Sablier from `docker-compose/core/docker-compose.yml`
8. ✅ **Add** common.sh functions for multi-server support
9. ✅ **Add** `deploy_remote_server()` function
10. ✅ **Update** `docker-compose/core/traefik/dynamic/` files

---

*Corrections Version: 1.0*  
*Date: February 4, 2026*  
*Based on: User feedback on implementation plan v2.0*
