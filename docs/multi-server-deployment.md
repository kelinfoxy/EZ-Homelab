# Multi-Server Deployment with On-Demand Services

## Overview

This guide explains the **current multi-server architecture** where:
- **Core Server**: Handles external traffic (ports 80/443); runs DuckDNS, Traefik (multi-provider), Authelia
- **Additional Servers**: Run Sablier (lazy loading) with direct port exposure; no local Traefik
- **Manual Routing**: Core Traefik routes to IP:PORT combinations via YAML configuration files
- **Independent Management**: Each server manages its own containers with lazy loading

> **Note**: This document describes the current simplified architecture. Additional servers are "headless" - they expose ports directly without local reverse proxy.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    🌐 PUBLIC INTERNET                            │
│  HTTPS Traffic (Ports 80/443 forwarded from router)             │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼ HTTPS (SSL/TLS)
┌─────────────────────────────────────────────────────────────────┐
│                         CORE SERVER                              │
│  ┌────────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│  │  DuckDNS   │  │ Traefik  │  │ Authelia │  │ Core Services │ │
│  │ (SSL DNS)  │  │ (multi-  │  │  (SSO)   │  │   (local)     │ │
│  │            │  │ provider)│  │          │  │               │ │
│  └────────────┘  └────┬─────┘  └──────────┘  └──────────────┘ │
│                       │                                          │
│          ┌──────────────┼──────────────┐                        │
│          │  Routes:     │              │                        │
│          │  • Local     │  (labels)    │                        │
│          │  • Remote    │  (YAML files)│                        │
└──────────┼──────────────┼──────────────┼────────────────────────┘
           │              │              │
           │ HTTP (internal network)     │
           │ No SSL/TLS encryption       │
           ▼              ▼              ▼
    ┌─────────────────────────────────────────┐
    │       ADDITIONAL SERVER (e.g., Pi)      │
    │  ┌──────────┐  ┌───────┐  ┌──────────┐ │
    │  │ Sablier  │  │ Media │  │ Exposed  │ │
    │  │ (lazy    │  │ Apps  │  │ Ports    │ │
    │  │ loading) │  │       │  │ 5001,    │ │
    │  └──────────┘  └───────┘  │ 8085...  │ │
    └────────────────────────────┼──────────┘
                                 │
                    Direct port access
                    (no local reverse proxy)
```

### Traffic Flow Summary

1. **Internet → Core**: HTTPS (ports 80/443 forwarded from router)
2. **Core → Additional**: HTTP (internal network, no encryption needed)
3. **Additional → Core**: HTTP (direct response to core Traefik)

# Deployment Process

## Step 1: Deploy Core Server

On the core server, run `ez-homelab.sh`  
* Use Option 1 to Install Prerequisites
* Then Option 2 to Deploy Core Server

This deploys: DuckDNS, Traefik(core), Authelia, Dashboards & Infrastructure

From Dockge you can start/stop any of the stacks or containers.

**Port Forwarding**:
- Forward ports 80 & 443 from your router
- Only this server requires port forwarding

## Step 2: Deploy Additional Server

On the additional server, run `ez-homelab.sh`  
* Use Option 1 to Install Prerequisites
* Then Option 3 to Deploy Additional Server

This deploys: Sablier (lazy loading), Dashboards & Infrastructure

From Dockge you can start/stop any of the stacks or containers.

**No Port Forwarding Required**:
- Services are accessed through core server

## How It Works

### Traffic Flow

1. **User accesses** `https://sonarr.yourdomain.duckdns.org` (HTTPS from internet)
2. **Core Traefik** receives HTTPS request:
   - Checks Authelia for authentication (SSO)
   - Routes to additional server: `http://192.168.1.100:8989` (HTTP internally)
3. **Additional server** receives direct HTTP request:
   - Service container receives request on exposed port
   - If stopped, Sablier starts the container
   - Shows loading page while container starts
4. **Service responds** directly back to core Traefik via HTTP, then HTTPS to user

### Key Points

- **External Traffic**: Always HTTPS (SSL/TLS encrypted)
- **Internal Traffic**: Always HTTP (no encryption needed on local network)
- **No Double Encryption**: Core Traefik terminates SSL, forwards plain HTTP internally

### Service Registration

When you deploy an additional server:
1. Services are deployed with exposed ports (no Traefik labels)
2. Core server creates YAML route files pointing to IP:PORT
3. Core Traefik loads routes automatically
4. Services become accessible at `https://servicename.hostname.yourdomain.duckdns.org`

### Key Benefits

- **Simplified Architecture**: No local Traefik on additional servers
- **Direct Port Access**: Services expose ports directly (no reverse proxy overhead)
- **Centralized Access**: All services accessed through one domain
- **Unified SSO**: Authelia on core server protects all services
- **Local Lazy Loading**: Sablier manages containers on each server independently

## Performance Considerations

- **Latency**: Direct routing (core → service) minimizes hops
- **Resource Usage**: Additional servers run only Sablier (~50MB) - no Traefik needed
- **Scalability**: Can add unlimited additional servers without complexity
- **Network**: Internal 1Gbps+ recommended between servers
- **Deployment Speed**: Additional servers deploy in ~2 minutes (vs 5-10 with local Traefik)

