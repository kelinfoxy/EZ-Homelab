# DuckDNS - Dynamic DNS Service

## Table of Contents
- [Overview](#overview)
- [What is DuckDNS?](#what-is-duckdns)
- [Why Use DuckDNS?](#why-use-duckdns)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Core Infrastructure  
**Docker Image:** [linuxserver/duckdns](https://hub.docker.com/r/linuxserver/duckdns)  
**Default Stack:** `core` (deployed on core server only)  
**Web UI:** No web interface (runs silently)  
**Authentication:** Not applicable

**Multi-Server Note:** DuckDNS runs only on the core server where Traefik generates the wildcard SSL certificate. This single certificate is used for all services across all servers in your homelab.

## What is DuckDNS?

DuckDNS is a free dynamic DNS (DDNS) service that provides you with a memorable subdomain under `duckdns.org` and keeps it updated with your current IP address. It's perfect for homelabs where your ISP provides a dynamic IP address that changes periodically.

### Key Features
- **Free subdomain** under duckdns.org
- **Automatic IP updates** every 5 minutes
- **No account required** - simple token-based authentication
- **IPv4 and IPv6 support**
- **No ads or tracking**
- **Works with Let's Encrypt** for SSL certificates

## Why Use DuckDNS?

1. **Access Your Homelab Remotely:** Use a memorable domain name instead of remembering IP addresses
2. **SSL Certificates:** Required for Let's Encrypt to issue SSL certificates for your domain
3. **Dynamic IP Handling:** Automatically updates when your ISP changes your IP
4. **Free and Simple:** No credit card, no complex setup
5. **Homelab Standard:** One of the most popular DDNS services in the homelab community

## How It Works

```
Your Home Network → Router (Dynamic IP) → Internet
                         ↓
                    DuckDNS Updates
                         ↓
                yourdomain.duckdns.org → Current IP
```

1. You create a subdomain at DuckDNS.org (e.g., `myhomelab.duckdns.org`)
2. DuckDNS gives you a token
3. The Docker container periodically sends updates to DuckDNS with your current public IP
4. When someone visits `myhomelab.duckdns.org`, they're directed to your current IP
5. Traefik uses this domain to request SSL certificates from Let's Encrypt

## Configuration in AI-Homelab

### Environment Variables

```bash
DOMAIN=yourdomain.duckdns.org
DUCKDNS_TOKEN=your-token-from-duckdns
DUCKDNS_SUBDOMAINS=yourdomain  # Without .duckdns.org
```

### Setup Steps

1. **Sign up at DuckDNS.org:**
   - Visit https://www.duckdns.org
   - Sign in with GitHub, Google, Reddit, or Twitter
   - No registration form needed

2. **Create your subdomain:**
   - Enter desired name (e.g., `myhomelab`)
   - Click "Add domain"
   - Copy your token (shown at top of page)

3. **Configure in `.env` file:**
   ```bash
   DOMAIN=myhomelab.duckdns.org
   DUCKDNS_TOKEN=paste-your-token-here
   DUCKDNS_SUBDOMAINS=myhomelab
   ```

4. **Deploy with core stack:**
   ```bash
   cd /opt/stacks/core
   docker compose up -d duckdns
   ```

### Verification

Check if DuckDNS is updating correctly:

```bash
# Check container logs
docker logs duckdns

# Verify your domain resolves
nslookup yourdomain.duckdns.org

# Check current IP
curl https://www.duckdns.org/update?domains=yourdomain&token=your-token&verbose=true
```

## Official Resources

- **Website:** https://www.duckdns.org
- **Install Page:** https://www.duckdns.org/install.jsp
- **FAQ:** https://www.duckdns.org/faqs.jsp
- **Docker Hub:** https://hub.docker.com/r/linuxserver/duckdns
- **LinuxServer.io Docs:** https://docs.linuxserver.io/images/docker-duckdns

## Educational Resources

### Videos
- [What is Dynamic DNS? (NetworkChuck)](https://www.youtube.com/watch?v=GRvFQfgvhag) - Great overview of DDNS concepts
- [DuckDNS Setup Tutorial (Techno Tim)](https://www.youtube.com/watch?v=AS1I7tGp2c8) - Practical setup guide
- [Home Lab Beginners Guide - DuckDNS](https://www.youtube.com/results?search_query=duckdns+homelab+tutorial)

### Articles & Guides
- [DuckDNS Official Documentation](https://www.duckdns.org/spec.jsp)
- [Self-Hosting Guide: Dynamic DNS](https://github.com/awesome-selfhosted/awesome-selfhosted#dynamic-dns)
- [LinuxServer.io DuckDNS Documentation](https://docs.linuxserver.io/images/docker-duckdns)

### Related Concepts
- **Dynamic DNS (DDNS):** A service that maps a domain name to a changing IP address
- **Public IP vs Private IP:** Your router's public-facing IP vs internal network IPs
- **DNS Propagation:** Time it takes for DNS changes to spread across the internet
- **A Record:** DNS record type that maps domain to IPv4 address
- **AAAA Record:** DNS record type that maps domain to IPv6 address

## Docker Configuration

### Container Details

```yaml
duckdns:
  image: lscr.io/linuxserver/duckdns:latest
  container_name: duckdns
  restart: unless-stopped
  environment:
    - PUID=${PUID:-1000}
    - PGID=${PGID:-1000}
    - TZ=${TZ}
    - SUBDOMAINS=${DUCKDNS_SUBDOMAINS}
    - TOKEN=${DUCKDNS_TOKEN}
    - UPDATE_IP=ipv4
  volumes:
    - /opt/stacks/core/duckdns:/config
```

### Update Frequency

The DuckDNS container updates your IP every 5 minutes by default. This is frequent enough for most use cases.

### Resource Usage

- **CPU:** Minimal (~0.1%)
- **RAM:** ~10MB
- **Disk:** Negligible
- **Network:** Tiny API calls every 5 minutes

## Troubleshooting

### Domain Not Resolving

```bash
# Check if DuckDNS is updating
docker logs duckdns

# Manually check current status
curl "https://www.duckdns.org/update?domains=yourdomain&token=your-token&verbose=true"

# Expected response: OK or KO (with details)
```

### Wrong IP Being Updated

```bash
# Check what IP DuckDNS sees
curl https://www.duckdns.org/update?domains=yourdomain&token=your-token&ip=&verbose=true

# Check your actual public IP
curl ifconfig.me

# If different, check router port forwarding
```

### Token Issues

- **Invalid Token:** Regenerate token at DuckDNS.org
- **Token Not Working:** Check for extra spaces in `.env` file
- **Multiple Domains:** Separate with commas: `domain1,domain2`

### Let's Encrypt Issues

If SSL certificates fail:
1. Verify DuckDNS is updating correctly
2. Check domain propagation: `nslookup yourdomain.duckdns.org`
3. Ensure ports 80 and 443 are forwarded to your server
4. Wait 10-15 minutes for DNS propagation

## Integration with Other Services

### Traefik

Traefik uses your DuckDNS domain for:
- Generating SSL certificates via Let's Encrypt
- Routing incoming HTTPS traffic to services
- Creating service-specific subdomains (e.g., `plex.yourdomain.duckdns.org`)

### Let's Encrypt

Let's Encrypt requires:
1. A publicly accessible domain (provided by DuckDNS)
2. DNS validation or HTTP challenge
3. Ports 80/443 accessible from the internet

### Port Forwarding

On your router, forward these ports to your server:
- Port 80 (HTTP) → Your Server IP
- Port 443 (HTTPS) → Your Server IP

## Alternatives to DuckDNS

- **No-IP:** Similar free DDNS service (requires monthly confirmation)
- **FreeDNS:** Another free option
- **Cloudflare:** Requires owning a domain, but adds CDN benefits
- **Custom Domain + Cloudflare:** More professional but requires purchasing domain

## Best Practices

1. **Keep Your Token Secret:** Don't share or commit to public repositories
2. **Use One Domain:** Multiple domains complicate SSL certificates
3. **Monitor Logs:** Occasionally check logs to ensure updates are working
4. **Router Backup:** Save your router config in case you need to reconfigure port forwarding
5. **Alternative DDNS:** Consider having a backup DDNS service

## Summary

DuckDNS is the foundational service that makes your homelab accessible from the internet. It provides:
- A memorable domain name for your homelab
- Automatic IP updates when your ISP changes your address
- Integration with Let's Encrypt for SSL certificates
- Simple, free, and reliable service

Without DuckDNS (or similar DDNS), you would need to use your IP address directly and manually update SSL certificates - making remote access and HTTPS much more difficult.
