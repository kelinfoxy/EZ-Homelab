# qBittorrent - Torrent Client

## Table of Contents
- [Overview](#overview)
- [What is qBittorrent?](#what-is-qbittorrent)
- [Why Use qBittorrent?](#why-use-qbittorrent)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Download Client  
**Docker Image:** [linuxserver/qbittorrent](https://hub.docker.com/r/linuxserver/qbittorrent)  
**Default Stack:** `media.yml`  
**Network Mode:** Via Gluetun (VPN container)  
**Web UI:** `http://SERVER_IP:8080` (via Gluetun)  
**Authentication:** Username/password (default: admin/adminadmin)  
**Ports:** 8080 (WebUI via Gluetun), 6881 (incoming connections via Gluetun)

## What is qBittorrent?

qBittorrent is a free, open-source BitTorrent client that serves as a complete replacement for µTorrent. It's lightweight, feature-rich, and most importantly: no ads, no bundled malware, and respects your privacy. In AI-Homelab, it runs through the Gluetun VPN container for secure, anonymous downloading.

### Key Features
- **Free & Open Source:** No ads, no tracking
- **Web UI:** Remote management via browser
- **RSS Support:** Auto-download from RSS feeds
- **Sequential Download:** Stream while downloading
- **Search Engine:** Built-in torrent search
- **IP Filtering:** Block unwanted IPs
- **Bandwidth Control:** Limit upload/download speeds
- **Category Management:** Organize torrents
- **Label System:** Tag and filter
- **Connection Encryption:** Secure traffic
- **UPnP/NAT-PMP:** Auto port forwarding
- **Tracker Management:** Add, edit, remove trackers

## Why Use qBittorrent?

1. **No Ads:** Unlike µTorrent, completely ad-free
2. **Open Source:** Transparent, community-audited code
3. **Free Forever:** No premium versions or nag screens
4. **Lightweight:** Minimal resource usage
5. **Feature-Rich:** Everything you need built-in
6. **Active Development:** Regular updates
7. **Cross-Platform:** Windows, Mac, Linux
8. **API Support:** Integrates with Sonarr/Radarr
9. **Privacy Focused:** No telemetry or tracking
10. **VPN Friendly:** Works perfectly with Gluetun

## How It Works

```
Sonarr/Radarr → qBittorrent (via Gluetun VPN)
                      ↓
                Torrent Download
                (All traffic via VPN)
                      ↓
             Download Complete
                      ↓
       Sonarr/Radarr Import File
                      ↓
          Move to Media Library
          (/mnt/media/tv or /movies)
                      ↓
            Plex/Jellyfin Scan
                      ↓
            Media Available
```

### VPN Integration

**In AI-Homelab:**
- qBittorrent runs **inside** Gluetun container network
- ALL qBittorrent traffic routes through VPN
- If VPN drops, qBittorrent has no internet (kill switch)
- Protects your real IP address
- Bypasses ISP throttling

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media/qbittorrent/config/    # qBittorrent configuration
/mnt/downloads/                           # Download directory
  ├── complete/                           # Completed downloads
  ├── incomplete/                         # In-progress downloads
  └── torrents/                           # Torrent files
```

### Environment Variables

```bash
# User permissions (must match media owner)
PUID=1000
PGID=1000

# Timezone
TZ=America/New_York

# Web UI port (inside Gluetun network)
WEBUI_PORT=8080
```

## Official Resources

- **Website:** https://www.qbittorrent.org
- **Documentation:** https://github.com/qbittorrent/qBittorrent/wiki
- **GitHub:** https://github.com/qbittorrent/qBittorrent
- **Forums:** https://qbforums.shiki.hu
- **Reddit:** https://reddit.com/r/qBittorrent
- **Docker Hub:** https://hub.docker.com/r/linuxserver/qbittorrent

## Educational Resources

### Videos
- [qBittorrent Setup Guide (Techno Tim)](https://www.youtube.com/watch?v=9QS9xjz6W-k)
- [qBittorrent + VPN Setup](https://www.youtube.com/results?search_query=qbittorrent+vpn+docker)
- [qBittorrent Best Settings](https://www.youtube.com/results?search_query=qbittorrent+best+settings)
- [Sonarr/Radarr + qBittorrent](https://www.youtube.com/results?search_query=sonarr+radarr+qbittorrent)

### Articles & Guides
- [Official Wiki](https://github.com/qbittorrent/qBittorrent/wiki)
- [LinuxServer.io qBittorrent](https://docs.linuxserver.io/images/docker-qbittorrent)
- [Optimal Settings Guide](https://github.com/qbittorrent/qBittorrent/wiki/Optimal-Settings)
- [Category Management](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1))

### Concepts to Learn
- **Seeders/Leechers:** Users uploading/downloading
- **Ratio:** Upload/download ratio
- **Seeding:** Sharing completed files
- **Private Trackers:** Require ratio maintenance
- **Port Forwarding:** Improves connection speed
- **NAT-PMP/UPnP:** Automatic port mapping
- **DHT:** Decentralized peer discovery
- **PEX:** Peer exchange protocol
- **Magnet Links:** Torrent links without .torrent files

## Docker Configuration

### Standard Configuration (with Gluetun VPN)

In AI-Homelab, qBittorrent uses Gluetun's network:

```yaml
gluetun:
  image: qmcgaw/gluetun:latest
  container_name: gluetun
  cap_add:
    - NET_ADMIN
  devices:
    - /dev/net/tun
  ports:
    - "8080:8080"   # qBittorrent WebUI
    - "6881:6881"   # qBittorrent incoming
    - "6881:6881/udp"
  environment:
    - VPN_SERVICE_PROVIDER=surfshark
    - VPN_TYPE=wireguard
    - WIREGUARD_PRIVATE_KEY=${SURFSHARK_PRIVATE_KEY}
    - WIREGUARD_ADDRESSES=${SURFSHARK_ADDRESS}
    - SERVER_COUNTRIES=Netherlands
  volumes:
    - /opt/stacks/core/gluetun:/gluetun

qbittorrent:
  image: linuxserver/qbittorrent:latest
  container_name: qbittorrent
  restart: unless-stopped
  network_mode: "service:gluetun"  # Uses Gluetun's network
  depends_on:
    - gluetun
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - WEBUI_PORT=8080
  volumes:
    - /opt/stacks/media/qbittorrent/config:/config
    - /mnt/downloads:/downloads
```

**Key Points:**
- `network_mode: "service:gluetun"` routes all traffic through VPN
- Ports exposed on Gluetun, not qBittorrent
- No internet access if VPN down (kill switch)
- Access via `http://SERVER_IP:8080` (Gluetun's port)

### Standalone Configuration (without VPN - NOT RECOMMENDED)

```yaml
qbittorrent:
  image: linuxserver/qbittorrent:latest
  container_name: qbittorrent
  restart: unless-stopped
  ports:
    - "8080:8080"
    - "6881:6881"
    - "6881:6881/udp"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media/qbittorrent/config:/config
    - /mnt/downloads:/downloads
```

**Warning:** This exposes your real IP address!

## Initial Setup

### First Access

1. **Start Containers:**
   ```bash
   docker compose up -d gluetun qbittorrent
   ```

2. **Verify VPN Connection:**
   ```bash
   docker logs gluetun | grep -i "connected"
   # Should see "Connected" message
   ```

3. **Get Initial Password:**
   ```bash
   docker logs qbittorrent | grep -i "temporary password"
   # Look for: "The WebUI administrator username is: admin"
   # "The WebUI administrator password is: XXXXXXXX"
   ```

4. **Access Web UI:**
   - Navigate to: `http://SERVER_IP:8080`
   - Username: `admin`
   - Password: From logs above

5. **Change Default Password:**
   - Tools → Options → Web UI → Authentication
   - Change password immediately!

### Essential Settings

**Tools → Options:**

#### Downloads

**When adding torrent:**
- Create subfolder: ✓ Enabled
- Start torrent: ✓ Enabled

**Saving Management:**
- Default Torrent Management Mode: Automatic
- When Torrent Category changed: Relocate
- When Default Save Path changed: Relocate affected
- When Category Save Path changed: Relocate

**Default Save Path:** `/downloads/incomplete`
**Keep incomplete torrents in:** `/downloads/incomplete`
**Copy .torrent files to:** `/downloads/torrents`
**Copy .torrent files for finished downloads to:** `/downloads/torrents/complete`

#### Connection

**Listening Port:**
- Port used for incoming connections: `6881`
- Use UPnP / NAT-PMP: ✓ Enabled (if VPN supports)

**Connections Limits:**
- Global maximum number of connections: `500`
- Maximum number of connections per torrent: `100`
- Global maximum upload slots: `20`
- Maximum upload slots per torrent: `4`

#### Speed

**Global Rate Limits:**
- Upload: `10000 KiB/s` (or lower to maintain ratio)
- Download: `0` (unlimited, or set based on bandwidth)

**Alternative Rate Limits:** (optional)
- Enable for scheduled slow periods
- Upload: `1000 KiB/s`
- Download: `5000 KiB/s`
- Schedule: Weekdays during work hours

#### BitTorrent

**Privacy:**
- ✓ Enable DHT (decentralized network)
- ✓ Enable PEX (peer exchange)
- ✓ Enable Local Peer Discovery
- Encryption mode: **Require encryption** (important!)

**Seeding Limits:**
- When ratio reaches: `2.0` (or required by tracker)
- Then: **Pause torrent**

#### Web UI

**Authentication:**
- Username: `admin` (or custom)
- Password: **Strong password!**
- Bypass authentication for clients on localhost: ✗ Disabled
- Bypass authentication for clients in whitelisted IP subnets: (optional)
  - `192.168.1.0/24` (your local network)

**Security:**
- Enable clickjacking protection: ✓
- Enable Cross-Site Request Forgery protection: ✓
- Enable Host header validation: ✓

**Custom HTTP Headers:** (if behind reverse proxy)
```
X-Frame-Options: SAMEORIGIN
```

#### Advanced

**Network Interface:**
- Leave blank (uses default via Gluetun)

**Optional IP address to bind to:** 
- Leave blank (handled by Gluetun)

**Validate HTTPS tracker certificates:** ✓ Enabled

### Category Setup (for Sonarr/Radarr)

**Categories → Add category:**

1. **tv-sonarr**
   - Save path: `/downloads/complete/tv-sonarr`
   - Download path: `/downloads/incomplete`

2. **movies-radarr**
   - Save path: `/downloads/complete/movies-radarr`
   - Download path: `/downloads/incomplete`

3. **music-lidarr**
   - Save path: `/downloads/complete/music-lidarr`

4. **books-readarr**
   - Save path: `/downloads/complete/books-readarr`

*arr apps will automatically use these categories when sending torrents.

## Advanced Topics

### VPN Kill Switch

**How It Works:**
- qBittorrent uses Gluetun's network
- If VPN disconnects, qBittorrent has no internet
- Automatic kill switch, no configuration needed

**Verify:**
```bash
# Check IP inside qBittorrent container
docker exec qbittorrent curl ifconfig.me
# Should show VPN IP, not your real IP

# Stop VPN
docker stop gluetun

# Try again
docker exec qbittorrent curl ifconfig.me
# Should fail (no internet)
```

### Port Forwarding (via VPN)

Some VPN providers support port forwarding for better speeds:

**Gluetun Configuration:**
```yaml
gluetun:
  environment:
    - VPN_PORT_FORWARDING=on
```

**qBittorrent Configuration:**
- Tools → Options → Connection
- Port used for incoming: Check Gluetun logs for forwarded port
- Random port: Disabled

**Check Forwarded Port:**
```bash
docker logs gluetun | grep -i "port"
# Look for: "port forwarded is XXXXX"
```

**Update qBittorrent:**
- Tools → Options → Connection → Port: XXXXX

### RSS Auto-Downloads

**Automatically download from RSS feeds:**

**View → RSS Reader:**

1. **Add RSS feed:**
   - New subscription → Feed URL
   - Example: TV show RSS from tracker

2. **Create Download Rule:**
   - RSS Downloader
   - Add rule
   - Must Contain: Episode naming pattern
   - Must Not Contain: Unwanted qualities
   - Assign Category: tv-sonarr
   - Save to directory: `/downloads/complete/tv-sonarr`

**Example Rule:**
- Rule name: "Breaking Bad 1080p"
- Must Contain: `Breaking.Bad S* 1080p`
- Must Not Contain: `720p|HDTV`
- Category: tv-sonarr

**Note:** Sonarr/Radarr handle RSS better. Use this for non-automated content.

### Search Engine

**Built-in torrent search:**

**View → Search Engine → Search plugins:**

1. **Install plugins:**
   - Check for updates
   - Install popular plugins (1337x, RARBG, etc.)

2. **Search:**
   - Enter search term
   - Select plugin(s)
   - Search
   - Add desired torrent

**Note:** Prowlarr + Sonarr/Radarr provide better search. This is for manual downloads.

### IP Filtering

**Block unwanted IPs (anti-piracy monitors):**

**Tools → Options → Connection:**

**IP Filtering:**
- ✓ Filter path (.dat, .p2p, .p2b): `/config/blocked-ips.txt`
- ✓ Apply to trackers

**Get Block List:**
```bash
# Download blocklist
docker exec qbittorrent wget -O /config/blocked-ips.txt \
  https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz

# Extract
docker exec qbittorrent gunzip /config/blocked-ips.txt.gz
```

**Auto-update (cron):**
```bash
0 3 * * 0 docker exec qbittorrent wget -O /config/blocked-ips.txt https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz && docker exec qbittorrent gunzip -f /config/blocked-ips.txt.gz
```

### Anonymous Mode

**Tools → Options → BitTorrent → Privacy:**

- ✓ Enable anonymous mode

**What it does:**
- Disables DHT
- Disables PEX
- Disables LPD
- Only uses trackers

**Use When:**
- Private trackers (required)
- Maximum privacy
- Tracker-only operation

### Sequential Download

**For streaming while downloading:**

1. Right-click torrent
2. ✓ Download in sequential order
3. ✓ Download first and last pieces first

**Use Case:**
- Stream video while downloading
- Works with Plex/Jellyfin

**Note:** Can affect swarm health, use sparingly.

### Scheduler

**Schedule speed limits:**

**Tools → Options → Speed → Alternative Rate Limits:**

1. Enable alternative rate limits
2. Set slower limits
3. Schedule: When to activate
   - Example: Weekdays 9am-5pm (reduce usage during work)

### Tags & Labels

**Organize torrents:**

**Add Tag:**
1. Right-click torrent → Add tags
2. Create custom tags
3. Filter by tag in left sidebar

**Use Cases:**
- Priority downloads
- Personal vs automated
- Quality levels
- Sources

## Troubleshooting

### qBittorrent Not Accessible

```bash
# Check containers
docker ps | grep -E "gluetun|qbittorrent"

# Check logs
docker logs gluetun | tail -20
docker logs qbittorrent | tail -20

# Check VPN connection
docker logs gluetun | grep -i "connected"

# Test access
curl http://localhost:8080
```

### Slow Download Speeds

```bash
# Check VPN connection
docker exec qbittorrent curl ifconfig.me
# Verify it's VPN IP

# Test VPN speed
docker exec gluetun speedtest-cli

# Common fixes:
# 1. Enable port forwarding (VPN provider)
# 2. Different VPN server location
# 3. Increase connection limits
# 4. Check seeders/leechers count
# 5. Try different torrent
```

**Settings to Check:**
- Tools → Options → Connection → Port forwarding
- Tools → Options → Connection → Connection limits (increase)
- Tools → Options → Speed → Remove limits temporarily

### VPN Kill Switch Not Working

```bash
# Verify network mode
docker inspect qbittorrent | grep NetworkMode
# Should show: "container:gluetun"

# Test kill switch
docker stop gluetun
docker exec qbittorrent curl ifconfig.me
# Should fail with "Could not resolve host"

# If it shows your real IP, network mode is wrong!
```

### Permission Errors

```bash
# Check download directory
ls -la /mnt/downloads/

# Should be owned by PUID:PGID (1000:1000)
sudo chown -R 1000:1000 /mnt/downloads/

# Check from container
docker exec qbittorrent ls -la /downloads
docker exec qbittorrent touch /downloads/test.txt
# Should succeed
```

### Torrents Stuck at "Stalled"

```bash
# Possible causes:
# 1. No seeders
# 2. Port not forwarded
# 3. VPN blocking connections
# 4. Tracker down

# Check tracker status
# Right-click torrent → Edit trackers
# Should show "Working"

# Force reannounce
# Right-click torrent → Force reannounce

# Check connection
# Bottom right: Connection icon should be green
```

### Can't Login to Web UI

```bash
# Reset password
docker stop qbittorrent

# Edit config
nano /opt/stacks/media/qbittorrent/config/qBittorrent/qBittorrent.conf

# Find and change:
# WebUI\Password_PBKDF2="@ByteArray(...)"

# Delete the Password line, restart
docker start qbittorrent

# Check logs for new temporary password
docker logs qbittorrent | grep "password"
```

### High CPU Usage

```bash
# Check torrent count
# Too many active torrents

# Limit active torrents
# Tools → Options → BitTorrent
# Maximum active torrents: 5
# Maximum active downloads: 3

# Check hashing
# Large files hashing = high CPU (temporary)

# Limit download speed if needed
```

## Performance Optimization

### Optimal Settings

```
Connection:
- Global max connections: 500
- Per torrent: 100
- Upload slots global: 20
- Upload slots per torrent: 4

BitTorrent:
- DHT, PEX, LPD: Enabled
- Encryption: Require encryption

Speed:
- Set based on bandwidth
- Leave some headroom
```

### Disk I/O

**Settings → Advanced → Disk cache:**
- Disk cache: `-1` (auto)
- Disk cache expiry: `60` seconds

**If using SSD:**
- Can increase cache
- Reduces write amplification

### Multiple VPN Locations

**For better speeds, try different locations:**

```yaml
gluetun:
  environment:
    - SERVER_COUNTRIES=Netherlands  # Change to different country
```

Popular choices:
- Netherlands (good speeds)
- Switzerland (privacy)
- Romania (fast)
- Sweden (balanced)

## Security Best Practices

1. **Always Use VPN:** Never run qBittorrent without VPN
2. **Strong Password:** Change default admin password
3. **Encryption Required:** Tools → Options → BitTorrent → Require encryption
4. **IP Filtering:** Use blocklists
5. **Network Mode:** Always use `network_mode: service:gluetun`
6. **Port Security:** Don't expose ports unless necessary
7. **Regular Updates:** Keep qBittorrent and Gluetun updated
8. **Verify VPN:** Regularly check IP address
9. **Private Trackers:** Respect ratio requirements
10. **Legal Content:** Only download legal content

## Backup Strategy

**Critical Files:**
```bash
/opt/stacks/media/qbittorrent/config/qBittorrent/qBittorrent.conf  # Main config
/opt/stacks/media/qbittorrent/config/qBittorrent/categories.json   # Categories
/opt/stacks/media/qbittorrent/config/qBittorrent/rss/             # RSS config
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/qbittorrent

# Stop qBittorrent
docker stop qbittorrent

# Backup config
tar -czf $BACKUP_DIR/qbittorrent-config-$DATE.tar.gz \
  /opt/stacks/media/qbittorrent/config/

# Start qBittorrent
docker start qbittorrent

# Keep last 7 backups
find $BACKUP_DIR -name "qbittorrent-config-*.tar.gz" -mtime +7 -delete
```

## Integration with Other Services

### qBittorrent + Gluetun (VPN)
- All traffic through VPN
- Kill switch protection
- IP address masking

### qBittorrent + Sonarr/Radarr
- Automatic downloads
- Category management
- Import on completion

### qBittorrent + Plex/Jellyfin
- Sequential download for streaming
- Auto-scan on import

## Summary

qBittorrent is the essential download client offering:
- Free, open-source, no ads
- Web-based management
- VPN integration (Gluetun)
- Category management
- RSS auto-downloads
- Built-in search
- Privacy-focused

**Perfect for:**
- Torrent downloading
- *arr stack integration
- VPN-protected downloading
- Privacy-conscious users
- Replacing µTorrent/BitTorrent

**Key Points:**
- Always use with VPN (Gluetun)
- Change default password
- Enable encryption
- Use categories for *arr apps
- Monitor ratio on private trackers
- Port forwarding improves speeds
- Regular IP address verification

**Remember:**
- VPN required for safety
- network_mode: service:gluetun
- Categories for organization
- Encryption required
- Change default credentials
- Verify VPN connection
- Respect seeding requirements
- Legal content only

**Essential Media Stack:**
```
Prowlarr → Sonarr/Radarr → qBittorrent (via Gluetun) → Plex/Jellyfin
```

qBittorrent + Gluetun = Safe, fast, private downloading!
