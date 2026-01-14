# Unmanic - Library Optimization

## Table of Contents
- [Overview](#overview)
- [What is Unmanic?](#what-is-unmanic)
- [Why Use Unmanic?](#why-use-unmanic)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Media Optimization  
**Docker Image:** [josh5/unmanic](https://hub.docker.com/r/josh5/unmanic)  
**Default Stack:** `media-extended.yml`  
**Web UI:** `https://unmanic.${DOMAIN}` or `http://SERVER_IP:8888`  
**Authentication:** Optional  
**Ports:** 8888

## What is Unmanic?

Unmanic is a library optimizer designed to automate file management and transcoding tasks. Unlike Tdarr (which processes entire libraries), Unmanic focuses on continuous optimization - it watches your media library and processes new files as they arrive. It's perfect for maintaining consistent quality and format standards automatically.

### Key Features
- **File Watcher:** Automatic processing of new files
- **Plugin System:** Extensible workflows
- **Hardware Acceleration:** GPU transcoding support
- **Container Conversion:** Automatic remuxing
- **Audio/Subtitle Management:** Track manipulation
- **Queue Management:** Priority handling
- **Statistics Dashboard:** Processing metrics
- **Multiple Libraries:** Independent configurations
- **Remote Workers:** Distributed processing
- **Pause/Resume:** Flexible scheduling

## Why Use Unmanic?

1. **Automatic Processing:** New files handled immediately
2. **Consistent Quality:** Enforce library standards
3. **Space Optimization:** Convert to efficient codecs
4. **Format Standardization:** All files same container
5. **Hardware Acceleration:** Fast GPU transcoding
6. **Plugin Ecosystem:** Pre-built workflows
7. **Simple Setup:** Easier than Tdarr for basic tasks
8. **Free & Open Source:** No cost
9. **Active Development:** Regular updates
10. **Docker Ready:** Easy deployment

## How It Works

```
New File Added to Library
        ↓
Unmanic Detects File (File Watcher)
        ↓
Applies Configured Plugins
        ↓
Queues for Processing
        ↓
Worker Processes File
        ↓
Output File Created
        ↓
Replaces Original
        ↓
Library Optimized
```

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media-management/unmanic/config/    # Configuration
/mnt/media/movies/                            # Movie library
/mnt/media/tv/                               # TV library
/tmp/unmanic/                                # Temp files
```

### Environment Variables

```bash
# User permissions
PUID=1000
PGID=1000

# Timezone
TZ=America/New_York
```

## Official Resources

- **Website:** https://unmanic.app
- **Documentation:** https://docs.unmanic.app
- **GitHub:** https://github.com/Unmanic/unmanic
- **Discord:** https://discord.gg/wpShMzf
- **Forum:** https://forum.unmanic.app

## Educational Resources

### Videos
- [Unmanic Setup Guide](https://www.youtube.com/results?search_query=unmanic+setup)
- [Unmanic vs Tdarr](https://www.youtube.com/results?search_query=unmanic+vs+tdarr)

### Articles & Guides
- [Official Docs](https://docs.unmanic.app)
- [Plugin Library](https://unmanic.app/plugins)

### Concepts to Learn
- **File Watching:** Real-time monitoring
- **Plugin Workflows:** Sequential processing
- **Hardware Transcoding:** GPU acceleration
- **Container Remuxing:** Format conversion without re-encoding
- **Worker Pools:** Parallel processing

## Docker Configuration

### Complete Service Definition

```yaml
unmanic:
  image: josh5/unmanic:latest
  container_name: unmanic
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8888:8888"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media-management/unmanic/config:/config
    - /mnt/media:/library
    - /tmp/unmanic:/tmp/unmanic
  devices:
    - /dev/dri:/dev/dri  # Intel QuickSync
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.unmanic.rule=Host(`unmanic.${DOMAIN}`)"
    - "traefik.http.routers.unmanic.entrypoints=websecure"
    - "traefik.http.routers.unmanic.tls.certresolver=letsencrypt"
    - "traefik.http.routers.unmanic.middlewares=authelia@docker"
    - "traefik.http.services.unmanic.loadbalancer.server.port=8888"
```

### With NVIDIA GPU

```yaml
unmanic:
  image: josh5/unmanic:latest
  container_name: unmanic
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
    - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
  # ... rest of config
```

## Initial Setup

### First Access

1. **Start Container:**
   ```bash
   docker compose up -d unmanic
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:8888`
   - Domain: `https://unmanic.yourdomain.com`

3. **Add Library:**
   - Settings → Libraries → Add Library
   - Path: `/library/movies`
   - Enable file watcher

4. **Install Plugins:**
   - Plugins → Install desired plugins
   - Configure plugin settings

5. **Configure Workers:**
   - Settings → Workers
   - Set worker count based on resources

### Popular Plugins

**Essential Plugins:**

1. **Video Encoder H265/HEVC**
   - Convert to H.265
   - Space savings

2. **Normalize Audio Levels**
   - Consistent volume
   - Prevents loud/quiet issues

3. **Remove Subtitle Streams**
   - Clean unwanted subtitles

4. **Container Conversion to MKV**
   - Standardize on MKV

5. **Video Resolution Limiter**
   - Downscale 4K to 1080p if needed

**Install:**
- Plugins → Search → Install
- Configure in Library settings

### Library Configuration

**Settings → Libraries → Select Library:**

**General:**
- Enable file watcher: ✓
- Enable inotify: ✓ (real-time)
- Scan interval: 30 minutes (backup to file watcher)

**Plugins:**
- Add plugins in desired order
- Each plugin processes sequentially

**Example Flow:**
1. Container Conversion to MKV
2. Video Encoder H265
3. Normalize Audio
4. Remove Subtitle Streams

### Worker Configuration

**Settings → Workers:**

**Worker Count:**
- 1-2 for GPU encoding
- 2-4 for CPU encoding
- Don't overload system

**Worker Settings:**
- Enable hardware acceleration
- Set temp directory
- Configure logging

## Troubleshooting

### Unmanic Not Processing Files

```bash
# Check file watcher
# Settings → Libraries → Check "Enable file watcher"

# Check logs
docker logs unmanic | tail -50

# Manual trigger
# Dashboard → Rescan Library

# Check queue
# Dashboard → Should show pending tasks

# Verify permissions
docker exec unmanic ls -la /library/movies/
```

### Transcoding Fails

```bash
# Check worker logs
# Dashboard → Workers → View logs

# Check temp space
df -h /tmp/unmanic/

# Check FFmpeg
docker exec unmanic ffmpeg -version

# Check GPU access
docker exec unmanic ls /dev/dri/

# Common issues:
# - Insufficient temp space
# - GPU not available
# - File format unsupported
```

### High Resource Usage

```bash
# Reduce worker count
# Settings → Workers → Decrease count

# Check active workers
docker stats unmanic

# Pause processing
# Dashboard → Pause button

# Schedule processing
# Process during off-hours only
```

## Summary

Unmanic is the library optimizer offering:
- Automatic file processing
- Real-time file watching
- Plugin-based workflows
- Hardware acceleration
- Simple setup
- Free and open-source

**Perfect for:**
- Continuous optimization
- New file processing
- Format standardization
- Automated workflows
- Simple transcoding needs

**Key Points:**
- File watcher for automation
- Plugin system for flexibility
- Hardware acceleration support
- Simpler than Tdarr for basic needs
- Real-time processing

**Remember:**
- Use fast temp directory
- Monitor disk space
- Test plugins before bulk use
- Hardware acceleration recommended
- Works great with Sonarr/Radarr

Unmanic keeps your library optimized automatically!
