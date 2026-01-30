# EZ-Homelab Enhanced Setup Scripts - Standards & Conventions

## Script Communication & Standards

### Exit Codes
- **0**: Success - Script completed without issues
- **1**: Error - Script failed, requires user intervention
- **2**: Warning - Script completed but with non-critical issues
- **3**: Skipped - Script skipped due to conditions (e.g., already installed)

### Logging
- **Location**: `/var/log/ez-homelab/` (created by setup.sh)
- **Format**: `YYYY-MM-DD HH:MM:SS [SCRIPT_NAME] LEVEL: MESSAGE`
- **Levels**: INFO, WARN, ERROR, DEBUG
- **Rotation**: Use logrotate with weekly rotation, keep 4 weeks

### Shared Variables (lib/common.sh)
```bash
# Repository and paths
EZ_HOME="${EZ_HOME:-/home/kelin/EZ-Homelab}"
STACKS_DIR="${STACKS_DIR:-/opt/stacks}"
LOG_DIR="${LOG_DIR:-/var/log/ez-homelab}"

# User and system
EZ_USER="${EZ_USER:-$USER}"
EZ_UID="${EZ_UID:-$(id -u)}"
EZ_GID="${EZ_GID:-$(id -g)}"

# Architecture detection
ARCH="$(uname -m)"
IS_ARM64=false
[[ "$ARCH" == "aarch64" ]] && IS_ARM64=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
```

### Configuration Files
- **Format**: Use YAML for complex configurations, .env for environment variables
- **Location**: `scripts/enhanced-setup/config/` for script configs
- **Validation**: All configs validated with `yq` (YAML) or `dotenv` (env)

### Function Naming
- **Prefix**: Use script name (e.g., `preflight_check_disk()`)
- **Style**: snake_case for functions, UPPER_CASE for constants
- **Documentation**: All functions have header comments with purpose, parameters, return values

## UI/UX Design

### Dialog/Whiptail Theme
- **Colors**: Blue headers (#0000FF), Green success (#00FF00), Red errors (#FF0000)
- **Size**: Auto-size based on content, minimum 80x24
- **Title**: "EZ-Homelab Setup - [Script Name]"
- **Backtitle**: "EZ-Homelab Enhanced Setup Scripts v1.0"

### Menu Flow
- **Navigation**: Tab/Arrow keys, Enter to select, Esc to cancel
- **Progress**: Use `--gauge` for long operations with percentage
- **Confirmation**: Always confirm destructive actions with "Are you sure? (y/N)"
- **Help**: F1 key shows context help, `--help` flag for command-line usage

### User Prompts
- **Style**: Clear, action-oriented (e.g., "Press Enter to continue" not "OK")
- **Defaults**: Safe defaults (e.g., N for destructive actions)
- **Validation**: Real-time input validation with error messages

## Error Handling & Recovery

### Error Types
- **Critical**: Script cannot continue (exit 1)
- **Warning**: Issue noted but script continues (exit 2)
- **Recoverable**: User can fix and retry

### Recovery Mechanisms
- **Backups**: Automatic backup of modified files (`.bak` extension)
- **Rollback**: `--rollback` flag to undo last operation
- **Resume**: Scripts detect partial completion and offer to resume
- **Cleanup**: `--cleanup` flag removes temporary files and partial installs

### User Guidance
- **Error Messages**: Include suggested fix (e.g., "Run 'sudo apt update' and retry")
- **Logs**: Point to log file location for detailed errors
- **Support**: Include link to documentation or issue tracker

## Testing & Validation

### Unit Testing
- **Tool**: ShellCheck for syntax validation
- **Coverage**: All scripts pass ShellCheck with no warnings
- **Mocks**: Use `mktemp` and environment variables to mock external calls

### Integration Testing
- **Environments**: 
  - AMD64: Ubuntu 22.04 LTS VM
  - ARM64: Raspberry Pi OS (64-bit) on Pi 4
- **Scenarios**: Clean install, partial install recovery, network failures
- **Automation**: Use GitHub Actions for CI/CD with matrix testing

### Validation Checks
- **Pre-run**: Scripts validate dependencies and environment
- **Post-run**: Verify expected files, services, and configurations
- **Cross-script**: Ensure scripts don't conflict (e.g., multiple network creations)

## Integration Points

### Existing EZ-Homelab Structure
- **Repository**: Scripts read from `$EZ_HOME/docker-compose/` and `$EZ_HOME/.env`
- **Runtime**: Deploy to `$STACKS_DIR/` matching current structure
- **Services**: Leverage existing compose files without modification
- **Secrets**: Use existing `.env` pattern, never commit secrets

### Service Dependencies
- **Core First**: All scripts enforce core stack deployment before others
- **Network Requirements**: Scripts create `traefik-network` and `homelab-network` as needed
- **Port Conflicts**: Validate no conflicts before deployment
- **Health Checks**: Use Docker health checks where available

### Version Compatibility
- **Docker**: Support 20.10+ with Compose V2
- **OS**: Debian 11+, Ubuntu 20.04+, Raspbian/Raspberry Pi OS
- **Architecture**: AMD64 and ARM64 with PiWheels for Python packages

## Development Workflow

### Branching Strategy
- **Main**: Production-ready code
- **Develop**: Integration branch
- **Feature**: `feature/script-name` for individual scripts
- **Hotfix**: `hotfix/issue-description` for urgent fixes

### Code Reviews
- **Required**: All PRs need review from at least one maintainer
- **Checklist**: Standards compliance, testing, documentation
- **Automation**: GitHub Actions for basic checks (ShellCheck, YAML validation)

### Documentation
- **Inline**: All functions and complex logic documented
- **README**: Each script has usage examples
- **Updates**: PRD updated with implemented features
- **Changelog**: Maintain `CHANGELOG.md` with version history

### Release Process
- **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Testing**: Full integration test before release
- **Packaging**: Scripts distributed as part of EZ-Homelab repository
- **Announcement**: Release notes with breaking changes highlighted