# Pi-hole - Network-Wide Ad Blocker

## Table of Contents
- [Overview](#overview)
- [What is Pi-hole?](#what-is-pi-hole)
- [Why Use Pi-hole?](#why-use-pi-hole)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Setup and Management](#setup-and-management)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Infrastructure / Network  
**Docker Image:** [pihole/pihole](https://hub.docker.com/r/pihole/pihole)  
**Default Stack:** `infrastructure.yml`  
**Web UI:** `https://pihole.${DOMAIN}/admin` or `http://SERVER_IP:8181/admin`  
**Authentication:** Admin password set via environment variable  
**DNS Port:** 53 (TCP/UDP)

## What is Pi-hole?

Pi-hole is a network-level advertisement and internet tracker blocking application that acts as a DNS sinkhole. Originally designed for Raspberry Pi, it now runs on any Linux system including Docker. It blocks ads for all devices on your network without requiring per-device configuration.

### Key Features
- **Network-Wide Blocking:** Blocks ads on all devices (phones, tablets, smart TVs)
- **DNS Level Blocking:** Intercepts DNS queries before ads load
- **No Client Software:** Works for all devices automatically
- **Extensive Blocklists:** Millions of known ad/tracking domains blocked
- **Web Interface:** Beautiful dashboard with statistics
- **Whitelist/Blacklist:** Custom domain control
- **DHCP Server:** Optional network DHCP service
- **DNS Over HTTPS:** Encrypted DNS queries (DoH)
- **Query Logging:** See all DNS queries on network
- **Group Management:** Different blocking rules for different devices
- **Regex Filtering:** Advanced domain pattern blocking

## Why Use Pi-hole?

1. **Block Ads Everywhere:** Mobile apps, smart TVs, IoT devices
2. **Faster Browsing:** Pages load faster without ads
3. **Privacy Protection:** Block trackers and analytics
4. **Save Bandwidth:** Don't download ad content
5. **Malware Protection:** Block known malicious domains
6. **Family Safety:** Block inappropriate content
7. **Network Visibility:** See what devices are connecting where
8. **Free:** No subscription fees
9. **Customizable:** Full control over blocking

## How It Works

```
Device (Phone/Computer/TV)
     ↓
DNS Query: "ads.example.com"
     ↓
Router/DHCP → Pi-hole (DNS Server)
     ↓
Is domain in blocklist?
     ├─ YES → Return 0.0.0.0 (blocked)
     └─ NO  → Forward to upstream DNS → Return real IP
```

### Blocking Process

1. **Device makes request:** "I want to visit ads.google.com"
2. **DNS query sent:** Device asks "What's the IP for ads.google.com?"
3. **Pi-hole receives query:** Checks against blocklists
4. **If blocked:** Returns 0.0.0.0 (null IP) - ad doesn't load
5. **If allowed:** Forwards to real DNS (1.1.1.1, 8.8.8.8, etc.)
6. **Result cached:** Faster subsequent queries

### Network Setup

**Before Pi-hole:**
```
Device → Router DNS → ISP DNS → Internet
```

**After Pi-hole:**
```
Device → Router (points to Pi-hole) → Pi-hole → Upstream DNS → Internet
                                         ↓
                                    (blocks ads)
```

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/infrastructure/pihole/
├── etc-pihole/         # Pi-hole configuration
│   ├── gravity.db      # Blocklist database
│   ├── custom.list     # Local DNS records
│   └── pihole-FTL.db   # Query log database
└── etc-dnsmasq.d/      # DNS server config
    └── custom.conf     # Custom DNS rules
```

### Environment Variables

```bash
# Web Interface Password
WEBPASSWORD=your-secure-password-here

# Timezone
TZ=America/New_York

# Upstream DNS Servers
PIHOLE_DNS_=1.1.1.1;8.8.8.8  # Cloudflare and Google
# PIHOLE_DNS_=9.9.9.9;149.112.112.112  # Quad9 (privacy-focused)

# Web Interface Settings
WEBTHEME=default-dark  # or default-light
VIRTUAL_HOST=pihole.yourdomain.com
WEB_PORT=80

# Optional: DHCP Server
DHCP_ACTIVE=false  # Set true if using Pi-hole as DHCP
DHCP_START=192.168.1.100
DHCP_END=192.168.1.200
DHCP_ROUTER=192.168.1.1
```

## Official Resources

- **Website:** https://pi-hole.net
- **Documentation:** https://docs.pi-hole.net
- **GitHub:** https://github.com/pi-hole/pi-hole
- **Docker Hub:** https://hub.docker.com/r/pihole/pihole
- **Discourse Forum:** https://discourse.pi-hole.net
- **Reddit:** https://reddit.com/r/pihole
- **Blocklists:** https://firebog.net

## Educational Resources

### Videos
- [Pi-hole - Network-Wide Ad Blocking (NetworkChuck)](https://www.youtube.com/watch?v=KBXTnrD_Zs4)
- [Ultimate Pi-hole Setup Guide (Techno Tim)](https://www.youtube.com/watch?v=FnFtWsZ8IP0)
- [How DNS Works (Explained)](https://www.youtube.com/watch?v=72snZctFFtA)
- [Pi-hole Docker Setup (DB Tech)](https://www.youtube.com/watch?v=NRe2-vye3ik)

### Articles & Guides
- [Pi-hole Official Documentation](https://docs.pi-hole.net)
- [Docker Pi-hole Setup](https://github.com/pi-hole/docker-pi-hole/)
- [Best Blocklists (Firebog)](https://firebog.net)
- [DNS Over HTTPS Setup](https://docs.pi-hole.net/guides/dns/cloudflared/)

### Concepts to Learn
- **DNS (Domain Name System):** Translates domains to IP addresses
- **DNS Sinkhole:** Returns null IP for blocked domains
- **Upstream DNS:** Real DNS servers Pi-hole forwards to
- **Blocklists:** Lists of known ad/tracker domains
- **Regex Filtering:** Pattern-based domain blocking
- **DHCP:** Network device IP assignment
- **DNS Over HTTPS (DoH):** Encrypted DNS queries
- **Local DNS:** Custom local domain resolution

## Docker Configuration

### Complete Service Definition

```yaml
pihole:
  image: pihole/pihole:latest
  container_name: pihole
  restart: unless-stopped
  hostname: pihole
  networks:
    - traefik-network
  ports:
    - "53:53/tcp"      # DNS TCP
    - "53:53/udp"      # DNS UDP
    - "8181:80/tcp"    # Web Interface (remapped to avoid conflict)
    # - "67:67/udp"    # DHCP (optional, uncomment if using)
  volumes:
    - /opt/stacks/infrastructure/pihole/etc-pihole:/etc/pihole
    - /opt/stacks/infrastructure/pihole/etc-dnsmasq.d:/etc/dnsmasq.d
  environment:
    - TZ=America/New_York
    - WEBPASSWORD=${PIHOLE_PASSWORD}
    - PIHOLE_DNS_=1.1.1.1;8.8.8.8
    - WEBTHEME=default-dark
    - VIRTUAL_HOST=pihole.${DOMAIN}
    - DNSMASQ_LISTENING=all
  cap_add:
    - NET_ADMIN  # Required for DHCP functionality
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.pihole.rule=Host(`pihole.${DOMAIN}`)"
    - "traefik.http.routers.pihole.entrypoints=websecure"
    - "traefik.http.routers.pihole.tls.certresolver=letsencrypt"
    - "traefik.http.services.pihole.loadbalancer.server.port=80"
```

### Important Notes

1. **Port 53:** DNS must be on port 53 (cannot be remapped)
2. **Web Port:** Can use 8181 externally, 80 internally
3. **NET_ADMIN:** Required capability for DHCP and network features
4. **Password:** Set strong password via WEBPASSWORD variable

## Setup and Management

### Initial Setup

1. **Deploy Pi-hole:** Start the container
2. **Wait 60 seconds:** Let gravity database build
3. **Access Web UI:** `https://pihole.yourdomain.com/admin`
4. **Login:** Use password from WEBPASSWORD
5. **Configure Router:** Point DNS to Pi-hole server IP

### Router Configuration

**Method 1: DHCP DNS Settings (Recommended)**
1. Access router admin panel
2. Find DHCP settings
3. Set Primary DNS: Pi-hole server IP (e.g., 192.168.1.10)
4. Set Secondary DNS: 1.1.1.1 or 8.8.8.8 (fallback)
5. Save and reboot router

**Method 2: Per-Device Configuration**
- Set DNS manually on each device
- Not recommended for whole-network blocking

### Dashboard Overview

**Main Dashboard Shows:**
- Total queries (last 24h)
- Queries blocked (percentage)
- Blocklist domains count
- Top allowed/blocked domains
- Query types (A, AAAA, PTR, etc.)
- Client activity
- Real-time query log

### Managing Blocklists

**Add Blocklists:**
1. Group Management → Adlists
2. Add list URL
3. Update Gravity (Tools → Update Gravity)

**Popular Blocklists (Firebog):**
```
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://v.firebog.net/hosts/AdguardDNS.txt
https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
```

**Update Gravity:**
```bash
# Via CLI
docker exec pihole pihole -g

# Or Web UI: Tools → Update Gravity
```

### Whitelist/Blacklist

**Whitelist Domain (Allow):**
1. Whitelist → Add domain
2. Example: `example.com`
3. Supports wildcards: `*.example.com`

**Blacklist Domain (Block):**
1. Blacklist → Add domain
2. Example: `ads.example.com`

**Via CLI:**
```bash
# Whitelist
docker exec pihole pihole -w example.com

# Blacklist
docker exec pihole pihole -b ads.example.com

# Regex whitelist
docker exec pihole pihole --regex-whitelist "^example\.com$"

# Regex blacklist
docker exec pihole pihole --regex "^ad[sx]?[0-9]*\..*"
```

### Query Log

**View Queries:**
1. Query Log → See all DNS requests
2. Filter by client, domain, type
3. Whitelist/Blacklist directly from log

**Privacy Modes:**
- Show Everything
- Hide Domains
- Hide Domains and Clients
- Anonymous Mode

## Advanced Topics

### Local DNS Records

Create custom local DNS entries:

**Via Web UI:**
1. Local DNS → DNS Records
2. Add domain → IP mapping
3. Example: `nas.local → 192.168.1.50`

**Via File:**
```bash
# /opt/stacks/infrastructure/pihole/etc-pihole/custom.list
192.168.1.50 nas.local
192.168.1.51 server.local
```

### Group Management

Different blocking rules for different devices:

1. **Create Groups:**
   - Group Management → Groups → Add Group
   - Example: "Kids Devices", "Guest Network"

2. **Assign Clients:**
   - Group Management → Clients → Add client to group

3. **Configure Adlists per Group:**
   - Group Management → Adlists → Assign to groups

### Regex Filtering

Advanced pattern-based blocking:

**Common Patterns:**
```regex
# Block all subdomains of ads.example.com
^ad[sx]?[0-9]*\.example\.com$

# Block tracking parameters
.*\?utm_.*

# Block all Facebook tracking
^(.+[_.-])?facebook\.[a-z]+$
```

**Add Regex:**
1. Domains → Regex Filter
2. Add regex pattern
3. Test with Query Log

### DNS Over HTTPS (DoH)

Encrypt DNS queries to upstream servers:

**Using Cloudflared:**
```yaml
cloudflared:
  image: cloudflare/cloudflared:latest
  container_name: cloudflared
  restart: unless-stopped
  command: proxy-dns
  environment:
    - TUNNEL_DNS_UPSTREAM=https://1.1.1.1/dns-query,https://1.0.0.1/dns-query
    - TUNNEL_DNS_PORT=5053
    - TUNNEL_DNS_ADDRESS=0.0.0.0

pihole:
  environment:
    - PIHOLE_DNS_=cloudflared#5053  # Use cloudflared as upstream
```

### Conditional Forwarding

Forward specific domains to specific DNS:

**Example:** Local domain to local DNS
```bash
# /opt/stacks/infrastructure/pihole/etc-dnsmasq.d/02-custom.conf
server=/local/192.168.1.1
```

### DHCP Server

Use Pi-hole as network DHCP server:

```yaml
environment:
  - DHCP_ACTIVE=true
  - DHCP_START=192.168.1.100
  - DHCP_END=192.168.1.200
  - DHCP_ROUTER=192.168.1.1
  - DHCP_LEASETIME=24
  - PIHOLE_DOMAIN=lan

ports:
  - "67:67/udp"  # DHCP port
```

**Steps:**
1. Disable DHCP on router
2. Enable DHCP in Pi-hole
3. Restart network devices

## Troubleshooting

### Pi-hole Not Blocking Ads

```bash
# Check if Pi-hole is receiving queries
docker logs pihole | grep query

# Verify DNS is set correctly on device
# Windows: ipconfig /all
# Linux/Mac: cat /etc/resolv.conf
# Should show Pi-hole IP

# Test DNS resolution
nslookup ads.google.com PIHOLE_IP
# Should return 0.0.0.0 if blocked

# Check gravity database
docker exec pihole pihole -g
```

### DNS Not Resolving

```bash
# Check if Pi-hole is running
docker ps | grep pihole

# Check DNS ports
sudo netstat -tulpn | grep :53

# Test DNS
dig @PIHOLE_IP google.com

# Check upstream DNS
docker exec pihole pihole -q
```

### Web Interface Not Accessible

```bash
# Check container logs
docker logs pihole

# Verify port mapping
docker port pihole

# Access via IP
http://SERVER_IP:8181/admin

# Check Traefik routing
docker logs traefik | grep pihole
```

### High CPU/Memory Usage

```bash
# Check container stats
docker stats pihole

# Database optimization
docker exec pihole pihole -q database optimize

# Reduce query logging
# Settings → Privacy → Anonymous mode

# Clear old queries
docker exec pihole sqlite3 /etc/pihole/pihole-FTL.db "DELETE FROM queries WHERE timestamp < strftime('%s', 'now', '-7 days')"
```

### False Positives (Sites Broken)

```bash
# Check query log for blocked domains
# Web UI → Query Log → Find blocked domain

# Whitelist domain
docker exec pihole pihole -w problematic-domain.com

# Or via Web UI:
# Whitelist → Add domain

# Common false positives:
# - microsoft.com CDNs
# - google-analytics.com (breaks some sites)
# - doubleclick.net (ad network but some sites need it)
```

### Blocklist Update Issues

```bash
# Manually update gravity
docker exec pihole pihole -g

# Check disk space
df -h

# Clear cache
docker exec pihole pihole -r
# Choose: Repair
```

## Security Best Practices

1. **Strong Password:** Use complex WEBPASSWORD
2. **Authelia Protection:** Add Authelia middleware for external access
3. **Firewall Rules:** Only expose port 53 as needed
4. **Update Regularly:** Keep Pi-hole container updated
5. **Backup Config:** Regular backups of `/etc/pihole` directory
6. **Query Privacy:** Enable privacy mode for sensitive networks
7. **Upstream DNS:** Use privacy-focused DNS (Quad9, Cloudflare)
8. **Monitor Logs:** Watch for unusual query patterns
9. **Network Segmentation:** Separate IoT devices
10. **HTTPS Only:** Use HTTPS for web interface access

## Performance Optimization

```yaml
environment:
  # Increase cache size
  - CACHE_SIZE=10000
  
  # Disable query logging (improves performance)
  - QUERY_LOGGING=false
  
  # Optimize DNS settings
  - DNSSEC=false  # Disable if not needed
```

**Database Maintenance:**
```bash
# Optimize database weekly
docker exec pihole sqlite3 /etc/pihole/pihole-FTL.db "VACUUM"

# Clear old queries (keep 7 days)
docker exec pihole pihole -f
```

## Backup and Restore

### Backup

**Via Web UI:**
1. Settings → Teleporter
2. Click "Backup"
3. Download tar.gz file

**Via CLI:**
```bash
# Backup entire config
tar -czf pihole-backup-$(date +%Y%m%d).tar.gz /opt/stacks/infrastructure/pihole/

# Backup only settings
docker exec pihole pihole -a -t
```

### Restore

**Via Web UI:**
1. Settings → Teleporter
2. Choose file
3. Click "Restore"

**Via CLI:**
```bash
# Restore from backup
tar -xzf pihole-backup-20240112.tar.gz -C /opt/stacks/infrastructure/pihole/
docker restart pihole
```

## Summary

Pi-hole provides network-wide ad blocking by acting as a DNS server that filters requests before they reach the internet. It:
- Blocks ads on all devices automatically
- Improves browsing speed and privacy
- Provides visibility into network DNS queries
- Offers extensive customization
- Protects against malware and tracking

**Setup Priority:**
1. Deploy Pi-hole container
2. Set strong admin password
3. Configure router DNS settings
4. Add blocklists (Firebog)
5. Monitor dashboard
6. Whitelist as needed
7. Configure DoH for privacy
8. Regular backups

**Remember:**
- DNS is critical - test thoroughly before deploying
- Keep secondary DNS as fallback
- Some sites may break - use whitelist
- Monitor query log initially
- Update gravity weekly
- Backup before major changes
