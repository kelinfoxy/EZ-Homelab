# Loki - Log Aggregation

## Table of Contents
- [Overview](#overview)
- [What is Loki?](#what-is-loki)
- [Why Use Loki?](#why-use-loki)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Log Aggregation  
**Docker Image:** [grafana/loki](https://hub.docker.com/r/grafana/loki)  
**Default Stack:** `monitoring.yml`  
**Web UI:** Accessed via Grafana  
**Query Language:** LogQL  
**Ports:** 3100

## What is Loki?

Loki is a log aggregation system inspired by Prometheus but for logs. It doesn't index log contents (like Elasticsearch), instead it indexes metadata labels, making it much more efficient. Designed to work seamlessly with Grafana for log visualization.

### Key Features
- **Label-Based Indexing:** Efficient storage
- **Grafana Integration:** Native support
- **LogQL:** Prometheus-like queries
- **Multi-Tenancy:** Isolated logs
- **Compression:** Efficient storage
- **Low Resource:** Minimal overhead
- **Promtail Agent:** Log shipper
- **Free & Open Source:** CNCF project

## Why Use Loki?

1. **Efficient:** Indexes labels, not content
2. **Grafana Native:** Seamless integration
3. **Cheap:** Low storage costs
4. **Simple:** Easy to operate
5. **Prometheus-Like:** Familiar for Prometheus users
6. **Low Resource:** Lightweight
7. **LogQL:** Powerful queries

## Configuration in AI-Homelab

```
/opt/stacks/monitoring/loki/
  loki-config.yml     # Loki configuration
  data/              # Log storage
```

## Official Resources

- **Website:** https://grafana.com/oss/loki
- **Documentation:** https://grafana.com/docs/loki/latest
- **LogQL:** https://grafana.com/docs/loki/latest/logql

## Docker Configuration

```yaml
loki:
  image: grafana/loki:latest
  container_name: loki
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "3100:3100"
  command: -config.file=/etc/loki/loki-config.yml
  volumes:
    - /opt/stacks/monitoring/loki/loki-config.yml:/etc/loki/loki-config.yml
    - /opt/stacks/monitoring/loki/data:/loki
```

### loki-config.yml

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-05-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb:
    directory: /loki/index
  filesystem:
    directory: /loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h
```

## Summary

Loki provides log aggregation offering:
- Efficient label-based indexing
- Grafana integration
- LogQL query language
- Low storage costs
- Minimal resource usage
- Promtail log shipping
- Free and open-source

**Perfect for:**
- Docker container logs
- Application logs
- System logs
- Centralized logging
- Grafana users
- Prometheus users

**Key Points:**
- Indexes labels, not content
- Much cheaper than Elasticsearch
- Works with Promtail
- Query in Grafana
- LogQL similar to PromQL
- Low resource usage
- 7-day retention typical

**Remember:**
- Use Promtail to send logs
- Add as Grafana data source
- LogQL for queries
- Configure retention
- Monitor disk space
- Label logs appropriately

Loki aggregates logs efficiently!
