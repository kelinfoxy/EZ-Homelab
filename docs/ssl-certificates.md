# SSL Certificates with Let's Encrypt and DuckDNS

Your homelab uses **Let's Encrypt** to automatically provide free SSL certificates for all your services. This ensures secure HTTPS connections without manual certificate management.

## How SSL Certificates Work in Your Homelab

### The Certificate Flow

1. **Domain Registration**: DuckDNS provides your dynamic domain (e.g., `yourname.duckdns.org`)
2. **Certificate Request**: Traefik requests a wildcard certificate (`*.yourname.duckdns.org`)
3. **Domain Validation**: Let's Encrypt validates you own the domain via DNS challenge
4. **Certificate Issuance**: Free SSL certificate is issued and stored
5. **Automatic Renewal**: Certificates renew automatically before expiration

### DuckDNS + Let's Encrypt Integration

**DuckDNS** handles dynamic DNS updates, while **Let's Encrypt** provides certificates:

- **DuckDNS**: Updates your public IP → domain mapping every 5 minutes
- **Let's Encrypt**: Issues trusted SSL certificates via ACME protocol
- **DNS Challenge**: Proves domain ownership by setting TXT records

### Wildcard Certificates Explained

Your setup uses a **wildcard certificate** (`*.yourdomain.duckdns.org`) that covers:
- `dockge.yourdomain.duckdns.org`
- `plex.yourdomain.duckdns.org`
- `jellyfin.yourdomain.duckdns.org`
- Any other subdomain automatically

**Why wildcard?** One certificate covers all services - no need for individual certificates per service.

### Certificate Storage & Management

- **Location**: `/opt/stacks/core/traefik/acme.json`
- **Permissions**: Must be `600` (read/write for owner only)
- **Backup**: Always backup this file - contains your certificates
- **Renewal**: Automatic, 30 days before expiration

## Testing vs Production Certificates

### Staging Server (For Testing)
```yaml
# In traefik.yml, add this line for testing:
caServer: https://acme-staging-v02.api.letsencrypt.org/directory
```

**Staging Benefits:**
- Unlimited certificates (no rate limits)
- Fast issuance for testing
- **Not trusted by browsers** (shows "Not Secure")

**When to use staging:**
- Setting up new environments
- Testing configurations
- Learning/development

### Production Server (For Live Use)
```yaml
# Remove or comment out caServer line for production
# certificatesResolvers:
#   letsencrypt:
#     acme:
#       # No caServer = production
```

**Production Limits:**

>This is why you want to use staging certificates for testing purposes!!!
>Always use staging certificates if you are running the setup & deploy scripts repeatedly

- **50 certificates per domain per week**
- **5 duplicate certificates per week**
- **Trusted by all browsers**

## Certificate Troubleshooting

### Check Certificate Status
```bash
# Count certificates in storage
python3 -c "import json; d=json.load(open('/opt/stacks/core/traefik/acme.json')); print(f'Certificates: {len(d[\"letsencrypt\"][\"Certificates\"])}')}"
```

### Common Issues & Solutions

**"Certificate not trusted" or "Not Secure" warnings:**
- **Staging certificates**: Expected - use production for live sites
- **DNS propagation**: Wait 5-10 minutes after setup
- **Browser cache**: Clear browser cache and try incognito mode

**Certificate request fails:**
- Check Traefik logs: `docker logs traefik | grep -i certificate`
- Verify DuckDNS token is correct in `.env`
- Ensure ports 80/443 are open and forwarded
- Wait 1+ hours between certificate requests

**Rate limit exceeded:**
- Switch to staging server for testing
- Wait 1 week for production limits to reset
- Check status at: https://letsencrypt.org/docs/rate-limits/

### DNS Challenge Process

When requesting certificates, Traefik:
1. Asks DuckDNS to set TXT record: `_acme-challenge.yourdomain.duckdns.org`
2. Let's Encrypt checks the TXT record to verify ownership
3. If valid, certificate is issued
4. TXT record is cleaned up automatically

**Note:** DuckDNS allows only ONE TXT record at a time. Multiple Traefik instances will conflict.

### Certificate Validation Commands

```bash
# Test certificate validity
echo | openssl s_client -connect yourdomain.duckdns.org:443 -servername dockge.yourdomain.duckdns.org 2>/dev/null | openssl x509 -noout -subject -issuer -dates

# Check if certificate covers wildcards
echo | openssl s_client -connect yourdomain.duckdns.org:443 -servername any-subdomain.yourdomain.duckdns.org 2>/dev/null | openssl x509 -noout -text | grep "Subject Alternative Name"
```

## Best Practices

### For Production
- Use production Let's Encrypt server
- Backup `acme.json` regularly
- Monitor certificate expiration (Traefik dashboard)
- Keep DuckDNS token secure

### For Development/Testing
- Use staging server to avoid rate limits
- Test with different subdomains
- Reset environments safely (preserve `acme.json` if possible)

### Security Notes
- Certificates are stored encrypted in `acme.json`
- Private keys never leave your server
- HTTPS provides encryption in transit
- Consider additional security headers in Traefik

## Certificate Lifecycle

- **Validity**: 90 days
- **Renewal**: Automatic, 30 days before expiration
- **Storage**: Persistent across container restarts
- **Backup**: Include in your homelab backup strategy