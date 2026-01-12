# Uptime Kuma - Uptime Monitoring

## Table of Contents
- [Overview](#overview)
- [What is Uptime Kuma?](#what-is-uptime-kuma)
- [Why Use Uptime Kuma?](#why-use-uptime-kuma)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Uptime Monitoring  
**Docker Image:** [louislam/uptime-kuma](https://hub.docker.com/r/louislam/uptime-kuma)  
**Default Stack:** `monitoring.yml`  
**Web UI:** `http://SERVER_IP:3001`  
**Ports:** 3001

## What is Uptime Kuma?

Uptime Kuma is a self-hosted monitoring tool like UptimeRobot. It monitors HTTP(s), TCP, DNS, ping, and more services, sending notifications when they go down. Beautiful UI with status pages, perfect for monitoring your homelab services.

### Key Features
- **20+ Monitor Types:** HTTP, TCP, ping, DNS, Docker, etc.
- **Beautiful UI:** Modern, clean interface
- **Status Pages:** Public/private status pages
- **Notifications:** 90+ notification services
- **Multi-Language:** 40+ languages
- **Certificates:** SSL cert expiry monitoring
- **Responsive:** Mobile-friendly
- **Free & Open Source:** No limits

## Why Use Uptime Kuma?

1. **Self-Hosted:** No external dependencies
2. **Beautiful:** Best-in-class UI
3. **Free:** Unlike UptimeRobot paid tiers
4. **Comprehensive:** 20+ monitor types
5. **Status Pages:** Share uptime publicly
6. **Active Development:** Rapid updates
7. **Easy:** Simple to setup

## Configuration in AI-Homelab

```
/opt/stacks/monitoring/uptime-kuma/data/
  kuma.db             # SQLite database
```

## Official Resources

- **GitHub:** https://github.com/louislam/uptime-kuma
- **Demo:** https://demo.uptime.kuma.pet

## Docker Configuration

```yaml
uptime-kuma:
  image: louislam/uptime-kuma:latest
  container_name: uptime-kuma
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "3001:3001"
  volumes:
    - /opt/stacks/monitoring/uptime-kuma/data:/app/data
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.uptime-kuma.rule=Host(`uptime.${DOMAIN}`)"
```

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d uptime-kuma
   ```

2. **Access UI:** `http://SERVER_IP:3001`

3. **Create Account:**
   - First user becomes admin
   - Set username and password

4. **Add Monitor:**
   - "+ Add New Monitor"
   - Type: HTTP(s), TCP, Ping, etc.
   - URL: https://service.yourdomain.com
   - Interval: 60 seconds
   - Retry: 3 times
   - Save

5. **Setup Notifications:**
   - Settings → Notifications
   - Add notification (Discord, Telegram, Email, etc.)
   - Test notification
   - Apply to monitors

6. **Create Status Page:**
   - Status Pages → "+ New Status Page"
   - Add monitors to display
   - Customize theme
   - Make public or private
   - Share URL

## Monitor Types

- **HTTP(s):** Website monitoring
- **TCP:** Port monitoring
- **Ping:** ICMP ping
- **DNS:** DNS resolution
- **Docker Container:** Container status
- **Keyword:** Search for text in page
- **JSON Query:** Check JSON response
- **SSL Certificate:** Cert expiry

## Summary

Uptime Kuma provides uptime monitoring offering:
- 20+ monitor types
- Beautiful web interface
- Status pages
- 90+ notification services
- SSL certificate monitoring
- Docker container monitoring
- Free and open-source

**Perfect for:**
- Service uptime monitoring
- Public status pages
- SSL cert expiry alerts
- Homelab monitoring
- Replacing UptimeRobot
- Team uptime visibility

**Key Points:**
- Self-hosted monitoring
- Beautiful modern UI
- 20+ monitor types
- 90+ notification options
- Public/private status pages
- First user = admin
- Very active development

**Remember:**
- Create admin account first
- Add all critical services
- Setup notifications
- Create status page for visibility
- Monitor SSL certificates
- Set appropriate check intervals
- Test notifications work

Uptime Kuma keeps your services monitored!
