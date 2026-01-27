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
# Install dependencies
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Or use convenience script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
sudo usermod -aG sudo $USER

# Log out and back in, or run: newgrp docker
```

## Step 3: Clone Repository

```bash
cd ~
git clone https://github.com/kelinfoxy/AI-Homelab.git
cd AI-Homelab
```

## Step 4: Configure Environment

```bash
cp .env.example .env
nano .env  # Edit all required variables
```

**Required variables:**
- `DOMAIN` - Your DuckDNS domain
- `DUCKDNS_TOKEN` - Your DuckDNS token
- `ACME_EMAIL` - Your email for Let's Encrypt
- `AUTHELIA_JWT_SECRET` - Generate with: `openssl rand -hex 64`
- `AUTHELIA_SESSION_SECRET` - Generate with: `openssl rand -hex 64`
- `AUTHELIA_STORAGE_ENCRYPTION_KEY` - Generate with: `openssl rand -hex 64`
- `SURFSHARK_USERNAME` and `SURFSHARK_PASSWORD` - If using VPN

## Step 5: Create Infrastructure

```bash
# Create directories
sudo mkdir -p /opt/stacks /mnt/{media,database,downloads,backups}
sudo chown -R $USER:$USER /opt/stacks /mnt

# Create networks
docker network create traefik-network
docker network create homelab-network
docker network create dockerproxy-network
docker network create media-network
```

## Step 6: Generate Authelia Password Hash

```bash
# Generate password hash (takes 30-60 seconds)
docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password 'YourSecurePassword'

# Copy the hash starting with $argon2id$...
```

## Step 7: Configure Authelia

```bash
# Copy Authelia config templates
mkdir -p /opt/stacks/core/authelia
cp config-templates/authelia/* /opt/stacks/core/authelia/

# Edit users_database.yml
nano /opt/stacks/core/authelia/users_database.yml

# Replace password hash and email in the users section:
users:
  admin:
    displayname: "Admin User"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."  # Your hash here
    email: your.email@example.com
    groups:
      - admins
      - users
```

## Step 8: Deploy Core Services

```bash
# Deploy core infrastructure
sudo mkdir -p /opt/stacks/core
cp docker-compose/core/docker-compose.yml /opt/stacks/core/docker-compose.yml
cp -r config-templates/traefik /opt/stacks/core/
cp .env /opt/stacks/core/

# Update Traefik email
sed -i "s/admin@example.com/$ACME_EMAIL/" /opt/stacks/core/traefik/traefik.yml

cd /opt/stacks/core
docker compose up -d
```

## Step 9: Deploy Infrastructure Stack

```bash
sudo mkdir -p /opt/stacks/infrastructure
cp docker-compose/infrastructure/docker-compose.yml /opt/stacks/infrastructure/docker-compose.yml
cp .env /opt/stacks/infrastructure/
cd /opt/stacks/infrastructure
docker compose up -d
```

## Step 10: Deploy Dashboards

```bash
sudo mkdir -p /opt/stacks/dashboards
cp docker-compose/dashboards/docker-compose.yml /opt/stacks/dashboards/docker-compose.yml
cp -r config-templates/homepage /opt/stacks/dashboards/
cp .env /opt/stacks/dashboards/

# Replace Homepage domain variables
find /opt/stacks/dashboards/homepage -type f \( -name "*.yaml" -o -name "*.yml" \) -exec sed -i "s/{{HOMEPAGE_VAR_DOMAIN}}/$DOMAIN/g" {} \;

cd /opt/stacks/dashboards
docker compose up -d
```

## Step 10.5: Multi-Server TLS Setup (Optional)

If you plan to deploy services on remote servers (like Raspberry Pi) that will be managed by Sablier for lazy loading, set up shared TLS certificates.

### On Core Server (where Traefik/Authelia run):

```bash
# Create shared CA directory
sudo mkdir -p /opt/stacks/core/shared-ca
sudo chown $USER:$USER /opt/stacks/core/shared-ca

# Generate shared CA certificate
cd /opt/stacks/core/shared-ca
openssl genrsa -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem -subj "/C=US/ST=State/L=City/O=Homelab/CN=Homelab-CA"

# Set proper permissions
chmod 600 ca-key.pem
chmod 644 ca.pem
```

### On Remote Servers:

```bash
# Create TLS directory
sudo mkdir -p /opt/stacks/core/shared-ca
sudo chown $USER:$USER /opt/stacks/core/shared-ca

# Copy shared CA from core server (replace CORE_IP with your core server IP)
scp user@CORE_IP:/opt/stacks/core/shared-ca/ca.pem /opt/stacks/core/shared-ca/
scp user@CORE_IP:/opt/stacks/core/shared-ca/ca-key.pem /opt/stacks/core/shared-ca/

# Generate client certificate for Docker client connections
openssl genrsa -out client-key.pem 4096
openssl req -subj "/CN=client" -new -key client-key.pem -out client.csr
openssl x509 -req -days 365 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem

# Configure Docker TLS
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "tls": true,
  "tlsverify": true,
  "tlscacert": "/opt/stacks/core/shared-ca/ca.pem",
  "tlscert": "/opt/stacks/core/shared-ca/server-cert.pem",
  "tlskey": "/opt/stacks/core/shared-ca/server-key.pem"
}
EOF

# Update Docker service to listen on TLS port
sudo sed -i 's|-H fd://|-H fd:// -H tcp://0.0.0.0:2376|' /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl restart docker

# Test TLS connection from core server
# On core server, run: docker --tlsverify --tlscacert /opt/stacks/core/shared-ca/ca.pem --tlscert /opt/stacks/core/shared-ca/client-cert.pem --tlskey /opt/stacks/core/shared-ca/client-key.pem -H tcp://REMOTE_IP:2376 ps
```

## Step 11: Verify Deployment

```bash
# Check running containers
docker ps

# Check logs if any service fails
docker logs container-name

# Access services
echo "Dockge: https://dockge.$DOMAIN"
echo "Authelia: https://auth.$DOMAIN"
echo "Traefik: https://traefik.$DOMAIN"
```

## Troubleshooting

**Permission issues:**
```bash
# Ensure proper ownership
sudo chown -R $USER:$USER /opt/stacks

# Check group membership
groups $USER
```

**Container won't start:**
```bash
# Check logs
docker logs container-name

# Check compose file syntax
docker compose config
```

**Network conflicts:**
```bash
# List existing networks
docker network ls

# Remove and recreate if needed
docker network rm network-name
docker network create network-name
```

## When to Use Manual Setup

- Automated script fails on your system
- You want full control over each step
- You're using a non-Debian/Ubuntu distribution
- You need custom configurations
- You're troubleshooting deployment issues

## Switching to Automated

If manual setup works, you can switch to the unified automated script for future updates:

```bash
# Just run the unified setup script
cd ~/EZ-Homelab
./scripts/ez-homelab.sh
```

The unified script is idempotent - it won't break existing configurations.
