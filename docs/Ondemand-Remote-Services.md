# On Demand Remote Services with Authelia, Sablier & Traefik

## Overview

This guide explains how to set up lazy-loading services on remote servers (like Raspberry Pi) that start automatically when accessed via Traefik. The core server runs Sablier, which connects to remote Docker daemons via TLS to manage container lifecycle.

## Prerequisites

- Core server with Traefik, Authelia, and Sablier deployed
- Remote server with Docker installed
- Shared TLS CA configured between core and remote servers

## Automated Setup

For new remote servers, use the automated script:

1. On the remote server, run `ez-homelab.sh` and select option 3 (Infrastructure Only)
2. When prompted, enter the core server IP for shared TLS CA
3. The script will automatically:
   - Copy shared CA from core server via SSH
   - Configure Docker TLS with shared certificates
   - Generate server certificates signed by shared CA
   - Set up Docker daemon for TLS on port 2376

**Important**: The script will fail if it cannot copy the shared CA from the core server. Ensure SSH access is configured between servers before running option 3.

## Manual Setup (if automated fails)

If the automated setup fails, manually configure TLS:

### On Core Server:
```bash
# Generate server certificates for remote server
cd /opt/stacks/core/shared-ca
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=<REMOTE_IP>" -new -key server-key.pem -out server.csr
echo "subjectAltName = DNS:<REMOTE_IP>,IP:<REMOTE_IP>,IP:127.0.0.1" > extfile.cnf
openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf
```

### On Remote Server:
```bash
# Copy certificates
scp user@core-server:/opt/stacks/core/shared-ca/ca.pem /opt/stacks/core/shared-ca/
scp user@core-server:/opt/stacks/core/shared-ca/server-cert.pem /opt/stacks/core/shared-ca/
scp user@core-server:/opt/stacks/core/shared-ca/server-key.pem /opt/stacks/core/shared-ca/

# Update Docker daemon
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "tls": true,
  "tlsverify": true,
  "tlscacert": "/opt/stacks/core/shared-ca/ca.pem",
  "tlscert": "/opt/stacks/core/shared-ca/server-cert.pem",
  "tlskey": "/opt/stacks/core/shared-ca/server-key.pem"
}
EOF

sudo systemctl restart docker
```

## 4 Step Process for Adding Services

1. Add route & service in Traefik external hosts file
2. Add middleware in Sablier config file (sablier.yml)
3. Add labels to compose files on Remote Host
4. Restart services

## Required Information
```bash
<server> - the hostname of the remote server

<service> - the application/container name

<full domain> - the base url for your proxy host (my-subdomain.duckdns.org)

<ip address> - the ip address of the remote server

<port> - the external port exposed by the service

<service display name> - how it will appear on the now loading page

<group name> - use <service name> for a single service, or something descriptive for the group of services that will start together.
  
```  
## Step 1: Add route & service in Traefik external hosts file

### In /opt/stacks/core/traefik/dynamic/external-host-server_name.yml  

```yaml
http:
    routers:
        # Add a section under routers for each Route (Proxy Host)
        <service>-<server>:
            rule: "Host(`<service>.<full domain>`)"
            entryPoints:
                - websecure
            service: <service>-<server>
            tls:
                certResolver: letsencrypt
            middlewares:
                - sablier-<server>-<service>@file
                - authelia@docker   # comment this line to disable SSO login

        # next route goes here

# All Routes go above this line
# Services section defines each service used above
services:
    <service>-<server>:
    loadBalancer:
        servers:
        - url: "http://<ip address>:<port>"
        passHostHeader: true
    
    # next service goes here
```
## Step 2: Add middlware to sablier config file

### In /opt/stacks/core/traefik/dynamic/sablier.yml  

```yaml
http:
    middlwares:
        # Add a section under middlewares for each Route (Proxy Host)
        sablier-<server>-<service>:
            plugin:
                sablier:
                sablierUrl: http://sablier-service:10000
                group: <server>-<group name>
                sessionDuration: 2m     # Increase this for convience
                ignoreUserAgent: curl   # Don't wake the service for a curl command
                dynamic:
                    displayName: <service display name>
                    theme: ghost        # This can be changed
                    show-details-by-default: true   # May want to disable for production

        # Next middleware goes here
```
## Step 3: Add labels to compose files on Remote Host

## On the Remote Server 

### Apply lables to the services in the compose files

```yaml
    labels:
      - sablier.enable=true
      - sablier.group=<server>-<group name>
      - sablier.start-on-demand=true

```

>**Note**:  
Traefik & Authelia labels are not used in the compose file for Remote Hosts

