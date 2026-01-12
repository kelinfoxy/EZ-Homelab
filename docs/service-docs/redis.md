# Redis - In-Memory Cache

## Table of Contents
- [Overview](#overview)
- [What is Redis?](#what-is-redis)
- [Why Use Redis?](#why-use-redis)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Redis Instances](#redis-instances)

## Overview

**Category:** In-Memory Data Store  
**Docker Image:** [redis](https://hub.docker.com/_/redis)  
**Default Stack:** `development.yml` and others  
**Ports:** 6379 (internal)

## What is Redis?

Redis (Remote Dictionary Server) is an in-memory data structure store used as a cache, message broker, and database. It's incredibly fast because data is stored in RAM, making it perfect for caching, sessions, queues, and real-time applications.

### Key Features
- **In-Memory:** Microsecond latency
- **Data Structures:** Strings, lists, sets, hashes, etc.
- **Persistence:** Optional disk writes
- **Pub/Sub:** Message broker
- **Atomic Operations:** Thread-safe operations
- **Replication:** Master-slave
- **Lua Scripting:** Server-side scripts
- **Free & Open Source:** BSD license

## Why Use Redis?

1. **Speed:** Extremely fast (in RAM)
2. **Versatile:** Cache, queue, pub/sub, database
3. **Simple:** Easy to use
4. **Reliable:** Battle-tested
5. **Rich Data Types:** More than key-value
6. **Atomic:** Safe concurrent access
7. **Popular:** Wide adoption

## Configuration in AI-Homelab

AI-Homelab uses Redis for caching and session storage in multiple applications.

## Official Resources

- **Website:** https://redis.io
- **Documentation:** https://redis.io/docs
- **Commands:** https://redis.io/commands

## Redis Instances

### Authentik Redis (authentik-redis)

```yaml
authentik-redis:
  image: redis:alpine
  container_name: authentik-redis
  restart: unless-stopped
  networks:
    - traefik-network
  command: --save 60 1 --loglevel warning
  volumes:
    - /opt/stacks/infrastructure/authentik-redis/data:/data
```

**Purpose:** Authentik SSO caching and sessions  
**Location:** `/opt/stacks/infrastructure/authentik-redis/data`

### GitLab Redis (gitlab-redis)

```yaml
gitlab-redis:
  image: redis:alpine
  container_name: gitlab-redis
  restart: unless-stopped
  networks:
    - traefik-network
  command: --save 60 1 --loglevel warning
  volumes:
    - /opt/stacks/development/gitlab-redis/data:/data
```

**Purpose:** GitLab caching and background jobs  
**Location:** `/opt/stacks/development/gitlab-redis/data`

### Development Redis (redis)

```yaml
redis:
  image: redis:alpine
  container_name: redis
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "6379:6379"
  command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
  volumes:
    - /opt/stacks/development/redis/data:/data
```

**Purpose:** General development caching  
**Location:** `/opt/stacks/development/redis/data`

## Management

### Access Redis CLI

```bash
# Connect to Redis
docker exec -it redis redis-cli

# With password
docker exec -it redis redis-cli -a your_password

# Or authenticate after connecting
AUTH your_password
```

### Common Commands

```redis
# Set key
SET mykey "Hello"

# Get key
GET mykey

# Set with expiration (seconds)
SETEX mykey 60 "expires in 60 seconds"

# List all keys
KEYS *

# Delete key
DEL mykey

# Check if key exists
EXISTS mykey

# Get key type
TYPE mykey

# Flush all data (careful!)
FLUSHALL

# Get info
INFO
```

### Monitor Activity

```bash
# Monitor commands in real-time
docker exec -it redis redis-cli MONITOR

# Get statistics
docker exec -it redis redis-cli INFO stats
```

### Backup Redis

```bash
# Redis automatically saves to dump.rdb
# Just backup the data volume
tar -czf redis-backup.tar.gz /opt/stacks/development/redis/data/

# Force save now
docker exec redis redis-cli SAVE
```

## Summary

Redis provides in-memory storage offering:
- Ultra-fast caching
- Session storage
- Message queuing (pub/sub)
- Real-time operations
- Rich data structures
- Persistence options
- Atomic operations
- Free and open-source

**Perfect for:**
- Application caching
- Session storage
- Real-time analytics
- Message queues
- Leaderboards
- Rate limiting
- Pub/sub messaging

**Key Points:**
- In-memory (very fast)
- Data persists to disk optionally
- Multiple data structures
- Simple key-value interface
- Use password protection
- Low resource usage
- Alpine image is tiny

**Remember:**
- Set password (--requirepass)
- Data stored in RAM
- Configure persistence
- Monitor memory usage
- Backup dump.rdb file
- Use for temporary data
- Not a full database replacement

Redis accelerates your applications with caching!
