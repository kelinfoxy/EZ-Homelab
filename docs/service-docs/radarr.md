# Radarr - Movie Automation

## Table of Contents
- [Overview](#overview)
- [What is Radarr?](#what-is-radarr)
- [Why Use Radarr?](#why-use-radarr)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Media Management & Automation  
**Docker Image:** [linuxserver/radarr](https://hub.docker.com/r/linuxserver/radarr)  
**Default Stack:** `media.yml`  
**Web UI:** `https://radarr.${DOMAIN}` or `http://SERVER_IP:7878`  
**Authentication:** Optional (configurable)  
**Ports:** 7878

## What is Radarr?

Radarr is a movie collection manager and automation tool for Usenet and BitTorrent. It's essentially Sonarr's sibling, but for movies. Radarr monitors for new movies you want, automatically downloads them when available, and organizes your movie library beautifully.

### Key Features
- **Automatic Downloads:** Grab movies as they release
- **Quality Management:** Choose preferred qualities and upgrades
- **Calendar:** Track movie releases
- **Movie Management:** Organize and rename automatically
- **Failed Download Handling:** Retry with different releases
- **Notifications:** Discord, Telegram, Pushover, etc.
- **Custom Scripts:** Automate workflows
- **List Integration:** Import from IMDb, Trakt, TMDb lists
- **Multiple Versions:** Keep different qualities of same movie
- **Collections:** Organize movie series/franchises

## Why Use Radarr?

1. **Never Miss Releases:** Auto-download on availability
2. **Quality Upgrades:** Replace with better versions over time
3. **Organization:** Consistent naming and structure
4. **Time Saving:** No manual searching
5. **Library Management:** Track watched, wanted, available
6. **4K Management:** Separate 4K from HD
7. **Collection Support:** Marvel, Star Wars, etc.
8. **Discovery:** Find new movies via lists
9. **Integration:** Works seamlessly with Plex/Jellyfin
10. **Free & Open Source:** No cost, community-driven

## How It Works

```
New Movie Release
       ↓
Radarr Checks RSS Feeds (Prowlarr)
       ↓
Evaluates Releases (Quality, Size, Custom Formats)
       ↓
Sends Best Release to Downloader
(qBittorrent via Gluetun VPN)
       ↓
Monitors Download Progress
       ↓
Download Completes
       ↓
Radarr Imports File
       ↓
Renames & Moves to Library
(/mnt/media/movies/)
       ↓
Plex/Jellyfin Auto-Scans
       ↓
Movie Available for Watching
```

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media/radarr/config/    # Radarr configuration
/mnt/downloads/                      # Download directory (from qBittorrent)
/mnt/media/movies/                   # Final movie library

Movie Library Structure:
/mnt/media/movies/
  The Matrix (1999)/
    The Matrix (1999) Bluray-1080p.mkv
  Inception (2010)/
    Inception (2010) Bluray-2160p.mkv
```

### Environment Variables

```bash
# User permissions (must match file ownership)
PUID=1000
PGID=1000

# Timezone
TZ=America/New_York
```

## Official Resources

- **Website:** https://radarr.video
- **Wiki:** https://wiki.servarr.com/radarr
- **GitHub:** https://github.com/Radarr/Radarr
- **Discord:** https://discord.gg/radarr
- **Reddit:** https://reddit.com/r/radarr
- **Docker Hub:** https://hub.docker.com/r/linuxserver/radarr

## Educational Resources

### Videos
- [Radarr Setup Guide (Techno Tim)](https://www.youtube.com/watch?v=5rtGBwBuzQE)
- [Complete *arr Stack Setup](https://www.youtube.com/results?search_query=radarr+sonarr+prowlarr+setup)
- [Radarr Quality Profiles](https://www.youtube.com/results?search_query=radarr+quality+profiles)
- [Radarr Custom Formats](https://www.youtube.com/results?search_query=radarr+custom+formats)

### Articles & Guides
- [TRaSH Guides (Essential!)](https://trash-guides.info/Radarr/)
- [Quality Settings Guide](https://trash-guides.info/Radarr/Radarr-Setup-Quality-Profiles/)
- [Custom Formats Guide](https://trash-guides.info/Radarr/radarr-setup-custom-formats/)
- [Naming Scheme](https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/)
- [Servarr Wiki](https://wiki.servarr.com/radarr)

### Concepts to Learn
- **Quality Profiles:** Define preferred qualities and upgrades
- **Custom Formats:** Advanced filtering (HDR, DV, Codecs, etc.)
- **Indexers:** Sources for releases (via Prowlarr)
- **Root Folders:** Where movies are stored
- **Minimum Availability:** When to search (Announced, In Cinemas, Released, Physical/Web)
- **Collections:** Movie franchises (MCU, DC, Star Wars)
- **Cutoff:** Quality to stop upgrading at

## Docker Configuration

### Complete Service Definition

```yaml
radarr:
  image: linuxserver/radarr:latest
  container_name: radarr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "7878:7878"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media/radarr/config:/config
    - /mnt/media/movies:/movies
    - /mnt/downloads:/downloads
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.radarr.rule=Host(`radarr.${DOMAIN}`)"
    - "traefik.http.routers.radarr.entrypoints=websecure"
    - "traefik.http.routers.radarr.tls.certresolver=letsencrypt"
    - "traefik.http.routers.radarr.middlewares=authelia@docker"
    - "traefik.http.services.radarr.loadbalancer.server.port=7878"
```

### Key Volume Mapping

```yaml
volumes:
  - /opt/stacks/media/radarr/config:/config    # Radarr settings
  - /mnt/media/movies:/movies                   # Movie library (final location)
  - /mnt/downloads:/downloads                   # Download client folder
```

**Important:** Radarr needs access to both download and library locations for hardlinking (instant moves without copying).

## Initial Setup

### First Access

1. **Start Container:**
   ```bash
   docker compose up -d radarr
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:7878`
   - Domain: `https://radarr.yourdomain.com`

3. **Initial Configuration:**
   - Settings → Media Management
   - Settings → Profiles
   - Settings → Indexers (via Prowlarr)
   - Settings → Download Clients

### Media Management Settings

**Settings → Media Management:**

1. **Rename Movies:** ✓ Enable
2. **Replace Illegal Characters:** ✓ Enable
3. **Standard Movie Format:**
   ```
   {Movie Title} ({Release Year}) {Quality Full}
   ```
   Example: `The Matrix (1999) Bluray-1080p.mkv`

4. **Movie Folder Format:**
   ```
   {Movie Title} ({Release Year})
   ```
   Example: `The Matrix (1999)`

5. **Root Folders:**
   - Add: `/movies`
   - This is where movies will be stored

**File Management:**
- ✓ Unmonitor Deleted Movies
- ✓ Download Propers and Repacks: Prefer and Upgrade
- ✓ Analyze video files
- ✓ Use Hardlinks instead of Copy: Important for space saving!
- Minimum Free Space: 100 MB
- ✓ Import Extra Files: Subtitles (srt, sub)

### Quality Profiles

**Settings → Profiles → Quality Profiles:**

**HD-1080p Profile (Recommended):**
1. Create new profile: "HD-1080p"
2. Upgrades Allowed: ✓
3. Upgrade Until: Bluray-1080p
4. Minimum Custom Format Score: 0
5. Upgrade Until Custom Format Score: 10000
6. Qualities (in order of preference):
   - Bluray-1080p
   - Remux-1080p (optional, large files)
   - WEB-1080p
   - HDTV-1080p
7. Save

**4K Profile (Optional):**
- Name: "Ultra HD"
- Upgrade Until: Bluray-2160p (Remux-2160p for best quality)
- Include HDR custom formats

**Follow TRaSH Guides** for optimal profiles:
https://trash-guides.info/Radarr/Radarr-Setup-Quality-Profiles/

### Download Client Setup

**Settings → Download Clients → Add → qBittorrent:**

1. **Name:** qBittorrent
2. **Enable:** ✓
3. **Host:** `gluetun` (if qBittorrent behind VPN)
4. **Port:** `8080`
5. **Username:** `admin`
6. **Password:** Your password
7. **Category:** `movies-radarr`
8. **Priority:** Normal
9. **Test → Save**

**Settings:**
- ✓ Remove Completed: Download completed and seeding
- ✓ Remove Failed: Failed downloads

### Indexer Setup (via Prowlarr)

Radarr should get indexers automatically from Prowlarr:

**Check Sync:**
1. Settings → Indexers
2. Should see synced indexers from Prowlarr
3. Test: Each should show "Successful"

**If Not Synced:**
- Prowlarr → Settings → Apps → Add Radarr
- Prowlarr Server: `http://prowlarr:9696`
- Radarr Server: `http://radarr:7878`
- API Key: From Radarr → Settings → General

### Adding Your First Movie

1. **Click "Add New"**
2. **Search:** Type movie name (e.g., "The Matrix")
3. **Select** correct movie from results
4. **Configure:**
   - Root Folder: `/movies`
   - Quality Profile: HD-1080p
   - Minimum Availability: Released (or Physical/Web)
   - ✓ Start search for movie
5. **Add Movie**

Radarr will:
- Add movie to database
- Search for best release
- Send to qBittorrent
- Monitor download
- Import when complete

## Advanced Topics

### Custom Formats

Custom Formats are the powerhouse of Radarr v4+, allowing precise control over releases.

**Settings → Custom Formats:**

**Common Custom Formats:**

1. **HDR Formats:**
   - HDR
   - HDR10+
   - Dolby Vision
   - HLG

2. **Audio Formats:**
   - Dolby Atmos
   - TrueHD
   - DTS-X
   - DTS-HD MA

3. **Release Groups:**
   - Preferred groups (RARBG, FGT, etc.)
   - Avoid groups (known bad quality)

4. **Resolution:**
   - 4K DV HDR10
   - 1080p

5. **Streaming Service:**
   - Netflix
   - Amazon
   - Apple TV+
   - Disney+

**Importing TRaSH Guides:**
https://trash-guides.info/Radarr/radarr-setup-custom-formats/

**Scoring Custom Formats:**
- Assign scores to formats
- Higher score = more preferred
- Negative scores = avoid
- Cutoff score = stop upgrading

**Example Scoring:**
- Dolby Vision: +100
- HDR10+: +75
- HDR: +50
- DTS-X: +30
- Dolby Atmos: +30
- Preferred Group: +10
- Bad Group: -1000

### Minimum Availability

**When should Radarr search for a movie?**

- **Announced:** As soon as announced (usually too early)
- **In Cinemas:** Theatrical release (usually only cams available)
- **Released:** Digital/Physical release announced
- **Physical/Web:** When officially released (best option)

**Recommendation:** Physical/Web for quality releases.

### Collections

**Movie Collections:**
- Automatically group franchises
- Marvel Cinematic Universe
- Star Wars
- James Bond
- etc.

**Settings → Metadata:**
- ✓ Enable Collections

**Managing Collections:**
- Movies → Collections tab
- View all movies in collection
- Add entire collection at once

**Auto-add Collection:**
- Edit movie → Collection → Monitor Collection
- Automatically adds all movies in franchise

### Multiple Radarr Instances

Run separate instances for different libraries:

**radarr-4k.yml:**
```yaml
radarr-4k:
  image: linuxserver/radarr:latest
  container_name: radarr-4k
  ports:
    - "7879:7878"
  volumes:
    - /opt/stacks/media/radarr-4k/config:/config
    - /mnt/media/movies-4k:/movies
    - /mnt/downloads:/downloads
  environment:
    - PUID=1000
    - PGID=1000
```

**Use Cases:**
- Separate 4K library (different Plex library)
- Different quality standards
- Testing new settings
- Language-specific (anime, foreign films)

### Import Lists

**Automatically add movies from lists:**

**Settings → Import Lists:**

**Trakt Lists:**
1. Add → Trakt List
2. Authenticate with Trakt
3. List Type: Watchlist, Popular, Trending, etc.
4. Quality Profile: HD-1080p
5. Monitor: Yes
6. Search on Add: Yes
7. Save

**IMDb Lists:**
1. Add → IMDb Lists
2. List ID: From IMDb list URL
3. Configure quality and monitoring

**TMDb Lists:**
- Popular Movies
- Upcoming Movies
- Top Rated

**Custom Lists:**
- Personal lists from various sources
- Auto-sync periodically

### Notifications

**Settings → Connect → Add Notification:**

**Popular Notifications:**
- **Plex:** Update library on import
- **Jellyfin:** Scan library
- **Discord:** New movie alerts
- **Telegram:** Mobile notifications
- **Pushover:** Push notifications
- **Email:** SMTP alerts
- **Webhook:** Custom integrations

**Example: Plex**
1. Add → Plex Media Server
2. Host: `plex`
3. Port: `32400`
4. Auth Token: From Plex
5. Triggers: On Download, On Import, On Upgrade
6. Update Library: ✓
7. Test → Save

### Custom Scripts

**Settings → Connect → Custom Script:**

Run scripts on events:
- On Grab
- On Download
- On Upgrade
- On Rename
- On Delete

**Use Cases:**
- External notifications
- File processing
- Metadata updates
- Backup triggers

### Quality Definitions

**Settings → Quality:**

Adjust size limits for qualities:

**Default Limits (MB per minute):**
- Bluray-2160p: 350-400
- Bluray-1080p: 60-100
- Bluray-720p: 25-50
- WEB-1080p: 25-50

**Adjust Based on:**
- Storage capacity
- Preference for quality vs. size
- Bandwidth limitations

## Troubleshooting

### Radarr Can't Find Releases

```bash
# Check indexers
# Settings → Indexers → Test All

# Check Prowlarr
docker logs prowlarr | grep radarr

# Manual search movie
# Movies → Movie → Manual Search → View logs

# Common causes:
# - No indexers
# - Movie not released yet
# - Quality profile too restrictive
# - Custom format scoring too high
```

### Downloads Not Importing

```bash
# Check download client
# Settings → Download Clients → Test

# Check permissions
ls -la /mnt/downloads/
ls -la /mnt/media/movies/

# Verify Radarr access
docker exec radarr ls /downloads
docker exec radarr ls /movies

# Check logs
docker logs radarr | grep -i import

# Common issues:
# - Permission denied
# - Wrong category in qBittorrent
# - Still seeding
# - Hardlink failed (different filesystems)
```

### Wrong Movie Match

```bash
# Edit movie
# Movies → Movie → Edit

# Search for correct movie
# Remove and re-add if necessary

# Check TMDb ID
# Ensure correct movie selected
```

### Constant Upgrades

```bash
# Movie keeps downloading

# Check quality profile cutoff
# Settings → Profiles → Cutoff should be set

# Check custom format scoring
# May be scoring new releases higher

# Lock quality
# Edit movie → Set specific quality → Don't upgrade
```

### Hardlink Errors

```bash
# "Unable to hardlink" error

# Check filesystem
df -h /mnt/downloads
df -h /mnt/media/movies

# Must be same filesystem for hardlinks
# If different, Radarr copies instead (slow)

# Solution: Both on same disk/mount
```

### Database Corruption

```bash
# Stop Radarr
docker stop radarr

# Backup database
cp /opt/stacks/media/radarr/config/radarr.db /opt/backups/

# Check integrity
sqlite3 /opt/stacks/media/radarr/config/radarr.db "PRAGMA integrity_check;"

# Restore from backup if corrupted
# rm /opt/stacks/media/radarr/config/radarr.db
# cp /opt/backups/radarr-DATE.db /opt/stacks/media/radarr/config/radarr.db

docker start radarr
```

## Performance Optimization

### RSS Sync Interval

**Settings → Indexers → Options:**
- RSS Sync Interval: 60 minutes (default)
- Movies release less frequently than TV
- Can increase interval to reduce load

### Database Optimization

```bash
# Stop Radarr
docker stop radarr

# Vacuum database
sqlite3 /opt/stacks/media/radarr/config/radarr.db "VACUUM;"

# Reduce history
# Settings → General → History Cleanup: 30 days

docker start radarr
```

### Optimize Scanning

**Settings → Media Management:**
- Analyze video files: No (if not needed)
- Rescan folder after refresh: Only if changed

### Limit Concurrent Downloads

**Settings → Download Clients:**
- Maximum Downloads: 5 (reasonable limit)
- Prevents overwhelming bandwidth

## Security Best Practices

1. **Enable Authentication:**
   - Settings → General → Security
   - Authentication: Required (Basic or Forms)

2. **API Key Security:**
   - Keep API key secret
   - Regenerate if compromised

3. **Reverse Proxy:**
   - Use Traefik + Authelia
   - Don't expose 7878 publicly

4. **Read-Only Media:**
   - Consider read-only mount for movies
   - Radarr needs write for imports

5. **Regular Backups:**
   - Backup `/config` directory
   - Includes database and settings

6. **Network Isolation:**
   - Separate Docker network
   - Only connect necessary services

7. **Keep Updated:**
   - Regular updates for security patches

## Backup Strategy

**Critical Files:**
```bash
/opt/stacks/media/radarr/config/radarr.db     # Database
/opt/stacks/media/radarr/config/config.xml    # Settings
/opt/stacks/media/radarr/config/Backup/       # Auto backups
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/radarr

# Manual backup trigger
docker exec radarr cp /config/radarr.db /config/backup-manual-$DATE.db

# Copy to backup location
cp /opt/stacks/media/radarr/config/radarr.db $BACKUP_DIR/radarr-$DATE.db

# Keep last 7 days
find $BACKUP_DIR -name "radarr-*.db" -mtime +7 -delete
```

**Restore:**
```bash
docker stop radarr
cp /opt/backups/radarr/radarr-20240101.db /opt/stacks/media/radarr/config/radarr.db
docker start radarr
```

## Integration with Other Services

### Radarr + Plex/Jellyfin
- Auto-update library on import
- Settings → Connect → Plex/Jellyfin

### Radarr + Prowlarr
- Centralized indexer management
- Auto-sync indexers
- Single source of truth

### Radarr + qBittorrent (via Gluetun)
- Download movies via VPN
- Automatic import after download
- Category-based organization

### Radarr + Jellyseerr
- User request interface
- Users request movies
- Radarr automatically downloads

### Radarr + Tautulli
- Track additions
- View statistics
- Popular movies

## Summary

Radarr is the essential movie automation tool offering:
- Automatic movie downloads
- Quality management and upgrades
- Organized movie library
- Custom format scoring
- Collection management
- Free and open-source

**Perfect for:**
- Movie collectors
- Automated library management
- Quality enthusiasts
- 4K collectors
- Collection completionists

**Key Points:**
- Follow TRaSH Guides for best setup
- Custom formats are powerful
- Use Physical/Web minimum availability
- Hardlinks save massive disk space
- Pair with Prowlarr for indexers
- Pair with qBittorrent + Gluetun
- Separate 4K instance recommended

**Remember:**
- Proper file permissions essential
- Same filesystem for hardlinks
- Quality profile cutoff important
- Custom format scoring controls upgrades
- Collections make franchises easy
- Regular backups crucial
- Test indexers periodically

Sonarr + Radarr + Prowlarr + qBittorrent = Complete media automation!
