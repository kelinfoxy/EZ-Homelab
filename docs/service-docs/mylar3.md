# Mylar3 - Comic Book Management

## Table of Contents
- [Overview](#overview)
- [What is Mylar3?](#what-is-mylar3)
- [Why Use Mylar3?](#why-use-mylar3)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)

## Overview

**Category:** Comic Book Management  
**Docker Image:** [linuxserver/mylar3](https://hub.docker.com/r/linuxserver/mylar3)  
**Default Stack:** `media-extended.yml`  
**Web UI:** `http://SERVER_IP:8090`  
**Ports:** 8090

## What is Mylar3?

Mylar3 is an automated comic book download manager. It's like Sonarr/Radarr but specifically designed for comic books. It tracks your favorite series, automatically downloads new issues when released, and organizes your comic collection with proper metadata and naming.

### Key Features
- **Series Tracking:** Monitor ongoing comic series
- **Automatic Downloads:** New issues downloaded automatically
- **Comic Vine Integration:** Accurate metadata
- **Weekly Pull Lists:** See this week's releases
- **Story Arc Support:** Track multi-series arcs
- **Quality Management:** Preferred file sizes and formats
- **File Organization:** Consistent naming and structure
- **Failed Download Handling:** Retry logic
- **Multiple Providers:** Torrent and Usenet
- **ComicRack/Ubooquity Integration:** Reader compatibility

## Why Use Mylar3?

1. **Never Miss Issues:** Auto-download weekly releases
2. **Series Management:** Track all your series
3. **Metadata Automation:** Comic Vine integration
4. **Organization:** Consistent file structure
5. **Weekly Pull Lists:** See what's new
6. **Story Arcs:** Track crossover events
7. **Quality Control:** Size and format preferences
8. **Free & Open Source:** No cost

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media-extended/mylar3/config/    # Configuration
/mnt/media/comics/                           # Comic library
/mnt/downloads/                              # Downloads

Comic Structure:
/mnt/media/comics/
  Series Name (Year)/
    Series Name #001 (Year).cbz
    Series Name #002 (Year).cbz
```

### Environment Variables

```bash
PUID=1000
PGID=1000
TZ=America/New_York
```

## Official Resources

- **GitHub:** https://github.com/mylar3/mylar3
- **Wiki:** https://github.com/mylar3/mylar3/wiki
- **Discord:** https://discord.gg/6UG94R7E8T

## Docker Configuration

```yaml
mylar3:
  image: linuxserver/mylar3:latest
  container_name: mylar3
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8090:8090"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media-extended/mylar3/config:/config
    - /mnt/media/comics:/comics
    - /mnt/downloads:/downloads
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.mylar3.rule=Host(`mylar3.${DOMAIN}`)"
    - "traefik.http.routers.mylar3.entrypoints=websecure"
    - "traefik.http.routers.mylar3.tls.certresolver=letsencrypt"
    - "traefik.http.routers.mylar3.middlewares=authelia@docker"
    - "traefik.http.services.mylar3.loadbalancer.server.port=8090"
```

## Initial Setup

1. **Start Container:**
   ```bash
   docker compose up -d mylar3
   ```

2. **Access UI:** `http://SERVER_IP:8090`

3. **Config Wizard:**
   - Comic Location: `/comics`
   - Download client: qBittorrent
   - Comic Vine API: Get from comicvine.gamespot.com/api
   - Search providers: Add torrent indexers

4. **Download Client:**
   - Settings → Download Settings → qBittorrent
   - Host: `gluetun`
   - Port: `8080`
   - Username/Password
   - Category: `comics-mylar`

5. **Comic Vine API:**
   - Register at comicvine.gamespot.com
   - Get API key
   - Settings → Comic Vine API key

6. **Add Series:**
   - Search for comic series
   - Select correct series
   - Set monitoring (all issues or future only)
   - Mylar searches automatically

### Weekly Pull List

**Pull List Tab:**
- Shows this week's comic releases
- For your monitored series
- One-click download

**Pull List Sources:**
- Comic Vine
- Marvel
- DC
- Image Comics

## Summary

Mylar3 is the comic book automation tool offering:
- Automatic issue downloads
- Series tracking
- Weekly pull lists
- Comic Vine metadata
- Story arc support
- Quality management
- Free and open-source

**Perfect for:**
- Comic book collectors
- Weekly release tracking
- Series completionists
- Digital comic readers
- Automated management

**Key Points:**
- Comic Vine API required
- Monitor ongoing series
- Weekly pull list feature
- Story arc tracking
- CBZ/CBR format support
- Integrates with comic readers

**File Formats:**
- CBZ (Comic Book ZIP)
- CBR (Comic Book RAR)
- Both supported by readers

**Remember:**
- Get Comic Vine API key
- Configure download client
- Add search providers
- Monitor series, not individual issues
- Check weekly pull list
- Story arcs tracked separately

Mylar3 automates your entire comic book collection!
