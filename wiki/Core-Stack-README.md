# Core Stack

## The core stack contains the critical infrastructure for a homelab.

>There are always other options.  
I chose these for easy of use and file based configuration (so AI can do it all)

>For a multi server homelab, only install core services on one server.   

* DuckDNS with LetsEncrypt- Free subdomains and wildcard SSL Certificates
* Authelia - Single Sign On (SSO) Authentication with optional 2 Factor Authentication
* Traefik - Proxy Host Routing to access your services through your duckdns url
* Sablier - Both a container and a Traefik plugin, enables ondemand services (saving resources and power)

## DuckDNS with LetsEncrypt

Get your free subdomain at http://www.duckdns.org 

>Copy your DuckDNS Token, you'll need to add that to the .env file

DuckDNS service will keep your subdomain pointing to your IP address, even if it changes.

LetsEncrypt service will generate 2 certificates, one for your duckdns subdomain, and one wildcard for the same domain.  
The wildcard certificate is used by all the services. No need for an individual certificate per service.

Certificates will auto renew. This is a set it and forget service, no webui, no changes needed when adding a new service.

>It can take 2-5 minutes for the certificates to be generated and applied. Until then it will use a self signed certificate. You just need to accept the browser warnings. Once it's applied the browser warnings will go away.

## Authelia

Provides Single Sign On (SSO) Authentication for your services.

>Some services you may not want behind SSO, like Jellyfin/Plex if you watch your media through an app on a smart TV, firestick or phone.

* Optional 2 Factor Authentication
* Easy to enable/disable - Comment out 1 line in the compose file then bring the stack down and back up to disable (not restart)
* Configured on a per service basis
    * A public service (like wordpress) can bypass authelia login and let the service handle it's own authentication
    * Admin services (like dockge/portainer) can use 2 Factor Authorization for an extra layer of security

## Traefik

Provides proxy routing for your services so you can access them at a url like wordpress.my-subdoain.duckdns.org

For services on a Remote Host, create a file in the traefik/dynamic folder like my-server-external-host.yml  
Create 1 file per remote host.

## Sablier

Provides ondemand container management (start/pause/stop)

>Important: The stack must be up and the service stopped for Sablier to work.  
Tip: If you have a lot of services, use a script to get the services to that state.

If a service is down and anything requests the url for that service, Sablier will start the service and redirect after a short delay (however long it takes the service to come up), usually less than 20 seconds.

Once the set inactivity period has elapsed, Sablier will pause or stop the container according to the settings.

This saves resources and electricity. Allowing you have more services installed, configured, and ready to use even if the server is incapable of running all the services simultaniously. Great for single board computers, mini PCs, low resource systems, and your power bill. 
