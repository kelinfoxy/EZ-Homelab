# DokuWiki - Documentation Wiki

## Table of Contents
- [Overview](#overview)
- [What is DokuWiki?](#what-is-dokuwiki)
- [Why Use DokuWiki?](#why-use-dokuwiki)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Wiki/Documentation  
**Docker Image:** [linuxserver/dokuwiki](https://hub.docker.com/r/linuxserver/dokuwiki)  
**Default Stack:** `productivity.yml`  
**Web UI:** `http://SERVER_IP:8083`  
**Database:** None (flat-file)  
**Ports:** 8083

## What is DokuWiki?

DokuWiki is a simple, standards-compliant wiki optimized for creating documentation. Unlike MediaWiki (Wikipedia's software), DokuWiki stores pages in plain text files, requiring no database. Perfect for personal notes, project documentation, and team knowledge bases.

### Key Features
- **No Database:** Flat-file storage
- **Easy Syntax:** Simple wiki markup
- **Version Control:** Built-in revisions
- **Access Control:** User permissions
- **Search:** Full-text search
- **Plugins:** 1000+ plugins
- **Templates:** Customizable themes
- **Media Files:** Image/file uploads
- **Namespace:** Organize pages in folders
- **Free & Open Source:** GPL license

## Why Use DokuWiki?

1. **Simple:** No database needed
2. **Fast:** Lightweight and quick
3. **Easy Editing:** Wiki syntax
4. **Backup:** Just copy text files
5. **Version History:** All changes tracked
6. **Portable:** Text files, easy to migrate
7. **Low Maintenance:** Minimal requirements
8. **Privacy:** Self-hosted docs

## Configuration in AI-Homelab

```
/opt/stacks/productivity/dokuwiki/config/
  dokuwiki/
    data/pages/         # Wiki pages (text files)
    data/media/         # Uploaded files
    conf/              # Configuration
```

## Official Resources

- **Website:** https://www.dokuwiki.org
- **Documentation:** https://www.dokuwiki.org/manual
- **Plugins:** https://www.dokuwiki.org/plugins
- **Syntax:** https://www.dokuwiki.org/syntax

## Docker Configuration

```yaml
dokuwiki:
  image: linuxserver/dokuwiki:latest
  container_name: dokuwiki
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8083:80"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
  volumes:
    - /opt/stacks/productivity/dokuwiki/config:/config
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.dokuwiki.rule=Host(`dokuwiki.${DOMAIN}`)"
```

## Summary

DokuWiki is the simple documentation wiki offering:
- No database required
- Plain text storage
- Easy wiki syntax
- Version control
- Fast and lightweight
- Plugin ecosystem
- Access control
- Free and open-source

**Perfect for:**
- Personal knowledge base
- Project documentation
- Team wikis
- Technical notes
- How-to guides
- Simple documentation needs

**Key Points:**
- Flat-file storage (no DB)
- Easy backup (copy files)
- Simple wiki markup
- Built-in version history
- Namespace organization
- User permissions available
- 1000+ plugins
- Very low resource usage

**Remember:**
- Pages stored as text files
- Namespace = folder structure
- Plugins for extended features
- Access control per page
- Regular file backups
- Simple syntax to learn

DokuWiki keeps documentation simple and portable!
