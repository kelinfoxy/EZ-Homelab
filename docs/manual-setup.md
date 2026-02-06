# Manual Setup Guide

If you prefer manual control or the automated script fails, follow these steps for manual installation.

## Prerequisites

- Fresh Debian/Ubuntu server or existing system
- Root/sudo access
- Internet connection

## Step 1: Update System

```bash
sudo apt update && sudo apt upgrade -y
```

## Step 2: Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker your-username

# Log out and back in, or run: newgrp docker
```

## Step 3: Clone Repository

```bash
cd ~
git clone https://github.com/kelinfoxy/EZ-Homelab.git
cd EZ-Homelab
```

## Step 4: Generate Secrets
```yaml
# Generate 3 Secrets for Authelia

# Generate hash for your password
docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password 'YourSecurePassword'

```

## Step 5: Configure Environment

```bash
cp .env.example .env
nano .env  # Edit all required variables
```

**Minimum Required variables:**
* PUID
* PGID
* TZ
* SERVER_IP                       
* SERVER_HOSTNAME                         
* DUCKDNS_SUBDOMAINS
* DUCKDNS_TOKEN
* DOMAIN
* DEFAULT_USER                             
* DEFAULT_PASSWORD
* DEFAULT_EMAIL  
**If using VPN**:
* SURFSHARK_USERNAM
* SURFSHARK_PASSWORD
* VPN_SERVER_COUNTRIES

## Step 6: Create Infrastructure

```bash
# Create directories
sudo mkdir -p /opt/stacks /opt/dockge 
sudo chown -R $USER:$USER /opt/stacks
sudo chown -R $USER:$USER /opt/dockge

# Create networks
docker network create traefik-network
docker network create homelab-network
docker network create dockerproxy-network
docker network create media-network
```

## Step 7: Copy folders
```yaml
sudo cp ~/EZ-Homelab/docker-compose /opt/stacks
# Move the dockge stack outside the stacks folder so you can't accidently stop dockge from dockge's webui
sudo mv /opt/stacks/dockge /opt/dockge
```

## Step 8: Configure Stacks

Some services require manualy editing the configuration files.  
Each stack has a script `deploy-stackname.sh` which will replace variables in the config files and the traefik labels in the compose file.

See the `Readme.md` file in each stack folder for manual instructions for each stack.

