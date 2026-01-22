# Mosquitto - MQTT Broker

## Table of Contents
- [Overview](#overview)
- [What is Mosquitto?](#what-is-mosquitto)
- [Why Use Mosquitto?](#why-use-mosquitto)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Message Broker  
**Docker Image:** [eclipse-mosquitto](https://hub.docker.com/_/eclipse-mosquitto)  
**Default Stack:** `homeassistant.yml`  
**Ports:** 1883 (MQTT), 9001 (WebSocket)

## What is Mosquitto?

Mosquitto is an MQTT broker - a message bus for IoT devices. MQTT (Message Queuing Telemetry Transport) is a lightweight publish/subscribe protocol perfect for smart home devices. Mosquitto acts as the central hub where devices publish messages (like sensor readings) and other devices/services subscribe to receive them.

### Key Features
- **Lightweight:** Minimal resource usage
- **Fast:** Low latency messaging
- **Reliable:** Quality of Service levels
- **Secure:** Authentication and TLS support
- **Standard:** Industry-standard MQTT 3.1.1 and 5.0
- **WebSocket Support:** Browser connections

## Why Use Mosquitto?

1. **IoT Standard:** Industry-standard protocol
2. **Lightweight:** Efficient for battery devices
3. **Fast:** Real-time messaging
4. **Central Hub:** Connect all IoT devices
5. **Home Assistant Integration:** Native support
6. **Zigbee2MQTT:** Required for Zigbee devices
7. **Tasmota:** Tasmota devices use MQTT

## Configuration in AI-Homelab

```
/opt/stacks/homeassistant/mosquitto/
  config/
    mosquitto.conf    # Main config
    password.txt      # Hashed passwords
  data/               # Persistence
  log/                # Logs
```

### mosquitto.conf

```conf
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log

listener 1883
allow_anonymous false
password_file /mosquitto/config/password.txt

listener 9001
protocol websockets
```

## Official Resources

- **Website:** https://mosquitto.org
- **Documentation:** https://mosquitto.org/documentation

## Docker Configuration

```yaml
mosquitto:
  image: eclipse-mosquitto:latest
  container_name: mosquitto
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "1883:1883"
    - "9001:9001"
  volumes:
    - /opt/stacks/homeassistant/mosquitto/config:/mosquitto/config
    - /opt/stacks/homeassistant/mosquitto/data:/mosquitto/data
    - /opt/stacks/homeassistant/mosquitto/log:/mosquitto/log
```

## Setup

**Create User:**
```bash
docker exec -it mosquitto mosquitto_passwd -c /mosquitto/config/password.txt homeassistant

# Add more users
docker exec -it mosquitto mosquitto_passwd /mosquitto/config/password.txt zigbee2mqtt

# Restart
docker restart mosquitto
```

**Test Connection:**
```bash
# Subscribe (terminal 1)
docker exec -it mosquitto mosquitto_sub -h localhost -t test/topic -u homeassistant -P yourpassword

# Publish (terminal 2)
docker exec -it mosquitto mosquitto_pub -h localhost -t test/topic -m "Hello MQTT" -u homeassistant -P yourpassword
```

## Summary

Mosquitto is the MQTT message broker providing:
- Central IoT message hub
- Publish/subscribe protocol
- Lightweight and fast
- Required for Zigbee2MQTT
- Home Assistant integration
- Secure authentication
- Free and open-source

**Perfect for:**
- Smart home setups
- Zigbee devices (via Zigbee2MQTT)
- Tasmota devices
- ESP devices
- IoT messaging
- Real-time communication

**Key Points:**
- Create users with mosquitto_passwd
- Used by Zigbee2MQTT
- Home Assistant connects to it
- Port 1883 for MQTT
- Port 9001 for WebSockets
- Authentication required

Mosquitto is the messaging backbone of your smart home!
