# EZ-Assistant Integration Guide

This guide explains how to integrate EZ-Assistant into your EZ-Homelab installation script.

## Files to Add

1. **ez-assistant-integration.sh**: Contains all the EZ-Assistant installation functions
2. **docker-compose.yml**: The Docker Compose configuration (already created)
3. **moltbot/config/moltbot.json**: Gateway configuration (already created)

## Integration Steps

### 1. Source the Integration Script

Add this line near the top of `ez-homelab.sh`, after the initial setup:

```bash
# Source EZ-Assistant integration
source "$(dirname "$0")/ez-assistant-integration.sh"
```

### 2. Add Menu Option

Find your main menu function and add the EZ-Assistant option:

```bash
echo "3) Install Docker + EZ-Homelab services"
echo "🤖 4) Install EZ-Assistant (AI Homelab Manager) - ~5-10 minutes"
echo "5) Exit"
```

### 3. Add Menu Handler

In your menu handling logic, add:

```bash
4)
    if install_ez_assistant; then
        echo "🎉 EZ-Assistant ready!"
    else
        echo "❌ EZ-Assistant installation failed, but EZ-Homelab setup continues..."
    fi
    ;;
```

### 4. Handle Dependencies

Ensure the script handles the case where Docker might not be installed yet:

- If user selects option 4 before installing Docker, show an error
- Or modify the logic to install Docker first if needed

## Configuration After Installation

After successful installation, users need to:

1. Edit `/opt/stacks/ez-assistant/.env` to add:
   - AI service keys (Claude, etc.)
   - Bot tokens (Telegram, Discord)

2. Set up Traefik routing for `assistant.yourdomain.com`

3. Configure the Moltbot gateway settings as needed

## Error Handling

The integration includes comprehensive error handling:

- System requirement checks
- Build failure recovery
- Service startup verification
- Clear user feedback

If EZ-Assistant fails to install, the main EZ-Homelab installation continues normally.

## Testing

Test the integration by:

1. Running the script on a fresh system
2. Selecting option 4 for EZ-Assistant
3. Verifying the build completes successfully
4. Checking that services start properly
5. Confirming the main script still works for options 1-3

## Maintenance

- Keep the Moltbot repository URL updated
- Monitor for changes in build requirements
- Update AI service configuration as needed</content>
<parameter name="filePath">/opt/stacks/ez-assistant/INTEGRATION_README.md