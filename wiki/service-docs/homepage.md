# Homepage - Application Dashboard

## Table of Contents
- [Overview](#overview)
- [What is Homepage?](#what-is-homepage)
- [Why Use Homepage?](#why-use-homepage)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Configuration Guide](#configuration-guide)
- [Widgets and Integrations](#widgets-and-integrations)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Dashboard  
**Docker Image:** [ghcr.io/gethomepage/homepage](https://github.com/gethomepage/homepage/pkgs/container/homepage)  
**Default Stack:** `dashboards.yml`  
**Web UI:** `https://homepage.${DOMAIN}` or `http://SERVER_IP:3000`  
**Authentication:** Optional (use Authelia for protection)  
**Purpose:** Unified dashboard for all homelab services

## What is Homepage?

Homepage is a modern, highly customizable application dashboard designed for homelabs. It provides a clean interface to access all your services with real-time status monitoring, API integrations, and customizable widgets.

### Key Features
- **Service Cards:** Organize services with icons, descriptions, and links
- **Live Status:** Health checks and uptime monitoring
- **API Integrations:** Real-time data from 100+ services
- **Widgets:** Weather, Docker stats, system resources, bookmarks
- **Customizable:** YAML-based configuration
- **Fast & Lightweight:** Minimal resource usage
- **Modern UI:** Clean, responsive design
- **Dark/Light Mode:** Theme options
- **Search:** Quick service filtering
- **Docker Integration:** Auto-discover containers
- **Bookmarks:** Quick links and resources
- **Multi-Language:** i18n support

## Why Use Homepage?

1. **Central Hub:** Single page for all homelab services
2. **Visual Overview:** See everything at a glance
3. **Status Monitoring:** Know which services are up/down
4. **Quick Access:** Fast navigation to services
5. **Beautiful Design:** Modern, polished interface
6. **Easy Configuration:** Simple YAML files
7. **Active Development:** Regular updates and improvements
8. **API Integration:** Real-time service stats
9. **Customizable:** Tailor to your needs
10. **Free & Open Source:** Community-driven

## How It Works

```
User → Browser → Homepage Dashboard
                      ↓
            ┌─────────┴─────────┐
            ↓                   ↓
     Service Cards          Widgets
     (with icons)         (live data)
            ↓                   ↓
     Click to access     API integrations
     service URL        (Plex, Sonarr, etc.)
```

### Architecture

**Configuration Structure:**
```
/config/
├── settings.yaml    # Global settings
├── services.yaml    # Service definitions
├── widgets.yaml     # Dashboard widgets
├── bookmarks.yaml   # Quick links
├── docker.yaml      # Docker integration
└── custom.css       # Custom styling (optional)
```

**Data Flow:**
1. **Homepage loads** configuration files
2. **Renders dashboard** with service cards
3. **Makes API calls** to configured services
4. **Displays live data** in widgets
5. **Health checks** verify service status
6. **Updates in real-time** (configurable interval)

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/dashboards/homepage/config/
├── settings.yaml
├── services.yaml
├── widgets.yaml
├── bookmarks.yaml
└── docker.yaml
```

### Environment Variables

```bash
# Optional: Custom port
PORT=3000

# Optional: Puid/Pgid for permissions
PUID=1000
PGID=1000
```

## Official Resources

- **Website:** https://gethomepage.dev
- **GitHub:** https://github.com/gethomepage/homepage
- **Documentation:** https://gethomepage.dev/en/installation/
- **Widgets Guide:** https://gethomepage.dev/en/widgets/
- **Service Integrations:** https://gethomepage.dev/en/widgets/services/
- **Discord:** https://discord.gg/k4ruYNrudu

## Educational Resources

### Videos
- [Homepage - The BEST Homelab Dashboard (Techno Tim)](https://www.youtube.com/watch?v=_MxpGN8eS4U)
- [Homepage Setup Guide (DB Tech)](https://www.youtube.com/watch?v=N9dQKJMrjZM)
- [Homepage vs Homarr vs Heimdall](https://www.youtube.com/results?search_query=homepage+vs+homarr)
- [Customizing Homepage Dashboard](https://www.youtube.com/results?search_query=homepage+dashboard+customization)

### Articles & Guides
- [Homepage Official Documentation](https://gethomepage.dev)
- [Service Widget Configuration](https://gethomepage.dev/en/widgets/services/)
- [Docker Integration Guide](https://gethomepage.dev/en/configs/docker/)
- [Customization Tips](https://gethomepage.dev/en/configs/custom-css-js/)

### Concepts to Learn
- **YAML Configuration:** Structured data format
- **API Integration:** RESTful service communication
- **Health Checks:** Service availability monitoring
- **Widgets:** Modular dashboard components
- **Docker Labels:** Metadata for auto-discovery
- **Reverse Proxy:** Accessing services through dashboard

## Docker Configuration

### Complete Service Definition

```yaml
homepage:
  image: ghcr.io/gethomepage/homepage:latest
  container_name: homepage
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "3000:3000"
  volumes:
    - /opt/stacks/dashboards/homepage/config:/app/config
    - /var/run/docker.sock:/var/run/docker.sock:ro  # For Docker integration
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.homepage.rule=Host(`${DOMAIN}`) || Host(`homepage.${DOMAIN}`)"
    - "traefik.http.routers.homepage.entrypoints=websecure"
    - "traefik.http.routers.homepage.tls.certresolver=letsencrypt"
    - "traefik.http.services.homepage.loadbalancer.server.port=3000"
```

## Configuration Guide

### settings.yaml

```yaml
---
# Global settings
title: My Homelab
background: /images/background.jpg  # Optional
cardBlur: md  # sm, md, lg
theme: dark  # dark, light, auto
color: slate  # slate, gray, zinc, neutral, stone, red, etc.

# Layout
layout:
  Media:
    style: row
    columns: 4
  Infrastructure:
    style: row
    columns: 3

# Quick search
quicklaunch:
  searchDescriptions: true
  hideInternetSearch: true

# Header widgets (shown at top)
headerStyle: clean  # boxed, clean
```

### services.yaml

```yaml
---
# Service groups and cards

- Media:
    - Plex:
        icon: plex.png
        href: https://plex.yourdomain.com
        description: Media Server
        widget:
          type: plex
          url: http://plex:32400
          key: your-plex-token
          
    - Sonarr:
        icon: sonarr.png
        href: https://sonarr.yourdomain.com
        description: TV Show Management
        widget:
          type: sonarr
          url: http://sonarr:8989
          key: your-sonarr-api-key
          
    - Radarr:
        icon: radarr.png
        href: https://radarr.yourdomain.com
        description: Movie Management
        widget:
          type: radarr
          url: http://radarr:7878
          key: your-radarr-api-key
          
    - qBittorrent:
        icon: qbittorrent.png
        href: https://qbit.yourdomain.com
        description: Torrent Client
        widget:
          type: qbittorrent
          url: http://gluetun:8080
          username: admin
          password: adminpass

- Infrastructure:
    - Dockge:
        icon: dockge.png
        href: https://dockge.yourdomain.com
        description: Stack Manager
        
    - Portainer:
        icon: portainer.png
        href: https://portainer.yourdomain.com
        description: Docker Management
        
    - Traefik:
        icon: traefik.png
        href: https://traefik.yourdomain.com
        description: Reverse Proxy
        widget:
          type: traefik
          url: http://traefik:8080

- Monitoring:
    - Glances:
        icon: glances.png
        href: https://glances.yourdomain.com
        description: System Monitor
        widget:
          type: glances
          url: http://glances:61208
          
    - Uptime Kuma:
        icon: uptime-kuma.png
        href: https://uptime.yourdomain.com
        description: Uptime Monitor
```

### widgets.yaml

```yaml
---
# Dashboard widgets (shown above services)

- logo:
    icon: /icons/logo.png  # Optional custom logo

- search:
    provider: google
    target: _blank

- datetime:
    text_size: xl
    format:
      timeStyle: short
      dateStyle: short

- resources:
    cpu: true
    memory: true
    disk: /
    cputemp: true
    uptime: true
    label: Server

- openmeteo:
    label: Home
    latitude: 40.7128
    longitude: -74.0060
    units: imperial
    cache: 5

- greeting:
    text_size: xl
    text: Welcome to my Homelab!
```

### bookmarks.yaml

```yaml
---
# Quick links and bookmarks

- Developer:
    - GitHub:
        - icon: github.png
          href: https://github.com
    - GitLab:
        - icon: gitlab.png
          href: https://gitlab.com

- Documentation:
    - Homepage Docs:
        - icon: homepage.png
          href: https://gethomepage.dev
    - Docker Docs:
        - icon: docker.png
          href: https://docs.docker.com

- Social:
    - Reddit:
        - icon: reddit.png
          href: https://reddit.com/r/homelab
    - Discord:
        - icon: discord.png
          href: https://discord.gg/homelab
```

### docker.yaml

```yaml
---
# Auto-discover Docker containers

my-docker:
  host: docker-proxy  # Use socket proxy for security
  port: 2375
  # Or direct socket (less secure):
  # socket: /var/run/docker.sock
```

Then add to services.yaml:
```yaml
- Docker:
    - My Container:
        icon: docker.png
        description: Auto-discovered container
        server: my-docker
        container: container-name
```

## Widgets and Integrations

### Service Widgets

**Popular Integrations:**

**Plex:**
```yaml
widget:
  type: plex
  url: http://plex:32400
  key: your-plex-token  # Get from Plex Web → Settings → Network → Show Advanced
```

**Sonarr/Radarr:**
```yaml
widget:
  type: sonarr
  url: http://sonarr:8989
  key: your-api-key  # Settings → General → API Key
```

**qBittorrent:**
```yaml
widget:
  type: qbittorrent
  url: http://gluetun:8080
  username: admin
  password: adminpass
```

**Pi-hole:**
```yaml
widget:
  type: pihole
  url: http://pihole:80
  key: your-api-key  # Settings → API → Show API token
```

**Traefik:**
```yaml
widget:
  type: traefik
  url: http://traefik:8080
```

**AdGuard Home:**
```yaml
widget:
  type: adguard
  url: http://adguard:80
  username: admin
  password: adminpass
```

### Information Widgets

**Weather:**
```yaml
- openmeteo:
    label: Home
    latitude: 40.7128
    longitude: -74.0060
    units: imperial  # or metric
    cache: 5
```

**System Resources:**
```yaml
- resources:
    cpu: true
    memory: true
    disk: /
    cputemp: true
    uptime: true
    label: Server
```

**Docker Stats:**
```yaml
- docker:
    server: my-docker
    show: running  # or all
```

**Glances:**
```yaml
- glances:
    url: http://glances:61208
    cpu: true
    mem: true
    process: true
```

### Custom Widgets

```yaml
- customapi:
    url: http://myapi.local/endpoint
    refreshInterval: 60000  # 60 seconds
    display: text  # or list, block
    mappings:
      - field: data.value
        label: My Value
        format: text
```

## Advanced Topics

### Custom CSS

Create `/config/custom.css`:
```css
/* Custom background */
body {
  background-image: url('/images/custom-bg.jpg');
  background-size: cover;
}

/* Larger service cards */
.service-card {
  min-height: 150px;
}

/* Custom colors */
:root {
  --color-primary: #1e40af;
  --color-secondary: #7c3aed;
}

/* Hide specific elements */
.some-class {
  display: none;
}
```

### Custom JavaScript

Create `/config/custom.js`:
```javascript
// Custom functionality
console.log('Homepage loaded!');

// Example: Auto-refresh every 5 minutes
setTimeout(() => {
  window.location.reload();
}, 300000);
```

### Multi-Column Layouts

```yaml
layout:
  Media:
    style: row
    columns: 4
  Infrastructure:
    style: column
    columns: 2
  Monitoring:
    style: row
    columns: 3
```

### Custom Icons

Place icons in `/config/icons/`:
```
/config/icons/
├── custom-icon1.png
├── custom-icon2.svg
└── custom-icon3.jpg
```

Reference in services:
```yaml
- My Service:
    icon: /icons/custom-icon1.png
```

### Docker Auto-Discovery

Automatically add containers with labels:

```yaml
# In container compose file
my-service:
  labels:
    - "homepage.group=Media"
    - "homepage.name=My Service"
    - "homepage.icon=service-icon.png"
    - "homepage.href=https://service.domain.com"
    - "homepage.description=My awesome service"
```

### Ping Health Checks

```yaml
- My Service:
    icon: service.png
    href: https://service.domain.com
    ping: https://service.domain.com
    # Shows green/red status indicator
```

### Custom API Widgets

```yaml
- customapi:
    url: http://api.local/stats
    refreshInterval: 30000
    display: block
    mappings:
      - field: users
        label: Active Users
        format: number
      - field: status
        label: Status
        format: text
```

## Troubleshooting

### Homepage Not Loading

```bash
# Check if container is running
docker ps | grep homepage

# View logs
docker logs homepage

# Check port
curl http://localhost:3000

# Verify Traefik routing
docker logs traefik | grep homepage
```

### Service Widgets Not Showing Data

```bash
# Check API connectivity
docker exec homepage curl http://service:port

# Verify API key is correct
# Check service logs for auth errors

# Test API manually
curl -H "X-Api-Key: your-key" http://service:port/api/endpoint

# Check Homepage logs for errors
docker logs homepage | grep -i error
```

### Configuration Changes Not Applied

```bash
# Homepage auto-reloads config files
# Wait 10-20 seconds

# Or restart container
docker restart homepage

# Check YAML syntax
# Use online YAML validator

# View Homepage logs
docker logs homepage | grep -i config
```

### Docker Socket Permission Error

```bash
# Fix socket permissions
sudo chmod 666 /var/run/docker.sock

# Or use Docker Socket Proxy (recommended)
# See docker-proxy.md

# Check mount
docker inspect homepage | grep -A5 Mounts
```

### Icons Not Displaying

```bash
# Homepage uses icon CDN by default
# Check internet connectivity

# Use local icons instead
# Place in /config/icons/

# Clear browser cache
# Hard refresh: Ctrl+Shift+R

# Check icon name matches service
# List available icons: https://github.com/walkxcode/dashboard-icons
```

### High CPU/Memory Usage

```bash
# Check container stats
docker stats homepage

# Reduce API polling frequency
# In services.yaml, add cache settings

# Disable unnecessary widgets

# Check for network issues
docker logs homepage | grep timeout
```

## Performance Optimization

### Reduce API Calls

```yaml
# Increase refresh intervals
widget:
  type: sonarr
  url: http://sonarr:8989
  key: api-key
  refreshInterval: 300000  # 5 minutes instead of default 10 seconds
```

### Cache Configuration

```yaml
# In settings.yaml
cache:
  size: 100  # Number of cached responses
  ttl: 300   # Cache time in seconds
```

### Lazy Loading

```yaml
# In settings.yaml
lazyLoad: true  # Load images as they scroll into view
```

## Customization Tips

### Color Themes

Available colors: `slate`, `gray`, `zinc`, `neutral`, `stone`, `red`, `orange`, `amber`, `yellow`, `lime`, `green`, `emerald`, `teal`, `cyan`, `sky`, `blue`, `indigo`, `violet`, `purple`, `fuchsia`, `pink`, `rose`

```yaml
color: blue
theme: dark
```

### Background Images

```yaml
background: /images/my-background.jpg
backgroundBlur: sm  # sm, md, lg, xl
backgroundSaturate: 50  # 0-100
backgroundBrightness: 50  # 0-100
```

### Card Appearance

```yaml
cardBlur: md  # sm, md, lg, xl
hideVersion: true
showStats: true
```

### Custom Greeting

```yaml
- greeting:
    text_size: xl
    text: "Welcome back, {{name}}!"
```

## Integration Examples

### Complete Media Stack

```yaml
- Media Server:
    - Plex:
        icon: plex.png
        href: https://plex.domain.com
        widget:
          type: plex
          url: http://plex:32400
          key: token
    
    - Jellyfin:
        icon: jellyfin.png
        href: https://jellyfin.domain.com
        widget:
          type: jellyfin
          url: http://jellyfin:8096
          key: api-key

- Media Management:
    - Sonarr:
        icon: sonarr.png
        href: https://sonarr.domain.com
        widget:
          type: sonarr
          url: http://sonarr:8989
          key: api-key
    
    - Radarr:
        icon: radarr.png
        href: https://radarr.domain.com
        widget:
          type: radarr
          url: http://radarr:7878
          key: api-key
    
    - Prowlarr:
        icon: prowlarr.png
        href: https://prowlarr.domain.com
        widget:
          type: prowlarr
          url: http://prowlarr:9696
          key: api-key
```

## Summary

Homepage provides a beautiful, functional dashboard for your homelab. It offers:
- Clean, modern interface
- Real-time service monitoring
- API integrations for live data
- Easy YAML configuration
- Highly customizable
- Active development and community

**Perfect for:**
- Homelab landing page
- Service overview
- Quick access portal
- Status monitoring
- Aesthetic presentation

**Best Practices:**
- Use Authelia for authentication if exposed
- Configure API widgets for live data
- Organize services into logical groups
- Use custom icons for consistency
- Enable Docker integration for automation
- Regular config backups
- Keep updated for new features

**Remember:**
- YAML syntax matters (indentation!)
- Test API connections before configuring widgets
- Use Docker Socket Proxy for security
- Customize colors and themes to preference
- Start simple, add complexity gradually
- Homepage is your homelab's front door - make it welcoming!
