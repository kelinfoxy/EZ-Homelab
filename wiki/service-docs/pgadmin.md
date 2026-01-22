# pgAdmin - PostgreSQL Management

## Table of Contents
- [Overview](#overview)
- [What is pgAdmin?](#what-is-pgadmin)
- [Why Use pgAdmin?](#why-use-pgadmin)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Database Management  
**Docker Image:** [dpage/pgadmin4](https://hub.docker.com/r/dpage/pgadmin4)  
**Default Stack:** `development.yml`  
**Web UI:** `http://SERVER_IP:5050`  
**Purpose:** PostgreSQL GUI management  
**Ports:** 5050

## What is pgAdmin?

pgAdmin is the most popular open-source management tool for PostgreSQL. It provides a web-based GUI for administering PostgreSQL databases - creating databases, running queries, managing users, viewing data, and more. Essential for PostgreSQL users who prefer visual tools over command-line.

### Key Features
- **Web Interface:** Browser-based access
- **Query Tool:** SQL editor with syntax highlighting
- **Visual Database Designer:** Create tables visually
- **Data Management:** Browse and edit data
- **User Management:** Manage roles and permissions
- **Backup/Restore:** GUI backup operations
- **Server Monitoring:** Performance dashboards
- **Multi-Server:** Manage multiple PostgreSQL servers
- **Free & Open Source:** PostgreSQL license

## Why Use pgAdmin?

1. **Visual Interface:** Easier than command-line
2. **Query Editor:** Write and test SQL visually
3. **Data Browser:** Browse tables easily
4. **Backup Tools:** GUI backup/restore
5. **Multi-Server:** Manage all PostgreSQL instances
6. **Graphical Design:** Design schemas visually
7. **Industry Standard:** Most used PostgreSQL tool

## Configuration in AI-Homelab

```
/opt/stacks/development/pgadmin/data/
  pgadmin4.db         # pgAdmin configuration
  sessions/          # Session data
  storage/           # Server connections
```

## Official Resources

- **Website:** https://www.pgadmin.org
- **Documentation:** https://www.pgadmin.org/docs
- **GitHub:** https://github.com/pgadmin-org/pgadmin4

## Docker Configuration

```yaml
pgadmin:
  image: dpage/pgadmin4:latest
  container_name: pgadmin
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "5050:80"
  environment:
    - PGADMIN_DEFAULT_EMAIL=admin@homelab.local
    - PGADMIN_DEFAULT_PASSWORD=${PGADMIN_PASSWORD}
    - PGADMIN_CONFIG_SERVER_MODE=False
    - PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=False
  volumes:
    - /opt/stacks/development/pgadmin/data:/var/lib/pgadmin
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.pgadmin.rule=Host(`pgadmin.${DOMAIN}`)"
```

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d pgadmin
   ```

2. **Access UI:** `http://SERVER_IP:5050`

3. **Login:**
   - Email: `admin@homelab.local`
   - Password: (from PGADMIN_PASSWORD env)

4. **Add Server:**
   - Right-click "Servers" → Register → Server
   - General tab:
     - Name: `PostgreSQL Dev`
   - Connection tab:
     - Host: `postgres` (container name)
     - Port: `5432`
     - Maintenance database: `postgres`
     - Username: `admin`
     - Password: (from PostgreSQL)
     - Save password: ✓
   - Save

5. **Browse Database:**
   - Expand server tree
   - Servers → PostgreSQL Dev → Databases
   - Right-click database → Query Tool

6. **Run Query:**
   - Query Tool (toolbar icon)
   - Write SQL
   - Execute (F5 or play button)

## Summary

pgAdmin is your PostgreSQL GUI offering:
- Web-based interface
- SQL query editor
- Visual database design
- Data browsing and editing
- User management
- Backup/restore tools
- Multi-server support
- Free and open-source

**Perfect for:**
- PostgreSQL administration
- Visual database management
- SQL query development
- Database design
- Learning PostgreSQL
- Backup management

**Key Points:**
- Web-based (browser access)
- Manage multiple PostgreSQL servers
- Query tool with syntax highlighting
- Visual schema designer
- Default: admin@homelab.local
- Change default password!
- Save server passwords

**Remember:**
- Set strong admin password
- Add all PostgreSQL servers
- Use query tool for SQL
- Save server connections
- Regular backups via GUI
- Monitor server performance
- Explore visual tools

pgAdmin makes PostgreSQL management visual!
