# WordPress - Content Management System

## Table of Contents
- [Overview](#overview)
- [What is WordPress?](#what-is-wordpress)
- [Why Use WordPress?](#why-use-wordpress)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Website/Blog Platform  
**Docker Image:** [wordpress](https://hub.docker.com/_/wordpress)  
**Default Stack:** `productivity.yml`  
**Web UI:** `https://wordpress.${DOMAIN}` or `http://SERVER_IP:8082`  
**Database:** MariaDB (wordpress-db container)  
**Ports:** 8082

## What is WordPress?

WordPress is the world's most popular content management system (CMS), powering 40%+ of all websites. While often associated with blogs, it's a full-featured CMS capable of building any type of website - from simple blogs to complex e-commerce sites.

### Key Features
- **Easy Content Editing:** WYSIWYG editor
- **10,000+ Themes:** Customizable designs
- **58,000+ Plugins:** Extend functionality
- **Media Management:** Photos, videos, files
- **SEO Friendly:** Built-in optimization
- **Multi-User:** Different permission levels
- **Mobile Responsive:** Most themes mobile-ready
- **Gutenberg Editor:** Block-based content
- **E-commerce:** WooCommerce plugin
- **Free & Open Source:** Core is free

## Why Use WordPress?

1. **Industry Standard:** Most popular CMS
2. **Easy to Use:** Non-technical friendly
3. **Huge Ecosystem:** Themes and plugins
4. **Community:** Massive support community
5. **Self-Hosted:** Own your content
6. **SEO:** Excellent SEO capabilities
7. **Flexible:** Any type of website
8. **Free Core:** Pay only for premium add-ons

## Configuration in AI-Homelab

```
/opt/stacks/productivity/wordpress/html/         # WordPress files
/opt/stacks/productivity/wordpress-db/data/      # MariaDB database
```

## Official Resources

- **Website:** https://wordpress.org
- **Documentation:** https://wordpress.org/support
- **Themes:** https://wordpress.org/themes
- **Plugins:** https://wordpress.org/plugins

## Docker Configuration

```yaml
wordpress-db:
  image: mariadb:latest
  container_name: wordpress-db
  restart: unless-stopped
  networks:
    - traefik-network
  environment:
    - MYSQL_ROOT_PASSWORD=${WP_DB_ROOT_PASSWORD}
    - MYSQL_DATABASE=wordpress
    - MYSQL_USER=wordpress
    - MYSQL_PASSWORD=${WP_DB_PASSWORD}
  volumes:
    - /opt/stacks/productivity/wordpress-db/data:/var/lib/mysql

wordpress:
  image: wordpress:latest
  container_name: wordpress
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8082:80"
  environment:
    - WORDPRESS_DB_HOST=wordpress-db
    - WORDPRESS_DB_USER=wordpress
    - WORDPRESS_DB_PASSWORD=${WP_DB_PASSWORD}
    - WORDPRESS_DB_NAME=wordpress
  volumes:
    - /opt/stacks/productivity/wordpress/html:/var/www/html
  depends_on:
    - wordpress-db
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.wordpress.rule=Host(`wordpress.${DOMAIN}`)"
```

## Summary

WordPress is the world's leading CMS offering:
- Easy content management
- 58,000+ plugins
- 10,000+ themes
- SEO optimization
- Multi-user support
- E-commerce ready
- Mobile responsive
- Free and open-source

**Perfect for:**
- Personal blogs
- Business websites
- Portfolio sites
- E-commerce (WooCommerce)
- News sites
- Knowledge bases
- Any public website

**Key Points:**
- Requires MariaDB database
- Install security plugins
- Regular updates critical
- Backup database regularly
- Use strong admin password
- Consider security hardening
- Performance caching recommended

**Remember:**
- Keep WordPress updated
- Backup regularly
- Use security plugins (Wordfence)
- Strong passwords essential
- Limit login attempts
- SSL certificate recommended
- Performance plugins help

WordPress powers your website with endless possibilities!
