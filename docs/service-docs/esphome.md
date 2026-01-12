# ESPHome - ESP Device Firmware

## Table of Contents
- [Overview](#overview)
- [What is ESPHome?](#what-is-esphome)
- [Why Use ESPHome?](#why-use-esphome)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)
- [Device Examples](#device-examples)

## Overview

**Category:** IoT Device Firmware  
**Docker Image:** [esphome/esphome](https://hub.docker.com/r/esphome/esphome)  
**Default Stack:** `homeassistant.yml`  
**Web UI:** `http://SERVER_IP:6052`  
**Ports:** 6052

## What is ESPHome?

ESPHome is a system for controlling ESP8266/ESP32 microcontrollers through simple YAML configuration files. It generates custom firmware for your ESP devices that integrates natively with Home Assistant. Create custom sensors, switches, lights, and more without writing code.

### Key Features
- **YAML Configuration:** No programming needed
- **Native HA Integration:** Auto-discovered
- **OTA Updates:** Update wirelessly
- **200+ Components:** Sensors, switches, displays
- **Local Control:** No cloud required
- **Fast:** Compiled C++ firmware
- **Cheap:** ESP8266 ~$2, ESP32 ~$5

## Why Use ESPHome?

1. **Cheap Custom Devices:** $2-5 per device
2. **No Programming:** YAML configuration
3. **Home Assistant Native:** Seamless integration
4. **Local Control:** Fully offline
5. **OTA Updates:** Update over WiFi
6. **Reliable:** Compiled firmware, very stable
7. **Versatile:** Sensors, relays, LEDs, displays

## Configuration in AI-Homelab

```
/opt/stacks/homeassistant/esphome/config/
  device1.yaml
  device2.yaml
```

## Official Resources

- **Website:** https://esphome.io
- **Documentation:** https://esphome.io/index.html
- **Devices:** https://esphome.io/devices/index.html

## Docker Configuration

```yaml
esphome:
  image: esphome/esphome:latest
  container_name: esphome
  restart: unless-stopped
  network_mode: host
  environment:
    - TZ=America/New_York
  volumes:
    - /opt/stacks/homeassistant/esphome/config:/config
```

## Device Examples

**Temperature Sensor (DHT22):**
```yaml
esphome:
  name: bedroom-temp
  platform: ESP8266
  board: d1_mini

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:
  encryption:
    key: !secret api_key

ota:
  password: !secret ota_password

sensor:
  - platform: dht
    pin: D2
    temperature:
      name: "Bedroom Temperature"
    humidity:
      name: "Bedroom Humidity"
    update_interval: 60s
```

**Smart Plug (Sonoff):**
```yaml
esphome:
  name: living-room-plug
  platform: ESP8266
  board: esp01_1m

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:
ota:

binary_sensor:
  - platform: gpio
    pin:
      number: GPIO0
      mode: INPUT_PULLUP
      inverted: True
    name: "Living Room Plug Button"
    on_press:
      - switch.toggle: relay

switch:
  - platform: gpio
    name: "Living Room Plug"
    pin: GPIO12
    id: relay
```

ESPHome turns cheap ESP modules into powerful smart home devices!
