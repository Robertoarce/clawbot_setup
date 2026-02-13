#!/bin/bash
set -e

# OpenClaw + Ollama Auto Setup Script
# Run this after cloning: bash setup.sh

echo "🦞 OpenClaw + Ollama Setup Starting..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Check if Ollama is installed
echo -e "${YELLOW}[1/5]${NC} Checking Ollama installation..."
if ! command -v ollama &> /dev/null; then
    echo "Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo -e "${GREEN}✓${NC} Ollama already installed"
fi

# 2. Start Ollama service (if not running)
echo -e "${YELLOW}[2/5]${NC} Ensuring Ollama service is running..."
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama in background..."
    nohup ollama serve > /tmp/ollama.log 2>&1 &
    sleep 3
fi
echo -e "${GREEN}✓${NC} Ollama service running"

# 3. Pull the model
echo -e "${YELLOW}[3/5]${NC} Pulling Qwen 2.5 14B model (this may take a while)..."
if ollama list | grep -q "qwen2.5:14b"; then
    echo -e "${GREEN}✓${NC} Model already exists"
else
    ollama pull qwen2.5:14b
fi

# 4. Install OpenClaw
echo -e "${YELLOW}[4/5]${NC} Installing OpenClaw..."
if ! command -v openclaw &> /dev/null; then
    npm install -g openclaw
else
    echo -e "${GREEN}✓${NC} OpenClaw already installed"
fi

# 5. Configure OpenClaw
echo -e "${YELLOW}[5/5]${NC} Configuring OpenClaw..."

# Export environment variables
export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_API_KEY=ollama

# Add to shell profile for persistence
SHELL_RC="${HOME}/.bashrc"
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="${HOME}/.zshrc"
fi

if ! grep -q "OLLAMA_BASE_URL" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "# Ollama configuration for OpenClaw" >> "$SHELL_RC"
    echo "export OLLAMA_BASE_URL=http://localhost:11434" >> "$SHELL_RC"
    echo "export OLLAMA_API_KEY=ollama" >> "$SHELL_RC"
    echo -e "${GREEN}✓${NC} Added Ollama env vars to $SHELL_RC"
fi

# Create minimal config if it doesn't exist
if [ ! -f ~/.openclaw/openclaw.json ]; then
    mkdir -p ~/.openclaw
    cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "meta": {
    "lastTouchedVersion": "2026.2.9",
    "lastTouchedAt": "2026-02-13T12:00:00.000Z"
  },
  "agents": {
    "defaults": {
      "workspace": "/home/clawsy/.openclaw/workspace",
      "compaction": {
        "mode": "safeguard"
      },
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      },
      "models": {
        "ollama/qwen2.5:14b": {}
      }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token"
    }
  },
  "skills": {
    "install": {
      "nodeManager": "bun"
    }
  }
}
EOF
    echo -e "${GREEN}✓${NC} Created OpenClaw config"
fi

# Set the default model
openclaw models set ollama/qwen2.5:14b 2>/dev/null || true

# Create auth profile non-interactively
mkdir -p ~/.openclaw/credentials
if [ ! -f ~/.openclaw/credentials/auth-profiles.json ]; then
    cat > ~/.openclaw/credentials/auth-profiles.json << 'EOF'
{
  "profiles": {
    "ollama:manual": {
      "provider": "ollama",
      "type": "token",
      "token": "ollama"
    }
  }
}
EOF
    echo -e "${GREEN}✓${NC} Created auth profile"
fi

# Start the gateway
echo ""
echo "Starting OpenClaw gateway..."
openclaw gateway restart 2>/dev/null || openclaw gateway start 2>/dev/null || true

sleep 2

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Test your setup with:"
echo "  openclaw agent --local --to +15555550123 --message 'Hello, test'"
echo ""
echo "Check status:"
echo "  openclaw models list"
echo "  openclaw gateway status"
echo ""
echo "Open dashboard:"
echo "  openclaw dashboard"
echo ""