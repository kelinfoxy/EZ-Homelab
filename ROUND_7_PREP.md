# Round 7 Testing - Preparation and Safety Guidelines

## Mission Context
Test AI-Homelab deployment scripts with focus on **safe cleanup and recovery** procedures. Round 6 revealed that aggressive cleanup operations caused system crashes requiring hard reboots and BIOS recovery.

## Critical Safety Requirements - NEW for Round 7

### ⚠️ SYSTEM CRASH PREVENTION
**Issue from Round 6**: Aggressive cleanup operations caused system crashes requiring power cycles and BIOS recovery attempts.

**Root Causes Identified**:
1. Removing directories while Docker containers were actively using them
2. Aggressive `rm -rf` operations on Docker volumes while containers running
3. No graceful shutdown sequence before cleanup
4. Docker volume operations causing filesystem corruption

### Safe Testing Procedure

#### Before Each Test Run
1. **Always use the new reset script** instead of manual cleanup
2. **Never** run cleanup commands while containers are running
3. **Always** stop containers gracefully before removing files
4. **Monitor** system resources during operations

#### Using the Safe Reset Script
```bash
cd ~/AI-Homelab/scripts
sudo ./reset-test-environment.sh
```

This script:
- ✅ Stops all containers gracefully (proper shutdown)
- ✅ Waits for containers to fully stop
- ✅ Removes Docker volumes safely
- ✅ Cleans directories only after containers stopped
- ✅ Preserves system packages and settings
- ✅ Does NOT touch Docker installation
- ✅ Does NOT modify system files

#### What NOT to Do (Dangerous Operations)
```bash
# ❌ NEVER do these while containers are running:
rm -rf /opt/stacks/core/traefik  # Can corrupt active containers
rm -rf /var/lib/docker/volumes/*  # Filesystem corruption risk
docker volume rm $(docker volume ls -q)  # Removes volumes containers need
find /var/lib/docker -exec rm -rf {} +  # EXTREMELY DANGEROUS

# ❌ NEVER force remove running containers:
docker rm -f $(docker ps -aq)  # Can cause state corruption

# ❌ NEVER use pkill on Docker processes:
pkill -9 docker  # Can corrupt Docker daemon state
```

#### Safe Cleanup Sequence (Manual)
If you need to clean up manually:
```bash
# 1. Stop services gracefully
cd /opt/stacks/core
docker compose down  # Waits for clean shutdown

# 2. Wait for full stop
sleep 5

# 3. Then and only then remove files
rm -rf /opt/stacks/core/traefik
rm -rf /opt/stacks/core/authelia

# 4. Remove volumes after containers stopped
docker volume rm core_authelia-data
```

## Round 7 Objectives

### Primary Goals
1. ✅ Verify safe reset script works without system crashes
2. ✅ Test full deployment after reset (round-trip testing)
3. ✅ Validate no file system corruption occurs
4. ✅ Ensure containers start cleanly after reset
5. ✅ Document any remaining edge cases

### Testing Checklist

#### Pre-Testing Setup
- [ ] System is stable and responsive
- [ ] All previous containers stopped cleanly
- [ ] Disk space sufficient (5GB+ free)
- [ ] No filesystem errors: `dmesg | grep -i error`
- [ ] Docker daemon healthy: `systemctl status docker`

#### Round 7 Test Sequence
1. **Clean slate** using reset script
   ```bash
   sudo ./scripts/reset-test-environment.sh
   ```
   - [ ] Script completes without errors
   - [ ] System remains responsive
   - [ ] No kernel panics or crashes
   - [ ] All volumes removed cleanly

2. **Fresh deployment** with improved scripts
   ```bash
   sudo ./scripts/setup-homelab.sh
   ```
   - [ ] Completes successfully
   - [ ] No permission errors
   - [ ] Password hash generated correctly
   - [ ] Credentials saved properly

3. **Deploy infrastructure**
   ```bash
   sudo ./scripts/deploy-homelab.sh
   ```
   - [ ] Containers start cleanly
   - [ ] No file conflicts
   - [ ] Authelia initializes properly
   - [ ] Credentials work immediately

