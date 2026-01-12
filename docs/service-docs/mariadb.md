# MariaDB - Database Services

## Table of Contents
- [Overview](#overview)
- [What is MariaDB?](#what-is-mariadb)
- [Why Use MariaDB?](#why-use-mariadb)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Database Instances in AI-Homelab](#database-instances-in-ai-homelab)
- [Management](#management)

## Overview

**Category:** Relational Database  
**Docker Image:** [mariadb](https://hub.docker.com/_/mariadb)  
**Default Stack:** `productivity.yml` (multiple instances)  
**Ports:** 3306 (internal, not exposed)

## What is MariaDB?

MariaDB is a drop-in replacement for MySQL, created by MySQL's original developers after Oracle acquired MySQL. It's a fast, reliable relational database used by millions of applications. In AI-Homelab, separate MariaDB instances serve different applications.

### Key Features
- **MySQL Compatible:** Drop-in replacement
- **Fast:** High performance
- **Reliable:** ACID compliant
- **Standard SQL:** Industry standard
- **Replication:** Master-slave support
- **Hot Backups:** Online backups
- **Storage Engines:** Multiple engines
- **Free & Open Source:** GPL license

## Why Use MariaDB?

1. **MySQL Alternative:** Better governance than Oracle MySQL
2. **Performance:** Often faster than MySQL
3. **Compatible:** Works with MySQL applications
4. **Open Source:** Truly community-driven
5. **Stable:** Production-ready
6. **Standard:** SQL standard compliance
7. **Support:** Wide adoption

## Configuration in AI-Homelab

### Database Instances

AI-Homelab uses **separate MariaDB containers** for each application to ensure:
- **Isolation:** App failures don't affect others
- **Backup Independence:** Backup apps separately
- **Resource Control:** Per-app resource limits
- **Version Control:** Different versions if needed

## Official Resources

- **Website:** https://mariadb.org
- **Documentation:** https://mariadb.com/kb/en/documentation
- **Docker Hub:** https://hub.docker.com/_/mariadb

## Database Instances in AI-Homelab

### 1. Nextcloud Database (nextcloud-db)

```yaml
nextcloud-db:
  image: mariadb:latest
  container_name: nextcloud-db
  restart: unless-stopped
  networks:
    - traefik-network
  environment:
    - MYSQL_ROOT_PASSWORD=${NEXTCLOUD_DB_ROOT_PASSWORD}
    - MYSQL_DATABASE=nextcloud
    - MYSQL_USER=nextcloud
    - MYSQL_PASSWORD=${NEXTCLOUD_DB_PASSWORD}
  volumes:
    - /opt/stacks/productivity/nextcloud-db/data:/var/lib/mysql
  command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
```

**Purpose:** Nextcloud file storage metadata  
**Location:** `/opt/stacks/productivity/nextcloud-db/data`  
**Special:** Requires specific transaction isolation

### 2. WordPress Database (wordpress-db)

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
```

**Purpose:** WordPress content and configuration  
**Location:** `/opt/stacks/productivity/wordpress-db/data`

### 3. BookStack Database (bookstack-db)

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
```

**Purpose:** BookStack knowledge base content  
**Location:** `/opt/stacks/productivity/bookstack-db/data`

### 4. MediaWiki Database (mediawiki-db)

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
```

**Purpose:** MediaWiki wiki content  
**Location:** `/opt/stacks/productivity/mediawiki-db/data`

## Management

### Access Database

```bash
# Connect to database
docker exec -it nextcloud-db mysql -u nextcloud -p

# Or as root
docker exec -it nextcloud-db mysql -u root -p
```

### Backup Database

```bash
# Backup single database
docker exec nextcloud-db mysqldump -u root -p${ROOT_PASSWORD} nextcloud > nextcloud-backup.sql

# Backup all databases
docker exec nextcloud-db mysqldump -u root -p${ROOT_PASSWORD} --all-databases > all-dbs-backup.sql

# Restore database
docker exec -i nextcloud-db mysql -u root -p${ROOT_PASSWORD} nextcloud < nextcloud-backup.sql
```

### Check Database Size

```bash
# Check size
docker exec -it nextcloud-db mysql -u root -p -e "
SELECT 
  table_schema AS 'Database',
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.TABLES
GROUP BY table_schema;"
```

### Optimize Database

```bash
# Optimize all tables
docker exec nextcloud-db mysqlcheck -u root -p --optimize --all-databases
```

## Summary

MariaDB provides reliable database services for:
- Nextcloud (file metadata)
- WordPress (content management)
- BookStack (knowledge base)
- MediaWiki (wiki content)
- Future applications

**Key Points:**
- Separate container per application
- Isolated for reliability
- Standard MySQL compatibility
- ACID compliance
- Easy backup/restore
- Low resource usage
- Production-ready

**Remember:**
- Use strong passwords
- Regular backups critical
- Monitor disk space
- Optimize periodically
- Update carefully
- Test backups work
- Separate containers = better isolation

MariaDB powers your data-driven applications!
