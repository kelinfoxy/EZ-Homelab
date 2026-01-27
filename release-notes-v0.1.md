# Release Notes  v0.1

## ez-homelab.sh

* Options 1 & 2: Require additional testing  
* Option 3: Confirmed working on fresh Debian 12 install with an existing core server.

## Manual Install Instructions

* May require some refinement

## Security

* Authelia SSO 
* Optional 2FA
* TLS Certificates for docker-proxy
* SSO enabled by default (except for special cases)

## DNS & Proxy

* DuckDNS & LetsEncrypt
* Traefik routing via lables for local services
* Traefik routing via external host files for remote servers
* service.yoursubdomain.duckdns.org subdomains for all exposed webui
* service.serverhostname.yoursubdomain.duckdns.org for services that are likely to run on multiple servers (dockge, glances, etc)

## Sablier lazyloading of services

>**WHY?** Saves resounces, reduces power bills, allows for running a ton of services without overtaxing your server.  

>Requires the stack to be up.

* Enabled on most services by default
* Dependant services are loaded as a group (like the arr apps)

>**Downsides** Short delay while the service starts.  
Occasional time-out or Bad Gateway errors in browser.  
Refreshing the page will work once the container is healthy.


## UX - Setup

On a fresh install of an OS, like Debian
* Log in as root and run (replace yourusername with the username created during install)  
    `apt update && apt upgrade -y && apt install git sudo -y && usermod -aG sudo yourusername`
* Run `exit` to log out
* Log in with your username
* Change directory to your home folder  
    `cd ~`
* Run `git clone https://github.com/kelinfoxy/EZ-Homelab.git`
* run `sudo ./scripts/ez-homelab.sh` to install docker
* Log out (`exit`) and back in
* Run `./scripts/ez-homelab.sh` (without sudo) to perform the install

**Once complete**  
* the script provides a link to open Dockge in a browser
* The core stack (if installed) is running
* The infrastructure stack is running
* The dashboards stack is running  
* All remaining stacks show as inactive

## UX - Dashboards

>**REMEMBER** Lazyloading only works if the stacks are up
* Homepage is the default dashboard
* homepage.yoursubdomain.duckdns.org
* Preconfigured to work out of the box

# Services Preconfigured wtih Traefik and Sablier
>**NOTE**: Most services require an initial setup in the webui on first launch

* Core stack
* Infrastructure stack
* Dashboards stack
* Media stack
* Media Management stack
* Productivity stack
* Transcoders stack
* Utilities stack
* VPN stack
* Wikis stack

The Monitoring stack is not configured for traefik/sablier yet

The Alternatives stack is completely untested.

## Github Wiki

Mostly accurate, needs refinement
