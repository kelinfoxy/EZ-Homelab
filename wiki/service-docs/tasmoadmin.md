# TasmoAdmin - Tasmota Device Manager

## Table of Contents
- [Overview](#overview)
- [What is TasmoAdmin?](#what-is-tasmoadmin)
- [Why Use TasmoAdmin?](#why-use-tasmoadmin)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** IoT Device Management  
**Docker Image:** [raymondmm/tasmoadmin](https://hub.docker.com/r/raymondmm/tasmoadmin)  
**Default Stack:** `homeassistant.yml`  
**Web UI:** `http://SERVER_IP:9999`  
**Ports:** 9999

## What is TasmoAdmin?

TasmoAdmin is a centralized web interface for managing multiple Tasmota-flashed devices. Tasmota is alternative firmware for ESP8266 smart devices (Sonoff, Tuya, etc.). TasmoAdmin lets you configure, update, and monitor all your Tasmota devices from one dashboard instead of accessing each device individually.

### Key Features
- **Centralized Management:** All devices in one place
- **Bulk Updates:** Update firmware on all devices
- **Configuration Backup:** Save device configs
- **Device Discovery:** Auto-find Tasmota devices
- **Monitoring:** See status of all devices
- **Remote Control:** Toggle devices
- **Group Operations:** Manage multiple devices

## Why Use TasmoAdmin?

1. **Bulk Management:** Update 50 devices in one click
2. **Configuration Backup:** Save before experiments
3. **Overview:** See all devices at once
4. **Easier Than Individual Access:** No remembering IPs
5. **Bulk Configuration:** Apply settings to groups
6. **Free & Open Source:** No cost

## Configuration in AI-Homelab

```
/opt/stacks/homeassistant/tasmoadmin/data/    # Device configs
```

## Official Resources

- **GitHub:** https://github.com/TasmoAdmin/TasmoAdmin
- **Tasmota:** https://tasmota.github.io/docs

## Docker Configuration

```yaml
tasmoadmin:
  image: raymondmm/tasmoadmin:latest
  container_name: tasmoadmin
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "9999:80"
  volumes:
    - /opt/stacks/homeassistant/tasmoadmin/data:/data
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.tasmoadmin.rule=Host(`tasmoadmin.${DOMAIN}`)"
```

## Summary

TasmoAdmin simplifies managing many Tasmota devices by providing centralized configuration, firmware updates, and monitoring from a single web interface.

**Perfect for:**
- Multiple Tasmota devices
- Bulk firmware updates
- Configuration management
- Device monitoring

**Key Points:**
- Manages Tasmota-flashed ESP devices
- Auto-discovery on network
- Bulk operations support
- Config backup/restore
- Free and open-source

TasmoAdmin makes Tasmota device management effortless!
