# On Demand Remote Services with Authelia, Sablier & Traefik

## 4 Step Process
1. Add route & service in Traefik external hosts file
2. Add middleware in Sablier config file (sablier.yml)
3. Add labels to compose files on Remote Host
4. Restart services

## Required Information
```bash
<server> - the hostname of the remote server

<service> - the application/container name

<full domain> - the base url for your proxy host (my-subdomain.duckdns.org)

<ip address> - the ip address of the remote server

<port> - the external port exposed by the service

<service display name> - how it will appear on the now loading page

<group name> - use <service name> for a single service, or something descriptive for the group of services that will start together.
  
```  
## Step 1: Add route & service in Traefik external hosts file

### In /opt/stacks/core/traefik/dynamic/external-host-server_name.yml  

```yaml
http:
    routers:
        # Add a section under routers for each Route (Proxy Host)
        <service>-<server>:
            rule: "Host(`<service>.<full domain>`)"
            entryPoints:
                - websecure
            service: <service>-<server>
            tls:
                certResolver: letsencrypt
            middlewares:
                - sablier-<server>-<service>@file
                - authelia@docker   # comment this line to disable SSO login

        # next route goes here

# All Routes go above this line
# Services section defines each service used above
services:
    <service>-<server>:
    loadBalancer:
        servers:
        - url: "http://<ip address>:<port>"
        passHostHeader: true
    
    # next service goes here
```
## Step 2: Add middlware to sablier config file

### In /opt/stacks/core/traefik/dynamic/sablier.yml  

```yaml
http:
    middlwares:
        # Add a section under middlewares for each Route (Proxy Host)
        sablier-<server>-<service>:
            plugin:
                sablier:
                sablierUrl: http://sablier-service:10000
                group: <server>-<group name>
                sessionDuration: 2m     # Increase this for convience
                ignoreUserAgent: curl   # Don't wake the service for a curl command
                dynamic:
                    displayName: <service display name>
                    theme: ghost        # This can be changed
                    show-details-by-default: true   # May want to disable for production

        # Next middleware goes here
```
## Step 3: Add labels to compose files on Remote Host

## On the Remote Server 

### Apply lables to the services in the compose files

```yaml
    labels:
      - sablier.enable=true
      - sablier.group=<server>-<group name>
      - sablier.start-on-demand=true

```

>**Note**:  
Traefik & Authelia labels are not used in the compose file for Remote Hosts

## Step 4: Restart services

### On host system

```bash
docker restart traefik
docker restart sablier-service
```

### On the Remote Host

```bash
cd /opt/stacks/<service>
docker compose down && docker compose up -d
docker stop <service>
```

## Setup Complete

Access your service by the proxy url.