## Step 4: Restart services

### On host system

```bash
docker restart traefik
docker restart sablier-service
```

### On the Remote Host

```bash
cd /opt/stacks/<service>
docker compose down && docker compose up -d
docker stop <service>
```

## Setup Complete

Access your service by the proxy url.

---

# Deployment Plan for Multi-Server Setup

This section provides a complete deployment plan for scenarios where the core infrastructure (Traefik, Authelia, Sablier) runs on one server, and application services run on remote servers. This setup enables centralized control and routing while maintaining service isolation.

## Architecture Overview

- **Core Server**: Hosts Traefik (reverse proxy), Authelia (SSO), Sablier (lazy loading controller)
- **Remote/Media Servers**: Host application containers controlled by Sablier
- **Communication**: TLS-secured Docker API calls between servers

## Prerequisites

- Both servers must be on the same network and able to communicate
- SSH access configured between servers (key-based or password authentication supported)
- Domain configured with DuckDNS or similar
- The EZ-Homelab script handles Docker TLS certificate generation on the core server and automatic copying to remote servers
- Basic understanding of Docker concepts (optional - script guides you through setup)

## Step 1: Configure Core Server

### On Core Server Only

1. **Install Docker** (if not already installed):
   ```bash
   curl -fsSL https://get.docker.com | sh
   usermod -aG docker $USER
   systemctl enable docker
   systemctl start docker
   # Log out and back in for group changes
   ```

2. **Configure Firewall** (optional, for security):
   ```bash
   sudo ufw allow 2376/tcp  # For Docker API access from remote servers
   sudo ufw --force enable
   ```

The EZ-Homelab script will automatically generate TLS certificates and configure Docker daemon TLS when you deploy the core infrastructure.

## Step 2: Configure Remote Servers

### On Each Remote Server

1. **Install Docker** (if not already installed):
   ```bash
   curl -fsSL https://get.docker.com | sh
   usermod -aG docker $USER
   systemctl enable docker
   systemctl start docker
   # Log out and back in for group changes
   ```

2. **Configure Firewall** (optional, for security):
   ```bash
   sudo ufw allow 2376/tcp  # For Docker API access from core server
   sudo ufw --force enable
   ```

The EZ-Homelab script will automatically copy TLS certificates from the core server and configure Docker daemon TLS when you run the infrastructure-only deployment.

## Certificate and Secret Sharing

The EZ-Homelab script automatically handles certificate and secret sharing for infrastructure-only deployments:

### Automatic Process (Recommended)

1. **On Remote Server**: Run `./scripts/ez-homelab.sh` and select option 3
2. **Script Actions**:
   - Prompts for core server IP
   - Tests SSH connectivity
   - Copies shared CA and TLS certificates from core server
   - Generates server-specific certificates signed by the shared CA
   - Configures Docker daemon for TLS on port 2376

### Manual Process (Fallback)

If automatic sharing fails, manually share certificates:

1. **On Core Server**:
   ```bash
   # Generate server certificates for remote server
   cd /opt/stacks/core/shared-ca
   openssl genrsa -out server-key.pem 4096
   openssl req -subj "/CN=<REMOTE_IP>" -new -key server-key.pem -out server.csr
   echo "subjectAltName = DNS:<REMOTE_IP>,IP:<REMOTE_IP>,IP:127.0.0.1" > extfile.cnf
   openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf
   ```

2. **On Remote Server**:
   ```bash
   # Copy certificates
   scp user@core-server:/opt/stacks/core/shared-ca/ca.pem /opt/stacks/core/shared-ca/
   scp user@core-server:/opt/stacks/core/shared-ca/server-cert.pem /opt/stacks/core/shared-ca/
   scp user@core-server:/opt/stacks/core/shared-ca/server-key.pem /opt/stacks/core/shared-ca/

   # Update Docker daemon
   sudo tee /etc/docker/daemon.json > /dev/null <<EOF
   {
     "tls": true,
     "tlsverify": true,
     "tlscacert": "/opt/stacks/core/shared-ca/ca.pem",
     "tlscert": "/opt/stacks/core/shared-ca/server-cert.pem",
     "tlskey": "/opt/stacks/core/shared-ca/server-key.pem"
   }
   EOF

   sudo systemctl restart docker
   ```

## Step 3: Deploy Core Infrastructure

### On Core Server

