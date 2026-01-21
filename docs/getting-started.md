# Getting Started Guide

Welcome to your AI-powered homelab! This guide will walk you through setting up your production-ready infrastructure with Dockge, Traefik, Authelia, and 50+ services.

## Getting Started Checklist
- [ ] Clone this repository to your home folder
- [ ] Configure `.env` file with your domain and tokens ([see prerequisites](#prerequisites))
- [ ] Run setup script (generates Authelia secrets and admin user) ([setup-homelab.sh](../scripts/setup-homelab.sh))
- [ ] Log out and back in for Docker group permissions
- [ ] Run deployment script (deploys all core, infrastructure & dashboard services) ([deploy-homelab.sh](../scripts/deploy-homelab.sh))
- [ ] Access Dockge web UI ([https://dockge.yourdomain.duckdns.org](https://dockge.yourdomain.duckdns.org))
- [ ] Set up 2FA with Authelia ([Authelia setup guide](service-docs/authelia.md))
- [ ] (optional) Deploy additional stacks as needed via Dockge ([services overview](services-overview.md))
- [ ] Configure and use VS Code with Github Copilot to manage the server ([AI management](.github/copilot-instructions.md))

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

After setup, learn what to do with your running homelab. See [Post-Setup Next Steps](post-setup-next-steps.md) for accessing services, customization, and maintenance.

## On-Demand Remote Services

For advanced users: Learn how to set up lazy-loading services on remote servers (like Raspberry Pi) that start automatically when accessed. See [On-Demand Remote Services](Ondemand-Remote-Services.md).
