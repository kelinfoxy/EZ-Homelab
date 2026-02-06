# Getting Started Guide

Welcome to your EZ-Homelab! This guide will walk you through setting up one or more homelab servers with Dockge, Traefik, Authelia, and [50+ services](services-overview.md).

## How It All Works

Before diving in, See [How Your AI Homelab Works](how-it-works.md) for a comprehensive overview.

## Getting Started Checklist
- [ ] Clone this repository to your home folder
- [ ] (optional) Configure `.env` file with your configuration details
- [ ] Forward ports 80 and 443 from your router to your **core server only**
- [ ] Run  ([ez-homelab.sh](../scripts/ez-homelab.sh))
- [ ] (Optional) Set up additional remote servers using option 3 in ez-homelab.sh
- [ ] Access Dockge web UI (`https://dockge.servername.${DOMAIN}`)
- [ ] Set up 2FA with Authelia ([Authelia setup guide](service-docs/authelia.md))
- [ ] Deploy additional stacks as needed via Dockge ([services overview](services-overview.md))
- [ ] Configure VS Code with GitHub Copilot to manage services ([AI management](.github/copilot-instructions.md))

## Setup Options

Choose the setup method that works best for you:

### 🚀 Automated Setup (Recommended)
For most users, the automated scripts handle everything.  
See [Automated Setup Guide](automated-setup.md) for step-by-step instructions.

### 🔧 Manual Setup
If you prefer manual control or the automated script fails,  
see the [Manual Setup Guide](manual-setup.md) for detailed instructions.

### 🤖 AI-Assisted Setup
Learn how to use VS Code with GitHub Copilot for AI-powered homelab management.  
See [AI VS Code Setup](ai-vscode-setup.md).

## SSL Certificates

Your homelab uses Let's Encrypt for automatic HTTPS certificates.  
See [SSL Certificates Guide](ssl-certificates.md) for details on certificate management and troubleshooting.

## What Comes Next

After setup, learn what to do with your running homelab. 
See [Post-Setup Guide](post-setup.md) for accessing services, customization, and maintenance.

## Multi-Server Deployments
>NOTE:  
**Core Server** refers to the server that has ports 80 & 443 forwarded to it.  
All other servers are refered to as **Remote Server(s)**

Learn how to set up lazy-loading services on remote servers that start automatically when accessed. Each server runs its own Traefik and Sablier for local container management, while the core server handles all external routing.

See [Multi-Server Deployment](multi-server-deployment.md) for detailed multi-server architecture and setup instructions.
