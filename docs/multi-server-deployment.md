# Multi-Server Deployment with On-Demand Services

## Overview

This guide explains the **current multi-server architecture** where:
- **Core Server**: Handles external traffic (ports 80/443); runs DuckDNS, Traefik (multi-provider), Authelia
- **Remote Servers**: Run their own Traefik (local-only) and Sablier (local containers)
- **No Docker API**: Servers communicate via HTTP/HTTPS; no TLS Docker API connections needed
- **Independent Management**: Each server manages its own containers with lazy loading

> **Note**: This document describes the current simplified architecture. For the legacy centralized Sablier approach, see the git history.

## Architecture Diagram

```
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
    Ports  │  HTTP/HTTPS  │              │
    80/443 │              │              │
           ▼              ▼              ▼
    ┌─────────────────────────────────────────┐
    │         REMOTE SERVER (e.g., Pi)        │
    │  ┌──────────┐  ┌──────────┐  ┌───────┐ │
    │  │ Traefik  │  │ Sablier  │  │ Media │ │
    │  │ (local)  │  │ (local)  │  │ Apps  │ │
    │  └──────────┘  └──────────┘  └───────┘ │
    └─────────────────────────────────────────┘
```

# Deployment Process

## Step 1: Deploy Core Server

On the core server, run `ez-homelab.sh`  
* Use Option 1 to Install Prerequesites
* Then Option 2 to Deploy Core Server

This deploys:  DuckDNS, Traefik(core), Authelia, Dashboards & Infrastructure

From Dockge you can start/stop any of the stacks or containers.

**Port Forwarding**:
- Forward ports 80 & 443 from your router
- Only this server requires port forwarding

## Step 2: Deploy Remote Server

On the remote server, run `ez-homelab.sh`  
* Use Option 1 to Install Prerequesites
* Then Option 3 to Deploy Remote Server

This deploys:  Traefik(local), Dashboards & Infrastructure

From Dockge you can start/stop any of the stacks or containers.

## How It Works

### Traffic Flow

1. **User accesses** `https://sonarr.yourdomain.duckdns.org`
2. **Core Traefik** receives request:
   - Checks Authelia for authentication (SSO)
   - Routes to remote server: `http://192.168.1.100:8989`
3. **Remote Traefik** receives forwarded request:
   - Discovers service is stopped (lazy loaded)
   - Forwards to local Sablier
4. **Remote Sablier**:
   - Starts Sonarr container
   - Shows loading page
   - Redirects to service when ready
5. **Service responds** through the chain back to user

### Key Benefits

- **Independent Management**: Each server controls its own containers
- **Centralized Access**: All services accessed through one domain
- **Unified SSO**: Authelia on core server protects all services
- **Local Lazy Loading**: Sablier manages containers on the same server

## Performance Considerations

- **Latency**: One additional hop (core → remote) adds minimal latency
- **Resource Usage**: Each server runs lightweight Traefik + Sablier (~100MB combined)
- **Scalability**: Can add unlimited remote servers without complexity
- **Network**: Internal 1Gbps+ recommended between servers

