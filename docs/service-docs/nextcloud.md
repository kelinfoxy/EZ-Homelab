# Nextcloud - Private Cloud Storage

## Table of Contents
- [Overview](#overview)
- [What is Nextcloud?](#what-is-nextcloud)
- [Why Use Nextcloud?](#why-use-nextcloud)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)
- [Setup](#setup)
- [Apps](#apps)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** File Storage & Collaboration  
**Docker Image:** [nextcloud](https://hub.docker.com/_/nextcloud)  
**Default Stack:** `productivity.yml`  
**Web UI:** `https://nextcloud.${DOMAIN}` or `http://SERVER_IP:8081`  
**Database:** MariaDB (separate container)  
**Ports:** 8081

## What is Nextcloud?

Nextcloud is a self-hosted alternative to Google Drive, Dropbox, and Microsoft 365. It provides file sync/share, calendar, contacts, office documents, video calls, and 200+ apps - all hosted on your own server with complete privacy.

### Key Features
- **File Sync & Share:** Like Dropbox
- **Calendar & Contacts:** Sync across devices
- **Office Suite:** Collaborative document editing
- **Photos:** Google Photos alternative
- **Video Calls:** Built-in Talk
- **Notes:** Markdown notes
- **Tasks:** Todo lists
- **200+ Apps:** Extensible platform
- **Mobile Apps:** iOS and Android
- **Desktop Sync:** Windows, Mac, Linux
- **E2E Encryption:** End-to-end encryption
- **Free & Open Source:** No subscriptions

## Why Use Nextcloud?

1. **Privacy:** Your data, your server
2. **No Limits:** Unlimited storage (your disk)
3. **No Subscriptions:** $0/month forever
4. **All-in-One:** Files, calendar, contacts, office
5. **Sync Everything:** Desktop and mobile apps
6. **Extensible:** Hundreds of apps
7. **Collaboration:** Share with family/team
8. **Standards:** CalDAV, CardDAV, WebDAV

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/productivity/nextcloud/
  html/               # Nextcloud installation
  data/              # User files
  config/            # Configuration
  apps/              # Installed apps

/opt/stacks/productivity/nextcloud-db/
  data/              # MariaDB database
```

### Environment Variables

```bash
# Nextcloud
MYSQL_HOST=nextcloud-db
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
MYSQL_PASSWORD=secure_password
NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.yourdomain.com

# MariaDB
MYSQL_ROOT_PASSWORD=root_password
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
MYSQL_PASSWORD=secure_password
```

## Official Resources

- **Website:** https://nextcloud.com
- **Documentation:** https://docs.nextcloud.com
- **Apps:** https://apps.nextcloud.com
- **Community:** https://help.nextcloud.com

## Docker Configuration

```yaml
nextcloud-db:
  image: mariadb:latest
  container_name: nextcloud-db
  restart: unless-stopped
  networks:
    - traefik-network
  environment:
    - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    - MYSQL_DATABASE=nextcloud
    - MYSQL_USER=nextcloud
    - MYSQL_PASSWORD=${MYSQL_PASSWORD}
  volumes:
    - /opt/stacks/productivity/nextcloud-db/data:/var/lib/mysql
  command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW

nextcloud:
  image: nextcloud:latest
  container_name: nextcloud
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8081:80"
  environment:
    - MYSQL_HOST=nextcloud-db
    - MYSQL_DATABASE=nextcloud
    - MYSQL_USER=nextcloud
    - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    - NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.${DOMAIN}
  volumes:
    - /opt/stacks/productivity/nextcloud/html:/var/www/html
    - /opt/stacks/productivity/nextcloud/data:/var/www/html/data
    - /opt/stacks/productivity/nextcloud/config:/var/www/html/config
    - /opt/stacks/productivity/nextcloud/apps:/var/www/html/custom_apps
  depends_on:
    - nextcloud-db
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.nextcloud.rule=Host(`nextcloud.${DOMAIN}`)"
    - "traefik.http.routers.nextcloud.entrypoints=websecure"
    - "traefik.http.routers.nextcloud.tls.certresolver=letsencrypt"
    - "traefik.http.services.nextcloud.loadbalancer.server.port=80"
```

## Setup

1. **Start Containers:**
   ```bash
   docker compose up -d nextcloud-db nextcloud
   ```

2. **Wait for DB Initialization:**
   ```bash
   docker logs nextcloud-db -f
   # Wait for "mysqld: ready for connections"
   ```

3. **Access UI:** `http://SERVER_IP:8081`

4. **Create Admin Account:**
   - Username: admin
   - Password: Strong password
   - Click "Install"

5. **Initial Configuration:**
   - Skip recommended apps (install later)
   - Allow data folder location

6. **Fix Trusted Domains (if external access):**
   ```bash
   docker exec -it --user www-data nextcloud php occ config:system:set trusted_domains 1 --value=nextcloud.yourdomain.com
   ```

## Apps

### Essential Apps

**Files:**
- **Photos:** Google Photos alternative with face recognition
- **Files Automated Tagging:** Auto-tag files
- **External Storage:** Connect other storage

**Productivity:**
- **Calendar:** CalDAV calendar sync
- **Contacts:** CardDAV contact sync
- **Tasks:** Todo list with CalDAV sync
- **Deck:** Kanban boards
- **Notes:** Markdown notes

**Office:**
- **Nextcloud Office:** Collaborative documents (based on Collabora)
- **OnlyOffice:** Alternative office suite

**Communication:**
- **Talk:** Video calls and chat
- **Mail:** Email client

**Media:**
- **Music:** Music player and library
- **News:** RSS reader

### Installing Apps

**Method 1: UI**
1. Apps menu (top right)
2. Browse or search
3. Download and enable

**Method 2: Command Line**
```bash
docker exec -it --user www-data nextcloud php occ app:install photos
docker exec -it --user www-data nextcloud php occ app:enable photos
```

## Troubleshooting

### Can't Access After Setup

```bash
# Add trusted domain
docker exec -it --user www-data nextcloud php occ config:system:set trusted_domains 1 --value=SERVER_IP

# Or edit config
docker exec -it nextcloud nano /var/www/html/config/config.php
# Add to 'trusted_domains' array
```

### Security Warnings

```bash
# Run maintenance mode
docker exec -it --user www-data nextcloud php occ maintenance:mode --on

# Clear cache
docker exec -it --user www-data nextcloud php occ maintenance:repair

# Update htaccess
docker exec -it --user www-data nextcloud php occ maintenance:update:htaccess

# Exit maintenance
docker exec -it --user www-data nextcloud php occ maintenance:mode --off
```

### Slow Performance

```bash
# Enable caching
docker exec -it --user www-data nextcloud php occ config:system:set memcache.local --value='\\OC\\Memcache\\APCu'

# Run background jobs via cron
docker exec -it --user www-data nextcloud php occ background:cron
```

### Missing Indices

```bash
# Add missing database indices
docker exec -it --user www-data nextcloud php occ db:add-missing-indices

# Convert to bigint (for large instances)
docker exec -it --user www-data nextcloud php occ db:convert-filecache-bigint
```

## Summary

Nextcloud is your private cloud offering:
- File sync and sharing
- Calendar and contacts sync
- Collaborative office suite
- Photo management
- Video calls
- 200+ apps
- Mobile and desktop clients
- Complete privacy
- Free and open-source

**Perfect for:**
- Replacing Google Drive/Dropbox
- Family file sharing
- Photo backup
- Calendar/contact sync
- Team collaboration
- Privacy-conscious users

**Key Points:**
- Requires MariaDB database
- 2GB RAM minimum
- Desktop sync clients available
- Mobile apps for iOS/Android
- CalDAV/CardDAV standards
- Enable caching for performance
- Regular backups important

**Remember:**
- Configure trusted domains
- Enable recommended apps
- Setup desktop sync client
- Mobile apps for phone backup
- Regular database maintenance
- Keep updated for security

Nextcloud puts you in control of your data!
