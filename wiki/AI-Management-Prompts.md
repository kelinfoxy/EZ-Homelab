# AI Management Prompts

This guide provides example prompts you can use with GitHub Copilot to manage your homelab. These prompts leverage the AI assistant's knowledge of your infrastructure to perform common tasks.

## Container and Stack Management

### Controling Services
- "Start/Pause/Stop/Restart the media stack"
- "Start/Pause/Stop/Restart wordpress"
- "Deploy the monitoring stack"
- "Bring up the core infrastructure"


### Restarting a service vs restarting a stack

Restarting a container (service) does NOT pick up changes to the compose file

Restarting a stack uses docker compose down && docker compose up -d  
This DOES load changes to the compose file

Restart traefik/sablier container(s) to apply configuration changes  
Restart the core stack to apply changes to the compose file  

Homepage configuration is loaded on demand, no restart needed

### Status Checks

>If your server keeps locking up, it's likely stuck background processes.  
VS Code Copilot Chat in Agent mode sometimes leaves a stuck process running (in my experience)

- "Show me the status of all containers"
- "Check if the media services are running"
- "List all deployed stacks"
- "Monitor container resource usage"
- "Check for and close any stuck proccesses hogging system resources"

## Service Configuration

### Adding New Services
- "Add Plex to my media stack"
- "Install Nextcloud for file sharing"
- "Set up Grafana for monitoring"
- "Deploy Home Assistant for automation"

### Modifying Existing Services
- "Change the port for my Plex service"
- "Update the domain for Authelia"
- "Configure VPN routing for qBittorrent"
- "Add SSL certificate for new service"

### Network Configuration
- "Configure Traefik routing for my new service"
- "Set up Authelia protection for admin services"
- "Create external proxy for Raspberry Pi service"
- "Configure Sablier lazy loading"

## Troubleshooting

### Log Analysis
- "Check logs for the media stack"
- "Analyze errors in the monitoring services"
- "Review Traefik routing issues"
- "Examine Authelia authentication problems"

### Performance Issues
- "Monitor resource usage for containers"
- "Check for memory leaks in services"
- "Analyze network connectivity issues"
- "Review disk space usage"

### Configuration Problems
- "Validate Docker Compose syntax"
- "Check environment variable configuration"
- "Verify network connectivity between services"
- "Test SSL certificate validity"

### System Health Checks
- "Check for stuck processes consuming resources"
- "Monitor system load and identify bottlenecks"
- "Verify file permissions for Docker volumes"
- "Check Docker daemon status and logs"
- "Validate network connectivity and DNS resolution"
- "Review system resource limits and quotas"

### Stuck Process Investigation
- "Find and terminate any stuck AI assistant processes"
- "Check for runaway Docker containers"
- "Monitor background jobs and cleanup if needed"
- "Review system process table for anomalies"
- "Check VS Code extension processes that may be hanging"

### File Permission Issues
- "Fix permission problems with Docker volumes"
- "Set correct ownership for service configuration files"
- "Resolve access denied errors for mounted directories"
- "Validate PUID/PGID settings match system users"
- "Check and repair file system permissions recursively"

## Backup and Recovery

### Creating Backups
- "Set up backup for my media files"
- "Configure automated backups for databases"
- "Create backup strategy for configurations"
- "Schedule regular system backups"

### Restoring Services
- "Restore from backup after failure"
- "Recover deleted configuration files"
- "Rebuild corrupted database"
- "Restore service from snapshot"

## Monitoring and Maintenance

### System Monitoring
- "Set up Grafana dashboards"
- "Configure Prometheus metrics"
- "Create uptime monitoring"
- "Set up log aggregation"

### Updates and Upgrades
- "Update all containers to latest versions"
- "Upgrade specific service to new version"
- "Check for security updates"
- "Apply system patches"

## Security Management

### Access Control
- "Add new user to Authelia"
- "Configure two-factor authentication"
- "Set up access policies"
- "Manage user permissions"

### SSL and Certificates
- "Renew SSL certificates"
- "Configure wildcard certificates"
- "Set up custom domains"
- "Troubleshoot certificate issues"

## Scaling and Optimization

### Resource Management
- "Optimize container resource limits"
- "Configure GPU access for services"
- "Set up load balancing"
- "Scale services horizontally"

### Storage Management
- "Configure additional storage drives"
- "Set up network storage"
- "Optimize disk usage"
- "Configure backup storage"

## Custom Configurations

### Advanced Setup
- "Create multi-server deployment"
- "Configure external service proxying"
- "Set up VPN routing for downloads"
- "Configure custom networking"

### Integration Tasks
- "Connect services to external APIs"
- "Configure webhook integrations"
- "Set up automated workflows"
- "Create custom monitoring alerts"

## Getting Help

### Documentation
- "Show me the service documentation"
- "Explain how Traefik routing works"
- "Guide me through SSL setup"
- "Help me understand Docker networking"

### Best Practices
- "Review my configuration for security"
- "Optimize my setup for performance"
- "Suggest backup improvements"
- "Recommend monitoring enhancements"

## Prompt Tips

### Be Specific
- Include service names: "Configure Plex, not just media service"
- Specify actions: "Add user" vs "Manage users"
- Mention locations: "In the media stack" vs "Somewhere"

### Provide Context
- "I'm getting error X when doing Y"
- "Service Z isn't starting after configuration change"
- "I need to connect service A to service B"

### Use Natural Language
- "Make my homelab more secure"
- "Help me set up backups"
- "Fix my broken service"

### Follow Up
- "That didn't work, try a different approach"
- "Show me the logs for that service"
- "Explain what that configuration does"

Remember: The AI assistant has full knowledge of your homelab architecture and can perform complex tasks. Start with simple requests and build up to more complex operations as you become comfortable with the system.