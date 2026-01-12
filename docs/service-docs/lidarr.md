# Lidarr - Music Automation

## Table of Contents
- [Overview](#overview)
- [What is Lidarr?](#what-is-lidarr)
- [Why Use Lidarr?](#why-use-lidarr)
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
**Docker Image:** [linuxserver/lidarr](https://hub.docker.com/r/linuxserver/lidarr)  
**Default Stack:** `media-extended.yml`  
**Web UI:** `https://lidarr.${DOMAIN}` or `http://SERVER_IP:8686`  
**Authentication:** Optional (configurable)  
**Ports:** 8686

## What is Lidarr?

Lidarr is a music collection manager for Usenet and BitTorrent users. It's the music equivalent of Sonarr (TV) and Radarr (movies), designed to monitor for new album releases from your favorite artists, automatically download them, and organize your music library with proper metadata and tagging.

### Key Features
- **Automatic Downloads:** New releases from monitored artists
- **Quality Management:** MP3, FLAC, lossless preferences
- **Artist Management:** Track favorite artists
- **Album Tracking:** Monitor discographies
- **Calendar:** Upcoming album releases
- **Metadata Enrichment:** Album art, artist info, tags
- **Format Support:** MP3, FLAC, M4A, OGG, WMA
- **MusicBrainz Integration:** Accurate metadata
- **Multiple Quality Tiers:** Lossy vs lossless
- **Plex/Jellyfin Integration:** Library updates

## Why Use Lidarr?

1. **Never Miss Releases:** Auto-download new albums
2. **Library Organization:** Consistent structure
3. **Quality Control:** FLAC for archival, MP3 for portable
4. **Complete Discographies:** Track all artist releases
5. **Metadata Automation:** Proper tags and artwork
6. **Format Flexibility:** Multiple quality profiles
7. **Missing Album Detection:** Find gaps in collection
8. **Time Saving:** No manual searching
9. **Free & Open Source:** No cost
10. **Integration:** Works with music players and servers

## How It Works

```
New Album Release (Artist Monitored)
          ↓
Lidarr Checks RSS Feeds (Prowlarr)
          ↓
Evaluates Releases (Quality, Format)
          ↓
Sends to qBittorrent (via Gluetun VPN)
          ↓
Download Completes
          ↓
Lidarr Imports & Tags
          ↓
Library Updated
(/mnt/media/music/)
          ↓
Plex/Jellyfin/Subsonic Access
```

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media-extended/lidarr/config/    # Lidarr configuration
/mnt/downloads/complete/music-lidarr/        # Downloaded music
/mnt/media/music/                            # Final music library

Library Structure:
/mnt/media/music/
  Artist Name/
    Album Name (Year)/
      01 - Track Name.flac
      02 - Track Name.flac
      cover.jpg
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

- **Website:** https://lidarr.audio
- **Wiki:** https://wiki.servarr.com/lidarr
- **GitHub:** https://github.com/Lidarr/Lidarr
- **Discord:** https://discord.gg/lidarr
- **Reddit:** https://reddit.com/r/lidarr
- **Docker Hub:** https://hub.docker.com/r/linuxserver/lidarr

## Educational Resources

### Videos
- [Lidarr Setup Guide](https://www.youtube.com/results?search_query=lidarr+setup)
- [*arr Stack Music Management](https://www.youtube.com/results?search_query=lidarr+music+automation)
- [Lidarr Quality Profiles](https://www.youtube.com/results?search_query=lidarr+quality+profiles)

### Articles & Guides
- [Official Documentation](https://wiki.servarr.com/lidarr)
- [Servarr Wiki](https://wiki.servarr.com/)
- [Quality Settings Guide](https://wiki.servarr.com/lidarr/settings#quality-profiles)

### Concepts to Learn
- **Quality Profiles:** Lossy vs lossless preferences
- **Metadata Profiles:** What to download (albums, EPs, singles)
- **Release Profiles:** Preferred sources (WEB, CD)
- **MusicBrainz:** Music metadata database
- **Bitrate:** Audio quality measurement
- **Lossless:** FLAC, ALAC (no quality loss)
- **Lossy:** MP3, AAC (compressed)

## Docker Configuration

### Complete Service Definition

```yaml
lidarr:
  image: linuxserver/lidarr:latest
  container_name: lidarr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8686:8686"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media-extended/lidarr/config:/config
    - /mnt/media/music:/music
    - /mnt/downloads:/downloads
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.lidarr.rule=Host(`lidarr.${DOMAIN}`)"
    - "traefik.http.routers.lidarr.entrypoints=websecure"
    - "traefik.http.routers.lidarr.tls.certresolver=letsencrypt"
    - "traefik.http.routers.lidarr.middlewares=authelia@docker"
    - "traefik.http.services.lidarr.loadbalancer.server.port=8686"
```

## Initial Setup

### First Access

1. **Start Container:**
   ```bash
   docker compose up -d lidarr
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:8686`
   - Domain: `https://lidarr.yourdomain.com`

3. **Initial Configuration:**
   - Settings → Media Management
   - Settings → Profiles
   - Settings → Indexers (via Prowlarr)
   - Settings → Download Clients

### Media Management Settings

**Settings → Media Management:**

1. **Rename Tracks:** ✓ Enable
2. **Replace Illegal Characters:** ✓ Enable

3. **Standard Track Format:**
   ```
   {Album Type}/{Artist Name} - {Album Title} ({Release Year})/{medium:00}{track:00} - {Track Title}
   ```
   Example: `Studio/Pink Floyd - The Dark Side of the Moon (1973)/0101 - Speak to Me.flac`

4. **Artist Folder Format:**
   ```
   {Artist Name}
   ```

5. **Album Folder Format:**
   ```
   {Album Title} ({Release Year})
   ```

6. **Root Folders:**
   - Add: `/music`

**File Management:**
- ✓ Unmonitor Deleted Tracks
- ✓ Use Hardlinks instead of Copy
- Minimum Free Space: 100 MB
- ✓ Import Extra Files: Artwork (cover.jpg, folder.jpg)

### Metadata Profiles

**Settings → Profiles → Metadata Profiles:**

**Standard Profile:**
- Albums: ✓
- EPs: ✓ (optional)
- Singles: ✗ (usually skip)
- Live: ✗ (optional)
- Compilation: ✗ (optional)
- Remix: ✗ (optional)
- Soundtrack: ✗ (optional)

**Complete Discography Profile:**
- Enable all types
- For die-hard fans wanting everything

### Quality Profiles

**Settings → Profiles → Quality Profiles:**

**FLAC (Lossless) Profile:**
1. Name: "Lossless"
2. Upgrades Allowed: ✓
3. Upgrade Until: FLAC
4. Qualities (in order):
   - FLAC
   - ALAC
   - FLAC 24bit (if available)

**MP3 (Lossy) Profile:**
1. Name: "High Quality MP3"
2. Upgrade Until: MP3-320
3. Qualities:
   - MP3-320
   - MP3-VBR-V0
   - MP3-256

**Hybrid Profile:**
- FLAC preferred
- Fall back to MP3-320

### Download Client Setup

**Settings → Download Clients → Add → qBittorrent:**

1. **Name:** qBittorrent
2. **Host:** `gluetun`
3. **Port:** `8080`
4. **Username:** `admin`
5. **Password:** Your password
6. **Category:** `music-lidarr`
7. **Test → Save**

### Indexer Setup (via Prowlarr)

**Prowlarr Integration:**
- Prowlarr → Settings → Apps → Add Lidarr
- Sync Categories: Audio/MP3, Audio/Lossless, Audio/Other
- Auto-syncs indexers

**Verify:**
- Settings → Indexers
- Should see synced indexers from Prowlarr

### Adding Your First Artist

1. **Click "Add New"**
2. **Search:** Artist name (e.g., "Pink Floyd")
3. **Select** correct artist (check MusicBrainz link)
4. **Configure:**
   - Root Folder: `/music`
   - Monitor: All Albums (or Future Albums)
   - Metadata Profile: Standard
   - Quality Profile: Lossless
   - ✓ Search for missing albums
5. **Add Artist**

## Advanced Topics

### Quality Definitions

**Settings → Quality → Quality Definitions:**

Adjust bitrate ranges:

**MP3-320:**
- Min: 310 kbps
- Max: 330 kbps

**MP3-VBR-V0:**
- Min: 220 kbps
- Max: 260 kbps

**FLAC:**
- Min: 600 kbps
- Preferred: 900-1400 kbps

### Release Profiles

**Settings → Profiles → Release Profiles:**

**Preferred Sources:**
- Must Contain: `WEB|CD|FLAC`
- Must Not Contain: `MP3|128|192` (if targeting lossless)
- Score: +10

**Avoid:**
- Must Not Contain: `REPACK|PROPER` (unless needed)
- Score: -10

### Import Lists

**Settings → Import Lists:**

**Spotify Integration:** (if available)
- Import playlists
- Auto-add followed artists

**Last.fm:**
- Import top artists
- Discover new music

**MusicBrainz:**
- Import artist discography
- Series/compilation tracking

### Notifications

**Settings → Connect:**

Popular notifications:
- **Plex:** Update library on import
- **Jellyfin:** Scan library
- **Discord:** New release alerts
- **Telegram:** Mobile notifications
- **Last.fm:** Scrobble integration
- **Custom Webhook:** External services

**Example: Plex**
1. Add → Plex Media Server
2. Host: `plex`
3. Port: `32400`
4. Auth Token: From Plex
5. Triggers: On Import, On Upgrade
6. Update Library: ✓
7. Test → Save

### Custom Scripts

**Settings → Connect → Custom Script:**

Run scripts on events:
- On Download
- On Import
- On Upgrade
- On Rename
- On Retag

**Use Cases:**
- Convert formats (FLAC → MP3 for mobile)
- Sync to music player
- Update external database
- Backup to cloud

### Retagging

**Automatic tag updates:**

**Settings → Media Management → Retagging:**
- ✓ Write tags to audio files
- Tag separator: `;` or `/`
- Standard tags: Artist, Album, Track, Year
- Additional tags: Genre, Comment, AlbumArtist

**Manual Retag:**
- Select album → Retag
- Updates all file tags with correct metadata

### Multiple Instances

**Separate instances for different use cases:**

**lidarr-lossless.yml:**
```yaml
lidarr-lossless:
  image: linuxserver/lidarr:latest
  container_name: lidarr-lossless
  ports:
    - "8687:8686"
  volumes:
    - /opt/stacks/media-extended/lidarr-lossless/config:/config
    - /mnt/media/music-flac:/music
    - /mnt/downloads:/downloads
```

**Use Cases:**
- Separate FLAC library
- Different quality standards
- Genre-specific instances

## Troubleshooting

### Lidarr Not Finding Albums

```bash
# Check indexers
# Settings → Indexers → Test All

# Check Prowlarr sync
docker logs prowlarr | grep lidarr

# Manual search
# Artist → Album → Manual Search

# Common issues:
# - No indexers with music categories
# - Album not released yet
# - Quality profile too restrictive
# - Wrong artist match (check MusicBrainz ID)
```

### Downloads Not Importing

```bash
# Check permissions
ls -la /mnt/downloads/complete/music-lidarr/
ls -la /mnt/media/music/

# Fix ownership
sudo chown -R 1000:1000 /mnt/media/music/

# Verify Lidarr access
docker exec lidarr ls /downloads
docker exec lidarr ls /music

# Check logs
docker logs lidarr | grep -i import

# Common issues:
# - Permission denied
# - Wrong category in qBittorrent
# - Format not in quality profile
# - Hardlink failed (different filesystems)
```

### Wrong Artist Match

```bash
# Search by MusicBrainz ID for accuracy
# Find MusicBrainz ID on musicbrainz.org
# Add New → Search: mbid:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

# Edit artist
# Library → Select Artist → Edit
# Search for correct match

# Check MusicBrainz link
# Ensure correct artist selected
```

### Tagging Issues

```bash
# Check tagging settings
# Settings → Media Management → Retagging

# Manual retag
# Select album → Retag

# Check file tags
docker exec lidarr exiftool /music/Artist/Album/track.flac

# Common issues:
# - Write tags disabled
# - File format doesn't support tags
# - Permission errors
```

### Database Corruption

```bash
# Stop Lidarr
docker stop lidarr

# Backup database
cp /opt/stacks/media-extended/lidarr/config/lidarr.db /opt/backups/

# Check integrity
sqlite3 /opt/stacks/media-extended/lidarr/config/lidarr.db "PRAGMA integrity_check;"

# Restore from backup if corrupted
docker start lidarr
```

## Performance Optimization

### RSS Sync Interval

**Settings → Indexers → Options:**
- RSS Sync Interval: 60 minutes
- Music releases less frequently

### Database Optimization

```bash
# Stop Lidarr
docker stop lidarr

# Vacuum database
sqlite3 /opt/stacks/media-extended/lidarr/config/lidarr.db "VACUUM;"

# Clear old history
# Settings → General → History Cleanup: 30 days

docker start lidarr
```

### Scan Optimization

**Settings → Media Management:**
- Analyze audio files: No (if not needed)
- Rescan folder after refresh: Only if changed

## Security Best Practices

1. **Enable Authentication:**
   - Settings → General → Security
   - Authentication: Required

2. **API Key Security:**
   - Keep API key secure
   - Regenerate if compromised

3. **Reverse Proxy:**
   - Use Traefik + Authelia
   - Don't expose port 8686 publicly

4. **Regular Backups:**
   - Backup `/config` directory
   - Includes database and settings

## Backup Strategy

**Critical Files:**
```bash
/opt/stacks/media-extended/lidarr/config/lidarr.db     # Database
/opt/stacks/media-extended/lidarr/config/config.xml    # Settings
/opt/stacks/media-extended/lidarr/config/Backup/       # Auto backups
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/lidarr

cp /opt/stacks/media-extended/lidarr/config/lidarr.db $BACKUP_DIR/lidarr-$DATE.db
find $BACKUP_DIR -name "lidarr-*.db" -mtime +7 -delete
```

## Integration with Other Services

### Lidarr + Prowlarr
- Centralized indexer management
- Auto-sync music indexers

### Lidarr + qBittorrent (via Gluetun)
- Download music via VPN
- Category-based organization

### Lidarr + Plex/Jellyfin
- Auto-update music library
- Metadata sync
- Album artwork

### Lidarr + Last.fm
- Scrobbling integration
- Discover new artists
- Import listening history

### Lidarr + Beets
- Advanced tagging
- Music organization
- Duplicate detection

## Summary

Lidarr is the music automation tool offering:
- Automatic album downloads
- Artist and discography tracking
- Quality management (MP3, FLAC)
- Metadata and tagging
- MusicBrainz integration
- Free and open-source

**Perfect for:**
- Music collectors
- Audiophiles (FLAC support)
- Complete discography seekers
- Automated music management
- Plex/Jellyfin music users

**Key Points:**
- Monitor favorite artists
- Quality profiles for lossy/lossless
- Automatic metadata tagging
- MusicBrainz for accuracy
- Separate instances for different qualities
- Regular backups recommended

**Remember:**
- Use MusicBrainz ID for accurate matching
- FLAC for archival, MP3 for portable
- Retagging updates file metadata
- Monitor "All Albums" vs "Future Only"
- Hardlinks save disk space
- Keep API key secure

Lidarr completes your media automation stack with music management!
