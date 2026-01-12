# Proxying External Hosts with Traefik and Authelia

This guide explains how to use Traefik and Authelia to proxy external services (like a Raspberry Pi running Home Assistant) through your domain with HTTPS and optional SSO protection.

## Overview

Traefik can proxy services that aren't running in Docker, such as:
- Home Assistant on a Raspberry Pi
- Other physical servers on your network
- Services running on different machines
- Any HTTP/HTTPS service accessible via IP:PORT

## Method 1: Using Traefik File Provider (Recommended)

### Step 1: Create External Service Configuration

Create a file in `/opt/stacks/traefik/dynamic/external-hosts.yml`:

```yaml
http:
  routers:
    # Home Assistant on Raspberry Pi
    homeassistant-external:
      rule: "Host(`ha.yourdomain.duckdns.org`)"
      entryPoints:
        - websecure
      service: homeassistant-external
      tls:
        certResolver: letsencrypt
      # Uncomment to add Authelia protection:
      # middlewares:
      #   - authelia@docker

  services:
    homeassistant-external:
      loadBalancer:
        servers:
          - url: "http://192.168.1.50:8123"  # Replace with your Pi's IP and port
        passHostHeader: true

  middlewares:
    # Optional: Add headers for WebSocket support
    homeassistant-headers:
      headers:
        customRequestHeaders:
          X-Forwarded-Proto: "https"
        customResponseHeaders:
          X-Frame-Options: "SAMEORIGIN"
```

### Step 2: Reload Traefik

Traefik watches the `/opt/stacks/traefik/dynamic/` directory automatically and reloads configurations:

```bash
# Verify configuration is loaded
docker logs traefik | grep external-hosts

# If needed, restart Traefik
cd /opt/stacks/traefik
docker compose restart
```

### Step 3: Test Access

Visit `https://ha.yourdomain.duckdns.org` - Traefik will:
1. Accept the HTTPS connection
2. Proxy the request to `http://192.168.1.50:8123`
3. Return the response with proper SSL
4. (Optionally) Require Authelia login if middleware is configured

## Method 2: Using Docker Labels (Dummy Container)

If you prefer managing routes via Docker labels (so the AI can modify them), create a dummy container:

### Create a Label Container

In `/opt/stacks/external-proxies/docker-compose.yml`:

```yaml
services:
  # Dummy container for Raspberry Pi Home Assistant
  homeassistant-proxy-labels:
    image: alpine:latest
    container_name: homeassistant-proxy-labels
    command: tail -f /dev/null  # Keep container running
    restart: unless-stopped
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.ha-external.rule=Host(`ha.${DOMAIN}`)"
      - "traefik.http.routers.ha-external.entrypoints=websecure"
      - "traefik.http.routers.ha-external.tls.certresolver=letsencrypt"
      # Point to external service
      - "traefik.http.services.ha-external.loadbalancer.server.url=http://192.168.1.50:8123"
      # Optional: Add Authelia (usually not for HA)
      # - "traefik.http.routers.ha-external.middlewares=authelia@docker"

networks:
  traefik-network:
    external: true
```

Deploy:
```bash
cd /opt/stacks/external-proxies
docker compose up -d
```

## Method 3: Hybrid Approach (File + Docker Discovery)

Combine both methods for maximum flexibility:
- Use file provider for static external hosts
- Use Docker labels for frequently changing services
- AI can manage both!

## Common External Services to Proxy

### Home Assistant (Raspberry Pi)
```yaml
homeassistant-pi:
  rule: "Host(`ha.yourdomain.duckdns.org`)"
  service: http://192.168.1.50:8123
  # No Authelia - HA has its own auth
```

### Router/Firewall Admin Panel
```yaml
router-admin:
  rule: "Host(`router.yourdomain.duckdns.org`)"
  service: http://192.168.1.1:80
  middlewares:
    - authelia@docker  # Add SSO protection
```

### Proxmox Server
```yaml
proxmox:
  rule: "Host(`proxmox.yourdomain.duckdns.org`)"
  service: https://192.168.1.100:8006
  middlewares:
    - authelia@docker
  # Note: Use https:// if backend uses HTTPS
```

### TrueNAS/FreeNAS
```yaml
truenas:
  rule: "Host(`nas.yourdomain.duckdns.org`)"
  service: http://192.168.1.200:80
  middlewares:
    - authelia@docker
```

### Security Camera NVR
```yaml
nvr:
  rule: "Host(`cameras.yourdomain.duckdns.org`)"
  service: http://192.168.1.10:80
  middlewares:
    - authelia@docker  # Definitely protect cameras!
```

## Advanced Configuration

### WebSocket Support

Some services (like Home Assistant) need WebSocket support:

```yaml
http:
  middlewares:
    websocket-headers:
      headers:
        customRequestHeaders:
          X-Forwarded-Proto: "https"
          Connection: "upgrade"
          Upgrade: "websocket"

  routers:
    homeassistant-external:
      middlewares:
        - websocket-headers
```

