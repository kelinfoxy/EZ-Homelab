# Sonarr - TV Show Automation

## Table of Contents
- [Overview](#overview)
- [What is Sonarr?](#what-is-sonarr)
- [Why Use Sonarr?](#why-use-sonarr)
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
**Docker Image:** [linuxserver/sonarr](https://hub.docker.com/r/linuxserver/sonarr)  
**Default Stack:** `media.yml`  
**Web UI:** `https://sonarr.${DOMAIN}` or `http://SERVER_IP:8989`  
**Authentication:** Optional (configurable)  
**Ports:** 8989

## What is Sonarr?

Sonarr is a PVR (Personal Video Recorder) for Usenet and BitTorrent users. It watches for new episodes of your favorite shows and automatically downloads, sorts, and renames them. Think of it as your personal TV show manager that never sleeps.

### Key Features
- **Automatic Downloads:** Grabs new episodes as they air
- **Quality Management:** Choose preferred qualities and upgrades
- **Calendar:** See upcoming episodes at a glance
- **Series Tracking:** Monitor all your shows in one place
- **Episode Management:** Rename and organize automatically
- **Failed Download Handling:** Retry with different releases
- **Notifications:** Pushover, Telegram, Discord, etc.
- **Custom Scripts:** Run actions on import
- **List Integration:** Import shows from Trakt, IMDb, etc.
- **Multi-Language:** Profiles for different audio/subtitle languages

## Why Use Sonarr?

1. **Never Miss Episodes:** Automatic downloads when they air
2. **Quality Upgrades:** Replace with better quality over time
3. **Organization:** Consistent naming and folder structure
4. **Time Saving:** No manual searching and downloading
5. **Metadata Management:** Integrates with Plex/Jellyfin/Emby
6. **Season Packs:** Smart handling of season releases
7. **Backlog Management:** Track missing episodes
8. **Multi-Show Management:** Hundreds of shows easily
9. **Smart Search:** Finds best releases automatically
10. **Integration Ecosystem:** Works with downloaders and indexers

## How It Works

```
New Episode Airs
       ↓
Sonarr Checks RSS Feeds (Prowlarr)
       ↓
Evaluates Releases (Quality, Size, etc.)
       ↓
Sends Best Release to Downloader
(qBittorrent via Gluetun VPN)
       ↓
Monitors Download Progress
       ↓
Download Completes
       ↓
Sonarr Imports File
       ↓
Renames & Moves to Library
(/mnt/media/tv/)
       ↓
Plex/Jellyfin Auto-Scans
       ↓
Episode Available for Watching
```

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media/sonarr/config/    # Sonarr configuration
/mnt/downloads/                      # Download directory (from qBittorrent)
/mnt/media/tv/                       # Final TV library

TV Library Structure:
/mnt/media/tv/
  Show Name (Year)/
    Season 01/
      Show Name - S01E01 - Episode Name.mkv
      Show Name - S01E02 - Episode Name.mkv
```

### Environment Variables

```bash
# User permissions (must match file ownership)
PUID=1000
PGID=1000

# Timezone (for air times)
TZ=America/New_York
```

## Official Resources

- **Website:** https://sonarr.tv
- **Wiki:** https://wiki.servarr.com/sonarr
- **GitHub:** https://github.com/Sonarr/Sonarr
- **Discord:** https://discord.gg/sonarr
- **Reddit:** https://reddit.com/r/sonarr
- **Docker Hub:** https://hub.docker.com/r/linuxserver/sonarr

## Educational Resources

### Videos
- [Sonarr Setup Guide (Techno Tim)](https://www.youtube.com/watch?v=5rtGBwBuzQE)
- [Complete *arr Stack Tutorial](https://www.youtube.com/results?search_query=sonarr+radarr+prowlarr+setup)
- [Sonarr Quality Profiles](https://www.youtube.com/results?search_query=sonarr+quality+profiles)
- [Sonarr Custom Formats](https://www.youtube.com/results?search_query=sonarr+custom+formats)

### Articles & Guides
- [TRaSH Guides (Must Read!)](https://trash-guides.info/Sonarr/)
- [Quality Settings Guide](https://trash-guides.info/Sonarr/Sonarr-Setup-Quality-Profiles/)
- [Custom Formats Guide](https://trash-guides.info/Sonarr/sonarr-setup-custom-formats/)
- [Naming Scheme](https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/)
- [Servarr Wiki](https://wiki.servarr.com/sonarr)

### Concepts to Learn
- **Quality Profiles:** Define preferred qualities and upgrades
- **Custom Formats:** Advanced release filtering (HDR, Dolby Vision, etc.)
- **Release Profiles:** Preferred/ignored words
- **Indexers:** Sources for releases (via Prowlarr)
- **Root Folders:** Where shows are stored
- **Series Types:** Standard, Daily, Anime
- **Season Packs:** Full season releases
- **Cutoff:** Quality to stop upgrading at

## Docker Configuration

### Complete Service Definition

```yaml
sonarr:
  image: linuxserver/sonarr:latest
  container_name: sonarr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8989:8989"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media/sonarr/config:/config
    - /mnt/media/tv:/tv
    - /mnt/downloads:/downloads
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.sonarr.rule=Host(`sonarr.${DOMAIN}`)"
    - "traefik.http.routers.sonarr.entrypoints=websecure"
    - "traefik.http.routers.sonarr.tls.certresolver=letsencrypt"
    - "traefik.http.routers.sonarr.middlewares=authelia@docker"
    - "traefik.http.services.sonarr.loadbalancer.server.port=8989"
```

### Key Volume Mapping

```yaml
volumes:
  - /opt/stacks/media/sonarr/config:/config     # Sonarr settings
  - /mnt/media/tv:/tv                            # TV library (final location)
  - /mnt/downloads:/downloads                    # Download client folder
```

**Important:** Sonarr needs access to both download location and final library location to perform hardlinking (instant moves without copying).

## Initial Setup

### First Access

1. **Start Container:**
   ```bash
   docker compose up -d sonarr
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:8989`
   - Domain: `https://sonarr.yourdomain.com`

3. **Initial Configuration:**
   - Settings → Media Management
   - Settings → Profiles
   - Settings → Indexers (via Prowlarr)
   - Settings → Download Clients

### Media Management Settings

**Settings → Media Management:**

1. **Rename Episodes:** ✓ Enable
2. **Replace Illegal Characters:** ✓ Enable
3. **Standard Episode Format:**
   ```
   {Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Full}
   ```
   Example: `Breaking Bad - S01E01 - Pilot Bluray-1080p.mkv`

4. **Daily Episode Format:**
   ```
   {Series Title} - {Air-Date} - {Episode Title} {Quality Full}
   ```

5. **Anime Episode Format:**
   ```
   {Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Full}
   ```

6. **Series Folder Format:**
   ```
   {Series Title} ({Series Year})
   ```
   Example: `Breaking Bad (2008)`

7. **Season Folder Format:**
   ```
   Season {season:00}
   ```

8. **Root Folders:**
   - Add: `/tv`
   - This is where shows will be stored

**File Management:**
- ✓ Unmonitor Deleted Episodes
- ✓ Download Propers and Repacks: Prefer and Upgrade
- ✓ Analyze video files
- ✓ Use Hardlinks instead of Copy: Important for space saving!
- Minimum Free Space: 100 MB

### Quality Profiles

**Settings → Profiles → Quality Profiles:**

Default profile is fine, but recommended setup:

**HD-1080p Profile:**
1. Create new profile: "HD-1080p"
2. Upgrades Allowed: ✓
3. Upgrade Until: Bluray-1080p
4. Qualities (in order):
   - Bluray-1080p
   - WEB-1080p
   - HDTV-1080p
   - WEBDL-1080p
5. Save

**4K Profile (optional):**
- Name: "Ultra HD"
- Upgrade Until: Bluray-2160p
- Qualities: 4K variants

**Follow TRaSH Guides** for optimal quality profiles:
https://trash-guides.info/Sonarr/Sonarr-Setup-Quality-Profiles/

### Download Client Setup

**Settings → Download Clients → Add → qBittorrent:**

1. **Name:** qBittorrent
2. **Enable:** ✓
3. **Host:** `gluetun` (container name, if qBittorrent behind VPN)
4. **Port:** `8080`
5. **Username:** `admin` (default)
6. **Password:** `adminadmin` (default, change this!)
7. **Category:** `tv-sonarr`
8. **Priority:** Normal
9. **Test → Save**

**Important Settings:**
- ✓ Remove Completed: Download completed and seeding
- ✓ Remove Failed: Downloads that fail

### Indexer Setup (via Prowlarr)

Sonarr should get indexers automatically from Prowlarr (Sync):

**Manual Check:**
1. Settings → Indexers
2. Should see synced indexers from Prowlarr
3. Each should show "Test: Successful"

**If Not Synced:**
- Go to Prowlarr → Settings → Apps
- Add Sonarr application
- Prowlarr Server: `http://prowlarr:9696`
- Sonarr Server: `http://sonarr:8989`
- API Key: From Sonarr → Settings → General → API Key

### Adding Your First Show

1. **Click "Add Series"**
2. **Search:** Type show name (e.g., "Breaking Bad")
3. **Select** correct show from results
4. **Configure:**
   - Root Folder: `/tv`
   - Quality Profile: HD-1080p
   - Series Type: Standard (or Daily/Anime)
   - Season: All or specific seasons
   - ✓ Start search for missing episodes
5. **Add Series**

Sonarr will:
- Add show to database
- Search for all missing episodes
- Send downloads to qBittorrent
- Monitor for new episodes

## Advanced Topics

### Custom Formats (v4)

Custom Formats allow advanced filtering of releases:

**Settings → Custom Formats:**

Common custom formats:
- **HDR:** Prefer HDR versions
- **Dolby Vision:** DV support
- **Streaming Services:** Prefer specific services
- **Audio:** Atmos, TrueHD, DTS-X
- **Release Groups:** Prefer trusted groups

**Importing from TRaSH Guides:**
https://trash-guides.info/Sonarr/sonarr-setup-custom-formats/

**Example Use Cases:**
- Prefer HDR for 4K TV
- Avoid streaming service logos/watermarks
- Prefer lossless audio
- Prefer specific release groups (RARBG, etc.)

### Release Profiles (Deprecated in v4)

Replaced by Custom Formats in Sonarr v4.

### Series Types

**Standard:**
- Regular TV shows
- Season/Episode numbering
- Example: Breaking Bad S01E01

**Daily:**
- Talk shows, news
- Air date naming
- Example: The Daily Show 2024-01-01

**Anime:**
- Absolute episode numbering
- Example: One Piece 001

Set when adding series.

### Auto-Tagging

**Settings → Import Lists:**

Automatically add shows from:
- **Trakt Lists:** Your watchlist, popular shows
- **IMDb Lists:** Custom lists
- **Simkl Lists:** Another tracking service
- **MyAnimeList:** For anime

**Example: Trakt Watchlist**
1. Settings → Import Lists → Add → Trakt Watchlist
2. Authenticate with Trakt
3. Configure:
   - Quality Profile: HD-1080p
   - Root Folder: /tv
   - Monitor: All Episodes
   - Search: Yes
4. Save

Shows added to your Trakt watchlist auto-import to Sonarr!

### Notifications

**Settings → Connect → Add Notification:**

Popular options:
- **Plex:** Update libraries on import
- **Jellyfin:** Scan library
- **Discord:** New episode notifications
- **Telegram:** Mobile alerts
- **Pushover:** Push notifications
- **Email:** SMTP notifications

**Example: Plex**
1. Add → Plex Media Server
2. Host: `plex`
3. Port: `32400`
4. Auth Token: Get from Plex
5. Triggers: On Import, On Upgrade
6. Test → Save

### Custom Scripts

**Settings → Connect → Custom Script:**

Run scripts on events:
- On Download
- On Import
- On Upgrade
- On Rename
- On Delete

**Example Use Cases:**
- Notify external service
- Trigger backup
- Custom file processing
- Update external database

### Multiple Sonarr Instances

Run separate instances for different use cases:

**sonarr-4k.yml:**
```yaml
sonarr-4k:
  image: linuxserver/sonarr:latest
  container_name: sonarr-4k
  ports:
    - "8990:8989"
  volumes:
    - /opt/stacks/media/sonarr-4k/config:/config
    - /mnt/media/tv-4k:/tv
    - /mnt/downloads:/downloads
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
```

**Use Cases:**
- Separate 4K library
- Different quality standards
- Anime-specific instance
- Testing new settings

### Season Pack Handling

**Settings → Indexers → Edit Indexer:**
- Prefer Season Pack: Yes
- Season Pack Only: No

**How It Works:**
- Sonarr prefers full season downloads
- More efficient than individual episodes
- Only grabs if meets quality requirements

### V4 vs V3

**Sonarr v4 (Current):**
- Custom Formats replace Release Profiles
- Better quality management
- Improved UI
- SQLite database

**Sonarr v3 (Legacy):**
- Release Profiles
- Older interface
- Still supported

**Migration:**
- Automatic on update
- Backup first!
- Read changelog

## Troubleshooting

### Sonarr Can't Find Releases

```bash
# Check indexers
# Settings → Indexers → Test All

# Check Prowlarr sync
docker logs prowlarr | grep sonarr

# Check search
# Series → Manual Search → View logs

# Common causes:
# - No indexers configured
# - Indexers down
# - Release doesn't exist yet
# - Quality profile too restrictive
```

### Downloads Not Importing

```bash
# Check download client connection
# Settings → Download Clients → Test

# Check permissions
ls -la /mnt/downloads/
ls -la /mnt/media/tv/

# Ensure Sonarr can access both
docker exec sonarr ls /downloads
docker exec sonarr ls /tv

# Check logs
docker logs sonarr | grep -i import

# Common issues:
# - Permission denied
# - Wrong category in qBittorrent
# - File still seeding
# - Hardlink failed (different filesystems)
```

### Wrong Series Match

```bash
# Edit series
# Series → Select Show → Edit

# Fix match
# Search for correct series
# Update Series

# Or delete and re-add with correct match
```

### Upgrade Loop

```bash
# Sonarr keeps downloading same episode

# Check quality profile
# Ensure "Upgrade Until" is set correctly

# Check custom formats
# May be scoring releases incorrectly

# Check file already exists
# Series → Select Episode → Delete file
# Sonarr may think existing file doesn't meet requirements
```

### Hardlink Errors

```bash
# Error: "Unable to hardlink"

# Check if /downloads and /tv on same filesystem
df -h /mnt/downloads
df -h /mnt/media/tv

# Must be on same mount point for hardlinks
# If different, Sonarr will copy instead

# Fix: Ensure both on same disk/volume
```

### Database Corruption

```bash
# Stop Sonarr
docker stop sonarr

# Backup database
cp /opt/stacks/media/sonarr/config/sonarr.db /opt/backups/

# Check database
sqlite3 /opt/stacks/media/sonarr/config/sonarr.db "PRAGMA integrity_check;"

# If corrupted, restore from backup
# Or let Sonarr rebuild (loses settings)
# rm /opt/stacks/media/sonarr/config/sonarr.db

docker start sonarr
```

## Performance Optimization

### RSS Sync Interval

**Settings → Indexers → Options:**
- RSS Sync Interval: 15 minutes (default)
- Lower for faster new episode detection
- Higher to reduce indexer load

### Reduce Database Size

```bash
# Stop Sonarr
docker stop sonarr

# Vacuum database
sqlite3 /opt/stacks/media/sonarr/config/sonarr.db "VACUUM;"

# Remove old history
# Settings → General → History Cleanup: 30 days

docker start sonarr
```

### Optimize Scanning

**Settings → Media Management:**
- Analyze video files: No (if not needed)
- Rescan Series Folder after Refresh: Only if Changed

Reduces I/O on library scans.

## Security Best Practices

1. **Enable Authentication:**
   - Settings → General → Security
   - Authentication: Required
   - Username and password

2. **API Key:**
   - Keep API key secure
   - Regenerate if compromised
   - Settings → General → API Key

3. **Reverse Proxy:**
   - Use Traefik + Authelia
   - Don't expose port 8989 publicly

4. **Read-Only Media:**
   - Mount TV library as read-only if possible
   - Sonarr needs write for imports

5. **Network Isolation:**
   - Consider separate Docker network
   - Only connect to necessary services

6. **Regular Backups:**
   - Backup `/config` directory
   - Includes database and settings

7. **Update Regularly:**
   - Keep Sonarr updated
   - Check release notes

## Backup Strategy

**Critical Files:**
```bash
/opt/stacks/media/sonarr/config/sonarr.db     # Database
/opt/stacks/media/sonarr/config/config.xml    # Settings
/opt/stacks/media/sonarr/config/Backup/       # Built-in backups
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/sonarr

# Create backup
docker exec sonarr cp /config/sonarr.db /config/backup-manual-$DATE.db

# Copy to backup location
cp /opt/stacks/media/sonarr/config/sonarr.db $BACKUP_DIR/sonarr-$DATE.db

# Keep last 7 days
find $BACKUP_DIR -name "sonarr-*.db" -mtime +7 -delete
```

**Restore:**
```bash
docker stop sonarr
cp /opt/backups/sonarr/sonarr-20240101.db /opt/stacks/media/sonarr/config/sonarr.db
docker start sonarr
```

## Integration with Other Services

### Sonarr + Plex/Jellyfin
- Auto-update library on import
- Settings → Connect → Plex/Jellyfin

### Sonarr + Prowlarr
- Automatic indexer management
- Centralized indexer configuration
- Prowlarr syncs to Sonarr

### Sonarr + qBittorrent (via Gluetun)
- Download client for torrents
- Behind VPN for safety
- Automatic import after download

### Sonarr + Jellyseerr
- User requests interface
- Jellyseerr sends to Sonarr
- Automated fulfillment

### Sonarr + Tautulli
- Track Sonarr additions via Plex
- Statistics on new episodes

## Summary

Sonarr is the essential TV show automation tool offering:
- Automatic episode downloads
- Quality management and upgrades
- Organized library structure
- Calendar and tracking
- Integration with downloaders and media servers
- Completely free and open-source

**Perfect for:**
- TV show enthusiasts
- Automated media management
- Quality upgraders
- Multiple show tracking
- Integration with *arr stack

**Key Points:**
- Follow TRaSH Guides for optimal setup
- Use quality profiles wisely
- Hardlinks save disk space
- Pair with Prowlarr for indexers
- Pair with qBittorrent + Gluetun for downloads
- Regular backups recommended
- RSS sync keeps you up-to-date

**Remember:**
- Proper file permissions crucial
- Same filesystem for hardlinks
- Quality profiles control upgrades
- Custom formats for advanced filtering
- Monitor RSS sync interval
- Keep API key secure
- Test indexers regularly

Sonarr + Radarr + Prowlarr + qBittorrent = Perfect media automation stack!
