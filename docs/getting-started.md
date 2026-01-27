# Getting Started Guide

Welcome to your AI-powered homelab! This guide will walk you through setting up your production-ready infrastructure with Dockge, Traefik, Authelia, and [50+ services](services-overview.md).

## Release v0.1.0 Highlights
This is the first official release of EZ-Homelab, thoroughly tested on Debian 12. Key features include:
- Automated SSL via DuckDNS and Let's Encrypt.
- Authelia SSO enabled by default for security.
- Sablier lazy loading to save resources.
- 50+ preconfigured services across 10 stacks.
- See [Release Notes](../release-notes-v0.1.0.md) for full details.

## Getting Started Checklist
- [ ] Clone this repository to your home folder
- [ ] Configure `.env` file with your domain and tokens ([see prerequisites](env-configuration.md))
- [ ] Forward ports 80 and 443 from your router to your server
- [ ] Run unified setup script (generates Authelia secrets and admin user, deploys services) ([ez-homelab.sh](../scripts/ez-homelab.sh))
- [ ] Access Dockge web UI (`https://dockge.${DOMAIN}`)
- [ ] Set up 2FA with Authelia ([Authelia setup guide](service-docs/authelia.md))
- [ ] (optional) Deploy additional stacks as needed via Dockge ([services overview](services-overview.md))
- [ ] Configure and use VS Code with Github Copilot to manage the server ([AI management](.github/copilot-instructions.md) | [Example prompts](ai-management-prompts.md))

## Setup Options

Choose the setup method that works best for you:

### 🚀 Automated Setup (Recommended)
For most users, the automated scripts handle everything. See [Automated Setup Guide](automated-setup.md) for step-by-step instructions.

### 🔧 Manual Setup
If you prefer manual control or the automated script fails, see the [Manual Setup Guide](manual-setup.md) for detailed instructions.

### 🤖 AI-Assisted Setup
Learn how to use VS Code with GitHub Copilot for AI-powered homelab management. See [AI VS Code Setup](ai-vscode-setup.md).

## How It All Works

Before diving in, understand how your homelab infrastructure works together. See [How Your AI Homelab Works](how-it-works.md) for a comprehensive overview.

## SSL Certificates

Your homelab uses Let's Encrypt for automatic HTTPS certificates. See [SSL Certificates Guide](ssl-certificates.md) for details on certificate management and troubleshooting.

## What Comes Next

After setup, learn what to do with your running homelab. See [Post-Setup Guide](post-setup.md) for accessing services, customization, and maintenance.

## On-Demand Remote Services

For advanced users: Learn how to set up lazy-loading services on remote servers (like Raspberry Pi) that start automatically when accessed. See [On-Demand Remote Services](Ondemand-Remote-Services.md).
