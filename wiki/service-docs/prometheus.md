# Prometheus - Metrics Database

## Table of Contents
- [Overview](#overview)
- [What is Prometheus?](#what-is-prometheus)
- [Why Use Prometheus?](#why-use-prometheus)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Setup](#setup)

## Overview

**Category:** Monitoring & Metrics  
**Docker Image:** [prom/prometheus](https://hub.docker.com/r/prom/prometheus)  
**Default Stack:** `monitoring.yml`  
**Web UI:** `http://SERVER_IP:9090`  
**Query Language:** PromQL  
**Ports:** 9090

## What is Prometheus?

Prometheus is an open-source monitoring system with a time-series database. It scrapes metrics from configured targets at intervals, stores them, and allows powerful querying. Combined with Grafana for visualization, it's the industry standard for infrastructure monitoring.

### Key Features
- **Time-Series DB:** Store metrics over time
- **Pull Model:** Scrapes targets
- **PromQL:** Powerful query language
- **Service Discovery:** Auto-discover targets
- **Alerting:** Alert on conditions
- **Exporters:** Monitor anything
- **Highly Scalable:** Production-grade
- **Free & Open Source:** CNCF project

## Why Use Prometheus?

1. **Industry Standard:** Used by Google, etc.
2. **Powerful Queries:** PromQL flexibility
3. **Exporters:** Monitor everything
4. **Grafana Integration:** Beautiful graphs
5. **Alerting:** Prometheus Alertmanager
6. **Reliable:** Battle-tested
7. **Active Development:** CNCF project

## Configuration in AI-Homelab

```
/opt/stacks/monitoring/prometheus/
  prometheus.yml      # Configuration
  data/              # Time-series data
  rules/             # Alert rules
```

### prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'docker'
    static_configs:
      - targets: ['docker-proxy:2375']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

## Official Resources

- **Website:** https://prometheus.io
- **Documentation:** https://prometheus.io/docs
- **PromQL:** https://prometheus.io/docs/prometheus/latest/querying/basics
- **Exporters:** https://prometheus.io/docs/instrumenting/exporters

## Educational Resources

### YouTube Videos
1. **TechWorld with Nana - Prometheus Monitoring**
   - https://www.youtube.com/watch?v=h4Sl21AKiDg
   - Complete Prometheus tutorial
   - PromQL queries explained
   - Grafana integration

2. **Techno Tim - Prometheus & Grafana**
   - https://www.youtube.com/watch?v=9TJx7QTrTyo
   - Docker setup
   - Exporters configuration
   - Dashboard creation

### Articles
1. **Prometheus Best Practices:** https://prometheus.io/docs/practices/naming
2. **PromQL Guide:** https://timber.io/blog/promql-for-humans

## Docker Configuration

```yaml
prometheus:
  image: prom/prometheus:latest
  container_name: prometheus
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "9090:9090"
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
    - '--storage.tsdb.path=/prometheus'
    - '--storage.tsdb.retention.time=30d'
    - '--web.console.libraries=/usr/share/prometheus/console_libraries'
    - '--web.console.templates=/usr/share/prometheus/consoles'
  volumes:
    - /opt/stacks/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    - /opt/stacks/monitoring/prometheus/data:/prometheus
    - /opt/stacks/monitoring/prometheus/rules:/etc/prometheus/rules
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.prometheus.rule=Host(`prometheus.${DOMAIN}`)"
```

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d prometheus
   ```

2. **Access UI:** `http://SERVER_IP:9090`

3. **Check Targets:**
   - Status → Targets
   - Verify exporters are "UP"

4. **Test Query:**
   - Graph tab
   - Query: `up`
   - Shows which targets are up

5. **Example Queries:**
   ```promql
   # CPU usage per container
   rate(container_cpu_usage_seconds_total[5m])

   # Memory usage
   container_memory_usage_bytes

   # Disk I/O
   rate(node_disk_read_bytes_total[5m])

   # Network traffic
   rate(container_network_receive_bytes_total[5m])
   ```

## Summary

Prometheus is your metrics database offering:
- Time-series metric storage
- Powerful PromQL queries
- Exporter ecosystem
- Service discovery
- Alerting integration
- Grafana visualization
- Industry standard
- Free and open-source

**Perfect for:**
- Infrastructure monitoring
- Container metrics
- Application metrics
- Performance tracking
- Alerting
- Capacity planning

**Key Points:**
- Scrapes metrics from exporters
- Stores in time-series database
- PromQL for queries
- Integrates with Grafana
- Alertmanager for alerts
- 15s scrape interval default
- 30 day retention typical

**Remember:**
- Configure scrape targets
- Install exporters for data sources
- Use Grafana for visualization
- Set retention period
- Monitor disk space
- Learn PromQL basics
- Regular backups

Prometheus powers your monitoring infrastructure!
