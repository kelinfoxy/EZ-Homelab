# SSL Certificate Issues with DuckDNS DNS Challenge

## Issue Summary
Wildcard SSL certificate acquisition via DuckDNS DNS-01 challenge consistently fails due to network connectivity issues with DuckDNS authoritative nameservers.

## Root Cause Analysis

### Why Both Domain and Wildcard are Required
Let's Encrypt requires validation of BOTH domains when using SAN (Subject Alternative Name) certificates:
- `yourdomain.duckdns.org` (apex domain)
- `*.yourdomain.duckdns.org` (wildcard)

This is a Let's Encrypt policy - you cannot obtain just the wildcard certificate. Both must be validated simultaneously.

### Technical Root Cause: Unreachable Authoritative Nameservers

**Problem**: DuckDNS authoritative nameservers (ns1-ns9.duckdns.org) are **unreachable** from the test system's network.

**Evidence**:
```bash
# Direct ping to DuckDNS nameservers - 100% packet loss
ping -c 2 ns1.duckdns.org  # FAIL: 100% packet loss
ping -c 2 99.79.143.35     # FAIL: 100% packet loss (direct IP)

# DNS queries to authoritative servers - timeout
dig @99.79.143.35 yourdomain.duckdns.org  # FAIL: timeout
dig @35.182.183.211 yourdomain.duckdns.org  # FAIL: timeout
dig @3.97.58.28 yourdomain.duckdns.org  # FAIL: timeout

# Queries to recursive resolvers - SUCCESS
dig @8.8.8.8 yourdomain.duckdns.org  # SUCCESS
dig @1.1.1.1 yourdomain.duckdns.org  # SUCCESS

# Traceroute analysis
traceroute 99.79.143.35
# Shows traffic reaching hop 5 (74.41.143.193) then black hole
# DuckDNS nameservers are hosted on Amazon AWS
# Suggests AWS security groups or ISP blocking
```

**Why This Matters**: 
Traefik's ACME client (lego library) requires verification against authoritative nameservers after setting TXT records. Even though:
- DuckDNS API successfully sets TXT records ✅
- TXT records propagate to public DNS (8.8.8.8, 1.1.1.1) ✅
- Recursive DNS queries work ✅

The lego library **must** also query the authoritative nameservers directly to verify propagation, and this step fails due to network unreachability.

## Attempted Solutions

### Configuration Optimizations Tried

1. **Increased propagation delay** - `delayBeforeCheck: 300` (5 minutes)
   - Result: Delay worked, but authoritative NS check still failed

2. **Extended timeout** - `DUCKDNS_PROPAGATION_TIMEOUT=600` (10 minutes)
   - Result: Longer timeout observed, but same NS unreachability issue

3. **LEGO environment variables**:
   ```yaml
   - LEGO_DISABLE_CNAME_SUPPORT=true
   - LEGO_EXPERIMENTAL_DNS_TCP_SUPPORT=true
   - LEGO_DNS_TIMEOUT=60
   - LEGO_DNS_RESOLVERS=1.1.1.1:53,8.8.8.8:53
   - LEGO_DISABLE_CP=true
   ```
   - Result: Forced use of recursive resolvers for some queries, but SOA lookups still failed

4. **Explicit Docker DNS configuration**:
   ```yaml
   dns:
     - 1.1.1.1
     - 8.8.8.8
   ```
   - Result: Container used correct resolvers, but lego still attempted authoritative NS queries

5. **VPN routing test** (through Gluetun container)
   - Result: DuckDNS nameservers also unreachable through VPN

### Error Messages Observed

**Phase 1: Direct authoritative nameserver timeout**
```
propagation: time limit exceeded: last error: authoritative nameservers: 
DNS call error: read udp 172.19.0.2:53666->3.97.58.28:53: i/o timeout 
[ns=ns6.duckdns.org.:53, question='_acme-challenge.yourdomain.duckdns.org. IN TXT']
```

**Phase 2: SOA record query failure**
```
propagation: time limit exceeded: last error: could not find zone: 
[fqdn=_acme-challenge.yourdomain.duckdns.org.] 
unexpected response for 'yourdomain.duckdns.org.' 
[question='yourdomain.duckdns.org. IN SOA', code=SERVFAIL]
```

## Working Configuration (Self-Signed Certificates)

