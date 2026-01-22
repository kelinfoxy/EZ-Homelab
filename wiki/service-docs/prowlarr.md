# Prowlarr - Indexer Manager

## Table of Contents
- [Overview](#overview)
- [What is Prowlarr?](#what-is-prowlarr)
- [Why Use Prowlarr?](#why-use-prowlarr)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Indexer Management  
**Docker Image:** [linuxserver/prowlarr](https://hub.docker.com/r/linuxserver/prowlarr)  
**Default Stack:** `media.yml`  
**Web UI:** `https://prowlarr.${DOMAIN}` or `http://SERVER_IP:9696`  
**Authentication:** Optional (configurable)  
**Ports:** 9696

## What is Prowlarr?

Prowlarr is an indexer manager and proxy for Sonarr, Radarr, Readarr, and Lidarr. Instead of configuring indexers (torrent/usenet sources) separately in each *arr app, Prowlarr manages them centrally and syncs automatically. It's the "one indexer to rule them all" for your media automation stack.

### Key Features
- **Centralized Indexer Management:** Configure once, use everywhere
- **Automatic Sync:** Pushes indexers to all *arr apps
- **Built-in Indexers:** 500+ indexers included
- **Custom Indexers:** Add any indexer via definitions
- **Search Aggregation:** Search across all indexers at once
- **Stats & History:** Track indexer performance
- **App Sync:** Connects with Sonarr, Radarr, Readarr, Lidarr
- **FlareSolverr Integration:** Bypass Cloudflare protection
- **Download Client Support:** Direct downloads (optional)
- **Notification Support:** Discord, Telegram, etc.

## Why Use Prowlarr?

1. **DRY Principle:** Configure indexers once, not in every app
2. **Centralized Management:** Single source of truth
3. **Automatic Sync:** Updates push to all connected apps
4. **Performance Monitoring:** See which indexers work best
5. **Easier Maintenance:** Update indexer settings in one place
6. **Search Aggregation:** Test searches across all indexers
7. **FlareSolverr Support:** Bypass protections automatically
8. **History Tracking:** Monitor what's being searched
9. **App Integration:** Seamless *arr stack integration
10. **Free & Open Source:** Part of the Servarr family

## How It Works

```
Prowlarr (Central Hub)
       ↓
Manages 500+ Indexers
(1337x, RARBG, YTS, etc.)
       ↓
Automatically Syncs To:
- Sonarr (TV)
- Radarr (Movies)
- Readarr (Books)
- Lidarr (Music)
       ↓
*arr Apps Search via Prowlarr
       ↓
Prowlarr Queries All Indexers
       ↓
Returns Aggregated Results
       ↓
*arr Apps Download Best Match
```

### The Problem Prowlarr Solves

**Before Prowlarr:**
- Configure indexers in Sonarr
- Configure same indexers in Radarr
- Configure same indexers in Readarr
- Configure same indexers in Lidarr
- Update indexer? Change in 4 places!

**With Prowlarr:**
- Configure indexers once in Prowlarr
- Auto-sync to all apps
- Update once, updates everywhere
- Centralized statistics and management

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media/prowlarr/config/    # Prowlarr configuration
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

- **Website:** https://prowlarr.com
- **Wiki:** https://wiki.servarr.com/prowlarr
- **GitHub:** https://github.com/Prowlarr/Prowlarr
- **Discord:** https://discord.gg/prowlarr
- **Reddit:** https://reddit.com/r/prowlarr
- **Docker Hub:** https://hub.docker.com/r/linuxserver/prowlarr

## Educational Resources

### Videos
- [Prowlarr Setup Guide (Techno Tim)](https://www.youtube.com/watch?v=ZI__3VNlQGM)
- [Complete *arr Stack with Prowlarr](https://www.youtube.com/results?search_query=prowlarr+sonarr+radarr+setup)
- [Prowlarr Indexer Setup](https://www.youtube.com/results?search_query=prowlarr+indexers)
- [FlareSolverr with Prowlarr](https://www.youtube.com/results?search_query=flaresolverr+prowlarr)

### Articles & Guides
- [Official Documentation](https://wiki.servarr.com/prowlarr)
- [Servarr Wiki](https://wiki.servarr.com/)
- [Indexer Setup Guide](https://wiki.servarr.com/prowlarr/indexers)
- [Application Sync Guide](https://wiki.servarr.com/prowlarr/settings#applications)

### Concepts to Learn
- **Indexers:** Sources for torrents/usenet (1337x, RARBG, etc.)
- **Trackers:** BitTorrent indexers
- **Usenet:** Alternative to torrents (requires subscription)
- **Public vs Private:** Indexer access types
- **API Keys:** Authentication between services
- **FlareSolverr:** Cloudflare bypass proxy
- **Categories:** Media type classifications
- **Sync Profiles:** What syncs to which app

## Docker Configuration

### Complete Service Definition

```yaml
prowlarr:
  image: linuxserver/prowlarr:latest
  container_name: prowlarr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "9696:9696"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media/prowlarr/config:/config
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.prowlarr.rule=Host(`prowlarr.${DOMAIN}`)"
    - "traefik.http.routers.prowlarr.entrypoints=websecure"
    - "traefik.http.routers.prowlarr.tls.certresolver=letsencrypt"
    - "traefik.http.routers.prowlarr.middlewares=authelia@docker"
    - "traefik.http.services.prowlarr.loadbalancer.server.port=9696"
```

### With FlareSolverr (for Cloudflare bypass)

```yaml
prowlarr:
  image: linuxserver/prowlarr:latest
  container_name: prowlarr
  # ... (same as above)
  depends_on:
    - flaresolverr

flaresolverr:
  image: ghcr.io/flaresolverr/flaresolverr:latest
  container_name: flaresolverr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8191:8191"
  environment:
    - LOG_LEVEL=info
```

## Initial Setup

### First Access

1. **Start Container:**
   ```bash
   docker compose up -d prowlarr
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:9696`
   - Domain: `https://prowlarr.yourdomain.com`

3. **Initial Configuration:**
   - Settings → Apps (connect *arr apps)
   - Indexers → Add Indexers
   - Settings → General (authentication)

### Connecting *arr Applications

**Settings → Apps → Add Application:**

#### Add Sonarr

1. **Name:** Sonarr
2. **Sync Level:** Add and Remove Only (recommended)
3. **Prowlarr Server:** `http://prowlarr:9696`
4. **Sonarr Server:** `http://sonarr:8989`
5. **API Key:** From Sonarr → Settings → General → API Key
6. **Sync Categories:** TV/SD, TV/HD, TV/UHD
7. **Test → Save**

#### Add Radarr

1. **Name:** Radarr
2. **Sync Level:** Add and Remove Only
3. **Prowlarr Server:** `http://prowlarr:9696`
4. **Radarr Server:** `http://radarr:7878`
5. **API Key:** From Radarr → Settings → General → API Key
6. **Sync Categories:** Movies/SD, Movies/HD, Movies/UHD
7. **Test → Save**

#### Add Readarr (if using)

1. **Name:** Readarr
2. **Server:** `http://readarr:8787`
3. **API Key:** From Readarr
4. **Categories:** Books/Ebook, Books/Audiobook

#### Add Lidarr (if using)

1. **Name:** Lidarr
2. **Server:** `http://lidarr:8686`
3. **API Key:** From Lidarr
4. **Categories:** Audio/MP3, Audio/Lossless

### Adding Indexers

**Indexers → Add Indexer:**

#### Popular Public Trackers

**1337x:**
1. Search: "1337x"
2. Select: 1337x
3. Base URL: (default)
4. API Key: (none for public)
5. Categories: Select relevant
6. Test → Save

**YTS:**
1. Search: "YTS"
2. Select: YTS
3. Configure categories
4. Test → Save

**EZTV:**
1. Search: "EZTV"
2. Select: EZTV (TV shows)
3. Configure
4. Test → Save

**Common Public Indexers:**
- 1337x (General)
- YTS (Movies, small file sizes)
- EZTV (TV Shows)
- RARBG (if still available)
- The Pirate Bay
- Nyaa (Anime)
- LimeTorrents

#### Private Trackers

**Requires Account:**
1. Register on tracker website
2. Get API key or credentials
3. Add in Prowlarr with credentials
4. Test → Save

**Popular Private Trackers:**
- BroadcastHe.Net (TV)
- PassThePopcorn (Movies)
- IPTorrents (General)
- TorrentLeech (General)

#### Usenet Indexers

**Requires Usenet Provider:**
1. Subscribe to usenet provider (Newshosting, etc.)
2. Subscribe to indexer (NZBGeek, etc.)
3. Add indexer with API key
4. Configure download client (SABnzbd, NZBGet)

### Auto-Sync Verification

**After adding indexers:**

1. **Check Sonarr:**
   - Settings → Indexers
   - Should see all indexers from Prowlarr
   - Each with "(Prowlarr)" suffix

2. **Check Radarr:**
   - Settings → Indexers
   - Should see same indexers
   - Auto-synced from Prowlarr

3. **Test Search:**
   - Sonarr → Add Series → Search
   - Should find results from all indexers

## Advanced Topics

### FlareSolverr Integration

Some indexers use Cloudflare protection. FlareSolverr bypasses this.

**Setup:**

1. **Add FlareSolverr Container:**
   ```yaml
   flaresolverr:
     image: ghcr.io/flaresolverr/flaresolverr:latest
     container_name: flaresolverr
     restart: unless-stopped
     ports:
       - "8191:8191"
     environment:
       - LOG_LEVEL=info
   ```

2. **Configure in Prowlarr:**
   - Settings → Indexers → Scroll down
   - FlareSolverr Host: `http://flaresolverr:8191`
   - Test

3. **Tag Indexers:**
   - Edit indexer
   - Tags → Add "flaresolverr"
   - Indexers with tag will use FlareSolverr

**When to Use:**
- Indexer returns Cloudflare errors
- "Access Denied" or "Checking your browser"
- DDoS protection pages

### Sync Profiles

**Settings → Apps → Sync Profiles:**

Control what syncs where:

**Standard Profile:**
- Sync categories: All
- Minimum seeders: 1
- Enable RSS: Yes
- Enable Automatic Search: Yes
- Enable Interactive Search: Yes

**Custom Profiles:**
- Create profiles for different apps
- Example: 4K-only profile for Radarr-4K

### Indexer Categories

**Important for Proper Sync:**

- **Movies:** Movies/HD, Movies/UHD, Movies/SD
- **TV:** TV/HD, TV/UHD, TV/SD
- **Music:** Audio/MP3, Audio/Lossless
- **Books:** Books/Ebook, Books/Audiobook
- **Anime:** TV/Anime, Movies/Anime

**Ensure Correct Categories:**
- Indexer must have correct categories
- Apps filter by category
- Mismatched categories = no results

### Statistics & History

**System → Status:**
- Indexer response times
- Success rates
- Error counts

**History:**
- View all searches
- Track performance
- Debug issues

**Indexer Stats:**
- Indexers → View stats column
- Grab count
- Query count
- Failure rate

### Custom Indexer Definitions

**Add Unlisted Indexers:**

1. **Find Indexer Definition:**
   - Prowlarr GitHub → Definitions
   - Or community-submitted

2. **Add Definition File:**
   - Copy YAML definition
   - Place in `/config/Definitions/Custom/`
   - Restart Prowlarr

3. **Add Indexer:**
   - Should appear in list
   - Configure as normal

### Download Clients (Optional)

**Prowlarr can send directly to download clients:**

**Settings → Download Clients → Add:**

Example: qBittorrent
- Host: `gluetun` (if via VPN)
- Port: `8080`
- Category: `prowlarr-manual`

**Use Case:**
- Manual downloads from Prowlarr
- Not needed for *arr apps (they have own clients)

### Notifications

**Settings → Connect:**

Get notified about:
- Indexer health issues
- Grab events
- Application updates

**Popular Notifications:**
- Discord
- Telegram
- Pushover
- Email
- Custom webhook

## Troubleshooting

### Prowlarr Not Accessible

```bash
# Check container status
docker ps | grep prowlarr

# View logs
docker logs prowlarr

# Test access
curl http://localhost:9696

# Check network
docker network inspect traefik-network
```

### Indexers Not Syncing to Apps

```bash
# Check app connection
# Settings → Apps → Test

# Check API keys match
# Prowlarr API key vs app's API key

# Check network connectivity
docker exec prowlarr ping -c 3 sonarr
docker exec prowlarr ping -c 3 radarr

# Force sync
# Settings → Apps → Select app → Sync App Indexers

# View logs
docker logs prowlarr | grep -i sync
```

### Indexer Failing

```bash
# Test indexer
# Indexers → Select indexer → Test

# Common issues:
# - Indexer down
# - Cloudflare protection (need FlareSolverr)
# - IP banned (too many requests)
# - API key invalid

# Check indexer status
# Visit indexer website directly

# Enable FlareSolverr if Cloudflare error
```

### FlareSolverr Not Working

```bash
# Check FlareSolverr status
docker logs flaresolverr

# Test FlareSolverr
curl http://localhost:8191/health

# Ensure Prowlarr can reach FlareSolverr
docker exec prowlarr curl http://flaresolverr:8191/health

# Verify indexer tagged
# Indexer → Edit → Tags → flaresolverr

# Check FlareSolverr logs during indexer test
docker logs -f flaresolverr
```

### No Search Results

```bash
# Check indexers enabled
# Indexers → Ensure not disabled

# Test indexers
# Indexers → Test All

# Check categories
# Indexer categories must match app needs

# Manual search
# Prowlarr → Search → Test query
# Should return results

# Check app logs
docker logs sonarr | grep prowlarr
docker logs radarr | grep prowlarr
```

### Database Corruption

```bash
# Stop Prowlarr
docker stop prowlarr

# Backup database
cp /opt/stacks/media/prowlarr/config/prowlarr.db /opt/backups/

# Check integrity
sqlite3 /opt/stacks/media/prowlarr/config/prowlarr.db "PRAGMA integrity_check;"

# If corrupted, restore or rebuild
# rm /opt/stacks/media/prowlarr/config/prowlarr.db

docker start prowlarr
# Prowlarr will recreate database (need to reconfigure)
```

## Performance Optimization

### Rate Limiting

**Settings → Indexers → Options:**
- Indexer download limit: 60 per day (per indexer)
- Prevents IP bans
- Adjust based on indexer limits

### Query Limits

**Per Indexer:**
- Edit indexer → Query Limit
- Requests per day
- Prevents abuse

### Caching

**Prowlarr caches results:**
- Reduces duplicate queries
- Improves response time
- Automatic management

### Database Maintenance

```bash
# Stop Prowlarr
docker stop prowlarr

# Vacuum database
sqlite3 /opt/stacks/media/prowlarr/config/prowlarr.db "VACUUM;"

# Restart
docker start prowlarr
```

## Security Best Practices

1. **Enable Authentication:**
   - Settings → General → Security
   - Authentication: Required
   - Username and password

2. **API Key Security:**
   - Keep API keys secret
   - Regenerate if compromised
   - Settings → General → API Key

3. **Use Reverse Proxy:**
   - Traefik + Authelia
   - Don't expose 9696 publicly

4. **Indexer Credentials:**
   - Secure storage
   - Use API keys over passwords
   - Rotate periodically

5. **Monitor Access:**
   - Check history for unusual activity
   - Review indexer stats

6. **VPN for Public Trackers:**
   - While Prowlarr doesn't download
   - Apps behind VPN still benefit

7. **Regular Updates:**
   - Keep Prowlarr current
   - Check release notes

## Backup Strategy

**Critical Files:**
```bash
/opt/stacks/media/prowlarr/config/prowlarr.db    # Database
/opt/stacks/media/prowlarr/config/config.xml     # Settings
/opt/stacks/media/prowlarr/config/Backup/        # Auto backups
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/prowlarr

# Backup database
cp /opt/stacks/media/prowlarr/config/prowlarr.db $BACKUP_DIR/prowlarr-$DATE.db

# Keep last 7 days
find $BACKUP_DIR -name "prowlarr-*.db" -mtime +7 -delete
```

**Restore:**
```bash
docker stop prowlarr
cp /opt/backups/prowlarr/prowlarr-20240101.db /opt/stacks/media/prowlarr/config/prowlarr.db
docker start prowlarr
```

## Integration with Other Services

### Prowlarr + Sonarr + Radarr
- Central indexer management
- Auto-sync to all apps
- Single configuration point

### Prowlarr + FlareSolverr
- Bypass Cloudflare protection
- Access protected indexers
- Automatic proxy usage

### Prowlarr + VPN
- Prowlarr itself doesn't need VPN
- Download clients (qBittorrent) need VPN
- Indexer searches are legal

## Summary

Prowlarr is the essential indexer manager for *arr stacks offering:
- Centralized indexer management
- Automatic sync to all *arr apps
- 500+ built-in indexers
- FlareSolverr integration
- Performance statistics
- History tracking
- Free and open-source

**Perfect for:**
- *arr stack users
- Multiple *arr applications
- Centralized management needs
- Indexer performance monitoring
- Simplified configuration

**Key Benefits:**
- Configure once, use everywhere
- Automatic sync to apps
- Single source of truth
- Easy maintenance
- Performance monitoring
- Cloudflare bypass support

**Remember:**
- Add Prowlarr first, then apps
- Apps auto-receive indexers
- Use FlareSolverr for Cloudflare
- Monitor indexer health
- Respect indexer rate limits
- Keep API keys secure
- Regular backups essential

**Essential Stack:**
```
Prowlarr (Indexer Manager)
    ↓
Sonarr (TV) + Radarr (Movies)
    ↓
qBittorrent (via Gluetun VPN)
    ↓
Plex/Jellyfin (Media Server)
```

Prowlarr is the glue that makes the *arr stack work seamlessly!