1. **Run the EZ-Homelab script** with core deployment:
   ```bash
   cd ~/EZ-Homelab
   ./scripts/ez-homelab.sh
   # Select option 1 (Default Setup) or 2 (Core Only)
   ```

   The script will:
   - Generate Authelia secrets automatically
   - Generate shared TLS CA and certificates
   - Configure Docker daemon TLS
   - Deploy Traefik, Authelia, and Sablier
   - Set up certificates for secure communication

2. **Verify core deployment**:
   ```bash
   # Check services are running
   docker ps --filter "label=com.docker.compose.project=core"
   
   # Test Authelia access
   curl -k https://auth.<your-domain>
   ```

## Step 4: Deploy Remote Infrastructure

### On Remote/Media Server

1. **Run the EZ-Homelab script** with infrastructure-only deployment:
   ```bash
   cd ~/EZ-Homelab
   ./scripts/ez-homelab.sh
   # Select option 3 (Infrastructure Only)
   ```

   The script will automatically:
   - Prompt for core server IP address
   - Establish SSH connection to core server
   - Copy shared CA and generate server-specific certificates
   - Configure Docker daemon for TLS on port 2376
   - Set up required networks and directories

2. **Manual certificate setup** (if automatic fails):
   If SSH connection fails, follow the manual process in the Certificate and Secret Sharing section above.

## Step 5: Configure Sablier for Remote Control

### On Core Server

Sablier uses middleware configuration in Traefik's dynamic files to control remote Docker daemons. The middleware specifies the remote server connection details.

1. **Create Sablier middleware configuration**:
   `/opt/stacks/core/traefik/dynamic/sablier.yml`
   ```yaml
   http:
     middlewares:
       sablier-<remote_hostname>-<group>:
         plugin:
           sablier:
             sablierUrl: http://sablier-service:10000
             group: <remote_hostname>-<group>
             sessionDuration: 2m
             ignoreUserAgent: curl
             dynamic:
               displayName: "<Service Group Display Name>"
               theme: ghost
               show-details-by-default: true
   ```

2. **Restart Traefik** to load the middleware:
   ```bash
   docker restart traefik
   ```

## Step 6: Deploy Application Services

### On Remote Server

1. **Deploy application stacks** with Sablier labels:
   ```yaml
   # Example: /opt/stacks/media-management/docker-compose.yml
   services:
     sonarr:
       labels:
         - sablier.enable=true
         - sablier.group=<REMOTE_HOSTNAME>-media
         - sablier.start-on-demand=true
   ```

2. **Deploy and stop services** for lazy loading:
   ```bash
   cd /opt/stacks/media-management
   docker compose up -d
   docker compose stop
   ```

## Step 7: Configure Traefik Routing

### On Core Server

Since Traefik cannot auto-discover labels from remote Docker hosts, use the file provider method:

1. **Create external host configuration**:
   `/opt/stacks/core/traefik/dynamic/external-host-<remote_server>.yml`
   ```yaml
   http:
     routers:
       sonarr-remote:
         rule: "Host(`sonarr.<DOMAIN>`)"
         entrypoints:
           - websecure
         service: sonarr-remote
         tls:
           certResolver: letsencrypt
         middlewares:
           - sablier-<remote_hostname>-media@file
           - authelia@docker

     services:
       sonarr-remote:
         loadBalancer:
           servers:
             - url: "http://<REMOTE_IP>:8989"
           passHostHeader: true
   ```

2. **Restart Traefik**:
   ```bash
   docker restart traefik
   ```

## Step 8: Verification and Testing

1. **Check Sablier connection**:
   ```bash
   # On core server
   docker logs sablier-service
   # Should show groups from remote server
   ```

2. **Test lazy loading**:
   - Access `https://sonarr.<DOMAIN>`
   - Should show Sablier loading page
   - Container should start on remote server

3. **Verify Traefik routes**:
   ```bash
   curl -k https://localhost:8080/api/http/routers | jq
   ```

## Troubleshooting

- **TLS Connection Issues**: Check certificate validity and paths on both core and remote servers
- **Sablier Not Detecting Groups**: Verify middleware configuration in `/opt/stacks/core/traefik/dynamic/sablier.yml` and that remote services have correct Sablier labels
- **Traefik Routing Problems**: Check external host YAML syntax and that Traefik has reloaded configuration
- **Network Connectivity**: Ensure ports 2376 (Docker API), 80, 443 are open between servers
- **Certificate Sharing Failed**: Verify SSH access between servers and that the shared CA exists on core server

## Security Considerations

- TLS certificates expire after 365 days - monitor and renew
- Limit Docker API access to trusted networks
- Use strong firewall rules
- Regularly update all components

This setup provides centralized management with distributed execution, optimal for resource management and security.

