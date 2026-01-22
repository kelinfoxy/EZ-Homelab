# Sablier - Lazy Loading Service

## Table of Contents
- [Overview](#overview)
- [What is Sablier?](#what-is-sablier)
- [Why Use Sablier?](#why-use-sablier)
- [How It Works](#how-it-works)
- [Configuration in AI-Homelab](#configuration-in-ai-homelab)
- [Official Resources](#official-resources)
- [Educational Resources](#educational-resources)
- [Docker Configuration](#docker-configuration)
- [Using Sablier](#using-sablier)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

**Category:** Core Infrastructure
**Docker Image:** [sablierapp/sablier](https://hub.docker.com/r/sablierapp/sablier)
**Default Stack:** `core.yml`
**Web UI:** No web UI (API only)
**Authentication:** None required
**Purpose:** On-demand container startup and resource management

## What is Sablier?

Sablier is a lightweight service that enables lazy loading for Docker containers. It automatically starts containers when they're accessed through Traefik and stops them after a period of inactivity, helping to conserve system resources and reduce power consumption.

### Key Features
- **On-Demand Startup:** Containers start automatically when accessed
- **Automatic Shutdown:** Containers stop after configurable inactivity periods
- **Traefik Integration:** Works seamlessly with Traefik reverse proxy
- **Resource Conservation:** Reduces memory and CPU usage for unused services
- **Group Management:** Related services can be managed as groups
- **Health Checks:** Waits for services to be ready before forwarding traffic
- **Minimal Overhead:** Lightweight with low resource requirements

## Why Use Sablier?

1. **Resource Efficiency:** Save memory and CPU by only running services when needed
2. **Power Savings:** Reduce power consumption on always-on systems
3. **Faster Boot:** Services start quickly when accessed vs. waiting for full system startup
4. **Scalability:** Handle more services than would fit in memory simultaneously
5. **Cost Effective:** Lower resource requirements mean smaller/fewer servers needed
6. **Environmental:** Reduce energy consumption and carbon footprint

## How It Works

```
User Request → Traefik → Sablier Check → Container Start → Health Check → Forward Traffic
                                      ↓
                               Container Stop (after timeout)
```

When a request comes in for a service with Sablier enabled:

1. **Route Detection:** Sablier monitors Traefik routes for configured services
2. **Container Check:** Verifies if the target container is running
3. **Startup Process:** If not running, starts the container via Docker API
4. **Health Verification:** Waits for the service to report healthy
5. **Traffic Forwarding:** Routes traffic to the now-running service
6. **Timeout Monitoring:** Tracks inactivity and stops containers after timeout

## Configuration in AI-Homelab

Sablier is deployed as part of the core infrastructure stack and requires no additional configuration for basic operation. It automatically discovers services with the appropriate labels.

### Service Integration

Add these labels to any service that should use lazy loading:

```yaml
services:
  myservice:
    # ... other configuration ...
    labels:
      - "sablier.enable=true"
      - "sablier.group=core-myservice"  # Optional: group related services
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.${DOMAIN}`)"
      # ... other Traefik labels ...
```

### Advanced Configuration

For services requiring custom timeouts or group management:

```yaml
labels:
  - "sablier.enable=true"
  - "sablier.group=media-services"        # Group name for related services
  - "sablier.timeout=300"                 # 5 minutes inactivity timeout (default: 300)
  - "sablier.theme=dark"                  # Optional: theme for Sablier UI (if used)
```

## Official Resources

- **GitHub Repository:** https://github.com/sablierapp/sablier
- **Docker Hub:** https://hub.docker.com/r/sablierapp/sablier
- **Documentation:** https://sablierapp.github.io/sablier/

## Educational Resources

- **Traefik Integration:** https://doc.traefik.io/traefik/middlewares/http/forwardauth/
- **Docker Lazy Loading:** Search for "docker lazy loading" or "container on-demand"
- **Resource Management:** Linux container resource management best practices

## Docker Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SABLIER_PROVIDER` | Container runtime provider | `docker` | Yes |
| `SABLIER_DOCKER_API_VERSION` | Docker API version | `1.53` | No |
| `SABLIER_DOCKER_NETWORK` | Docker network for containers | `traefik-network` | Yes |
| `SABLIER_LOG_LEVEL` | Logging level (debug, info, warn, error) | `debug` | No |
| `DOCKER_HOST` | Docker socket endpoint | `tcp://docker-proxy:2375` | Yes |

### Ports

- **10000** - Sablier API endpoint (internal use only)

### Volumes

None required - Sablier communicates with Docker via API

### Networks

- **traefik-network** - Required for communication with Traefik
- **homelab-network** - Required for Docker API access

## Using Sablier

### Basic Usage

1. **Enable on Service:** Add `sablier.enable=true` label to any service
2. **Access Service:** Navigate to the service URL in your browser
3. **Automatic Startup:** Sablier detects the request and starts the container
4. **Wait for Ready:** Service starts and health checks pass
5. **Use Service:** Container is now running and accessible
6. **Automatic Shutdown:** Container stops after 5 minutes of inactivity

### Monitoring Lazy Loading

Check which services are managed by Sablier:

```bash
# View all containers with Sablier labels
docker ps --filter "label=sablier.enable=true" --format "table {{.Names}}\t{{.Status}}"

# Check Sablier logs
docker logs sablier

# View Traefik routes that trigger lazy loading
docker logs traefik | grep sablier
```

### Service Groups

Group related services that should start/stop together:

```yaml
# Database and web app in same group
services:
  myapp:
    labels:
      - "sablier.enable=true"
      - "sablier.group=myapp-stack"

  myapp-db:
    labels:
      - "sablier.enable=true"
      - "sablier.group=myapp-stack"
```

### Custom Timeouts

Set different inactivity timeouts per service:

```yaml
labels:
  - "sablier.enable=true"
  - "sablier.timeout=600"  # 10 minutes
```

## Advanced Topics

### Performance Considerations

- **Startup Time:** Services take longer to respond on first access
- **Resource Spikes:** Multiple services starting simultaneously can cause load
- **Health Checks:** Ensure services have proper health checks for reliable startup

### Troubleshooting Startup Issues

- **Container Won't Start:** Check Docker logs for the failing container
- **Health Check Fails:** Verify service health endpoints are working
- **Network Issues:** Ensure containers are on the correct Docker network

### Integration with Monitoring

Sablier works with existing monitoring:

- **Prometheus:** Can monitor Sablier API metrics
- **Grafana:** Visualize container start/stop events
- **Dozzle:** View logs from lazy-loaded containers

## Troubleshooting

### Service Won't Start Automatically

**Symptoms:** Accessing service URL shows connection error

**Solutions:**
```bash
# Check if Sablier is running
docker ps | grep sablier

# Verify service has correct labels
docker inspect container-name | grep sablier

# Check Sablier logs
docker logs sablier

# Test manual container start
docker start container-name
```

### Containers Not Stopping

**Symptoms:** Containers remain running after inactivity timeout

**Solutions:**
```bash
# Check timeout configuration
docker inspect container-name | grep sablier.timeout

# Verify Sablier has access to Docker API
docker exec sablier curl -f http://docker-proxy:2375/_ping

# Check for active connections
netstat -tlnp | grep :port
```

### Traefik Routing Issues

**Symptoms:** Service accessible but Sablier not triggering

**Solutions:**
```bash
# Verify Traefik labels
docker inspect container-name | grep traefik

# Check Traefik configuration
docker logs traefik | grep "Creating router"

# Test direct access (bypass Sablier)
curl http://container-name:port/health
```

### Common Issues

**Issue:** Services start but are not accessible
**Fix:** Ensure services are on the `traefik-network`

**Issue:** Sablier can't connect to Docker API
**Fix:** Verify `DOCKER_HOST` environment variable and network connectivity

**Issue:** Containers start but health checks fail
**Fix:** Add proper health checks to service configurations

**Issue:** High resource usage during startup
**Fix:** Stagger service startups or increase system resources

### Performance Tuning

- **Increase Timeouts:** For services that need longer inactivity periods
- **Group Services:** Related services can share startup/shutdown cycles
- **Monitor Resources:** Use Glances or Prometheus to track resource usage
- **Optimize Health Checks:** Ensure health checks are fast and reliable

### Getting Help

- **GitHub Issues:** https://github.com/sablierapp/sablier/issues
- **Community:** Check Traefik and Docker forums for lazy loading discussions
- **Logs:** Enable debug logging with `SABLIER_LOG_LEVEL=debug`
  - "sablier.start-on-demand=true"     # Enable lazy loading
```

### Traefik Middleware

Configure Sablier middleware in Traefik dynamic configuration:

```yaml
http:
  middlewares:
    sablier-service:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: core-service-name
          sessionDuration: 2m    # How long to keep service running after access
          ignoreUserAgent: curl  # Don't start service for curl requests
          dynamic:
            displayName: Service Name
            theme: ghost
            show-details-by-default: true
```

## Examples

### Basic Service with Lazy Loading

```yaml
services:
  my-service:
    image: my-service:latest
    container_name: my-service
    restart: "no"  # Important: Must be "no" for Sablier to control start/stop
    networks:
      - traefik-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-service.rule=Host(`my-service.${DOMAIN}`)"
      - "traefik.http.routers.my-service.entrypoints=websecure"
      - "traefik.http.routers.my-service.tls.certresolver=letsencrypt"
      - "traefik.http.routers.my-service.middlewares=authelia@docker"
      - "traefik.http.services.my-service.loadbalancer.server.port=8080"
      # Sablier lazy loading
      - "sablier.enable=true"
      - "sablier.group=core-my-service"
      - "sablier.start-on-demand=true"
```

### Remote Service Proxy

For services on remote servers, configure Traefik routes with Sablier middleware:

```yaml
# In /opt/stacks/core/traefik/dynamic/remote-services.yml
http:
  routers:
    remote-service:
      rule: "Host(`remote-service.${DOMAIN}`)"
      entryPoints:
        - websecure
      service: remote-service
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-remote-service@file

  services:
    remote-service:
      loadBalancer:
        servers:
          - url: "http://remote-server-ip:port"

  middlewares:
    sablier-remote-service:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: remote-server-group
          sessionDuration: 5m
          displayName: Remote Service
```

## Troubleshooting

### Service Won't Start

**Check Sablier logs:**
```bash
cd /opt/stacks/core
docker compose logs sablier-service
```

**Verify container permissions:**
```bash
# Check if Sablier can access Docker API
docker exec sablier-service curl -f http://localhost:10000/health
```

### Services Not Starting on Demand

**Check Traefik middleware configuration:**
```bash
# Verify middleware is loaded
docker logs traefik | grep sablier
```

**Check service labels:**
```bash
# Verify Sablier labels are present
docker inspect service-name | grep sablier
```

### Services Stop Too Quickly

**Increase session duration:**
```yaml
middlewares:
  sablier-service:
    plugin:
      sablier:
        sessionDuration: 10m  # Increase from default
```

### Performance Issues

**Check resource usage:**
```bash
docker stats sablier-service
```

**Monitor Docker API calls:**
```bash
docker logs sablier-service | grep "API call"
```

## Best Practices

### Resource Management

- Use lazy loading for services that aren't accessed frequently
- Set appropriate session durations based on usage patterns
- Monitor resource usage to ensure adequate system capacity

### Configuration

- **Always set `restart: "no"`** for Sablier-managed services to allow full lifecycle control
- Group related services together for coordinated startup
- Use descriptive display names for the loading page
- Configure appropriate timeouts for your use case

### Security

- Sablier runs with Docker API access - ensure proper network isolation
- Use Docker socket proxy for additional security
- Monitor Sablier logs for unauthorized access attempts

## Integration with Other Services

### Homepage Dashboard

Add Sablier status to Homepage:

```yaml
# In homepage config
- Core Infrastructure:
    - Sablier:
        icon: docker.png
        href: http://sablier-service:10000
        description: Lazy loading service
        widget:
          type: iframe
          url: http://sablier-service:10000
```

### Monitoring

Monitor Sablier with Prometheus metrics (if available) or basic health checks:

```yaml
# Health check
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:10000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## Advanced Configuration

### Custom Themes

Sablier supports different loading page themes:

```yaml
dynamic:
  displayName: My Service
  theme: ghost      # Options: ghost, hacker, ocean, etc.
  show-details-by-default: true
```

### Group Management

Services can be grouped for coordinated startup:

```yaml
# All services in the same group start together
labels:
  - "sablier.group=media-stack"
  - "sablier.enable=true"
  - "sablier.start-on-demand=true"
```

### API Access

Sablier provides a REST API for programmatic control:

```bash
# Get service status
curl http://sablier-service:10000/api/groups

# Start a service group
curl -X POST http://sablier-service:10000/api/groups/media-stack/start

# Stop a service group
curl -X POST http://sablier-service:10000/api/groups/media-stack/stop
```

## Migration from Manual Management

When adding Sablier to existing services:

1. **Change restart policy** to `"no"` in the compose file (critical for Sablier control)
2. **Add Sablier labels** to the service compose file
3. **Configure Traefik middleware** for the service
4. **Stop the service** initially (let Sablier manage it)
5. **Test access** - service should start automatically
6. **Monitor logs** to ensure proper operation

> **Important**: Services managed by Sablier must have `restart: "no"` to allow Sablier full control over container lifecycle. Do not use `unless-stopped`, `always`, or `on-failure` restart policies.

## Related Documentation

- [Traefik Documentation](traefik.md) - Reverse proxy configuration
- [Authelia Documentation](authelia.md) - SSO authentication
- [On-Demand Remote Services](../Ondemand-Remote-Services.md) - Remote service setup guide