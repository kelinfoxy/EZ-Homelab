# GitLab - DevOps Platform

## Table of Contents
- [Overview](#overview)
- [What is GitLab?](#what-is-gitlab)
- [Why Use GitLab?](#why-use-gitlab)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** DevOps Platform  
**Docker Image:** [gitlab/gitlab-ce](https://hub.docker.com/r/gitlab/gitlab-ce)  
**Default Stack:** `development.yml`  
**Web UI:** `http://SERVER_IP:8929`  
**SSH:** Port 2224  
**Ports:** 8929, 2224  
**Resource Requirements:** 4GB+ RAM

## What is GitLab?

GitLab is a complete DevOps platform - Git hosting, CI/CD, issue tracking, container registry, and more in one application. It's the open-source alternative to GitHub Enterprise, providing everything needed for modern software development.

### Key Features
- **Git Repositories:** Unlimited repos
- **CI/CD:** GitLab Runner integration
- **Issue Tracking:** Project management
- **Container Registry:** Docker image hosting
- **Wiki:** Per-project documentation
- **Code Review:** Merge requests
- **Snippets:** Code sharing
- **Auto DevOps:** Automated CI/CD
- **Security Scanning:** Built-in security
- **Free & Open Source:** CE edition

## Why Use GitLab?

1. **All-in-One:** Git + CI/CD + more
2. **Self-Hosted:** Private code platform
3. **CI/CD Included:** No separate service
4. **Container Registry:** Host Docker images
5. **Issue Tracking:** Built-in project management
6. **GitHub Alternative:** More features included
7. **Active Development:** Regular updates

## Configuration in AI-Homelab

```
/opt/stacks/development/gitlab/
  config/              # GitLab configuration
  logs/               # Application logs
  data/               # Git repositories, uploads
```

**Warning:** GitLab is resource-intensive (4GB+ RAM minimum).

## Official Resources

- **Website:** https://about.gitlab.com
- **Documentation:** https://docs.gitlab.com
- **CI/CD Docs:** https://docs.gitlab.com/ee/ci

## Docker Configuration

```yaml
gitlab:
  image: gitlab/gitlab-ce:latest
  container_name: gitlab
  restart: unless-stopped
  hostname: gitlab.${DOMAIN}
  networks:
    - traefik-network
  ports:
    - "8929:80"
    - "2224:22"
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'https://gitlab.${DOMAIN}'
      gitlab_rails['gitlab_shell_ssh_port'] = 2224
      gitlab_rails['time_zone'] = 'America/New_York'
  volumes:
    - /opt/stacks/development/gitlab/config:/etc/gitlab
    - /opt/stacks/development/gitlab/logs:/var/log/gitlab
    - /opt/stacks/development/gitlab/data:/var/opt/gitlab
  shm_size: '256m'
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.gitlab.rule=Host(`gitlab.${DOMAIN}`)"
```

**Note:** First startup takes 5-10 minutes. GitLab needs significant resources.

## Summary

GitLab is your complete DevOps platform offering:
- Git repository hosting
- Built-in CI/CD pipelines
- Container registry
- Issue tracking
- Wiki and documentation
- Code review (merge requests)
- Security scanning
- Free and open-source

**Perfect for:**
- Private Git hosting
- CI/CD pipelines
- Team development
- DevOps workflows
- Container image hosting
- Project management
- Self-hosted GitHub alternative

**Key Points:**
- Requires 4GB+ RAM
- All-in-one DevOps platform
- Built-in CI/CD
- Container registry included
- First startup slow (5-10 min)
- SSH on port 2224
- Resource intensive

**Remember:**
- Needs significant resources
- Initial setup takes time
- Get root password from logs
- Configure GitLab Runner for CI/CD
- Container registry built-in
- Regular backups important
- Update carefully (read changelogs)

GitLab provides enterprise DevOps at home!
