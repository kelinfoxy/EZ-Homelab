# Zigbee2MQTT - Zigbee Bridge

## Table of Contents
- [Overview](#overview)
- [What is Zigbee2MQTT?](#what-is-zigbee2mqtt)
- [Why Use Zigbee2MQTT?](#why-use-zigbee2mqtt)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)
- [Setup](#setup)

## Overview

**Category:** Zigbee Gateway  
**Docker Image:** [koenkk/zigbee2mqtt](https://hub.docker.com/r/koenkk/zigbee2mqtt)  
**Default Stack:** `homeassistant.yml`  
**Web UI:** `http://SERVER_IP:8080`  
**Requires:** USB Zigbee coordinator  
**Ports:** 8080

## What is Zigbee2MQTT?

Zigbee2MQTT is a bridge between Zigbee devices and MQTT. It allows you to use Zigbee devices with Home Assistant without proprietary hubs (Philips Hue bridge, IKEA gateway, etc.). You only need a $15 USB Zigbee coordinator stick.

### Key Features
- **2500+ Supported Devices:** Huge compatibility
- **No Cloud:** Local control
- **No Hubs Needed:** Just USB stick
- **OTA Updates:** Update device firmware
- **Groups:** Control multiple devices
- **Scenes:** Save device states
- **Touchlink:** Reset devices
- **Web UI:** Visual management
- **Free & Open Source:** No subscriptions

## Why Use Zigbee2MQTT?

1. **No Proprietary Hubs:** Save $50+ per brand
2. **Local Control:** No internet required
3. **Any Brand:** Mix Philips, IKEA, Aqara, etc.
4. **More Features:** Than manufacturer apps
5. **Device Updates:** OTA firmware updates
6. **Privacy:** No cloud reporting
7. **Open Source:** Community supported

## Configuration in AI-Homelab

```
/opt/stacks/homeassistant/zigbee2mqtt/
  data/
    configuration.yaml
    database.db
    devices.yaml
    groups.yaml
```

### Zigbee Coordinators

**Recommended:**
- **Sonoff Zigbee 3.0 USB Plus** ($20) - Works great
- **ConBee II** ($40) - Premium option
- **CC2652P** ($25) - Powerful, longer range

**Not Recommended:**
- CC2531 - Old, limited, unreliable

## Official Resources

- **Website:** https://www.zigbee2mqtt.io
- **Supported Devices:** https://www.zigbee2mqtt.io/supported-devices
- **Documentation:** https://www.zigbee2mqtt.io/guide

## Docker Configuration

```yaml
zigbee2mqtt:
  image: koenkk/zigbee2mqtt:latest
  container_name: zigbee2mqtt
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8080:8080"
  environment:
    - TZ=America/New_York
  volumes:
    - /opt/stacks/homeassistant/zigbee2mqtt/data:/app/data
    - /run/udev:/run/udev:ro
  devices:
    - /dev/ttyUSB0:/dev/ttyUSB0
```

## Setup

1. **Find USB Device:**
   ```bash
   ls -la /dev/ttyUSB*
   # or
   ls -la /dev/ttyACM*
   ```

2. **Configure:**
   Edit `/opt/stacks/homeassistant/zigbee2mqtt/data/configuration.yaml`:
   ```yaml
   homeassistant: true
   permit_join: false
   mqtt:
     base_topic: zigbee2mqtt
     server: mqtt://mosquitto:1883
     user: zigbee2mqtt
     password: your_password
   serial:
     port: /dev/ttyUSB0
   frontend:
     port: 8080
   advanced:
     network_key: GENERATE  # Auto-generates on first start
   ```

3. **Start Container:**
   ```bash
   docker compose up -d zigbee2mqtt
   ```

4. **Access Web UI:** `http://SERVER_IP:8080`

5. **Pair Devices:**
   - In UI: Enable "Permit Join" (top right)
   - Or in config: `permit_join: true` and restart
   - Put device in pairing mode (usually hold button)
   - Device appears in Zigbee2MQTT
   - Automatically appears in Home Assistant
   - Disable permit join when done!

## Summary

Zigbee2MQTT bridges Zigbee devices to Home Assistant via MQTT, enabling local control of 2500+ devices from any manufacturer without proprietary hubs.

**Perfect for:**
- Zigbee smart home devices
- Avoiding cloud dependencies
- Multi-brand setups
- Local control
- Cost savings (no hubs)

**Key Points:**
- Requires USB Zigbee coordinator
- 2500+ supported devices
- No manufacturer hubs needed
- Works with MQTT and Home Assistant
- OTA firmware updates
- Web UI for management
- Keep permit_join disabled when not pairing

**Remember:**
- Plug coordinator away from USB 3.0 ports (interference)
- Use USB extension cable if needed
- Disable permit_join after pairing
- Keep firmware updated
- Routers extend network (powered devices)

Zigbee2MQTT liberates your Zigbee devices from proprietary hubs!
