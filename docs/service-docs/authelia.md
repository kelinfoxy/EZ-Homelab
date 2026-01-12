# Authelia - Single Sign-On & Two-Factor Authentication

## Table of Contents
- [Overview](#overview)
- [What is Authelia?](#what-is-authelia)
- [Why Use Authelia?](#why-use-authelia)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [User Management](#user-management)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Core Infrastructure  
**Docker Image:** [authelia/authelia](https://hub.docker.com/r/authelia/authelia)  
**Default Stack:** `core.yml`  
**Web UI:** `https://auth.${DOMAIN}`  
**Authentication:** Self-authenticating (login portal)

## What is Authelia?

Authelia is an open-source authentication and authorization server providing single sign-on (SSO) and two-factor authentication (2FA) for your applications via a web portal. It acts as a gatekeeper between Traefik and your services.

### Key Features
- **Single Sign-On (SSO):** Log in once, access all protected services
- **Two-Factor Authentication:** TOTP (Google Authenticator, Authy), WebAuthn, Security Keys
- **Access Control:** Per-service, per-user, per-network rules
- **Session Management:** Remember devices, revoke sessions
- **Identity Verification:** Email verification for password resets
- **Security Policies:** Custom policies per service (one_factor, two_factor, bypass)
- **Lightweight:** Minimal resource usage
- **Integration:** Works seamlessly with Traefik via ForwardAuth

## Why Use Authelia?

1. **Enhanced Security:** Add 2FA to services that don't support it natively
2. **Centralized Authentication:** One login portal for all services
3. **Granular Access Control:** Control who can access what
4. **Remember Devices:** Don't re-authenticate on trusted devices
5. **Protection Layer:** Extra security even if a service has vulnerabilities
6. **Free & Open Source:** No licensing costs
7. **Privacy:** Self-hosted, your data stays with you

## How It Works

```
User → Traefik → Authelia (Check Auth) → Service
                    ↓
              Not Authenticated
                    ↓
              Login Portal
                    ↓
            Username/Password
                    ↓
              2FA (TOTP/WebAuthn)
                    ↓
              Cookie Issued
                    ↓
            Access Granted
```

### Authentication Flow

1. **User accesses** `https://sonarr.yourdomain.com`
2. **Traefik** sends request to Authelia (ForwardAuth middleware)
3. **Authelia checks** for valid authentication cookie
4. **If not authenticated:**
   - Redirects to `https://auth.yourdomain.com`
   - User enters username/password
   - User completes 2FA challenge
   - Authelia issues authentication cookie
5. **If authenticated:**
   - Authelia checks access control rules
   - If authorized, request forwarded to service
6. **Session remembered** for configured duration

### Integration with Traefik

Services protected by Authelia use a special middleware:

```yaml
labels:
  - "traefik.http.routers.sonarr.middlewares=authelia@docker"
```

This tells Traefik to verify authentication before allowing access.

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/core/authelia/
├── configuration.yml    # Main configuration
├── users_database.yml   # User accounts and passwords
└── db.sqlite3          # Session/TOTP storage (auto-generated)
```

### Main Configuration (`configuration.yml`)

```yaml
server:
  host: 0.0.0.0
  port: 9091

log:
  level: info

theme: dark

totp:
  issuer: yourdomain.com

authentication_backend:
  file:
    path: /config/users_database.yml
    password:
      algorithm: argon2id
      iterations: 1
      salt_length: 16
      parallelism: 8
      memory: 64

access_control:
  default_policy: deny
  
  rules:
    # Bypass auth for public services
    - domain: "public.yourdomain.com"
      policy: bypass
    
    # One-factor for internal networks
    - domain: "*.yourdomain.com"
      policy: one_factor
      networks:
        - 192.168.1.0/24
    
    # Two-factor for everything else
    - domain: "*.yourdomain.com"
      policy: two_factor

session:
  name: authelia_session
  domain: yourdomain.com
  expiration: 1h
  inactivity: 5m
  remember_me_duration: 1M

regulation:
  max_retries: 5
  find_time: 10m
  ban_time: 15m

storage:
  local:
    path: /config/db.sqlite3

notifier:
  filesystem:
    filename: /config/notification.txt
  # Alternative: SMTP for email notifications
  # smtp:
  #   username: your-email@gmail.com
  #   password: your-app-password
  #   host: smtp.gmail.com
  #   port: 587
  #   sender: your-email@gmail.com
```

### Users Database (`users_database.yml`)

```yaml
users:
  john:
    displayname: "John Doe"
    password: "$argon2id$v=19$m=65536,t=3,p=4$BpLnfgDsc2WD8F2q$qQv8kuZHAOhqx7/Ju3qNqawhKhh9q9L6KUXCv7RQ0MA"
    email: john@example.com
    groups:
      - admins
      - users
  
  jane:
    displayname: "Jane Smith"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: jane@example.com
    groups:
      - users
```

### Generating Password Hashes

```bash
# Using Docker
docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'YourPasswordHere'

# Or from within the container
docker exec -it authelia authelia crypto hash generate argon2 --password 'YourPasswordHere'
```

### Environment Variables

```bash
AUTHELIA_JWT_SECRET=your-super-secret-jwt-key-min-32-chars
AUTHELIA_SESSION_SECRET=your-super-secret-session-key-min-32-chars
AUTHELIA_STORAGE_ENCRYPTION_KEY=your-super-secret-storage-key-min-32-chars
```

**Generate secure secrets:**
```bash
# Generate random 64-character hex strings
openssl rand -hex 32
```

## Official Resources

- **Website:** https://www.authelia.com
- **Documentation:** https://www.authelia.com/docs/
- **GitHub:** https://github.com/authelia/authelia
- **Docker Hub:** https://hub.docker.com/r/authelia/authelia
- **Community:** https://discord.authelia.com
- **Configuration Examples:** https://github.com/authelia/authelia/tree/master/examples

## Educational Resources

### Videos
- [Authelia - The BEST Authentication Platform (Techno Tim)](https://www.youtube.com/watch?v=u6H-Qwf4nZA)
- [Secure Your Self-Hosted Apps with Authelia (DB Tech)](https://www.youtube.com/watch?v=4UKOh3ssQSU)
- [Authelia Setup with Traefik (Wolfgang's Channel)](https://www.youtube.com/watch?v=g7oUvxGqvPw)
- [Two-Factor Authentication Explained](https://www.youtube.com/watch?v=0mvCeNsTa1g)

### Articles & Guides
- [Authelia Official Documentation](https://www.authelia.com/docs/)
- [Integration with Traefik](https://www.authelia.com/integration/proxies/traefik/)
- [Access Control Configuration](https://www.authelia.com/configuration/security/access-control/)
- [Migration from Organizr/Authelia v3](https://www.authelia.com/docs/configuration/migration.html)

### Concepts to Learn
- **Single Sign-On (SSO):** Authentication once for multiple applications
- **Two-Factor Authentication (2FA):** Second verification method (TOTP, WebAuthn)
- **TOTP:** Time-based One-Time Password (Google Authenticator)
- **WebAuthn:** Web Authentication standard (Yubikey, Touch ID)
- **ForwardAuth:** Proxy authentication delegation
- **LDAP:** Lightweight Directory Access Protocol (user directories)
- **Session Management:** Cookie-based authentication tracking
- **Argon2:** Modern password hashing algorithm

## Docker Configuration

### Complete Service Definition

```yaml
authelia:
  image: authelia/authelia:latest
  container_name: authelia
  restart: unless-stopped
  networks:
    - traefik-network
  volumes:
    - /opt/stacks/core/authelia:/config
  environment:
    - TZ=America/New_York
    - AUTHELIA_JWT_SECRET=${AUTHELIA_JWT_SECRET}
    - AUTHELIA_SESSION_SECRET=${AUTHELIA_SESSION_SECRET}
    - AUTHELIA_STORAGE_ENCRYPTION_KEY=${AUTHELIA_STORAGE_ENCRYPTION_KEY}
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.authelia.rule=Host(`auth.${DOMAIN}`)"
    - "traefik.http.routers.authelia.entrypoints=websecure"
    - "traefik.http.routers.authelia.tls.certresolver=letsencrypt"
    
    # ForwardAuth Middleware
    - "traefik.http.middlewares.authelia.forwardAuth.address=http://authelia:9091/api/verify?rd=https://auth.${DOMAIN}"
    - "traefik.http.middlewares.authelia.forwardAuth.trustForwardHeader=true"
    - "traefik.http.middlewares.authelia.forwardAuth.authResponseHeaders=Remote-User,Remote-Groups,Remote-Name,Remote-Email"
```

### Protecting Services

Add the Authelia middleware to any service:

```yaml
myservice:
  image: myapp:latest
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.myservice.rule=Host(`myservice.${DOMAIN}`)"
    - "traefik.http.routers.myservice.entrypoints=websecure"
    - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
    - "traefik.http.routers.myservice.middlewares=authelia@docker"  # <-- Add this
  networks:
    - traefik-network
```

## User Management

### Adding Users

1. **Generate password hash:**
   ```bash
   docker exec -it authelia authelia crypto hash generate argon2 --password 'SecurePassword123!'
   ```

2. **Add to `users_database.yml`:**
   ```yaml
   users:
     newuser:
       displayname: "New User"
       password: "$argon2id$v=19$m=65536..."  # Paste hash here
       email: newuser@example.com
       groups:
         - users
   ```

3. **Restart Authelia:**
   ```bash
   docker restart authelia
   ```

### Removing Users

Simply remove the user block from `users_database.yml` and restart.

### Resetting Passwords

Generate a new hash and replace the password field, then restart Authelia.

### Group-Based Access Control

```yaml
access_control:
  rules:
    # Only admins can access admin panel
    - domain: "admin.yourdomain.com"
      policy: two_factor
      subject:
        - "group:admins"
    
    # Users can access media services
    - domain:
        - "plex.yourdomain.com"
        - "jellyfin.yourdomain.com"
      policy: one_factor
      subject:
        - "group:users"
```

## Advanced Topics

### SMTP Email Notifications

Configure email for password resets and notifications:

```yaml
notifier:
  smtp:
    username: your-email@gmail.com
    password: your-app-password  # Use app-specific password
    host: smtp.gmail.com
    port: 587
    sender: your-email@gmail.com
    subject: "[Authelia] {title}"
```

### LDAP Authentication

For advanced setups with Active Directory or FreeIPA:

```yaml
authentication_backend:
  ldap:
    url: ldap://ldap.example.com
    base_dn: dc=example,dc=com
    username_attribute: uid
    additional_users_dn: ou=users
    users_filter: (&({username_attribute}={input})(objectClass=person))
    additional_groups_dn: ou=groups
    groups_filter: (&(member={dn})(objectClass=groupOfNames))
    user: cn=admin,dc=example,dc=com
    password: admin-password
```

### Per-Service Policies

```yaml
access_control:
  rules:
    # Public services (no auth)
    - domain: "public.yourdomain.com"
      policy: bypass
    
    # Internal network only (one factor)
    - domain: "internal.yourdomain.com"
      policy: one_factor
      networks:
        - 192.168.1.0/24
    
    # High security (two factor required)
    - domain:
        - "banking.yourdomain.com"
        - "finance.yourdomain.com"
      policy: two_factor
```

### Network-Based Rules

```yaml
access_control:
  rules:
    # Bypass for local network
    - domain: "*.yourdomain.com"
      policy: bypass
      networks:
        - 192.168.1.0/24
        - 172.16.0.0/12
    
    # Require 2FA from external networks
    - domain: "*.yourdomain.com"
      policy: two_factor
```

### Custom Session Duration

```yaml
session:
  expiration: 12h        # Session expires after 12 hours
  inactivity: 30m        # Session expires after 30 min inactivity
  remember_me_duration: 1M  # Remember device for 1 month
```

## Troubleshooting

### Cannot Access Login Portal

```bash
# Check if Authelia is running
docker ps | grep authelia

# View logs
docker logs authelia

# Check configuration syntax
docker exec authelia authelia validate-config /config/configuration.yml

# Test connectivity
curl http://localhost:9091/api/health
```

### Services Not Requiring Authentication

```bash
# Verify middleware is applied
docker inspect service-name | grep authelia

# Check Traefik dashboard for middleware
# Visit: https://traefik.yourdomain.com

# Verify Authelia middleware definition
docker logs traefik | grep authelia

# Test ForwardAuth directly
curl -I -H "Host: service.yourdomain.com" http://authelia:9091/api/verify
```

### Login Not Working

```bash
# Check users_database.yml syntax
docker exec authelia cat /config/users_database.yml

# Verify password hash
docker exec authelia authelia crypto hash validate argon2 --password 'YourPassword' --hash '$argon2id...'

# Check logs for authentication attempts
docker logs authelia | grep -i auth

# Verify JWT and session secrets are set
docker exec authelia env | grep SECRET
```

### 2FA Not Working

```bash
# Check TOTP configuration
docker exec authelia cat /config/configuration.yml | grep -A5 totp

# Verify time synchronization (critical for TOTP)
docker exec authelia date
date  # Compare with host

# Check TOTP database
sqlite3 /opt/stacks/core/authelia/db.sqlite3 "SELECT * FROM totp_configurations;"

# Reset 2FA for user (delete TOTP entry)
sqlite3 /opt/stacks/core/authelia/db.sqlite3 "DELETE FROM totp_configurations WHERE username='username';"
```

### Session Issues

```bash
# Check session configuration
docker exec authelia cat /config/configuration.yml | grep -A10 session

# Clear session database
sqlite3 /opt/stacks/core/authelia/db.sqlite3 "DELETE FROM user_sessions;"

# Verify domain matches
# session.domain should match your base domain
# Example: session.domain: yourdomain.com
#          Services: *.yourdomain.com
```

### Configuration Validation

```bash
# Validate full configuration
docker exec authelia authelia validate-config /config/configuration.yml

# Check for common issues
docker logs authelia | grep -i error
docker logs authelia | grep -i warn
```

## Security Best Practices

1. **Strong Secrets:** Use 32+ character random secrets for JWT, session, and storage encryption
2. **Enable 2FA:** Require two-factor for external access
3. **Network Policies:** Use bypass for trusted networks, two_factor for internet
4. **Session Management:** Set appropriate expiration and inactivity timeouts
5. **Regular Updates:** Keep Authelia updated for security patches
6. **Email Notifications:** Configure SMTP for password reset security
7. **Backup:** Regularly backup `users_database.yml` and `db.sqlite3`
8. **Rate Limiting:** Configure `regulation` to prevent brute force
9. **Log Monitoring:** Review logs for failed authentication attempts
10. **Use HTTPS Only:** Never expose Authelia over plain HTTP

## Common Use Cases

### Home Access (No Auth)

```yaml
- domain: "*.yourdomain.com"
  policy: bypass
  networks:
    - 192.168.1.0/24
```

### Friends & Family (One Factor)

```yaml
- domain:
    - "plex.yourdomain.com"
    - "jellyfin.yourdomain.com"
  policy: one_factor
```

### Admin Services (Two Factor)

```yaml
- domain:
    - "dockge.yourdomain.com"
    - "portainer.yourdomain.com"
  policy: two_factor
  subject:
    - "group:admins"
```

### VPN Required

```yaml
- domain: "admin.yourdomain.com"
  policy: bypass
  networks:
    - 10.8.0.0/24  # Gluetun VPN network
```

## Summary

Authelia is your homelab's security layer. It:
- Adds authentication to any service
- Provides SSO across all applications
- Enables 2FA even for services that don't support it
- Offers granular access control
- Protects against unauthorized access
- Integrates seamlessly with Traefik

Setting up Authelia properly is one of the most important security steps for your homelab. Take time to understand access control rules and test your configuration thoroughly. Always keep the `users_database.yml` and `db.sqlite3` backed up, as they contain critical authentication data.
