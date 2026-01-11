# Configuration Templates

This directory contains example configuration files for various services. These templates provide sensible defaults and are ready to use with minimal modifications.

## Usage

1. **Create your config directory** (if it doesn't exist):
   ```bash
   mkdir -p config/service-name
   ```

2. **Copy the template** to your config directory:
   ```bash
   cp config-templates/service-name/* config/service-name/
   ```

3. **Edit the configuration** as needed for your environment

4. **Start the service** using Docker Compose

## Available Templates

### Prometheus (`prometheus/prometheus.yml`)
Metrics collection and monitoring system configuration.

**Features:**
- Pre-configured to scrape Node Exporter and cAdvisor
- 15-second scrape interval
- Ready for additional service monitoring

**Setup:**
```bash
mkdir -p config/prometheus
cp config-templates/prometheus/prometheus.yml config/prometheus/
docker compose -f docker-compose/monitoring.yml up -d prometheus
```

### Loki (`loki/loki-config.yml`)
Log aggregation system configuration.

**Features:**
- Filesystem-based storage
- 30-day log retention
- Automatic log compaction
- Pre-configured for Promtail

**Setup:**
```bash
mkdir -p config/loki
cp config-templates/loki/loki-config.yml config/loki/
docker compose -f docker-compose/monitoring.yml up -d loki
```

### Promtail (`promtail/promtail-config.yml`)
Log shipper for Loki.

**Features:**
- Automatically ships Docker container logs
- Parses Docker JSON format
- Extracts container IDs and names
- Optional system log collection

**Setup:**
```bash
mkdir -p config/promtail
cp config-templates/promtail/promtail-config.yml config/promtail/
docker compose -f docker-compose/monitoring.yml up -d promtail
```

### Redis (`redis/redis.conf`)
In-memory data store configuration.

**Features:**
- Both AOF and RDB persistence enabled
- 256MB memory limit with LRU eviction
- Sensible defaults for homelab use
- Security options (password protection available)

**Setup:**
```bash
mkdir -p config/redis
cp config-templates/redis/redis.conf config/redis/
# Optional: Edit redis.conf to set a password
docker compose -f docker-compose/development.yml up -d redis
```

## Customization Tips

### Prometheus
- Add more scrape targets to monitor additional services
- Adjust `scrape_interval` based on your needs (lower = more frequent, more data)
- Configure alerting by uncommenting the alertmanager section

### Loki
- Adjust `retention_period` to keep logs longer or shorter
- Change storage from filesystem to S3 for better scalability
- Configure multiple tenants if needed

### Promtail
- Add more scrape configs for system logs, application logs, etc.
- Customize pipeline stages to extract more labels
- Filter logs based on patterns

### Redis
- Set `maxmemory` based on your available RAM
- Choose appropriate `maxmemory-policy` for your use case
- Enable password protection by uncommenting `requirepass`

## Service-Specific Notes

### Services That Don't Need Config Templates

Many services work perfectly with just environment variables and don't require separate config files:

- **Plex, Jellyfin**: Configure via web UI
- **Sonarr, Radarr, Prowlarr**: Configure via web UI
- **Portainer**: Configure via web UI
- **Grafana**: Can use provisioning or web UI
- **Most LinuxServer.io images**: Configured via environment variables

### Services That Benefit from Config Files

- **Prometheus**: Requires `prometheus.yml` for scrape configuration
- **Loki**: Requires config for storage and retention
- **Promtail**: Requires config for log sources
- **Redis**: Benefits from custom config for persistence and security
- **Nginx**: Needs config for proxy rules (use Nginx Proxy Manager UI instead)

## Best Practices

1. **Version Control**: Keep your config templates in git
2. **Secrets**: Never commit passwords or API keys
3. **Comments**: Add comments explaining custom settings
4. **Backups**: Backup config directories regularly
5. **Testing**: Test config changes in a separate environment first

## Creating New Templates

When creating templates for other services:

1. Start with the official documentation
2. Use sensible defaults for homelab use
3. Add comments explaining important settings
4. Include examples for common customizations
5. Test the template before committing

## Getting Help

- Check the official documentation for each service
- Ask GitHub Copilot in VS Code for configuration help
- Review the [Docker Guidelines](../docs/docker-guidelines.md)
- Consult service-specific community forums

## Example: Full Monitoring Stack Setup

```bash
# Create all config directories
mkdir -p config/{prometheus,loki,promtail,grafana}

# Copy templates
cp config-templates/prometheus/prometheus.yml config/prometheus/
cp config-templates/loki/loki-config.yml config/loki/
cp config-templates/promtail/promtail-config.yml config/promtail/

# Start the monitoring stack
docker compose -f docker-compose/monitoring.yml up -d

# Access services
# Prometheus: http://server-ip:9090
# Grafana: http://server-ip:3000
# Loki: http://server-ip:3100
```

## Troubleshooting

### Config file not found
Ensure you copied the template to the correct location referenced in the docker-compose file.

### Permission errors
Fix ownership:
```bash
sudo chown -R 1000:1000 config/service-name
```

### Syntax errors
Validate YAML files:
```bash
# For YAML files
python3 -c "import yaml; yaml.safe_load(open('config/service/config.yml'))"
```

### Service won't start
Check logs for configuration errors:
```bash
docker compose -f docker-compose/file.yml logs service-name
```
