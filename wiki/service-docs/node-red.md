# Node-RED - Visual Automation

## Table of Contents
- [Overview](#overview)
- [What is Node-RED?](#what-is-node-red)
- [Why Use Node-RED?](#why-use-node-red)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)
- [Integration with Home Assistant](#integration-with-home-assistant)

## Overview

**Category:** Visual Automation  
**Docker Image:** [nodered/node-red](https://hub.docker.com/r/nodered/node-red)  
**Default Stack:** `homeassistant.yml`  
**Web UI:** `http://SERVER_IP:1880`  
**Ports:** 1880

## What is Node-RED?

Node-RED is a flow-based programming tool for wiring together hardware devices, APIs, and online services. It provides a browser-based visual editor where you drag and drop nodes to create automations. Extremely popular with Home Assistant users for creating complex automations that would be difficult in Home Assistant's native automation system.

### Key Features
- **Visual Programming:** Drag and drop flows
- **700+ Nodes:** Pre-built functionality
- **Home Assistant Integration:** Deep integration
- **Debugging:** Real-time message inspection
- **Functions:** JavaScript for custom logic
- **Subflows:** Reusable components
- **Context Storage:** Variables and state
- **Dashboard:** Create custom UIs

## Why Use Node-RED?

1. **Visual:** See your automation logic
2. **More Powerful:** Than HA automations
3. **Easier Complex Logic:** AND/OR conditions
4. **Debugging:** See data flow in real-time
5. **Reusable:** Subflows for common patterns
6. **Learning Curve:** Easier than YAML
7. **Community:** Tons of examples

### Node-RED vs Home Assistant Automations

**Use Node-RED when:**
- Complex conditional logic needed
- Multiple triggers with different actions
- Data transformation required
- API calls to external services
- State machines
- Advanced debugging needed

**Use HA Automations when:**
- Simple trigger → action
- Using blueprints
- Want HA native management
- Simple time-based automations

## Configuration in AI-Homelab

```
/opt/stacks/homeassistant/node-red/data/
  flows.json          # Your flows
  settings.js         # Node-RED config
  package.json        # Installed nodes
```

## Official Resources

- **Website:** https://nodered.org
- **Documentation:** https://nodered.org/docs
- **Flows Library:** https://flows.nodered.org
- **Home Assistant Nodes:** https://zachowj.github.io/node-red-contrib-home-assistant-websocket

## Docker Configuration

```yaml
node-red:
  image: nodered/node-red:latest
  container_name: node-red
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "1880:1880"
  environment:
    - TZ=America/New_York
  volumes:
    - /opt/stacks/homeassistant/node-red/data:/data
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.node-red.rule=Host(`node-red.${DOMAIN}`)"
```

## Integration with Home Assistant

1. **Install HA Nodes:**
   - In Node-RED: Menu → Manage Palette → Install
   - Search: `node-red-contrib-home-assistant-websocket`
   - Install

2. **Configure Connection:**
   - Drag any Home Assistant node to canvas
   - Double-click → Add new server
   - Base URL: `http://home-assistant:8123` (or IP)
   - Access Token: Generate in HA (Profile → Long-lived token)

3. **Available Nodes:**
   - **Events: state:** Trigger on entity state change
   - **Events: all:** Listen to all events
   - **Call service:** Control devices
   - **Current state:** Get entity state
   - **Get entities:** List entities
   - **Trigger: state:** More options than events

**Example Flow: Motion Light with Conditions**

```
[Motion Sensor] → [Check Time] → [Check if Dark] → [Turn On Light] → [Wait 5min] → [Turn Off Light]
```

## Summary

Node-RED is the visual automation tool offering:
- Drag-and-drop flow creation
- Deep Home Assistant integration
- More powerful than HA automations
- Real-time debugging
- JavaScript functions for custom logic
- Dashboard creation
- Free and open-source

**Perfect for:**
- Complex Home Assistant automations
- Visual thinkers
- API integrations
- State machines
- Advanced logic requirements
- Custom dashboards

**Key Points:**
- Visual programming interface
- Requires HA nodes package
- Long-lived access token needed
- More flexible than HA automations
- Real-time flow debugging
- Subflows for reusability

**Remember:**
- Generate HA long-lived token
- Install home-assistant-websocket nodes
- Save/deploy flows after changes
- Export flows for backup
- Use debug nodes while developing

Node-RED makes complex automations visual and manageable!
