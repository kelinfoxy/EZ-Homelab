# Code Server - VS Code in Browser

## Table of Contents
- [Overview](#overview)
- [What is Code Server?](#what-is-code-server)
- [Why Use Code Server?](#why-use-code-server)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Development Environment  
**Docker Image:** [linuxserver/code-server](https://hub.docker.com/r/linuxserver/code-server)  
**Default Stack:** `utilities.yml` or `development.yml`  
**Web UI:** `https://code.${DOMAIN}` or `http://SERVER_IP:8443`  
**Ports:** 8443

## What is Code Server?

Code Server is VS Code running in your browser. Access your development environment from anywhere without installing anything. It's the full VS Code experience - extensions, settings, terminal - accessible via web browser.

### Key Features
- **VS Code:** Real VS Code, not a clone
- **Browser Access:** Any device, anywhere
- **Extensions:** Full extension support
- **Terminal:** Integrated terminal
- **Git:** Built-in Git support
- **Settings Sync:** Keep preferences
- **Collaborative:** Share sessions
- **Self-Hosted:** Your server
- **Free & Open Source:** No cost

## Why Use Code Server?

1. **Access Anywhere:** Code from any device
2. **No Installation:** Just browser needed
3. **Consistent:** Same environment everywhere
4. **Powerful:** Full VS Code features
5. **iPad Coding:** Code on tablets
6. **Remote Access:** Access home server
7. **Team Sharing:** Collaborative coding
8. **Self-Hosted:** Privacy and control

## Configuration in AI-Homelab

```
/opt/stacks/utilities/code-server/config/      # VS Code settings
/opt/stacks/utilities/code-server/workspace/   # Your projects
```

## Official Resources

- **Website:** https://coder.com/docs/code-server
- **GitHub:** https://github.com/coder/code-server
- **Documentation:** https://coder.com/docs

## Docker Configuration

```yaml
code-server:
  image: linuxserver/code-server:latest
  container_name: code-server
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8443:8443"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - PASSWORD=your_secure_password
    - SUDO_PASSWORD=sudo_password
  volumes:
    - /opt/stacks/utilities/code-server/config:/config
    - /opt/stacks:/workspace  # Your code
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.code-server.rule=Host(`code.${DOMAIN}`)"
```

## Summary

Code Server brings VS Code to your browser offering:
- Full VS Code in browser
- Extension support
- Integrated terminal
- Git integration
- Access from anywhere
- No local installation needed
- Self-hosted
- Free and open-source

**Perfect for:**
- Remote coding
- iPad/tablet development
- Consistent dev environment
- Team collaboration
- Cloud-based development
- Learning programming

**Key Points:**
- Real VS Code, not clone
- Extensions work
- Integrated terminal
- Git support
- Password protected
- Access via browser
- Mount your code directories

**Remember:**
- Set strong password
- HTTPS recommended
- Mount volumes for persistence
- Install extensions as needed
- Terminal has full access
- Save work regularly

Code Server puts VS Code everywhere!
