# EZ-Homelab TUI Deployment Script

A modern, user-friendly Terminal User Interface (TUI) replacement for the complex bash deployment script. Built with Python, Rich, and Questionary for an intuitive setup experience.

## Features

- **Interactive TUI**: Beautiful terminal interface with conditional question flow
- **Automated Deployment**: Use `--yes` flag for hands-free deployment with complete .env file
- **Save-Only Mode**: Configure without deploying using `--save-only` flag
- **Smart Validation**: Pre-flight checks ensure system readiness
- **Three Deployment Scenarios**:
  - Single Server Full: Deploy everything (core + infrastructure + dashboards)
  - Core Server: Deploy only essential services
  - Remote Server: Deploy infrastructure for multi-server setups
- **Flexible Service Selection**: Choose which services to deploy and prepare for Dockge

## Quick Start

### Prerequisites

- Ubuntu 20.04+ or Debian 11+
- Python 3.8+
- Internet connection
- DuckDNS account (for dynamic DNS)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kelinfoxy/EZ-Homelab.git
   cd EZ-Homelab
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Copy environment template:**
   ```bash
   cp .env.example .env
   ```

### Usage

#### Interactive Setup (Recommended)
```bash
python ez-homelab-tui.py
```

#### Automated Deployment
```bash
# Complete your .env file first, then:
python ez-homelab-tui.py --yes
```

#### Save Configuration Only
```bash
python ez-homelab-tui.py --save-only
```

## Command Line Options

- No flags: Interactive TUI mode
- `--yes` or `-y`: Automated deployment using complete .env file
- `--save-only`: Answer questions and save .env without deploying
- `--help`: Show help message

## Deployment Scenarios

### 1. Single Server Full Deployment
Deploys everything on one server:
- Core services (DuckDNS, Traefik, Authelia, Sablier, Dockge)
- Infrastructure services (Pi-hole, Dozzle, Glances, etc.)
- Dashboard services (Homepage, Homarr)
- Prepares all additional stacks for Dockge

### 2. Core Server Deployment
Deploys only essential services:
- Core services + Dashboards
- Prepares all additional stacks for Dockge
- Suitable for dedicated core server in multi-server setup

### 3. Remote Server Deployment
Deploys infrastructure without core services:
- Infrastructure services + Dashboards + Dockge
- For application servers in multi-server setup
- Requires core server to be set up first

## Configuration

The script uses a comprehensive `.env` file with two main sections:

### Required Configuration
```bash
# Basic server settings
PUID=1000
PGID=1000
TZ=America/New_York
SERVER_IP=192.168.1.100
SERVER_HOSTNAME=debian

# Domain settings
DUCKDNS_SUBDOMAINS=yourdomain
DUCKDNS_TOKEN=your-token

# Admin credentials (for core servers)
DEFAULT_USER=admin
DEFAULT_PASSWORD=secure-password
DEFAULT_EMAIL=admin@yourdomain.duckdns.org
```

### Deployment Configuration (Optional)
```bash
# For automated deployment
DEPLOYMENT_TYPE=SINGLE_SERVER
AUTO_REBOOT=false
INSTALL_DOCKER=true
INSTALL_NVIDIA=true

# Service selection
DEPLOY_DOCKGE=true
DEPLOY_CORE=true
DEPLOY_INFRASTRUCTURE=true
DEPLOY_DASHBOARDS=true
PREPARE_VPN=true
PREPARE_MEDIA=true
# ... etc
```

## System Requirements

- **OS**: Ubuntu 20.04+ or Debian 11+
- **Python**: 3.8 or higher
- **RAM**: Minimum 4GB (8GB recommended)
- **Disk**: 10GB free space minimum
- **Network**: Internet connection for downloads

## What Gets Installed

### System Setup
- Docker and Docker Compose
- NVIDIA drivers and Container Toolkit (if GPU detected)
- UFW firewall configuration
- Automatic security updates
- Required system packages

### Docker Networks
- `traefik-network`: For services behind Traefik
- `homelab-network`: General service communication
- `media-network`: Media service isolation

### Services Deployed
Based on your deployment scenario and selections.

## Post-Installation

After successful deployment:

1. **Access Dockge**: `https://dockge.yourdomain.duckdns.org`
2. **Configure Authelia**: `https://auth.yourdomain.duckdns.org` (if core services deployed)
3. **Start Additional Services**: Use Dockge web UI to deploy prepared stacks
4. **Access Homepage**: `https://homepage.yourdomain.duckdns.org`

## Troubleshooting

### Common Issues

**"Python version 3.8+ required"**
- Upgrade Python: `sudo apt install python3.10`

**"Missing required dependency"**
- Install dependencies: `pip install -r requirements.txt`

**"Pre-flight checks failed"**
- Ensure you're running on Ubuntu/Debian
- Check internet connectivity
- Verify sufficient disk space

**"Deployment failed"**
- Check Docker installation: `docker --version`
- Verify .env configuration
- Review deployment logs

### Getting Help

- Check the [docs/](docs/) directory for detailed guides
- Review [troubleshooting](docs/quick-reference.md) in the quick reference
- Use the AI assistant in VS Code for EZ-Homelab specific help

## Development

### Running Tests
```bash
# Basic syntax check
python -m py_compile ez-homelab-tui.py

# YAML validation
python -c "import yaml; yaml.safe_load(open('config-templates/traefik/dynamic/external-host-production.yml'))"
```

### Code Structure
- `EZHomelabTUI` class: Main application logic
- Pre-flight checks and validation
- Interactive question flow
- Deployment orchestration
- Configuration management

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

See [LICENSE](LICENSE) file for details.