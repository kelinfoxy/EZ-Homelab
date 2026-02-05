# Action Report: SSL Wildcard Certificate Setup

**Date:** January 12, 2026  
**Status:** ✅ Completed Successfully  
**Impact:** All homelab services now have valid Let's Encrypt SSL certificates

---

## Problem Statement

Services were showing "not secure" warnings in browsers despite Traefik being configured for Let's Encrypt certificates. Multiple simultaneous certificate requests were failing due to DNS challenge conflicts.

## Root Causes Identified

### 1. **Multiple Simultaneous Certificate Requests**
- **Issue:** Each service (dockge, dozzle, glances, pihole, authelia) had `traefik.http.routers.*.tls.certresolver=letsencrypt` labels
- **Impact:** Traefik attempted to request individual certificates for each subdomain simultaneously
- **Consequence:** DuckDNS DNS challenge can only handle ONE TXT record at `_acme-challenge.yourdomain.duckdns.org` at a time
- **Result:** All certificate requests failed with "Incorrect TXT record" errors

### 2. **DNS TXT Record Conflicts**
- **Issue:** Multiple services tried to create different TXT records at the same DNS location
- **Example:** 
  - Service A creates: `_acme-challenge.yourdomain.duckdns.org` = "token1"
  - Service B overwrites: `_acme-challenge.yourdomain.duckdns.org` = "token2"
  - Let's Encrypt validates Service A but finds "token2" → validation fails
- **DuckDNS Limitation:** Can only maintain ONE TXT record per domain

### 3. **Authelia Configuration Error**
- **Issue:** Environment variable `AUTHELIA_NOTIFIER_SMTP_PASSWORD` was set without corresponding SMTP configuration
- **Impact:** Authelia crashed on startup with "please ensure only one of the 'smtp' or 'filesystem' notifier is configured"
- **Consequence:** Services requiring Authelia authentication were inaccessible

### 4. **Stale DNS Records**
- **Issue:** Old TXT records from failed attempts persisted in DNS
- **Impact:** New certificate attempts validated against old, incorrect TXT records

## Solution Implemented

### Phase 1: Identify Certificate Request Pattern

**Actions:**
1. Discovered Traefik logs at `/var/log/traefik/traefik.log` (not stdout)
2. Analyzed logs showing multiple simultaneous DNS-01 challenges
3. Confirmed DuckDNS TXT record conflicts

**Command Used:**
```bash
docker exec traefik tail -f /var/log/traefik/traefik.log
```

### Phase 2: Configure Wildcard Certificate

**Actions:**
1. Removed `certresolver` labels from all services except Traefik
2. Configured wildcard certificate on Traefik router only
3. Added DNS propagation skip for faster validation

**Changes Made:**

**File:** `/home/kelin/AI-Homelab/docker-compose/core.yml`
```yaml
# Traefik - Only service with certresolver
traefik:
  labels:
    - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
    - "traefik.http.routers.traefik.tls.domains[0].main=${DOMAIN}"
    - "traefik.http.routers.traefik.tls.domains[0].sans=*.${DOMAIN}"

# Authelia - No certresolver, just tls=true
authelia:
  labels:
    - "traefik.http.routers.authelia.tls=true"
```

**File:** `/home/kelin/AI-Homelab/docker-compose/infrastructure.yml`
```yaml
# All infrastructure services - No certresolver
dockge:
  labels:
    - "traefik.http.routers.dockge.tls=true"

dozzle:
  labels:
    - "traefik.http.routers.dozzle.tls=true"

glances:
  labels:
    - "traefik.http.routers.glances.tls=true"

pihole:
  labels:
    - "traefik.http.routers.pihole.tls=true"
```

**File:** `/opt/stacks/core/traefik/traefik.yml`
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /acme.json
      dnsChallenge:
        provider: duckdns
        disablePropagationCheck: true  # Added to skip DNS propagation wait
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
```

### Phase 3: Clear DNS and Reset Certificates

**Actions:**
1. Stopped all services to clear DNS TXT records
2. Reset `acme.json` to force fresh certificate request
3. Waited 60 seconds for DNS to fully clear
4. Restarted services with wildcard-only configuration

**Commands Executed:**
```bash
# Stop services
cd /opt/stacks/core && docker compose down

