# BookStack - Knowledge Base

## Table of Contents
- [Overview](#overview)
- [What is BookStack?](#what-is-bookstack)
- [Why Use BookStack?](#why-use-bookstack)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Wiki/Knowledge Base  
**Docker Image:** [linuxserver/bookstack](https://hub.docker.com/r/linuxserver/bookstack)  
**Default Stack:** `productivity.yml`  
**Web UI:** `http://SERVER_IP:6875`  
**Database:** MariaDB (bookstack-db container)  
**Ports:** 6875

## What is BookStack?

BookStack is a beautiful, easy-to-use platform for organizing and storing information. It uses a Books → Chapters → Pages hierarchy, making it perfect for documentation, wikis, and knowledge bases. Think of it as a self-hosted alternative to Notion or Confluence.

### Key Features
- **Book Organization:** Books → Chapters → Pages
- **WYSIWYG Editor:** Rich text editing
- **Markdown Support:** Alternative editor
- **Page Revisions:** Version history
- **Search:** Full-text search
- **Attachments:** File uploads
- **Multi-Tenancy:** Per-book permissions
- **User Management:** Roles and permissions
- **Diagrams:** Draw.io integration
- **API:** REST API
- **Free & Open Source:** MIT license

## Why Use BookStack?

1. **Beautiful UI:** Modern, clean design
2. **Intuitive:** Book/chapter structure makes sense
3. **Easy Editing:** WYSIWYG or Markdown
4. **Organized:** Natural hierarchy
5. **Permissions:** Granular access control
6. **Search:** Find anything quickly
7. **Diagrams:** Built-in diagram editor
8. **Active Development:** Regular updates

## Configuration in AI-Homelab

```
/opt/stacks/productivity/bookstack/config/       # BookStack config
/opt/stacks/productivity/bookstack-db/data/      # MariaDB database
```

## Official Resources

- **Website:** https://www.bookstackapp.com
- **Documentation:** https://www.bookstackapp.com/docs
- **GitHub:** https://github.com/BookStackApp/BookStack
- **Demo:** https://demo.bookstackapp.com

## Docker Configuration

```yaml
bookstack-db:
  image: mariadb:latest
  container_name: bookstack-db
  restart: unless-stopped
  networks:
    - traefik-network
  environment:
    - MYSQL_ROOT_PASSWORD=${BOOKSTACK_DB_ROOT_PASSWORD}
    - MYSQL_DATABASE=bookstack
    - MYSQL_USER=bookstack
    - MYSQL_PASSWORD=${BOOKSTACK_DB_PASSWORD}
  volumes:
    - /opt/stacks/productivity/bookstack-db/data:/var/lib/mysql

bookstack:
  image: linuxserver/bookstack:latest
  container_name: bookstack
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "6875:80"
  environment:
    - PUID=1000
    - PGID=1000
    - TZ=America/New_York
    - DB_HOST=bookstack-db
    - DB_DATABASE=bookstack
    - DB_USERNAME=bookstack
    - DB_PASSWORD=${BOOKSTACK_DB_PASSWORD}
    - APP_URL=https://bookstack.${DOMAIN}
  volumes:
    - /opt/stacks/productivity/bookstack/config:/config
  depends_on:
    - bookstack-db
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.bookstack.rule=Host(`bookstack.${DOMAIN}`)"
```

## Summary

BookStack is your organized knowledge base offering:
- Beautiful book/chapter/page structure
- WYSIWYG and Markdown editors
- Version history
- Granular permissions
- Full-text search
- Diagram editor
- File attachments
- Free and open-source

**Perfect for:**
- Company documentation
- Team knowledge bases
- Project documentation
- Personal notes
- Technical documentation
- Procedures and guides
- Collaborative writing

**Key Points:**
- Requires MariaDB database
- Book → Chapter → Page hierarchy
- Default login: admin@admin.com / password
- Change default credentials!
- WYSIWYG or Markdown editing
- Fine-grained permissions
- Draw.io integration
- REST API available

**Remember:**
- Change default admin credentials
- Set APP_URL for proper links
- Organize content in books
- Use chapters for sections
- Set permissions per book
- Regular database backups
- Search is very powerful

BookStack makes documentation beautiful and organized!