4. **Verify services**
   - [ ] Traefik accessible and routing
   - [ ] Authelia login works
   - [ ] Dockge UI accessible
   - [ ] SSL certificates generating

5. **Test reset again** (idempotency)
   ```bash
   sudo ./scripts/reset-test-environment.sh
   ```
   - [ ] Stops everything gracefully
   - [ ] No orphaned containers
   - [ ] No volume leaks
   - [ ] System stable after reset

## Changes Made for Round 7

### New Files
- **`scripts/reset-test-environment.sh`** - Safe cleanup script with proper shutdown sequence

### Modified Files
- **`scripts/deploy-homelab.sh`**:
  - Added graceful container stop before config file operations
  - Removed automatic database cleanup (now use reset script instead)
  - Added safety checks before rm operations
  - Better warnings about existing databases

### Removed Dangerous Operations
```bash
# REMOVED from deploy-homelab.sh:
docker compose up -d authelia 2>&1 | grep -q "encryption key" && {
    docker compose down authelia
    sudo rm -rf /var/lib/docker/volumes/core_authelia-data/_data/*
}
# This was causing crashes - containers couldn't handle abrupt volume removal

# REMOVED blind directory removal:
rm -rf /opt/stacks/core/traefik /opt/stacks/core/authelia
# Now checks if containers are running first
```

## System Health Monitoring

### Before Each Test Run
```bash
# Check system health
free -h  # Memory available
df -h    # Disk space
dmesg | tail -20  # Recent kernel messages
systemctl status docker  # Docker daemon health
docker ps  # Running containers
```

### During Testing
- Monitor system logs: `journalctl -f`
- Watch Docker logs: `docker compose logs -f`
- Check resource usage: `htop` or `top`

### After Issues
```bash
# If system becomes unresponsive:
# 1. DO NOT hard power off immediately
# 2. Try to SSH in from another machine
# 3. Gracefully stop Docker: systemctl stop docker
# 4. Wait 30 seconds for disk writes to complete
# 5. Then reboot: systemctl reboot

# Check for filesystem corruption after boot:
sudo dmesg | grep -i error
sudo journalctl -xb | grep -i error
```

## Recovery Procedures

### If Deploy Script Hangs
```bash
# In another terminal:
cd /opt/stacks/core
docker compose ps  # See what's running
docker compose logs authelia  # Check for errors
docker compose down  # Stop gracefully
# Then re-run deploy
```

### If Authelia Won't Start (Encryption Key Error)
```bash
# Use the reset script:
sudo ./scripts/reset-test-environment.sh
# Then start fresh deployment
```

### If System Crashed During Testing
```bash
# After reboot:
# 1. Check Docker state
systemctl status docker
docker ps -a  # Look for crashed containers

# 2. Clean up properly
cd /opt/stacks/core
docker compose down --remove-orphans

# 3. Remove corrupted volumes
docker volume prune -f

# 4. Start fresh with reset script
sudo ./scripts/reset-test-environment.sh
```

## Success Criteria for Round 7

### Must Have
- ✅ Reset script completes without system crashes
- ✅ Can deploy and reset multiple times safely
- ✅ No filesystem corruption after any operation
- ✅ System remains responsive throughout testing
- ✅ All containers stop gracefully

### Should Have
- ✅ Clear warnings before destructive operations
- ✅ Confirmation prompts for cleanup
- ✅ Progress indicators during long operations
- ✅ Health checks before and after operations

### Nice to Have
- ⭐ Automatic backup before reset
- ⭐ Rollback capability
- ⭐ System health validation
- ⭐ Detailed logging of all operations

## Emergency Contacts / References

- Docker best practices: https://docs.docker.com/config/daemon/
- Linux filesystem safety: `man sync`, `man fsync`
- systemd service management: `man systemctl`

## Post-Round 7 Review

### Document These
- [ ] Any new crash scenarios discovered
- [ ] System resource usage patterns
- [ ] Time required for clean operations
- [ ] Any remaining unsafe operations
- [ ] User experience improvements needed

---

**Remember**: System stability is more important than testing speed. Always wait for clean shutdowns and never force operations.
