# Homarr - Another Application Dashboard

## Table of Contents
- [Overview](#overview)
- [What is Homarr?](#what-is-homarr)
- [Why Use Homarr?](#why-use-homarr)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Setup and Usage](#setup-and-usage)
- [Widgets and Apps](#widgets-and-apps)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Dashboard  
**Docker Image:** [ghcr.io/ajnart/homarr](https://github.com/ajnart/homarr/pkgs/container/homarr)  
**Default Stack:** `dashboards.yml`  
**Web UI:** `https://homarr.${DOMAIN}` or `http://SERVER_IP:7575`  
**Authentication:** Built-in user system  
**Purpose:** Interactive application dashboard (alternative to Homepage)

## What is Homarr?

Homarr is a customizable application dashboard with a focus on ease of use and interactivity. Unlike Homepage's YAML configuration, Homarr offers a web-based drag-and-drop interface for building your dashboard.

### Key Features
- **Drag-and-Drop UI:** Visual dashboard builder
- **Built-in Auth:** User accounts and permissions
- **App Integrations:** 50+ service widgets
- **Custom Widgets:** RSS, Calendar, Weather, Docker stats
- **Responsive Design:** Mobile-friendly
- **Multi-Board Support:** Create multiple dashboards
- **Search Integration:** Built-in search aggregation
- **Docker Integration:** Container status monitoring
- **Customizable Themes:** Light/dark mode with colors
- **Widget Variety:** Information, media, monitoring widgets
- **No Configuration Files:** Everything managed via GUI
- **Modern UI:** Clean, intuitive interface

## Why Use Homarr?

### Homarr vs Homepage

**Use Homarr if you want:**
- ✅ GUI-based configuration (no YAML)
- ✅ Drag-and-drop dashboard building
- ✅ Built-in user authentication
- ✅ Interactive widget management
- ✅ Visual customization
- ✅ More widget variety
- ✅ Easier for non-technical users

**Use Homepage if you want:**
- ✅ YAML configuration (GitOps friendly)
- ✅ Lighter resource usage
- ✅ Faster performance
- ✅ More mature project
- ✅ Configuration as code

### Common Use Cases

1. **Family Dashboard:** Easy for non-technical users
2. **Media Center:** Integrated media widgets
3. **Multiple Dashboards:** Different boards for different purposes
4. **Interactive Monitoring:** Clickable, actionable widgets
5. **Visual Customization:** Design your perfect dashboard

## How It Works

```
User → Browser → Homarr Web UI
                      ↓
              Dashboard Editor
            (Drag-and-drop interface)
                      ↓
         ┌────────────┴────────────┐
         ↓                         ↓
    App Tiles                  Widgets
    (Services)           (Live data, RSS, etc.)
         ↓                         ↓
    Click to access        API integrations
    service                (Sonarr, Radarr, etc.)
```

### Architecture

**Data Storage:**
- SQLite database (stores dashboards, users, settings)
- Configuration directory (icons, backups)
- No YAML files required

**Components:**
1. **Web Interface:** Dashboard builder and viewer
2. **API Backend:** Service integrations
3. **Database:** User accounts, dashboards, settings
4. **Docker Integration:** Container monitoring

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/dashboards/homarr/
├── data/           # Database and configs
├── icons/          # Custom icons
└── backups/        # Dashboard backups
```

### Environment Variables

```bash
# Base URL (if behind reverse proxy)
BASE_URL=https://homarr.yourdomain.com

# Port
PORT=7575

# Timezone
TZ=America/New_York

# Optional: Disable analytics
DISABLE_ANALYTICS=true
```

## Official Resources

- **Website:** https://homarr.dev
- **GitHub:** https://github.com/ajnart/homarr
- **Documentation:** https://homarr.dev/docs/introduction
- **Discord:** https://discord.gg/aCsmEV5RgA
- **Demo:** https://demo.homarr.dev

## Educational Resources

### Videos
- [Homarr - Modern Dashboard for Your Homelab (Techno Tim)](https://www.youtube.com/watch?v=a2S5iHG5C0M)
- [Homarr Setup Tutorial (DB Tech)](https://www.youtube.com/watch?v=tdMAXd9sHY4)
- [Homepage vs Homarr - Which Dashboard?](https://www.youtube.com/results?search_query=homarr+vs+homepage)

### Articles & Guides
- [Homarr Official Documentation](https://homarr.dev/docs)
- [Widget Configuration Guide](https://homarr.dev/docs/widgets)
- [Integration Setup](https://homarr.dev/docs/integrations)

### Concepts to Learn
- **Dashboard Builders:** Visual interface design
- **Widget Systems:** Modular dashboard components
- **API Integration:** Service data fetching
- **User Authentication:** Multi-user support
- **Docker Integration:** Container monitoring
- **Responsive Design:** Mobile-friendly layouts

## Docker Configuration

### Complete Service Definition

```yaml
homarr:
  image: ghcr.io/ajnart/homarr:latest
  container_name: homarr
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "7575:7575"
  volumes:
    - /opt/stacks/dashboards/homarr/data:/app/data/configs
    - /opt/stacks/dashboards/homarr/icons:/app/public/icons
    - /opt/stacks/dashboards/homarr/data:/data
    - /var/run/docker.sock:/var/run/docker.sock:ro  # For Docker integration
  environment:
    - BASE_URL=https://homarr.${DOMAIN}
    - PORT=7575
    - TZ=America/New_York
    - DISABLE_ANALYTICS=true
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.homarr.rule=Host(`homarr.${DOMAIN}`)"
    - "traefik.http.routers.homarr.entrypoints=websecure"
    - "traefik.http.routers.homarr.tls.certresolver=letsencrypt"
    - "traefik.http.services.homarr.loadbalancer.server.port=7575"
```

## Setup and Usage

### Initial Setup

1. **Access Homarr:**
   - Navigate to: `https://homarr.yourdomain.com`
   - Or: `http://SERVER_IP:7575`

2. **Create Admin Account:**
   - Click "Get Started"
   - Enter username and password
   - Create first dashboard

3. **Dashboard Creation:**
   - Name your dashboard
   - Choose layout (grid, list, etc.)
   - Start adding apps and widgets

### Adding Applications

**Method 1: Manual Add**
1. Click "Edit Mode" (pencil icon)
2. Click "+" button
3. Select "App"
4. Fill in details:
   - Name
   - URL
   - Icon (search or upload)
   - Description
5. Save

**Method 2: Integration**
1. Add app as above
2. Click "Integration" tab
3. Select service type (Sonarr, Radarr, etc.)
4. Enter API URL and key
5. Save - widget will show live data

**Method 3: Docker Discovery**
1. Enable Docker integration
2. Homarr auto-discovers containers
3. Add discovered apps to dashboard

### Dashboard Editor

**Edit Mode:**
- Click pencil icon to enter edit mode
- Drag tiles to rearrange
- Resize tiles by dragging corners
- Delete tiles with X button
- Click tiles to edit settings

**Grid System:**
- Tiles snap to grid
- Customizable grid size
- Responsive layout
- Mobile-optimized views

**Categories:**
- Create sections (Media, Management, etc.)
- Collapse/expand categories
- Organize apps logically

### User Management

**Create Users:**
1. Settings → Users → Add User
2. Set username and password
3. Assign permissions
4. User can login and customize their dashboard

**Permissions:**
- **Admin:** Full access
- **User:** View and edit own dashboards
- **Guest:** Read-only access

## Widgets and Apps

### Application Widgets

**Supported Integrations:**

**Media:**
- Plex, Jellyfin, Emby
- Sonarr, Radarr, Lidarr, Readarr
- Prowlarr, Jackett
- qBittorrent, Transmission, Deluge
- Tautulli (Plex stats)
- Overseerr, Jellyseerr

**Infrastructure:**
- Portainer
- Traefik
- Pi-hole, AdGuard Home
- Uptime Kuma
- Proxmox

**Other:**
- Home Assistant
- Nextcloud
- Gitea
- Calibre-Web
- Many more...

### Information Widgets

**Weather Widget:**
```
Location: Auto-detect or manual
Provider: OpenWeatherMap, WeatherAPI
Units: Imperial/Metric
Forecast: 3-7 days
```

**Calendar Widget:**
```
Type: iCal URL
Source: Google Calendar, Nextcloud, etc.
Events: Upcoming events display
```

**RSS Widget:**
```
Feed URL: Any RSS/Atom feed
Items: Number to show
Refresh: Update interval
```

**Docker Widget:**
```
Shows: Running/Stopped containers
Stats: CPU, Memory, Network
Control: Start/Stop containers (if permissions)
```

**Clock Widget:**
```
Format: 12h/24h
Timezone: Custom or system
Date: Show/hide
Analog/Digital: Style choice
```

**Media Server Widget:**
```
Plex/Jellyfin: Currently playing
Recent: Recently added
Stats: Library counts
```

### Custom Widgets

**HTML Widget:**
- Embed custom HTML
- Use for iframes, custom content
- CSS styling support

**Iframe Widget:**
- Embed external websites
- Dashboard within dashboard
- Useful for Grafana, etc.

**Image Widget:**
- Display static images
- Backgrounds, logos
- Network/local images

## Advanced Topics

### Custom Icons

**Upload Custom Icons:**
1. Place icons in `/icons/` directory
2. Or upload via UI
3. Reference in app settings

**Icon Sources:**
- Built-in icon library (1000+)
- Upload your own (PNG, SVG, JPG)
- URL to external icon
- Dashboard Icons repository

### Multiple Dashboards

**Create Multiple Boards:**
1. Settings → Boards → New Board
2. Name and configure
3. Switch between boards
4. Different dashboards for different purposes:
   - Family board
   - Admin board
   - Media board
   - etc.

**Board Sharing:**
- Share board link
- Set access permissions
- Public vs private boards

### Themes and Customization

**Theme Options:**
- Light/Dark mode
- Accent colors
- Background images
- Custom CSS (advanced)

**Layout Options:**
- Grid size
- Tile spacing
- Column count
- Responsive breakpoints

### Docker Integration

**Enable Docker:**
1. Mount Docker socket
2. Settings → Docker → Enable
3. Select which containers to show
4. Auto-discovery or manual

**Docker Features:**
- Container status
- Start/Stop controls (if enabled)
- Resource usage
- Quick access to logs

### API Access

**REST API:**
- Endpoint: `https://homarr.domain.com/api`
- Authentication: API key
- Use for automation
- Integration with other tools

**API Uses:**
- Automated dashboard updates
- External monitoring
- Custom integrations
- Backup automation

### Backup and Restore

**Manual Backup:**
1. Settings → Backups
2. Create backup
3. Download JSON file

**Restore:**
1. Settings → Backups
2. Upload backup file
3. Select boards to restore

**File System Backup:**
```bash
# Backup entire data directory
tar -czf homarr-backup-$(date +%Y%m%d).tar.gz /opt/stacks/dashboards/homarr/data/

# Restore
tar -xzf homarr-backup-20240112.tar.gz -C /opt/stacks/dashboards/homarr/
docker restart homarr
```

### Import/Export

**Export Dashboard:**
- Settings → Export → Download JSON
- Share with others
- Version control

**Import Dashboard:**
- Settings → Import → Upload JSON
- Community dashboards
- Template boards

## Troubleshooting

### Homarr Not Loading

```bash
# Check container status
docker ps | grep homarr

# View logs
docker logs homarr

# Test port
curl http://localhost:7575

# Check Traefik routing
docker logs traefik | grep homarr
```

### Can't Login

```bash
# Reset admin password
docker exec -it homarr npm run db:reset-password

# Or recreate database (WARNING: loses data)
docker stop homarr
rm -rf /opt/stacks/dashboards/homarr/data/db.sqlite
docker start homarr
# Creates new database, need to setup again
```

### Widgets Not Showing Data

```bash
# Check API connectivity
docker exec homarr curl http://service:port

# Verify API key
# Re-enter in widget settings

# Check service logs
docker logs service-name

# Test API manually
curl -H "X-Api-Key: key" http://service:port/api/endpoint
```

### Icons Not Displaying

```bash
# Clear browser cache
# Ctrl+Shift+R (hard refresh)

# Check icon path
ls -la /opt/stacks/dashboards/homarr/icons/

# Ensure proper permissions
sudo chown -R 1000:1000 /opt/stacks/dashboards/homarr/

# Re-upload icon via UI
```

### Docker Integration Not Working

```bash
# Verify socket mount
docker inspect homarr | grep -A5 Mounts

# Check socket permissions
ls -la /var/run/docker.sock

# Fix permissions
sudo chmod 666 /var/run/docker.sock

# Or use Docker Socket Proxy (recommended)
```

### High Memory Usage

```bash
# Check container stats
docker stats homarr

# Typical usage: 100-300MB
# If higher, restart container
docker restart homarr

# Reduce widgets if needed
# Remove unused integrations
```

### Slow Performance

```bash
# Reduce widget refresh rates
# Edit widget → Change refresh interval

# Disable unused features
# Settings → Integrations → Disable unused

# Check network latency
# Ping services from Homarr container

# Restart container
docker restart homarr
```

## Performance Optimization

### Reduce API Calls

- Increase widget refresh intervals
- Disable widgets for services you don't monitor frequently
- Use lazy loading for images

### Optimize Docker

```yaml
homarr:
  deploy:
    resources:
      limits:
        cpus: '1.0'
        memory: 512M
      reservations:
        memory: 128M
```

### Cache Settings

- Enable browser caching
- Use CDN for icons if available
- Optimize image sizes

## Comparison with Alternatives

### Homarr vs Homepage

**Homarr:**
- GUI configuration
- Built-in authentication
- Drag-and-drop
- More interactive
- Higher resource usage

**Homepage:**
- YAML configuration
- External auth required
- Faster performance
- GitOps friendly
- Lighter weight

### Homarr vs Heimdall

**Homarr:**
- More modern UI
- Better integrations
- Active development
- More features

**Heimdall:**
- Simpler
- Very lightweight
- Established project
- Basic functionality

### Homarr vs Organizr

**Homarr:**
- Newer, modern
- Better mobile support
- Easier setup
- More widgets

**Organizr:**
- More mature
- Tab-based interface
- Different philosophy
- Large community

## Tips and Tricks

### Efficient Layouts

**Media Dashboard:**
- Large tiles for Plex/Jellyfin
- Medium tiles for *arr apps
- Small tiles for indexers
- Weather widget in corner

**Admin Dashboard:**
- Grid of management tools
- Docker status widget
- System resource widget
- Recent logs/alerts

**Family Dashboard:**
- Large, simple icons
- Hide technical services
- Focus on media/content
- Bright, friendly theme

### Widget Combinations

**Media Setup:**
1. Plex/Jellyfin (large, with integration)
2. Sonarr/Radarr (medium, with stats)
3. qBittorrent (small, with speed)
4. Recently added (widget)

**Monitoring Setup:**
1. Docker widget (container status)
2. Pi-hole widget (blocking stats)
3. Uptime Kuma widget (service status)
4. Weather widget (why not?)

### Custom Styling

Use custom CSS for unique looks:
- Rounded corners
- Custom colors
- Transparency effects
- Animations

## Summary

Homarr is a user-friendly, interactive dashboard that offers:
- Visual dashboard builder
- Built-in authentication
- Rich widget ecosystem
- Drag-and-drop interface
- Modern, responsive design
- No configuration files needed

**Perfect for:**
- Users who prefer GUI over YAML
- Multi-user environments
- Interactive dashboards
- Visual customization fans
- Quick setup without learning curve

**Trade-offs:**
- Higher resource usage than Homepage
- Database dependency
- Less GitOps friendly
- Newer project (less mature)

**Best Practices:**
- Use both Homepage and Homarr (they complement each other)
- Homepage for you, Homarr for family
- Regular backups of database
- Optimize widget refresh rates
- Use Docker Socket Proxy for security
- Keep updated for new features

**Remember:**
- Homarr is all about visual customization
- No YAML - everything in UI
- Great for non-technical users
- Built-in auth is convenient
- Can coexist with Homepage
- Choose based on your preference and use case
