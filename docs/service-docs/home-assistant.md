# Home Assistant - Home Automation Platform

## Table of Contents
- [Overview](#overview)
- [What is Home Assistant?](#what-is-home-assistant)
- [Why Use Home Assistant?](#why-use-home-assistant)
- [Key Concepts](#key-concepts)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [Integrations](#integrations)
- [Automations](#automations)
- [Add-ons vs Docker](#add-ons-vs-docker)
- [Troubleshooting](#troubleshooting)
- [Advanced Topics](#advanced-topics)

## Overview

**Category:** Home Automation  
**Docker Image:** [homeassistant/home-assistant](https://hub.docker.com/r/homeassistant/home-assistant)  
**Default Stack:** `homeassistant.yml`  
**Web UI:** `https://homeassistant.${DOMAIN}` or `http://SERVER_IP:8123`  
**Ports:** 8123  
**Network Mode:** host (for device discovery)

## What is Home Assistant?

Home Assistant is a free, open-source home automation platform that focuses on local control and privacy. It integrates thousands of different devices and services, allowing you to automate and control your entire smart home from a single interface. Unlike cloud-based solutions, Home Assistant runs entirely locally on your network.

### Key Features
- **2000+ Integrations:** Supports virtually every smart device
- **Local Control:** Works without internet
- **Privacy Focused:** Your data stays home
- **Powerful Automations:** Visual and YAML-based
- **Voice Control:** Alexa, Google, Siri compatibility
- **Energy Monitoring:** Track usage and solar
- **Mobile Apps:** iOS and Android
- **Dashboards:** Customizable UI
- **Community:** Huge active community
- **Free & Open Source:** No subscriptions

## Why Use Home Assistant?

1. **Universal Integration:** Control everything from one place
2. **Local Control:** Works without internet
3. **Privacy:** Data never leaves your network
4. **No Cloud Required:** Unlike SmartThings, Alexa routines
5. **Powerful Automations:** Complex logic possible
6. **Active Development:** Updates every 3 weeks
7. **Community:** Massive community support
8. **Cost:** Free forever, no subscriptions
9. **Customizable:** Unlimited flexibility
10. **Future-Proof:** Open-source ensures longevity

## Key Concepts

### Entities
The basic building blocks of Home Assistant:
- **Sensors:** Temperature, humidity, power usage
- **Switches:** On/off devices
- **Lights:** Brightness, color control
- **Binary Sensors:** Motion, door/window sensors
- **Climate:** Thermostats
- **Cameras:** Video feeds
- **Media Players:** Speakers, TVs

### Integrations
Connections to devices and services:
- **Zigbee2MQTT:** Zigbee devices
- **ESPHome:** Custom ESP devices
- **MQTT:** Message broker protocol
- **HACS:** Community store
- **Tasmota:** Flashed smart plugs
- **UniFi:** Network devices
- **Plex/Jellyfin:** Media servers

### Automations
Triggered actions:
- **Trigger:** What starts the automation
- **Condition:** Requirements to continue
- **Action:** What happens

Example: Motion detected → If after sunset → Turn on lights

### Scripts
Reusable action sequences:
- Manual execution
- Called from automations
- Parameterized

### Scenes
Saved states of devices:
- "Movie Time" → Dims lights, closes blinds
- "Good Night" → Turns off everything
- One-click activation

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/homeassistant/home-assistant/config/
  configuration.yaml      # Main config
  automations.yaml       # Automations
  scripts.yaml           # Scripts
  secrets.yaml           # Sensitive data
  custom_components/     # HACS and custom integrations
  www/                   # Custom resources
  blueprints/            # Automation blueprints
```

### Environment Variables

```bash
TZ=America/New_York
```

### Network Mode: host

Home Assistant uses `network_mode: host` instead of bridge networking. This is required for:
- **Device Discovery:** mDNS, UPnP, SSDP
- **Casting:** Chromecast, Google Home
- **HomeKit:** Apple HomeKit bridge
- **DLNA:** Media device discovery

**Trade-off:** Can't use Traefik routing easily. Typically accessed via IP:8123 or DNS record pointing to server IP.

## Official Resources

- **Website:** https://www.home-assistant.io
- **Documentation:** https://www.home-assistant.io/docs
- **Community:** https://community.home-assistant.io
- **GitHub:** https://github.com/home-assistant/core
- **YouTube:** https://www.youtube.com/@homeassistant

## Educational Resources

### YouTube Channels
1. **Everything Smart Home** - https://www.youtube.com/@EverythingSmartHome
   - Best Home Assistant tutorials
   - Device reviews and integrations
   - Automation ideas

2. **Smart Home Junkie** - https://www.youtube.com/@SmartHomeJunkie
   - In-depth Home Assistant guides
   - Zigbee, Z-Wave, ESPHome
   - Advanced automations

3. **Intermit.Tech** - https://www.youtube.com/@intermittechnology
   - Technical deep dives
   - Docker Home Assistant setup
   - Integration tutorials

4. **BeardedTinker** - https://www.youtube.com/@BeardedTinker
   - German/English tutorials
   - Creative automation ideas
   - Device comparisons

### Articles & Guides
1. **Official Getting Started:** https://www.home-assistant.io/getting-started
2. **Home Assistant Course:** https://www.home-assistant.io/course
3. **Community Guides:** https://community.home-assistant.io/c/guides/37

### Books
1. **"Home Assistant Cookbook"** by Marco Bruni
2. **"Practical Home Assistant"** by Alan Tse

## Docker Configuration

```yaml
home-assistant:
  image: homeassistant/home-assistant:latest
  container_name: home-assistant
  restart: unless-stopped
  network_mode: host
  privileged: true  # For USB devices (Zigbee/Z-Wave sticks)
  environment:
    - TZ=America/New_York
  volumes:
    - /opt/stacks/homeassistant/home-assistant/config:/config
    - /etc/localtime:/etc/localtime:ro
    - /run/dbus:/run/dbus:ro  # For Bluetooth
  devices:
    - /dev/ttyUSB0:/dev/ttyUSB0  # Zigbee coordinator (if present)
  labels:
    - "com.centurylinklabs.watchtower.enable=false"  # Manual updates recommended
```

**Note:** `network_mode: host` means no Traefik routing. Access via server IP.

## Initial Setup

1. **Start Container:**
   ```bash
   docker compose up -d home-assistant
   ```

2. **Access UI:** `http://SERVER_IP:8123`

3. **Create Account:**
   - Name, username, password
   - This is your admin account
   - Secure password required

4. **Set Location:**
   - Used for weather, sun position
   - Important for automations

5. **Scan for Devices:**
   - Home Assistant auto-discovers many devices
   - Check discovered integrations

6. **Install HACS (Highly Recommended):**

   HACS provides thousands of community integrations and themes.

   ```bash
   # Access container
   docker exec -it home-assistant bash

   # Download HACS
   wget -O - https://get.hacs.xyz | bash -

   # Restart Home Assistant
   exit
   docker restart home-assistant
   ```

   Then in UI:
   - Settings → Devices & Services → Add Integration
   - Search "HACS"
   - Authorize with GitHub account
   - HACS now available in sidebar

## Integrations

### Essential Integrations

**Zigbee2MQTT:**
- Connect Zigbee devices
- Requires Zigbee coordinator USB stick
- See zigbee2mqtt.md documentation

**ESPHome:**
- Custom ESP8266/ESP32 devices
- Flashed smart plugs, sensors
- See esphome.md documentation

**MQTT:**
- Message broker for IoT devices
- Connects Zigbee2MQTT, Tasmota
- See mosquitto.md documentation

**Mobile App:**
- iOS/Android apps
- Location tracking
- Notifications
- Remote access

**Media Integrations:**
- Plex/Jellyfin: Media controls
- Spotify: Music control
- Sonos: Speaker control

**Network Integrations:**
- UniFi: Device tracking
- Pi-hole: Stats and control
- Wake on LAN: Turn on computers

### Adding Integrations

**UI Method:**
1. Settings → Devices & Services
2. "+ Add Integration"
3. Search for integration
4. Follow setup wizard

**YAML Method (configuration.yaml):**
```yaml
# Example: MQTT
mqtt:
  broker: mosquitto
  port: 1883
  username: !secret mqtt_user
  password: !secret mqtt_pass
```

## Automations

### Visual Editor

1. **Settings → Automations & Scenes → Create Automation**

2. **Choose Trigger:**
   - Time
   - Device state change
   - Numeric state (temperature > 75°F)
   - Event
   - Webhook

3. **Add Conditions (Optional):**
   - Time of day
   - Day of week
   - Device states
   - Numeric comparisons

4. **Choose Actions:**
   - Turn on/off devices
   - Send notifications
   - Call services
   - Delays
   - Repeat actions

### YAML Automations

**Example: Motion-Activated Lights**

```yaml
automation:
  - alias: "Hallway Motion Lights"
    description: "Turn on hallway lights when motion detected after sunset"
    trigger:
      - platform: state
        entity_id: binary_sensor.hallway_motion
        to: "on"
    condition:
      - condition: sun
        after: sunset
    action:
      - service: light.turn_on
        target:
          entity_id: light.hallway
        data:
          brightness_pct: 75
      - delay:
          minutes: 5
      - service: light.turn_off
        target:
          entity_id: light.hallway
```

### Automation Ideas

**Security:**
- Notify if door opens when away
- Flash lights if motion detected at night
- Send camera snapshot on doorbell press

**Comfort:**
- Adjust thermostat based on presence
- Close blinds when sunny
- Turn on fan if temperature > X

**Energy:**
- Turn off devices at bedtime
- Disable charging when battery full
- Monitor and alert high usage

**Media:**
- Dim lights when movie starts
- Pause media on doorbell
- Resume after phone call

## Add-ons vs Docker

**Home Assistant OS** (not used in AI-Homelab) includes an "Add-ons" system. Since AI-Homelab uses Docker directly, we deploy services as separate containers instead:

| Add-on | AI-Homelab Docker Service |
|--------|---------------------------|
| Mosquitto Broker | mosquitto container |
| Zigbee2MQTT | zigbee2mqtt container |
| ESPHome | esphome container |
| Node-RED | node-red container |
| File Editor | code-server container |

**Advantages of Docker Approach:**
- More control
- Easier backups
- Standard Docker tools
- Better resource management

**Disadvantage:**
- Manual integration setup (vs automatic with add-ons)

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs home-assistant

# Common issue: Port 8123 in use
sudo netstat -tulpn | grep 8123

# Check config syntax
docker exec home-assistant python -m homeassistant --script check_config
```

### Configuration Errors

```bash
# Validate configuration
# Settings → System → Check Configuration

# Or via command line:
docker exec home-assistant python -m homeassistant --script check_config

# View specific file
docker exec home-assistant cat /config/configuration.yaml
```

### Integration Not Working

```bash
# Check logs for integration
# Settings → System → Logs
# Filter by integration name

# Reload integration
# Settings → Devices & Services → Integration → Reload

# Remove and re-add if persistent
# Settings → Devices & Services → Integration → Delete
# Then add again
```

### USB Device Not Found

```bash
# List USB devices
ls -la /dev/ttyUSB*
ls -la /dev/ttyACM*

# Check device is passed to container
docker exec home-assistant ls -la /dev/

# Verify permissions
ls -la /dev/ttyUSB0

# Add user to dialout group (host)
sudo usermod -aG dialout kelin
# Restart

# Or set permissions in docker-compose
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
```

### Slow Performance

```bash
# Check recorder size
docker exec -it home-assistant bash
ls -lh /config/home-assistant_v2.db

# If large (>1GB), purge old data
# In UI: Settings → System → Repair → Database
# Or configure in configuration.yaml:

recorder:
  purge_keep_days: 7
  commit_interval: 5
```

## Advanced Topics

### Backup Strategy

**Manual Backup:**
```bash
# Stop container
docker stop home-assistant

# Backup config directory
tar -czf ha-backup-$(date +%Y%m%d).tar.gz \
  /opt/stacks/homeassistant/home-assistant/config/

# Start container
docker start home-assistant
```

**Automated Backup:**
Use Home Assistant's built-in backup (Settings → System → Backups), or setup scheduled backups with the Backrest service in utilities stack.

### Secrets Management

Keep passwords out of configuration:

**secrets.yaml:**
```yaml
mqtt_user: homeassistant
mqtt_pass: your_secure_password
api_key: abc123xyz789
```

**configuration.yaml:**
```yaml
mqtt:
  username: !secret mqtt_user
  password: !secret mqtt_pass

weather:
  - platform: openweathermap
    api_key: !secret api_key
```

### Custom Components (HACS)

Thousands of community integrations:

**Popular HACS Integrations:**
- **Browser Mod:** Control browser tabs
- **Frigate:** NVR integration
- **Adaptive Lighting:** Circadian-based lighting
- **Alexa Media Player:** Advanced Alexa control
- **Waste Collection Schedule:** Trash reminders
- **Grocy:** Grocery management

**Install from HACS:**
1. HACS → Integrations
2. Search for integration
3. Download
4. Restart Home Assistant
5. Add integration via UI

### Templating

Jinja2 templates for dynamic values:

```yaml
# Get temperature difference
{{ states('sensor.outside_temp') | float - states('sensor.inside_temp') | float }}

# Conditional message
{% if is_state('person.john', 'home') %}
  John is home
{% else %}
  John is away
{% endif %}

# Count open windows
{{ states.binary_sensor | selectattr('entity_id', 'search', 'window')
   | selectattr('state', 'eq', 'on') | list | count }}
```

### Voice Control

**Alexa:**
- Settings → Integrations → Alexa
- Expose entities to Alexa
- "Alexa, turn on living room lights"

**Google Assistant:**
- Requires Home Assistant Cloud ($6.50/month) or manual setup
- Or use Nabu Casa Cloud for easy setup

**Local Voice:**
- New feature (2023+)
- Wake word detection
- Runs fully local
- Requires USB microphone

### Node-RED Integration

Visual automation builder:
- More flexible than HA automations
- Drag-and-drop flow-based
- See node-red.md documentation

**Connect to HA:**
- Install node-red-contrib-home-assistant-websocket
- Configure Home Assistant server
- Long-lived access token

## Summary

Home Assistant is the ultimate home automation platform offering:
- 2000+ device integrations
- Local control and privacy
- Powerful automations
- Voice control
- Energy monitoring
- Mobile apps
- Active community
- Free and open-source

**Perfect for:**
- Smart home enthusiasts
- Privacy-conscious users
- DIY home automation
- Multi-brand device integration
- Complex automation needs
- Energy monitoring

**Key Points:**
- Runs entirely locally
- Works without internet
- Massive device support
- 3-week release cycle
- HACS for community add-ons
- Mobile apps available
- No subscriptions required

**Remember:**
- Install HACS for extra integrations
- Use secrets.yaml for passwords
- Regular backups important
- Community forum is helpful
- Updates every 3 weeks
- Read changelogs before updating

Home Assistant gives you complete control of your smart home!
