# Jellyfin - Open-Source Media Server

## Table of Contents
- [Overview](#overview)
- [What is Jellyfin?](#what-is-jellyfin)
- [Why Use Jellyfin?](#why-use-jellyfin)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Library Management](#library-management)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Media Server  
**Docker Image:** [linuxserver/jellyfin](https://hub.docker.com/r/linuxserver/jellyfin)  
**Default Stack:** `media.yml`  
**Web UI:** `https://jellyfin.${DOMAIN}` or `http://SERVER_IP:8096`  
**Authentication:** Local accounts (no external service required)  
**Ports:** 8096 (HTTP), 8920 (HTTPS), 7359 (auto-discovery), 1900 (DLNA)

## What is Jellyfin?

Jellyfin is a free, open-source media server forked from Emby. It provides complete control over your media with no tracking, premium features, or account requirements. Jellyfin is 100% free with all features available without subscriptions.

### Key Features
- **Completely Free:** No premium tiers or subscriptions
- **Open Source:** GPLv2 licensed
- **No Tracking:** Zero telemetry or analytics
- **Local Accounts:** No external service required
- **Hardware Acceleration:** VAAPI, NVENC, QSV, AMF
- **Live TV & DVR:** Built-in EPG support
- **SyncPlay:** Watch together feature
- **Native Apps:** Android, iOS, Roku, Fire TV, etc.
- **Web Player:** Modern HTML5 player
- **DLNA Server:** Stream to any DLNA device
- **Plugins:** Extensible with official/community plugins
- **Webhooks:** Custom notifications and integrations

## Why Use Jellyfin?

1. **100% Free:** All features, no subscriptions ever
2. **Privacy Focused:** No tracking, no accounts to external services
3. **Open Source:** Community-driven development
4. **Self-Contained:** No dependency on external services
5. **Hardware Transcoding:** Free for everyone
6. **Modern Interface:** Clean, responsive UI
7. **Active Development:** Regular updates
8. **Plugin System:** Extend functionality
9. **SyncPlay:** Watch parties built-in
10. **No Vendor Lock-in:** Your data, your control

## How It Works

```
Media Files → Jellyfin Server (scans and organizes)
                    ↓
          Metadata Enrichment
          (TheMovieDB, MusicBrainz, etc.)
                    ↓
         ┌──────────┴──────────┐
         ↓                     ↓
    Direct Play              Transcoding
    (Compatible)         (Hardware Accel)
         ↓                     ↓
    Jellyfin Apps        Jellyfin Apps
    (All Devices)       (Any Browser)
```

### Media Flow

1. **Add media** to libraries
2. **Jellyfin scans** and identifies content
3. **Metadata scraped** from open databases
4. **User requests** via web/app
5. **Jellyfin determines** if transcoding needed
6. **Hardware transcoding** if supported
7. **Stream** to client

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media/jellyfin/
├── config/                    # Jellyfin configuration
├── cache/                     # Temporary cache
└── transcode/                 # Transcoding temp files

/mnt/media/
├── movies/                    # Movie files
├── tv/                       # TV show files
├── music/                    # Music files
└── photos/                   # Photo files
```

### Environment Variables

```bash
# User permissions
PUID=1000
PGID=1000

# Timezone
TZ=America/New_York

# Optional: Published server URL
JELLYFIN_PublishedServerUrl=https://jellyfin.yourdomain.com
```

## Official Resources

- **Website:** https://jellyfin.org
- **Documentation:** https://jellyfin.org/docs/
- **GitHub:** https://github.com/jellyfin/jellyfin
- **Forum:** https://forum.jellyfin.org
- **Reddit:** https://reddit.com/r/jellyfin
- **Matrix Chat:** https://matrix.to/#/#jellyfin:matrix.org
- **Feature Requests:** https://features.jellyfin.org

## Educational Resources

### Videos
- [Jellyfin Setup Guide (Techno Tim)](https://www.youtube.com/watch?v=R2zVv0DoMF4)
- [Jellyfin vs Plex vs Emby](https://www.youtube.com/results?search_query=jellyfin+vs+plex)
- [Ultimate Jellyfin Setup](https://www.youtube.com/watch?v=zUmIGwbNBw0)
- [Jellyfin Hardware Transcoding](https://www.youtube.com/results?search_query=jellyfin+hardware+transcoding)
- [Jellyfin Tips and Tricks](https://www.youtube.com/results?search_query=jellyfin+tips+tricks)

### Articles & Guides
- [Official Documentation](https://jellyfin.org/docs/)
- [Hardware Acceleration](https://jellyfin.org/docs/general/administration/hardware-acceleration.html)
- [Naming Conventions](https://jellyfin.org/docs/general/server/media/movies.html)
- [Plugin Catalog](https://jellyfin.org/docs/general/server/plugins/)
- [Client Apps](https://jellyfin.org/clients/)

### Concepts to Learn
- **Transcoding:** Converting media formats in real-time
- **Hardware Acceleration:** GPU-based encoding (VAAPI, NVENC, QSV)
- **Direct Play:** Streaming without conversion
- **Remuxing:** Changing container without re-encoding
- **Metadata Providers:** TheMovieDB, TVDb, MusicBrainz
- **NFO Files:** Local metadata files
- **DLNA:** Network streaming protocol

## Docker Configuration

### Complete Service Definition

```yaml
jellyfin:
  image: linuxserver/jellyfin:latest
  container_name: jellyfin
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8096:8096"     # HTTP Web UI
    - "8920:8920"     # HTTPS (optional)
    - "7359:7359/udp" # Auto-discovery
    - "1900:1900/udp" # DLNA
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - JELLYFIN_PublishedServerUrl=https://jellyfin.${DOMAIN}
  volumes:
    - /opt/stacks/media/jellyfin/config:/config
    - /opt/stacks/media/jellyfin/cache:/cache
    - /mnt/media/movies:/data/movies:ro
    - /mnt/media/tv:/data/tvshows:ro
    - /mnt/media/music:/data/music:ro
  devices:
    - /dev/dri:/dev/dri  # Intel QuickSync
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.${DOMAIN}`)"
    - "traefik.http.routers.jellyfin.entrypoints=websecure"
    - "traefik.http.routers.jellyfin.tls.certresolver=letsencrypt"
    - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
```

### With NVIDIA GPU

```yaml
jellyfin:
  image: linuxserver/jellyfin:latest
  container_name: jellyfin
  restart: unless-stopped
  runtime: nvidia  # Requires nvidia-docker
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
    - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
  volumes:
    - /opt/stacks/media/jellyfin/config:/config
    - /mnt/media:/data:ro
  ports:
    - "8096:8096"
```

### Transcoding on RAM Disk

```yaml
jellyfin:
  volumes:
    - /opt/stacks/media/jellyfin/config:/config
    - /mnt/media:/data:ro
    - /dev/shm:/config/transcodes  # Use RAM for transcoding
```

## Initial Setup

### First-Time Configuration

1. **Start Container:**
   ```bash
   docker compose up -d jellyfin
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:8096`
   - Via domain: `https://jellyfin.yourdomain.com`

3. **Initial Setup Wizard:**
   - Select preferred display language
   - Create administrator account (local, no external service)
   - Set up media libraries
   - Configure remote access
   - Review settings

### Adding Libraries

**Add Movie Library:**
1. Dashboard → Libraries → Add Media Library
2. Content type: Movies
3. Display name: Movies
4. Folders → Add → `/data/movies`
5. Preferred language: English
6. Country: United States
7. Save

**Add TV Library:**
1. Dashboard → Libraries → Add Media Library
2. Content type: Shows
3. Display name: TV Shows
4. Folders → Add → `/data/tvshows`
5. Save

**Add Music Library:**
1. Content type: Music
2. Folders → Add → `/data/music`
3. Save

### File Naming Conventions

**Movies:**
```
/data/movies/
  Movie Name (Year)/
    Movie Name (Year).mkv
    
Example:
/data/movies/
  The Matrix (1999)/
    The Matrix (1999).mkv
```

**TV Shows:**
```
/data/tvshows/
  Show Name (Year)/
    Season 01/
      Show Name - S01E01 - Episode Name.mkv
      
Example:
/data/tvshows/
  Breaking Bad (2008)/
    Season 01/
      Breaking Bad - S01E01 - Pilot.mkv
      Breaking Bad - S01E02 - Cat's in the Bag.mkv
```

**Music:**
```
/data/music/
  Artist/
    Album (Year)/
      01 - Track Name.mp3
```

## Library Management

### Scanning Libraries

**Manual Scan:**
- Dashboard → Libraries → Scan All Libraries
- Or click scan icon on specific library

**Scheduled Scanning:**
- Dashboard → Scheduled Tasks → Scan Media Library
- Configure scan interval

**Real-time Monitoring:**
- Dashboard → Libraries → Enable real-time monitoring
- Watches for file changes

### Metadata Management

**Providers:**
- Dashboard → Libraries → Select library → Manage Library
- Metadata providers: TheMovieDB, TVDb, OMDb, etc.
- Order determines priority

**Identify Item:**
1. Select item with wrong metadata
2. ... → Identify
3. Search by name or TMDB/TVDb ID
4. Select correct match

**Edit Metadata:**
- ... → Edit Metadata
- Change title, description, images, etc.
- Lock fields to prevent overwriting

**Refresh Metadata:**
- ... → Refresh Metadata
- Re-scrapes from providers

### Collections

**Auto Collections:**
- Jellyfin auto-creates collections from metadata
- Example: "Marvel Cinematic Universe" for all MCU movies

**Manual Collections:**
1. Dashboard → Collections → New Collection
2. Name collection
3. Add movies/shows
4. Set sorting and display options

## Advanced Topics

### Hardware Transcoding

**Intel QuickSync (QSV):**

1. **Verify GPU Access:**
   ```bash
   docker exec jellyfin ls -la /dev/dri
   # Should show renderD128, card0, etc.
   
   # Check permissions
   docker exec jellyfin id
   # User should have video group (render group ID)
   ```

2. **Enable in Jellyfin:**
   - Dashboard → Playback → Transcoding
   - Hardware acceleration: Intel QuickSync (QSV)
   - Enable hardware decoding for: H264, HEVC, VP9, AV1
   - Enable hardware encoding for: H264, HEVC
   - Save

**NVIDIA GPU (NVENC):**

1. **Ensure nvidia-docker installed:**
   ```bash
   docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
   ```

2. **Enable in Jellyfin:**
   - Dashboard → Playback → Transcoding
   - Hardware acceleration: Nvidia NVENC
   - Enable codecs
   - Save

**AMD GPU (AMF/VAAPI):**

```yaml
jellyfin:
  devices:
    - /dev/dri:/dev/dri
    - /dev/kfd:/dev/kfd  # AMD GPU
  group_add:
    - video
    - render
```

Dashboard → Transcoding → VAAPI

**Verify Hardware Transcoding:**
- Play a video that requires transcoding
- Dashboard → Activity
- Check encoding method shows (hw)

### User Management

**Add Users:**
1. Dashboard → Users → Add User
2. Enter username and password
3. Configure library access
4. Set permissions

**User Profiles:**
- Each user has own watch history
- Separate Continue Watching
- Individual preferences

**Parental Controls:**
- Set maximum parental rating
- Block unrated content
- Restrict library access

### Plugins

**Install Plugins:**
1. Dashboard → Plugins → Catalog
2. Browse available plugins
3. Install desired plugins
4. Restart Jellyfin

**Popular Plugins:**
- **TMDb Box Sets:** Auto-create collections
- **Trakt:** Sync watch history to Trakt.tv
- **Reports:** Generate library reports
- **Skin Manager:** Custom themes
- **Anime:** Better anime support
- **Fanart:** Additional image sources
- **Merge Versions:** Combine different qualities
- **Playback Reporting:** Track user activity

**Third-Party Repositories:**
- Add custom plugin repositories
- Dashboard → Plugins → Repositories

### SyncPlay (Watch Together)

**Enable:**
- Dashboard → Plugins → SyncPlay
- Restart Jellyfin

**Use:**
1. User creates SyncPlay group
2. Shares join code
3. Others join with code
4. Playback synchronized across all users
5. Chat available

**Perfect For:**
- Long-distance watch parties
- Family movie nights
- Synchronized viewing

### Live TV & DVR

**Requirements:**
- TV tuner hardware (HDHomeRun, etc.)
- Or IPTV source (m3u playlist)

**Setup:**
1. Dashboard → Live TV
2. Add TV source:
   - Tuner device (network device auto-detected)
   - Or IPTV (M3U URL)
3. Configure EPG (Electronic Program Guide)
   - XML TV guide URL
4. Map channels
5. Save

**DVR:**
- Record shows from EPG
- Series recordings
- Post-processing options

## Troubleshooting

### Jellyfin Not Accessible

```bash
# Check container status
docker ps | grep jellyfin

# View logs
docker logs jellyfin

# Test access
curl http://localhost:8096

# Check ports
docker port jellyfin
```

### Libraries Not Scanning

```bash
# Check permissions
ls -la /mnt/media/movies/

# Fix ownership
sudo chown -R 1000:1000 /mnt/media/

# Check container can access
docker exec jellyfin ls /data/movies

# Manual scan from UI
# Dashboard → Libraries → Scan All Libraries

# Check logs
docker logs jellyfin | grep -i scan
```

### Hardware Transcoding Not Working

```bash
# Verify GPU device
docker exec jellyfin ls -la /dev/dri

# Check permissions
docker exec jellyfin groups
# Should include video (44) and render (106 or 104)

# For Intel GPU, check:
docker exec jellyfin vainfo
# Should list supported codecs

# Check Jellyfin logs during playback
docker logs -f jellyfin
# Look for hardware encoding messages
```

**Fix GPU Permissions:**
```bash
# Get render group ID
getent group render

# Update docker-compose
jellyfin:
  group_add:
    - "106"  # render group ID
```

### Transcoding Failing

```bash
# Check transcode directory
docker exec jellyfin ls /config/transcodes/

# Ensure enough disk space
df -h /opt/stacks/media/jellyfin/

# Check FFmpeg
docker exec jellyfin ffmpeg -version

# Test hardware encoding
docker exec jellyfin ffmpeg -hwaccel vaapi -i /data/movies/sample.mkv -c:v h264_vaapi -f null -
```

### Playback Buffering

**Causes:**
- Network bandwidth insufficient
- Transcoding too slow (CPU overload)
- Disk I/O bottleneck
- Client compatibility issues

**Solutions:**
- Enable hardware transcoding
- Lower streaming quality
- Use direct play when possible
- Optimize media files (H264/HEVC)
- Increase transcoding threads
- Use faster storage for transcode directory

### Metadata Not Downloading

```bash
# Check internet connectivity
docker exec jellyfin ping -c 3 api.themoviedb.org

# Verify metadata providers enabled
# Dashboard → Libraries → Library → Metadata providers

# Force metadata refresh
# Select item → Refresh Metadata → Replace all metadata

# Check naming conventions
# Ensure files follow Jellyfin naming standards
```

### Database Corruption

```bash
# Stop Jellyfin
docker stop jellyfin

# Backup database
cp -r /opt/stacks/media/jellyfin/config/data /opt/backups/jellyfin-data-backup

# Check database
sqlite3 /opt/stacks/media/jellyfin/config/data/library.db "PRAGMA integrity_check;"

# If corrupted, restore from backup or rebuild library
# Delete database and rescan (loses watch history)
# rm /opt/stacks/media/jellyfin/config/data/library.db

# Restart
docker start jellyfin
```

## Performance Optimization

### Transcoding Performance

```yaml
# Use RAM disk for transcoding
jellyfin:
  volumes:
    - /dev/shm:/config/transcodes
    
# Or fast NVMe
volumes:
  - /path/to/fast/nvme:/config/transcodes
```

**Settings:**
- Dashboard → Playback → Transcoding
- Transcoding thread count: Number of CPU cores
- Hardware acceleration: Enabled
- H264 encoding CRF: 23 (lower = better quality, more CPU)
- Throttle transcodes: Disabled (for local network)

### Database Optimization

```bash
# Stop Jellyfin
docker stop jellyfin

# Vacuum databases
sqlite3 /opt/stacks/media/jellyfin/config/data/library.db "VACUUM;"
sqlite3 /opt/stacks/media/jellyfin/config/data/jellyfin.db "VACUUM;"

# Restart
docker start jellyfin
```

### Network Optimization

**Settings:**
- Dashboard → Networking
- LAN Networks: 192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
- Enable automatic port mapping: Yes
- Public HTTPS port: 8920 (if using)
- Public HTTP port: 8096

### Cache Settings

```yaml
# Separate cache volume for better I/O
jellyfin:
  volumes:
    - /opt/stacks/media/jellyfin/cache:/cache
```

Dashboard → System → Caching:
- Clear image cache periodically
- Set cache expiration

## Security Best Practices

1. **Strong Passwords:** Enforce for all users
2. **HTTPS Only:** Use Traefik for SSL
3. **Read-Only Media:** Mount media as `:ro`
4. **User Permissions:** Grant minimal library access
5. **Network Segmentation:** Consider separate VLAN
6. **Regular Updates:** Keep Jellyfin current
7. **Secure Remote Access:** Use VPN or Traefik auth
8. **Disable UPnP:** If not needed for remote access
9. **API Keys:** Regenerate periodically
10. **Audit Users:** Review user accounts regularly

## Backup Strategy

**Critical Files:**
```bash
/opt/stacks/media/jellyfin/config/data/  # Databases
/opt/stacks/media/jellyfin/config/config/  # Configuration
/opt/stacks/media/jellyfin/config/metadata/  # Custom metadata
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/jellyfin

# Stop Jellyfin for consistent backup
docker stop jellyfin

# Backup configuration
tar -czf $BACKUP_DIR/jellyfin-config-$DATE.tar.gz \
  /opt/stacks/media/jellyfin/config/

# Restart
docker start jellyfin

# Keep last 7 backups
find $BACKUP_DIR -name "jellyfin-config-*.tar.gz" -mtime +7 -delete
```

**Restore:**
```bash
docker stop jellyfin
tar -xzf jellyfin-config-20240101.tar.gz -C /
docker start jellyfin
```

## Jellyseerr Integration

Pair with Jellyseerr for media requests:

```yaml
jellyseerr:
  image: fallenbagel/jellyseerr:latest
  container_name: jellyseerr
  environment:
    - LOG_LEVEL=info
  volumes:
    - /opt/stacks/media/jellyseerr/config:/app/config
  ports:
    - "5055:5055"
```

Allows users to:
- Request movies/shows
- Track request status
- Get notifications when available
- Browse available content

## Summary

Jellyfin is the leading open-source media server offering:
- 100% free, no premium tiers
- Complete privacy, no tracking
- Hardware transcoding for everyone
- Modern, responsive interface
- Active community development
- Plugin extensibility
- Live TV & DVR built-in

**Perfect for:**
- Privacy-conscious users
- Self-hosting enthusiasts
- Those avoiding subscriptions
- Open-source advocates
- Full control seekers
- GPU transcoding needs (free)

**Trade-offs:**
- Smaller app ecosystem than Plex
- Less polished UI than Plex
- Fewer smart TV apps
- Smaller community/resources
- Some features less mature

**Remember:**
- Hardware transcoding is free (unlike Plex Pass)
- No external account required
- All features available without payment
- Active development, improving constantly
- Great alternative to Plex
- Pair with Sonarr/Radarr for automation
- Use Jellyseerr for user requests
- Privacy-first approach

Jellyfin is the best choice for users who want complete control, privacy, and all features without subscriptions!
