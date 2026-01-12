# Authentik - Identity Provider & SSO Platform

## Table of Contents
- [Overview](#overview)
- [What is Authentik?](#what-is-authentik)
- [Why Use Authentik?](#why-use-authentik)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Initial Setup](#initial-setup)
- [User Management](#user-management)
- [Application Integration](#application-integration)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Infrastructure / Authentication (Alternative to Authelia)  
**Docker Images:**
- `ghcr.io/goauthentik/server` (Main server + worker)
- `postgres:12-alpine` (Database)
- `redis:alpine` (Cache)  
**Default Stack:** `infrastructure.yml`  
**Web UI:** `https://authentik.${DOMAIN}`  
**Authentication:** Self-authenticating (creates own login portal)  
**Components:** 4-service architecture (server, worker, database, cache)

## What is Authentik?

Authentik is an open-source Identity Provider (IdP) focused on flexibility and versatility. It provides Single Sign-On (SSO), OAuth2, SAML, LDAP, and more through an intuitive web interface. Unlike Authelia's file-based configuration, Authentik is fully managed through its GUI.

### Key Features
- **Multiple Protocols:** OAuth2, OIDC, SAML, LDAP, Proxy
- **Web-Based Configuration:** No file editing required
- **User Portal:** Self-service user dashboard
- **Policy Engine:** Flexible, rule-based access control
- **Flow Designer:** Visual authentication flow builder
- **Multi-Factor Auth:** TOTP, WebAuthn, Duo, SMS
- **LDAP Provider:** Act as LDAP server for legacy apps
- **User Self-Service:** Password reset, profile management, 2FA setup
- **Groups & Roles:** Hierarchical permission management
- **Branding:** Custom themes, logos, colors
- **Admin Interface:** Comprehensive management dashboard
- **Event Logging:** Detailed audit trails

## Why Use Authentik?

### Authentik vs Authelia

**Use Authentik if you want:**
- ✅ GUI-based configuration (no YAML editing)
- ✅ SAML support (not in Authelia)
- ✅ LDAP server functionality
- ✅ User self-service portal
- ✅ Visual flow designer
- ✅ More complex authentication flows
- ✅ OAuth2/OIDC provider for external apps
- ✅ Enterprise features (groups, roles, policies)

**Use Authelia if you want:**
- ✅ Simpler, lighter weight
- ✅ File-based configuration (GitOps friendly)
- ✅ Minimal resource usage
- ✅ Faster setup for basic use cases
- ✅ No database required

### Common Use Cases

1. **SSO for Homelab:** Single login for all services
2. **LDAP for Legacy Apps:** Provide LDAP to apps that need it
3. **OAuth Provider:** Act as identity provider for custom apps
4. **Self-Service Portal:** Let users manage their own accounts
5. **Advanced Policies:** Complex access control rules
6. **SAML Federation:** Integrate with enterprise systems
7. **User Management:** GUI for managing users and groups

## How It Works

```
User → Browser → Authentik (SSO Portal)
                     ↓
              Authentication Flow
           (Password + 2FA + Policies)
                     ↓
              Token/Session Issued
                     ↓
         ┌──────────────┴──────────────┐
         ↓                              ↓
    Forward Auth                    OAuth/SAML
    (Traefik)                       (Applications)
         ↓                              ↓
    Your Services              External Applications
```

### Component Architecture

```
┌─────────────────────────────────────────────┐
│         Authentik Server (Port 9000)        │
│  - Web UI                                   │
│  - API                                      │
│  - Auth endpoints                           │
│  - Forward auth provider                    │
└───────────┬─────────────────────────────────┘
            ↓
┌───────────┴─────────────────────────────────┐
│      Authentik Worker (Background)          │
│  - Scheduled tasks                          │
│  - Email notifications                      │
│  - Policy evaluation                        │
│  - LDAP sync                                │
└───────────┬─────────────────────────────────┘
            ↓
┌───────────┴─────────────────────────────────┐
│      PostgreSQL Database                    │
│  - User accounts                            │
│  - Applications                             │
│  - Flows and stages                         │
│  - Policies and rules                       │
└───────────┬─────────────────────────────────┘
            ↓
┌───────────┴─────────────────────────────────┐
│           Redis Cache                       │
│  - Sessions                                 │
│  - Cache                                    │
│  - Rate limiting                            │
└─────────────────────────────────────────────┘
```

### Authentication Flow

1. **User accesses** protected service
2. **Traefik forwards** to Authentik
3. **Authentik checks** session cookie
4. **If not authenticated:**
   - Redirect to Authentik login
   - User enters credentials
   - Multi-factor authentication (if enabled)
   - Policy evaluation
   - Session created
5. **If authenticated:**
   - Check authorization policies
   - Grant or deny access
6. **User accesses** service

## Configuration in AI-Homelab

### Directory Structure

```
/opt/stacks/infrastructure/authentik/
├── media/              # User-uploaded files, branding
├── custom-templates/   # Custom email templates
├── certs/             # Custom SSL certificates (optional)
└── backups/           # Database backups
```

### Environment Variables

```bash
# PostgreSQL Database
POSTGRES_USER=authentik
POSTGRES_PASSWORD=secure-database-password-here
POSTGRES_DB=authentik

# Authentik Configuration
AUTHENTIK_SECRET_KEY=long-random-secret-key-min-50-chars
AUTHENTIK_ERROR_REPORTING__ENABLED=false

# Email (Optional but recommended)
AUTHENTIK_EMAIL__HOST=smtp.gmail.com
AUTHENTIK_EMAIL__PORT=587
AUTHENTIK_EMAIL__USERNAME=your-email@gmail.com
AUTHENTIK_EMAIL__PASSWORD=your-app-password
AUTHENTIK_EMAIL__USE_TLS=true
AUTHENTIK_EMAIL__FROM=authentik@yourdomain.com

# Redis
AUTHENTIK_REDIS__HOST=authentik-redis
AUTHENTIK_REDIS__PORT=6379

# PostgreSQL Connection
AUTHENTIK_POSTGRESQL__HOST=authentik-db
AUTHENTIK_POSTGRESQL__NAME=authentik
AUTHENTIK_POSTGRESQL__USER=authentik
AUTHENTIK_POSTGRESQL__PASSWORD=secure-database-password-here

# Optional: Disable password policy
AUTHENTIK_PASSWORD_MINIMUM_LENGTH=8

# Optional: Log level
AUTHENTIK_LOG_LEVEL=info
```

**Generate Secret Key:**
```bash
openssl rand -hex 50
```

## Official Resources

- **Website:** https://goauthentik.io
- **Documentation:** https://docs.goauthentik.io
- **GitHub:** https://github.com/goauthentik/authentik
- **Discord:** https://discord.gg/jg33eMhnj6
- **Forum:** https://github.com/goauthentik/authentik/discussions
- **Docker Hub:** https://hub.docker.com/r/goauthentik/server

## Educational Resources

### Videos
- [Authentik - The BEST SSO Platform? (Techno Tim)](https://www.youtube.com/watch?v=N5unsATNpJk)
- [Authentik Setup and Configuration (DB Tech)](https://www.youtube.com/watch?v=D8ovMx_CILE)
- [Authentik vs Authelia Comparison](https://www.youtube.com/results?search_query=authentik+vs+authelia)
- [OAuth2 and OIDC Explained](https://www.youtube.com/watch?v=t18YB3xDfXI)

### Articles & Guides
- [Authentik Official Documentation](https://docs.goauthentik.io)
- [Forward Auth with Traefik](https://docs.goauthentik.io/docs/providers/proxy/forward_auth)
- [LDAP Provider Setup](https://docs.goauthentik.io/docs/providers/ldap/)
- [OAuth2/OIDC Provider](https://docs.goauthentik.io/docs/providers/oauth2/)

### Concepts to Learn
- **Identity Provider (IdP):** Service that manages user identities
- **OAuth2/OIDC:** Modern authentication protocols
- **SAML:** Enterprise federation protocol
- **LDAP:** Directory access protocol
- **Forward Auth:** Proxy-based authentication
- **Flows:** Customizable authentication sequences
- **Stages:** Building blocks of flows
- **Policies:** Rules for access control
- **Providers:** Application integration methods

## Docker Configuration

### Complete Stack Definition

```yaml
# PostgreSQL Database
authentik-db:
  image: postgres:12-alpine
  container_name: authentik-db
  restart: unless-stopped
  networks:
    - authentik-network
  volumes:
    - /opt/stacks/infrastructure/authentik/database:/var/lib/postgresql/data
  environment:
    - POSTGRES_USER=${POSTGRES_USER}
    - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    - POSTGRES_DB=${POSTGRES_DB}
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
    interval: 10s
    timeout: 5s
    retries: 5

# Redis Cache
authentik-redis:
  image: redis:alpine
  container_name: authentik-redis
  restart: unless-stopped
  networks:
    - authentik-network
  healthcheck:
    test: ["CMD-SHELL", "redis-cli ping"]
    interval: 10s
    timeout: 5s
    retries: 5

# Authentik Server
authentik:
  image: ghcr.io/goauthentik/server:latest
  container_name: authentik
  restart: unless-stopped
  command: server
  networks:
    - traefik-network
    - authentik-network
  volumes:
    - /opt/stacks/infrastructure/authentik/media:/media
    - /opt/stacks/infrastructure/authentik/custom-templates:/templates
  environment:
    - AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}
    - AUTHENTIK_ERROR_REPORTING__ENABLED=false
    - AUTHENTIK_REDIS__HOST=authentik-redis
    - AUTHENTIK_POSTGRESQL__HOST=authentik-db
    - AUTHENTIK_POSTGRESQL__NAME=${POSTGRES_DB}
    - AUTHENTIK_POSTGRESQL__USER=${POSTGRES_USER}
    - AUTHENTIK_POSTGRESQL__PASSWORD=${POSTGRES_PASSWORD}
    - TZ=America/New_York
  depends_on:
    - authentik-db
    - authentik-redis
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.authentik.rule=Host(`authentik.${DOMAIN}`)"
    - "traefik.http.routers.authentik.entrypoints=websecure"
    - "traefik.http.routers.authentik.tls.certresolver=letsencrypt"
    - "traefik.http.services.authentik.loadbalancer.server.port=9000"
    
    # Forward Auth Middleware
    - "traefik.http.middlewares.authentik.forwardAuth.address=http://authentik:9000/outpost.goauthentik.io/auth/traefik"
    - "traefik.http.middlewares.authentik.forwardAuth.trustForwardHeader=true"
    - "traefik.http.middlewares.authentik.forwardAuth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid"

# Authentik Worker (Background Tasks)
authentik-worker:
  image: ghcr.io/goauthentik/server:latest
  container_name: authentik-worker
  restart: unless-stopped
  command: worker
  networks:
    - authentik-network
  volumes:
    - /opt/stacks/infrastructure/authentik/media:/media
    - /opt/stacks/infrastructure/authentik/custom-templates:/templates
    - /opt/stacks/infrastructure/authentik/certs:/certs
  environment:
    - AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}
    - AUTHENTIK_ERROR_REPORTING__ENABLED=false
    - AUTHENTIK_REDIS__HOST=authentik-redis
    - AUTHENTIK_POSTGRESQL__HOST=authentik-db
    - AUTHENTIK_POSTGRESQL__NAME=${POSTGRES_DB}
    - AUTHENTIK_POSTGRESQL__USER=${POSTGRES_USER}
    - AUTHENTIK_POSTGRESQL__PASSWORD=${POSTGRES_PASSWORD}
    - TZ=America/New_York
  depends_on:
    - authentik-db
    - authentik-redis

networks:
  authentik-network:
    internal: true  # Database and Redis not exposed externally
  traefik-network:
    external: true
```

### Protecting Services with Authentik

```yaml
myservice:
  image: myapp:latest
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.myservice.rule=Host(`myservice.${DOMAIN}`)"
    - "traefik.http.routers.myservice.entrypoints=websecure"
    - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
    - "traefik.http.routers.myservice.middlewares=authentik@docker"  # Add this
  networks:
    - traefik-network
```

## Initial Setup

### First-Time Configuration

1. **Deploy Stack:**
   ```bash
   cd /opt/stacks/infrastructure
   docker compose up -d authentik-db authentik-redis authentik authentik-worker
   ```

2. **Wait for Initialization:**
   ```bash
   # Watch logs
   docker logs -f authentik
   # Wait for: "Bootstrap completed successfully"
   ```

3. **Access Web UI:**
   - Navigate to: `https://authentik.yourdomain.com/if/flow/initial-setup/`
   - This is a **one-time URL** for initial admin setup

4. **Create Admin Account:**
   - Email: `admin@yourdomain.com`
   - Username: `admin`
   - Password: Strong password
   - Complete setup

5. **Login:**
   - Go to: `https://authentik.yourdomain.com`
   - Login with admin credentials
   - You'll see the user interface

6. **Access Admin Interface:**
   - Click on your profile (top right)
   - Select "Admin Interface"
   - This is where you configure everything

### Initial Configuration Steps

1. **Configure Branding:**
   - System → Settings → Branding
   - Upload logo
   - Set colors and theme

2. **Configure Email (Recommended):**
   - System → Settings → Email
   - SMTP settings
   - Test email delivery

3. **Create Default Outpost:**
   - Applications → Outposts
   - Should have one called "authentik Embedded Outpost"
   - This handles forward auth

4. **Create Application:**
   - Applications → Applications → Create
   - Name: Your service name
   - Slug: your-service
   - Provider: Create new provider

## User Management

### Creating Users

**Via Admin Interface:**
1. Directory → Users → Create
2. Fill in details:
   - Username (required)
   - Email (required)
   - Name
   - Active status
3. Set password or send activation email
4. Assign to groups (optional)

**Via User Portal:**
- Enable self-registration in Flow settings
- Users can sign up themselves
- Admin approval optional

### Creating Groups

1. Directory → Groups → Create
2. Name and optional parent group
3. Add users
4. Assign to applications

### Group Hierarchy

```
All Users
├── Admins
│   ├── System Admins
│   └── Application Admins
├── Users
│   ├── Family
│   └── Friends
└── Guests
```

### Password Policies

1. Policies → Create → Password Policy
2. Configure:
   - Minimum length
   - Uppercase/lowercase requirements
   - Numbers and symbols
   - Complexity score
3. Bind to flows

## Application Integration

### Forward Auth (Traefik)

**For most homelab services:**

1. **Create Provider:**
   - Applications → Providers → Create
   - Type: Proxy Provider
   - Name: `my-service-proxy`
   - Authorization flow: Default
   - Forward auth: External host: `https://myservice.yourdomain.com`

2. **Create Application:**
   - Applications → Applications → Create
   - Name: `My Service`
   - Slug: `my-service`
   - Provider: Select provider created above
   - Launch URL: `https://myservice.yourdomain.com`

3. **Configure Service:**
   ```yaml
   myservice:
     labels:
       - "traefik.http.routers.myservice.middlewares=authentik@docker"
   ```

### OAuth2/OIDC Integration

**For apps supporting OAuth2:**

1. **Create Provider:**
   - Type: OAuth2/OpenID Provider
   - Client type: Confidential
   - Client ID: Auto-generated or custom
   - Client Secret: Auto-generated (save this!)
   - Redirect URIs: `https://myapp.com/oauth/callback`
   - Signing Key: Auto-select

2. **Create Application:**
   - Link to OAuth provider
   - Users can now login via "Sign in with Authentik"

3. **Configure Application:**
   - OIDC Discovery URL: `https://authentik.yourdomain.com/application/o/{slug}/.well-known/openid-configuration`
   - Client ID: From provider
   - Client Secret: From provider

### LDAP Provider

**For legacy apps requiring LDAP:**

1. **Create Provider:**
   - Type: LDAP Provider
   - Name: `LDAP Service`
   - Base DN: `dc=ldap,dc=goauthentik,dc=io`
   - Bind Flow: Default

2. **Create Application:**
   - Link to LDAP provider

3. **Create Outpost:**
   - Applications → Outposts → Create
   - Type: LDAP
   - Providers: Select LDAP provider
   - Port: 389 or 636 (LDAPS)

4. **Configure Application:**
   - LDAP Server: `ldap://authentik-ldap:389`
   - Base DN: From provider
   - Bind DN: `cn=admin,dc=ldap,dc=goauthentik,dc=io`
   - Bind Password: From Authentik

### SAML Provider

**For enterprise SAML apps:**

1. **Create Provider:**
   - Type: SAML Provider
   - ACS URL: From application
   - Issuer: Auto-generated
   - Service Provider Binding: POST or Redirect
   - Audience: From application

2. **Download Metadata:**
   - Export metadata XML
   - Import into target application

## Advanced Topics

### Custom Flows

**Create Custom Login Flow:**

1. **Flows → Create:**
   - Name: `Custom Login`
   - Designation: Authentication
   - Authentication: User/Password

2. **Add Stages:**
   - Identification Stage (username/email)
   - Password Stage
   - MFA Validation Stage
   - User Write Stage

3. **Configure Flow:**
   - Policy bindings
   - Stage bindings
   - Flow order

4. **Assign to Applications:**
   - Applications → Select app → Authentication flow

### Policy Engine

**Create Access Policy:**

```python
# Example policy: Only allow admins
return user.groups.filter(name="Admins").exists()
```

```python
# Example: Only allow access during business hours
import datetime
now = datetime.datetime.now()
return 9 <= now.hour < 17
```

```python
# Example: Block specific IPs
blocked_ips = ["192.168.1.100", "10.0.0.50"]
return request.context.get("ip") not in blocked_ips
```

**Bind Policy:**
1. Applications → Select app
2. Policy Bindings → Create
3. Select policy
4. Set order and action (allow/deny)

### Custom Branding

**Custom Theme:**
1. System → Settings → Branding
2. Upload logo
3. Set background image
4. Custom CSS:
   ```css
   :root {
       --ak-accent: #1f6feb;
       --ak-dark-background: #0d1117;
   }
   ```

**Custom Email Templates:**
1. Create template in `/custom-templates/email/`
2. Use Authentik template variables
3. Reference in email stages

### Events and Monitoring

**Event Logging:**
- Events → Event Logs
- Filter by user, action, app
- Export for analysis

**Notifications:**
- Events → Notification Rules
- Trigger on specific events
- Send to email, webhook, etc.

**Monitoring:**
- System → System Tasks
- Worker status
- Database connections
- Cache status

### LDAP Synchronization

Sync users from external LDAP:

1. **Create LDAP Source:**
   - Directory → Federation & Social Login → Create
   - Type: LDAP Source
   - Server URI: `ldaps://ldap.example.com`
   - Bind CN and password
   - Base DN for users and groups

2. **Sync Configuration:**
   - User object filter
   - Group object filter
   - Attribute mapping

3. **Manual Sync:**
   - Directory → Sources → Select source → Sync

## Troubleshooting

### Can't Access Initial Setup URL

```bash
# Check if Authentik is running
docker ps | grep authentik

# View logs
docker logs authentik

# If you missed initial setup, create admin via CLI
docker exec -it authentik ak create_admin_group
docker exec -it authentik ak create_recovery_key
# Use recovery key to access /if/flow/recovery/
```

### Database Connection Errors

```bash
# Check if database is running
docker ps | grep authentik-db

# Check database health
docker exec authentik-db pg_isready -U authentik

# View database logs
docker logs authentik-db

# Test connection
docker exec authentik-db psql -U authentik -d authentik -c "SELECT 1;"

# Reset database (WARNING: deletes all data)
docker compose down
docker volume rm authentik_database
docker compose up -d
```

### Redis Connection Errors

```bash
# Check if Redis is running
docker ps | grep authentik-redis

# Test Redis
docker exec authentik-redis redis-cli ping

# View Redis logs
docker logs authentik-redis

# Flush Redis cache (safe)
docker exec authentik-redis redis-cli FLUSHALL
```

### Services Not Being Protected

```bash
# Verify middleware is applied
docker inspect service-name | grep authentik

# Check Traefik logs
docker logs traefik | grep authentik

# Test forward auth directly
curl -I -H "Host: service.yourdomain.com" \
  http://authentik:9000/outpost.goauthentik.io/auth/traefik

# Check outpost status
# Admin Interface → Applications → Outposts → Status should be "healthy"
```

### Login Not Working

```bash
# Check Authentik logs
docker logs authentik | grep -i error

# Verify flows are configured
# Admin Interface → Flows → Should have default flows

# Check browser console
# F12 → Console → Look for errors

# Clear cookies and try again
# Browser → DevTools → Application → Clear cookies

# Test with incognito/private window
```

### Worker Not Processing Tasks

```bash
# Check worker status
docker ps | grep authentik-worker

# View worker logs
docker logs authentik-worker

# Restart worker
docker restart authentik-worker

# Check scheduled tasks
# Admin Interface → System → System Tasks
```

### High Memory Usage

```bash
# Check container stats
docker stats authentik authentik-db authentik-redis

# Restart services
docker restart authentik authentik-worker

# Optimize database
docker exec authentik-db vacuumdb -U authentik -d authentik -f

# Clear Redis cache
docker exec authentik-redis redis-cli FLUSHALL
```

### Email Not Sending

```bash
# Test email configuration
# Admin Interface → System → Settings → Email → Test

# Check worker logs (worker handles emails)
docker logs authentik-worker | grep -i email

# Verify SMTP settings
docker exec authentik env | grep EMAIL

# For Gmail, use App Password, not account password
# https://support.google.com/accounts/answer/185833
```

## Backup and Restore

### Backup

**Database Backup:**
```bash
# Backup PostgreSQL
docker exec authentik-db pg_dump -U authentik authentik > authentik-backup-$(date +%Y%m%d).sql

# Backup media files
tar -czf authentik-media-$(date +%Y%m%d).tar.gz /opt/stacks/infrastructure/authentik/media
```

**Automated Backup Script:**
```bash
#!/bin/bash
BACKUP_DIR="/opt/backups/authentik"
DATE=$(date +%Y%m%d-%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
docker exec authentik-db pg_dump -U authentik authentik | gzip > $BACKUP_DIR/authentik-db-$DATE.sql.gz

# Backup media
tar -czf $BACKUP_DIR/authentik-media-$DATE.tar.gz /opt/stacks/infrastructure/authentik/media

# Keep only last 7 days
find $BACKUP_DIR -name "authentik-*" -mtime +7 -delete

echo "Backup completed: $DATE"
```

### Restore

```bash
# Stop services
docker compose down

# Restore database
docker compose up -d authentik-db
docker exec -i authentik-db psql -U authentik authentik < authentik-backup-20240112.sql

# Restore media
tar -xzf authentik-media-20240112.tar.gz -C /

# Start services
docker compose up -d
```

## Performance Optimization

### Database Optimization

```bash
# Vacuum and analyze
docker exec authentik-db vacuumdb -U authentik -d authentik -f -z

# Reindex
docker exec authentik-db reindexdb -U authentik -d authentik
```

### Redis Configuration

```yaml
authentik-redis:
  command: >
    --maxmemory 256mb
    --maxmemory-policy allkeys-lru
    --save ""
```

### Worker Scaling

Run multiple workers for better performance:

```yaml
authentik-worker:
  deploy:
    replicas: 2
  # Or create multiple named workers
```

## Security Best Practices

1. **Strong Secret Key:** Use 50+ character random key
2. **Email Verification:** Enable email verification for new users
3. **MFA Required:** Enforce 2FA for admin accounts
4. **Policy Bindings:** Use policies to restrict access
5. **Regular Backups:** Automate database and media backups
6. **Update Regularly:** Keep Authentik updated
7. **Monitor Events:** Review event logs for suspicious activity
8. **Secure Database:** Never expose PostgreSQL publicly
9. **Secure Redis:** Keep Redis on internal network
10. **HTTPS Only:** Always use SSL/TLS

## Migration from Authelia

**Considerations:**
1. **Different Philosophy:** Authelia is file-based, Authentik is database-based
2. **User Migration:** No automated tool - manual recreation needed
3. **Flow Configuration:** Different access control model
4. **Resource Usage:** Authentik uses more resources (database, Redis)
5. **Flexibility:** Authentik offers more features but more complexity

**Steps:**
1. Deploy Authentik stack alongside Authelia
2. Configure Authentik flows and policies
3. Recreate users and groups in Authentik
4. Test services with Authentik middleware
5. Gradually migrate services
6. Remove Authelia when confident

## Summary

Authentik is a powerful, flexible identity provider that offers:
- Web-based configuration (no file editing)
- Multiple authentication protocols (OAuth2, SAML, LDAP)
- User self-service portal
- Advanced policy engine
- Visual flow designer
- Enterprise-grade features

**Perfect for:**
- Complex authentication requirements
- Multiple user groups and roles
- SAML integration needs
- LDAP for legacy applications
- User self-service requirements
- OAuth2/OIDC provider functionality

**Trade-offs:**
- Higher resource usage (4 containers vs 1)
- More complex setup
- Database dependency
- Steeper learning curve

**Remember:**
- Use strong secret keys
- Enable MFA for admins
- Regular database backups
- Monitor event logs
- Start with simple flows
- Gradually add complexity
- Test thoroughly before production use
- Authentik and Authelia can coexist during migration
