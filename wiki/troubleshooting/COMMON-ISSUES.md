# Common Issues and Solutions

## Installation Issues

### Docker Group Permissions

**Symptom:** `permission denied while trying to connect to the Docker daemon socket`

**Solution:**
```bash
# After running setup script, you must log out and back in
exit  # or logout

# Or without logging out:
newgrp docker
```

### Password Hash Generation Timeout

**Symptom:** Password hash generation takes longer than 60 seconds

**Causes:**
- High CPU usage from other processes
- Slow system (argon2 is computationally intensive)

**Solutions:**
```bash
# Check system resources
top
# or
htop

# If system is slow, reduce argon2 iterations (less secure but faster)
# This is handled automatically by Authelia - just wait
# On very slow systems, it may take up to 2 minutes
```

### Port Conflicts

**Symptom:** `bind: address already in use`

**Solution:**
```bash
# Check what's using the port
sudo lsof -i :80
sudo lsof -i :443

# Common culprits:
# - Apache: sudo systemctl stop apache2
# - Nginx: sudo systemctl stop nginx
# - Another container: docker ps (find and stop it)
```

## Deployment Issues

### Authelia Restart Loop

**Symptom:** Authelia container keeps restarting

**Common causes:**
1. **Password hash corruption** - Fixed in current version
2. **Encryption key mismatch** - Changed .env after initial deployment

**Solution:**
```bash
# Check logs
sudo docker logs authelia

# If encryption key error, reset Authelia database:
sudo ./scripts/reset-test-environment.sh
# Then run setup and deploy again
```

### Watchtower Issues

**Status:** Temporarily disabled due to Docker API compatibility

**Issue:** Docker 29.x requires API v1.44, but Watchtower versions have compatibility issues

**Current state:** Commented out in infrastructure.yml with documentation

**Manual updates instead:**
```bash
# Update all images in a stack
cd /opt/stacks/stack-name/
docker compose pull
docker compose up -d
```

### Homepage Not Showing Correct URLs

**Symptom:** Homepage shows `{{HOMEPAGE_VAR_DOMAIN}}` instead of actual domain

**Cause:** Old deployment script version

**Solution:**
```bash
# Re-run deployment script (safe - won't affect running services)
sudo ./scripts/deploy-homelab.sh

# Or manually fix:
cd /opt/stacks/dashboards/homepage
sudo find . -name "*.yaml" -exec sed -i "s/{{HOMEPAGE_VAR_DOMAIN}}/yourdomain.duckdns.org/g" {} \;
```

### Services Not Accessible via HTTPS

**Symptom:** Can't access services at https://service.yourdomain.duckdns.org

**Solutions:**

1. **Check Traefik is running:**
```bash
sudo docker ps | grep traefik
sudo docker logs traefik
```

2. **Verify DuckDNS is updating:**
```bash
sudo docker logs duckdns
# Should show "Your IP has been updated"
```

3. **Check ports are open:**
```bash
sudo ufw status
# Should show 80/tcp and 443/tcp ALLOW
```

4. **Verify domain resolves:**
```bash
nslookup yourdomain.duckdns.org
# Should return your public IP
```

## Service-Specific Issues

### Gluetun VPN Not Connecting

**Symptom:** Gluetun shows connection errors

**Solutions:**
```bash
# Check credentials in .env
cat ~/EZ-Homelab/.env | grep SURFSHARK

# Check Gluetun logs
sudo docker logs gluetun

# Common fixes:
# 1. Wrong server region
# 2. Invalid credentials
# 3. WireGuard not supported by provider
```

### Pi-hole DNS Not Working

**Symptom:** Devices can't resolve DNS through Pi-hole

**Solutions:**
```bash
# Check Pi-hole is running
sudo docker ps | grep pihole

# Verify port 53 is available
sudo lsof -i :53

# If systemd-resolved is conflicting:
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
```

### Dockge Shows Empty

**Symptom:** No stacks visible in Dockge

**Cause:** Stacks not copied to /opt/stacks/

**Solution:**
```bash
# Check what exists
ls -la /opt/stacks/

# Re-run deployment to copy stacks
sudo ./scripts/deploy-homelab.sh
```

## Performance Issues

### Slow Container Start Times

**Causes:**
- First-time image pulls
- Slow disk (not using SSD/NVMe)
- Insufficient RAM

**Solutions:**
```bash
# Pre-pull images
cd /opt/stacks/stack-name/
docker compose pull

# Check disk performance
sudo hdparm -Tt /dev/sda  # Replace with your disk

# Check RAM usage
free -h

# Move /opt/stacks to faster disk if needed
```

### High CPU Usage from Authelia

**Normal:** Argon2 password hashing is intentionally CPU-intensive for security

**If persistent:**
```bash
# Check what's causing load
sudo docker stats

# If Authelia constantly high:
sudo docker logs authelia
# Look for repeated authentication attempts (possible attack)
```

## Reset and Recovery

### Complete Reset (Testing Only)

**Warning:** This is destructive!

```bash
# Use the safe reset script
sudo ./scripts/reset-test-environment.sh

# Then re-run setup and deploy
sudo ./scripts/setup-homelab.sh
sudo ./scripts/deploy-homelab.sh
```

### Partial Reset (Single Stack)

```bash
# Stop and remove specific stack
cd /opt/stacks/stack-name/
docker compose down -v  # -v removes volumes (data loss!)

# Redeploy
docker compose up -d
```

### Backup Before Reset

```bash
# Backup important data
sudo tar czf ~/homelab-backup-$(date +%Y%m%d).tar.gz /opt/stacks/

# Backup specific volumes
docker run --rm \
  -v stack_volume:/data \
  -v $(pwd):/backup \
  busybox tar czf /backup/volume-backup.tar.gz /data
```

## Getting Help

1. **Check container logs:**
   ```bash
   sudo docker logs container-name
   sudo docker logs -f container-name  # Follow logs
   ```

2. **Use Dozzle for real-time logs:**
   Access at https://dozzle.yourdomain.duckdns.org

3. **Check the AI assistant:**
   Ask Copilot in VS Code for specific issues

4. **Verify configuration:**
   ```bash
   # Check .env file
   cat ~/EZ-Homelab/.env
   
   # Check compose file
   cat /opt/stacks/stack-name/docker-compose.yml
   ```

5. **Docker system info:**
   ```bash
   docker info
   docker version
   docker system df  # Disk usage
   ```