Current deployment is **fully functional** with self-signed certificates:
- All services accessible via HTTPS ✅
- Can proceed through browser certificate warnings ✅
- Traefik routing works correctly ✅
- Authelia SSO functional ✅
- All stacks deployed successfully ✅

## Recommended Solutions for Next Test Run

### Option 1: Switch to Cloudflare DNS (RECOMMENDED)
**Pros**:
- Cloudflare nameservers are highly reliable and globally accessible
- Supports wildcard certificates via DNS-01 challenge
- Better performance and propagation times
- Well-tested with Traefik

**Steps**:
1. Move domain to Cloudflare (free tier sufficient)
2. Obtain Cloudflare API token (Zone:DNS:Edit permission)
3. Update `traefik.yml`:
   ```yaml
   dnsChallenge:
     provider: cloudflare
     delayBeforeCheck: 30  # Cloudflare propagates quickly
     resolvers:
       - "1.1.1.1:53"
       - "1.0.0.1:53"
   ```
4. Update `docker-compose.yml`:
   ```yaml
   environment:
     - CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
   ```

### Option 2: Investigate Network Blocking
**Diagnostic Steps**:
1. Test from different network (mobile hotspot, different ISP)
2. Contact ISP to check if AWS IP ranges are blocked
3. Check router/firewall for DNS filtering or AWS blocking
4. Test with different VPN provider

**If network is the issue**: 
- May need to use VPN or proxy for Traefik container
- Consider hosting Traefik on different network segment

### Option 3: HTTP-01 Challenge (Non-Wildcard)
**Pros**:
- More reliable (no DNS dependencies)
- Works with current DuckDNS setup
- No external nameserver queries required

**Cons**:
- ❌ No wildcard certificate (must specify each subdomain)
- Requires port 80 accessible from internet
- Separate certificate for each subdomain

**Steps**:
1. Update `traefik.yml`:
   ```yaml
   httpChallenge:
     entryPoint: web
   ```
2. Remove wildcard domain label from Traefik service:
   ```yaml
   # Remove this line:
   - "traefik.http.routers.traefik.tls.domains[0].sans=*.${DOMAIN}"
   ```
3. Add explicit TLS configuration to each service's labels

### Option 4: Use Alternative DNS Provider with DuckDNS
Keep DuckDNS for dynamic IP updates, but use different DNS for certificates:
1. Use Cloudflare for DNS records
2. Keep DuckDNS container for IP updates
3. Create CNAME in Cloudflare pointing to DuckDNS
4. Use Cloudflare for certificate challenge

## Files to Update in Repository

### ~/AI-Homelab/stacks/core/traefik/traefik.yml
Document both HTTP and DNS challenge configurations with clear comments.

### ~/AI-Homelab/stacks/core/docker-compose.yml
Ensure wildcard domain configuration is correct (it is currently):
```yaml
- "traefik.http.routers.traefik.tls.domains[0].main=${DOMAIN}"
- "traefik.http.routers.traefik.tls.domains[0].sans=*.${DOMAIN}"
```
**This is correct** - keep both apex and wildcard.

### ~/EZ-Homelab/docs/service-docs/traefik.md
Add troubleshooting section for DuckDNS DNS challenge issues.

## Success Criteria for Next Test

### Must Have:
- [ ] Valid wildcard SSL certificate obtained
- [ ] Certificate automatically renews
- [ ] No browser certificate warnings
- [ ] Documented working configuration

### Should Have:
- [ ] Certificate acquisition completes in < 5 minutes
- [ ] Reliable across multiple test runs
- [ ] Clear error messages if failure occurs

## Timeline Analysis

**First Test Run**: Certificates reportedly worked
**Current Test Run**: Consistent failures

**Possible Explanations**:
1. DuckDNS infrastructure changes (AWS security policies)
2. ISP routing changes
3. Increased AWS security after abuse/attacks
4. Different network environment during first test

## Conclusion

**Current Status**: System is production-ready except for SSL certificate warnings.

**Blocking Issue**: DuckDNS authoritative nameservers unreachable from current network environment.

**Recommendation**: **Switch to Cloudflare DNS** for next test run. This is the most reliable solution and is the industry standard for automated certificate management with Traefik.

**Alternative**: If staying with DuckDNS is required, investigate network connectivity issues with ISP and consider using HTTP-01 challenge (losing wildcard capability).
