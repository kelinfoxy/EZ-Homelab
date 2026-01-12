# Alertmanager - Alert Routing

## Table of Contents
- [Overview](#overview)
- [What is Alertmanager?](#what-is-alertmanager)
- [Why Use Alertmanager?](#why-use-alertmanager)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Alert Management  
**Docker Image:** [prom/alertmanager](https://hub.docker.com/r/prom/alertmanager)  
**Default Stack:** `monitoring.yml`  
**Web UI:** `http://SERVER_IP:9093`  
**Purpose:** Handle Prometheus alerts  
**Ports:** 9093

## What is Alertmanager?

Alertmanager handles alerts from Prometheus. It deduplicates, groups, and routes alerts to notification channels (email, Slack, PagerDuty, etc.). It also manages silencing and inhibition of alerts. The alerting component of the Prometheus ecosystem.

### Key Features
- **Alert Routing:** Send to right channels
- **Grouping:** Combine similar alerts
- **Deduplication:** No duplicate alerts
- **Silencing:** Mute alerts temporarily
- **Inhibition:** Suppress dependent alerts
- **Notifications:** Email, Slack, webhooks, etc.
- **Web UI:** Manage alerts visually
- **Free & Open Source:** Prometheus project

## Why Use Alertmanager?

1. **Prometheus Native:** Designed for Prometheus
2. **Smart Routing:** Alerts go where needed
3. **Deduplication:** No spam
4. **Grouping:** Related alerts together
5. **Silencing:** Maintenance mode
6. **Multi-Channel:** Email, Slack, etc.

## Configuration in AI-Homelab

```
/opt/stacks/monitoring/alertmanager/
  alertmanager.yml    # Configuration
  data/              # Alert state
```

### alertmanager.yml

```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'discord'

receivers:
  - name: 'discord'
    webhook_configs:
      - url: 'YOUR_DISCORD_WEBHOOK_URL'
        send_resolved: true

  - name: 'email'
    email_configs:
      - to: 'alerts@yourdomain.com'
        from: 'alertmanager@yourdomain.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your@gmail.com'
        auth_password: 'app_password'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
```

## Official Resources

- **Website:** https://prometheus.io/docs/alerting/latest/alertmanager
- **Configuration:** https://prometheus.io/docs/alerting/latest/configuration

## Docker Configuration

```yaml
alertmanager:
  image: prom/alertmanager:latest
  container_name: alertmanager
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "9093:9093"
  command:
    - '--config.file=/etc/alertmanager/alertmanager.yml'
    - '--storage.path=/alertmanager'
  volumes:
    - /opt/stacks/monitoring/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
    - /opt/stacks/monitoring/alertmanager/data:/alertmanager
```

## Setup

1. **Configure Prometheus:**
   Add to prometheus.yml:
   ```yaml
   alerting:
     alertmanagers:
       - static_configs:
           - targets: ['alertmanager:9093']

   rule_files:
     - '/etc/prometheus/rules/*.yml'
   ```

2. **Create Alert Rules:**
   `/opt/stacks/monitoring/prometheus/rules/alerts.yml`:
   ```yaml
   groups:
     - name: example
       rules:
         - alert: InstanceDown
           expr: up == 0
           for: 5m
           labels:
             severity: critical
           annotations:
             summary: "Instance {{ $labels.instance }} down"
             description: "{{ $labels.instance }} has been down for more than 5 minutes."

         - alert: HighCPU
           expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
           for: 5m
           labels:
             severity: warning
           annotations:
             summary: "High CPU usage on {{ $labels.instance }}"
             description: "CPU usage is above 80% for more than 5 minutes."

         - alert: HighMemory
           expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
           for: 5m
           labels:
             severity: warning
           annotations:
             summary: "High memory usage on {{ $labels.instance }}"
             description: "Memory usage is above 90%."

         - alert: DiskSpaceLow
           expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
           for: 5m
           labels:
             severity: critical
           annotations:
             summary: "Low disk space on {{ $labels.instance }}"
             description: "Disk space is below 10%."
   ```

3. **Restart Prometheus:**
   ```bash
   docker restart prometheus
   ```

4. **Access Alertmanager UI:** `http://SERVER_IP:9093`

## Summary

Alertmanager routes alerts from Prometheus offering:
- Alert deduplication
- Grouping and routing
- Multiple notification channels
- Silencing and inhibition
- Web UI management
- Free and open-source

**Perfect for:**
- Prometheus alert handling
- Multi-channel notifications
- Alert management
- Maintenance silencing
- Alert grouping

**Key Points:**
- Receives alerts from Prometheus
- Routes to notification channels
- Deduplicates and groups
- Supports silencing
- Web UI for management
- Configure in alertmanager.yml
- Define rules in Prometheus

**Remember:**
- Configure receivers (Discord, Email, etc.)
- Create alert rules in Prometheus
- Test alerts work
- Use silencing for maintenance
- Group related alerts
- Set appropriate thresholds
- Monitor alertmanager itself

Alertmanager manages your alerts intelligently!
