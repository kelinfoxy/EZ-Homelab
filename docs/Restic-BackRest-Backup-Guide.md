# Comprehensive Backup Guide: Restic + Backrest

This guide covers your configured setup with **Restic** (the backup engine) and **Backrest** (the web UI for managing Restic). It includes current info (as of January 2026), configurations, examples, and best practices. Your setup backs up Docker volumes, service configs, and databases with automated stop/start hooks.

## Overview

### What is Restic?
Restic (latest: v0.18.1) is a modern, open-source backup program written in Go. It provides:
- **Deduplication**: Efficiently stores only changed data.
- **Encryption**: All data is encrypted with AES-256.
- **Snapshots**: Point-in-time backups with metadata.
- **Cross-Platform**: Works on Linux, macOS, Windows.
- **Backends**: Supports local, SFTP, S3, etc.
- **Features**: Compression, locking, pruning, mounting snapshots.

Restic is command-line based; Backrest provides a web UI.

### What is Backrest?
Backrest (latest: v1.10.1) is a web-based UI for Restic, built with Go and SvelteKit. It simplifies Restic management:
- **Web Interface**: Create repos, plans, and monitor backups.
- **Automation**: Scheduled backups, hooks (pre/post commands).
- **Integration**: Runs Restic under the hood.
- **Features**: Multi-repo support, retention policies, notifications.

Your Backrest instance is containerized, with access to Docker volumes and host paths.

## Your Current Setup

### Backrest Configuration
- **Container**: `garethgeorge/backrest:latest` on port 9898.
- **Mounts**:
  - `/var/lib/docker/volumes:/docker_volumes` (all Docker volumes).
  - `/opt/stacks:/opt/stacks` (service configs and data).
  - `/var/run/docker.sock` (for Docker commands in hooks).
- **Environment**:
  - `BACKREST_DATA=/data` (internal data).
  - `BACKREST_CONFIG=/config/config.json` (plans/repos).
  - `BACKREST_UI_CONFIG={"baseURL": "https://backrest.kelin-casa.duckdns.org"}` (UI base URL).
- **Repos**: `jarvis-restic-repo` (your main repo).
- **Plans**:
  - **jarvis-database-backup**: Backs up `_mysql` volumes with DB stop/start hooks.
  - **Other Plans**: For volumes/configs (e.g., individual paths like `/docker_volumes/gitea_data/_data`).

### Key Features in Use
- **Hooks**: Pre-backup stops DBs, post-backup starts them.
- **Retention**: Keep last 30 snapshots.
- **Schedule**: Daily backups.
- **Paths**: Selective (e.g., DB volumes, service data).

## Step-by-Step Guide

### 1. Accessing Backrest
- URL: `https://backrest.kelin-casa.duckdns.org`
- Auth: Via Authelia (as configured in NPM).
- UI Sections: Repos, Plans, Logs.

### 2. Managing Repos
Repos store backups. Yours is `jarvis-restic-repo`.

#### Create a New Repo
1. Go to **Repos** > **Add Repo**.
2. **Name**: `my-new-repo`.
3. **Storage**: Choose backend (e.g., Local: `/data/repos/my-new-repo`).
4. **Password**: Set a strong password (Restic encrypts with this).
5. **Initialize**: Backrest runs `restic init`.

#### Example Config (JSON)
```json
{
  "id": "jarvis-restic-repo",
  "uri": "/repos/jarvis-restic-repo",
  "password": "your-secure-password",
  "env": {},
  "flags": []
}
```

#### Best Practices
- Use strong passwords.
- For remote: Use SFTP/S3 for offsite backups.
- Test access: `restic list snapshots --repo /repos/repo-name`.

### 3. Creating Backup Plans
Plans define what/when/how to back up.