# Reset certificate storage
rm /opt/stacks/core/traefik/acme.json
touch /opt/stacks/core/traefik/acme.json
chmod 600 /opt/stacks/core/traefik/acme.json
chown kelin:kelin /opt/stacks/core/traefik/acme.json

# Wait for DNS to clear
sleep 60
dig +short TXT _acme-challenge.yourdomain.duckdns.org  # Verified empty

# Deploy updated configuration
cp /home/kelin/AI-Homelab/docker-compose/core.yml /opt/stacks/core/docker-compose.yml
cd /opt/stacks/core && docker compose up -d
```

### Phase 4: Fix Authelia Configuration

**Issue Found:** Environment variable triggering SMTP configuration check

**File:** `/opt/stacks/core/docker-compose.yml`

**Removed:**
```yaml
environment:
  - AUTHELIA_NOTIFIER_SMTP_PASSWORD=${SMTP_PASSWORD}  # ❌ Removed
```

**Command:**
```bash
cd /opt/stacks/core && docker compose up -d authelia
```

### Phase 5: Fix Infrastructure Services

**Issue:** Missing `networks:` header in compose file

**File:** `/opt/stacks/infrastructure/infrastructure.yml`

**Fixed:**
```yaml
# Before (incorrect):
  traefik-network:
    external: true

# After (correct):
networks:
  traefik-network:
    external: true
  homelab-network:
    driver: bridge
  dockerproxy-network:
    driver: bridge
```

**Command:**
```bash
cd /opt/stacks/infrastructure && docker compose -f infrastructure.yml up -d
```

## Results

### Certificate Obtained Successfully ✅

**acme.json Contents:**
```json
{
  "letsencrypt": {
    "Account": {
      "Email": "your-email@example.com",
      "Registration": {
        "uri": "https://acme-v02.api.letsencrypt.org/acme/acct/XXXXXXXXXX"
      }
    },
    "Certificates": [
      {
        "domain": {
          "main": "dockge.yourdomain.duckdns.org"
        }
      },
      {
        "domain": {
          "main": "yourdomain.duckdns.org",
          "sans": ["*.yourdomain.duckdns.org"]
        }
      }
    ]
  }
}
```

**Certificate Details:**
- **Subject:** CN=yourdomain.duckdns.org
- **Issuer:** C=US, O=Let's Encrypt, CN=R12
- **Coverage:** Wildcard certificate covering all subdomains
- **File Size:** 23KB (up from 0 bytes)

### Services Status

All services running with valid SSL certificates:

| Service | Status | URL | Certificate |
|---------|--------|-----|-------------|
| Traefik | ✅ Up | https://traefik.yourdomain.duckdns.org | Valid |
| Authelia | ✅ Up | https://auth.yourdomain.duckdns.org | Valid |
| Dockge | ✅ Up | https://dockge.yourdomain.duckdns.org | Valid |
| Dozzle | ✅ Up | https://dozzle.yourdomain.duckdns.org | Valid |
| Glances | ✅ Up | https://glances.yourdomain.duckdns.org | Valid |
| Pi-hole | ✅ Up | https://pihole.yourdomain.duckdns.org | Valid |

## Best Practices & Prevention

### 1. ✅ Use Wildcard Certificates with DuckDNS

**Rule:** Only ONE service should request certificates with DuckDNS DNS challenge

**Configuration:**
```yaml
# ✅ CORRECT: Only Traefik requests wildcard cert
traefik:
  labels:
    - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
    - "traefik.http.routers.traefik.tls.domains[0].main=${DOMAIN}"
    - "traefik.http.routers.traefik.tls.domains[0].sans=*.${DOMAIN}"

# ✅ CORRECT: Other services just enable TLS
other-service:
  labels:
    - "traefik.http.routers.service.tls=true"  # Uses wildcard automatically

