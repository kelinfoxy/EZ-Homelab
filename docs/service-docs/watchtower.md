# Watchtower - Automated Container Updates

## Table of Contents
- [Overview](#overview)
- [What is Watchtower?](#what-is-watchtower)
- [Why Use Watchtower?](#why-use-watchtower)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Controlling Updates](#controlling-updates)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Infrastructure Automation  
**Docker Image:** [containrrr/watchtower](https://hub.docker.com/r/containrrr/watchtower)  
**Default Stack:** `infrastructure.yml`  
**Web UI:** None (runs as automated service)  
**Default Behavior:** Checks for updates daily at 4 AM

## What is Watchtower?

Watchtower is an automated Docker container update service that monitors running containers and automatically updates them when new images are available. It pulls new images, stops old containers, and starts new ones while preserving volumes and configuration.

### Key Features
- **Automatic Updates:** Keeps containers up-to-date automatically
- **Schedule Control:** Cron-based update scheduling
- **Selective Monitoring:** Choose which containers to update
- **Notifications:** Email, Slack, Discord, etc. on updates
- **Update Strategies:** Rolling updates, one-time runs
- **Cleanup:** Automatically removes old images
- **Dry Run Mode:** Test without actually updating
- **Label-Based Control:** Fine-grained update control per container
- **Zero Downtime:** Seamless container recreation

## Why Use Watchtower?

1. **Security:** Automatic security patches
2. **Convenience:** No manual image updates needed
3. **Consistency:** All containers stay updated
4. **Time Savings:** Automates tedious update process
5. **Minimal Downtime:** Fast container recreation
6. **Safe Updates:** Preserves volumes and configuration
7. **Rollback Support:** Keep old images for fallback
8. **Notification:** Get notified of updates

## How It Works

```
Watchtower (scheduled check)
     ↓
Check Docker Hub for new images
     ↓
Compare with local image digests
     ↓
If new version found:
     ├─ Pull new image
     ├─ Stop old container
     ├─ Remove old container
     ├─ Create new container (same config)
     ├─ Start new container
     └─ Remove old image (optional)
```

### Update Process

1. **Scheduled Check:** Watchtower wakes up (e.g., 4 AM daily)
2. **Scan Containers:** Finds all monitored containers
3. **Check Registries:** Queries Docker Hub/registries for new images
4. **Compare Digests:** Checks if image hash changed
5. **Pull New Image:** Downloads latest version
6. **Recreate Container:** Stops old, starts new with same config
7. **Cleanup:** Removes old images (if configured)
8. **Notify:** Sends notification (if configured)

### What Gets Preserved

✅ **Preserved:**
- Volumes and data
- Networks
- Environment variables
- Labels
- Port mappings
- Restart policy

❌ **Not Preserved:**
- Running processes inside container
- Temporary files in container filesystem
- In-memory data

## Configuration in AI-Homelab

### Directory Structure

```
# Watchtower doesn't need persistent storage
# All configuration via environment variables
```

### Environment Variables

```bash
# Schedule (cron format)
WATCHTOWER_SCHEDULE=0 0 4 * * *  # Daily at 4 AM

# Cleanup old images
WATCHTOWER_CLEANUP=true

# Include stopped containers
WATCHTOWER_INCLUDE_STOPPED=false

# Include restarting containers
WATCHTOWER_INCLUDE_RESTARTING=false

# Debug logging
WATCHTOWER_DEBUG=false

# Notifications (optional)
WATCHTOWER_NOTIFICATIONS=email
WATCHTOWER_NOTIFICATION_EMAIL_FROM=watchtower@yourdomain.com
WATCHTOWER_NOTIFICATION_EMAIL_TO=admin@yourdomain.com
WATCHTOWER_NOTIFICATION_EMAIL_SERVER=smtp.gmail.com
WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT=587
WATCHTOWER_NOTIFICATION_EMAIL_SERVER_USER=your-email@gmail.com
WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PASSWORD=your-app-password
```

## Official Resources

- **GitHub:** https://github.com/containrrr/watchtower
- **Docker Hub:** https://hub.docker.com/r/containrrr/watchtower
- **Documentation:** https://containrrr.dev/watchtower/
- **Arguments Reference:** https://containrrr.dev/watchtower/arguments/

## Educational Resources

### Videos
- [Watchtower - Auto Update Docker Containers (Techno Tim)](https://www.youtube.com/watch?v=5lP_pdjcVMo)
- [Keep Docker Containers Updated Automatically](https://www.youtube.com/watch?v=SZ-wprcMYGY)
- [Watchtower Setup Tutorial (DB Tech)](https://www.youtube.com/watch?v=Ejtzf-Y8Vac)

### Articles & Guides
- [Watchtower Official Documentation](https://containrrr.dev/watchtower/)
- [Docker Update Strategies](https://containrrr.dev/watchtower/arguments/)
- [Notification Configuration](https://containrrr.dev/watchtower/notifications/)
- [Cron Schedule Examples](https://crontab.guru/)

### Concepts to Learn
- **Container Updates:** How Docker updates work
- **Image Digests:** SHA256 hashes for images
- **Cron Scheduling:** Time-based task automation
- **Rolling Updates:** Zero-downtime deployment
- **Image Tags vs Digests:** Differences and implications
- **Semantic Versioning:** Understanding version numbers
- **Docker Labels:** Metadata for containers

## Docker Configuration

### Complete Service Definition

```yaml
watchtower:
  image: containrrr/watchtower:latest
  container_name: watchtower
  restart: unless-stopped
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  environment:
    - WATCHTOWER_SCHEDULE=0 0 4 * * *  # 4 AM daily
    - WATCHTOWER_CLEANUP=true
    - WATCHTOWER_INCLUDE_STOPPED=false
    - WATCHTOWER_INCLUDE_RESTARTING=true
    - WATCHTOWER_ROLLING_RESTART=true
    - WATCHTOWER_TIMEOUT=30s
    - TZ=America/New_York
    # Optional: Notifications
    # - WATCHTOWER_NOTIFICATIONS=email
    # - WATCHTOWER_NOTIFICATION_EMAIL_FROM=watchtower@yourdomain.com
    # - WATCHTOWER_NOTIFICATION_EMAIL_TO=admin@yourdomain.com
```

### Schedule Formats

```bash
# Cron format: second minute hour day month weekday
# * * * * * *  = every second
# 0 * * * * *  = every minute
# 0 0 * * * *  = every hour
# 0 0 4 * * *  = daily at 4 AM
# 0 0 4 * * 0  = weekly on Sunday at 4 AM
# 0 0 4 1 * *  = monthly on 1st at 4 AM

# Common schedules:
WATCHTOWER_SCHEDULE="0 0 4 * * *"        # Daily 4 AM
WATCHTOWER_SCHEDULE="0 0 4 * * 0"        # Weekly Sunday 4 AM
WATCHTOWER_SCHEDULE="0 0 2 1,15 * *"     # 1st and 15th at 2 AM
WATCHTOWER_SCHEDULE="0 */6 * * * *"      # Every 6 hours
```

Use https://crontab.guru/ to test cron expressions.

## Controlling Updates

### Label-Based Control

**Enable/Disable per Container:**

```yaml
myservice:
  image: myapp:latest
  labels:
    # Enable updates (default)
    - "com.centurylinklabs.watchtower.enable=true"
    
    # OR disable updates
    - "com.centurylinklabs.watchtower.enable=false"
```

### Monitor Specific Containers

Run Watchtower with container names:
```bash
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  container1 container2 container3
```

### Exclude Containers

```yaml
watchtower:
  image: containrrr/watchtower
  environment:
    - WATCHTOWER_LABEL_ENABLE=true  # Only update labeled containers
```

Then add label to containers you want updated:
```yaml
myservice:
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
```

### Update Scope

**Scope Options:**
```yaml
environment:
  # Only update containers with specific scope
  - WATCHTOWER_SCOPE=myscope

# Then label containers:
myservice:
  labels:
    - "com.centurylinklabs.watchtower.scope=myscope"
```

## Advanced Topics

### Notification Configuration

#### Email Notifications

```yaml
environment:
  - WATCHTOWER_NOTIFICATIONS=email
  - WATCHTOWER_NOTIFICATION_EMAIL_FROM=watchtower@yourdomain.com
  - WATCHTOWER_NOTIFICATION_EMAIL_TO=admin@yourdomain.com
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER=smtp.gmail.com
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT=587
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_USER=your-email@gmail.com
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PASSWORD=your-app-password
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_TLS_SKIP_VERIFY=false
```

#### Slack Notifications

```yaml
environment:
  - WATCHTOWER_NOTIFICATIONS=slack
  - WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
  - WATCHTOWER_NOTIFICATION_SLACK_IDENTIFIER=watchtower
```

#### Discord Notifications

```yaml
environment:
  - WATCHTOWER_NOTIFICATIONS=discord
  - WATCHTOWER_NOTIFICATION_URL=https://discord.com/api/webhooks/YOUR/WEBHOOK
```

### One-Time Run

Run once and exit (useful for testing):
```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once
```

### Dry Run Mode

Test without actually updating:
```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once \
  --debug \
  --dry-run
```

### Rolling Restart

Update containers one at a time (safer):
```yaml
environment:
  - WATCHTOWER_ROLLING_RESTART=true
```

### Monitor Only Mode

Check for updates but don't apply:
```yaml
environment:
  - WATCHTOWER_MONITOR_ONLY=true
  - WATCHTOWER_NOTIFICATIONS=email  # Get notified of available updates
```

### Custom Update Commands

Run commands after update:
```yaml
myservice:
  labels:
    - "com.centurylinklabs.watchtower.lifecycle.post-update=/scripts/post-update.sh"
```

### Private Registry

Update containers from private registries:
```bash
# Docker Hub
docker login

# Private registry
docker login registry.example.com

# Watchtower will use stored credentials
```

Or configure explicitly:
```yaml
environment:
  - REPO_USER=username
  - REPO_PASS=password
```

## Troubleshooting

### Check Watchtower Status

```bash
# View logs
docker logs watchtower

# Follow logs in real-time
docker logs -f watchtower

# Check last run
docker logs watchtower | grep "Session done"
```

### Force Manual Update

```bash
# Run Watchtower once
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once \
  --debug
```

### Container Not Updating

```bash
# Check if container is monitored
docker logs watchtower | grep container-name

# Verify image has updates
docker pull image:tag

# Check for update labels
docker inspect container-name | grep watchtower

# Force update specific container
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once \
  container-name
```

### Updates Breaking Services

```bash
# Stop Watchtower
docker stop watchtower

# Rollback manually
docker pull image:old-tag
docker compose up -d --force-recreate service-name

# Or restore from backup
# If you kept old images (no cleanup):
docker images | grep image-name
docker tag image:old-sha image:latest
docker compose up -d service-name
```

### High Resource Usage

```bash
# Check Watchtower stats
docker stats watchtower

# Increase check interval
# Change from hourly to daily:
WATCHTOWER_SCHEDULE="0 0 4 * * *"

# Enable cleanup to free disk space
WATCHTOWER_CLEANUP=true
```

### Notification Not Working

```bash
# Test email manually
docker exec watchtower wget --spider https://smtp.gmail.com

# Check credentials
docker logs watchtower | grep -i notification

# Verify SMTP settings
# For Gmail, use App Password, not account password
```

## Best Practices

### Recommended Configuration

```yaml
watchtower:
  image: containrrr/watchtower:latest
  container_name: watchtower
  restart: unless-stopped
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  environment:
    # Daily at 4 AM
    - WATCHTOWER_SCHEDULE=0 0 4 * * *
    
    # Clean up old images
    - WATCHTOWER_CLEANUP=true
    
    # Rolling restart (safer)
    - WATCHTOWER_ROLLING_RESTART=true
    
    # 30 second timeout
    - WATCHTOWER_TIMEOUT=30s
    
    # Enable notifications
    - WATCHTOWER_NOTIFICATIONS=email
    - WATCHTOWER_NOTIFICATION_EMAIL_FROM=watchtower@yourdomain.com
    - WATCHTOWER_NOTIFICATION_EMAIL_TO=admin@yourdomain.com
    
    - TZ=America/New_York
```

### Update Strategy

1. **Start Conservative:**
   - Weekly updates initially
   - Monitor for issues
   - Gradually increase frequency

2. **Use Labels:**
   - Disable updates for critical services
   - Update testing services first
   - Separate production from testing

3. **Enable Notifications:**
   - Know when updates happen
   - Track update history
   - Alert on failures

4. **Test Regularly:**
   - Dry run before enabling
   - Manual one-time runs
   - Verify services after updates

5. **Backup Strategy:**
   - Keep old images (disable cleanup initially)
   - Backup volumes before major updates
   - Document rollback procedures

### Selective Updates

```yaml
# Core infrastructure: Manual updates only
traefik:
  labels:
    - "com.centurylinklabs.watchtower.enable=false"

authelia:
  labels:
    - "com.centurylinklabs.watchtower.enable=false"

# Media services: Auto-update
plex:
  labels:
    - "com.centurylinklabs.watchtower.enable=true"

sonarr:
  labels:
    - "com.centurylinklabs.watchtower.enable=true"
```

## Security Considerations

1. **Docker Socket Access:** Watchtower needs full Docker access (security risk)
2. **Automatic Updates:** Can break things unexpectedly
3. **Test Environment:** Test updates in dev before production
4. **Backup First:** Always backup critical services
5. **Monitor Logs:** Watch for failed updates
6. **Rollback Plan:** Know how to revert updates
7. **Pin Versions:** Use specific tags for critical services
8. **Update Windows:** Schedule during low-usage times
9. **Notification:** Always enable notifications
10. **Review Updates:** Check changelog before auto-updating

## Summary

Watchtower automates container updates, providing:
- Automatic security patches
- Consistent update schedule
- Minimal manual intervention
- Clean, simple configuration
- Notification support
- Label-based control

**Use Watchtower for:**
- Non-critical services
- Media apps (Plex, Sonarr, etc.)
- Utilities and tools
- Development environments

**Avoid for:**
- Core infrastructure (Traefik, Authelia)
- Databases (require careful updates)
- Custom applications
- Services requiring migration steps

**Remember:**
- Start with conservative schedule
- Enable cleanup after testing
- Use labels for fine control
- Monitor notifications
- Have rollback plan
- Test in dry-run mode first
- Backup before major updates
