This file contains the current configuration for Traefik & Sablier on the server jarvis (192.168.4.4)
This configuration was working in a previous test round.

external-host-jarvis.yml
```yaml
http:
  routers:
    backrest-jarvis:
      rule: "Host(`backrest.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: backrest-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-backrest@file
        - authelia@docker

    bookstack-jarvis:
      rule: "Host(`bookstack.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: bookstack-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-bookstack@file
        - authelia@docker
    
    bitwarden-jarvis:
      rule: "Host(`bitwarden.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: bitwarden-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-bitwarden@file
        - authelia@docker

    calibre-web-jarvis:
      rule: "Host(`calibre.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: calibre-web-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-calibre-web@file
        - authelia@docker

    code-jarvis:
      rule: "Host(`code.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: code-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-code-server@file
        - authelia@docker

    dockge-jarvis:
      rule: "Host(`jarvis.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: dockge-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - authelia@docker

    dockhand-jarvis:
      rule: "Host(`dockhand.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: dockhand-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - authelia@docker

    dokuwiki-jarvis:
      rule: "Host(`wiki.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: dokuwiki-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-dokuwiki@file
        - authelia@docker

    dozzle-jarvis:
      rule: "Host(`dozzle.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: dozzle-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-dozzle@file
        - authelia@docker

    duplicati-jarvis:
      rule: "Host(`duplicati.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: duplicati-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-duplicati@file
        - authelia@docker

    formio-jarvis:
      rule: "Host(`formio.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: formio-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-formio@file
        - authelia@docker

    gitea-jarvis:
      rule: "Host(`gitea.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: gitea-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-gitea@file
        - authelia@docker

    glances-jarvis:
      rule: "Host(`glances.jarvis.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: glances-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-glances@file
        - authelia@docker

    homepage-jarvis:
      rule: "Host(`homepage.jarvis.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: homepage-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - authelia@docker

    homarr-jarvis:
      rule: "Host(`homarr.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: homarr-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - authelia@docker
        - sablier-jarvis-homarr@file

    jellyfin-jarvis:
      rule: "Host(`jellyfin.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: jellyfin-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-jellyfin@file
        # No authelia middleware for media apps

    kopia-jarvis:
      rule: "Host(`kopia.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: kopia-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-kopia@file
        - authelia@docker

    mealie-jarvis:
      rule: "Host(`mealie.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: mealie-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-mealie@file
        - authelia@docker

    motioneye-jarvis:
      rule: "Host(`motioneye.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: motioneye-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - authelia@docker

    mediawiki-jarvis:
      rule: "Host(`mediawiki.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: mediawiki-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-mediawiki@file
        - authelia@docker

    nextcloud-jarvis:
      rule: "Host(`nextcloud.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: nextcloud-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-nextcloud@file
        - authelia@docker

    openkm-jarvis:
      rule: "Host(`openkm.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: openkm-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-openkm@file
        - authelia@docker

    openwebui-jarvis:
      rule: "Host(`openwebui.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: openwebui-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-openwebui@file
        - authelia@docker

    qbittorrent-jarvis:
      rule: "Host(`torrents.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: qbittorrent-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-arr@file
        - authelia@docker

    tdarr-jarvis:
      rule: "Host(`tdarr.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: tdarr-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-arr@file
        - authelia@docker

    unmanic-jarvis:
      rule: "Host(`unmanic.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: unmanic-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-unmanic@file
        - authelia@docker

    wordpress-jarvis:
      rule: "Host(`knot-u.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: wordpress-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-wordpress@file
        - authelia@file