# ❌ WRONG: Multiple services requesting certs
other-service:
  labels:
    - "traefik.http.routers.service.tls.certresolver=letsencrypt"  # DON'T DO THIS
```

### 2. ✅ DuckDNS DNS Challenge Limitations

**Understand the Constraint:**
- DuckDNS can only maintain ONE TXT record at `_acme-challenge.yourdomain.duckdns.org`
- Multiple simultaneous challenges WILL fail
- Use wildcard certificate to avoid this limitation

**Alternative Providers (if needed):**
- Cloudflare: Supports multiple simultaneous DNS challenges
- Route53: Supports multiple TXT records
- Use HTTP challenge if DNS challenge isn't required

### 3. ✅ Traefik Logging Configuration

**Enable File Logging for Debugging:**

**File:** `/opt/stacks/core/traefik/traefik.yml`
```yaml
log:
  level: DEBUG  # Use DEBUG for troubleshooting, INFO for production
  filePath: /var/log/traefik/traefik.log  # Easier to tail than docker logs

# Mount in docker-compose.yml:
volumes:
  - /var/log/traefik:/var/log/traefik
```

**Useful Commands:**
```bash
# Monitor certificate acquisition
docker exec traefik tail -f /var/log/traefik/traefik.log | grep -E "acme|certificate|DNS"

# Check for errors
docker exec traefik tail -100 /var/log/traefik/traefik.log | grep -E "error|Unable"

# View specific domain
docker exec traefik tail -200 /var/log/traefik/traefik.log | grep "yourdomain.duckdns.org"
```

### 4. ✅ Certificate Troubleshooting Workflow

**When certificates aren't working:**

```bash
# 1. Check acme.json status
cat /opt/stacks/core/traefik/acme.json | python3 -m json.tool | grep -A5 "Certificates"

# 2. Check certificate count
python3 -c "import json; d=json.load(open('/opt/stacks/core/traefik/acme.json')); print(f'Certificates: {len(d[\"letsencrypt\"][\"Certificates\"])}')"

# 3. Test certificate being served
echo | openssl s_client -connect auth.yourdomain.duckdns.org:443 -servername auth.yourdomain.duckdns.org 2>/dev/null | openssl x509 -noout -subject -issuer

# 4. Check DNS TXT records
dig +short TXT _acme-challenge.yourdomain.duckdns.org

# 5. Check Traefik logs
docker exec traefik tail -50 /var/log/traefik/traefik.log
```

### 5. ✅ Environment Variable Hygiene

**Principle:** Only set environment variables that are actually used

**Example - Authelia:**
```yaml
# ✅ CORRECT: Only variables for configured features
environment:
  - AUTHELIA_JWT_SECRET=${AUTHELIA_JWT_SECRET}
  - AUTHELIA_SESSION_SECRET=${AUTHELIA_SESSION_SECRET}
  - AUTHELIA_STORAGE_ENCRYPTION_KEY=${AUTHELIA_STORAGE_ENCRYPTION_KEY}

# ❌ WRONG: SMTP variable without SMTP configuration
environment:
  - AUTHELIA_NOTIFIER_SMTP_PASSWORD=${SMTP_PASSWORD}  # Causes crash if SMTP not in config.yml
```

### 6. ✅ Docker Compose File Validation

**Before deploying:**
```bash
# Validate syntax
docker compose -f /path/to/file.yml config

# Check for common errors
grep -n "^  [a-z]" file.yml  # Networks should have "networks:" header
```

### 7. ✅ Certificate Renewal Strategy

**Automatic Renewal:**
- Traefik automatically renews certificates 30 days before expiration
- Wildcard certificate covers all subdomains (no individual renewals needed)
- Monitor `acme.json` for certificate expiration dates

**Backup acme.json:**
```bash
# Regular backup (e.g., daily cron)
cp /opt/stacks/core/traefik/acme.json /opt/backups/acme.json.$(date +%Y%m%d)

