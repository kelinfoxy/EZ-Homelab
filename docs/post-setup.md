# Post-Setup Next Steps

Congratulations! Your AI-powered homelab is now running. Here's what to do next.

## Access Your Services

### Single Server Deployment

- **Homepage**: `https://homepage.yourdomain.duckdns.org`
  - Great place to start exploring your services
  - After configuring your services, come back and add widgets with API keys (optional)
  - Or ask the AI to find the API keys and add the widgets

- **Dockge**: `https://dockge.yourdomain.duckdns.org`
  - Deploy & Manage the stacks & services
  - Your primary management interface

- **Authelia**: `https://auth.yourdomain.duckdns.org`
  - Configure 2FA for enhanced security (optional)

- **Traefik**: `https://traefik.yourdomain.duckdns.org`
  - View/Edit your routing rules
  - Tip: Let the AI manage the routing for you

- **VS Code**: `https://code.yourdomain.duckdns.org`
   - Install GitHub Copilot Chat extension
   - Open the EZ-Homelab repository
   - Use AI assistance for:
      - Adding new services
      - Configuring Traefik routing
      - Managing Docker stacks

### Multi-Server Deployment

If you deployed across multiple servers:

**Core Server Services** (accessed from anywhere):
- All services above (Homepage, Dockge, Authelia, Traefik, code-server)
- Access these through your domain: `service.yourdomain.duckdns.org`

**Remote Server Services** (accessed through core):
- Remote services automatically routed through core Traefik
- Example: `https://sonarr.yourdomain.duckdns.org` → Core → Remote Server
- SSO protection applied by core Authelia

**Direct Local Access** (on remote server network):
- Services also accessible via local IP: `http://192.168.1.100:8989`
- Useful for troubleshooting or local management
- No SSO protection on local access

**Management Tips:**
- Use core Dockge to manage all servers (if configured)
- Each server has its own local Traefik/Sablier for container management
- All services appear under unified domain through core routing

## Monitoring Services

- Use Dockge to easily view live container logs
- Configure Uptime Kuma to provide uptime tracking with dashboards
- Check Grafana for system metrics and monitoring

## Customize Your Homelab

### Add Custom Services

Tell the AI what service you want to install - give it a Docker-based GitHub repository or Docker Hub image. Use your imagination, the Copilot instructions are configured with best practices and a framework to add new services.

### Remove Unwanted Services

To remove a stack:
```bash
cd /opt/stacks/stack-name
docker compose down
cd ..
sudo rm -rf stack-name
```

To remove the volumes/resources for the stack:
```bash
# Stop stack and remove everything
cd /opt/stacks/stack-name
docker compose down -v --remove-orphans

# Remove unused Docker resources
docker system prune -a --volumes
```

## Set Up Backups

Your homelab includes comprehensive backup solutions. The default setup includes Backrest (Restic-based) for automated backups.

### Quick Backup Setup

1. **Access Backrest**: `https://backrest.yourdomain.duckdns.org`
2. **Configure repositories**: Add local or cloud storage destinations
3. **Set up schedules**: Configure automatic backup schedules
4. **Add backup jobs**: Create jobs for your important data

### What to Back Up

- **Configuration files**: `/opt/stacks/*/config/` directories
- **Databases**: Service-specific database volumes
- **User data**: Nextcloud files, Git repositories, etc.
- **Media libraries**: Movies, TV shows, music (if space allows)

### Backup Commands

```bash
# Manual backup of a volume
docker run --rm \
  -v source-volume:/data \
  -v /mnt/backups:/backup \
  busybox tar czf /backup/volume-backup-$(date +%Y%m%d).tar.gz /data

# List Backrest configurations
cd /opt/stacks/utilities/backrest
docker compose exec backrest restic snapshots

# Restore from backup
docker run --rm \
  -v target-volume:/data \
  -v /mnt/backups:/backup \
  busybox tar xzf /backup/volume-backup.tar.gz -C /
```

For detailed backup configuration, see the [Restic-BackRest-Backup-Guide.md](Restic-BackRest-Backup-Guide.md).

## Troubleshooting

### Script Issues
- **Permission denied**: Run with `sudo`
- **Docker not found**: Log out/in or run `newgrp docker`
- **Network conflicts**: Check existing networks with `docker network ls`

### Service Issues
- **Can't access services**: Check Traefik dashboard at `https://traefik.yourdomain.duckdns.org`
- **SSL certificate errors**: Wait 2-5 minutes for wildcard certificate to be obtained from Let's Encrypt
  - Check status: `python3 -c "import json; d=json.load(open('/opt/stacks/core/traefik/acme.json')); print(f'Certificates: {len(d[\"letsencrypt\"][\"Certificates\"])}')"`
  - View logs: `docker exec traefik tail -50 /var/log/traefik/traefik.log | grep certificate`
- **Authelia login fails**: Check user database configuration at `/opt/stacks/core/authelia/users_database.yml`
- **"Not secure" warnings**: Clear browser cache or wait for DNS propagation (up to 5 minutes)
- **Check logs**: Use Dozzle web interface at `https://dozzle.yourdomain.duckdns.org` or run `docker logs <container-name>`

### Common Fixes
```bash
# Restart Docker
sudo systemctl restart docker

# Check service logs
cd /opt/stacks/stack-name
docker compose logs -f

# Rebuild service
docker compose up -d --build service-name
```

## Next Steps

1. **Explore services** through Dockge
2. **Set up backups** with Backrest (default Restic-based solution)
3. **Set up monitoring** with Grafana/Prometheus
4. **Add external services** via Traefik proxying
5. **Use AI assistance** for custom configurations

Happy homelabbing! 🚀