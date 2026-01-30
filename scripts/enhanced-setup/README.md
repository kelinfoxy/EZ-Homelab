# EZ-Homelab Enhanced Setup System

A comprehensive, modular bash-based setup and management system for EZ-Homelab, replacing the complex Python TUI with robust, cross-platform scripts.

## 🚀 Quick Start

### For Fresh Installs (Recommended)
```bash
# Clone the repository
git clone https://github.com/kelinfoxy/EZ-Homelab.git
cd EZ-Homelab

# Start the interactive menu system
cd scripts/enhanced-setup
./menu.sh
```

The menu provides guided access to all functionality with real-time system status.

### Manual Usage
```bash
cd scripts/enhanced-setup

# Phase 1: System Setup
./preflight.sh    # Validate system requirements
./setup.sh        # Install Docker and dependencies

# Phase 2: Configuration
./pre-deployment-wizard.sh  # Interactive service selection
./localize.sh               # Apply environment variables
./validate.sh               # Validate configurations

# Phase 3: Deployment
./deploy.sh core           # Deploy core services
./deploy.sh infrastructure # Deploy infrastructure
./deploy.sh monitoring     # Deploy monitoring stack

# Phase 4: Management
./service.sh list          # List all services
./monitor.sh dashboard     # System monitoring
./backup.sh config         # Backup configurations
./update.sh check          # Check for updates
```

## 📋 System Architecture

### Phase 1: Core Infrastructure
- **preflight.sh**: System requirement validation
- **setup.sh**: Docker installation and configuration

### Phase 2: Configuration Management
- **pre-deployment-wizard.sh**: Interactive service selection and configuration
- **localize.sh**: Template variable substitution
- **generalize.sh**: Reverse template processing
- **validate.sh**: Multi-purpose validation (environment, compose, network, SSL)

### Phase 3: Deployment Engine
- **deploy.sh**: Orchestrated service deployment with health checks and rollback

### Phase 4: Service Orchestration & Management
- **service.sh**: Individual service management (start/stop/restart/logs/exec)
- **monitor.sh**: Real-time monitoring and alerting
- **backup.sh**: Automated backup orchestration
- **update.sh**: Service update management with zero-downtime

### Shared Libraries
- **lib/common.sh**: Shared utilities, logging, validation functions
- **lib/ui.sh**: Text-based UI components and progress indicators

## 🎯 Key Features

- **🔧 Template-Based Configuration**: Environment variable substitution system
- **🚀 Smart Deployment**: Dependency-ordered deployment with health verification
- **📊 Real-Time Monitoring**: System resources, service health, and alerting
- **💾 Automated Backups**: Configuration, volumes, logs with retention policies
- **⬆️ Safe Updates**: Rolling updates with rollback capabilities
- **🔍 Comprehensive Validation**: Multi-layer checks for reliability
- **📝 Detailed Logging**: Structured logging to `~/.ez-homelab/logs/`
- **🔄 Cross-Platform**: Works on Linux, macOS, and other Unix-like systems

## 📖 Documentation

- **[PRD](prd.md)**: Product Requirements Document
- **[Standards](standards.md)**: Development standards and guidelines
- **[Traefik Guide](../docs/Traefik%20Routing%20Quick%20Reference.md)**: Traefik configuration reference

## 🛠️ Environment Variables

Create a `.env` file in the EZ-Homelab root directory:

```bash
# Domain and SSL
DOMAIN=yourdomain.com
EMAIL=your@email.com

# Timezone
TZ=America/New_York

# User IDs (auto-detected if not set)
EZ_USER=yourusername
EZ_UID=1000
EZ_GID=1000

# Service-specific variables
# Add as needed for your services
```

## 🏗️ Development

### Prerequisites
- Bash 4.0+
- Docker and Docker Compose
- Standard Unix tools (curl, wget, jq, git)

### Adding New Services
1. Create docker-compose.yml in appropriate category directory
2. Add template variables with `${VAR_NAME}` syntax
3. Update service discovery in common.sh if needed
4. Test with validation scripts

### Script Standards
- Follow the established patterns in existing scripts
- Use shared libraries for common functionality
- Include comprehensive error handling and logging
- Add help text with `--help` flag

## 🤝 Contributing

1. Follow the development standards in `standards.md`
2. Test thoroughly on multiple platforms
3. Update documentation as needed
4. Submit pull requests with clear descriptions

## 📄 License

This project is part of EZ-Homelab. See the main repository for licensing information.

## 🆘 Troubleshooting

### Common Issues
- **Permission denied**: Run `chmod +x *.sh lib/*.sh`
- **Docker not found**: Run `./setup.sh` first
- **Template errors**: Check `.env` file and run `./validate.sh`
- **Service failures**: Check logs with `./service.sh logs <service>`

### Getting Help
- Check the logs in `~/.ez-homelab/logs/`
- Run individual scripts with `--help` for usage
- Use the troubleshooting tools in the Advanced menu
- Check the documentation files for detailed guides

---

**Happy Homelabbing!** 🏠💻