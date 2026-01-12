# Readarr - Book & Audiobook Automation

## Table of Contents
- [Overview](#overview)
- [What is Readarr?](#what-is-readarr)
- [Why Use Readarr?](#why-use-readarr)
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
**Docker Image:** [linuxserver/readarr](https://hub.docker.com/r/linuxserver/readarr)  
**Default Stack:** `media-extended.yml`  
**Web UI:** `https://readarr.${DOMAIN}` or `http://SERVER_IP:8787`  
**Authentication:** Optional (configurable)  
**Ports:** 8787

## What is Readarr?

Readarr is an ebook and audiobook collection manager for Usenet and BitTorrent users. It's part of the *arr family (like Sonarr for TV and Radarr for movies), but specifically designed for books. Readarr monitors for new book releases, automatically downloads them, and organizes your library with proper metadata.

### Key Features
- **Automatic Downloads:** New releases from monitored authors
- **Quality Management:** Ebook vs audiobook, formats
- **Author Management:** Track favorite authors
- **Series Tracking:** Monitor book series
- **Calendar:** Upcoming releases
- **Metadata Enrichment:** Book covers, descriptions, ISBNs
- **Format Support:** EPUB, MOBI, AZW3, PDF, MP3, M4B
- **GoodReads Integration:** Import reading lists
- **Multiple Libraries:** Fiction, non-fiction, audiobooks
- **Calibre Integration:** Works with Calibre libraries

## Why Use Readarr?

1. **Never Miss Releases:** Auto-download new books from favorite authors
2. **Library Organization:** Consistent structure and naming
3. **Format Flexibility:** Multiple ebook formats
4. **Series Management:** Track reading order
5. **Metadata Automation:** Covers, descriptions, authors
6. **GoodReads Integration:** Import want-to-read lists
7. **Audiobook Support:** Unified management
8. **Time Saving:** No manual searching
9. **Free & Open Source:** No cost
10. **Calibre Compatible:** Works with existing libraries

## How It Works

```
New Book Release (Author Monitored)
          ↓
Readarr Checks RSS Feeds (Prowlarr)
          ↓
Evaluates Releases (Format, Quality)
          ↓
Sends to qBittorrent (via Gluetun VPN)
          ↓
Download Completes
          ↓
Readarr Imports & Organizes
          ↓
Library Updated
(/mnt/media/books/)
          ↓
Calibre-Web / Calibre Access
```

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media-extended/readarr/config/    # Readarr configuration
/mnt/downloads/complete/books-readarr/        # Downloaded books
/mnt/media/books/                             # Final book library

Library Structure:
/mnt/media/books/
  Author Name/
    Series Name/
      Book 01 - Title (Year).epub
      Book 02 - Title (Year).epub
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

- **Website:** https://readarr.com
- **Wiki:** https://wiki.servarr.com/readarr
- **GitHub:** https://github.com/Readarr/Readarr
- **Discord:** https://discord.gg/readarr
- **Reddit:** https://reddit.com/r/readarr
- **Docker Hub:** https://hub.docker.com/r/linuxserver/readarr

## Educational Resources

### Videos
- [Readarr Setup Guide](https://www.youtube.com/results?search_query=readarr+setup)
- [*arr Stack Complete Guide](https://www.youtube.com/results?search_query=readarr+sonarr+radarr)
- [Readarr + Calibre](https://www.youtube.com/results?search_query=readarr+calibre)

### Articles & Guides
- [Official Documentation](https://wiki.servarr.com/readarr)
- [Servarr Wiki](https://wiki.servarr.com/)
- [Calibre Integration](https://wiki.servarr.com/readarr/settings#calibre)

### Concepts to Learn
- **Metadata Profiles:** Preferred ebook formats
- **Quality Profiles:** Quality and format preferences
- **Release Profiles:** Preferred/avoided release groups
- **Root Folders:** Library locations
- **Author vs Book:** Monitoring modes
- **GoodReads Lists:** Import reading lists
- **Calibre Content Server:** Integration

## Docker Configuration

### Complete Service Definition

```yaml
readarr:
  image: linuxserver/readarr:develop  # Use develop tag
  container_name: readarr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8787:8787"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media-extended/readarr/config:/config
    - /mnt/media/books:/books
    - /mnt/downloads:/downloads
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.readarr.rule=Host(`readarr.${DOMAIN}`)"
    - "traefik.http.routers.readarr.entrypoints=websecure"
    - "traefik.http.routers.readarr.tls.certresolver=letsencrypt"
    - "traefik.http.routers.readarr.middlewares=authelia@docker"
    - "traefik.http.services.readarr.loadbalancer.server.port=8787"
```

**Note:** Use `develop` tag for latest features. Readarr is still in active development.

## Initial Setup

### First Access

1. **Start Container:**
   ```bash
   docker compose up -d readarr
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:8787`
   - Domain: `https://readarr.yourdomain.com`

3. **Initial Configuration:**
   - Settings → Media Management
   - Settings → Profiles
   - Settings → Indexers (via Prowlarr)
   - Settings → Download Clients

### Media Management Settings

**Settings → Media Management:**

1. **Rename Books:** ✓ Enable
2. **Replace Illegal Characters:** ✓ Enable

3. **Standard Book Format:**
   ```
   {Author Name}/{Series Title}/{Series Title} - {Book #} - {Book Title} ({Release Year})
   ```
   Example: `Brandon Sanderson/Mistborn/Mistborn - 01 - The Final Empire (2006).epub`

4. **Author Folder Format:**
   ```
   {Author Name}
   ```

5. **Root Folders:**
   - Add: `/books`

**File Management:**
- ✓ Unmonitor Deleted Books
- ✓ Use Hardlinks instead of Copy
- Minimum Free Space: 100 MB
- ✓ Import Extra Files

### Metadata Profiles

**Settings → Profiles → Metadata Profiles:**

Default profile includes:
- Ebook formats (EPUB, MOBI, AZW3, PDF)
- Audiobook formats (MP3, M4B, M4A)

**Custom Profile Example:**
- Name: "Ebooks Only"
- Include: EPUB, MOBI, AZW3, PDF
- Exclude: Audio formats

### Quality Profiles

**Settings → Profiles → Quality Profiles:**

**Ebook Profile:**
1. Name: "Ebook - High Quality"
2. Upgrades Allowed: ✓
3. Upgrade Until: EPUB
4. Qualities (in order):
   - EPUB
   - AZW3
   - MOBI
   - PDF (lowest priority)

**Audiobook Profile:**
1. Name: "Audiobook"
2. Upgrade Until: M4B (best for chapters)
3. Qualities:
   - M4B
   - MP3

### Download Client Setup

**Settings → Download Clients → Add → qBittorrent:**

1. **Name:** qBittorrent
2. **Host:** `gluetun`
3. **Port:** `8080`
4. **Username:** `admin`
5. **Password:** Your password
6. **Category:** `books-readarr`
7. **Test → Save**

### Indexer Setup (via Prowlarr)

**Prowlarr Integration:**
- Prowlarr → Settings → Apps → Add Readarr
- Sync Categories: Books/Ebook, Books/Audiobook
- Auto-syncs indexers to Readarr

**Verify:**
- Settings → Indexers
- Should see synced indexers from Prowlarr

### Adding Your First Author

1. **Click "Add New"**
2. **Search:** Author name (e.g., "Brandon Sanderson")
3. **Select** correct author
4. **Configure:**
   - Root Folder: `/books`
   - Monitor: All Books (or Future Books)
   - Metadata Profile: Standard
   - Quality Profile: Ebook - High Quality
   - ✓ Search for missing books
5. **Add Author**

### Adding Individual Books

1. **Library → Add New → Search for a book**
2. **Search:** Book title or ISBN
3. **Select** correct book
4. **Configure:**
   - Root Folder: `/books`
   - Monitor: Yes
   - Quality Profile: Ebook - High Quality
   - ✓ Start search for book
5. **Add Book**

## Advanced Topics

### GoodReads Integration

**Import Reading Lists:**

**Settings → Import Lists → Add → GoodReads Lists:**

1. **Access Token:** Get from GoodReads
2. **User ID:** Your GoodReads ID
3. **List Name:** "to-read" or custom list
4. **Root Folder:** `/books`
5. **Quality Profile:** Ebook - High Quality
6. **Monitor:** Yes
7. **Search on Add:** Yes
8. **Save**

**Auto-sync periodically** to import new books from your GoodReads lists.

### Calibre Integration

**If you use Calibre:**

**Settings → Calibre:**

1. **Host:** IP of Calibre server
2. **Port:** `8080` (default)
3. **Username/Password:** If Calibre requires auth
4. **Library:** Name of Calibre library
5. **Save**

**Options:**
- Use Calibre for metadata
- Export to Calibre on import
- Sync with Calibre library

### Multiple Libraries

**Separate ebook and audiobook libraries:**

```yaml
readarr-audio:
  image: linuxserver/readarr:develop
  container_name: readarr-audio
  ports:
    - "8788:8787"
  volumes:
    - /opt/stacks/media-extended/readarr-audio/config:/config
    - /mnt/media/audiobooks:/books
    - /mnt/downloads:/downloads
  environment:
    - PUID=1000
    - PGID=1000
```

Separate instance for audiobooks with different quality profile.

### Metadata Management

**Edit Metadata:**
- Select book → Edit → Metadata
- Change title, author, description
- Upload custom cover
- Lock fields to prevent overwriting

**Refresh Metadata:**
- Right-click book → Refresh & Scan
- Re-fetches from online sources

### Series Management

**Monitor Entire Series:**
1. Add author
2. View author page
3. Series tab → Select series
4. Monitor entire series
5. Readarr tracks all books in series

**Reading Order:**
- Readarr shows series order
- Books numbered sequentially
- Missing books highlighted

### Custom Scripts

**Settings → Connect → Custom Script:**

Run scripts on events:
- On Download
- On Import
- On Upgrade
- On Rename
- On Delete

**Use Cases:**
- Convert formats (MOBI → EPUB)
- Sync to e-reader
- Backup to cloud
- Update external database

### Notifications

**Settings → Connect:**

Popular notifications:
- **Calibre:** Update library on import
- **Discord:** New book alerts
- **Telegram:** Mobile notifications
- **Email:** SMTP alerts
- **Custom Webhook:** External integrations

## Troubleshooting

### Readarr Not Finding Books

```bash
# Check indexers
# Settings → Indexers → Test All

# Check Prowlarr sync
docker logs prowlarr | grep readarr

# Manual search
# Book → Manual Search → View logs

# Common issues:
# - No indexers with book categories
# - Book not released yet
# - Quality profile too restrictive
# - Wrong book metadata (try ISBN search)
```

### Downloads Not Importing

```bash
# Check permissions
ls -la /mnt/downloads/complete/books-readarr/
ls -la /mnt/media/books/

# Fix ownership
sudo chown -R 1000:1000 /mnt/media/books/

# Verify Readarr access
docker exec readarr ls /downloads
docker exec readarr ls /books

# Check logs
docker logs readarr | grep -i import

# Common issues:
# - Permission denied
# - Wrong category in qBittorrent
# - File format not in metadata profile
# - Hardlink failed (different filesystems)
```

### Wrong Author/Book Match

```bash
# Search by ISBN for accurate match
# Add New → Search: ISBN-13 number

# Edit book/author
# Library → Select → Edit
# Search for correct match

# Check metadata sources
# Settings → Metadata → Verify sources enabled
```

### Database Corruption

```bash
# Stop Readarr
docker stop readarr

# Backup database
cp /opt/stacks/media-extended/readarr/config/readarr.db /opt/backups/

# Check integrity
sqlite3 /opt/stacks/media-extended/readarr/config/readarr.db "PRAGMA integrity_check;"

# Restore from backup if corrupted
docker start readarr
```

## Performance Optimization

### RSS Sync Interval

**Settings → Indexers → Options:**
- RSS Sync Interval: 60 minutes
- Books release less frequently than TV/movies

### Database Optimization

```bash
# Stop Readarr
docker stop readarr

# Vacuum database
sqlite3 /opt/stacks/media-extended/readarr/config/readarr.db "VACUUM;"

# Clear old history
# Settings → General → History Cleanup: 30 days

docker start readarr
```

## Security Best Practices

1. **Enable Authentication:**
   - Settings → General → Security
   - Authentication: Required

2. **API Key Security:**
   - Keep API key secure
   - Regenerate if compromised

3. **Reverse Proxy:**
   - Use Traefik + Authelia
   - Don't expose port 8787 publicly

4. **Regular Backups:**
   - Backup `/config` directory
   - Includes database and settings

## Backup Strategy

**Critical Files:**
```bash
/opt/stacks/media-extended/readarr/config/readarr.db     # Database
/opt/stacks/media-extended/readarr/config/config.xml     # Settings
/opt/stacks/media-extended/readarr/config/Backup/        # Auto backups
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/readarr

cp /opt/stacks/media-extended/readarr/config/readarr.db $BACKUP_DIR/readarr-$DATE.db
find $BACKUP_DIR -name "readarr-*.db" -mtime +7 -delete
```

## Integration with Other Services

### Readarr + Prowlarr
- Centralized indexer management
- Auto-sync book indexers

### Readarr + qBittorrent (via Gluetun)
- Download books via VPN
- Category-based organization

### Readarr + Calibre-Web
- Web interface for reading
- Library management
- Format conversion

### Readarr + Calibre
- Professional ebook management
- Format conversion
- Metadata editing
- E-reader sync

## Summary

Readarr is the ebook/audiobook automation tool offering:
- Automatic book downloads
- Author and series tracking
- Format management (EPUB, MOBI, MP3, M4B)
- GoodReads integration
- Calibre compatibility
- Free and open-source

**Perfect for:**
- Avid readers
- Audiobook enthusiasts
- Series completionists
- GoodReads users
- Calibre users
- Book collectors

**Key Points:**
- Use develop tag for latest features
- Monitor favorite authors
- GoodReads list integration
- Multiple format support
- Calibre compatibility
- Series tracking
- ISBN search for accuracy

**Remember:**
- Still in active development
- Use ISBN for accurate matching
- Separate ebook/audiobook profiles
- Integrate with Calibre-Web for reading
- Monitor series, not just books
- Regular backups recommended

Readarr completes the *arr stack for comprehensive media automation!
