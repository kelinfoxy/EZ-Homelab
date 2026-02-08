# Automated Setup (Recommended)

For most users, the automated setup script handles everything from system preparation to deployment.

## Prerequisites
- **Fresh Debian/Ubuntu server** (or existing system)
- **Root/sudo access**
- **Internet connection**
- **Ports 80 and 443 forwarded** from your router to your **core server only** (required for SSL certificates)

**Note**: For multi-server setups, only the core server needs ports forwarded. 

# Deploy Core Server

## Connect to your server via SSH  
   >Tip: Use VS Code on your local machine to ssh in to your server for the easiest install!  

## Install commands
   ```bash
   sudo apt update && sudo apt upgrade -y && sudo apt install git -y && git clone https://github.com/kelinfoxy/EZ-Homelab.git
   && cd EZ-Homelab
   ```

## Run the ez-homelab.sh script with sudo:  
   `sudo ./scripts/ez-homelab.sh`

### Select option 1 Install Prerequesites 
   * This will install docker and prepare the local environment.

### Logout and back in to apply docker group changes

### Run the script without sudo and select Option 2: Deploy Core Server  
   * It will prompt for required env variables and create/update ~/EZ-Homelab/.env   

   **Note:** Certificate generation may take 2-5 minutes. All services will use the wildcard certificate automatically.  

   **Login credentials:**  
   - Username: `admin` (default username - or the custom username you specified during setup)  
   - Password: The secure password you created when prompted by the setup script  

**That's it!** Your homelab is ready.  
**Access Dockge at `https://dockge.yourdomain.duckdns.org`**  

----

# Deploy Additional Server

>**You must have one and only one core server**

## Follow the steps above but select Option 3: Deploy Additional Server

   * It will prompt for required env variables if missing from ~/EZ-Homelab/.env
   * It includes variables for connecting to the core server

----

## What Gets Deployed Where

| Component | Core Server | Remote Servers |
|-----------|-------------|----------------|
| DuckDNS | ✅ Yes | ❌ No |
| Authelia | ✅ Yes | ❌ No |
| Traefik | ✅ Yes  | ❌ No |
| Sablier | ✅ Yes  | ✅ Yes  |
| Dockge | ✅ Yes | ✅ Yes |
| Services | ✅ Any | ✅ Any |

### Architecture Benefits
- **Single Domain**: All services accessible via core server's domain
- **No Port Forwarding**: Remote servers don't need router configuration
- **Automatic Discovery**: Core Traefik finds services on all servers
- **Local Control**: Each Sablier manages its own server's containers

## What the ez-homelab.sh Script Does

The `ez-homelab.sh` script is a comprehensive guided setup and deployment tool:

**System Preparation (when needed):**
- ✅ Pre-flight checks (internet connectivity, disk space 50GB+)
- ✅ Updates system packages
- ✅ Installs required packages (git, curl, etc.)
- ✅ Installs Docker Engine + Compose V2 (if not present)
- ✅ Configures user permissions (docker, sudo groups)
- ✅ Sets up firewall (UFW with SSH, HTTP, HTTPS)
- ✅ Enables SSH server

**Interactive Configuration:**
- ✅ Prompts for all required env variables
- ✅ Generates three secrets for Authelia (JWT, session, encryption)
- ✅ Generates argon2id password hash for admin password using Docker
- ✅ Validates Docker is available before operations

**Infrastructure Setup & Deployment:**
- ✅ Creates directory structure (`/opt/stacks/` & `opt/dockge`)
- ✅ Sets up Docker networks (homelab, traefik, dockerproxy)
- ✅ Deploys selected service stacks with individual deployment scripts
- ✅ Obtains wildcard SSL certificate (*.yourdomain.duckdns.org)
- ✅ Configures Traefik for multi-server support
- ✅ Detects NVIDIA GPU and offers driver installation

**Safety Features:**
- Interactive guidance with clear prompts
- Timeout handling (60s for Docker operations)
- Comprehensive error messages with troubleshooting hints
- Safe to re-run (idempotent operations)

## Release-Specific Notes
- **Current Version**: Production-ready with comprehensive multi-server support
- **Stacks**: Core, Infrastructure, Sablier, and Dashboards deploy automatically
- **Dashboards**: Homepage is preconfigured at `homepage.yourdomain.duckdns.org`
- **Multi-Server**: Use option 3 for remote server infrastructure deployment
- **Modular Deployment**: Individual scripts in `docker-compose/*/deploy-*.sh` called by ez-homelab.sh