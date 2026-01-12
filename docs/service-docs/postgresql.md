# PostgreSQL - Database Services

## Table of Contents
- [Overview](#overview)
- [What is PostgreSQL?](#what-is-postgresql)
- [Why Use PostgreSQL?](#why-use-postgresql)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Database Instances](#database-instances)

## Overview

**Category:** Relational Database  
**Docker Image:** [postgres](https://hub.docker.com/_/postgres)  
**Default Stack:** `development.yml`  
**Ports:** 5432 (internal)

## What is PostgreSQL?

PostgreSQL is an advanced open-source relational database. It's more feature-rich than MySQL/MariaDB, with better support for complex queries, JSON, full-text search, and extensions. Many consider it the best open-source database.

### Key Features
- **ACID Compliant:** Reliable transactions
- **JSON Support:** Native JSON/JSONB
- **Extensions:** PostGIS, pg_trgm, etc.
- **Full-Text Search:** Built-in FTS
- **Complex Queries:** Advanced SQL
- **Replication:** Streaming replication
- **Performance:** Excellent for complex queries
- **Free & Open Source:** PostgreSQL license

## Why Use PostgreSQL?

1. **Feature-Rich:** More features than MySQL
2. **Standards Compliant:** SQL standard
3. **JSON Support:** Native JSON queries
4. **Extensions:** Powerful ecosystem
5. **Reliability:** ACID compliant
6. **Performance:** Great for complex queries
7. **Community:** Strong development

## Configuration in AI-Homelab

AI-Homelab uses separate PostgreSQL instances for different applications.

## Official Resources

- **Website:** https://www.postgresql.org
- **Documentation:** https://www.postgresql.org/docs
- **Docker Hub:** https://hub.docker.com/_/postgres

## Database Instances

### GitLab Database (gitlab-postgres)

```yaml
gitlab-postgres:
  image: postgres:14
  container_name: gitlab-postgres
  restart: unless-stopped
  networks:
    - traefik-network
  environment:
    - POSTGRES_DB=gitlabhq_production
    - POSTGRES_USER=gitlab
    - POSTGRES_PASSWORD=${GITLAB_DB_PASSWORD}
  volumes:
    - /opt/stacks/development/gitlab-postgres/data:/var/lib/postgresql/data
```

**Purpose:** GitLab platform database  
**Location:** `/opt/stacks/development/gitlab-postgres/data`

### Development Database (postgres)

```yaml
postgres:
  image: postgres:latest
  container_name: postgres
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "5432:5432"
  environment:
    - POSTGRES_USER=admin
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    - POSTGRES_DB=postgres
  volumes:
    - /opt/stacks/development/postgres/data:/var/lib/postgresql/data
```

**Purpose:** General development database  
**Location:** `/opt/stacks/development/postgres/data`

## Management

### Access Database

```bash
# Connect to PostgreSQL
docker exec -it postgres psql -U admin -d postgres

# Or specific database
docker exec -it postgres psql -U admin -d dbname
```

### Common Commands

```sql
-- List databases
\l

-- Connect to database
\c database_name

-- List tables
\dt

-- Describe table
\d table_name

-- List users
\du

-- Quit
\q
```

### Backup Database

```bash
# Backup single database
docker exec postgres pg_dump -U admin dbname > backup.sql

# Backup all databases
docker exec postgres pg_dumpall -U admin > all_dbs_backup.sql

# Restore database
docker exec -i postgres psql -U admin -d dbname < backup.sql
```

### Create Database/User

```sql
-- Create database
CREATE DATABASE myapp;

-- Create user
CREATE USER myuser WITH PASSWORD 'password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE myapp TO myuser;
```

## Summary

PostgreSQL provides advanced database services for:
- GitLab (if using PostgreSQL backend)
- Development applications
- Applications needing JSON support
- Complex query requirements
- Extensions like PostGIS

**Key Points:**
- More advanced than MySQL
- Native JSON support
- Powerful extensions
- ACID compliance
- Excellent performance
- Standards compliant
- Free and open-source

**Remember:**
- Use strong passwords
- Regular backups critical
- Monitor disk space
- VACUUM periodically
- Use pgAdmin for GUI management
- Test backups work
- Separate containers for isolation

PostgreSQL powers your advanced applications!
