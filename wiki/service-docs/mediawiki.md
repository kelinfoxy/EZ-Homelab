# MediaWiki - Wiki Platform

## Table of Contents
- [Overview](#overview)
- [What is MediaWiki?](#what-is-mediawiki)
- [Why Use MediaWiki?](#why-use-mediawiki)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Wiki Platform  
**Docker Image:** [mediawiki](https://hub.docker.com/_/mediawiki)  
**Default Stack:** `productivity.yml`  
**Web UI:** `http://SERVER_IP:8084`  
**Database:** MariaDB (mediawiki-db container)  
**Ports:** 8084

## What is MediaWiki?

MediaWiki is the software that powers Wikipedia. It's a powerful, feature-rich wiki platform designed for large-scale collaborative documentation. If you want Wikipedia-style wikis with advanced features, templates, and extensions, MediaWiki is the choice.

### Key Features
- **Powers Wikipedia:** Battle-tested at scale
- **Advanced Markup:** Wikitext syntax
- **Templates:** Reusable content blocks
- **Categories:** Organize pages
- **Version History:** Complete revision tracking
- **Extensions:** 2000+ extensions
- **Multi-Language:** Full internationalization
- **Media Management:** Images, files
- **User Management:** Roles and rights
- **API:** Comprehensive API
- **Free & Open Source:** GPL license

## Why Use MediaWiki?

1. **Feature-Rich:** Most powerful wiki software
2. **Proven:** Runs Wikipedia
3. **Extensible:** 2000+ extensions
4. **Templates:** Advanced content reuse
5. **Categories:** Powerful organization
6. **API:** Extensive automation
7. **Community:** Large user base
8. **Professional:** Enterprise-grade

## Configuration in AI-Homelab

```
/opt/stacks/productivity/mediawiki/html/         # MediaWiki installation
/opt/stacks/productivity/mediawiki/images/       # Uploaded files
/opt/stacks/productivity/mediawiki-db/data/      # MariaDB database
```

## Official Resources

- **Website:** https://www.mediawiki.org
- **Documentation:** https://www.mediawiki.org/wiki/Documentation
- **Extensions:** https://www.mediawiki.org/wiki/Category:Extensions
- **Manual:** https://www.mediawiki.org/wiki/Manual:Contents

## Docker Configuration

```yaml
mediawiki-db:
  image: mariadb:latest
  container_name: mediawiki-db
  restart: unless-stopped
  networks:
    - traefik-network
  environment:
    - MYSQL_ROOT_PASSWORD=${MEDIAWIKI_DB_ROOT_PASSWORD}
    - MYSQL_DATABASE=mediawiki
    - MYSQL_USER=mediawiki
    - MYSQL_PASSWORD=${MEDIAWIKI_DB_PASSWORD}
  volumes:
    - /opt/stacks/productivity/mediawiki-db/data:/var/lib/mysql

mediawiki:
  image: mediawiki:latest
  container_name: mediawiki
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8084:80"
  environment:
    - MEDIAWIKI_DB_HOST=mediawiki-db
    - MEDIAWIKI_DB_NAME=mediawiki
    - MEDIAWIKI_DB_USER=mediawiki
    - MEDIAWIKI_DB_PASSWORD=${MEDIAWIKI_DB_PASSWORD}
  volumes:
    - /opt/stacks/productivity/mediawiki/html:/var/www/html
    - /opt/stacks/productivity/mediawiki/images:/var/www/html/images
  depends_on:
    - mediawiki-db
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.mediawiki.rule=Host(`mediawiki.${DOMAIN}`)"
```

## Summary

MediaWiki is the enterprise wiki platform offering:
- Wikipedia's proven software
- Advanced wikitext markup
- Template system
- 2000+ extensions
- Categories and organization
- Complete revision history
- Multi-language support
- Free and open-source

**Perfect for:**
- Large wikis
- Complex documentation
- Wikipedia-style sites
- Corporate knowledge bases
- Community documentation
- Template-heavy content
- Multi-language wikis

**Key Points:**
- Requires MariaDB database
- Wikipedia's software
- Steeper learning curve
- Very powerful features
- Template system
- Extension ecosystem
- Wikitext syntax
- Enterprise-grade

**Remember:**
- Complete installation wizard
- Download LocalSettings.php after setup
- Place in /var/www/html/
- Wikitext syntax to learn
- Extensions add features
- Templates powerful but complex
- Regular backups important

MediaWiki brings Wikipedia's power to your wiki!