### HTTPS Backend

If your external service already uses HTTPS:

```yaml
http:
  services:
    https-backend:
      loadBalancer:
        servers:
          - url: "https://192.168.1.50:8123"
        serversTransport: insecureTransport

  serversTransports:
    insecureTransport:
      insecureSkipVerify: true  # Only if using self-signed cert
```

### IP Whitelist

Restrict access to specific IPs:

```yaml
http:
  middlewares:
    local-only:
      ipWhiteList:
        sourceRange:
          - "192.168.1.0/24"
          - "10.0.0.0/8"

  routers:
    sensitive-service:
      middlewares:
        - local-only
        - authelia@docker
```

## Authelia Bypass Rules

Configure Authelia to bypass authentication for specific external hosts.

Edit `/opt/stacks/authelia/configuration.yml`:

```yaml
access_control:
  rules:
    # Bypass for Home Assistant (app access)
    - domain: ha.yourdomain.duckdns.org
      policy: bypass
    
    # Require auth for router admin
    - domain: router.yourdomain.duckdns.org
      policy: one_factor
    
    # Two-factor for critical services
    - domain: proxmox.yourdomain.duckdns.org
      policy: two_factor
```

## DNS Configuration

Ensure your DuckDNS domain points to your public IP:

1. DuckDNS container automatically updates your IP
2. Port forward 80 and 443 to your Traefik server
3. All subdomains (`*.yourdomain.duckdns.org`) point to same IP
4. Traefik routes based on Host header

## Troubleshooting

### Check Traefik Routing
```bash
# View active routes
docker logs traefik | grep "Creating router"

# Check if external host route is loaded
docker logs traefik | grep homeassistant

# View Traefik dashboard
# Visit: https://traefik.yourdomain.duckdns.org
```

### Test Without SSL
```bash
# Temporarily test direct connection
curl -H "Host: ha.yourdomain.duckdns.org" http://localhost/
```

### Check Authelia Logs
```bash
cd /opt/stacks/authelia
docker compose logs -f authelia
```

### Verify External Service
```bash
# Test that external service is reachable
curl http://192.168.1.50:8123
```

## AI Management

The AI can manage external host proxying by:

1. **Reading existing configurations**: Parse `/opt/stacks/traefik/dynamic/*.yml`
2. **Adding new routes**: Create/update YAML files in dynamic directory
3. **Modifying Docker labels**: Update dummy container labels
4. **Configuring Authelia rules**: Edit `configuration.yml` for bypass/require auth
5. **Testing connectivity**: Suggest verification steps

Example AI prompt:
> "Add proxying for my Unifi Controller at 192.168.1.5:8443 with Authelia protection"

AI will:
1. Create route configuration file
2. Add HTTPS backend support (Unifi uses HTTPS)
3. Configure Authelia middleware
4. Add to Homepage dashboard
5. Provide testing instructions

## Security Best Practices

1. **Always use Authelia** for admin interfaces (routers, NAS, etc.)
2. **Bypass Authelia** only for services with their own auth (HA, Plex)
3. **Use IP whitelist** for highly sensitive services
4. **Enable two-factor** for critical infrastructure
5. **Monitor access logs** in Traefik and Authelia
6. **Keep services updated** - Traefik, Authelia, and external services

## Example: Complete External Host Setup

Let's proxy a Raspberry Pi Home Assistant:

1. **Traefik configuration** (`/opt/stacks/traefik/dynamic/raspberry-pi.yml`):
```yaml
http:
  routers:
    ha-pi:
      rule: "Host(`ha.yourdomain.duckdns.org`)"
      entryPoints:
        - websecure
      service: ha-pi
      tls:
        certResolver: letsencrypt
      middlewares:
        - ha-headers

  services:
    ha-pi:
      loadBalancer:
        servers:
          - url: "http://192.168.1.50:8123"

  middlewares:
    ha-headers:
      headers:
        customRequestHeaders:
          X-Forwarded-Proto: "https"
```

2. **Authelia bypass** (in `/opt/stacks/authelia/configuration.yml`):
```yaml
access_control:
  rules:
    - domain: ha.yourdomain.duckdns.org
      policy: bypass
```

3. **Homepage entry** (in `/opt/stacks/homepage/config/services.yaml`):
```yaml
- Home Automation:
    - Home Assistant (Pi):
        icon: home-assistant.png
        href: https://ha.yourdomain.duckdns.org
        description: HA on Raspberry Pi
        ping: 192.168.1.50
        widget:
          type: homeassistant
          url: http://192.168.1.50:8123
          key: your-long-lived-token
```

4. **Test**:
```bash
# Reload Traefik (automatic, but verify)
docker logs traefik | grep ha-pi

# Visit
https://ha.yourdomain.duckdns.org
```

Done! Your Raspberry Pi Home Assistant is now accessible via your domain with HTTPS. 🎉
