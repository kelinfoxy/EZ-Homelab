# Grafana - Metrics Visualization

## Table of Contents
- [Overview](#overview)
- [What is Grafana?](#what-is-grafana)
- [Why Use Grafana?](#why-use-grafana)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Setup](#setup)

## Overview

**Category:** Monitoring Dashboards  
**Docker Image:** [grafana/grafana](https://hub.docker.com/r/grafana/grafana)  
**Default Stack:** `monitoring.yml`  
**Web UI:** `http://SERVER_IP:3001`  
**Default Login:** admin/admin  
**Ports:** 3001

## What is Grafana?

Grafana is the leading open-source platform for monitoring and observability. It visualizes data from Prometheus, InfluxDB, Elasticsearch, and 80+ other data sources with beautiful, interactive dashboards. The standard for turning metrics into insights.

### Key Features
- **Beautiful Dashboards:** Stunning visualizations
- **80+ Data Sources:** Prometheus, InfluxDB, MySQL, etc.
- **Alerting:** Visual alert rules
- **Variables:** Dynamic dashboards
- **Annotations:** Mark events
- **Sharing:** Share dashboards/panels
- **Plugins:** Extend functionality
- **Templating:** Reusable dashboards
- **Community Dashboards:** 10,000+ ready-made
- **Free & Open Source:** No limits

## Why Use Grafana?

1. **Industry Standard:** Used everywhere
2. **Beautiful:** Best-in-class visualizations
3. **Flexible:** 80+ data sources
4. **Easy:** Pre-made dashboards
5. **Powerful:** Advanced queries
6. **Alerting:** Visual alert builder
7. **Community:** Huge dashboard library
8. **Free:** All features included

## Configuration in AI-Homelab

```
/opt/stacks/monitoring/grafana/data/
  grafana.db          # Configuration database
  dashboards/         # Dashboard JSON
  plugins/            # Installed plugins
```

## Official Resources

- **Website:** https://grafana.com
- **Documentation:** https://grafana.com/docs/grafana/latest
- **Dashboards:** https://grafana.com/grafana/dashboards
- **Tutorials:** https://grafana.com/tutorials

## Educational Resources

### YouTube Videos
1. **Techno Tim - Prometheus & Grafana**
   - https://www.youtube.com/watch?v=9TJx7QTrTyo
   - Complete setup guide
   - Dashboard creation
   - Alerting configuration

2. **TechWorld with Nana - Grafana Tutorial**
   - https://www.youtube.com/watch?v=QDQmY1iFvSU
   - Dashboard building
   - Variables and templating
   - Best practices

3. **Christian Lempa - Grafana Basics**
   - https://www.youtube.com/watch?v=bXZeTpFGw94
   - Getting started
   - Data source configuration
   - Panel types

### Popular Dashboards
1. **Node Exporter Full:** https://grafana.com/grafana/dashboards/1860 (ID: 1860)
2. **Docker Container & Host Metrics:** https://grafana.com/grafana/dashboards/179 (ID: 179)
3. **cAdvisor:** https://grafana.com/grafana/dashboards/14282 (ID: 14282)

## Docker Configuration

```yaml
grafana:
  image: grafana/grafana:latest
  container_name: grafana
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "3001:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel
    - GF_SERVER_ROOT_URL=https://grafana.${DOMAIN}
  volumes:
    - /opt/stacks/monitoring/grafana/data:/var/lib/grafana
  user: "472"  # grafana user
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.grafana.rule=Host(`grafana.${DOMAIN}`)"
```

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d grafana
   ```

2. **Access UI:** `http://SERVER_IP:3001`

3. **First Login:**
   - Username: `admin`
   - Password: `admin`
   - Set new password

4. **Add Prometheus Data Source:**
   - Configuration (gear) → Data Sources → Add
   - Type: Prometheus
   - URL: `http://prometheus:9090`
   - Save & Test

5. **Import Dashboard:**
   - Dashboards (squares) → Import
   - Enter dashboard ID (e.g., 1860)
   - Select Prometheus data source
   - Import

6. **Popular Dashboard IDs:**
   - **1860:** Node Exporter Full
   - **179:** Docker Container Metrics
   - **14282:** cAdvisor
   - **11074:** Node Exporter for Prometheus
   - **893:** Docker Metrics

7. **Create Custom Dashboard:**
   - Dashboards → New Dashboard
   - Add Panel
   - Select visualization
   - Write PromQL query
   - Configure panel options
   - Save dashboard

## Summary

Grafana is your visualization platform offering:
- Beautiful metric dashboards
- 80+ data source types
- 10,000+ community dashboards
- Visual alert builder
- Dashboard templating
- Team collaboration
- Plugin ecosystem
- Free and open-source

**Perfect for:**
- Prometheus visualization
- Infrastructure monitoring
- Application metrics
- Business analytics
- IoT data
- Log analysis
- Performance dashboards

**Key Points:**
- Change default password!
- Import community dashboards
- Prometheus common data source
- Dashboard ID for quick import
- Variables make dashboards dynamic
- Alerting built-in
- Share dashboards easily

**Remember:**
- Default: admin/admin
- Change password immediately
- Add Prometheus as data source
- Use community dashboards (save time)
- Learn PromQL for custom queries
- Set refresh intervals
- Export dashboards as JSON backup

Grafana turns metrics into beautiful insights!
