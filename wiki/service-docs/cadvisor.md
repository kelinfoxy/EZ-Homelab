# cAdvisor - Container Metrics

## Table of Contents
- [Overview](#overview)
- [What is cAdvisor?](#what-is-cadvisor)
- [Why Use cAdvisor?](#why-use-cadvisor)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Container Metrics  
**Docker Image:** [gcr.io/cadvisor/cadvisor](https://gcr.io/cadvisor/cadvisor)  
**Default Stack:** `monitoring.yml`  
**Web UI:** `http://SERVER_IP:8080`  
**Purpose:** Export container metrics  
**Ports:** 8080

## What is cAdvisor?

cAdvisor (Container Advisor) analyzes and exposes resource usage and performance metrics from running containers. Created by Google, it provides detailed metrics for each container including CPU, memory, network, and filesystem usage. Essential for Docker monitoring.

### Key Features
- **Per-Container Metrics:** Individual container stats
- **Resource Usage:** CPU, memory, network, disk
- **Historical Data:** Resource usage over time
- **Web UI:** Built-in dashboard
- **Prometheus Export:** Metrics endpoint
- **Auto-Discovery:** Finds all containers
- **Real-Time:** Live metrics
- **Free & Open Source:** Google project

## Why Use cAdvisor?

1. **Container Visibility:** See what each container uses
2. **Resource Tracking:** CPU, memory, I/O per container
3. **Prometheus Integration:** Standard exporter
4. **Google Standard:** Industry trusted
5. **Auto-Discovery:** No configuration needed
6. **Web UI:** Built-in visualization

## Configuration in AI-Homelab

```
No configuration files needed. cAdvisor auto-discovers containers.
```

## Official Resources

- **GitHub:** https://github.com/google/cadvisor
- **Documentation:** https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md

## Docker Configuration

```yaml
cadvisor:
  image: gcr.io/cadvisor/cadvisor:latest
  container_name: cadvisor
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8080:8080"
  privileged: true
  devices:
    - /dev/kmsg
  volumes:
    - /:/rootfs:ro
    - /var/run:/var/run:ro
    - /sys:/sys:ro
    - /var/lib/docker:/var/lib/docker:ro
    - /dev/disk:/dev/disk:ro
```

**Note:** Requires `privileged: true` and many volume mounts to access container metrics.

## Metrics Available

### CPU
- `container_cpu_usage_seconds_total` - CPU usage per container
- `container_cpu_system_seconds_total` - System CPU usage
- `container_cpu_user_seconds_total` - User CPU usage

### Memory
- `container_memory_usage_bytes` - Memory usage
- `container_memory_working_set_bytes` - Working set
- `container_memory_rss` - Resident set size
- `container_memory_cache` - Page cache
- `container_memory_swap` - Swap usage

### Network
- `container_network_receive_bytes_total` - Bytes received
- `container_network_transmit_bytes_total` - Bytes transmitted
- `container_network_receive_errors_total` - Receive errors
- `container_network_transmit_errors_total` - Transmit errors

### Filesystem
- `container_fs_usage_bytes` - Filesystem usage
- `container_fs_reads_bytes_total` - Bytes read
- `container_fs_writes_bytes_total` - Bytes written

## Summary

cAdvisor provides container metrics offering:
- Per-container resource usage
- CPU, memory, network, disk metrics
- Auto-discovery of containers
- Web UI dashboard
- Prometheus export
- Real-time monitoring
- Free and open-source

**Perfect for:**
- Docker container monitoring
- Resource usage tracking
- Performance analysis
- Identifying resource hogs
- Capacity planning

**Key Points:**
- Google's container advisor
- Auto-discovers all containers
- Built-in web UI
- Prometheus integration
- Requires privileged mode
- Port 8080 for UI and metrics
- Grafana dashboard 14282

**Remember:**
- Add to Prometheus config
- Import Grafana dashboard
- Privileged mode required
- Many volume mounts needed
- Web UI at :8080
- Low overhead

cAdvisor monitors all your containers!
