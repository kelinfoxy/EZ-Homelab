# Vaultwarden - Password Manager

## Table of Contents
- [Overview](#overview)
- [What is Vaultwarden?](#what-is-vaultwarden)
- [Why Use Vaultwarden?](#why-use-vaultwarden)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Setup](#setup)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Password Management  
**Docker Image:** [vaultwarden/server](https://hub.docker.com/r/vaultwarden/server)  
**Default Stack:** `utilities.yml`  
**Web UI:** `https://vaultwarden.${DOMAIN}` or `http://SERVER_IP:8343`  
**Client Apps:** Bitwarden apps (iOS, Android, desktop, browser extensions)  
**Ports:** 8343

## What is Vaultwarden?

Vaultwarden (formerly Bitwarden_RS) is an unofficial Bitwarden server implementation written in Rust. It's fully compatible with official Bitwarden clients but designed for self-hosting with much lower resource requirements. Store all your passwords, credit cards, secure notes, and identities encrypted on your own server.

### Key Features
- **Bitwarden Compatible:** Use official apps
- **End-to-End Encryption:** Zero-knowledge
- **Cross-Platform:** Windows, Mac, Linux, iOS, Android
- **Browser Extensions:** Chrome, Firefox, Safari, Edge
- **Password Generator:** Strong password creation
- **2FA Support:** TOTP, U2F, Duo
- **Secure Notes:** Encrypted notes storage
- **File Attachments:** Store encrypted files
- **Collections:** Organize passwords
- **Organizations:** Family/team sharing
- **Low Resource:** <100MB RAM
- **Free & Open Source:** No premium required

## Why Use Vaultwarden?

1. **Self-Hosted:** Control your passwords
2. **Free Premium Features:** All features included
3. **Privacy:** Passwords never leave your server
4. **Zero-Knowledge:** Only you can decrypt
5. **Lightweight:** Runs on anything
6. **Bitwarden Apps:** Use official clients
7. **Family Sharing:** Free organizations
8. **Open Source:** Auditable security

## Configuration in AI-Homelab

```
/opt/stacks/utilities/vaultwarden/data/
  db.sqlite3          # Password database (encrypted)
  attachments/        # File attachments
  sends/             # Bitwarden Send files
  config.json        # Configuration
```

## Official Resources

- **GitHub:** https://github.com/dani-garcia/vaultwarden
- **Wiki:** https://github.com/dani-garcia/vaultwarden/wiki
- **Bitwarden Apps:** https://bitwarden.com/download/

## Educational Resources

### YouTube Videos
1. **Techno Tim - Vaultwarden Setup**
   - https://www.youtube.com/watch?v=yzjgD3hIPtE
   - Complete setup guide
   - Browser extension configuration
   - Organization setup

2. **DB Tech - Bitwarden RS (Vaultwarden)**
   - https://www.youtube.com/watch?v=2IceFM4BZqk
   - Docker deployment
   - App configuration
   - Security best practices

3. **Wolfgang's Channel - Vaultwarden Security**
   - https://www.youtube.com/watch?v=ViR021iiR5Y
   - Security hardening
   - 2FA setup
   - Backup strategies

### Articles
1. **Official Wiki:** https://github.com/dani-garcia/vaultwarden/wiki
2. **Comparison:** https://github.com/dani-garcia/vaultwarden/wiki/Which-container-image-to-use

## Docker Configuration

```yaml
vaultwarden:
  image: vaultwarden/server:latest
  container_name: vaultwarden
  restart: unless-stopped
  networks:
    - traefik-network
  ports:
    - "8343:80"
  environment:
    - DOMAIN=https://vaultwarden.${DOMAIN}
    - SIGNUPS_ALLOWED=true  # Disable after creating accounts
    - INVITATIONS_ALLOWED=true
    - SHOW_PASSWORD_HINT=false
    - WEBSOCKET_ENABLED=true
    - SENDS_ALLOWED=true
    - EMERGENCY_ACCESS_ALLOWED=true
  volumes:
    - /opt/stacks/utilities/vaultwarden/data:/data
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.vaultwarden.rule=Host(`vaultwarden.${DOMAIN}`)"
    - "traefik.http.routers.vaultwarden.entrypoints=websecure"
    - "traefik.http.routers.vaultwarden.tls.certresolver=letsencrypt"
    - "traefik.http.services.vaultwarden.loadbalancer.server.port=80"
```

## Setup

1. **Start Container:**
   ```bash
   docker compose up -d vaultwarden
   ```

2. **Access Web Vault:** `https://vaultwarden.yourdomain.com`

3. **Create Account:**
   - Click "Create Account"
   - Email (for account identification)
   - Strong master password (REMEMBER THIS!)
   - Master password cannot be recovered!
   - Hint (optional, stored in server)

4. **Disable Public Signups:**
   After creating accounts, edit docker-compose.yml:
   ```yaml
   - SIGNUPS_ALLOWED=false
   ```
   Then: `docker compose up -d vaultwarden`

5. **Setup Browser Extension:**
   - Install Bitwarden extension
   - Settings → Server URL → Custom
   - `https://vaultwarden.yourdomain.com`
   - Log in with your account

6. **Setup Mobile Apps:**
   - Download Bitwarden app
   - Before login, tap settings gear
   - Server URL → Custom
   - `https://vaultwarden.yourdomain.com`
   - Log in

7. **Enable 2FA (Recommended):**
   - Web Vault → Settings → Two-step Login
   - Authenticator App (Free) or
   - Duo, YubiKey, Email (all free in Vaultwarden)
   - Scan QR code with authenticator
   - Save recovery code!

## Troubleshooting

### Can't Connect from Apps

```bash
# Check domain is set
docker exec vaultwarden cat /data/config.json | grep domain

# Verify HTTPS working
curl -I https://vaultwarden.yourdomain.com

# Check logs
docker logs vaultwarden | tail -20
```

### Forgot Master Password

**There is NO recovery!** Master password cannot be reset. Your vault is encrypted with your master password. Without it, the data cannot be decrypted.

**Prevention:**
- Write master password somewhere safe
- Use a memorable but strong passphrase
- Consider password hint (stored on server)
- Print recovery codes for 2FA

### Websocket Issues

```bash
# Ensure websocket enabled
docker inspect vaultwarden | grep WEBSOCKET

# Should show: WEBSOCKET_ENABLED=true
```

### Backup Vault

```bash
# Stop container
docker stop vaultwarden

# Backup data directory
tar -czf vaultwarden-backup-$(date +%Y%m%d).tar.gz \
  /opt/stacks/utilities/vaultwarden/data/

# Start container
docker start vaultwarden

# Or use Backrest (default) for automatic backups
```

## Summary

Vaultwarden is your self-hosted password manager offering:
- Bitwarden-compatible server
- All premium features free
- End-to-end encryption
- Cross-platform apps
- Browser extensions
- Family/team organizations
- Secure note storage
- File attachments
- Very lightweight
- Free and open-source

**Perfect for:**
- Password management
- Family password sharing
- Self-hosted security
- Privacy-conscious users
- Replacing LastPass/1Password
- Secure note storage

**Key Points:**
- Compatible with Bitwarden clients
- Master password CANNOT be recovered
- Disable signups after creating accounts
- Enable 2FA for security
- Regular backups critical
- Set custom server URL in apps
- HTTPS required for full functionality

**Remember:**
- Master password = cannot recover
- Write it down somewhere safe
- Enable 2FA immediately
- Disable public signups
- Regular backups essential
- Use official Bitwarden apps
- HTTPS required for apps

Vaultwarden gives you control of your passwords!
