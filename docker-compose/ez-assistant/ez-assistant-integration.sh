#!/bin/bash

# EZ-Assistant Integration for EZ-Homelab
# This file contains functions to be integrated into ez-homelab.sh

# EZ-Assistant Installation Functions
# Add these functions to your ez-homelab.sh script

check_ez_assistant_requirements() {
    echo "🔍 Checking EZ-Assistant requirements..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        return 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo "❌ Docker daemon is not running. Please start Docker."
        return 1
    fi

    # Check Git
    if ! command -v git &> /dev/null; then
        echo "❌ Git is not installed. Please install Git."
        return 1
    fi

    # Check available disk space (need at least 2GB)
    local available_space=$(df /tmp | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 2097152 ]; then  # 2GB in KB
        echo "❌ Insufficient disk space. Need at least 2GB free."
        return 1
    fi

    # Check internet connectivity
    if ! ping -c 1 github.com &> /dev/null; then
        echo "❌ No internet connection. Required for downloading Moltbot."
        return 1
    fi

    echo "✅ System requirements met"
    return 0
}

build_ez_assistant_image() {
    local build_dir="/tmp/moltbot-build-$$"
    local image_name="moltbot:local"

    echo "🔨 Building EZ-Assistant Docker image..."
    echo "   This may take 5-10 minutes depending on your internet connection"
    echo ""

    # Create temporary build directory
    mkdir -p "$build_dir"
    cd "$build_dir"

    # Clone Moltbot repository
    echo "📥 Cloning Moltbot repository..."
    if ! git clone https://github.com/moltbot/moltbot.git .; then
        echo "❌ Failed to clone Moltbot repository"
        cd /
        rm -rf "$build_dir"
        return 1
    fi

    # Create Dockerfile for the build
    cat > Dockerfile << 'EOF'
FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY pnpm-lock.yaml ./

# Install pnpm
RUN npm install -g pnpm

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN pnpm run build

# Expose ports
EXPOSE 3000 3001

# Set environment variables
ENV NODE_ENV=production

# Create non-root user
RUN useradd -m -u 1001 moltbot
USER moltbot

# Start the application
CMD ["pnpm", "start"]
EOF

    # Build the Docker image
    echo "🏗️  Building Docker image..."
    if ! docker build -t "$image_name" .; then
        echo "❌ Failed to build Docker image"
        cd /
        rm -rf "$build_dir"
        return 1
    fi

    # Clean up
    cd /
    rm -rf "$build_dir"

    echo "✅ Docker image built successfully: $image_name"
    return 0
}

setup_ez_assistant_config() {
    local stack_dir="/opt/stacks/ez-assistant"

    echo "⚙️  Setting up EZ-Assistant configuration..."

    # Create stack directory
    mkdir -p "$stack_dir"

    # Create .env file if it doesn't exist
    if [[ ! -f "$stack_dir/.env" ]]; then
        cat > "$stack_dir/.env" << 'EOF'
# EZ-Assistant Environment Configuration
# Add your API keys and bot tokens below

# AI Service API Keys (required for AI functionality)
# Get from: https://console.anthropic.com/
CLAUDE_API_KEY=your_claude_api_key_here

# Bot Tokens (optional - for Telegram/Discord integration)
# Telegram: Talk to @BotFather on Telegram to create a bot
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Discord: Create at https://discord.com/developers/applications
DISCORD_BOT_TOKEN=your_discord_bot_token_here

# Gateway Configuration
CLAWDBOT_GATEWAY_TOKEN=your_secure_gateway_token_here
CLAWDBOT_CLI_TOKEN=your_secure_cli_token_here

# Web UI Configuration
CLAWDBOT_WEB_USERNAME=admin
CLAWDBOT_WEB_PASSWORD=change_this_password
EOF
        echo "📝 Created $stack_dir/.env - Please edit with your API keys"
    else
        echo "ℹ️  .env file already exists"
    fi

    # Create moltbot config directory
    mkdir -p "$stack_dir/moltbot/config"

    # Create moltbot.json config
    cat > "$stack_dir/moltbot/config/moltbot.json" << 'EOF'
{
  "gateway": {
    "port": 3001,
    "token": "${CLAWDBOT_GATEWAY_TOKEN}",
    "cors": {
      "origin": "*"
    }
  },
  "cli": {
    "token": "${CLAWDBOT_CLI_TOKEN}",
    "gatewayUrl": "http://moltbot-gateway:3001"
  },
  "web": {
    "port": 3000,
    "username": "${CLAWDBOT_WEB_USERNAME}",
    "password": "${CLAWDBOT_WEB_PASSWORD}",
    "gatewayUrl": "http://moltbot-gateway:3001"
  },
  "ai": {
    "provider": "claude",
    "apiKey": "${CLAUDE_API_KEY}"
  },
  "bots": {
    "telegram": {
      "enabled": true,
      "token": "${TELEGRAM_BOT_TOKEN}"
    },
    "discord": {
      "enabled": true,
      "token": "${DISCORD_BOT_TOKEN}"
    }
  }
}
EOF

    echo "✅ Configuration files created"
    return 0
}

