# FlareSolverr - Cloudflare Bypass Proxy

## Table of Contents
- [Overview](#overview)
- [What is FlareSolverr?](#what-is-flaresolverr)
- [Why Use FlareSolverr?](#why-use-flaresolverr)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Proxy Service  
**Docker Image:** [ghcr.io/flaresolverr/flaresolverr](https://github.com/FlareSolverr/FlareSolverr/pkgs/container/flaresolverr)  
**Default Stack:** `media-management.yml`  
**API Port:** 8191  
**Authentication:** None (internal service)  
**Used By:** Prowlarr, Jackett, NZBHydra2

## What is FlareSolverr?

FlareSolverr is a proxy server that solves Cloudflare and DDoS-GUARD challenges automatically. Many torrent indexers and websites use Cloudflare protection to prevent automated access. FlareSolverr uses a headless browser to solve these challenges, allowing Prowlarr and other *arr apps to access protected indexers.

### Key Features
- **Cloudflare Bypass:** Solves "Checking your browser" challenges
- **DDoS-GUARD Support:** Handles DDoS protection pages
- **Headless Browser:** Uses Chromium to simulate real browser
- **Simple API:** Easy integration with existing tools
- **Session Management:** Maintains authentication cookies
- **No Manual Intervention:** Fully automated
- **Docker Ready:** Easy deployment
- **Lightweight:** Minimal resource usage

## Why Use FlareSolverr?

1. **Access Protected Indexers:** Bypass Cloudflare challenges
2. **Automated:** No manual captcha solving
3. **Essential for Prowlarr:** Many indexers require it
4. **Free:** No paid services needed
5. **Simple Integration:** Works with *arr apps
6. **Session Support:** Maintains login state
7. **Multiple Sites:** Works with various protections
8. **Open Source:** Community-maintained

## How It Works

```
Prowlarr → Indexer (Protected by Cloudflare)
       ↓
Cloudflare Challenge Detected
       ↓
Prowlarr → FlareSolverr API
       ↓
FlareSolverr Opens Headless Browser
       ↓
Solves Cloudflare Challenge
       ↓
Returns Cookies/Content to Prowlarr
       ↓
Prowlarr Accesses Indexer Successfully
```

### Challenge Types

**Cloudflare:**
- "Checking your browser before accessing..."
- JavaScript challenge
- Captcha (in some cases)

**DDoS-GUARD:**
- Similar protection mechanism
- Requires browser verification

## Configuration in AI-Homelab

### Directory Structure

```
# No persistent data needed
# FlareSolverr is stateless
```

### Environment Variables

```bash
# Log level
LOG_LEVEL=info

# Optional: Log HTML responses
LOG_HTML=false

# Optional: Captcha solver (paid services)
# CAPTCHA_SOLVER=none

# Optional: Timeout
# TIMEOUT=60000
```

## Official Resources

- **GitHub:** https://github.com/FlareSolverr/FlareSolverr
- **Docker Hub:** https://github.com/FlareSolverr/FlareSolverr/pkgs/container/flaresolverr
- **Documentation:** https://github.com/FlareSolverr/FlareSolverr/wiki

## Educational Resources

### Videos
- [FlareSolverr Setup](https://www.youtube.com/results?search_query=flaresolverr+prowlarr+setup)
- [Bypass Cloudflare with FlareSolverr](https://www.youtube.com/results?search_query=flaresolverr+cloudflare)

### Articles & Guides
- [GitHub Documentation](https://github.com/FlareSolverr/FlareSolverr)
- [Prowlarr Integration](https://wiki.servarr.com/prowlarr/settings#flaresolverr)

### Concepts to Learn
- **Cloudflare Challenge:** Browser verification system
- **Headless Browser:** Browser without UI
- **Session Management:** Cookie persistence
- **Proxy Server:** Intermediary for requests
- **Rate Limiting:** Request throttling

## Docker Configuration

### Complete Service Definition

```yaml
flaresolverr:
  image: ghcr.io/flaresolverr/flaresolverr:latest
  container_name: flaresolverr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8191:8191"
  environment:
    - LOG_LEVEL=info
    - LOG_HTML=false
    - CAPTCHA_SOLVER=none
    - TZ=America/New_York
```

**Note:** No volume needed - stateless service

### Resource Limits (Optional)

```yaml
flaresolverr:
  image: ghcr.io/flaresolverr/flaresolverr:latest
  container_name: flaresolverr
  deploy:
    resources:
      limits:
        memory: 1G
        cpus: '1.0'
  # ... rest of config
```

## Usage

### Prowlarr Integration

**Settings → Indexers → FlareSolverr:**

1. **Tags:** Create tag "flaresolverr"
2. **Host:** `http://flaresolverr:8191`
3. **Test connection**
4. **Save**

**Tag Indexers:**
- Edit indexer that needs FlareSolverr
- Tags → Add "flaresolverr"
- Save

**When to Tag:**
- Indexer returns Cloudflare errors
- "Checking your browser" messages
- "DDoS protection by Cloudflare"
- 403 Forbidden errors

### Manual API Testing

```bash
# Test FlareSolverr
curl -X POST http://localhost:8191/v1 \
  -H "Content-Type: application/json" \
  -d '{
    "cmd": "request.get",
    "url": "https://example.com",
    "maxTimeout": 60000
  }'
```

**Response:**
- Status
- Cookies
- HTML content
- Challenge solution

### Session Management

**Create Session:**
```bash
curl -X POST http://localhost:8191/v1 \
  -d '{"cmd": "sessions.create"}'
```

**Use Session:**
```bash
curl -X POST http://localhost:8191/v1 \
  -d '{
    "cmd": "request.get",
    "url": "https://example.com",
    "session": "SESSION_ID"
  }'
```

**Destroy Session:**
```bash
curl -X POST http://localhost:8191/v1 \
  -d '{
    "cmd": "sessions.destroy",
    "session": "SESSION_ID"
  }'
```

## Troubleshooting

### FlareSolverr Not Working

```bash
# Check container status
docker ps | grep flaresolverr

# Check logs
docker logs flaresolverr

# Test API
curl http://localhost:8191/health
# Should return: {"status": "ok"}

# Check connectivity from Prowlarr
docker exec prowlarr curl http://flaresolverr:8191/health
```

### Indexer Still Blocked

```bash
# Common causes:
# 1. FlareSolverr not tagged on indexer
# 2. Cloudflare updated protection
# 3. IP temporarily banned
# 4. Rate limiting

# Verify tag
# Prowlarr → Indexers → Edit indexer → Tags

# Check FlareSolverr logs
docker logs flaresolverr | tail -50

# Try different indexer
# Some sites may be too aggressive

# Wait and retry
# Temporary bans usually lift after time
```

### High Memory Usage

```bash
# Check resource usage
docker stats flaresolverr

# Chromium uses significant memory
# Normal: 200-500MB
# High load: 500MB-1GB

# Restart if memory leak
docker restart flaresolverr

# Set memory limit
# Add to docker-compose:
  deploy:
    resources:
      limits:
        memory: 1G
```

### Timeout Errors

```bash
# Increase timeout
# Environment variable:
TIMEOUT=120000  # 2 minutes

# Or in request:
curl -X POST http://localhost:8191/v1 \
  -d '{
    "cmd": "request.get",
    "url": "https://example.com",
    "maxTimeout": 120000
  }'

# Check network speed
# Slow connections need longer timeout
```

### Browser Crashes

```bash
# Check logs for crashes
docker logs flaresolverr | grep -i crash

# Restart container
docker restart flaresolverr

# Check memory limits
# May need more RAM

# Update to latest version
docker pull ghcr.io/flaresolverr/flaresolverr:latest
docker compose up -d flaresolverr
```

## Performance Optimization

### Resource Allocation

**Recommended:**
- CPU: 0.5-1 core
- RAM: 500MB-1GB
- No disk I/O needed

**High Load:**
- Increase memory limit
- More CPU if many requests

### Request Throttling

**Prowlarr automatically throttles:**
- Don't overload FlareSolverr
- Rate limits prevent bans

### Session Reuse

**For authenticated sites:**
- Create persistent session
- Reuse across requests
- Reduces challenge frequency

## Security Best Practices

1. **Internal Network Only:** Don't expose port 8191 publicly
2. **No Authentication:** FlareSolverr has no auth (keep internal)
3. **Docker Network:** Use private Docker network
4. **Regular Updates:** Keep FlareSolverr current
5. **Monitor Logs:** Watch for abuse
6. **Resource Limits:** Prevent DoS via resource exhaustion

## Integration with Other Services

### FlareSolverr + Prowlarr
- Bypass Cloudflare on indexers
- Tag-based activation
- Automatic challenge solving

### FlareSolverr + Jackett
- Similar integration
- Configure FlareSolverr endpoint
- Tag indexers needing it

### FlareSolverr + NZBHydra2
- Usenet indexer aggregator
- Cloudflare bypass support
- Configure endpoint URL

## Summary

FlareSolverr is the Cloudflare bypass proxy offering:
- Automatic challenge solving
- Prowlarr integration
- Headless browser technology
- Session management
- Simple API
- Free and open-source

**Perfect for:**
- Protected indexer access
- Prowlarr users
- Cloudflare bypassing
- Automated workflows
- *arr stack integration

**Key Points:**
- Tag indexers in Prowlarr
- No authentication (keep internal)
- Uses headless Chromium
- Memory usage ~500MB
- Stateless service
- Essential for many indexers

**Remember:**
- Don't expose publicly
- Tag only needed indexers
- Monitor resource usage
- Restart if memory issues
- Keep updated
- Internal Docker network only

FlareSolverr enables access to Cloudflare-protected indexers automatically!
