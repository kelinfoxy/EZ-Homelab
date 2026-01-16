# AI-Homelab Resource Limits Template
# Modern deploy.resources configuration for Docker Compose
# Based on researched typical usage patterns for homelab services
# These are conservative defaults - monitor and adjust as needed

# ===========================================
# SERVICE TYPE TEMPLATES
# ===========================================

# LIGHTWEIGHT SERVICES (Reverse proxy, auth, DNS, monitoring)
lightweight_service:
  deploy:
    resources:
      limits:
        cpus: '0.25'      # 25% of 1 CPU core
        memory: 128M      # 128MB RAM
        pids: 256         # Max processes
      reservations:
        cpus: '0.10'      # Reserve 10% of 1 CPU
        memory: 64M       # Reserve 64MB RAM

# STANDARD WEB SERVICES (Dashboards, simple web apps)
web_service:
  deploy:
    resources:
      limits:
        cpus: '0.50'      # 50% of 1 CPU core
        memory: 256M      # 256MB RAM
        pids: 512         # Max processes
      reservations:
        cpus: '0.25'      # Reserve 25% of 1 CPU
        memory: 128M      # Reserve 128MB RAM

# DATABASE SERVICES (PostgreSQL, MariaDB, Redis)
database_service:
  deploy:
    resources:
      limits:
        cpus: '1.0'       # 1 CPU core
        memory: 1G        # 1GB RAM (for caching)
        pids: 1024        # Max processes
      reservations:
        cpus: '0.50'      # Reserve 0.5 CPU
        memory: 512M      # Reserve 512MB RAM

# MEDIA SERVERS (Jellyfin, Plex - without GPU)
media_server:
  deploy:
    resources:
      limits:
        cpus: '2.0'       # 2 CPU cores (for transcoding)
        memory: 2G        # 2GB RAM
        pids: 2048        # Max processes
      reservations:
        cpus: '1.0'       # Reserve 1 CPU
        memory: 1G        # Reserve 1GB RAM

# DOWNLOADERS (qBittorrent, Transmission)
downloader_service:
  deploy:
    resources:
      limits:
        cpus: '1.0'       # 1 CPU core
        memory: 512M      # 512MB RAM
        pids: 1024        # Max processes
      reservations:
        cpus: '0.50'      # Reserve 0.5 CPU
        memory: 256M      # Reserve 256MB RAM

# HEAVY APPLICATIONS (Nextcloud, Gitea with users)
heavy_app:
  deploy:
    resources:
      limits:
        cpus: '1.5'       # 1.5 CPU cores
        memory: 1G        # 1GB RAM
        pids: 2048        # Max processes
      reservations:
        cpus: '0.75'      # Reserve 0.75 CPU
        memory: 512M      # Reserve 512MB RAM

# MONITORING STACK (Prometheus, Grafana, Loki)
monitoring_service:
  deploy:
    resources:
      limits:
        cpus: '0.75'      # 0.75 CPU cores
        memory: 512M      # 512MB RAM
        pids: 1024        # Max processes
      reservations:
        cpus: '0.25'      # Reserve 0.25 CPU
        memory: 256M      # Reserve 256MB RAM

# ===========================================
# SPECIFIC SERVICE RECOMMENDATIONS
# ===========================================

# Core Infrastructure Stack
traefik:           # Reverse proxy - handles SSL/TLS/crypto
  template: lightweight_service
  notes: "CPU intensive for SSL handshakes, low memory usage"

authelia:         # Authentication service
  template: lightweight_service
  notes: "Very low resource usage, mostly memory for sessions"

duckdns:          # DNS updater
  template: lightweight_service
  notes: "Minimal resources, mostly network I/O"

# Infrastructure Stack
pihole:           # DNS ad blocker
  template: lightweight_service
  notes: "Memory intensive for blocklists, low CPU"

dockge:           # Docker management UI
  template: web_service
  notes: "Light web interface, occasional CPU spikes"

glances:          # System monitoring
  template: web_service
  notes: "Low resource monitoring tool"

# Dashboard Stack
homepage:         # Status dashboard
  template: web_service
  notes: "Static content, very light"

homarr:           # Dashboard with widgets
  template: web_service
  notes: "JavaScript heavy but still light"

# Media Stack
jellyfin:         # Media server
  template: media_server
  notes: "CPU intensive for transcoding, high memory for caching"

calibre_web:      # Ebook manager
  template: web_service
  notes: "Light web app with database"

# Downloaders Stack
qbittorrent:      # Torrent client
  template: downloader_service
  notes: "Network I/O heavy, moderate CPU for hashing"

# Home Assistant Stack
home_assistant:   # Smart home hub
  template: heavy_app
  notes: "Python app with many integrations, moderate resources"

esphome:          # IoT firmware
  template: web_service
  notes: "Web interface for device management"

nodered:          # Automation workflows
  template: web_service
  notes: "Node.js app, moderate memory usage"

# Productivity Stack
nextcloud:        # File sync/sharing
  template: heavy_app
  notes: "PHP app with database, resource intensive with users"

gitea:            # Git server
  template: web_service
  notes: "Go app, lightweight but scales with repos"

# Monitoring Stack
prometheus:       # Metrics collection
  template: monitoring_service
  notes: "Time-series database, memory intensive for retention"

grafana:          # Metrics visualization
  template: web_service
  notes: "Web dashboard, moderate resources"

loki:             # Log aggregation
  template: monitoring_service
  notes: "Log storage, memory for indexing"

uptime_kuma:      # Uptime monitoring
  template: web_service
  notes: "Monitoring checks, light resource usage"

# Development Stack
code_server:     # VS Code in browser
  template: heavy_app
  notes: "Full IDE, resource intensive for large projects"

# Utility Stack
# Most utilities are lightweight web services
speedtest_tracker:
  template: web_service
  notes: "Speed test monitoring, occasional CPU usage"

# ===========================================
# RESOURCE MONITORING COMMANDS
# ===========================================

# Monitor current usage
docker stats

# Monitor specific service
docker stats service_name

# Check container resource usage over time
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Check system resources
docker system df

# View running processes in container
docker exec service_name ps aux

# Memory usage details
docker exec service_name cat /proc/meminfo | head -10

# ===========================================
# ADJUSTMENT GUIDELINES
# ===========================================

# If container is killed by OOM:
# 1. Increase memory limit by 50-100%
# 2. Check for memory leaks in application
# 3. Consider adding swap space to host

# If container is slow/unresponsive:
# 1. Increase CPU limits
# 2. Check for CPU bottlenecks
# 3. Monitor disk I/O if database-related

# General rule of thumb:
# - Start with conservative limits
# - Monitor actual usage with 'docker stats'
# - Adjust based on real-world usage patterns
# - Leave 20-30% headroom for spikes</content>
<parameter name="filePath">/home/kelin/AI-Homelab/docs/resource-limits-template.md