# EZ-Homelab Release Notes - v0.1.0

## Overview
EZ-Homelab v0.1.0 is the first official release of this Docker homelab infrastructure. Tested on Debian 12, it deploys 50+ services with automated SSL, SSO authentication, and resource-efficient lazy loading. This release focuses on ease of setup, security, and scalability for self-hosted environments.

## What's New
- 🚀 **Sablier Lazy Loading**: Automatically starts services on-demand to save resources and reduce power costs. Enabled by default on most services; dependent services (e.g., *arr apps) load as groups.
- 🔒 **Security Enhancements**: Authelia SSO enabled by default (with optional 2FA); TLS certificates for Docker proxy; secure routing via Traefik.
- 🌐 **DNS & Proxy**: DuckDNS integration with Let's Encrypt wildcard SSL; Traefik routing for local services (via labels) and remote servers (via external host files). Subdomains like `service.yoursubdomain.duckdns.org` for web UIs, with multi-server support (e.g., `dockge.serverhostname.yoursubdomain.duckdns.org`).
- 📊 **Dashboards**: Preconfigured Homepage at `homepage.yoursubdomain.duckdns.org` for easy service access. Lazy loading requires stacks to be up.
- 🛠️ **Setup Improvements**: Unified `ez-homelab.sh` script with refined options; detailed UX for fresh OS installs.

## Services Included
Preconfigured with Traefik and Sablier (most require initial web UI setup):
- Core, Infrastructure, Dashboards, Media, Media Management, Productivity, Transcoders, Utilities, VPN, and Wikis stacks.
- **Notes**: Monitoring stack not yet configured for Traefik/Sablier. Alternatives stack is untested.

## Installation & Setup
- **Automated (Recommended)**: Run `./ez-homelab.sh` (Option 3 confirmed working on fresh Debian 12 with existing core server; Options 1 & 2 need additional testing).
- **Manual**: Follow [Manual Setup Guide](docs/manual-setup.md)—may require refinement.
- **Fresh OS Steps** (e.g., Debian):
  1. As root: `apt update && apt upgrade -y && apt install git sudo -y && usermod -aG sudo yourusername`.
  2. Exit and log in as user: `cd ~ && git clone https://github.com/kelinfoxy/EZ-Homelab.git`.
  3. Install Docker: `sudo ./scripts/ez-homelab.sh`.
  4. Exit/login and run: `./scripts/ez-homelab.sh` (without sudo).
- **Post-Setup**: Script provides Dockge link. Core, Infrastructure, and Dashboards stacks run automatically; others are inactive.

## Known Issues & Limitations
- **ez-homelab.sh**: Options 1 & 2 require additional testing.
- **Sablier**: May cause short delays, timeouts, or Bad Gateway errors on first access—refresh the page once the container is healthy.
- **Manual Install**: Instructions may need refinement.
- **GitHub Wiki**: Mostly accurate but needs updates.

## Upgrading from Previous Versions
No previous versions exist—this is the initial release. For future upgrades, pull latest images and redeploy via Dockge.

## Thanks & Feedback
Thanks to the community for early feedback! Report issues or contribute via GitHub. See [Getting Started](docs/getting-started.md) for more details.