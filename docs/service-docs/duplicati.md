# Duplicati - Backup Solution

## Table of Contents
- [Overview](#overview)
- [What is Duplicati?](#what-is-duplicati)
- [Why Use Duplicati?](#why-use-duplicati)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Backup & Recovery  
**Docker Image:** [linuxserver/duplicati](https://hub.docker.com/r/linuxserver/duplicati)  
**Default Stack:** `utilities.yml`  
**Web UI:** `http://SERVER_IP:8200`  
**Ports:** 8200

## What is Duplicati?

Duplicati is a backup client that securely stores encrypted, incremental, compressed backups on cloud storage or other locations. It supports many cloud providers, has a web interface, and is completely free and open-source.

### Key Features
- **20+ Backends:** S3, B2, Google Drive, OneDrive, SFTP, etc.
- **Encryption:** AES-256 encryption
- **Compression:** Multiple algorithms
- **Incremental:** Only changed data
- **Deduplication:** Block-level dedup
- **Web Interface:** Browser-based
- **Scheduling:** Automated backups
- **Throttling:** Bandwidth control
- **Versioning:** Multiple versions
- **Free & Open Source:** No cost

## Why Use Duplicati?

1. **Cloud Friendly:** 20+ storage backends
2. **Encrypted:** Secure backups
3. **Incremental:** Fast backups
4. **Free:** No licensing costs
5. **Web UI:** Easy management
6. **Windows Support:** Cross-platform
7. **Mature:** Proven solution

## Configuration in AI-Homelab

```
/opt/stacks/utilities/duplicati/config/    # Duplicati config
```

## Official Resources

- **Website:** https://www.duplicati.com
- **Documentation:** https://duplicati.readthedocs.io
- **Forum:** https://forum.duplicati.com

## Docker Configuration

```yaml
duplicati:
  image: linuxserver/duplicati:latest
  container_name: duplicati
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8200:8200"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/utilities/duplicati/config:/config
    - /opt/stacks:/source:ro  # Source data
    - /mnt:/backups  # Backup destination
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.duplicati.rule=Host(`duplicati.${DOMAIN}`)"
```

## Summary

Duplicati provides encrypted backups to 20+ cloud storage providers with web-based management, incremental backups, and comprehensive versioning.

**Perfect for:**
- Cloud backups
- Encrypted off-site storage
- Multi-cloud backup strategy
- Scheduled automatic backups
- Version retention

**Key Points:**
- 20+ storage backends
- AES-256 encryption
- Block-level deduplication
- Web-based interface
- Incremental backups
- Bandwidth throttling
- Free and open-source

Duplicati backs up your data to the cloud!