# Keep last 7 days
find /opt/backups -name "acme.json.*" -mtime +7 -delete
```

## Key Learnings

### Technical Insights

1. **DuckDNS Limitation:** Single TXT record constraint requires wildcard certificate approach
2. **DNS Propagation:** `disablePropagationCheck: true` speeds up validation but relies on fast DNS updates
3. **Traefik Labels:** `tls=true` vs `tls.certresolver=letsencrypt` - use former for wildcard coverage
4. **Environment Variables:** Can trigger configuration validation even without corresponding config file entries

### Process Insights

1. **Log Discovery:** Traefik logs to files by default, not always visible via `docker logs`
2. **DNS Clearing:** Stopping services and waiting 60s ensures DNS records fully clear
3. **Incremental Debugging:** Monitor logs during certificate acquisition to catch issues early
4. **Configuration Synchronization:** Repository files must be copied to deployment locations

## Documentation Updates

### Files Modified

**Repository:**
- `/home/kelin/AI-Homelab/docker-compose/core.yml`
- `/home/kelin/AI-Homelab/docker-compose/infrastructure.yml`

**Deployed:**
- `/opt/stacks/core/docker-compose.yml`
- `/opt/stacks/core/traefik/traefik.yml`
- `/opt/stacks/core/traefik/acme.json`
- `/opt/stacks/infrastructure/infrastructure.yml`

### Configuration Templates

**Wildcard Certificate Template:**
```yaml
services:
  traefik:
    labels:
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik.tls.domains[0].main=${DOMAIN}"
      - "traefik.http.routers.traefik.tls.domains[0].sans=*.${DOMAIN}"
  
  any-other-service:
    labels:
      - "traefik.http.routers.service.tls=true"  # No certresolver!
```

## Future Recommendations

### Short-term (Next Week)

1. ✅ Monitor certificate auto-renewal (should happen automatically)
2. ✅ Test browser access from different devices to verify SSL
3. ✅ Update homelab documentation with wildcard certificate pattern
4. ⚠️ Consider adding certificate monitoring alerts

### Medium-term (Next Month)

1. Set up automated `acme.json` backups
2. Document certificate troubleshooting runbook
3. Consider migrating to Cloudflare if more services are added
4. Implement certificate expiration monitoring

### Long-term (Next Quarter)

1. Evaluate alternative DNS providers for better DNS challenge support
2. Consider setting up staging Let's Encrypt for testing
3. Implement centralized logging for all services
4. Add Prometheus/Grafana monitoring for SSL certificate expiration

## Quick Reference

### Emergency Certificate Reset

```bash
# 1. Stop all services
cd /opt/stacks/core && docker compose down
cd /opt/stacks/infrastructure && docker compose -f infrastructure.yml down

# 2. Reset acme.json
rm /opt/stacks/core/traefik/acme.json
touch /opt/stacks/core/traefik/acme.json
chmod 600 /opt/stacks/core/traefik/acme.json

# 3. Wait for DNS to clear
sleep 60

# 4. Restart
cd /opt/stacks/core && docker compose up -d
cd /opt/stacks/infrastructure && docker compose -f infrastructure.yml up -d

# 5. Monitor
docker exec traefik tail -f /var/log/traefik/traefik.log
```

### Verify Certificate Command

```bash
echo | openssl s_client -connect ${SUBDOMAIN}.yourdomain.duckdns.org:443 -servername ${SUBDOMAIN}.yourdomain.duckdns.org 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

### Check All Service Certificates

```bash
for subdomain in auth traefik dockge dozzle glances pihole; do
  echo "=== $subdomain.yourdomain.duckdns.org ==="
  echo | openssl s_client -connect $subdomain.yourdomain.duckdns.org:443 -servername $subdomain.yourdomain.duckdns.org 2>/dev/null | openssl x509 -noout -subject -issuer
  echo
done
```

---

## Summary

Successfully implemented wildcard SSL certificate for all homelab services using Let's Encrypt DNS challenge via DuckDNS. Key success factor was recognizing DuckDNS's limitation of one TXT record at a time and configuring Traefik to request a single wildcard certificate instead of individual certificates per service. All services now accessible via HTTPS with valid certificates.

**Status:** ✅ Production Ready  
**Next Review:** 30 days before certificate expiration (March 13, 2026)
