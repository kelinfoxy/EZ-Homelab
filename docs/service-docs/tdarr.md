# Tdarr - Transcoding Automation

## Table of Contents
- [Overview](#overview)
- [What is Tdarr?](#what-is-tdarr)
- [Why Use Tdarr?](#why-use-tdarr)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Media Transcoding  
**Docker Image:** [ghcr.io/haveagitgat/tdarr](https://github.com/HaveAGitGat/Tdarr/pkgs/container/tdarr)  
**Default Stack:** `transcoders.yml`  
**Web UI:** `https://tdarr.${DOMAIN}` or `http://SERVER_IP:8265`  
**Server Port:** 8266  
**Authentication:** Built-in  
**Ports:** 8265 (WebUI), 8266 (Server)

## What is Tdarr?

Tdarr is a distributed transcoding system for automating media library transcoding/remuxing management. It can convert your entire media library to specific codecs (like H.265/HEVC), formats, or remove unwanted audio/subtitle tracks - all automatically. It uses a plugin system with hundreds of pre-made plugins for common tasks, supports hardware acceleration, and can run transcoding across multiple nodes.

### Key Features
- **Distributed Transcoding:** Multiple worker nodes
- **Plugin System:** 500+ pre-made plugins
- **Hardware Acceleration:** NVIDIA, Intel QSV, AMD
- **Health Checks:** Identify corrupted files
- **Codec Conversion:** H.264 → H.265, VP9, AV1
- **Audio/Subtitle Management:** Remove unwanted tracks
- **Container Remux:** MKV → MP4, etc.
- **Scheduling:** Transcode during specific hours
- **Library Statistics:** Codec breakdown, space usage
- **Web UI:** Modern interface with dark mode

## Why Use Tdarr?

1. **Space Savings:** H.265 saves 30-50% vs H.264
2. **Standardization:** Consistent codec across library
3. **Compatibility:** Convert to Plex/Jellyfin-friendly formats
4. **Cleanup:** Remove unwanted audio/subtitle tracks
5. **Quality Control:** Health checks detect corruption
6. **Automation:** Set it and forget it
7. **Hardware Acceleration:** Fast transcoding with GPU
8. **Distributed:** Use multiple machines
9. **Free & Open Source:** No cost
10. **Flexible:** Plugin system for any workflow

## How It Works

```
Tdarr Scans Media Library
        ↓
Analyzes Each File
(Codec, resolution, audio tracks, etc.)
        ↓
Compares Against Rules/Plugins
        ↓
Files Needing Transcoding → Queue
        ↓
Worker Nodes Process Queue
(Using CPU or GPU)
        ↓
Transcoded File Created
        ↓
Replaces Original (or saves alongside)
        ↓
Library Updated
```

### Architecture

**Tdarr Server:**
- Central management
- Web UI
- Library scanning
- Queue management

**Tdarr Node:**
- Worker process
- Performs transcoding
- Can run on same or different machine
- Multiple nodes supported

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media-management/tdarr/
├── server/              # Tdarr server data
├── config/              # Configuration
├── logs/                # Logs
└── temp/                # Temporary transcoding files

/mnt/media/              # Media libraries (shared)
├── movies/
└── tv/
```

### Environment Variables

```bash
# Server
serverIP=0.0.0.0
serverPort=8266
webUIPort=8265

# User permissions
PUID=1000
PGID=1000

# Timezone
TZ=America/New_York

# Hardware acceleration (optional)
# NVIDIA_VISIBLE_DEVICES=all
```

## Official Resources

- **Website:** https://tdarr.io
- **Documentation:** https://docs.tdarr.io
- **GitHub:** https://github.com/HaveAGitGat/Tdarr
- **Discord:** https://discord.gg/GF8Chh3
- **Forum:** https://www.reddit.com/r/Tdarr
- **Plugins:** https://github.com/HaveAGitGat/Tdarr_Plugins

## Educational Resources

### Videos
- [Tdarr Setup Guide](https://www.youtube.com/results?search_query=tdarr+setup+guide)
- [Tdarr H.265 Conversion](https://www.youtube.com/results?search_query=tdarr+h265+conversion)
- [Tdarr Hardware Transcoding](https://www.youtube.com/results?search_query=tdarr+hardware+acceleration)

### Articles & Guides
- [Official Documentation](https://docs.tdarr.io)
- [Plugin Library](https://github.com/HaveAGitGat/Tdarr_Plugins)
- [Best Practices](https://docs.tdarr.io/docs/tutorials/best-practices)

### Concepts to Learn
- **Transcoding:** Converting video codecs
- **Remuxing:** Changing container without re-encoding
- **H.265/HEVC:** Modern codec, better compression
- **Hardware Encoding:** GPU-accelerated transcoding
- **Bitrate:** Video quality measurement
- **CRF:** Constant Rate Factor (quality setting)
- **Streams:** Video, audio, subtitle tracks

## Docker Configuration

### Complete Service Definition

```yaml
tdarr:
  image: ghcr.io/haveagitgat/tdarr:latest
  container_name: tdarr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8265:8265"  # WebUI
    - "8266:8266"  # Server
  environment:
    - serverIP=0.0.0.0
    - serverPort=8266
    - webUIPort=8265
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media-management/tdarr/server:/app/server
    - /opt/stacks/media-management/tdarr/config:/app/configs
    - /opt/stacks/media-management/tdarr/logs:/app/logs
    - /opt/stacks/media-management/tdarr/temp:/temp
    - /mnt/media:/media
  devices:
    - /dev/dri:/dev/dri  # Intel QuickSync
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.tdarr.rule=Host(`tdarr.${DOMAIN}`)"
    - "traefik.http.routers.tdarr.entrypoints=websecure"
    - "traefik.http.routers.tdarr.tls.certresolver=letsencrypt"
    - "traefik.http.routers.tdarr.middlewares=authelia@docker"
    - "traefik.http.services.tdarr.loadbalancer.server.port=8265"
```

### With NVIDIA GPU

```yaml
tdarr:
  image: ghcr.io/haveagitgat/tdarr:latest
  container_name: tdarr
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
    - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
  # ... rest of config
```

### Tdarr Node (Worker)

```yaml
tdarr-node:
  image: ghcr.io/haveagitgat/tdarr_node:latest
  container_name: tdarr-node
  restart: unless-stopped
  network_mode: service:tdarr
  environment:
    - nodeName=MainNode
    - serverIP=0.0.0.0
    - serverPort=8266
    - PUID=1000
    - PGID=1000
  volumes:
    - /opt/stacks/media-management/tdarr/config:/app/configs
    - /opt/stacks/media-management/tdarr/logs:/app/logs
    - /opt/stacks/media-management/tdarr/temp:/temp
    - /mnt/media:/media
  devices:
    - /dev/dri:/dev/dri
```

## Initial Setup

### First Access

1. **Start Containers:**
   ```bash
   docker compose up -d tdarr tdarr-node
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:8265`
   - Domain: `https://tdarr.yourdomain.com`

3. **Initial Configuration:**
   - Add libraries
   - Configure node
   - Install plugins
   - Create flows

### Add Library

**Libraries Tab → Add Library:**

1. **Name:** Movies
2. **Source:** `/media/movies`
3. **Folder watch:** ✓ Enable
4. **Priority:** Normal
5. **Schedule:** Always (or specific hours)
6. **Save**

**Repeat for TV Shows:**
- Name: TV Shows
- Source: `/media/tv`

### Configure Node

**Nodes Tab:**

**Built-in Node:**
- Should appear automatically
- Named "MainNode" (from docker config)
- Shows as "Online"

**Node Settings:**
- Transcode GPU: 1 (if GPU available)
- Transcode CPU: 2-4 (CPU threads)
- Health Check GPU: 0
- Health Check CPU: 1

**Hardware Acceleration:**
- CPU Only: Use CPU workers
- NVIDIA: Select "NVENC" codec in plugins
- Intel QSV: Select "QSV" codec
- Prioritize GPU for best performance

### Install Plugins

**Plugins Tab → Community:**

**Essential Plugins:**

1. **Migz-Transcode using Nvidia GPU & FFMPEG**
   - NVIDIA hardware transcoding
   - H.264 → H.265

2. **Migz-Transcode using CPU & FFMPEG**
   - CPU-based transcoding
   - Fallback for non-GPU

3. **Remux Container to MKV**
   - Convert to MKV without re-encoding

4. **Remove All Subtitle Streams**
   - Clean unwanted subtitles

5. **Remove Non-English Audio Streams**
   - Keep only English audio

**Install:**
- Click "+" to install plugin
- Shows in "Local" tab when installed

### Create Flow

**Flows Tab → Add Flow:**

**Example: Convert to H.265**

1. **Flow Name:** H.265 Conversion
2. **Add Step:**
   - Plugin: Migz-Transcode using Nvidia GPU & FFMPEG
   - Target Codec: hevc (H.265)
   - CRF: 23 (quality)
   - Resolution: Keep original
   - Audio: Copy (no transcode)
   - Subtitles: Copy
3. **Save Flow**

**Assign to Library:**
- Libraries → Movies → Transcode Options
- Flow: H.265 Conversion
- Save

### Start Processing

**Dashboard:**
- View queue
- Processing status
- Completed/Failed counts
- Library statistics

**Start Transcoding:**
- Automatically starts based on schedule
- Monitor progress in real-time

## Advanced Topics

### Custom Plugins

**Create Custom Plugin:**

**Plugins Tab → Local → Create Plugin:**

```javascript
function details() {
  return {
    id: "Custom_H265",
    Stage: "Pre-processing",
    Name: "Custom H.265 Conversion",
    Type: "Video",
    Operation: "Transcode",
    Description: "Custom H.265 conversion with specific settings",
    Version: "1.0",
    Tags: "video,h265,nvenc",
  };
}

function plugin(file, librarySettings, inputs, otherArguments) {
  var response = {
    processFile: false,
    preset: "",
    handBrakeMode: false,
    FFmpegMode: true,
    reQueueAfter: true,
    infoLog: "",
  };

  if (file.video_codec_name === "hevc") {
    response.infoLog += "File already H.265 ☑\n";
    response.processFile = false;
    return response;
  }

  response.processFile = true;
  response.preset = "-c:v hevc_nvenc -crf 23 -c:a copy -c:s copy";
  response.infoLog += "Transcoding to H.265 with NVENC\n";
  
  return response;
}

module.exports.details = details;
module.exports.plugin = plugin;
```

**Use Cases:**
- Specific quality settings
- Custom audio handling
- Conditional transcoding
- Advanced workflows

### Flow Conditions

**Add Conditions to Flows:**

**Example: Only transcode if > 1080p**
- Add condition: Resolution > 1920x1080
- Then: Transcode to 1080p
- Else: Skip

**Example: Only if file size > 5GB**
- Condition: File size check
- Large files get transcoded
- Small files skipped

### Scheduling

**Library Settings → Schedule:**

**Transcode Schedule:**
- All day: 24/7 transcoding
- Night only: 10PM - 6AM
- Custom hours: Define specific times

**Use Cases:**
- Transcode during off-hours
- Avoid peak usage times
- Save electricity costs

### Health Checks

**Detect Corrupted Files:**

**Libraries → Settings → Health Check:**
- ✓ Enable health check
- Check for: Video errors, audio errors
- Workers: 1-2 CPU workers

**Health Check Flow:**
- Scans files for corruption
- Marks unhealthy files
- Option to quarantine or delete

### Statistics

**Dashboard → Statistics:**

**Library Stats:**
- Total files
- Codec breakdown (H.264 vs H.265)
- Total size
- Space savings potential

**Processing Stats:**
- Files processed
- Success rate
- Average processing time
- Queue size

### Multiple Libraries

**Separate libraries for:**
- Movies
- TV Shows
- 4K Content
- Different quality tiers

**Benefits:**
- Different flows per library
- Prioritization
- Separate schedules

## Troubleshooting

### Tdarr Not Transcoding

```bash
# Check node status
# Nodes tab → Should show "Online"

# Check queue
# Dashboard → Should show items

# Check workers
# Nodes → Workers should be > 0

# Check logs
docker logs tdarr
docker logs tdarr-node

# Common issues:
# - No workers configured
# - Library not assigned to flow
# - Schedule disabled
# - Temp directory full
```

### Transcoding Fails

```bash
# Check logs
docker logs tdarr-node | tail -50

# Check temp directory space
df -h /opt/stacks/media-management/tdarr/temp/

# Check FFmpeg
docker exec tdarr-node ffmpeg -version

# Check hardware acceleration
# GPU not detected → use CPU plugins

# Check file permissions
ls -la /mnt/media/movies/
```

### High CPU/GPU Usage

```bash
# Check worker count
# Nodes → Reduce workers if too high

# Monitor resources
docker stats tdarr tdarr-node

# Limit workers:
# - GPU: 1-2
# - CPU: 2-4 (depending on cores)

# Schedule during off-hours
# Libraries → Schedule → Night only
```

### Slow Transcoding

```bash
# Enable hardware acceleration
# Use NVENC/QSV plugins instead of CPU

# Reduce quality
# CRF 28 faster than CRF 18

# Increase workers (if resources available)

# Use faster preset
# Plugin settings → Preset: fast/faster

# Check disk I/O
# Fast NVMe for temp directory improves speed
```

### Files Not Replacing Originals

```bash
# Check flow settings
# Flow → Output → Replace original: ✓

# Check permissions
ls -la /mnt/media/

# Check temp directory
ls -la /opt/stacks/media-management/tdarr/temp/

# Check logs for errors
docker logs tdarr-node | grep -i error
```

## Performance Optimization

### Hardware Acceleration

**Best Performance:**
1. NVIDIA GPU (NVENC)
2. Intel QuickSync (QSV)
3. AMD GPU
4. CPU (slowest)

**Settings:**
- GPU workers: 1-2
- Quality: CRF 23-28
- Preset: medium/fast

### Temp Directory

**Use Fast Storage:**
```yaml
volumes:
  - /path/to/fast/nvme:/temp
```

**Or RAM disk:**
```yaml
volumes:
  - /dev/shm:/temp
```

**Benefits:**
- Faster read/write
- Reduced wear on HDDs

### Worker Optimization

**Recommendations:**
- Transcode GPU: 1-2
- Transcode CPU: 50-75% of cores
- Health Check: 1 CPU worker

**Don't Overload:**
- System needs resources for other services
- Leave headroom

## Security Best Practices

1. **Reverse Proxy:** Use Traefik + Authelia
2. **Read-Only Media:** Use separate temp directory
3. **Backup Before Bulk Operations:** Test on small set first
4. **Regular Backups:** Original files until verified
5. **Monitor Disk Space:** Transcoding needs 2x file size temporarily
6. **Limit Access:** Keep UI secured
7. **Regular Updates:** Keep Tdarr current

## Backup Strategy

**Before Transcoding:**
- Test on small library subset
- Verify quality before bulk processing
- Keep original files until verified

**Critical Files:**
```bash
/opt/stacks/media-management/tdarr/server/  # Database
/opt/stacks/media-management/tdarr/config/  # Configuration
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/tdarr

tar -czf $BACKUP_DIR/tdarr-$DATE.tar.gz \
  /opt/stacks/media-management/tdarr/server/ \
  /opt/stacks/media-management/tdarr/config/

find $BACKUP_DIR -name "tdarr-*.tar.gz" -mtime +7 -delete
```

## Integration with Other Services

### Tdarr + Plex/Jellyfin
- Transcode to compatible codecs
- Reduce Plex transcoding load
- Optimize library for direct play

### Tdarr + Sonarr/Radarr
- Process new downloads automatically
- Standard quality across library

## Summary

Tdarr is the transcoding automation system offering:
- Distributed transcoding
- H.265 space savings
- Hardware acceleration
- 500+ plugins
- Flexible workflows
- Health checking
- Free and open-source

**Perfect for:**
- Large media libraries
- Space optimization (H.265)
- Library standardization
- Quality control
- Hardware acceleration users

**Key Points:**
- Use GPU for best performance
- CRF 23 good balance
- Test on small set first
- Monitor disk space
- Fast temp directory helps
- Schedule during off-hours
- Backup before bulk operations

**Remember:**
- Transcoding is lossy (quality loss)
- Keep originals until verified
- H.265 saves 30-50% space
- Hardware acceleration essential
- Can take days for large libraries
- Test plugins before bulk use

Tdarr automates your entire library transcoding workflow!
