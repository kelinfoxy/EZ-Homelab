# Backrest - Backup Solution

## Table of Contents
- [Overview](#overview)
- [What is Backrest?](#what-is-backrest)
- [Why Use Backrest?](#why-use-backrest)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Backup & Recovery  
**Docker Image:** [garethgeorge/backrest](https://hub.docker.com/r/garethgeorge/backrest)  
**Default Stack:** `utilities.yml`  
**Web UI:** `http://SERVER_IP:9898`  
**Backend:** Restic  
**Ports:** 9898

## What is Backrest?

Backrest is a web UI and orchestration layer for Restic, a powerful backup tool. It provides scheduled backups, retention policies, and a beautiful interface for managing backups across multiple repositories and destinations. Think of it as a user-friendly wrapper around Restic's power.

### Key Features
- **Web Interface:** Manage backups visually
- **Multiple Repos:** Backup to different locations
- **Schedules:** Cron-based automatic backups
- **Retention Policies:** Keep last N backups
- **Compression:** Automatic compression
- **Deduplication:** Save storage space
- **Encryption:** AES-256 encryption
- **Destinations:** Local, S3, B2, SFTP, WebDAV
- **Notifications:** Alerts on failure
- **Browse & Restore:** Visual file restoration

## Why Use Backrest?

1. **Easy Backups:** Simple web interface
2. **Restic Power:** Proven backup engine
3. **Automated:** Set and forget
4. **Multiple Destinations:** Flexibility
5. **Encrypted:** Secure backups
6. **Deduplicated:** Efficient storage
7. **Free & Open Source:** No cost

## Configuration in AI-Homelab

```
/opt/stacks/utilities/backrest/data/      # Backrest config
/opt/stacks/utilities/backrest/cache/     # Restic cache
```

## Official Resources

- **GitHub:** https://github.com/garethgeorge/backrest
- **Restic:** https://restic.net

## Docker Configuration

```yaml
backrest:
  image: garethgeorge/backrest:latest
  container_name: backrest
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "9898:9898"
  environment:
    - BACKREST_DATA=/data
    - BACKREST_CONFIG=/config/config.json
    - XDG_CACHE_HOME=/cache
  volumes:
    - /opt/stacks/utilities/backrest/data:/data
    - /opt/stacks/utilities/backrest/config:/config
    - /opt/stacks/utilities/backrest/cache:/cache
    - /opt/stacks:/backup-source:ro  # What to backup
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.backrest.rule=Host(`backrest.${DOMAIN}`)"
```

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d backrest
   ```

2. **Access UI:** `http://SERVER_IP:9898`

3. **Create Repository:**
   - Add Repository
   - Location: Local, S3, B2, etc.
   - Encryption password
   - Initialize repository

4. **Create Plan:**
   - Add backup plan
   - Source: `/backup-source` (mounted volume)
   - Repository: Select created repo
   - Schedule: `0 2 * * *` (2 AM daily)
   - Retention: Keep last 7 daily, 4 weekly, 12 monthly

5. **Run Backup:**
   - Manual: Click "Backup Now"
   - Or wait for schedule

6. **Restore:**
   - Browse backups
   - Select snapshot
   - Browse files
   - Restore to location

## Summary

Backrest provides web-based backup management offering:
- Visual Restic interface
- Scheduled automated backups
- Multiple backup destinations
- Retention policies
- Encryption and deduplication
- Easy restore
- Free and open-source

**Perfect for:**
- Homelab backups
- Docker volume backups
- Off-site backup management
- Automated backup schedules
- Visual backup management

**Key Points:**
- Built on Restic
- Web interface
- Supports many backends
- Encryption by default
- Deduplication saves space
- Cron-based scheduling
- Easy restore interface

**Remember:**
- Mount volumes to backup
- Set retention policies
- Test restores regularly
- Off-site backup recommended
- Keep repository password safe
- Monitor backup success
- Schedule during low usage

Backrest makes Restic backups manageable!
