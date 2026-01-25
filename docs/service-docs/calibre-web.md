# Calibre-Web - Ebook Library Manager

## Table of Contents
- [Overview](#overview)
- [What is Calibre-Web?](#what-is-calibre-web)
- [Why Use Calibre-Web?](#why-use-calibre-web)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Ebook Management  
**Docker Image:** [linuxserver/calibre-web](https://hub.docker.com/r/linuxserver/calibre-web)  
**Default Stack:** `media.yml`  
**Web UI:** `https://calibre-web.${DOMAIN}` or `http://SERVER_IP:8083`  
**Default Login:** admin/admin123  
**Ports:** 8083

## What is Calibre-Web?

Calibre-Web is a web-based ebook reader and library manager. It provides a clean interface to browse, read, and download ebooks from your Calibre library. Works perfectly with Readarr for automated ebook management.

### Key Features
- **Web Reader:** Read ebooks in browser
- **Format Support:** EPUB, PDF, MOBI, AZW3, CBR, CBZ
- **User Management:** Multiple users with permissions
- **Send to Kindle:** Email books to Kindle
- **OPDS Feed:** E-reader app integration
- **Metadata Editing:** Edit book information
- **Custom Columns:** Organize your way
- **Shelves:** Create reading lists
- **Download:** Multiple formats available

## Why Use Calibre-Web?

1. **Web Access:** Read anywhere with browser
2. **No Calibre Desktop:** Standalone web interface
3. **Multi-User:** Family members can have accounts
4. **Kindle Integration:** Send books to Kindle
5. **E-Reader Support:** OPDS for apps
6. **Readarr Compatible:** Works with automated downloads
7. **Free & Open Source:** No cost

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media-management/calibre-web/config/    # Config
/mnt/media/books/                                 # Calibre library
```

### Environment Variables

```bash
PUID=1000
PGID=1000
TZ=America/New_York
DOCKER_MODS=linuxserver/mods:universal-calibre  # Optional: Convert books
```

## Official Resources

- **GitHub:** https://github.com/janeczku/calibre-web
- **Documentation:** https://github.com/janeczku/calibre-web/wiki

## Docker Configuration

```yaml
calibre-web:
  image: linuxserver/calibre-web:latest
  container_name: calibre-web
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8083:8083"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - DOCKER_MODS=linuxserver/mods:universal-calibre
  volumes:
    - /opt/stacks/media-management/calibre-web/config:/config
    - /mnt/media/books:/books
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.calibre-web.rule=Host(`calibre-web.${DOMAIN}`)"
    - "traefik.http.routers.calibre-web.entrypoints=websecure"
    - "traefik.http.routers.calibre-web.tls.certresolver=letsencrypt"
    - "traefik.http.services.calibre-web.loadbalancer.server.port=8083"
```

## Initial Setup

1. **Start Container:**
   ```bash
   docker compose up -d calibre-web
   ```

2. **Access UI:** `http://SERVER_IP:8083`

3. **First Login:**
   - Username: `admin`
   - Password: `admin123`
   - **Change immediately!**

4. **Database Location:**
   - Set to: `/books/metadata.db`
   - This is your Calibre library database

5. **Configure Settings:**
   - Admin → Edit Basic Configuration
   - Set server name, enable features
   - Configure email for Kindle sending

### Key Settings

**Basic Configuration:**
- Server Name: Your server name
- Enable uploads: ✓ (if wanted)
- Enable public registration: ✗ (keep private)

**Feature Configuration:**
- Enable uploading: Based on needs
- Enable book conversion: ✓
- Enable Goodreads integration: ✓ (optional)

**UI Configuration:**
- Theme: Dark/Light
- Books per page: 20
- Random books: 4

## Troubleshooting

### Can't Find Database

```bash
# Check Calibre library structure
ls -la /mnt/media/books/
# Should contain metadata.db

# If no Calibre library exists:
# Install Calibre desktop app
# Create library pointing to /mnt/media/books/
# Or let Readarr create it

# Check permissions
sudo chown -R 1000:1000 /mnt/media/books/
```

### Books Not Showing

```bash
# Check database path
# Admin → Basic Configuration → Database location

# Rescan library
# Admin → Reconnect to Calibre DB

# Check logs
docker logs calibre-web | tail -20
```

### Send to Kindle Not Working

```bash
# Configure email settings
# Admin → Edit Basic Configuration → E-mail Server Settings

# Gmail example:
# SMTP: smtp.gmail.com
# Port: 587
# Encryption: STARTTLS
# Username: your@gmail.com
# Password: App-specific password

# Add Kindle email
# User → Edit → Kindle E-mail
```

## Summary

Calibre-Web is the ebook reader offering:
- Web-based reading
- Format conversion
- Multi-user support
- Kindle integration
- OPDS feeds
- Readarr compatible
- Free and open-source

**Perfect for:**
- Ebook collections
- Web-based reading
- Family sharing
- Kindle users
- Readarr integration

**Key Points:**
- Requires Calibre library (metadata.db)
- Works with Readarr
- Change default password!
- OPDS for e-reader apps
- Send to Kindle via email

**Remember:**
- Point to existing Calibre library
- Or create new library with Calibre desktop
- Readarr can populate library
- Multi-user support available
- Supports most ebook formats

Calibre-Web provides beautiful web access to your ebook library!
