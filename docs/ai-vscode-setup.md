# AI-Assisted VS Code Setup

This guide will help you set up VS Code with GitHub Copilot to manage your AI-Homelab using AI assistance.

## Prerequisites

- VS Code installed on your local machine
- GitHub Copilot extension installed
- SSH access to your homelab server
- Basic familiarity with VS Code

## Step 1: Install Required Extensions

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for and install:
   - **GitHub Copilot** (by GitHub)
   - **Remote SSH** (by Microsoft) - for connecting to your server
   - **Docker** (by Microsoft) - for Docker support
   - **YAML** (by Red Hat) - for editing compose files

## Step 2: Connect to Your Homelab Server

1. In VS Code, open the Command Palette (Ctrl+Shift+P)
2. Type "Remote-SSH: Connect to Host..."
3. Enter your server's SSH details: `ssh user@your-server-ip`
4. Authenticate with your password or SSH key

## Step 3: Open the AI-Homelab Repository

1. Once connected to your server, open the terminal in VS Code (Ctrl+`)
2. Navigate to your repository:
   ```bash
   cd ~/AI-Homelab
   ```
3. Open the folder in VS Code: `File > Open Folder` and select `/home/your-user/AI-Homelab`

## Step 4: Enable GitHub Copilot

1. Make sure you're signed into GitHub in VS Code
2. GitHub Copilot should activate automatically
3. You can test it by opening a file and typing a comment or code

## Step 5: Use AI Assistance for Homelab Management

The AI assistant is configured with comprehensive knowledge of your homelab architecture. You can ask it to:

### Common Tasks
- **Add new services**: "Add a new service to my media stack"
- **Modify configurations**: "Change the port for my Plex service"
- **Troubleshoot issues**: "Why isn't my service starting?"
- **Update services**: "Update all services to latest versions"
- **Configure routing**: "Add Traefik routing for my new service"

### How to Interact
1. Open any relevant file (docker-compose.yml, configuration files)
2. Use comments to describe what you want: `# TODO: Add new service here`
3. Or use the chat interface: Ask questions in natural language
4. The AI will suggest edits, create new files, or run commands

### Example Prompts
- "Create a compose file for a new media service"
- "Help me configure Authelia for a new user"
- "Add VPN routing to my download service"
- "Set up monitoring for my new application"

## Step 6: Best Practices

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