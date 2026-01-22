# Promtail - Log Shipper

## Table of Contents
- [Overview](#overview)
- [What is Promtail?](#what-is-promtail)
- [Why Use Promtail?](#why-use-promtail)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Log Shipping  
**Docker Image:** [grafana/promtail](https://hub.docker.com/r/grafana/promtail)  
**Default Stack:** `monitoring.yml`  
**Purpose:** Ship logs to Loki  
**Ports:** 9080

## What is Promtail?

Promtail is the log shipping agent for Loki. It discovers log files, reads them, parses labels, and ships them to Loki. Think of it as the Filebeat/Fluentd equivalent for Loki.

### Key Features
- **Log Discovery:** Auto-find log files
- **Label Extraction:** Parse labels from logs
- **Tailing:** Follow log files
- **Position Tracking:** Don't lose logs
- **Multi-Tenant:** Send to multiple Loki instances
- **Docker Integration:** Scrape container logs
- **Pipeline Processing:** Transform logs
- **Free & Open Source:** CNCF project

## Why Use Promtail?

1. **Loki Native:** Designed for Loki
2. **Docker Aware:** Scrape container logs
3. **Label Extraction:** Smart parsing
4. **Reliable:** Position tracking
5. **Efficient:** Minimal overhead
6. **Simple:** Easy configuration

## Configuration in AI-Homelab

```
/opt/stacks/monitoring/promtail/
  promtail-config.yml    # Configuration
  positions.yaml         # Log positions
```

## Official Resources

- **Website:** https://grafana.com/docs/loki/latest/clients/promtail
- **Documentation:** https://grafana.com/docs/loki/latest/clients/promtail

## Docker Configuration

```yaml
promtail:
  image: grafana/promtail:latest
  container_name: promtail
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "9080:9080"
  command: -config.file=/etc/promtail/promtail-config.yml
  volumes:
    - /opt/stacks/monitoring/promtail/promtail-config.yml:/etc/promtail/promtail-config.yml
    - /var/lib/docker/containers:/var/lib/docker/containers:ro
    - /var/run/docker.sock:/var/run/docker.sock:ro
    - /opt/stacks/monitoring/promtail/positions.yaml:/positions.yaml
```

### promtail-config.yml

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'stream'
    pipeline_stages:
      - docker: {}
```

## Summary

Promtail ships logs to Loki offering:
- Docker container log collection
- Label extraction
- Position tracking
- Pipeline processing
- Loki integration
- Free and open-source

**Perfect for:**
- Sending Docker logs to Loki
- System log shipping
- Application log forwarding
- Centralized log collection

**Key Points:**
- Ships logs to Loki
- Scrapes Docker containers
- Tracks log positions
- Extracts labels
- Minimal resource usage
- Loki's preferred agent

**Remember:**
- Mount Docker socket
- Configure Loki URL
- Labels parsed from containers
- Position file prevents duplicates
- Low overhead
- Works seamlessly with Loki

Promtail sends logs to Loki!
