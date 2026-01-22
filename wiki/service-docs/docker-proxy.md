# Docker Socket Proxy - Secure Docker Socket Access

## Table of Contents
- [Overview](#overview)
- [What is Docker Socket Proxy?](#what-is-docker-socket-proxy)
- [Why Use Docker Socket Proxy?](#why-use-docker-socket-proxy)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Access Control](#access-control)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Infrastructure Security  
**Docker Image:** [tecnativa/docker-socket-proxy](https://hub.docker.com/r/tecnativa/docker-socket-proxy)  
**Default Stack:** `infrastructure.yml`  
**Web UI:** None (proxy service)  
**Port:** 2375 (internal only)  
**Purpose:** Secure access layer for Docker socket

## What is Docker Socket Proxy?

Docker Socket Proxy is a security-focused proxy that sits between Docker management tools and the Docker socket. It provides fine-grained access control to Docker API endpoints, allowing you to grant specific permissions rather than full Docker socket access.

### Key Features
- **Granular Permissions:** Control which Docker API endpoints are accessible
- **Security Layer:** Prevents full root access to host
- **Read/Write Control:** Separate read-only and write permissions
- **API Filtering:** Whitelist specific Docker API calls
- **No Authentication:** Relies on network isolation
- **Lightweight:** Minimal resource usage
- **HAProxy Based:** Stable, proven technology
- **Zero Config:** Works out of the box with sensible defaults

## Why Use Docker Socket Proxy?

### The Problem

Direct Docker socket access (`/var/run/docker.sock`) grants **root-equivalent access** to the host:

```yaml
# DANGEROUS: Full access to Docker = root on host
traefik:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

**Risks:**
- Container can access all other containers
- Can mount host filesystem
- Can escape container isolation
- Can compromise entire system

### The Solution

Docker Socket Proxy provides controlled access:

```yaml
# SAFER: Limited access via proxy
traefik:
  environment:
    - DOCKER_HOST=tcp://docker-proxy:2375
# No direct socket mount!

docker-proxy:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  environment:
    - CONTAINERS=1  # Allow container list
    - SERVICES=1    # Allow service list
    - TASKS=0       # Deny task access
```

**Benefits:**
1. **Principle of Least Privilege:** Only grant necessary permissions
2. **Reduced Attack Surface:** Limit what compromised container can do
3. **Audit Trail:** Centralized access point
4. **Network Isolation:** Proxy can be on separate network
5. **Read-Only Socket:** Proxy uses read-only mount

## How It Works

```
Management Tool (Traefik/Portainer/Dockge)
     ↓
TCP Connection to docker-proxy:2375
     ↓
Docker Socket Proxy (HAProxy)
     ├─ Check permissions
     ├─ Filter allowed endpoints
     └─ Forward or block request
     ↓
Docker Socket (/var/run/docker.sock)
     ↓
Docker Engine
```

### Request Flow

1. **Tool makes API request:** "List containers"
2. **Connects to proxy:** tcp://docker-proxy:2375
3. **Proxy checks permissions:** Is CONTAINERS=1?
4. **If allowed:** Forward to Docker socket
5. **If denied:** Return 403 Forbidden
6. **Response returned:** To requesting tool

### Permission Model

**Environment variables control access:**
- `CONTAINERS=1` → Allow container operations
- `IMAGES=1` → Allow image operations
- `NETWORKS=1` → Allow network operations
- `VOLUMES=1` → Allow volume operations
- `SERVICES=1` → Allow swarm service operations
- `TASKS=1` → Allow swarm task operations
- `SECRETS=1` → Allow secret operations
- `POST=0` → Deny all write operations (read-only)

## Configuration in AI-Homelab

### Directory Structure

```
# No persistent storage needed
# All configuration via environment variables
```

### Environment Variables

```bash
# Core Docker API endpoints
CONTAINERS=1    # Container list, inspect, logs, stats
SERVICES=1      # Service management (for Swarm)
TASKS=1         # Task management (for Swarm)
NETWORKS=1      # Network operations
VOLUMES=1       # Volume operations
IMAGES=1        # Image list, pull, push
INFO=1          # Docker info, version
EVENTS=1        # Docker events stream
PING=1          # Health check

# Write operations (set to 0 for read-only)
POST=1          # Create operations
BUILD=0         # Image build (usually not needed)
COMMIT=0        # Container commit
CONFIGS=0       # Config management
DISTRIBUTION=0  # Registry operations
EXEC=0          # Execute in container (dangerous)
SECRETS=0       # Secret management (Swarm)
SESSION=0       # Not commonly used
SWARM=0         # Swarm management

# Security
LOG_LEVEL=info  # Logging verbosity
```

## Official Resources

- **GitHub:** https://github.com/Tecnativa/docker-socket-proxy
- **Docker Hub:** https://hub.docker.com/r/tecnativa/docker-socket-proxy
- **Documentation:** https://github.com/Tecnativa/docker-socket-proxy/blob/master/README.md

## Educational Resources

### Videos
- [Docker Socket Security (TechnoTim)](https://www.youtube.com/watch?v=0aOqx8mQZFk)
- [Why You Should Use Docker Socket Proxy](https://www.youtube.com/results?search_query=docker+socket+proxy+security)
- [Container Security Best Practices](https://www.youtube.com/watch?v=9weaE6QEm8A)

### Articles & Guides
- [Docker Socket Proxy Documentation](https://github.com/Tecnativa/docker-socket-proxy)
- [Docker Socket Security Risks](https://docs.docker.com/engine/security/)
- [Principle of Least Privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)

### Concepts to Learn
- **Unix Socket:** Inter-process communication file
- **Docker API:** RESTful API for Docker operations
- **TCP Socket:** Network socket for remote access
- **HAProxy:** Load balancer and proxy
- **Least Privilege:** Minimal permissions principle
- **Attack Surface:** Potential vulnerability points
- **Container Escape:** Breaking out of container isolation

## Docker Configuration

### Complete Service Definition

```yaml
docker-proxy:
  image: tecnativa/docker-socket-proxy:latest
  container_name: docker-proxy
  restart: unless-stopped
  privileged: true  # Required for socket access
  networks:
    - docker-proxy-network  # Isolated network
  ports:
    - "2375:2375"  # Only expose internally
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro  # Read-only!
  environment:
    # Core permissions (what Traefik/Portainer need)
    - CONTAINERS=1
    - SERVICES=1
    - NETWORKS=1
    - IMAGES=1
    - INFO=1
    - EVENTS=1
    - PING=1
    
    # Write operations (enable as needed)
    - POST=1
    
    # Deny dangerous operations
    - BUILD=0
    - COMMIT=0
    - EXEC=0
    - SECRETS=0
    
    # Logging
    - LOG_LEVEL=info

networks:
  docker-proxy-network:
    internal: true  # No external access
```

### Connecting Services to Proxy

**Traefik Configuration:**
```yaml
traefik:
  networks:
    - traefik-network
    - docker-proxy-network
  environment:
    - DOCKER_HOST=tcp://docker-proxy:2375
  # NO volumes for Docker socket!
  # volumes:
  #   - /var/run/docker.sock:/var/run/docker.sock  # REMOVE THIS
```

**Portainer Configuration:**
```yaml
portainer:
  networks:
    - traefik-network
    - docker-proxy-network
  environment:
    - AGENT_HOST=docker-proxy
  # NO volumes for Docker socket!
```

**Dockge Configuration:**
```yaml
dockge:
  networks:
    - traefik-network
    - docker-proxy-network
  environment:
    - DOCKER_HOST=tcp://docker-proxy:2375
  # NO volumes for Docker socket!
```

## Access Control

### Traefik Minimal Permissions

Traefik only needs to read container labels:

```yaml
docker-proxy:
  environment:
    - CONTAINERS=1  # Read container info
    - SERVICES=1    # Read services
    - NETWORKS=1    # Read networks
    - INFO=1        # Docker info
    - EVENTS=1      # Watch for changes
    - POST=0        # No write operations
```

### Portainer Full Permissions

Portainer needs more access for management:

```yaml
docker-proxy:
  environment:
    - CONTAINERS=1
    - SERVICES=1
    - TASKS=1
    - NETWORKS=1
    - VOLUMES=1
    - IMAGES=1
    - INFO=1
    - EVENTS=1
    - POST=1        # Create/update
    - PING=1
```

### Watchtower Minimal Permissions

Watchtower needs to pull images and recreate containers:

```yaml
docker-proxy:
  environment:
    - CONTAINERS=1
    - IMAGES=1
    - INFO=1
    - POST=1        # Create operations
```

### Read-Only Mode

For monitoring tools (Glances, Dozzle):

```yaml
docker-proxy:
  environment:
    - CONTAINERS=1
    - SERVICES=1
    - TASKS=1
    - NETWORKS=1
    - VOLUMES=1
    - IMAGES=1
    - INFO=1
    - EVENTS=1
    - POST=0        # No writes
    - BUILD=0
    - COMMIT=0
    - EXEC=0
```

## Advanced Topics

### Multiple Proxy Instances

Run separate proxies for different permission levels:

**docker-proxy-read (for monitoring tools):**
```yaml
docker-proxy-read:
  image: tecnativa/docker-socket-proxy
  environment:
    - CONTAINERS=1
    - IMAGES=1
    - INFO=1
    - POST=0  # Read-only
  networks:
    - monitoring-network
```

**docker-proxy-write (for management tools):**
```yaml
docker-proxy-write:
  image: tecnativa/docker-socket-proxy
  environment:
    - CONTAINERS=1
    - IMAGES=1
    - NETWORKS=1
    - VOLUMES=1
    - POST=1  # Read-write
  networks:
    - management-network
```

### Custom HAProxy Configuration

For advanced filtering, mount custom config:

```yaml
docker-proxy:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
```

**Custom haproxy.cfg:**
```haproxy
global
    log stdout format raw local0

defaults
    log global
    mode http
    timeout connect 5s
    timeout client 30s
    timeout server 30s

frontend docker
    bind :2375
    default_backend docker_backend

backend docker_backend
    server docker unix@/var/run/docker.sock
    
    # Custom ACLs
    acl containers_req path_beg /containers
    acl images_req path_beg /images
    
    # Only allow specific endpoints
    http-request deny unless containers_req or images_req
```

### Logging and Monitoring

```yaml
docker-proxy:
  environment:
    - LOG_LEVEL=debug  # More verbose logging
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "3"
```

**Monitor access:**
```bash
# View proxy logs
docker logs -f docker-proxy

# See what endpoints are being accessed
docker logs docker-proxy | grep -E "GET|POST|PUT|DELETE"
```

### Network Isolation

```yaml
networks:
  docker-proxy-network:
    driver: bridge
    internal: true  # No internet access
    ipam:
      config:
        - subnet: 172.25.0.0/16
```

**Only allow specific services:**
```yaml
services:
  traefik:
    networks:
      docker-proxy-network:
        ipv4_address: 172.25.0.2
  
  portainer:
    networks:
      docker-proxy-network:
        ipv4_address: 172.25.0.3
```

## Troubleshooting

### Services Can't Connect to Docker

```bash
# Check if proxy is running
docker ps | grep docker-proxy

# Test proxy connectivity
docker exec traefik wget -qO- http://docker-proxy:2375/version

# Check networks
docker network inspect docker-proxy-network

# Verify service is on proxy network
docker inspect traefik | grep -A10 Networks
```

### Permission Denied Errors

```bash
# Check proxy logs
docker logs docker-proxy

# Example error: "POST /containers/create 403"
# Solution: Add POST=1 to docker-proxy environment

# Check which endpoint is being blocked
docker logs docker-proxy | grep 403

# Enable required permission
# If /images/create is blocked, add IMAGES=1
```

### Traefik Not Discovering Services

```bash
# Ensure these are enabled:
docker-proxy:
  environment:
    - CONTAINERS=1
    - SERVICES=1
    - EVENTS=1  # Critical for auto-discovery

# Check if Traefik is using proxy
docker exec traefik env | grep DOCKER_HOST

# Test manually
docker exec traefik wget -qO- http://docker-proxy:2375/containers/json
```

### Portainer Shows "Cannot connect to Docker"

```bash
# Portainer needs more permissions
docker-proxy:
  environment:
    - CONTAINERS=1
    - SERVICES=1
    - TASKS=1
    - NETWORKS=1
    - VOLUMES=1
    - IMAGES=1
    - POST=1

# In Portainer settings:
# Environment URL: tcp://docker-proxy:2375
# Not: unix:///var/run/docker.sock
```

### Watchtower Not Updating Containers

```bash
# Watchtower needs write access
docker-proxy:
  environment:
    - CONTAINERS=1
    - IMAGES=1
    - POST=1  # Required for creating containers

# Check Watchtower logs
docker logs watchtower
```

### High Memory/CPU Usage

```bash
# Check proxy stats
docker stats docker-proxy

# Should be minimal (~10MB RAM, <1% CPU)
# If high, check for connection leaks

# Restart proxy
docker restart docker-proxy

# Check for excessive requests
docker logs docker-proxy | wc -l
```

## Security Best Practices

1. **Read-Only Socket:** Always mount socket as `:ro`
2. **Minimal Permissions:** Only enable what's needed
3. **Network Isolation:** Use internal network
4. **No Public Exposure:** Never expose port 2375 to internet
5. **Separate Proxies:** Different proxies for different trust levels
6. **Monitor Access:** Review logs regularly
7. **Disable Exec:** Never enable EXEC unless absolutely necessary
8. **Regular Updates:** Keep proxy image updated
9. **Principle of Least Privilege:** Start with nothing, add as needed
10. **Testing:** Test permissions in development first

## Migration Guide

### Converting from Direct Socket Access

**Before (insecure):**
```yaml
traefik:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

**After (secure):**

1. **Add docker-proxy:**
```yaml
docker-proxy:
  image: tecnativa/docker-socket-proxy
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  environment:
    - CONTAINERS=1
    - SERVICES=1
    - NETWORKS=1
    - EVENTS=1
  networks:
    - docker-proxy-network
```

2. **Update service:**
```yaml
traefik:
  environment:
    - DOCKER_HOST=tcp://docker-proxy:2375
  networks:
    - traefik-network
    - docker-proxy-network
  # Remove socket volume!
```

3. **Create network:**
```yaml
networks:
  docker-proxy-network:
    internal: true
```

4. **Test:**
```bash
docker compose up -d
docker logs traefik  # Check for errors
```

## Performance Impact

**Overhead:**
- Latency: ~1-2ms per request
- Memory: ~10-20MB
- CPU: <1%

**Minimal impact because:**
- Docker API calls are infrequent
- Proxy is extremely lightweight
- HAProxy is optimized for performance

**Benchmark:**
```bash
# Direct socket
time docker ps
# ~0.05s

# Via proxy
time docker -H tcp://docker-proxy:2375 ps
# ~0.06s

# Negligible difference for management operations
```

## Summary

Docker Socket Proxy is a critical security component that:
- Provides granular access control to Docker API
- Prevents root-equivalent access from containers
- Uses principle of least privilege
- Adds minimal overhead
- Simple to configure and maintain

**Essential for:**
- Production environments
- Multi-user setups
- Security-conscious homelabs
- Compliance requirements
- Defense in depth strategy

**Implementation Priority:**
1. Deploy docker-proxy with minimal permissions
2. Update Traefik to use proxy (most critical)
3. Update Portainer to use proxy
4. Update other management tools
5. Remove all direct socket mounts
6. Test thoroughly
7. Monitor logs

**Remember:**
- Direct socket access = root on host
- Always use read-only socket mount in proxy
- Start with restrictive permissions
- Add permissions only as needed
- Use separate proxies for different trust levels
- Never expose proxy to internet
- Monitor access logs
- Essential security layer for homelab
