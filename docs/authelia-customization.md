# Authelia Customization Guide

This guide covers how to customize Authelia for your specific needs.

## Available Customization Options

### 1. Branding and Appearance
Edit `/opt/stacks/core/authelia/configuration.yml`:

```yaml
# Custom logo and branding
theme: dark  # Options: light, dark, grey, auto

# No built-in web UI for configuration
# All settings managed via YAML files
```

### 2. User Management
Users are managed in `/opt/stacks/core/authelia/users_database.yml`:

```yaml
users:
  username:
    displayname: "Display Name"
    password: "$argon2id$v=19$m=65536..." # Generated with authelia hash-password
    email: user@example.com
    groups:
      - admins
      - users
```

Generate password hash:
```bash
docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password 'yourpassword'
```

### 3. Access Control Rules
Customize who can access what in `configuration.yml`:

```yaml
access_control:
  default_policy: deny
  
  rules:
    # Public services (no auth)
    - domain:
        - "jellyfin.yourdomain.com"
        - "plex.yourdomain.com"
      policy: bypass
    
    # Admin only services
    - domain:
        - "dockge.yourdomain.com"
        - "portainer.yourdomain.com"
      policy: two_factor
      subject:
        - "group:admins"
    
    # All authenticated users
    - domain: "*.yourdomain.com"
      policy: one_factor
```

### 4. Two-Factor Authentication (2FA)
- TOTP (Time-based One-Time Password) via apps like Google Authenticator, Authy
- Configure in `configuration.yml` under `totp:` section
- Per-user enrollment via Authelia UI at `https://auth.${DOMAIN}`

### 5. Session Management
Edit `configuration.yml`:

```yaml
session:
  name: authelia_session
  expiration: 1h  # How long before re-login required
  inactivity: 5m  # Timeout after inactivity
  remember_me_duration: 1M  # "Remember me" checkbox duration
```

### 6. Notification Settings
Email notifications for password resets, 2FA enrollment:

```yaml
notifier:
  smtp:
    host: smtp.gmail.com
    port: 587
    username: your-email@gmail.com
    password: app-password
    sender: authelia@yourdomain.com
```

## No Web UI for Configuration

⚠️ **Important**: Authelia does **not** have a configuration web UI. All configuration is done via YAML files:
- `/opt/stacks/core/authelia/configuration.yml` - Main settings
- `/opt/stacks/core/authelia/users_database.yml` - User accounts

This is **by design** and makes Authelia perfect for AI management and security-first approach:
- AI can read and modify YAML files
- Version control friendly
- No UI clicks required
- Infrastructure as code
- Secure by default

**Web UI Available For:**
- Login page: `https://auth.${DOMAIN}`
- User profile: Change password, enroll 2FA
- Device enrollment: Manage trusted devices

## Alternative with Web UI: Authentik

If you need a web UI for user management, Authentik is included in the infrastructure stack:
- **Authentik**: Full-featured SSO with web UI for user/group management
- Access at: `https://authentik.${DOMAIN}`
- Includes PostgreSQL database and Redis cache
- More complex but offers GUI-based configuration
- Deploy only if you need web-based user management

**Other Alternatives:**
- **Keycloak**: Enterprise-grade SSO with web UI
- **Authelia + LDAP**: Use LDAP with web management (phpLDAPadmin, etc.)

## Quick Configuration with AI

Since all Authelia configuration is file-based, you can use the AI assistant to:
- Add/remove users
- Modify access rules
- Change session settings
- Update branding
- Enable/disable features

Just ask: "Add a new user to Authelia" or "Change session timeout to 2 hours"

## Common Customizations

### Adding a New User

1. Generate password hash:
```bash
docker run --rm authelia/authelia:4.37 authelia crypto hash generate argon2 --password 'newuserpassword'
```

2. Edit `/opt/stacks/core/authelia/users_database.yml`:
```yaml
users:
  admin:
    # existing admin user...
  
  newuser:
    displayname: "New User"
    password: "$argon2id$v=19$m=65536..." # paste generated hash
    email: newuser@example.com
    groups:
      - users
```

3. Restart Authelia:
```bash
cd /opt/stacks/core
docker compose restart authelia
```

### Bypass SSO for Specific Service

Edit the service's Traefik labels to remove the Authelia middleware:

```yaml
# Before (SSO protected)
labels:
  - "traefik.http.routers.service.middlewares=authelia@docker"

# After (bypass SSO)
labels:
  # - "traefik.http.routers.service.middlewares=authelia@docker"  # commented out
```

### Change Session Timeout

Edit `/opt/stacks/core/authelia/configuration.yml`:
```yaml
session:
  expiration: 12h  # Changed from 1h to 12h
  inactivity: 30m  # Changed from 5m to 30m
```

Restart Authelia to apply changes.

### Enable SMTP Notifications

Edit `/opt/stacks/core/authelia/configuration.yml`:
```yaml
notifier:
  smtp:
    host: smtp.gmail.com
    port: 587
    username: your-email@gmail.com
    password: your-app-password  # Use app-specific password
    sender: authelia@yourdomain.com
    subject: "[Authelia] {title}"
```

### Create Admin-Only Access Rule

Edit `/opt/stacks/core/authelia/configuration.yml`:
```yaml
access_control:
  rules:
    # Admin-only services
    - domain:
        - "dockge.yourdomain.duckdns.org"
        - "traefik.yourdomain.duckdns.org"
        - "portainer.yourdomain.duckdns.org"
      policy: two_factor
      subject:
        - "group:admins"
    
    # All other services - any authenticated user
    - domain: "*.yourdomain.duckdns.org"
      policy: one_factor
```

Restart Authelia after changes.

## Troubleshooting

### User Can't Log In

1. Check password hash format in users_database.yml
2. Verify email address matches
3. Check Authelia logs: `docker logs authelia`

### 2FA Not Working

1. Ensure time sync on server: `timedatectl`
2. Check TOTP configuration in configuration.yml
3. Regenerate QR code for user

### Sessions Expire Too Quickly

Increase session expiration in configuration.yml:
```yaml
session:
  expiration: 24h
  inactivity: 1h
```

### Can't Access Specific Service

Check access control rules - service domain may be blocked by default_policy: deny

## Additional Resources

- [Authelia Documentation](https://www.authelia.com/docs/)
- [Authelia Service Docs](service-docs/authelia.md)
- [Getting Started Guide](getting-started.md)
