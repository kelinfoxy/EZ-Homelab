# Plex - Media Server

## Table of Contents
- [Overview](#overview)
- [What is Plex?](#what-is-plex)
- [Why Use Plex?](#why-use-plex)
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
**Docker Image:** [linuxserver/plex](https://hub.docker.com/r/linuxserver/plex)  
**Default Stack:** `media.yml`  
**Web UI:** `https://plex.${DOMAIN}` or `http://SERVER_IP:32400/web`  
**Authentication:** Plex account required (free or Plex Pass)  
**Ports:** 32400 (web), 1900, 3005, 5353, 8324, 32410-32414, 32469

## What is Plex?

Plex is a comprehensive media server platform that organizes your personal media collection (movies, TV shows, music, photos) and streams it to any device. It's the most popular media server with apps on virtually every platform.

### Key Features
- **Universal Streaming:** Apps for every device
- **Beautiful Interface:** Polished, professional UI
- **Automatic Metadata:** Fetches posters, descriptions, cast info
- **Transcoding:** Converts media for any device
- **Live TV & DVR:** With Plex Pass and TV tuner
- **Mobile Sync:** Download for offline viewing
- **User Management:** Share libraries with friends/family
- **Watched Status:** Track progress across devices
- **Collections:** Organize movies into collections
- **Discover:** Recommendations and trending
- **Remote Access:** Stream from anywhere
- **Plex Pass:** Premium features (hardware transcoding, etc.)

## Why Use Plex?

1. **Most Popular:** Largest user base and app ecosystem
2. **Professional UI:** Best-looking interface
3. **Easy Sharing:** Simple friend/family sharing
4. **Universal Apps:** Literally every platform
5. **Active Development:** Regular updates
6. **Hardware Transcoding:** GPU acceleration (Plex Pass)
7. **Mobile Downloads:** Offline viewing
8. **Live TV:** DVR functionality
9. **Free:** Core features free, Plex Pass optional
10. **Discovery Features:** Find new content easily

## How It Works

```
Media Files → Plex Server (scans and organizes)
                    ↓
          Metadata Enrichment
          (posters, info, etc.)
                    ↓
         ┌──────────┴──────────┐
         ↓                     ↓
    Local Network         Remote Access
    (Direct Play)         (Transcoding)
         ↓                     ↓
    Plex Apps            Plex Apps
    (All Devices)       (Outside Home)
```

### Media Flow

1. **Add media** to watched folders
2. **Plex scans** and identifies content
3. **Metadata fetched** from online databases
4. **User requests** content via app
5. **Plex analyzes** client capabilities
6. **Direct play** or **transcode** as needed
7. **Stream** to client device

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media/plex/config/    # Plex configuration
/mnt/media/
├── movies/                        # Movie files
├── tv/                           # TV show files
├── music/                        # Music files
└── photos/                       # Photo files
```

### Environment Variables

```bash
# User permissions
PUID=1000
PGID=1000

# Timezone
TZ=America/New_York

# Plex Claim Token (for setup)
PLEX_CLAIM=claim-xxxxxxxxxxxxxxxx

# Optional: Version
VERSION=latest  # or specific version

# Optional: Hardware transcoding
# Requires Plex Pass + GPU
NVIDIA_VISIBLE_DEVICES=all  # For NVIDIA GPUs
```

**Get Claim Token:**
Visit: https://www.plex.tv/claim/ (valid for 4 minutes)

## Official Resources

- **Website:** https://www.plex.tv
- **Support:** https://support.plex.tv
- **Forums:** https://forums.plex.tv
- **Reddit:** https://reddit.com/r/PleX
- **API Documentation:** https://www.plex.tv/api/
- **Plex Pass:** https://www.plex.tv/plex-pass/

## Educational Resources

### Videos
- [Plex Setup Guide (Techno Tim)](https://www.youtube.com/watch?v=IOUbZPoKJM0)
- [Plex vs Jellyfin vs Emby](https://www.youtube.com/results?search_query=plex+vs+jellyfin)
- [Ultimate Plex Server Setup](https://www.youtube.com/watch?v=XKDSld-CrHU)
- [Plex Hardware Transcoding](https://www.youtube.com/results?search_query=plex+hardware+transcoding)

### Articles & Guides
- [Plex Official Documentation](https://support.plex.tv/articles/)
- [Naming Conventions](https://support.plex.tv/articles/naming-and-organizing-your-movie-media-files/)
- [Hardware Transcoding](https://support.plex.tv/articles/115002178853-using-hardware-accelerated-streaming/)
- [Remote Access Setup](https://support.plex.tv/articles/200289506-remote-access/)

### Concepts to Learn
- **Transcoding:** Converting media to compatible format
- **Direct Play:** Streaming without conversion
- **Direct Stream:** Remux container, no transcode
- **Hardware Acceleration:** GPU-based transcoding
- **Metadata Agents:** Sources for media information
- **Libraries:** Organized media collections
- **Quality Profiles:** Streaming quality settings

## Docker Configuration

### Complete Service Definition

```yaml
plex:
  image: linuxserver/plex:latest
  container_name: plex
  restart: unless-stopped
  network_mode: host  # Required for auto-discovery
  # Or use bridge network with all ports
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - VERSION=latest
    - PLEX_CLAIM=${PLEX_CLAIM}  # Optional, for initial setup
  volumes:
    - /opt/stacks/media/plex/config:/config
    - /mnt/media/movies:/movies
    - /mnt/media/tv:/tv
    - /mnt/media/music:/music
    - /mnt/media/photos:/photos
    - /tmp/plex-transcode:/transcode  # Temporary transcoding files
  devices:
    - /dev/dri:/dev/dri  # For Intel QuickSync
  # For NVIDIA GPU (requires nvidia-docker):
  # runtime: nvidia
  # environment:
  #   - NVIDIA_VISIBLE_DEVICES=all
  #   - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
```

### With Traefik (bridge network)

```yaml
plex:
  image: linuxserver/plex:latest
  container_name: plex
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "32400:32400/tcp"   # Web UI
    - "1900:1900/udp"     # DLNA
    - "3005:3005/tcp"     # Plex Companion
    - "5353:5353/udp"     # Bonjour/Avahi
    - "8324:8324/tcp"     # Roku
    - "32410:32410/udp"   # GDM Network Discovery
    - "32412:32412/udp"   # GDM Network Discovery
    - "32413:32413/udp"   # GDM Network Discovery
    - "32414:32414/udp"   # GDM Network Discovery
    - "32469:32469/tcp"   # Plex DLNA Server
  volumes:
    - /opt/stacks/media/plex/config:/config
    - /mnt/media:/media:ro  # Read-only mount
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.plex.rule=Host(`plex.${DOMAIN}`)"
    - "traefik.http.routers.plex.entrypoints=websecure"
    - "traefik.http.routers.plex.tls.certresolver=letsencrypt"
    - "traefik.http.services.plex.loadbalancer.server.port=32400"
```

## Initial Setup

### First-Time Configuration

1. **Start Container:**
   ```bash
   docker compose up -d plex
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:32400/web`
   - Via domain: `https://plex.yourdomain.com`

3. **Sign In:**
   - Use existing Plex account
   - Or create free account

4. **Server Setup Wizard:**
   - Give server a friendly name
   - Allow remote access (optional)
   - Add libraries (next section)

### Adding Libraries

**Add Movie Library:**
1. Settings → Libraries → Add Library
2. Type: Movies
3. Add folder: `/movies`
4. Advanced → Scanner: Plex Movie
5. Advanced → Agent: Plex Movie
6. Add Library

**Add TV Show Library:**
1. Settings → Libraries → Add Library
2. Type: TV Shows
3. Add folder: `/tv`
4. Advanced → Scanner: Plex Series
5. Advanced → Agent: Plex TV Series
6. Add Library

**Add Music Library:**
1. Type: Music
2. Add folder: `/music`
3. Scanner: Plex Music

### File Naming Conventions

**Movies:**
```
/movies/
  Movie Name (Year)/
    Movie Name (Year).mkv
    
Example:
/movies/
  The Matrix (1999)/
    The Matrix (1999).mkv
```

**TV Shows:**
```
/tv/
  Show Name (Year)/
    Season 01/
      Show Name - S01E01 - Episode Name.mkv
      
Example:
/tv/
  Breaking Bad (2008)/
    Season 01/
      Breaking Bad - S01E01 - Pilot.mkv
      Breaking Bad - S01E02 - Cat's in the Bag.mkv
```

## Library Management

### Scanning Libraries

**Manual Scan:**
- Settings → Libraries → Select library → Scan Library Files

**Auto-Scan:**
- Settings → Library → "Scan my library automatically"
- "Run a partial scan when changes are detected"

**Force Refresh:**
- Select library → ... → Refresh All

### Metadata Management

**Fix Incorrect Match:**
1. Find incorrectly matched item
2. ... menu → Fix Match
3. Search for correct title
4. Select correct match

**Edit Metadata:**
- ... menu → Edit
- Change title, poster, summary, etc.
- Unlock fields to override fetched data

**Refresh Metadata:**
- ... menu → Refresh Metadata
- Re-fetches from online sources

### Collections

**Auto Collections:**
- Settings → Libraries → Select library
- Advanced → Collections
- Enable "Use collection info from The Movie Database"

**Manual Collections:**
1. Select movies → Edit → Tags → Collection
2. Add collection name
3. Collection appears automatically

### Optimize Media

**Optimize Versions:**
- Settings → Convert automatically (Plex Pass)
- Creates optimized versions for specific devices
- Saves transcoding resources

## Advanced Topics

### Hardware Transcoding (Plex Pass Required)

**Intel QuickSync:**
```yaml
plex:
  devices:
    - /dev/dri:/dev/dri
```

Settings → Transcoder → Hardware acceleration:
- Enable: "Use hardware acceleration when available"
- Select: Intel QuickSync

**NVIDIA GPU:**
```yaml
plex:
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
    - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
```

Settings → Transcoder:
- Enable: "Use hardware acceleration when available"

**Verify:**
- Dashboard → Now Playing
- Check if "transcode (hw)" appears

### Remote Access

**Enable:**
1. Settings → Network → Remote Access
2. Click "Enable Remote Access"
3. Plex sets up automatically (UPnP)

**Manual Port Forward:**
- Router: Forward port 32400 to Plex server IP
- Settings → Network → Manually specify public port: 32400

**Custom Domain:**
- Settings → Network → Custom server access URLs
- Add: `https://plex.yourdomain.com:443`

### User Management

**Add Users:**
1. Settings → Users & Sharing → Add Friend
2. Enter email or username
3. Select libraries to share
4. Set restrictions (if any)

**Managed Users (Home Users):**
- Settings → Users & Sharing → Plex Home
- Create profiles for family members
- PIN protection
- Content restrictions

### Plex Pass Features

**Worth It For:**
- Hardware transcoding (essential for 4K)
- Mobile downloads
- Live TV & DVR
- Multiple user accounts (managed users)
- Camera upload
- Plex Dash (monitoring app)

**Get Plex Pass:**
- Monthly: $4.99
- Yearly: $39.99
- Lifetime: $119.99 (best value)

### Tautulli Integration

Monitor Plex activity:
```yaml
tautulli:
  image: linuxserver/tautulli
  volumes:
    - /opt/stacks/media/tautulli:/config
  environment:
    - PLEX_URL=http://plex:32400
```

Features:
- Watch statistics
- Activity monitoring
- Notifications
- User analytics

### Plugins and Extras

**Plugins:**
- Settings → Plugins
- Available plugins (deprecated by Plex)
- Use Sonarr/Radarr instead for acquisition

**Extras:**
- Behind the scenes
- Trailers
- Interviews
Place in movie/show folder with `-extras` suffix

## Troubleshooting

### Plex Not Accessible

```bash
# Check container status
docker ps | grep plex

# View logs
docker logs plex

# Test local access
curl http://localhost:32400/web

# Check network mode
docker inspect plex | grep NetworkMode
```

### Libraries Not Scanning

```bash
# Check permissions
ls -la /mnt/media/movies/

# Fix ownership
sudo chown -R 1000:1000 /mnt/media/

# Force scan
# Settings → Libraries → Scan Library Files

# Check logs
docker logs plex | grep -i scan
```

### Transcoding Issues

```bash
# Check transcode directory permissions
ls -la /tmp/plex-transcode/

# Ensure enough disk space
df -h /tmp

# Disable transcoding temporarily
# Settings → Transcoder → Transcoder quality: Maximum

# Check hardware acceleration
# Dashboard → Now Playing → Look for (hw)
```

### Buffering/Playback Issues

**Causes:**
- Network bandwidth
- Transcoding CPU overload
- Disk I/O bottleneck
- Insufficient RAM

**Solutions:**
- Lower streaming quality
- Enable hardware transcoding (Plex Pass)
- Use direct play when possible
- Upgrade network
- Optimize media files

### Remote Access Not Working

```bash
# Check port forwarding
# Router should forward 32400 → Plex server

# Check Plex status
# Settings → Network → Remote Access → Test

# Manually specify port
# Settings → Network → Manually specify: 32400

# Check firewall
sudo ufw allow 32400/tcp
```

### Metadata Not Downloading

```bash
# Check internet connectivity
docker exec plex ping -c 3 metadata.provider.plex.tv

# Refresh metadata
# Select library → Refresh All

# Check agents
# Settings → Agents → Make sure agents are enabled

# Force re-match
# Item → Fix Match → Search again
```

### Database Corruption

```bash
# Stop Plex
docker stop plex

# Backup database
cp /opt/stacks/media/plex/config/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db /opt/backups/

# Repair database
docker run --rm -v /opt/stacks/media/plex/config:/config \
  linuxserver/plex \
  /usr/lib/plexmediaserver/Plex\ Media\ Server --repair

# Restart Plex
docker start plex
```

## Performance Optimization

### Transcoding

```yaml
# Use RAM disk for transcoding
volumes:
  - /dev/shm:/transcode
```

### Database Optimization

```bash
# Stop Plex
docker stop plex

# Vacuum database
sqlite3 "/opt/stacks/media/plex/config/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db" "VACUUM;"

# Restart
docker start plex
```

### Quality Settings

**Streaming Quality:**
- Settings → Network → Internet streaming quality
- Set based on upload bandwidth
- Lower = less transcoding

**Direct Play:**
- Settings → Network → Treat WAN IP As LAN Bandwidth
- Reduces unnecessary transcoding

## Security Best Practices

1. **Strong Password:** Use secure Plex account password
2. **2FA:** Enable two-factor authentication on Plex account
3. **Read-Only Media:** Mount media as `:ro` when possible
4. **Limited Sharing:** Only share with trusted users
5. **Secure Remote Access:** Use HTTPS only
6. **Regular Updates:** Keep Plex updated
7. **Monitor Activity:** Use Tautulli for user tracking
8. **PIN Protection:** Use PINs for managed users
9. **Network Isolation:** Consider separate network for media
10. **Firewall:** Restrict remote access if not needed

## Backup Strategy

**Critical Files:**
```bash
# Configuration and database
/opt/stacks/media/plex/config/Library/Application Support/Plex Media Server/

# Important:
- Plug-in Support/Databases/  # Watch history, metadata
- Metadata/  # Cached images
- Preferences.xml  # Settings
```

**Backup Script:**
```bash
#!/bin/bash
docker stop plex
tar -czf plex-backup-$(date +%Y%m%d).tar.gz \
  /opt/stacks/media/plex/config/
docker start plex
```

## Summary

Plex is the industry-leading media server offering:
- Professional interface and experience
- Universal device support
- Powerful transcoding
- Easy sharing with friends/family
- Active development and features
- Free with optional Plex Pass

**Perfect for:**
- Home media streaming
- Sharing with non-technical users
- Remote access needs
- Multi-device households
- Premium experience seekers

**Trade-offs:**
- Closed source
- Requires Plex account
- Some features require Plex Pass
- Phone sync requires Plex Pass
- More resource intensive than alternatives

**Remember:**
- Proper file naming is crucial
- Hardware transcoding needs Plex Pass
- Remote access requires port forwarding
- Share responsibly with trusted users
- Regular backups recommended
- Consider Plex Pass for full features
- Plex + Sonarr/Radarr = Perfect combo
