# Gitea - Git Server

## Table of Contents
- [Overview](#overview)
- [What is Gitea?](#what-is-gitea)
- [Why Use Gitea?](#why-use-gitea)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Git Repository Hosting  
**Docker Image:** [gitea/gitea](https://hub.docker.com/r/gitea/gitea)  
**Default Stack:** `productivity.yml`  
**Web UI:** `https://gitea.${DOMAIN}` or `http://SERVER_IP:3000`  
**SSH:** Port 222  
**Ports:** 3000, 222

## What is Gitea?

Gitea is a self-hosted Git service similar to GitHub/GitLab but lightweight and easy to deploy. It provides web-based Git repository hosting with features like pull requests, code review, issue tracking, and CI/CD integration - all running on your own infrastructure.

### Key Features
- **Git Repositories:** Unlimited repos
- **Web Interface:** GitHub-like UI
- **Pull Requests:** Code review workflow
- **Issue Tracking:** Built-in bug tracking
- **Wiki:** Per-repository wikis
- **Organizations:** Team management
- **SSH & HTTP:** Git access methods
- **Actions:** CI/CD (GitHub Actions compatible)
- **Webhooks:** Integration hooks
- **API:** REST API
- **Lightweight:** Runs on Raspberry Pi
- **Free & Open Source:** MIT license

## Why Use Gitea?

1. **Self-Hosted:** Control your code
2. **Private Repos:** Unlimited private repos
3. **Lightweight:** Low resource usage
4. **Fast:** Go-based, very quick
5. **Easy Setup:** Minutes to deploy
6. **GitHub Alternative:** Similar features
7. **No Limits:** No user/repo restrictions
8. **Privacy:** Code never leaves your server

## Configuration in AI-Homelab

```
/opt/stacks/productivity/gitea/data/          # Git repos
/opt/stacks/productivity/gitea/config/        # Configuration
```

## Official Resources

- **Website:** https://gitea.io
- **Documentation:** https://docs.gitea.io
- **GitHub:** https://github.com/go-gitea/gitea

## Docker Configuration

```yaml
gitea:
  image: gitea/gitea:latest
  container_name: gitea
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "3000:3000"
    - "222:22"
  environment:
    - USER_UID=1000
    - USER_GID=1000
    - GITEA__database__DB_TYPE=sqlite3
    - GITEA__server__DOMAIN=gitea.${DOMAIN}
    - GITEA__server__ROOT_URL=https://gitea.${DOMAIN}
    - GITEA__server__SSH_DOMAIN=gitea.${DOMAIN}
    - GITEA__server__SSH_PORT=222
  volumes:
    - /opt/stacks/productivity/gitea/data:/data
    - /etc/timezone:/etc/timezone:ro
    - /etc/localtime:/etc/localtime:ro
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.gitea.rule=Host(`gitea.${DOMAIN}`)"
```

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d gitea
   ```

2. **Access UI:** `http://SERVER_IP:3000`

3. **Initial Configuration:**
   - Database: SQLite (default, sufficient for most)
   - Admin username/password
   - Application URL: `https://gitea.yourdomain.com`
   - SSH Port: 222

4. **Create Repository:**
   - "+" button → New Repository
   - Name, description, visibility
   - Initialize with README if desired

5. **Clone Repository:**
   ```bash
   # HTTPS
   git clone https://gitea.yourdomain.com/username/repo.git

   # SSH (configure SSH key first)
   git clone ssh://git@gitea.yourdomain.com:222/username/repo.git
   ```

## Summary

Gitea is your self-hosted Git server offering:
- GitHub-like interface
- Unlimited repositories
- Pull requests & code review
- Issue tracking
- Organizations & teams
- CI/CD with Actions
- Lightweight & fast
- Free and open-source

**Perfect for:**
- Personal projects
- Private code hosting
- Team development
- GitHub alternative
- Code portfolio
- Learning Git workflows
- CI/CD pipelines

**Key Points:**
- Very lightweight (runs on Pi)
- GitHub-like features
- SSH and HTTPS access
- Built-in CI/CD (Actions)
- SQLite or external DB
- Webhook support
- API available
- Easy migration from GitHub

**Remember:**
- Configure SSH keys for easy access
- Use organizations for teams
- Enable Actions for CI/CD
- Regular backups of /data
- Strong admin password
- Consider external database for heavy use
- Port 222 for SSH (avoid 22 conflict)

Gitea puts your code under your control!
