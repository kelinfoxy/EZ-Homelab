# Jellyseerr - Media Request Management

## Table of Contents
- [Overview](#overview)
- [What is Jellyseerr?](#what-is-jellyseerr)
- [Why Use Jellyseerr?](#why-use-jellyseerr)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Media Request Management  
**Docker Image:** [fallenbagel/jellyseerr](https://hub.docker.com/r/fallenbagel/jellyseerr)  
**Default Stack:** `media-management.yml`  
**Web UI:** `https://jellyseerr.${DOMAIN}` or `http://SERVER_IP:5055`  
**Authentication:** Via Jellyfin (SSO)  
**Ports:** 5055

## What is Jellyseerr?

Jellyseerr is a fork of Overseerr specifically designed for Jellyfin. It provides a beautiful, user-friendly interface for users to request movies and TV shows. When a request is made, Jellyseerr automatically sends it to Sonarr or Radarr for download, then notifies users when their content is available. Think of it as the "frontend" for your media automation stack that non-technical users can easily navigate.

### Key Features
- **Jellyfin Integration:** Native SSO authentication
- **Beautiful UI:** Modern, responsive interface
- **User Requests:** Non-admin users can request content
- **Auto-Approval:** Configurable approval workflows
- **Request Management:** View, approve, deny requests
- **Availability Tracking:** Know when content is available
- **Notifications:** Discord, Telegram, Email, Pushover
- **Discovery:** Browse trending, popular, upcoming content
- **User Quotas:** Limit requests per user
- **4K Support:** Separate 4K requests
- **Multi-Language:** Support for multiple languages

## Why Use Jellyseerr?

1. **User-Friendly:** Non-technical users can request content easily
2. **Automated Workflow:** Request → Sonarr/Radarr → Download → Notify
3. **Permission Control:** Admins approve or auto-approve
4. **Discovery Interface:** Users can browse and discover content
5. **Request Tracking:** See status of all requests
6. **Notifications:** Keep users informed
7. **Jellyfin Integration:** Seamless SSO
8. **Quota Management:** Prevent abuse
9. **Mobile Friendly:** Responsive design
10. **Free & Open Source:** Community-driven

## How It Works

```
User Browses Jellyseerr
       ↓
Requests Movie/TV Show
       ↓
Jellyseerr Checks Availability
       ↓
Not Available → Send to Sonarr/Radarr
       ↓
Sonarr/Radarr → qBittorrent
       ↓
Download Completes
       ↓
Imported to Jellyfin Library
       ↓
Jellyseerr Notifies User
       ↓
User Watches Content
```

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media-management/jellyseerr/config/    # Jellyseerr configuration
```

### Environment Variables

```bash
# Log level
LOG_LEVEL=info

# Optional: Custom port
PORT=5055
```

## Official Resources

- **Website:** https://docs.jellyseerr.dev
- **Documentation:** https://docs.jellyseerr.dev
- **GitHub:** https://github.com/Fallenbagel/jellyseerr
- **Discord:** https://discord.gg/ckbvBtDJgC
- **Docker Hub:** https://hub.docker.com/r/fallenbagel/jellyseerr

## Educational Resources

### Videos
- [Jellyseerr Setup Guide](https://www.youtube.com/results?search_query=jellyseerr+setup)
- [Overseerr vs Jellyseerr](https://www.youtube.com/results?search_query=overseerr+vs+jellyseerr)
- [Jellyfin Request System](https://www.youtube.com/results?search_query=jellyfin+request+system)

### Articles & Guides
- [Official Documentation](https://docs.jellyseerr.dev)
- [Installation Guide](https://docs.jellyseerr.dev/getting-started/installation)
- [User Guide](https://docs.jellyseerr.dev/using-jellyseerr/users)

### Concepts to Learn
- **SSO (Single Sign-On):** Jellyfin authentication
- **Request Workflow:** Request → Approval → Download → Notify
- **User Permissions:** Admin vs Requester roles
- **Quotas:** Limiting requests per time period
- **4K Requests:** Separate quality tiers
- **Auto-Approval:** Automatic vs manual approval

## Docker Configuration

### Complete Service Definition

```yaml
jellyseerr:
  image: fallenbagel/jellyseerr:latest
  container_name: jellyseerr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "5055:5055"
  environment:
    - LOG_LEVEL=info
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media-management/jellyseerr/config:/app/config
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.jellyseerr.rule=Host(`jellyseerr.${DOMAIN}`)"
    - "traefik.http.routers.jellyseerr.entrypoints=websecure"
    - "traefik.http.routers.jellyseerr.tls.certresolver=letsencrypt"
    - "traefik.http.services.jellyseerr.loadbalancer.server.port=5055"
```

**Note:** No Authelia middleware - Jellyseerr has built-in Jellyfin authentication.

## Initial Setup

### First Access

1. **Start Container:**
   ```bash
   docker compose up -d jellyseerr
   ```

2. **Access Web UI:**
   - Local: `http://SERVER_IP:5055`
   - Domain: `https://jellyseerr.yourdomain.com`

3. **Setup Wizard:**
   - Configure Jellyfin server
   - Add Sonarr and Radarr
   - Configure default settings
   - Sign in with Jellyfin account

### Jellyfin Server Configuration

**Step 1: Connect Jellyfin**

1. **Server Name:** Your Jellyfin server name
2. **Hostname/IP:** `jellyfin` (Docker container name) or `http://jellyfin:8096`
3. **Port:** `8096`
4. **SSL:** ✗ (internal Docker network)
5. **External URL:** `https://jellyfin.yourdomain.com` (for user links)
6. **Test Connection**
7. **Sign in with Jellyfin Admin Account**

**What happens:**
- Jellyseerr connects to Jellyfin
- Imports users from Jellyfin
- Sets up SSO authentication

### Sonarr Configuration

**Settings → Services → Sonarr → Add Sonarr Server:**

1. **Default Server:** ✓ (primary Sonarr)
2. **4K Server:** ✗ (unless you have separate 4K Sonarr)
3. **Server Name:** Sonarr
4. **Hostname/IP:** `sonarr`
5. **Port:** `8989`
6. **API Key:** From Sonarr → Settings → General → API Key
7. **Base URL:** Leave blank
8. **Quality Profile:** HD-1080p (or your default)
9. **Root Folder:** `/tv`
10. **Language Profile:** English (or your preference)
11. **Tags:** (optional)
12. **External URL:** `https://sonarr.yourdomain.com`
13. **Enable Scan:** ✓
14. **Enable Automatic Search:** ✓
15. **Test → Save**

**For 4K Setup (Optional):**
- Add second Sonarr instance
- Check "4K Server"
- Point to Sonarr-4K instance

### Radarr Configuration

**Settings → Services → Radarr → Add Radarr Server:**

1. **Default Server:** ✓
2. **4K Server:** ✗
3. **Server Name:** Radarr
4. **Hostname/IP:** `radarr`
5. **Port:** `7878`
6. **API Key:** From Radarr → Settings → General → API Key
7. **Base URL:** Leave blank
8. **Quality Profile:** HD-1080p
9. **Root Folder:** `/movies`
10. **Minimum Availability:** Released
11. **Tags:** (optional)
12. **External URL:** `https://radarr.yourdomain.com`
13. **Enable Scan:** ✓
14. **Enable Automatic Search:** ✓
15. **Test → Save**

### User Management

**Settings → Users:**

**Import Users:**
- Users automatically imported from Jellyfin
- Each user can sign in with Jellyfin credentials

**User Permissions:**
1. **Admin:** Full control
2. **User:** Can request, see own requests
3. **Manage Requests:** Can approve/deny requests

**Configure Default Permissions:**
- Settings → Users → Default Permissions
- Request Movies: ✓
- Request TV: ✓
- Request 4K: ✗ (optional)
- Auto-approve: ✗ (review before downloading)
- Request Limit: 10 per week (adjust as needed)

### General Settings

**Settings → General:**

**Application Title:** Your server name (appears in UI)

**Application URL:** `https://jellyseerr.yourdomain.com`

**CSRF Protection:** ✓ Enable

**Hide Available Media:** ✗ (show what's already available)

**Allow Partial Series Requests:** ✓ (users can request specific seasons)

**Default Permissions:** Configure for new users

## Advanced Topics

### Auto-Approval

**Settings → Users → Select User → Permissions:**

- **Auto-approve Movies:** ✓
- **Auto-approve TV:** ✓
- **Auto-approve 4K:** ✗ (usually manual)

**Use Cases:**
- Trusted users
- Family members
- Reduce manual work

**Caution:**
- Can lead to storage issues
- Consider quotas

### Request Quotas

**Settings → Users → Select User → Permissions:**

**Movie Quotas:**
- Movie Request Limit: 10
- Time Period: Week

**TV Quotas:**
- TV Request Limit: 5
- Time Period: Week

**4K Quotas:**
- Separate limits for 4K
- Usually more restrictive

**Reset:**
- Quotas reset based on time period
- Can be adjusted per user

### Notifications

**Settings → Notifications:**

**Available Notification Types:**
- Email (SMTP)
- Discord
- Telegram
- Pushover
- Slack
- Webhook

**Configuration Example: Discord**

1. **Settings → Notifications → Discord → Add**
2. **Webhook URL:** From Discord server
3. **Bot Username:** Jellyseerr (optional)
4. **Bot Avatar:** Custom avatar URL (optional)
5. **Notification Types:**
   - Media Requested: ✓
   - Media Approved: ✓
   - Media Available: ✓
   - Media Failed: ✓
   - Request Pending: ✓ (for admins)
6. **Test → Save**

**Telegram Setup:**
1. Create bot with @BotFather
2. Get bot token
3. Get chat ID
4. Add to Jellyseerr
5. Configure notification types

### 4K Management

**Separate 4K Workflow:**

**Requirements:**
- Separate Sonarr-4K and Radarr-4K instances
- Separate 4K media libraries
- More storage space

**Setup:**
1. Add 4K Sonarr/Radarr servers
2. Check "4K Server" checkbox
3. Configure different quality profiles (2160p)
4. Separate root folders (/movies-4k, /tv-4k)

**User Permissions:**
- Restrict 4K requests to admins/trusted users
- Higher quotas for regular content

### Library Sync

**Settings → Services → Sync Libraries:**

**Manual Sync:**
- Force refresh of available content
- Updates Jellyseerr's cache

**Automatic Sync:**
- Runs periodically
- Keeps availability up-to-date

**Scan Settings:**
- Enable scan on Sonarr/Radarr servers
- Real-time availability updates

### Discovery Features

**Home Page:**
- Trending movies/TV
- Popular content
- Upcoming releases
- Recently Added

**Search:**
- Search movies, TV, people
- Filter by genre, year, rating
- Browse by network (Netflix, HBO, etc.)

**Recommendations:**
- Similar content suggestions
- Based on existing library

### Public Sign-Up

**Settings → General → Enable New Jellyfin Sign-In:**

- ✓ Allow new users to sign in
- ✗ Disable if you want manual approval

**With Jellyfin:**
- Users must have Jellyfin account first
- Then can access Jellyseerr

**Without Public Sign-Up:**
- Admin must import users manually
- More control over access

## Troubleshooting

### Jellyseerr Can't Connect to Jellyfin

```bash
# Check containers running
docker ps | grep -E "jellyseerr|jellyfin"

# Check network connectivity
docker exec jellyseerr curl http://jellyfin:8096

# Check Jellyfin API
curl http://SERVER_IP:8096/System/Info

# Verify hostname
# Should be: http://jellyfin:8096 (not localhost)

# Check logs
docker logs jellyseerr | grep -i jellyfin
docker logs jellyfin | grep -i error
```

### Jellyseerr Can't Connect to Sonarr/Radarr

```bash
# Test connectivity
docker exec jellyseerr curl http://sonarr:8989
docker exec jellyseerr curl http://radarr:7878

# Verify API keys
# Copy from Sonarr/Radarr → Settings → General → API Key
# Paste exactly into Jellyseerr

# Check network
docker network inspect traefik-network
# Jellyseerr, Sonarr, Radarr should all be on same network

# Check logs
docker logs jellyseerr | grep -i "sonarr\|radarr"
```

### Requests Not Sending to Sonarr/Radarr

```bash
# Check request status
# Jellyseerr → Requests tab
# Should show "Requested" → "Approved" → "Processing"

# Check auto-approval settings
# Settings → Users → Permissions
# Auto-approve enabled?

# Manually approve
# Requests → Pending → Approve

# Check Sonarr/Radarr logs
docker logs sonarr | grep -i jellyseerr
docker logs radarr | grep -i jellyseerr

# Verify quality profiles exist
# Sonarr/Radarr → Settings → Profiles
# Profile must match what's configured in Jellyseerr
```

### Users Can't Sign In

```bash
# Verify Jellyfin connection
# Settings → Jellyfin → Test Connection

# Check user exists in Jellyfin
# Jellyfin → Dashboard → Users

# Import users
# Settings → Users → Import Jellyfin Users

# Check permissions
# Settings → Users → Select user → Permissions

# Check logs
docker logs jellyseerr | grep -i auth
```

### Notifications Not Working

```bash
# Test notification
# Settings → Notifications → Select notification → Test

# Check notification settings
# Verify webhook URLs, API keys, etc.

# Check Discord webhook
curl -X POST "https://discord.com/api/webhooks/YOUR/WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{"content":"Test"}'

# Check logs
docker logs jellyseerr | grep -i notification
```

## Performance Optimization

### Database Optimization

```bash
# Jellyseerr uses SQLite
# Stop container
docker stop jellyseerr

# Vacuum database
sqlite3 /opt/stacks/media-management/jellyseerr/config/db/db.sqlite3 "VACUUM;"

# Restart
docker start jellyseerr
```

### Cache Management

**Settings → General:**
- Cache timeout: 6 hours (default)
- Adjust based on library size

### Scan Frequency

- More frequent scans = higher load
- Balance between real-time updates and performance
- Consider library size

## Security Best Practices

1. **Use HTTPS:** Always access via Traefik with SSL
2. **Strong Jellyfin Passwords:** Users authenticate via Jellyfin
3. **Restrict New Sign-Ins:** Disable if not needed
4. **User Quotas:** Prevent abuse
5. **Approve Requests:** Don't auto-approve all users
6. **Regular Updates:** Keep Jellyseerr current
7. **API Key Security:** Keep Sonarr/Radarr keys secure
8. **Network Isolation:** Internal Docker network only

## Backup Strategy

**Critical Files:**
```bash
/opt/stacks/media-management/jellyseerr/config/db/db.sqlite3  # Database
/opt/stacks/media-management/jellyseerr/config/settings.json  # Settings
```

**Backup Script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/opt/backups/jellyseerr

docker stop jellyseerr
tar -czf $BACKUP_DIR/jellyseerr-$DATE.tar.gz \
  /opt/stacks/media-management/jellyseerr/config/
docker start jellyseerr

find $BACKUP_DIR -name "jellyseerr-*.tar.gz" -mtime +7 -delete
```

## Integration with Other Services

### Jellyseerr + Jellyfin
- SSO authentication
- User import
- Library sync
- Availability checking

### Jellyseerr + Sonarr + Radarr
- Automatic request forwarding
- Quality profile mapping
- Status tracking
- Download monitoring

### Jellyseerr + Discord/Telegram
- Request notifications
- Approval notifications
- Availability notifications
- Admin alerts

## Summary

Jellyseerr is the user-friendly request management system offering:
- Beautiful, modern interface
- Jellyfin SSO integration
- Automatic Sonarr/Radarr integration
- Request approval workflow
- User quotas and permissions
- Notification system
- Discovery and browsing
- Free and open-source

**Perfect for:**
- Shared Jellyfin servers
- Family media servers
- Non-technical users
- Request management
- Automated workflows

**Key Points:**
- Jellyfin authentication (SSO)
- Connect to Sonarr and Radarr
- Configure user permissions
- Set up notifications
- Enable/disable auto-approval
- Use quotas to prevent abuse
- Separate 4K management optional

**Remember:**
- Users need Jellyfin accounts
- API keys from Sonarr/Radarr required
- Configure quotas appropriately
- Test notifications
- Regular backups recommended
- Auto-approval optional
- 4K requires separate instances

Jellyseerr makes media requests simple and automated for everyone!
