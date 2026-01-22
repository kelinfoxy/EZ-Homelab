# Node Exporter - System Metrics

## Table of Contents
- [Overview](#overview)
- [What is Node Exporter?](#what-is-node-exporter)
- [Why Use Node Exporter?](#why-use-node-exporter)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Metrics Exporter  
**Docker Image:** [prom/node-exporter](https://hub.docker.com/r/prom/node-exporter)  
**Default Stack:** `monitoring.yml`  
**Purpose:** Export host system metrics  
**Ports:** 9100

## What is Node Exporter?

Node Exporter is a Prometheus exporter for hardware and OS metrics. It exposes CPU, memory, disk, network, and dozens of other system metrics in Prometheus format. Essential for monitoring your server health.

### Key Features
- **Hardware Metrics:** CPU, memory, disk, network
- **OS Metrics:** Load, uptime, processes
- **Filesystem:** Disk usage, I/O
- **Network:** Traffic, errors, connections
- **Temperature:** CPU/disk temps (if available)
- **Lightweight:** Minimal overhead
- **Standard:** Official Prometheus exporter

## Why Use Node Exporter?

1. **Essential:** Core system monitoring
2. **Comprehensive:** 100+ metrics
3. **Standard:** Official Prometheus exporter
4. **Lightweight:** Low resource usage
5. **Reliable:** Battle-tested
6. **Grafana Dashboards:** Many pre-made

## Configuration in AI-Homelab

```
Node Exporter runs on host network mode to access system metrics.
```

## Official Resources

- **GitHub:** https://github.com/prometheus/node_exporter
- **Metrics:** https://github.com/prometheus/node_exporter#enabled-by-default

## Docker Configuration

```yaml
node-exporter:
  image: prom/node-exporter:latest
  container_name: node-exporter
  restart: unless-stopped
  network_mode: host
  pid: host
  command:
    - '--path.procfs=/host/proc'
    - '--path.sysfs=/host/sys'
    - '--path.rootfs=/host'
    - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
  volumes:
    - /proc:/host/proc:ro
    - /sys:/host/sys:ro
    - /:/host:ro,rslave
```

**Note:** Uses `network_mode: host` to access system metrics directly.

## Metrics Available

### CPU
- `node_cpu_seconds_total` - CPU time per mode
- `node_load1` - Load average (1 minute)
- `node_load5` - Load average (5 minutes)
- `node_load15` - Load average (15 minutes)

### Memory
- `node_memory_MemTotal_bytes` - Total memory
- `node_memory_MemFree_bytes` - Free memory
- `node_memory_MemAvailable_bytes` - Available memory
- `node_memory_Buffers_bytes` - Buffer cache
- `node_memory_Cached_bytes` - Page cache

### Disk
- `node_filesystem_size_bytes` - Filesystem size
- `node_filesystem_free_bytes` - Free space
- `node_filesystem_avail_bytes` - Available space
- `node_disk_read_bytes_total` - Bytes read
- `node_disk_written_bytes_total` - Bytes written

### Network
- `node_network_receive_bytes_total` - Bytes received
- `node_network_transmit_bytes_total` - Bytes transmitted
- `node_network_receive_errors_total` - Receive errors
- `node_network_transmit_errors_total` - Transmit errors

## Summary

Node Exporter provides system metrics offering:
- CPU usage and load
- Memory usage
- Disk space and I/O
- Network traffic
- System uptime
- 100+ other metrics
- Prometheus format
- Free and open-source

**Perfect for:**
- System health monitoring
- Resource usage tracking
- Capacity planning
- Performance analysis
- Server dashboards

**Key Points:**
- Official Prometheus exporter
- Runs on port 9100
- Host network mode
- Exports 100+ metrics
- Grafana dashboard 1860
- Very lightweight
- Essential for monitoring

**Remember:**
- Add to Prometheus scrape config
- Import Grafana dashboard 1860
- Monitor disk space
- Watch CPU and memory
- Network metrics valuable
- Low overhead

Node Exporter monitors your server health!
