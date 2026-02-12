# Wildcard Certificate Setup Instructions

## Current Status
- Your HTTPS certificates ARE working (3 individual certificates restored)
- Configuration is **ready** for wildcard certificate
- **Rate limit hit**: Must wait until **2026-02-13 21:33 UTC** before requesting new certificates

## Why You Hit the Rate Limit
Let's Encrypt limits **5 certificates per exact set of domain names per week**. You requested individual certificates for each service multiple times during testing, hitting this limit.

## Rate Limit Reset
- **Reset Time**: February 13, 2026 at 21:33 UTC (approximately 4:33 PM EST)
- **After reset**: Traefik will automatically request the wildcard certificate

## What's Been Configured

### 1. Wildcard Certificate Request
File: `/opt/stacks/core/traefik/dynamic/wildcard-cert.yml`
- Requests: `kelinreij.duckdns.org` + `*.kelinreij.duckdns.org`
- Uses DNS challenge (already configured in traefik.yml)
- Will cover ALL subdomains with one certificate

### 2. Traefik Configuration Updated
File: `/opt/stacks/core/traefik/config/traefik.yml`
- Added DNS resolvers for faster DNS challenge
- DNS challenge already configured for DuckDNS

### 3. Current Certificates (Individual)
- traefik.kelinreij.duckdns.org
- pihole.kelinreij.duckdns.org
- auth.kelinreij.duckdns.org

## After Rate Limit Resets

### Option A: Automatic (Recommended)
1. Traefik will automatically request the wildcard certificate when it restarts or refreshes
2. The wildcard-cert.yml configuration will trigger the request
3. All services will automatically use the wildcard certificate

### Option B: Manual Trigger
If the automatic request doesn't happen:

```bash
# Clear existing certificates to force new request
sudo cp /opt/stacks/core/traefik/letsencrypt/acme.json /opt/stacks/core/traefik/letsencrypt/acme.json.pre-wildcard
sudo truncate -s 0 /opt/stacks/core/traefik/letsencrypt/acme.json
sudo chmod 600 /opt/stacks/core/traefik/letsencrypt/acme.json

# Restart Traefik to request wildcard certificate
cd /opt/stacks/core
docker-compose restart traefik

# Wait 30 seconds and verify
sleep 30
sudo cat /opt/stacks/core/traefik/letsencrypt/acme.json | python3 -c "import sys, json; data=json.load(sys.stdin); certs = data.get('letsencrypt', {}).get('Certificates', []); [print(f'Main: {c[\"domain\"].get(\"main\")}, SANs: {c[\"domain\"].get(\"sans\", [])}') for c in certs]"
```

### Verify Wildcard Certificate
You should see:
```
Main: kelinreij.duckdns.org, SANs: ['*.kelinreij.duckdns.org']
```

## Checking Rate Limit Status

```bash
# Check Traefik logs for rate limit errors
docker exec traefik grep -i "rate" /var/log/traefik/traefik.log | tail -5

# Check certificate requests
docker exec traefik grep "obtaining.*certificate" /var/log/traefik/traefik.log | tail -5
```

## Future Service Additions

Once the wildcard certificate is in place, new services will automatically use it. No need to request individual certificates anymore!

## Avoiding Rate Limits in the Future

1. **Use Staging for Testing**
   Update `traefik.yml` temporarily when testing:
   ```yaml
   caServer: https://acme-staging-v02.api.letsencrypt.org/directory  # Staging
   ```

2. **Don't Clear acme.json Unless Necessary**
   - Certificates auto-renew every 60 days
   - Only clear if you need to switch certificate types

3. **Wildcard = One Certificate for All Services**
   - No more individual requests
   - Add unlimited services without hitting limits

## Backup Files Created
- `/opt/stacks/core/traefik/config/traefik.yml.backup` - Original config
- `/opt/stacks/core/traefik/letsencrypt/acme.json.backup` - Working certificates (restored)

## Next Steps
1. **Wait until February 13, 2026 at 21:33 UTC**
2. Either let Traefik auto-request the wildcard cert, or trigger manually (Option B above)
3. Verify the wildcard certificate is in place
4. Enjoy unlimited service additions without rate limits!
