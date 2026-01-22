# Glances - System Monitoring Dashboard

## Table of Contents
- [Overview](#overview)
- [What is Glances?](#what-is-glances)
- [Why Use Glances?](#why-use-glances)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Using Glances](#using-glances)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Infrastructure Monitoring  
**Docker Image:** [nicolargo/glances](https://hub.docker.com/r/nicolargo/glances)  
**Default Stack:** `infrastructure.yml`  
**Web UI:** `https://glances.${DOMAIN}`  
**Authentication:** Protected by Authelia (SSO)  
**Purpose:** Real-time system resource monitoring

## What is Glances?

Glances is a cross-platform system monitoring tool that provides a comprehensive overview of your system's resources. It displays CPU, memory, disk, network, and process information in a single interface, accessible via CLI, Web UI, or API.

### Key Features
- **Comprehensive Monitoring:** CPU, RAM, disk, network, sensors, processes
- **Real-Time Updates:** Live statistics updated every few seconds
- **Web Interface:** Beautiful responsive dashboard
- **REST API:** Export metrics for other tools
- **Docker Support:** Monitor containers and host system
- **Alerts:** Configurable thresholds for warnings
- **Historical Data:** Short-term data retention
- **Extensible:** Plugins for additional monitoring
- **Export Options:** InfluxDB, Prometheus, CSV, JSON
- **Lightweight:** Minimal resource usage
- **Cross-Platform:** Linux, macOS, Windows

## Why Use Glances?

1. **Quick Overview:** See system health at a glance
2. **Resource Monitoring:** Track CPU, RAM, disk usage
3. **Process Management:** Identify resource-heavy processes
4. **Container Monitoring:** Monitor Docker containers
5. **Network Analysis:** Track network bandwidth
6. **Temperature Monitoring:** Hardware sensor data
7. **Disk I/O:** Identify disk bottlenecks
8. **Easy Access:** Web interface from any device
9. **No Complex Setup:** Works out of the box
10. **Free & Open Source:** No licensing costs

## How It Works

```
Host System (CPU, RAM, Disk, Network)
     ↓
Glances Container (accesses host metrics via /proc, /sys)
     ↓
Data Collection & Processing
     ↓
┌─────────────┬──────────────┬────────────┐
│  Web UI     │  REST API    │  CLI       │
│  (Port 61208)│ (JSON/Export)│  (Terminal)│
└─────────────┴──────────────┴────────────┘
```

### Monitoring Architecture

**Host Access:**
- `/proc` - Process and system info
- `/sys` - Hardware information
- `/var/run/docker.sock` - Docker container stats
- `/etc/os-release` - System information

**Data Flow:**
1. **Collect:** Gather metrics from system files
2. **Process:** Calculate rates, averages, deltas
3. **Store:** Keep short-term history in memory
4. **Display:** Render in web UI or export
5. **Alert:** Check thresholds and warn if exceeded

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/infrastructure/glances/
└── config/
    └── glances.conf  # Optional configuration file
```

### Environment Variables

```bash
# Web server mode
GLANCES_OPT=-w

# Timezone
TZ=America/New_York

# Update interval (seconds)
# GLANCES_OPT=-w -t 2

# Disable web password (use Authelia)
# GLANCES_OPT=-w --disable-webui
```

## Official Resources

- **Website:** https://nicolargo.github.io/glances/
- **GitHub:** https://github.com/nicolargo/glances
- **Docker Hub:** https://hub.docker.com/r/nicolargo/glances
- **Documentation:** https://glances.readthedocs.io
- **Wiki:** https://github.com/nicolargo/glances/wiki

## Educational Resources

### Videos
- [Glances - System Monitoring Tool (Techno Tim)](https://www.youtube.com/watch?v=3dT1LEVhdJM)
- [Server Monitoring with Glances](https://www.youtube.com/results?search_query=glances+system+monitoring)
- [Linux System Monitoring Tools](https://www.youtube.com/watch?v=5JHwNjX6FKs)

### Articles & Guides
- [Glances Official Documentation](https://glances.readthedocs.io)
- [Glances Configuration Guide](https://glances.readthedocs.io/en/stable/config.html)
- [System Monitoring Best Practices](https://www.brendangregg.com/linuxperf.html)

### Concepts to Learn
- **/proc filesystem:** Linux process information
- **CPU Load Average:** 1, 5, and 15-minute averages
- **Memory Types:** RAM, swap, cache, buffers
- **Disk I/O:** Read/write operations per second
- **Network Metrics:** Bandwidth, packets, errors
- **Process States:** Running, sleeping, zombie
- **System Sensors:** Temperature, fan speeds, voltages

## Docker Configuration

### Complete Service Definition

```yaml
glances:
  image: nicolargo/glances:latest
  container_name: glances
  restart: unless-stopped
  pid: host  # Required for accurate process monitoring
  networks:
    - traefik-network
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - /etc/os-release:/etc/os-release:ro
    - /opt/stacks/infrastructure/glances/config:/glances/conf:ro
  environment:
    - GLANCES_OPT=-w
    - TZ=America/New_York
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.glances.rule=Host(`glances.${DOMAIN}`)"
    - "traefik.http.routers.glances.entrypoints=websecure"
    - "traefik.http.routers.glances.tls.certresolver=letsencrypt"
    - "traefik.http.routers.glances.middlewares=authelia@docker"
    - "traefik.http.services.glances.loadbalancer.server.port=61208"
```

### Important Mount Points

```yaml
volumes:
  # Docker container monitoring
  - /var/run/docker.sock:/var/run/docker.sock:ro
  
  # System information
  - /etc/os-release:/etc/os-release:ro
  
  # Host filesystem (optional, for disk monitoring)
  # - /:/rootfs:ro
  
  # Configuration file (optional)
  - /opt/stacks/infrastructure/glances/config:/glances/conf:ro
```

### Network Modes

**For better host monitoring, use host network:**
```yaml
glances:
  network_mode: host
  # Then access via: http://SERVER_IP:61208
  # Or still use Traefik but with host networking
```

## Using Glances

### Dashboard Overview

**Web Interface Sections:**

1. **Header:**
   - Hostname
   - System uptime
   - Linux distribution
   - Current time

2. **CPU:**
   - Overall CPU usage (%)
   - Per-core utilization
   - Load average (1, 5, 15 min)
   - Context switches

3. **Memory:**
   - Total RAM
   - Used/Free
   - Cache/Buffers
   - Swap usage

4. **Disk:**
   - Partition information
   - Space used/free
   - Mount points
   - Disk I/O rates

5. **Network:**
   - Interface names
   - Upload/Download rates
   - Total transferred
   - Errors and drops

6. **Sensors:**
   - CPU temperature
   - Fan speeds
   - Other hardware sensors

7. **Docker:**
   - Container list
   - Container CPU/Memory
   - Container I/O

8. **Processes:**
   - Top CPU/Memory processes
   - Process details
   - Sort options

### Color Coding

Glances uses colors to indicate resource usage:

- **Green:** OK (< 50%)
- **Blue:** Caution (50-70%)
- **Magenta:** Warning (70-90%)
- **Red:** Critical (> 90%)

### Sorting Options

Click on column headers to sort:
- **CPU:** CPU usage
- **MEM:** Memory usage
- **TIME:** Process runtime
- **NAME:** Process name
- **PID:** Process ID

### Keyboard Shortcuts (CLI Mode)

If accessing via terminal:
```
a - Sort by automatic (CPU + memory)
c - Sort by CPU
m - Sort by memory
p - Sort by process name
i - Sort by I/O rate
t - Sort by time (cumulative)
d - Show/hide disk I/O
f - Show/hide filesystem
n - Show/hide network
s - Show/hide sensors
k - Kill process
h - Show help
q - Quit
```

## Advanced Topics

### Configuration File

Create custom configuration for alerts and thresholds:

**glances.conf:**
```ini
[global]
refresh=2
check_update=false

[cpu]
# CPU thresholds (%)
careful=50
warning=70
critical=90

[memory]
# Memory thresholds (%)
careful=50
warning=70
critical=90

[load]
# Load average thresholds
careful=1.0
warning=2.0
critical=5.0

[diskio]
# Disk I/O hide regex
hide=loop.*,ram.*

[fs]
# Filesystem hide regex
hide=/boot.*,/snap.*

[network]
# Network interface hide regex
hide=lo,docker.*

[docker]
# Show all containers
all=true
# Max containers to display
max_name_size=20

[alert]
# Alert on high CPU
cpu_careful=50
cpu_warning=70
cpu_critical=90
```

Mount config:
```yaml
volumes:
  - /opt/stacks/infrastructure/glances/config/glances.conf:/glances/conf/glances.conf:ro
```

### Export to InfluxDB

Send metrics to InfluxDB for long-term storage:

**glances.conf:**
```ini
[influxdb]
host=influxdb
port=8086
protocol=http
user=glances
password=glances
db=glances
prefix=localhost
tags=environment:homelab
```

### Export to Prometheus

Make metrics available for Prometheus scraping:

```yaml
glances:
  environment:
    - GLANCES_OPT=-w --export prometheus
  ports:
    - "9091:9091"  # Prometheus exporter port
```

**Prometheus config:**
```yaml
scrape_configs:
  - job_name: 'glances'
    static_configs:
      - targets: ['glances:9091']
```

### REST API

Access metrics programmatically:

```bash
# Get all stats
curl http://glances:61208/api/3/all

# Get specific stat
curl http://glances:61208/api/3/cpu
curl http://glances:61208/api/3/mem
curl http://glances:61208/api/3/docker

# Get process list
curl http://glances:61208/api/3/processlist

# Full API documentation
curl http://glances:61208/docs
```

### Alerts and Actions

Configure alerts in glances.conf:

```ini
[alert]
disable=False

[process]
# Alert if process not running
list=sshd,nginx,docker
# Alert if process running
disable_pattern=.*badprocess.*

[action]
# Execute script on alert
critical_action=script:/scripts/alert.sh
```

### Multi-Server Monitoring

Monitor multiple servers:

**On each remote server:**
```yaml
glances:
  image: nicolargo/glances
  environment:
    - GLANCES_OPT=-s  # Server mode
  ports:
    - "61209:61209"
```

**On main server:**
```yaml
glances:
  environment:
    - GLANCES_OPT=-w --browser
    # Or use client mode to connect
```

Access via web UI: "Remote monitoring" section

### Custom Plugins

Create custom monitoring plugins:

```python
# /opt/stacks/infrastructure/glances/config/plugins/custom_plugin.py
from glances.plugins.glances_plugin import GlancesPlugin

class Plugin(GlancesPlugin):
    def update(self):
        # Your custom monitoring code
        stats = {}
        stats['custom_metric'] = get_custom_data()
        return stats
```

## Troubleshooting

### Glances Not Showing Host Metrics

```bash
# Verify host access
docker exec glances ls /proc
docker exec glances cat /proc/cpuinfo

# Check pid mode
docker inspect glances | grep -i pid

# Ensure proper mounts
docker inspect glances | grep -A10 Mounts

# Try host network mode
# In compose: network_mode: host
```

### Docker Containers Not Visible

```bash
# Verify Docker socket mount
docker exec glances ls -la /var/run/docker.sock

# Check permissions
docker exec glances docker ps

# Ensure docker section enabled in config
# Or no config file hiding it
```

### High CPU Usage from Glances

```bash
# Increase refresh interval
GLANCES_OPT=-w -t 5  # Update every 5 seconds

# Disable modules you don't need
# In glances.conf:
# disable=sensors,raid

# Check if something is hammering the API
docker logs traefik | grep glances
```

### Temperature Sensors Not Showing

```bash
# Need access to /sys
volumes:
  - /sys:/sys:ro

# Install lm-sensors on host
sudo apt install lm-sensors
sudo sensors-detect

# Verify sensors work on host
sensors
```

### Web Interface Not Loading

```bash
# Check if Glances is running
docker ps | grep glances

# View logs
docker logs glances

# Test direct access
curl http://SERVER_IP:61208

# Check Traefik routing
docker logs traefik | grep glances

# Verify web mode enabled
docker exec glances ps aux | grep glances
```

### Disk Information Incomplete

```bash
# Mount host root filesystem
volumes:
  - /:/rootfs:ro

# In glances.conf:
[fs]
hide=/rootfs/boot.*,/rootfs/snap.*
```

### Memory Information Incorrect

```bash
# Use host PID namespace
pid: host

# Check /proc/meminfo access
docker exec glances cat /proc/meminfo

# Restart container
docker restart glances
```

## Performance Optimization

### Reduce Update Frequency

```yaml
environment:
  - GLANCES_OPT=-w -t 5  # Update every 5 seconds (default is 2)
```

### Disable Unnecessary Modules

**glances.conf:**
```ini
[global]
# Disable modules you don't need
disable=raid,sensors,hddtemp
```

### Limit Process List

```ini
[processlist]
# Max number of processes to display
max=50
```

### Resource Limits

```yaml
glances:
  deploy:
    resources:
      limits:
        cpus: '0.5'
        memory: 256M
```

## Security Considerations

1. **Protect with Authelia:** Exposes sensitive system info
2. **Read-Only Mounts:** Use `:ro` for all mounted volumes
3. **Limited Socket Access:** Consider Docker Socket Proxy
4. **No Public Access:** Never expose without authentication
5. **API Security:** Restrict API access if enabled
6. **Process Info:** Can reveal application details
7. **Network Monitoring:** Shows internal network traffic
8. **Regular Updates:** Keep Glances container updated
9. **Audit Logs:** Monitor who accesses the interface
10. **Minimal Permissions:** Only mount what's necessary

## Integration with Other Tools

### Grafana Dashboard

Export to Prometheus, then visualize in Grafana:

1. **Enable Prometheus export** in Glances
2. **Add Prometheus datasource** in Grafana
3. **Import Glances dashboard:** https://grafana.com/grafana/dashboards/

### Home Assistant

Monitor via REST API:

```yaml
sensor:
  - platform: rest
    resource: http://glances:61208/api/3/cpu
    name: Server CPU
    value_template: '{{ value_json.total }}'
    unit_of_measurement: '%'
```

### Uptime Kuma

Monitor Glances availability:

- Type: HTTP(s)
- URL: https://glances.yourdomain.com
- Heartbeat: Every 60 seconds

## Comparison with Alternatives

### Glances vs htop/top

**Glances:**
- Web interface
- Historical data
- Docker monitoring
- Remote access
- Exportable metrics

**htop:**
- Terminal only
- No web interface
- Lower overhead
- More detailed process tree

### Glances vs Netdata

**Glances:**
- Simpler setup
- Lighter weight
- Better for single server
- Python-based

**Netdata:**
- More detailed metrics
- Better long-term storage
- Complex setup
- Better for multiple servers

### Glances vs Prometheus + Grafana

**Glances:**
- All-in-one solution
- Easier setup
- Less powerful
- Short-term data

**Prometheus + Grafana:**
- Enterprise-grade
- Long-term storage
- Complex setup
- Powerful querying

## Summary

Glances provides real-time system monitoring in a simple, accessible interface. It:
- Shows comprehensive system metrics at a glance
- Monitors Docker containers alongside host
- Provides web UI and REST API
- Uses minimal resources
- Requires minimal configuration
- Perfect for quick system health checks

**Best For:**
- Homelab monitoring
- Quick troubleshooting
- Resource usage overview
- Docker container monitoring
- Single-server setups

**Not Ideal For:**
- Long-term metric storage
- Complex alerting
- Multi-server enterprise monitoring
- Detailed performance analysis

**Remember:**
- Protect with Authelia
- Use host PID mode for accurate monitoring
- Mount Docker socket for container stats
- Configure thresholds for alerts
- Complement with Grafana for long-term analysis
- Lightweight alternative to complex monitoring stacks