install_ez_assistant() {
    local stack_dir="/opt/stacks/ez-assistant"

    echo "🤖 Installing EZ-Assistant..."
    echo "   This will build Moltbot from source (5-10 minutes)"
    echo ""

    # Check requirements
    if ! check_ez_assistant_requirements; then
        echo "❌ Requirements not met. Skipping EZ-Assistant installation."
        return 1
    fi

    # Build Docker image
    if ! build_ez_assistant_image; then
        echo "❌ Failed to build EZ-Assistant image."
        return 1
    fi

    # Setup configuration
    if ! setup_ez_assistant_config; then
        echo "❌ Failed to setup EZ-Assistant configuration."
        return 1
    fi

    # Create docker-compose.yml
    cat > "$stack_dir/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  moltbot-gateway:
    image: moltbot:local
    container_name: moltbot-gateway
    restart: unless-stopped
    environment:
      - CLAWDBOT_MODE=gateway
    env_file:
      - .env
    volumes:
      - ./moltbot/config:/app/config:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - ez-homelab
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.assistant.rule=Host(`assistant.yourdomain.com`)"
      - "traefik.http.routers.assistant.entrypoints=websecure"
      - "traefik.http.routers.assistant.tls.certresolver=letsencrypt"
      - "traefik.http.services.assistant.loadbalancer.server.port=3000"
      - "traefik.http.middlewares.assistant-websocket.headers.customrequestheaders.X-Forwarded-Proto=https"
      - "traefik.http.middlewares.assistant-websocket.headers.customrequestheaders.X-Real-IP=$remote"
      - "traefik.http.middlewares.assistant-websocket.headers.customrequestheaders.X-Forwarded-Host=$host"
      - "traefik.http.routers.assistant.middlewares=assistant-websocket"

  moltbot-cli:
    image: moltbot:local
    container_name: moltbot-cli
    restart: unless-stopped
    environment:
      - CLAWDBOT_MODE=cli
    env_file:
      - .env
    volumes:
      - ./moltbot/config:/app/config:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - ez-homelab
    depends_on:
      - moltbot-gateway

networks:
  ez-homelab:
    external: true
EOF

    # Start the services
    echo "🚀 Starting EZ-Assistant services..."
    cd "$stack_dir"
    if ! docker-compose up -d; then
        echo "❌ Failed to start EZ-Assistant services."
        return 1
    fi

    # Wait for services to be healthy
    echo "⏳ Waiting for services to start..."
    sleep 10

    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        echo "✅ EZ-Assistant services started successfully!"
    else
        echo "⚠️  Services may still be starting. Check status with: docker-compose ps"
    fi

    echo ""
    echo "🔑 Important: Configure your AI service keys and bot tokens in:"
    echo "   $stack_dir/.env"
    echo ""
    echo "🤖 Your EZ-Assistant will be available at:"
    echo "   https://assistant.yourdomain.com (after Traefik setup)"
    echo ""
    echo "📚 For setup instructions, visit:"
    echo "   https://docs.ez-homelab.com/assistant"

    return 0
}