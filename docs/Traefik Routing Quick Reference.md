# Traefik Routing Quick Reference

## Variables (used throughout):

```yaml
  ${infrastructure}
  ${description}
  ${watchtower_enable}
  ${service}
  ${sso_enable}
  ${sablier_enable}
  ${traefik_enable}
  ${port}
```

## Compose file labels section

### Service metadata
```yaml
- homelab.category=${infrastructure}
- homelab.description=${description}
- com.centurylinklabs.watchtower.enable=${watchtower_enable}
```

### Traefik labels 

>**Traefik labels** are used for services on the same machine  
They are ignored when the service is on a different machine


```yaml
- "traefik.enable=${traefik_enable}"
- "traefik.http.routers.${service}.rule=Host(`${service}.${DOMAIN}`)"
- "traefik.http.routers.${service}.entrypoints=websecure"
- "traefik.http.routers.${service}.tls.certresolver=letsencrypt"
- "traefik.http.routers.${service}.middlewares=authelia@docker"
- "traefik.http.services.${service}.loadbalancer.server.port=${port}"
```

### Sablier lazy loading

```yaml
- sablier.enable=${sablier_enable}
- sablier.group=${SERVER_HOSTNAME}-${service}
- sablier.start-on-demand=true
```

## External Host Yml Files

>**Recomended**: use 1 yml file per host  

### external-host-production.yml
```yaml
http:
  # Routes for External Host Services
  routers:
    # External Service Routing Template
    ${service}-${SERVER_HOSTNAME}:
      rule: "Host(`${service}.${DOMAIN}`)"
      entryPoints:
        - websecure
      service: ${service}-${SERVER_HOSTNAME}
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-${SERVER_HOSTNAME}-${service}@file
        - authelia@docker

  # Middleware Definitions
  middlewares:


  # Service Definitions
  services:
    ${service}-${SERVER_HOSTNAME}:
      loadBalancer:
        servers:
          - url: "http://${SERVER_IP}:${port}"
        passHostHeader: true

```

## sablier.yml

```yaml
# Session duration set to 5m for testing. Increase to 30m for production.
http:
  middlewares:
    # Authelia SSO middleware
    authelia:
      forwardauth:
        address: http://authelia:9091/api/verify?rd=https://auth.${DOMAIN}/
        authResponseHeaders:
          - X-Secret
        trustForwardHeader: true

    # Sablier enabled Service Template
    sablier-${SERVER_HOSTNAME}-${service}:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: ${SERVER_HOSTNAME}-${service}
          sessionDuration: 5m
          ignoreUserAgent: curl
          dynamic:
            displayName: ${service}
            theme: ghost
            show-details-by-default: true


```