#### Your DB Plan Example
```json
{
  "id": "jarvis-database-backup",
  "repo": "jarvis-restic-repo",
  "paths": [
    "/docker_volumes/bookstack_mysql/_data",
    "/docker_volumes/gitea_mysql/_data",
    "/docker_volumes/mediawiki_mysql/_data",
    "/docker_volumes/nextcloud_mysql/_data",
    "/docker_volumes/formio_mysql/_data"
  ],
  "excludes": [],
  "iexcludes": [],
  "schedule": {
    "clock": "CLOCK_LOCAL",
    "maxFrequencyDays": 1
  },
  "backup_flags": [],
  "hooks": [
    {
      "actionCommand": {
        "command": "for vol in $(docker volume ls -q | grep '_mysql$'); do docker ps -q --filter volume=$vol | xargs -r docker stop || true; done"
      },
      "conditions": ["CONDITION_SNAPSHOT_START"],
      "onError": "ON_ERROR_CANCEL"
    },
    {
      "actionCommand": {
        "command": "for vol in $(docker volume ls -q | grep '_mysql$'); do docker ps -a -q --filter volume=$vol | xargs -r docker start || true; done"
      },
      "conditions": ["CONDITION_SNAPSHOT_END"],
      "onError": "ON_ERROR_RETRY_1MINUTE"
    }
  ],
  "retention": {
    "policyKeepLastN": 30
  }
}
```

#### Create a New Plan
1. Go to **Plans** > **Add Plan**.
2. **Repo**: Select `jarvis-restic-repo`.
3. **Paths**: Add directories (e.g., `/opt/stacks/homepage/config`).
4. **Schedule**: Set frequency (e.g., daily).
5. **Hooks**: Add pre/post commands (e.g., for non-DB backups).
6. **Retention**: Keep last N snapshots.
7. **Save & Run**: Test with **Run Backup Now**.

#### Example: Volume Backup Plan
```json
{
  "id": "volumes-backup",
  "repo": "jarvis-restic-repo",
  "paths": [
    "/docker_volumes/gitea_data/_data",
    "/docker_volumes/nextcloud_html/_data"
  ],
  "schedule": {"maxFrequencyDays": 1},
  "retention": {"policyKeepLastN": 14}
}
```

### 4. Running & Monitoring Backups
- **Manual**: Plans > Select plan > **Run Backup**.
- **Scheduled**: Runs automatically per schedule.
- **Logs**: Check **Logs** tab for output/errors.
- **Status**: View snapshots in repo details.

#### Restic Commands (via Backrest)
Backrest runs Restic under the hood. Examples:
- Backup: `restic backup /path --repo /repo`
- List: `restic snapshots --repo /repo`
- Restore: `restic restore latest --repo /repo --target /restore/path`
- Prune: `restic forget --keep-last 30 --repo /repo`

### 5. Restoring Data
1. Go to **Repos** > Select repo > **Snapshots**.
2. Choose snapshot > **Restore**.
3. Select paths/files > Target directory.
4. Run restore.

#### Example Restore Command
```bash
restic restore latest --repo /repos/jarvis-restic-repo --target /tmp/restore --path /docker_volumes/bookstack_mysql/_data
```

### 6. Advanced Features
- **Excludes**: Add glob patterns (e.g., `*.log`) to skip files.
- **Compression**: Enable in backup flags: `--compression max`.
- **Notifications**: Configure webhooks in Backrest settings.
- **Mounting**: `restic mount /repo /mnt/backup` to browse snapshots.
- **Forget/Prune**: Auto-managed via retention, or manual: `restic forget --keep-daily 7 --repo /repo`.

### 7. Best Practices
- **Security**: Use strong repo passwords. Limit Backrest access.
- **Testing**: Regularly test restores.
- **Retention**: Balance storage (e.g., keep 30 daily).
- **Monitoring**: Check logs for failures.
- **Offsite**: Add a remote repo for disaster recovery.
- **Performance**: Schedule during low-usage times.
- **Updates**: Keep Restic/Backrest updated (current versions noted).

### 8. Troubleshooting
- **Hook Failures**: Check Docker socket access; ensure CLI installed.
- **Permissions**: Bind mounts may need `chown` to match container user.
- **Space**: Monitor repo size; prune old snapshots.
- **Errors**: Logs show Restic output; search for "exit status" codes.

This covers your setup. For more, visit [Restic Docs](https://restic.net/) and [Backrest GitHub](https://github.com/garethgeorge/backrest). Let me know if you need help with specific configs!