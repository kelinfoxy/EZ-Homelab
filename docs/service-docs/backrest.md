# Backrest - Comprehensive Backup Solution

**Category:** Backup & Recovery

**Description:** Backrest is a web-based UI for Restic, providing scheduled backups, retention policies, and a beautiful interface for managing backups across multiple repositories and destinations. It serves as the default backup strategy for AI-Homelab.

**Docker Image:** `garethgeorge/backrest:latest`

**Documentation:** [Backrest GitHub](https://github.com/garethgeorge/backrest)

## Overview

### What is Backrest?
Backrest (latest: v1.10.1) is a web-based UI for Restic, built with Go and SvelteKit. It simplifies Restic management:
- **Web Interface**: Create repos, plans, and monitor backups.
- **Automation**: Scheduled backups, hooks (pre/post commands).
- **Integration**: Runs Restic under the hood.
- **Features**: Multi-repo support, retention policies, notifications.

### What is Restic?
Restic (latest: v0.18.1) is a modern, open-source backup program written in Go. It provides:
- **Deduplication**: Efficiently stores only changed data.
- **Encryption**: All data is encrypted with AES-256.
- **Snapshots**: Point-in-time backups with metadata.
- **Cross-Platform**: Works on Linux, macOS, Windows.
- **Backends**: Supports local, SFTP, S3, etc.
- **Features**: Compression, locking, pruning, mounting snapshots.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BACKREST_DATA` | Internal data directory | `/data` |
| `BACKREST_CONFIG` | Configuration file path | `/config/config.json` |
| `BACKREST_UI_CONFIG` | UI configuration JSON | `{"baseURL": "https://backrest.${DOMAIN}"}` |

### Ports

- **9898** - Web UI port

### Volumes

- `./data:/data` - Backrest internal data and repositories
- `./config:/config` - Configuration files
- `./cache:/cache` - Restic cache for performance
- `/var/lib/docker/volumes:/docker_volumes:ro` - Access to Docker volumes
- `/opt/stacks:/opt/stacks:ro` - Access to service configurations
- `/var/run/docker.sock:/var/run/docker.sock` - Docker API access for hooks

## Usage

### Accessing Backrest
- **URL**: `https://backrest.${DOMAIN}`
- **Authentication**: Via Authelia SSO
- **UI Sections**: Repos, Plans, Logs

### Managing Repositories
Repositories store your backups. Create one for your main backup location.

#### Create Repository
1. Go to **Repos** → **Add Repo**
2. **Name**: `main-backup-repo`
3. **Storage**: Choose backend (Local, SFTP, S3, etc.)
4. **Password**: Set strong encryption password
5. **Initialize**: Backrest runs `restic init`

### Creating Backup Plans
Plans define what, when, and how to back up.

#### Database Backup Plan (Recommended)
```json
{
  "id": "database-backup",
  "repo": "main-backup-repo",
  "paths": [
    "/docker_volumes/*_mysql/_data",
    "/docker_volumes/*_postgres/_data"
  ],
  "schedule": {
    "maxFrequencyDays": 1
  },
  "hooks": [
    {
      "actionCommand": {
        "command": "for vol in $(docker volume ls -q | grep '_mysql$'); do docker ps -q --filter volume=$vol | xargs -r docker stop || true; done"
      },
      "conditions": ["CONDITION_SNAPSHOT_START"]
    },
    {
      "actionCommand": {
        "command": "for vol in $(docker volume ls -q | grep '_mysql$'); do docker ps -a -q --filter volume=$vol | xargs -r docker start || true; done"
      },
      "conditions": ["CONDITION_SNAPSHOT_END"]
    }
  ],
  "retention": {
    "policyKeepLastN": 30
  }
}
```

#### Service Configuration Backup Plan
```json
{
  "id": "config-backup",
  "repo": "main-backup-repo",
  "paths": [
    "/opt/stacks"
  ],
  "excludes": [
    "**/cache",
    "**/tmp",
    "**/log"
  ],
  "schedule": {
    "maxFrequencyDays": 1
  },
  "retention": {
    "policyKeepLastN": 14
  }
}
```

### Running Backups
- **Manual**: Plans → Select plan → **Run Backup Now**
- **Scheduled**: Runs automatically per plan schedule
- **Monitor**: Check **Logs** tab for status and errors

### Restoring Data
1. Go to **Repos** → Select repo → **Snapshots**
2. Choose snapshot → **Restore**
3. Select paths/files → Set target directory
4. Run restore operation

## Best Practices

### Security
- Use strong repository passwords
- Limit Backrest UI access via Authelia
- Store passwords securely (not in config files)

### Performance
- Schedule backups during low-usage hours
- Use compression for large backups
- Monitor repository size growth

### Retention
- Keep 30 daily snapshots for critical data
- Keep 14 snapshots for configurations
- Regularly prune old snapshots

### Testing
- Test restore procedures regularly
- Verify backup integrity
- Document restore processes

## Integration with AI-Homelab

### Homepage Dashboard
Add Backrest to your Homepage dashboard:

```yaml
# In homepage/services.yaml
- Infrastructure:
    - Backrest:
        icon: backup.png
        href: https://backrest.${DOMAIN}
        description: Backup management
        widget:
          type: iframe
          url: https://backrest.${DOMAIN}
```

### Monitoring
Monitor backup success with Uptime Kuma or Grafana alerts.

## Troubleshooting

### Common Issues

**Backup Failures**
- Check repository access and credentials
- Verify source paths exist and are readable
- Review hook commands for syntax errors

**Hook Issues**
- Ensure Docker socket is accessible
- Check that containers can be stopped/started
- Verify hook commands work manually

**Performance Problems**
- Check available disk space
- Monitor CPU/memory usage during backups
- Consider excluding large, frequently changing files

**Restore Issues**
- Ensure target directory exists and is writable
- Check file permissions
- Verify snapshot integrity

## Advanced Features

### Multiple Repositories
- **Local**: For fast, local backups
- **Remote**: SFTP/S3 for offsite storage
- **Hybrid**: Local for speed, remote for safety

### Custom Hooks
```bash
# Pre-backup: Stop services
docker compose -f /opt/stacks/core/docker-compose.yml stop

# Post-backup: Start services
docker compose -f /opt/stacks/core/docker-compose.yml start
```

### Notifications
Configure webhooks in Backrest settings for backup status alerts.

## Migration from Other Solutions

### From Duplicati
1. Export Duplicati configurations
2. Create equivalent Backrest plans
3. Test backups and restores
4. Decommission Duplicati

### From Manual Scripts
1. Identify current backup sources and schedules
2. Create Backrest plans with same parameters
3. Add appropriate hooks for service management
4. Test and validate

## Related Documentation

- **[Backup Strategy Guide](../Restic-BackRest-Backup-Guide.md)** - Comprehensive setup and usage guide
- **[Docker Guidelines](../docker-guidelines.md)** - Volume management and persistence
- **[Quick Reference](../quick-reference.md)** - Command reference and troubleshooting

---

**Backrest provides enterprise-grade backup capabilities with an intuitive web interface, making it the perfect default backup solution for AI-Homelab.**