# Arr Services (no SSO for media apps)
    
    jellyseerr-jarvis:
      rule: "Host(`jellyseerr.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: jellyseerr-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-arr@file
        - authelia@docker

    prowlarr-jarvis:
      rule: "Host(`prowlarr.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: prowlarr-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-arr@file
        - authelia@docker

    radarr-jarvis:
      rule: "Host(`radarr.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: radarr-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-arr@file
        - authelia@docker

    sonarr-jarvis:
      rule: "Host(`sonarr.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: sonarr-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-arr@file
        - authelia@docker

    lidarr-jarvis:
      rule: "Host(`lidarr.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: lidarr-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-arr@file
        - authelia@docker

    readarr-jarvis:
      rule: "Host(`readarr.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: readarr-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-arr@file
        - authelia@docker

    mylar3-jarvis:
      rule: "Host(`mylar3.kelinreij.duckdns.org`)"
      entryPoints:
        - websecure
      service: mylar3-jarvis
      tls:
        certResolver: letsencrypt
      middlewares:
        - sablier-jarvis-arr@file
        - authelia@docker

  services:
    backrest-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:9898"
        passHostHeader: true

    bitwarden-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8000"
        passHostHeader: true

    bookstack-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:6875"
        passHostHeader: true

    calibre-web-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8083"
        passHostHeader: true

    code-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8079"
        passHostHeader: true

    dockge-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:5001"
        passHostHeader: true

    dockhand-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:3003"
        passHostHeader: true

    dokuwiki-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8087"
        passHostHeader: true

    dozzle-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8085"
        passHostHeader: true

    duplicati-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8200"
        passHostHeader: true

    formio-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:3002"
        passHostHeader: true

    gitea-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:3010"
        passHostHeader: true

    glances-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:61208"
        passHostHeader: true

    homarr-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:7575"
        passHostHeader: true

    homepage-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:3000"
        passHostHeader: true

    jellyfin-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8096"
        passHostHeader: true

    kopia-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:51515"
        passHostHeader: true

    mealie-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:9000"
        passHostHeader: true

    mediawiki-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8084"
        passHostHeader: true

    motioneye-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8081"
        passHostHeader: true

    nextcloud-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8089"
        passHostHeader: true

    openkm-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:18080"
        passHostHeader: true

    openwebui-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:3004"
        passHostHeader: true

    qbittorrent-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8080"
        passHostHeader: true

    tdarr-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8265"
        passHostHeader: true

    unmanic-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8888"
        passHostHeader: true

    wordpress-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8088"
        passHostHeader: true

    # Arr Services

    jellyseerr-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:5055"
        passHostHeader: true

    prowlarr-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:9696"
        passHostHeader: true

    radarr-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:7878"
        passHostHeader: true

    sonarr-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8989"
        passHostHeader: true

    lidarr-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8686"
        passHostHeader: true

    readarr-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8787"
        passHostHeader: true

    mylar3-jarvis:
      loadBalancer:
        servers:
          - url: "http://192.168.4.11:8090"
        passHostHeader: true

```

sablier.yml
```yaml
http:
  middlewares:
    sablier-jarvis-arr:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-arr
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Arr Apps
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-backrest:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-backrest
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Backrest
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-bookstack:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-bookstack
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Bookstack
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-jellyfin:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-jellyfin
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Jellyfin
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-calibre-web:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-calibre-web
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Calibre Web
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-code-server:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-code-server
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Code Server
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-bitwarden:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-bitwarden
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: bitwarden
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-wordpress:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-wordpress
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: wordpress
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-nextcloud:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-nextcloud
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: NextCloud
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-mediawiki:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-mediawiki
          sessionDuration: 2m
          ignoreUserAgent: curl
          dynamic:
            displayName: mediawiki
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-mealie:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-mealie
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Mealie
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-gitea:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-gitea
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Gitea
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-formio:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-formio
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: FormIO
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-dozzle:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-dozzle
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: dozzle
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-duplicati:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-duplicati
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Duplicati
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-glances:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-glances
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Glances
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-homarr:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-homarr
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Homarr
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-komodo:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-komodo
          sessionDuration: 2m
          ignoreUserAgent: curl
          dynamic:
            displayName: Komodo
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-kopia:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-kopia
          sessionDuration: 2m
          ignoreUserAgent: curl
          dynamic:
            displayName: Kopia
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-openkm:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-openkm
          sessionDuration: 2m
          ignoreUserAgent: curl
          dynamic:
            displayName: OpenKM
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-openwebui:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: openwebui-jarvis
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: OpenWebUI
            theme: ghost
            show-details-by-default: true
            
    sablier-jarvis-pulse:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-pulse
          sessionDuration: 2m
          ignoreUserAgent: curl
          dynamic:
            displayName: Pulse
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-tdarr:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-tdarr
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Tdarr
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-unmanic:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-unmanic
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: Unmanic
            theme: ghost
            show-details-by-default: true

    sablier-jarvis-dokuwiki:
      plugin:
        sablier:
          sablierUrl: http://sablier-service:10000
          group: jarvis-dokuwiki  
          sessionDuration: 30m
          ignoreUserAgent: curl
          dynamic:
            displayName: DokuWiki
            theme: ghost
            show-details-by-default: true

    authelia:
      forwardauth:
        address: http://authelia:9091/api/verify?rd=https://auth.kelinreij.duckdns.org/
        authResponseHeaders:
          - X-Secret
        trustForwardHeader: true


```