# Dozzle - Real-Time Docker Log Viewer

## Table of Contents
- [Overview](#overview)
- [What is Dozzle?](#what-is-dozzle)
- [Why Use Dozzle?](#why-use-dozzle)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Using Dozzle](#using-dozzle)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Infrastructure Monitoring  
**Docker Image:** [amir20/dozzle](https://hub.docker.com/r/amir20/dozzle)  
**Default Stack:** `infrastructure.yml`  
**Web UI:** `https://dozzle.${DOMAIN}`  
**Authentication:** Protected by Authelia (SSO)  
**Purpose:** Real-time container log viewing and searching

## What is Dozzle?

Dozzle is a lightweight, web-based Docker log viewer that provides real-time log streaming in a beautiful interface. It's designed to be simple, fast, and secure, requiring no database or complicated setup.

### Key Features
- **Real-Time Streaming:** Live log updates as they happen
- **Multi-Container View:** View logs from multiple containers simultaneously
- **Search & Filter:** Search through logs with regex support
- **Syntax Highlighting:** Colored log output for better readability
- **Dark/Light Theme:** Comfortable viewing in any environment
- **No Database:** Reads directly from Docker socket
- **Mobile Friendly:** Responsive design works on phones/tablets
- **Small Footprint:** ~15MB Docker image
- **Automatic Discovery:** Finds all containers automatically
- **Log Export:** Download logs for offline analysis
- **Authentication:** Built-in auth or use reverse proxy
- **Multi-Host Support:** Monitor logs from multiple Docker hosts

## Why Use Dozzle?

1. **Quick Troubleshooting:** Instantly see container errors
2. **No SSH Required:** Check logs from anywhere via web browser
3. **Lightweight:** Uses minimal resources
4. **Beautiful Interface:** Better than `docker logs` command
5. **Real-Time:** See logs as they happen
6. **Search:** Find specific errors quickly
7. **Multi-Container:** Monitor multiple services at once
8. **Easy Access:** No CLI needed for non-technical users
9. **Mobile Access:** Check logs from phone
10. **Free & Open Source:** No licensing costs

## How It Works

```
Docker Containers → Docker Engine (logging driver)
                         ↓
                   Docker Socket (/var/run/docker.sock)
                         ↓
                    Dozzle Container
                         ↓
                    Web Interface (Real-time streaming)
                         ↓
                    Browser (You)
```

### Log Flow

1. **Containers write logs:** Applications output to stdout/stderr
2. **Docker captures logs:** Stored by Docker logging driver
3. **Dozzle reads socket:** Connects to Docker socket
4. **Real-time streaming:** Logs pushed to browser via WebSockets
5. **Display in UI:** Formatted, colored, searchable logs

### No Storage Required

- Dozzle doesn't store logs
- Reads directly from Docker
- Container logs stored in Docker's logging driver
- Dozzle just provides a viewing interface

## Configuration in AI-Homelab

### Directory Structure

```
# Dozzle doesn't require persistent storage
# All configuration via environment variables or command flags
```

### Environment Variables

```bash
# No authentication (use Authelia instead)
DOZZLE_NO_ANALYTICS=true

# Hostname display
DOZZLE_HOSTNAME=homelab-server

# Base path (if behind reverse proxy)
DOZZLE_BASE=/

# Timezone
TZ=America/New_York
```

## Official Resources

- **Website:** https://dozzle.dev
- **GitHub:** https://github.com/amir20/dozzle
- **Docker Hub:** https://hub.docker.com/r/amir20/dozzle
- **Documentation:** https://dozzle.dev/guide/
- **Live Demo:** https://dozzle.dev/demo

## Educational Resources

### Videos
- [Dozzle - Docker Log Viewer (Techno Tim)](https://www.youtube.com/watch?v=RMm3cJSrI0s)
- [Best Docker Log Viewer? Dozzle Review](https://www.youtube.com/results?search_query=dozzle+docker+logs)
- [Docker Logging Best Practices](https://www.youtube.com/watch?v=1S3w5vERFIc)

### Articles & Guides
- [Dozzle Official Documentation](https://dozzle.dev/guide/)
- [Docker Logging Drivers](https://docs.docker.com/config/containers/logging/configure/)
- [Docker Logs Best Practices](https://docs.docker.com/config/containers/logging/)

### Concepts to Learn
- **Container Logs:** stdout/stderr output from containers
- **Docker Logging Drivers:** json-file, syslog, journald, etc.
- **Log Rotation:** Managing log file sizes
- **WebSockets:** Real-time browser communication
- **Docker Socket:** Unix socket for Docker API
- **Log Levels:** DEBUG, INFO, WARN, ERROR
- **Regex:** Pattern matching for log searching

## Docker Configuration

### Complete Service Definition

```yaml
dozzle:
  image: amir20/dozzle:latest
  container_name: dozzle
  restart: unless-stopped
  networks:
    - traefik-network
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  environment:
    - DOZZLE_NO_ANALYTICS=true
    - DOZZLE_HOSTNAME=homelab-server
    - TZ=America/New_York
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.dozzle.rule=Host(`dozzle.${DOMAIN}`)"
    - "traefik.http.routers.dozzle.entrypoints=websecure"
    - "traefik.http.routers.dozzle.tls.certresolver=letsencrypt"
    - "traefik.http.routers.dozzle.middlewares=authelia@docker"
    - "traefik.http.services.dozzle.loadbalancer.server.port=8080"
```

### Important Notes

1. **Docker Socket:** Read-only access sufficient
2. **Port 8080:** Default Dozzle web interface port
3. **No Ports Exposed:** Access only via Traefik
4. **Authelia Required:** No built-in auth, use Authelia

## Using Dozzle

### Interface Overview

**Main Screen:**
- List of all containers
- Status (running/stopped)
- Container names
- Click to view logs

**Container View:**
- Real-time log streaming
- Search box at top
- Timestamp toggle
- Download button
- Container stats
- Multi-container tabs

### Viewing Logs

**Single Container:**
1. Click container name
2. Logs stream in real-time
3. Auto-scrolls to bottom
4. Click timestamp to stop auto-scroll

**Multiple Containers:**
1. Click first container
2. Click "+" button
3. Select additional containers
4. View logs side-by-side or merged

### Searching Logs

**Basic Search:**
1. Type in search box
2. Press Enter
3. Matching lines highlighted
4. Navigate with arrow buttons

**Advanced Search (Regex):**
```regex
# Find errors
error|fail|exception

# Find specific IP
192\.168\.1\..*

# Find HTTP codes
HTTP/[0-9]\.[0-9]" [45][0-9]{2}

# Case insensitive
(?i)warning
```

### Filtering Options

**Filter by:**
- Container name
- Log content
- Time range (scroll to older logs)
- Log level (if structured logs)

### Log Export

**Download Logs:**
1. View container logs
2. Click download icon
3. Choose time range
4. Save as text file

### Interface Features

**Toolbar:**
- 🔍 Search box
- ⏸️ Pause auto-scroll
- ⬇️ Download logs
- 🕐 Toggle timestamps
- ⚙️ Settings
- 🌙 Dark/Light mode toggle

**Keyboard Shortcuts:**
- `/` - Focus search
- `Esc` - Clear search
- `Space` - Pause/Resume scroll
- `g` - Scroll to top
- `G` - Scroll to bottom

## Advanced Topics

### Multi-Host Monitoring

Monitor Docker on multiple servers:

**Remote Host Requirements:**
```yaml
# On remote server - expose Docker socket via TCP (secure)
# Or use Dozzle agent

# Agent on remote server:
dozzle-agent:
  image: amir20/dozzle:latest
  command: agent
  environment:
    - DOZZLE_AGENT_KEY=your-secret-key
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
```

**Main Dozzle:**
```yaml
dozzle:
  environment:
    - DOZZLE_REMOTE_HOST=tcp://remote-server:2376
    # Or for agent:
    - DOZZLE_AGENT_KEY=your-secret-key
```

### Custom Filters

Filter containers by labels:

```yaml
dozzle:
  environment:
    - DOZZLE_FILTER=status=running
    - DOZZLE_FILTER=label=com.docker.compose.project=media
```

**Hide Containers:**
```yaml
mycontainer:
  labels:
    - "dozzle.enable=false"  # Hide from Dozzle
```

### Authentication

**Built-in Simple Auth (Alternative to Authelia):**
```yaml
dozzle:
  environment:
    - DOZZLE_USERNAME=admin
    - DOZZLE_PASSWORD=secure-password
    - DOZZLE_KEY=random-32-character-key-for-cookies
```

Generate key:
```bash
openssl rand -hex 16
```

### Base Path Configuration

If running behind reverse proxy with subpath:

```yaml
dozzle:
  environment:
    - DOZZLE_BASE=/dozzle
```

Then access at: `https://domain.com/dozzle`

### Log Level Filtering

Show only specific log levels:

```yaml
dozzle:
  environment:
    - DOZZLE_LEVEL=info  # Only info and above
```

Levels: `trace`, `debug`, `info`, `warn`, `error`

### Container Grouping

Group containers by label:

```yaml
# In compose file:
plex:
  labels:
    - "dozzle.group=media"

sonarr:
  labels:
    - "dozzle.group=media"

# Dozzle will group them together
```

## Troubleshooting

### Dozzle Not Showing Containers

```bash
# Check if Dozzle can access Docker socket
docker exec dozzle ls -la /var/run/docker.sock

# Verify containers are running
docker ps

# Check Dozzle logs
docker logs dozzle

# Test socket access
docker exec dozzle docker ps
```

### Logs Not Updating

```bash
# Check container is producing logs
docker logs container-name

# Verify WebSocket connection
# Open browser console: F12 → Network → WS
# Should see WebSocket connection

# Check browser console for errors
# F12 → Console

# Try different browser
# Some corporate firewalls block WebSockets
```

### Can't Access Web Interface

```bash
# Check if Dozzle is running
docker ps | grep dozzle

# Check Traefik routing
docker logs traefik | grep dozzle

# Test direct access (if port exposed)
curl http://localhost:8080

# Check network connectivity
docker exec dozzle ping traefik
```

### Search Not Working

```bash
# Clear browser cache
# Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)

# Check search syntax
# Use proper regex escaping

# Try simple text search first
# Then progress to regex

# Check browser console for JavaScript errors
```

### High Memory Usage

```bash
# Check Dozzle stats
docker stats dozzle

# Viewing many containers at once increases memory
# Close unnecessary container tabs

# Restart Dozzle
docker restart dozzle

# Limit containers with filters
DOZZLE_FILTER=status=running
```

### Logs Cut Off / Incomplete

```bash
# Docker has log size limits
# Check logging driver config

# View Docker daemon log config
docker info | grep -A5 "Logging Driver"

# Configure log rotation (in daemon.json):
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

## Docker Logging Configuration

### Logging Drivers

**JSON File (Default):**
```yaml
services:
  myapp:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

**Syslog:**
```yaml
services:
  myapp:
    logging:
      driver: syslog
      options:
        syslog-address: "tcp://192.168.1.1:514"
```

**Journald:**
```yaml
services:
  myapp:
    logging:
      driver: journald
```

### Log Rotation

**Global Configuration:**
```bash
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "compress": "true"
  }
}

# Restart Docker
sudo systemctl restart docker
```

**Per-Container:**
```yaml
services:
  myapp:
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "5"
```

### Best Practices

1. **Set Max Size:** Prevent disk space issues
2. **Rotate Logs:** Keep 3-5 recent files
3. **Compress Old Logs:** Save disk space
4. **Structured Logging:** JSON format for better parsing
5. **Log Levels:** Use appropriate levels (debug, info, error)
6. **Sensitive Data:** Never log passwords or secrets

## Performance Optimization

### Reduce Log Volume

```yaml
services:
  myapp:
    environment:
      # Reduce log verbosity
      - LOG_LEVEL=warn  # Only warnings and errors
```

### Limit Containers

```yaml
dozzle:
  environment:
    # Only show running containers
    - DOZZLE_FILTER=status=running
    
    # Only specific projects
    - DOZZLE_FILTER=label=com.docker.compose.project=media
```

### Disable Analytics

```yaml
dozzle:
  environment:
    - DOZZLE_NO_ANALYTICS=true
```

## Security Considerations

1. **Protect with Authelia:** Never expose Dozzle publicly without auth
2. **Read-Only Socket:** Use `:ro` for Docker socket mount
3. **Use Docker Proxy:** Consider Docker Socket Proxy for extra security
4. **Network Isolation:** Keep on trusted network
5. **Log Sanitization:** Ensure logs don't contain secrets
6. **HTTPS Only:** Always use SSL/TLS
7. **Limited Access:** Only give access to trusted users
8. **Monitor Access:** Review who accesses logs
9. **Log Retention:** Don't keep logs longer than necessary
10. **Regular Updates:** Keep Dozzle updated

## Comparison with Alternatives

### Dozzle vs Portainer Logs

**Dozzle:**
- Specialized for logs
- Real-time streaming
- Better search/filter
- Lighter weight
- Multiple containers simultaneously

**Portainer:**
- Full Docker management
- Logs + container control
- More features
- Heavier resource usage

### Dozzle vs CLI (docker logs)

**Dozzle:**
- Web interface
- Multi-container view
- Search functionality
- No SSH needed
- User-friendly

**CLI:**
- Scriptable
- More control
- No additional resources
- Faster for experts

### Dozzle vs Loki/Grafana

**Dozzle:**
- Simple setup
- No database
- Real-time only
- Lightweight

**Loki/Grafana:**
- Log aggregation
- Long-term storage
- Advanced querying
- Complex setup
- Enterprise features

## Tips & Tricks

### Quick Container Access

**Bookmark Specific Containers:**
```
https://dozzle.yourdomain.com/show?name=plex
https://dozzle.yourdomain.com/show?name=sonarr
```

### Multi-Container Monitoring

Monitor entire stack:
```
https://dozzle.yourdomain.com/show?name=plex&name=sonarr&name=radarr
```

### Color-Coded Logs

If your app supports colored output:
```yaml
myapp:
  environment:
    - FORCE_COLOR=true
    - TERM=xterm-256color
```

### Regular Expressions Cheat Sheet

```regex
# Find errors
error|exception|fail

# Find warnings
warn|warning|caution

# Find IP addresses
\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}

# Find URLs
https?://[^\s]+

# Find timestamps
\d{4}-\d{2}-\d{2}

# Case insensitive
(?i)search_term
```

## Summary

Dozzle is a simple, lightweight tool for viewing Docker container logs. It provides:
- Beautiful web interface for log viewing
- Real-time log streaming
- Multi-container support
- Search and filter capabilities
- No database or complex setup required
- Minimal resource usage

**Perfect for:**
- Quick troubleshooting
- Development environments
- Non-technical user access
- Mobile log viewing
- Real-time monitoring

**Not ideal for:**
- Long-term log storage
- Advanced log analysis
- Log aggregation across many hosts
- Compliance/audit requirements

**Remember:**
- Protect with Authelia
- Use read-only Docker socket
- Configure log rotation
- Monitor disk space
- Logs are ephemeral (not stored by Dozzle)
- Great complement to Grafana/Loki for detailed analysis
