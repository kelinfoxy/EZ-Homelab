# Traefik - Modern Reverse Proxy

## Table of Contents
- [Overview](#overview)
- [What is Traefik?](#what-is-traefik)
- [Why Use Traefik?](#why-use-traefik)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Core Infrastructure  
**Docker Image:** [traefik](https://hub.docker.com/_/traefik)  
**Default Stack:** `core.yml`  
**Web UI:** `https://traefik.${DOMAIN}`  
**Authentication:** Protected by Authelia (SSO)

## What is Traefik?

Traefik is a modern HTTP reverse proxy and load balancer designed for microservices and containerized applications. It automatically discovers services and configures routing, making it ideal for Docker environments.

### Key Features
- **Automatic Service Discovery:** Detects Docker containers and configures routing automatically
- **Automatic HTTPS:** Integrates with Let's Encrypt for free SSL certificates
- **Dynamic Configuration:** No need to restart when adding/removing services
- **Multiple Providers:** Supports Docker, Kubernetes, Consul, and more
- **Middleware Support:** Authentication, rate limiting, compression, etc.
- **Load Balancing:** Distribute traffic across multiple instances
- **WebSocket Support:** Full WebSocket passthrough
- **Dashboard:** Built-in web UI for monitoring

## Why Use Traefik?

1. **Single Entry Point:** All services accessible through one domain with subdomains
2. **Automatic SSL:** Free SSL certificates automatically renewed
3. **No Manual Configuration:** Services auto-configure with Docker labels
4. **Security:** Centralized authentication and access control
5. **Professional Setup:** Industry-standard reverse proxy
6. **Easy Maintenance:** Add/remove services without touching Traefik config

## How It Works

```
Internet → Your Domain → Router (Port 80/443) → Traefik
                                                   ├→ Plex (plex.domain.com)
                                                   ├→ Sonarr (sonarr.domain.com)
                                                   ├→ Radarr (radarr.domain.com)
                                                   └→ [Other Services]
```

### Request Flow

1. **User visits** `https://plex.yourdomain.duckdns.org`
2. **DNS resolves** to your public IP (via DuckDNS)
3. **Router forwards** port 443 to Traefik
4. **Traefik receives** the request and checks routing rules
5. **Middleware** applies authentication (if required)
6. **Traefik forwards** request to Plex container
7. **Response flows back** through Traefik to user

### Service Discovery

Traefik reads Docker labels to configure routing:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.plex.rule=Host(`plex.${DOMAIN}`)"
  - "traefik.http.routers.plex.entrypoints=websecure"
  - "traefik.http.routers.plex.tls.certresolver=letsencrypt"
```

Traefik automatically:
- Creates route for `plex.yourdomain.com`
- Requests SSL certificate from Let's Encrypt
- Renews certificates before expiration
- Routes traffic to Plex container

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/core/traefik/
├── traefik.yml          # Static configuration
├── dynamic/             # Dynamic routing rules
│   ├── routes.yml       # Additional routes
│   └── external.yml     # External service proxying
└── acme.json           # SSL certificates (auto-generated)
```

### Static Configuration (`traefik.yml`)

```yaml
api:
  dashboard: true  # Enable web dashboard

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /acme.json
      # For testing environments: Use Let's Encrypt staging to avoid rate limits
      # caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      dnsChallenge:
        provider: duckdns
        # Note: Explicit resolvers can cause DNS propagation check failures
        # Remove resolvers to use system's DNS for better DuckDNS TXT record resolution

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    directory: /dynamic
    watch: true
```

### Environment Variables

```bash
DOMAIN=yourdomain.duckdns.org
ACME_EMAIL=your-email@example.com
```

### Service Labels Example

```yaml
services:
  myservice:
    image: myapp:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.${DOMAIN}`)"
      - "traefik.http.routers.myservice.entrypoints=websecure"
      - "traefik.http.routers.myservice.tls=true"  # Uses wildcard cert automatically
      - "traefik.http.routers.myservice.middlewares=authelia@docker"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"
    networks:
      - traefik-network
```

## Official Resources

- **Website:** https://traefik.io
- **Documentation:** https://doc.traefik.io/traefik/
- **GitHub:** https://github.com/traefik/traefik
- **Docker Hub:** https://hub.docker.com/_/traefik
- **Community Forum:** https://community.traefik.io
- **Blog:** https://traefik.io/blog/

## Educational Resources

### Videos
- [Traefik 101 - What is a Reverse Proxy? (Techno Tim)](https://www.youtube.com/watch?v=liV3c9m_OX8)
- [Traefik Tutorial - The BEST Reverse Proxy? (NetworkChuck)](https://www.youtube.com/watch?v=wLrmmh1eI94)
- [Traefik vs Nginx Proxy Manager](https://www.youtube.com/results?search_query=traefik+vs+nginx+proxy+manager)
- [Traefik + Docker + SSL (Wolfgang's Channel)](https://www.youtube.com/watch?v=lJRPg9jN4hE)

### Articles & Guides
- [Traefik Official Documentation](https://doc.traefik.io/traefik/)
- [Traefik Quick Start Guide](https://doc.traefik.io/traefik/getting-started/quick-start/)
- [Docker Provider Documentation](https://doc.traefik.io/traefik/providers/docker/)
- [Let's Encrypt with Traefik](https://doc.traefik.io/traefik/user-guides/docker-compose/acme-http/)
- [Awesome Traefik (GitHub)](https://github.com/containous/traefik/wiki)

### Concepts to Learn
- **Reverse Proxy:** Server that sits between clients and backend services
- **Load Balancer:** Distributes traffic across multiple backend servers
- **EntryPoints:** Ports where Traefik listens (80, 443)
- **Routers:** Define rules for routing traffic to services
- **Middleware:** Process requests (auth, rate limiting, headers)
- **Services:** Backend applications that receive traffic
- **ACME:** Automatic Certificate Management Environment (Let's Encrypt)

## Docker Configuration

### Complete Service Definition

```yaml
traefik:
  image: traefik:v2.11
  container_name: traefik
  restart: unless-stopped
  security_opt:
    - no-new-privileges:true
  networks:
    - traefik-network
  ports:
    - "80:80"      # HTTP (redirects to HTTPS)
    - "443:443"    # HTTPS
    - "8080:8080"  # Dashboard
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - /opt/stacks/core/traefik/traefik.yml:/traefik.yml:ro
    - /opt/stacks/core/traefik/dynamic:/dynamic:ro
    - /opt/stacks/core/traefik/acme.json:/acme.json
  environment:
    - DUCKDNS_TOKEN=${DUCKDNS_TOKEN}
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.traefik.rule=Host(`traefik.${DOMAIN}`)"
    - "traefik.http.routers.traefik.entrypoints=websecure"
    - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
    - "traefik.http.routers.traefik.tls.domains[0].main=${DOMAIN}"
    - "traefik.http.routers.traefik.tls.domains[0].sans=*.${DOMAIN}"
    - "traefik.http.routers.traefik.middlewares=authelia@docker"
    - "traefik.http.routers.traefik.service=api@internal"
```

### Important Files

#### acme.json
Stores SSL certificates. **Must have 600 permissions:**
```bash
touch /opt/stacks/core/traefik/acme.json
chmod 600 /opt/stacks/core/traefik/acme.json
```

#### Dynamic Configuration
Add custom routes for non-Docker services:

```yaml
# /opt/stacks/core/traefik/dynamic/external.yml
http:
  routers:
    raspberry-pi:
      rule: "Host(`pi.yourdomain.com`)"
      entryPoints:
        - websecure
      service: raspberry-pi
      tls:
        certResolver: letsencrypt
  
  services:
    raspberry-pi:
      loadBalancer:
        servers:
          - url: "http://192.168.1.50:80"
```

## Advanced Topics

### Middlewares

#### Authentication (Authelia)
```yaml
labels:
  - "traefik.http.routers.myservice.middlewares=authelia@docker"
```

#### Rate Limiting
```yaml
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100
        burst: 50
```

#### Headers
```yaml
http:
  middlewares:
    security-headers:
      headers:
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
```

### Multiple Domains

```yaml
labels:
  - "traefik.http.routers.myservice.rule=Host(`app.domain1.com`) || Host(`app.domain2.com`)"
```

### PathPrefix Routing

```yaml
labels:
  - "traefik.http.routers.myservice.rule=Host(`domain.com`) && PathPrefix(`/app`)"
```

### WebSocket Support

WebSockets work automatically. For specific configuration:

```yaml
labels:
  - "traefik.http.services.myservice.loadbalancer.sticky.cookie=true"
```

### Custom Certificates

```yaml
tls:
  certificates:
    - certFile: /path/to/cert.pem
      keyFile: /path/to/key.pem
```

## Troubleshooting

### Check Traefik Dashboard

Access at `https://traefik.yourdomain.com` to see:
- All discovered services
- Active routes
- Certificate status
- Error logs

### Common Issues

#### Service Not Accessible

```bash
# Check if Traefik is running
docker ps | grep traefik

# View Traefik logs
docker logs traefik

# Check if service is on traefik-network
docker inspect service-name | grep Networks

# Verify labels
docker inspect service-name | grep traefik
```

#### Wildcard Certificates with DuckDNS

**IMPORTANT:** When using DuckDNS for DNS challenge, only ONE service should request certificates:

```yaml
# ✅ CORRECT: Only Traefik requests wildcard certificate
traefik:
  labels:
    - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
    - "traefik.http.routers.traefik.tls.domains[0].main=${DOMAIN}"
    - "traefik.http.routers.traefik.tls.domains[0].sans=*.${DOMAIN}"

# ✅ CORRECT: Other services just enable TLS
other-service:
  labels:
    - "traefik.http.routers.service.tls=true"  # Uses wildcard cert

# ❌ WRONG: Multiple services requesting individual certs
other-service:
  labels:
    - "traefik.http.routers.service.tls.certresolver=letsencrypt"  # Causes conflicts!
```

**Why?** DuckDNS can only maintain ONE TXT record at `_acme-challenge.yourdomain.duckdns.org`. Multiple simultaneous certificate requests will fail with "Incorrect TXT record" errors.

**Solution:** Use a wildcard certificate (`*.yourdomain.duckdns.org`) that covers all subdomains.

**Verify Certificate:**
```bash
# Check wildcard certificate is obtained
python3 -c "import json; d=json.load(open('/opt/stacks/core/traefik/acme.json')); print(f'Certificates: {len(d[\"letsencrypt\"][\"Certificates\"])}')"

# Test certificate being served
echo | openssl s_client -connect yourdomain.duckdns.org:443 -servername yourdomain.duckdns.org 2>/dev/null | openssl x509 -noout -subject -issuer
```

#### SSL Certificate Issues

```bash
# Check acme.json permissions
ls -la /opt/stacks/core/traefik/acme.json
# Should be: -rw------- (600)

# Check certificate generation logs
docker exec traefik tail -50 /var/log/traefik/traefik.log | grep -E "acme|certificate"

# Verify ports 80/443 are accessible
curl -I http://yourdomain.duckdns.org
curl -I https://yourdomain.duckdns.org

# Check Let's Encrypt rate limits
# Let's Encrypt allows 50 certificates per domain per week
```

#### Testing Environment Setup

When resetting test environments, use Let's Encrypt staging to avoid production rate limits:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      # ... rest of config
```

**Staging certificates are not trusted by browsers** - they're for testing only. Switch back to production when deploying.

#### Certificate Conflicts During Testing

- **Preserve acme.json** across test environment resets to reuse certificates
- **Use staging server** for frequent testing to avoid rate limits
- **Wait 1+ hours** between certificate requests to allow DNS propagation
- **Ensure only one Traefik instance** performs DNS challenges (DuckDNS allows only one TXT record)

#### Router Port Forwarding

Ensure these ports are forwarded to your server:
- Port 80 (HTTP) → Required for Let's Encrypt challenges
- Port 443 (HTTPS) → Required for HTTPS traffic

#### acme.json Corruption

```bash
# Backup and recreate
cp /opt/stacks/core/traefik/acme.json /opt/stacks/core/traefik/acme.json.backup
rm /opt/stacks/core/traefik/acme.json
touch /opt/stacks/core/traefik/acme.json
chmod 600 /opt/stacks/core/traefik/acme.json

# Restart Traefik
docker restart traefik
```

### Debugging Commands

```bash
# Test service connectivity from Traefik
docker exec traefik ping service-name

# Check routing rules
docker exec traefik traefik version

# Validate configuration
docker exec traefik cat /traefik.yml

# Check docker socket connection
docker exec traefik ls -la /var/run/docker.sock
```

## Security Best Practices

1. **Protect Dashboard:** Always use Authelia or basic auth for dashboard
2. **Regular Updates:** Keep Traefik updated for security patches
3. **Limit Docker Socket:** Use Docker Socket Proxy for additional security
4. **Use Strong Ciphers:** Configure modern TLS settings
5. **Rate Limiting:** Implement rate limiting on public endpoints
6. **Security Headers:** Enable HSTS, CSP, and other security headers
7. **Monitor Logs:** Regularly review logs for suspicious activity

## Performance Optimization

- **Enable Compression:** Traefik can compress responses
- **Connection Pooling:** Reuse connections to backend services
- **HTTP/2:** Enabled by default for better performance
- **Caching:** Consider adding caching middleware
- **Resource Limits:** Set appropriate CPU/memory limits

## Comparison with Alternatives

### Traefik vs Nginx Proxy Manager
- **Traefik:** Automatic discovery, native Docker integration, config as code
- **NPM:** Web UI for configuration, simpler for beginners, more manual setup

### Traefik vs Caddy
- **Traefik:** Better for Docker, more features, larger community
- **Caddy:** Simpler config, automatic HTTPS, less Docker-focused

### Traefik vs HAProxy
- **Traefik:** Modern, dynamic, Docker-native
- **HAProxy:** More powerful, complex config, not Docker-native

## Summary

Traefik is the heart of your homelab's networking infrastructure. It:
- Automatically routes all web traffic to appropriate services
- Manages SSL certificates without manual intervention
- Provides a single entry point for all services
- Integrates seamlessly with Docker
- Scales from simple to complex setups

Understanding Traefik is crucial for managing your homelab effectively. Take time to explore the dashboard and understand how routing works - it will make troubleshooting and adding new services much easier.

## Related Services

- **[Authelia](authelia.md)** - SSO authentication that integrates with Traefik
- **[Sablier](sablier.md)** - Lazy loading that works with Traefik routing
- **[DuckDNS](duckdns.md)** - Dynamic DNS for SSL certificate validation
- **[Gluetun](gluetun.md)** - VPN routing that can work alongside Traefik

## See Also

- **[Traefik Labels Guide](../docker-guidelines.md#traefik-label-patterns)** - How to configure services for Traefik
- **[SSL Certificate Setup](../getting-started.md#notes-about-ssl-certificates-from-letsencrypt-with-duckdns)** - How SSL certificates work with Traefik
- **[External Host Proxying](../proxying-external-hosts.md)** - Route non-Docker services through Traefik
