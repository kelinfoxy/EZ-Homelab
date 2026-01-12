# Gluetun - VPN Client Container

## Table of Contents
- [Overview](#overview)
- [What is Gluetun?](#what-is-gluetun)
- [Why Use Gluetun?](#why-use-gluetun)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Routing Traffic Through Gluetun](#routing-traffic-through-gluetun)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Core Infrastructure  
**Docker Image:** [qmcgaw/gluetun](https://hub.docker.com/r/qmcgaw/gluetun)  
**Default Stack:** `core.yml`  
**Web UI:** `http://SERVER_IP:8000` (Control Server)  
**VPN Provider:** Surfshark (or 60+ others supported)

## What is Gluetun?

Gluetun is a lightweight VPN client container that provides VPN connectivity to other Docker containers. Instead of installing VPN clients on your host or within individual containers, Gluetun acts as a VPN gateway that other containers can route their traffic through.

### Key Features
- **60+ VPN Providers:** Surfshark, NordVPN, Private Internet Access, ProtonVPN, Mullvad, etc.
- **Kill Switch:** Blocks all traffic if VPN disconnects
- **Port Forwarding:** Automatic port forwarding for supported providers
- **Network Namespace Sharing:** Other containers can use Gluetun's network
- **Health Checks:** Built-in monitoring and auto-reconnection
- **DNS Management:** Uses VPN provider's DNS for privacy
- **HTTP Control Server:** Web UI for monitoring and control
- **IPv6 Support:** Optional IPv6 routing
- **Custom Provider Support:** Can configure any OpenVPN/Wireguard provider

## Why Use Gluetun?

1. **Privacy for Torrenting:** Hide your IP when using qBittorrent
2. **Geo-Restrictions:** Access region-locked content
3. **Container-Level VPN:** Only specific services use VPN, not entire system
4. **Kill Switch Protection:** Traffic blocked if VPN fails
5. **Easy Management:** Single container for all VPN needs
6. **Provider Flexibility:** Switch between providers easily
7. **No Split Tunneling Complexity:** Docker handles networking
8. **Port Forwarding:** Essential for torrent seeding

## How It Works

```
Internet → VPN Server (Surfshark) → Gluetun Container
                                         ↓
                                    Shared Network
                                         ↓
                            ┌────────────┴────────────┐
                            ↓                         ↓
                      qBittorrent                 Prowlarr
                  (network: gluetun)          (network: gluetun)
```

### Network Namespace Sharing

Containers can use Gluetun's network stack:

```yaml
qbittorrent:
  image: linuxserver/qbittorrent
  network_mode: "service:gluetun"  # Use Gluetun's network
  # This container now routes ALL traffic through VPN
```

### Traffic Flow

1. **Container makes request** (e.g., qBittorrent downloads torrent)
2. **Traffic routed** to Gluetun container
3. **Gluetun encrypts** traffic and sends through VPN tunnel
4. **VPN server receives** encrypted traffic
5. **VPN server forwards** request to internet
6. **Response flows back** through same path
7. **If VPN fails,** kill switch blocks all traffic

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/core/gluetun/
└── (No persistent config needed - all via environment variables)
```

### Environment Variables

```bash
# VPN Provider
VPN_SERVICE_PROVIDER=surfshark
VPN_TYPE=openvpn  # or wireguard

# Surfshark Credentials
OPENVPN_USER=your-surfshark-username
OPENVPN_PASSWORD=your-surfshark-password

# Server Selection
SERVER_COUNTRIES=USA  # or SERVER_CITIES=New York
# SERVER_REGIONS=us-east

# Features
FIREWALL_OUTBOUND_SUBNETS=192.168.1.0/24  # Allow local network
PORT_FORWARD=on  # Enable port forwarding (if supported)
DOT=on  # DNS over TLS

# Health Check
HEALTH_VPN_DURATION_INITIAL=30s
HEALTH_SUCCESS_WAIT_DURATION=5m
```

### Surfshark Setup

1. **Get Surfshark Account:**
   - Sign up at https://surfshark.com
   - Go to Manual Setup → OpenVPN/Wireguard
   - Copy service credentials (NOT your login credentials)

2. **Generate Service Credentials:**
   ```
   Dashboard → Manual Setup → Credentials
   Username: random-string
   Password: random-string
   ```

3. **Configure Gluetun:**
   ```bash
   OPENVPN_USER=your-service-username
   OPENVPN_PASSWORD=your-service-password
   ```

### Server Selection Options

```bash
# By Country
SERVER_COUNTRIES=USA,Canada

# By City
SERVER_CITIES=New York,Los Angeles

# By Region (provider-specific)
SERVER_REGIONS=us-east

# By Hostname (specific server)
SERVER_HOSTNAMES=us-nyc-st001

# Random selection within criteria
# Gluetun will pick best server automatically
```

## Official Resources

- **GitHub:** https://github.com/qdm12/gluetun
- **Docker Hub:** https://hub.docker.com/r/qmcgaw/gluetun
- **Wiki:** https://github.com/qdm12/gluetun-wiki
- **Provider Setup:** https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers
- **Surfshark Setup:** https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/surfshark.md

## Educational Resources

### Videos
- [VPN Explained - What is a VPN? (NetworkChuck)](https://www.youtube.com/watch?v=YEe8vs26ytg)
- [Docker VPN Setup with Gluetun (Techno Tim)](https://www.youtube.com/watch?v=fpkLvnAKen0)
- [Secure Your Docker Containers with VPN](https://www.youtube.com/results?search_query=gluetun+docker+vpn)
- [Port Forwarding for Torrents Explained](https://www.youtube.com/watch?v=jTThdKLHbq8)

### Articles & Guides
- [Gluetun Wiki - Getting Started](https://github.com/qdm12/gluetun-wiki)
- [VPN Kill Switch Explained](https://www.comparitech.com/blog/vpn-privacy/vpn-kill-switch/)
- [Why Use VPN for Torrenting](https://www.cloudwards.net/vpn-for-torrenting/)
- [Network Namespace Sharing in Docker](https://docs.docker.com/network/)

### Concepts to Learn
- **VPN (Virtual Private Network):** Encrypted tunnel for internet traffic
- **Kill Switch:** Blocks traffic if VPN disconnects
- **Port Forwarding:** Allows incoming connections (important for seeding)
- **DNS Leak:** When DNS queries bypass VPN (Gluetun prevents this)
- **Split Tunneling:** Some apps use VPN, others don't (Docker makes this easy)
- **OpenVPN vs Wireguard:** Two VPN protocols (Wireguard is newer, faster)
- **Network Namespace:** Container network isolation/sharing

## Docker Configuration

### Complete Service Definition

```yaml
gluetun:
  image: qmcgaw/gluetun:latest
  container_name: gluetun
  restart: unless-stopped
  cap_add:
    - NET_ADMIN  # Required for VPN
  devices:
    - /dev/net/tun:/dev/net/tun  # Required for VPN
  networks:
    - traefik-network
  ports:
    # Gluetun Control Server
    - "8000:8000"
    
    # Ports for services using Gluetun's network
    - "8080:8080"   # qBittorrent Web UI
    - "9696:9696"   # Prowlarr Web UI (if through VPN)
    # Add more as needed
  
  volumes:
    - /opt/stacks/core/gluetun:/gluetun
  
  environment:
    - VPN_SERVICE_PROVIDER=surfshark
    - VPN_TYPE=openvpn
    - OPENVPN_USER=${SURFSHARK_USER}
    - OPENVPN_PASSWORD=${SURFSHARK_PASSWORD}
    - SERVER_COUNTRIES=USA
    - FIREWALL_OUTBOUND_SUBNETS=192.168.1.0/24
    - PORT_FORWARD=on
    - DOT=on
    - TZ=America/New_York
  
  # Health check
  healthcheck:
    test: ["CMD", "wget", "--spider", "-q", "https://api.ipify.org"]
    interval: 1m
    timeout: 10s
    retries: 3
    start_period: 30s
```

### Alternative: Wireguard

```yaml
environment:
  - VPN_SERVICE_PROVIDER=surfshark
  - VPN_TYPE=wireguard
  - WIREGUARD_PRIVATE_KEY=${SURFSHARK_WG_PRIVATE_KEY}
  - WIREGUARD_ADDRESSES=10.14.0.2/16
  - SERVER_COUNTRIES=USA
```

## Routing Traffic Through Gluetun

### Method 1: Network Mode (Recommended)

```yaml
qbittorrent:
  image: linuxserver/qbittorrent
  container_name: qbittorrent
  network_mode: "service:gluetun"  # Use Gluetun's network
  depends_on:
    - gluetun
  volumes:
    - /opt/stacks/media/qbittorrent:/config
    - /mnt/downloads:/downloads
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - WEBUI_PORT=8080
  # NO ports section - use Gluetun's ports
  # NO networks section - uses Gluetun's network
```

**Important:** When using `network_mode: "service:gluetun"`:
- Don't define `ports:` on the service
- Don't define `networks:` on the service
- Add ports to **Gluetun's** ports section
- Access WebUI through Gluetun's IP

### Method 2: Custom Network (Advanced)

```yaml
services:
  gluetun:
    # ... gluetun config ...
    networks:
      vpn-network:
        ipv4_address: 172.20.0.2
  
  qbittorrent:
    # ... qbittorrent config ...
    networks:
      vpn-network:
    depends_on:
      - gluetun

networks:
  vpn-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Exposing Services Through Traefik

When using `network_mode: "service:gluetun"`, Traefik labels go on **Gluetun**:

```yaml
gluetun:
  image: qmcgaw/gluetun
  # ... other config ...
  labels:
    # qBittorrent labels on Gluetun
    - "traefik.enable=true"
    - "traefik.http.routers.qbittorrent.rule=Host(`qbit.${DOMAIN}`)"
    - "traefik.http.routers.qbittorrent.entrypoints=websecure"
    - "traefik.http.routers.qbittorrent.tls.certresolver=letsencrypt"
    - "traefik.http.routers.qbittorrent.middlewares=authelia@docker"
    - "traefik.http.services.qbittorrent.loadbalancer.server.port=8080"

qbittorrent:
  image: linuxserver/qbittorrent
  network_mode: "service:gluetun"
  # NO labels here
```

## Advanced Topics

### Port Forwarding

Essential for torrent seeding. Supported providers:
- Private Internet Access (PIA)
- ProtonVPN
- Perfect Privacy
- AirVPN

**Configuration:**
```bash
PORT_FORWARD=on
PORT_FORWARD_ONLY=true  # Only use servers with port forwarding
```

**Get forwarded port:**
```bash
# Check Gluetun logs
docker logs gluetun | grep "port forwarded"

# Or via control server
curl http://localhost:8000/v1/openvpn/portforwarded
```

**Use in qBittorrent:**
1. Get port from Gluetun logs: `Port forwarded is 12345`
2. In qBittorrent Settings → Connection → Listening Port → Set to `12345`

### Multiple VPN Connections

Run multiple Gluetun instances for different regions:

```yaml
gluetun-usa:
  image: qmcgaw/gluetun
  container_name: gluetun-usa
  environment:
    - SERVER_COUNTRIES=USA
  # ... rest of config ...

gluetun-uk:
  image: qmcgaw/gluetun
  container_name: gluetun-uk
  environment:
    - SERVER_COUNTRIES=United Kingdom
  # ... rest of config ...
```

### Custom VPN Provider

For providers not natively supported:

```yaml
environment:
  - VPN_SERVICE_PROVIDER=custom
  - VPN_TYPE=openvpn
  - OPENVPN_CUSTOM_CONFIG=/gluetun/custom.conf

volumes:
  - ./custom.ovpn:/gluetun/custom.conf:ro
```

### DNS Configuration

```bash
# Use VPN provider DNS (default)
DOT=on  # DNS over TLS

# Use custom DNS
DNS_ADDRESS=1.1.1.1  # Cloudflare

# Multiple DNS servers
DNS_ADDRESS=1.1.1.1,8.8.8.8
```

### Firewall Rules

```bash
# Allow local network access
FIREWALL_OUTBOUND_SUBNETS=192.168.1.0/24,172.16.0.0/12

# Block all except VPN
FIREWALL_VPN_INPUT_PORTS=  # No incoming connections

# Allow specific outbound ports
FIREWALL_OUTBOUND_PORTS=80,443,53
```

## Troubleshooting

### Check VPN Connection

```bash
# View Gluetun logs
docker logs gluetun

# Check public IP (should show VPN IP)
docker exec gluetun wget -qO- https://api.ipify.org

# Check if VPN is connected
docker exec gluetun cat /tmp/gluetun/ip
```

### Service Can't Access Internet

```bash
# Check if service is using Gluetun's network
docker inspect service-name | grep NetworkMode

# Test from within service
docker exec service-name curl https://api.ipify.org

# Check firewall rules
docker logs gluetun | grep -i firewall

# Verify outbound subnets
# Ensure FIREWALL_OUTBOUND_SUBNETS includes your local network
```

### VPN Keeps Disconnecting

```bash
# Check provider status
# Visit your VPN provider's status page

# Try different server
SERVER_COUNTRIES=Canada  # Change country

# Try Wireguard instead of OpenVPN
VPN_TYPE=wireguard

# Check system resources
docker stats gluetun

# View connection logs
docker logs gluetun | grep -i "connection\|disconnect"
```

### Port Forwarding Not Working

```bash
# Check if provider supports it
# Only certain providers support port forwarding

# Verify it's enabled
docker logs gluetun | grep -i "port forward"

# Get forwarded port
curl http://localhost:8000/v1/openvpn/portforwarded

# Check if server supports it
PORT_FORWARD_ONLY=true  # Force port-forward-capable servers
```

### DNS Leaks

```bash
# Test DNS
docker exec gluetun nslookup google.com

# Check DNS configuration
docker exec gluetun cat /etc/resolv.conf

# Enable DNS over TLS
DOT=on
```

### Can't Access Service WebUI

```bash
# If using network_mode: "service:gluetun"
# Access via: http://GLUETUN_IP:PORT

# Check Gluetun's IP
docker inspect gluetun | grep IPAddress

# Verify ports are exposed on Gluetun
docker ps | grep gluetun

# Check if service is running
docker ps | grep service-name
```

### Kill Switch Testing

```bash
# Stop VPN (simulate disconnection)
docker exec gluetun killall openvpn

# Try accessing internet from connected service
docker exec qbittorrent curl https://api.ipify.org
# Should fail or timeout

# Restart VPN
docker restart gluetun
```

## Security Best Practices

1. **Use Strong Credentials:** Never share your VPN credentials
2. **Enable Kill Switch:** Always use Gluetun's built-in kill switch
3. **DNS over TLS:** Enable `DOT=on` to prevent DNS leaks
4. **Firewall Rules:** Restrict outbound traffic to necessary subnets only
5. **Regular Updates:** Keep Gluetun updated for security patches
6. **Provider Selection:** Use reputable VPN providers (no-logs policy)
7. **Monitor Logs:** Regularly check for connection issues
8. **Test IP Leaks:** Verify your IP is hidden: https://ipleak.net
9. **Port Security:** Only forward ports when necessary
10. **Split Tunneling:** Only route traffic that needs VPN through Gluetun

## Provider Comparisons

### Surfshark
- **Pros:** Unlimited devices, fast, affordable
- **Cons:** No port forwarding
- **Best for:** General privacy, torrenting (without seeding priority)

### Private Internet Access (PIA)
- **Pros:** Port forwarding, proven no-logs
- **Cons:** US-based
- **Best for:** Torrenting with seeding

### Mullvad
- **Pros:** Anonymous (no email required), port forwarding
- **Cons:** More expensive
- **Best for:** Maximum privacy

### ProtonVPN
- **Pros:** Port forwarding, excellent privacy
- **Cons:** Expensive for full features
- **Best for:** Privacy-focused users

### NordVPN
- **Pros:** Fast, large server network
- **Cons:** No port forwarding
- **Best for:** General use, streaming

## Summary

Gluetun is essential for:
- Protecting torrent traffic (qBittorrent, Transmission)
- Bypassing geo-restrictions
- Hiding your IP from specific services
- Maintaining privacy for indexers (Prowlarr, Jackett)
- Professional homelab security

By routing only specific containers through the VPN, you maintain:
- Fast local network access for other services
- Privacy where it matters
- Simple, maintainable configuration
- Automatic failover protection

Remember: Always verify your VPN is working correctly by checking your public IP from containers using Gluetun's network. The IP should match your VPN provider's IP, not your home IP.
