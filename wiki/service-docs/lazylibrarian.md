# Lazy Librarian - Book Management

## Table of Contents
- [Overview](#overview)
- [What is Lazy Librarian?](#what-is-lazy-librarian)
- [Why Use Lazy Librarian?](#why-use-lazy-librarian)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)

## Overview

**Category:** Book Management  
**Docker Image:** [linuxserver/lazylibrarian](https://hub.docker.com/r/linuxserver/lazylibrarian)  
**Default Stack:** `media-extended.yml`  
**Web UI:** `http://SERVER_IP:5299`  
**Alternative To:** Readarr  
**Ports:** 5299

## What is Lazy Librarian?

Lazy Librarian is an automated book downloader similar to Sonarr/Radarr but for books. It's an alternative to Readarr, with some users preferring its interface and magazine support. It automatically downloads ebooks and audiobooks from your wanted list.

### Key Features
- **Author Tracking:** Monitor favorite authors
- **GoodReads Integration:** Import reading lists
- **Magazine Support:** Download magazines
- **Calibre Integration:** Automatic library management
- **Multiple Providers:** Usenet and torrent indexers
- **Format Management:** EPUB, MOBI, PDF, audiobooks
- **Quality Control:** Preferred formats
- **Notifications:** Discord, Telegram, email

## Why Use Lazy Librarian?

1. **Magazine Support:** Unlike Readarr
2. **GoodReads Integration:** Easy list importing
3. **Calibre Integration:** Seamless library management
4. **Alternative Interface:** Some prefer over Readarr
5. **Mature Project:** Stable and proven
6. **Audiobook Support:** Built-in
7. **Free & Open Source:** No cost

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/media-management/lazylibrarian/config/    # Config
/mnt/media/books/                                    # Book library
/mnt/downloads/                                      # Downloads
```

### Environment Variables

```bash
PUID=1000
PGID=1000
TZ=America/New_York
```

## Official Resources

- **Website:** https://lazylibrarian.gitlab.io
- **GitLab:** https://gitlab.com/LazyLibrarian/LazyLibrarian
- **Wiki:** https://lazylibrarian.gitlab.io/

## Docker Configuration

```yaml
lazylibrarian:
  image: linuxserver/lazylibrarian:latest
  container_name: lazylibrarian
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "5299:5299"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/media-management/lazylibrarian/config:/config
    - /mnt/media/books:/books
    - /mnt/downloads:/downloads
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.lazylibrarian.rule=Host(`lazylibrarian.${DOMAIN}`)"
    - "traefik.http.routers.lazylibrarian.entrypoints=websecure"
    - "traefik.http.routers.lazylibrarian.tls.certresolver=letsencrypt"
    - "traefik.http.routers.lazylibrarian.middlewares=authelia@docker"
    - "traefik.http.services.lazylibrarian.loadbalancer.server.port=5299"
```

## Initial Setup

1. **Start Container:**
   ```bash
   docker compose up -d lazylibrarian
   ```

2. **Access UI:** `http://SERVER_IP:5299`

3. **Configure:**
   - Config → Download Settings → qBittorrent
   - Config → Search Providers → Add providers
   - Config → Processing → Calibre integration
   - Add authors to watch

4. **GoodReads Setup:**
   - Config → GoodReads API → Get API key from goodreads.com/api
   - Import reading list

5. **Add Author:**
   - Search for author
   - Add to database
   - Check "Wanted" books
   - LazyLibrarian searches automatically

## Summary

Lazy Librarian is the book automation tool offering:
- Author and book tracking
- Magazine support (unique feature)
- GoodReads integration
- Calibre compatibility
- Audiobook support
- Alternative to Readarr
- Free and open-source

**Perfect for:**
- Book collectors
- Magazine readers
- GoodReads users
- Calibre users
- Those wanting Readarr alternative

**Key Points:**
- Supports magazines (Readarr doesn't)
- GoodReads API required
- Calibre integration available
- Configure download client
- Add search providers
- Monitor authors, not individual books

**Readarr vs Lazy Librarian:**
- Readarr: Newer, cleaner UI, active development
- Lazy Librarian: Magazines, mature, different approach
- Both integrate with Calibre
- Choose based on preference

Lazy Librarian automates your book and magazine collection!
