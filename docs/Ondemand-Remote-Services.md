# On Demand Remote Services with Authelia, Sablier & Traefik

## 4 Step Process
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
- SSH access configured between servers (passwordless recommended for automation)
- Domain configured with DuckDNS or similar
- The EZ-Homelab script handles most Docker TLS and certificate setup automatically
- Basic understanding of Docker concepts (optional - script guides you through setup)

## Step 1: Configure Docker TLS on All Servers

### On Each Server (Core and Remote)

1. **Install Docker** (if not already installed):
   ```bash
   curl -fsSL https://get.docker.com | sh
   usermod -aG docker $USER
   systemctl enable docker
   systemctl start docker
   # Log out and back in for group changes
   ```

2. **Generate TLS Certificates**:
   ```bash
   mkdir -p ~/EZ-Homelab/docker-tls
   cd ~/EZ-Homelab/docker-tls

   # Generate CA
   openssl genrsa -out ca-key.pem 4096
   openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem -subj "/C=US/ST=State/L=City/O=Organization/CN=Docker-CA"

   # Generate server key and cert (replace SERVER_IP with actual IP)
   openssl genrsa -out server-key.pem 4096
   openssl req -subj "/CN=<SERVER_IP>" -new -key server-key.pem -out server.csr
   echo "subjectAltName = DNS:<SERVER_IP>,IP:<SERVER_IP>,IP:127.0.0.1" > extfile.cnf
   openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf

   # Generate client key and cert
   openssl genrsa -out client-key.pem 4096
   openssl req -subj "/CN=client" -new -key client-key.pem -out client.csr
   openssl x509 -req -days 365 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem
   ```

3. **Configure Docker Daemon**:
   Create `/etc/docker/daemon.json`:
   ```json
   {
     "tls": true,
     "tlsverify": true,
     "tlscacert": "/home/$USER/EZ-Homelab/docker-tls/ca.pem",
     "tlscert": "/home/$USER/EZ-Homelab/docker-tls/server-cert.pem",
     "tlskey": "/home/$USER/EZ-Homelab/docker-tls/server-key.pem"
   }
   ```

4. **Update Systemd Service**:
   ```bash
   sudo sed -i 's|-H fd://|-H fd:// -H tcp://0.0.0.0:2376|' /lib/systemd/system/docker.service
   sudo systemctl daemon-reload
   sudo systemctl restart docker
   ```

5. **Configure Firewall**:
   ```bash
   sudo ufw allow 2376/tcp
   sudo ufw --force enable
   ```

## Certificate and Secret Sharing

The EZ-Homelab script automatically handles certificate and secret sharing for infrastructure-only deployments:

### Automatic Process (Recommended)

1. **On Remote Server**: Run `./scripts/ez-homelab.sh` and select option 3
2. **Script Actions**:
   - Prompts for core server IP
   - Tests SSH connectivity
   - Copies Docker TLS certificates for remote control
   - Sets up certificates in the correct location

### Manual Process (Fallback)

If automatic sharing fails, manually share certificates:

1. **On Core Server**:
   ```bash
   # Copy client certificates to remote server
   scp /opt/stacks/core/docker-tls/ca.pem /opt/stacks/core/docker-tls/client-cert.pem /opt/stacks/core/docker-tls/client-key.pem user@remote-server:/opt/stacks/infrastructure/docker-tls/
   ```

2. **On Remote Server**:
   ```bash
   # Ensure certificates are in the correct location
   ls -la /opt/stacks/infrastructure/docker-tls/
   # Should contain: ca.pem, client-cert.pem, client-key.pem
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
   - Configure TLS for Docker API
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
   - Copy Authelia secrets and TLS certificates
   - Configure Docker TLS for remote control
   - Set up required networks and directories

2. **Manual certificate sharing** (if automatic fails):
   If SSH connection fails, manually copy certificates:
   ```bash
   # On core server, copy certs to remote server
   scp /opt/stacks/core/docker-tls/ca.pem /opt/stacks/core/docker-tls/client-cert.pem /opt/stacks/core/docker-tls/client-key.pem user@remote-server:/opt/stacks/infrastructure/docker-tls/
   
   # On remote server, copy Authelia secrets
   scp /home/kelin/EZ-Homelab/.env user@remote-server:/home/kelin/EZ-Homelab/.env.core
   ```

## Step 5: Configure Sablier for Remote Control

### On Core Server

Update Sablier configuration to control remote servers:

1. **Edit core docker-compose.yml**:
   ```yaml
   sablier-service:
     environment:
       - DOCKER_HOST=tcp://<REMOTE_SERVER_IP>:2376
       - DOCKER_TLS_VERIFY=1
       - DOCKER_CERT_PATH=/certs
     volumes:
       - ./docker-tls/ca.pem:/certs/ca.pem:ro
       - ./docker-tls/client-cert.pem:/certs/cert.pem:ro
       - ./docker-tls/client-key.pem:/certs/key.pem:ro
   ```

2. **Restart core stack**:
   ```bash
   cd /opt/stacks/core
   docker compose down
   docker compose up -d
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

## Step 5: Configure Traefik Routing

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
           - sablier-<remote_hostname>-arr@file
           - authelia@docker

     services:
       sonarr-remote:
         loadBalancer:
           servers:
             - url: "http://<REMOTE_IP>:8989"
           passHostHeader: true
   ```

2. **Create Sablier middleware configuration**:
   `/opt/stacks/core/traefik/dynamic/sablier.yml`
   ```yaml
   http:
     middlewares:
       sablier-<remote_hostname>-arr:
         plugin:
           sablier:
             sablierUrl: http://sablier-service:10000
             group: <remote_hostname>-arr
             sessionDuration: 2m
             ignoreUserAgent: curl
             dynamic:
               displayName: "Media Management Services"
               theme: ghost
               show-details-by-default: true
   ```

3. **Restart Traefik**:
   ```bash
   docker restart traefik
   ```

## Step 6: Verification and Testing

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

- **TLS Connection Issues**: Check certificate validity and paths
- **Sablier Not Detecting Groups**: Verify DOCKER_HOST and certificates
- **Traefik Routing Problems**: Check external host YAML syntax
- **Network Connectivity**: Ensure ports 2376, 80, 443 are open between servers

## Security Considerations

- TLS certificates expire after 365 days - monitor and renew
- Limit Docker API access to trusted networks
- Use strong firewall rules
- Regularly update all components

This setup provides centralized management with distributed execution, optimal for resource management and security.

