# Bazarr - Subtitle Automation

## Table of Contents
- [Overview](#overview)
- [What is Bazarr?](#what-is-bazarr)
- [Why Use Bazarr?](#why-use-bazarr)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Subtitle Management  
**Docker Image:** [linuxserver/bazarr](https://hub.docker.com/r/linuxserver/bazarr)  
**Default Stack:** `media-management.yml`  
**Web UI:** `https://bazarr.${DOMAIN}` or `http://SERVER_IP:6767`  
**Authentication:** Optional (configurable)  
**Ports:** 6767

## What is Bazarr?

Bazarr is a companion application to Sonarr and Radarr that manages and downloads subtitles. It automatically downloads missing subtitles for your movies and TV shows based on your language preferences, and can even upgrade subtitles when better versions become available. It integrates seamlessly with your existing media stack.

### Key Features
- **Automatic Subtitle Downloads:** Missing subtitles retrieved automatically
- **Multi-Language Support:** Download multiple languages per media
- **Sonarr/Radarr Integration:** Syncs with your libraries
- **Provider Management:** 20+ subtitle providers
- **Quality Scoring:** Prioritize best subtitle releases
- **Forced Subtitles:** Foreign language only scenes
- **Hearing Impaired:** SDH subtitle support
- **Manual Search:** Override automatic selection
- **Upgrade Subtitles:** Replace with better versions
- **Embedded Subtitles:** Extract from MKV files
- **Custom Post-Processing:** Scripts on download

## Why Use Bazarr?

1. **Accessibility:** Subtitles for hearing impaired viewers
2. **Foreign Language:** Watch content in any language
3. **Automatic Management:** No manual subtitle searching
4. **Quality Control:** Sync and score subtitles
5. **Multi-Language:** Support for multiple languages
6. **Upgrade System:** Replace poor quality subtitles
7. **Integration:** Works with Sonarr/Radarr
8. **Time Saving:** Automated workflow
9. **Free & Open Source:** No cost
10. **Comprehensive Providers:** Access to all major sources

## How It Works

```
New Movie/Episode Added
(via Sonarr/Radarr)
        ↓
Bazarr Detects Missing Subtitles
        ↓
Searches Subtitle Providers
(OpenSubtitles, Subscene, etc.)
        ↓
Evaluates Options (Score, Sync)
        ↓
Downloads Best Match
        ↓
Places Subtitle Next to Media File
        ↓
Plex/Jellyfin Detects Subtitle
        ↓
Subtitle Available in Player
```

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media-management/bazarr/config/    # Bazarr configuration
/mnt/media/movies/                           # Movie library (with subtitles)
/mnt/media/tv/                              # TV library (with subtitles)

Subtitle Structure:
/mnt/media/movies/
  The Matrix (1999)/
    The Matrix (1999).mkv
    The Matrix (1999).en.srt          # English
    The Matrix (1999).en.forced.srt   # Forced English
    The Matrix (1999).es.srt          # Spanish
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

- **Website:** https://www.bazarr.media
- **Documentation:** https://wiki.bazarr.media
- **GitHub:** https://github.com/morpheus65535/bazarr
- **Discord:** https://discord.gg/MH2e2eb
- **Reddit:** https://reddit.com/r/bazarr
- **Docker Hub:** https://hub.docker.com/r/linuxserver/bazarr

## Educational Resources

### Videos
- [Bazarr Setup Guide (Techno Tim)](https://www.youtube.com/results?search_query=bazarr+setup+techno+tim)
- [Subtitle Automation](https://www.youtube.com/results?search_query=bazarr+sonarr+radarr)
- [Bazarr Best Settings](https://www.youtube.com/results?search_query=bazarr+best+settings)

### Articles & Guides
- [Official Wiki](https://wiki.bazarr.media)
- [Setup Guide](https://wiki.bazarr.media/Getting-Started)
- [Provider Setup](https://wiki.bazarr.media/Subtitle-Providers/)

### Concepts to Learn
- **Subtitle Formats:** SRT, ASS, SSA, VTT
- **Forced Subtitles:** Foreign language only
- **Hearing Impaired (SDH):** Sound descriptions
- **Subtitle Sync:** Timing adjustment
- **Subtitle Score:** Quality metrics
- **Embedded Subtitles:** Within MKV container
- **External Subtitles:** Separate .srt files

## Docker Configuration

### Complete Service Definition

```yaml
bazarr:
  image: linuxserver/bazarr:latest
  container_name: bazarr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "6767:6767"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media-management/bazarr/config:/config
    - /mnt/media/movies:/movies
    - /mnt/media/tv:/tv
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.bazarr.rule=Host(`bazarr.${DOMAIN}`)"
    - "traefik.http.routers.bazarr.entrypoints=websecure"
    - "traefik.http.routers.bazarr.tls.certresolver=letsencrypt"
    - "traefik.http.routers.bazarr.middlewares=authelia@docker"
    - "traefik.http.services.bazarr.loadbalancer.server.port=6767"
```

## Initial Setup

### First Access

1. **Start Container:**
   ```bash
   docker compose up -d bazarr
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:6767`
   - Domain: `https://bazarr.yourdomain.com`

3. **Initial Configuration:**
   - Settings → Languages
   - Settings → Providers
   - Settings → Sonarr
   - Settings → Radarr

### Language Configuration

**Settings → Languages → Languages Filter:**

1. **Languages:**
   - Add language(s) you want subtitles for
   - Example: English, Spanish, French
   - Order determines priority

2. **Profile 1 (Default):**
   - Name: "Default"
   - Languages: English
   - ✓ Enabled

3. **Create Additional Profiles:**
   - Multi-language profile
   - Hearing impaired profile
   - Foreign language only

**Settings → Languages → Default Settings:**

- **Single Language:** ✗ (allow multiple)
- **Hearing-impaired:** No (or Prefer/Require if needed)
- **Forced Only:** No (foreign language scenes only)

### Subtitle Providers

**Settings → Providers:**

**Add Subtitle Providers:**

1. **OpenSubtitles.org:**
   - Create account at opensubtitles.org
   - Get API key
   - Add to Bazarr
   - Username and API key
   - Save

2. **OpenSubtitles.com (New):**
   - Newer version
   - Better quality
   - Requires account
   - API key

3. **Subscene:**
   - No account required
   - Good quality
   - Enable

4. **Addic7ed:**
   - Requires account
   - Great for TV shows
   - Username and password

5. **YIFY Subtitles:**
   - Movies
   - No account
   - Enable

**Provider Priority:**
- Drag to reorder
- Top providers checked first
- Lower providers as fallback

**Recommended Providers:**
- OpenSubtitles.com (best quality)
- Addic7ed (TV shows)
- OpenSubtitles.org (backup)
- YIFY (movies)
- Subscene (backup)

### Anti-Captcha (Optional)

Some providers use captchas:

**Settings → Providers → Anti-Captcha:**
- Service: Anti-Captcha
- API Key: From anti-captcha.com
- Costs money, optional

### Sonarr Integration

**Settings → Sonarr → Add:**

1. **Name:** Sonarr
2. **Address:** `http://sonarr:8989`
3. **API Key:** From Sonarr → Settings → General
4. **Download Only Monitored:** ✓ Yes
5. **Exclude Season Packs:** ✓ Yes (optional)
6. **Full Update:** Every 6 hours
7. **Test → Save**

**Sync:**
- Bazarr imports all shows from Sonarr
- Monitors for new episodes
- Downloads subtitles automatically

### Radarr Integration

**Settings → Radarr → Add:**

1. **Name:** Radarr
2. **Address:** `http://radarr:7878`
3. **API Key:** From Radarr → Settings → General
4. **Download Only Monitored:** ✓ Yes
5. **Full Update:** Every 6 hours
6. **Test → Save**

**Sync:**
- Bazarr imports all movies from Radarr
- Monitors for new movies
- Downloads subtitles automatically

### Subtitle Search Settings

**Settings → Subtitles → Subtitle Options:**

**Search:**
- **Adaptive Searching:** ✓ Enable (better results)
- **Minimum Score:** 80% (adjust based on quality needs)
- **Download Hearing-Impaired:** Prefer (or Don't Use)
- **Use Scene Name:** ✓ Enable
- **Use Original Format:** ✓ Enable (keep .srt, .ass, etc.)

**Upgrade:**
- **Upgrade Previously Downloaded:** ✓ Enable
- **Upgrade Manually Downloaded:** ✗ Disable (keep manual choices)
- **Upgrade for 7 Days:** (tries for better subtitles)
- **Score Threshold:** 360 (out of 360 for perfect)

**Performance:**
- **Use Embedded Subtitles:** ✗ Disable (extract if needed)
- **Exclude External Subtitles:** ✗ Disable

## Advanced Topics

### Language Profiles

**Create Custom Profiles:**

**Settings → Languages → Profiles:**

**Example: English + Spanish**
1. Click "+"
2. Name: "Dual Language"
3. Add languages: English, Spanish
4. Cutoff: English (stop when English found)
5. Save

**Example: Hearing Impaired**
1. Name: "SDH English"
2. Language: English
3. Hearing-Impaired: Required
4. Save

**Assign to Series/Movies:**
- Series → Edit → Language Profile: Dual Language
- Movies → Edit → Language Profile: SDH English

### Forced Subtitles

**Foreign language only scenes:**

**Example:** English movie with Spanish dialogue scenes
- Bazarr can download "forced" subtitles
- Only shows during foreign language

**Settings:**
- Language Profile → Forced: Yes
- Downloads .forced.srt files

### Manual Search

**Override automatic selection:**

1. **Series/Movies → Select item**
2. **Click "Search" icon**
3. **View all available subtitles**
4. **Select manually**
5. **Download**

**Use Cases:**
- Automatic subtitle quality poor
- Specific release group needed
- Hearing impaired preference

### Subtitle Sync

**Fix subtitle timing issues:**

**Settings → Subtitles → Subtitle Options:**
- ✓ Subtitle Sync (use ffmpeg)
- Fixes out-of-sync subtitles

**Manual Sync:**
- Tools like SubShift
- Bazarr can trigger external scripts

### Embedded Subtitle Extraction

**Extract from MKV:**

**Settings → Subtitles → Subtitle Options:**
- ✓ Use Embedded Subtitles
- Bazarr extracts to external .srt
- Useful for compatibility

**Requirements:**
- ffmpeg installed (included in linuxserver image)
- MKV files with embedded subs

### Custom Post-Processing

**Settings → Notifications → Custom:**

**Run scripts after subtitle download:**
- Convert formats
- Additional sync
- Notify external services
- Custom workflows

**Script location:**
```bash
/config/custom_scripts/post-download.sh
```

### Mass Actions

**Series/Movies → Mass Editor:**

**Actions:**
- Search All Subtitles
- Remove Subtitles
- Change Language Profile
- Update from Sonarr/Radarr

**Use Cases:**
- Initial setup (search all)
- Change preferences for multiple items
- Cleanup

### History

**History Tab:**

**View all subtitle actions:**
- Downloads
- Upgrades
- Deletions
- Manual searches

**Filters:**
- By language
- By provider
- By score
- By date

**Statistics:**
- Total downloads
- Provider success rates
- Language distribution

## Troubleshooting

### Bazarr Not Finding Subtitles

```bash
# Check providers
# Settings → Providers → Test

# Check provider status
# System → Status → Provider health

# Manual search
# Series/Movies → Manual Search
# View available subtitles

# Common issues:
# - Provider down/rate-limited
# - Wrong API key
# - Low minimum score (reduce)
# - Release name mismatch
```

### Bazarr Can't Connect to Sonarr/Radarr

```bash
# Test connection
docker exec bazarr curl http://sonarr:8989
docker exec bazarr curl http://radarr:7878

# Verify API keys
# Copy from Sonarr/Radarr exactly

# Check network
docker network inspect traefik-network

# Check logs
docker logs bazarr | grep -i "sonarr\|radarr"

# Force sync
# Settings → Sonarr/Radarr → Full Update
```

### Subtitles Not Appearing in Plex/Jellyfin

```bash
# Check subtitle location
ls -la /mnt/media/movies/Movie*/

# Should be next to video file:
# movie.mkv
# movie.en.srt

# Check permissions
sudo chown -R 1000:1000 /mnt/media/movies/

# Refresh Plex/Jellyfin
# Plex: Scan Library Files
# Jellyfin: Scan Library

# Check subtitle format
# Plex/Jellyfin support: SRT, VTT, ASS
# Not: SUB, IDX (convert if needed)
```

### Low Quality Subtitles

```bash
# Increase minimum score
# Settings → Subtitles → Minimum Score: 90%

# Enable adaptive search
# Settings → Subtitles → Adaptive Searching: ✓

# Add more providers
# Settings → Providers → Add quality providers

# Manual search
# Select item → Manual Search → Choose better subtitle
```

### Provider Rate Limiting

```bash
# Check provider status
# System → Status

# Wait for rate limit reset
# Usually hourly or daily

# Add more providers
# Distribute load across multiple sources

# Use Anti-Captcha
# Settings → Providers → Anti-Captcha
# Bypasses rate limits (paid service)
```

### Database Issues

```bash
# Stop Bazarr
docker stop bazarr

# Backup database
cp /opt/stacks/media-management/bazarr/config/db/bazarr.db /opt/backups/

# Check integrity
sqlite3 /opt/stacks/media-management/bazarr/config/db/bazarr.db "PRAGMA integrity_check;"

# Vacuum if needed
sqlite3 /opt/stacks/media-management/bazarr/config/db/bazarr.db "VACUUM;"

# Restart
docker start bazarr
```

## Performance Optimization

### Provider Settings

**Settings → Providers → Anti-Captcha:**
- Reduces rate limiting
- Faster searches
- Costs money

**Provider Limits:**
- Respect rate limits
- Don't overload providers
- Use multiple providers

### Sync Frequency

**Settings → Sonarr/Radarr:**
- Full Update: Every 6-12 hours
- More frequent = higher load
- Balance between updates and performance

### Minimum Score

**Settings → Subtitles:**
- Minimum Score: 80-90%
- Lower = more results, lower quality
- Higher = fewer results, better quality

## Security Best Practices

1. **Enable Authentication:**
   - Settings → General → Security
   - Authentication: Required

2. **API Key Security:**
   - Keep provider API keys secure
   - Regenerate if compromised

3. **Reverse Proxy:**
   - Use Traefik + Authelia
   - Don't expose port 6767 publicly

4. **Regular Updates:**
   - Keep Bazarr current
   - Update providers

## Backup Strategy

**Critical Files:**
```bash
/opt/stacks/media-management/bazarr/config/db/bazarr.db    # Database
/opt/stacks/media-management/bazarr/config/config/config.yaml  # Settings
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/bazarr

docker stop bazarr
tar -czf $BACKUP_DIR/bazarr-$DATE.tar.gz \
  /opt/stacks/media-management/bazarr/config/
docker start bazarr

find $BACKUP_DIR -name "bazarr-*.tar.gz" -mtime +7 -delete
```

## Integration with Other Services

### Bazarr + Sonarr/Radarr
- Automatic library sync
- New media detection
- Subtitle download triggers

### Bazarr + Plex/Jellyfin
- Subtitles appear automatically
- Multiple language support
- Forced subtitle support

## Summary

Bazarr is the subtitle automation tool offering:
- Automatic subtitle downloads
- Multi-language support
- Sonarr/Radarr integration
- 20+ subtitle providers
- Quality scoring and upgrades
- Forced and SDH subtitles
- Free and open-source

**Perfect for:**
- Multi-language households
- Hearing impaired accessibility
- Foreign language content
- Automated workflows
- Quality subtitle seekers

**Key Points:**
- Configure language profiles
- Add multiple providers
- Set minimum score appropriately
- Sync with Sonarr/Radarr
- Enable subtitle upgrades
- Use adaptive searching
- OpenSubtitles.com recommended

**Remember:**
- Subtitles placed next to media files
- .srt files for Plex/Jellyfin
- Multiple languages supported
- Forced subtitles for foreign scenes
- Provider rate limits exist
- Manual search available
- Regular backups recommended

Bazarr completes your media stack with comprehensive subtitle management!
