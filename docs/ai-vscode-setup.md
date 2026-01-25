# AI-Assisted VS Code Setup

This guide shows you how to use VS Code with GitHub Copilot on your local PC to set up and manage your homelab server remotely. The AI assistant will help you configure your server from scratch.

## Prerequisites

- VS Code installed on your local PC
- GitHub Copilot extension installed
- SSH access to your homelab server (fresh Ubuntu/Debian install)
- Basic familiarity with VS Code

## Step 1: Install Required Extensions

1. Open VS Code on your local PC
2. Go to Extensions (Ctrl+Shift+X)
3. Search for and install:
   - **GitHub Copilot** (by GitHub) - AI assistant
   - **Remote SSH** (by Microsoft) - for connecting to your server
   - **Docker** (by Microsoft) - for Docker support
   - **YAML** (by Red Hat) - for editing compose files

## Step 2: Connect to Your Homelab Server

1. In VS Code, open the Command Palette (Ctrl+Shift+P)
2. Type "Remote-SSH: Connect to Host..."
3. Enter your server's SSH details: `ssh user@your-server-ip`
4. Authenticate with your password or SSH key

## Step 3: Use AI to Set Up Your Server

With VS Code connected to your server, you can now use GitHub Copilot to guide you through the entire setup process:

### Initial Server Setup
- **Clone repository**: Ask Copilot "Help me clone the AI-Homelab repository"
- **Configure environment**: "Guide me through setting up the .env file"
- **Run setup scripts**: "Walk me through running the ez-homelab.sh script"
- **Deploy services**: "Help me run the deployment script"

### AI-Assisted Configuration
The AI will help you:
- Generate secure passwords and API keys
- Configure domain settings and SSL certificates
- Set up user accounts and permissions
- Troubleshoot any issues that arise

## Step 4: Open the AI-Homelab Repository

1. Once connected to your server, open the terminal in VS Code (Ctrl+`)
2. Navigate to your repository:
   ```bash
   cd ~/AI-Homelab
   ```
3. Open the folder in VS Code: `File > Open Folder` and select `/home/your-user/AI-Homelab`

## Step 5: Enable GitHub Copilot

1. Make sure you're signed into GitHub in VS Code
2. GitHub Copilot should activate automatically
3. You can test it by opening a file and typing a comment or code

## How Services Get Added

### The AI Way (Recommended)
1. **Tell the AI**: "Add Plex to my media stack"
2. **AI Creates**: Docker Compose file with proper configuration
3. **AI Configures**: Traefik routing, Authelia protection, resource limits
4. **AI Deploys**: Service goes live with HTTPS and SSO
5. **AI Updates**: Homepage dashboard automatically

### Manual Way
1. **Find Service**: Choose from 50+ pre-configured services
2. **Upload to Dockge**: Use the web interface
3. **Configure**: Set environment variables and volumes
4. **Deploy**: Click deploy and wait
5. **Access**: Service is immediately available at `https://servicename.yourdomain.duckdns.org`

**Note**: If your core stack (Traefik, Authelia) is on a separate server, you'll need to:
- Configure external routing in Traefik's dynamic configuration
- Set up Sablier lazy loading rules for the remote server
- Ensure proper network connectivity between servers

## Storage Strategy

### Configuration Files
- **Location**: `/opt/stacks/stack-name/config/`
- **Purpose**: Service settings, databases, user data
- **Backup**: Included in automatic backups

### Media & Large Data
- **Location**: `/mnt/media/`, `/mnt/downloads/`
- **Purpose**: Movies, TV shows, music, downloads
- **Performance**: Direct mounted drives for speed
- **Important**: You'll need additional physical drives mounted at these locations for media storage

## AI Features

### VS Code Integration
- **Copilot Chat**: Natural language commands for infrastructure management
- **File Editing**: AI modifies Docker Compose files, configuration YAML
- **Troubleshooting**: AI analyzes logs and suggests fixes
- **Documentation**: AI keeps docs synchronized with deployed services
- **Direct File Access**: You can view and modify files directly in VS Code
- **Manual Changes**: Tell the AI to check your manual changes: "Review the changes I just made to the compose file"

## Scaling & Customization

### Adding Services
- **Pre-built**: 50+ services ready to deploy
- **Custom**: AI can create configurations for any Docker service
- **External**: Proxy services on other devices (Raspberry Pi, NAS)

### Deploying Additional Servers
You can deploy multiple servers for different purposes:

#### Core Stack on Separate Server
- **Purpose**: Dedicated server for reverse proxy, authentication, and VPN
- **Deployment**: Deploy core stack first on the dedicated server
- **Impact on Other Servers**:
  - **Traefik**: Configure external routing for services on other servers
  - **Sablier**: Set up lazy loading rules for remote services
  - **Compose Files**: Services reference the core server's Traefik network externally

#### Media Server Example
- **Server 1**: Core stack (Traefik, Authelia, Gluetun)
- **Server 2**: Media services (Plex, Sonarr, Radarr)
- **Configuration**: Media server compose files connect to core server's networks

## Port Forwarding Requirements

**Important**: You must forward ports 80 and 443 from your router to your homelab server for SSL certificates and web access to work.

### Router Configuration
1. Log into your router's admin interface
2. Find the port forwarding section
3. Forward:
   - **Port 80** (HTTP) → Your server's IP address
   - **Port 443** (HTTPS) → Your server's IP address
4. Save changes and test connectivity

### Why This Matters
- **SSL Certificates**: Let's Encrypt needs port 80 for domain validation
- **HTTPS Access**: All services use port 443 for secure connections
- **Wildcard Certificates**: Enables `*.yourdomain.duckdns.org` subdomains

## Best Practices

- **Always backup** before making changes
- **Test in isolation** - deploy single services first
- **Use the AI** for complex configurations
- **Read the documentation** linked in responses
- **Validate YAML** before deploying: `docker compose config`

## Troubleshooting

### Copilot Not Working
- Check your GitHub subscription includes Copilot
- Ensure you're signed into GitHub in VS Code
- Try reloading VS Code window

### SSH Connection Issues
- Verify SSH keys are set up correctly
- Check firewall settings on your server
- Ensure SSH service is running

### AI Not Understanding Context
- Open the relevant files first
- Provide specific file paths
- Include error messages when troubleshooting

## Next Steps

Once set up, you can manage your entire homelab through VS Code:
- Deploy new services
- Modify configurations
- Monitor logs
- Troubleshoot issues
- Scale your infrastructure

The AI assistant follows the same patterns and conventions as your existing setup, ensuring consistency and reliability.