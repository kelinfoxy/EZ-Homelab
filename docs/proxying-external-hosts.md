# Proxying External Hosts with Traefik and Authelia

This guide explains how to use Traefik and Authelia to proxy external services (like a Raspberry Pi running Home Assistant) through your domain with HTTPS and optional SSO protection.

## Overview

Traefik can proxy services that aren't running in Docker, such as:
Yea- Home Assistant on a Raspberry Pi
- Other physical servers on your network
- Services running on different machines
- Any HTTP/HTTPS service accessible via IP:PORT

## Quick Start

### Step 1: Create Configuration File

Create a YAML file in `/opt/stacks/traefik/dynamic/` named `external-host-servername.yml` where servername is the remove server's host name:

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

Traefik automatically detects and loads new configuration files:

```bash
# Verify configuration is loaded
docker logs traefik | grep homeassistant

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
``
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

## AI Management

The AI can manage external host proxying by:

1. **Reading existing configurations**: Parse `/opt/stacks/traefik/dynamic/*.yml`
2. **Adding new routes**: Create/update YAML files in dynamic directory
3. **Configuring Authelia rules**: Edit `configuration.yml` for bypass/require auth
4. **Adding Homepage entries**: Update dashboard configuration

Example AI prompt:
> "Add proxying for my Unifi Controller at 192.168.1.5:8443 with Authelia protection"

AI will:
1. Create route configuration file
2. Add HTTPS backend support (Unifi uses HTTPS)
3. Configure Authelia middleware
4. Add to Homepage dashboard
5. Provide testing instructions

## Example: Complete External Host Setup

Let's proxy a Raspberry Pi Home Assistant:

1. **Traefik configuration** (`/opt/stacks/traefik/dynamic/extarnal-host-homeassistant.yml`):
```yaml
http:
  routers:
    ha-pi:
      rule: "Host(`homeassistant.yourdomain.duckdns.org`)"
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
    - domain: homeassistant.yourdomain.duckdns.org
      policy: bypass
```

3. **Homepage entry** (in `/opt/stacks/homepage/config/services.yaml`):
```yaml
- Home Automation:
    - Home Assistant (Pi):
        icon: home-assistant.png
        href: https://homeassistant.yourdomain.duckdns.org
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
