# MotionEye - Camera Surveillance

## Table of Contents
- [Overview](#overview)
- [What is MotionEye?](#what-is-motioneye)
- [Why Use MotionEye?](#why-use-motioneye)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Docker Configuration](#docker-configuration)

## Overview

**Category:** Video Surveillance  
**Docker Image:** [ccrisan/motioneye](https://hub.docker.com/r/ccrisan/motioneye)  
**Default Stack:** `homeassistant.yml`  
**Web UI:** `http://SERVER_IP:8765`  
**Default Login:** admin (no password)  
**Ports:** 8765, 8081-8084 (camera streams)

## What is MotionEye?

MotionEye is a web-based frontend for the Motion video surveillance software. It provides a simple interface to manage IP cameras, USB webcams, and Raspberry Pi cameras. Features include motion detection, recording, streaming, and notifications.

### Key Features
- **Multiple Cameras:** Support many cameras
- **Motion Detection:** Alert on movement
- **Recording:** Continuous or motion-triggered
- **Streaming:** Live MJPEG/RTSP streams
- **Cloud Upload:** Google Drive, Dropbox
- **Notifications:** Email, webhooks
- **Mobile Friendly:** Responsive web UI
- **Home Assistant Integration:** Camera entities

## Why Use MotionEye?

1. **Simple Setup:** Easy camera addition
2. **Motion Detection:** Built-in alerts
3. **Free:** No subscription fees
4. **Local Storage:** Your NAS/server
5. **Multiple Cameras:** Centralized management
6. **Home Assistant:** Native integration
7. **Lightweight:** Low resource usage

## Configuration in AI-Homelab

```
/opt/stacks/homeassistant/motioneye/
  config/              # Configuration
  media/              # Recordings
```

## Official Resources

- **GitHub:** https://github.com/ccrisan/motioneye
- **Wiki:** https://github.com/ccrisan/motioneye/wiki

## Docker Configuration

```yaml
motioneye:
  image: ccrisan/motioneye:master-amd64
  container_name: motioneye
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8765:8765"
    - "8081:8081"  # Camera stream ports
    - "8082:8082"
  environment:
    - TZ=America/New_York
  volumes:
    - /opt/stacks/homeassistant/motioneye/config:/etc/motioneye
    - /opt/stacks/homeassistant/motioneye/media:/var/lib/motioneye
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.motioneye.rule=Host(`motioneye.${DOMAIN}`)"
```

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d motioneye
   ```

2. **Access UI:** `http://SERVER_IP:8765`
   - Username: `admin`
   - Password: (blank)
   - **Set password immediately!**

3. **Add Camera:**
   - Click "+" or hamburger menu → Add Camera
   - Camera Type: Network Camera, Simple MJPEG, RTSP, etc.
   - URL: `rtsp://username:password@camera_ip:554/stream`
   - Test and save

4. **Configure Motion Detection:**
   - Select camera
   - Motion Detection → Enable
   - Frame Change Threshold: 1-5% typical
   - Motion Notifications → Email or webhook

5. **Recording:**
   - Recording Mode: Continuous or Motion Triggered
   - Storage location: /var/lib/motioneye
   - Retention: Automatic cleanup

## Summary

MotionEye provides free, local video surveillance with motion detection, recording, and Home Assistant integration for IP cameras and webcams.

**Perfect for:**
- Home security cameras
- Motion-triggered recording
- Multiple camera management
- Local recording
- Budget surveillance

**Key Points:**
- Free and open-source
- Motion detection built-in
- Supports many camera types
- Local storage
- Home Assistant integration
- Change default password!
- RTSP/MJPEG streams

**Remember:**
- Set admin password immediately
- Configure motion detection sensitivity
- Set recording retention
- Test camera streams
- Use RTSP for best quality

MotionEye turns any camera into a smart surveillance system!
