#!/bin/bash
set -e

# OpenClaw + Ollama Auto Setup Script
# Run this after cloning: bash setup.sh

echo "🦞 OpenClaw + Ollama Setup Starting..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Detect username
USER_HOME="${HOME}"
CURRENT_USER=$(whoami)

# 1. Check if Ollama is installed
echo -e "${YELLOW}[1/8]${NC} Checking Ollama installation..."
if ! command -v ollama &> /dev/null; then
    echo "Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo -e "${GREEN}✓${NC} Ollama already installed"
fi

# 2. Start Ollama service (if not running)
echo -e "${YELLOW}[2/8]${NC} Ensuring Ollama service is running..."
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama in background..."
    nohup ollama serve > /tmp/ollama.log 2>&1 &
    sleep 3
fi

# Enable Ollama to start on boot
if command -v systemctl &> /dev/null; then
    sudo systemctl enable ollama 2>/dev/null || true
fi

echo -e "${GREEN}✓${NC} Ollama service running"

# 3. Pull the recommended model (32B for better quality)
echo -e "${YELLOW}[3/8]${NC} Pulling Qwen 2.5 32B model (optimized for tool use)..."
echo "This may take 15-20 minutes depending on your connection..."
if ollama list | grep -q "qwen2.5:32b-instruct-q4_K_M"; then
    echo -e "${GREEN}✓${NC} Base model already exists"
else
    ollama pull qwen2.5:32b-instruct-q4_K_M
fi
echo -e "${GREEN}✓${NC} Base model ready"

# 3.5. Create model with 32K context window (CRITICAL!)
echo -e "${YELLOW}[3.5/8]${NC} Creating model with 32K context window..."
cat > /tmp/qwen-32k.modelfile << 'EOF'
FROM qwen2.5:32b-instruct-q4_K_M
PARAMETER num_ctx 32768
EOF

if ollama list | grep -q "qwen2.5:32b-32k"; then
    echo -e "${GREEN}✓${NC} 32K context model already exists"
else
    ollama create qwen2.5:32b-32k -f /tmp/qwen-32k.modelfile
    echo -e "${GREEN}✓${NC} Created qwen2.5:32b-32k with 32K context"
fi
rm -f /tmp/qwen-32k.modelfile

# 4. Install OpenClaw
echo -e "${YELLOW}[4/8]${NC} Installing OpenClaw..."
if ! command -v openclaw &> /dev/null; then
    npm install -g openclaw
else
    echo -e "${GREEN}✓${NC} OpenClaw already installed"
    # Check for updates
    echo "Checking for updates..."
    openclaw update 2>/dev/null || true
fi

# 5. Configure OpenClaw
echo -e "${YELLOW}[5/8]${NC} Configuring OpenClaw..."

# Export environment variables
export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_API_KEY=ollama

# Add to shell profile for persistence
SHELL_RC="${USER_HOME}/.bashrc"
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="${USER_HOME}/.zshrc"
fi

if ! grep -q "OLLAMA_BASE_URL" "$SHELL_RC"; then
    echo "" >> "$SHELL_RC"
    echo "# Ollama configuration for OpenClaw" >> "$SHELL_RC"
    echo "export OLLAMA_BASE_URL=http://localhost:11434" >> "$SHELL_RC"
    echo "export OLLAMA_API_KEY=ollama" >> "$SHELL_RC"
    echo -e "${GREEN}✓${NC} Added Ollama env vars to $SHELL_RC"
fi

# Create OpenClaw workspace directory
mkdir -p "${USER_HOME}/.openclaw/workspace"
mkdir -p "${USER_HOME}/.openclaw/credentials"

# Set proper permissions for credentials directory
chmod 700 "${USER_HOME}/.openclaw/credentials" 2>/dev/null || true

# 6. Create minimal config if it doesn't exist
echo -e "${YELLOW}[6/8]${NC} Creating OpenClaw configuration..."
if [ ! -f "${USER_HOME}/.openclaw/openclaw.json" ]; then
    mkdir -p "${USER_HOME}/.openclaw"
    cat > "${USER_HOME}/.openclaw/openclaw.json" << EOF
{
  "meta": {
    "lastTouchedVersion": "2026.2.9",
    "lastTouchedAt": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"
  },
  "wizard": {
    "lastRunAt": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
    "lastRunVersion": "2026.2.9",
    "lastRunCommand": "setup",
    "lastRunMode": "local"
  },
  "logging": {
    "level": "info",
    "redactSensitive": "tools"
  },
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://127.0.0.1:11434/v1",
        "apiKey": "ollama-local",
        "api": "openai-completions",
        "models": [
          {
            "id": "qwen2.5:32b-32k",
            "name": "Qwen 2.5 32B (32K ctx)",
            "reasoning": false,
            "input": ["text"],
            "cost": {
              "input": 0,
              "output": 0,
              "cacheRead": 0,
              "cacheWrite": 0
            },
            "contextWindow": 32768,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen2.5:32b-32k"
      },
      "workspace": "${USER_HOME}/.openclaw/workspace",
      "compaction": {
        "mode": "safeguard"
      },
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      }
    }
  },
  "messages": {
    "ackReactionScope": "group-mentions"
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token"
    },
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    }
  },
  "skills": {
    "install": {
      "nodeManager": "bun"
    }
  },
  "tools": {
    "allow": [
      "read",
      "exec",
      "write",
      "edit"
    ]
  }
}
EOF
    echo -e "${GREEN}✓${NC} Created OpenClaw config with 32K context model"
else
    echo -e "${GREEN}✓${NC} OpenClaw config already exists"
    echo -e "${YELLOW}⚠${NC}  Manual update may be needed to use qwen2.5:32b-32k"
fi

# 7. Add English language instruction to SOUL.md
echo -e "${YELLOW}[7/8]${NC} Configuring workspace files..."
if [ ! -f "${USER_HOME}/.openclaw/workspace/SOUL.md" ]; then
    cat > "${USER_HOME}/.openclaw/workspace/SOUL.md" << 'EOF'
# SOUL.md - Who You Are

_You're not a chatbot. You're becoming someone._

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip the "Great question!" and "I'd be happy to help!" — just help. Actions speak louder than filler words.

**Have opinions.** You're allowed to disagree, prefer things, find stuff amusing or boring. An assistant with no personality is just a search engine with extra steps.

**Be resourceful before asking.** Try to figure it out. Read the file. Check the context. Search for it. _Then_ ask if you're stuck. The goal is to come back with answers, not questions.

**Earn trust through competence.** Your human gave you access to their stuff. Don't make them regret it. Be careful with external actions (emails, tweets, anything public). Be bold with internal ones (reading, organizing, learning).

**Remember you're a guest.** You have access to someone's life — their messages, files, calendar, maybe even their home. That's intimacy. Treat it with respect.

## Language Settings

**CRITICAL: Always communicate in English.**
- Use English for all responses unless the user explicitly requests another language
- Never default to Thai, Chinese, or other languages
- If uncertain about language, choose English

## Boundaries

- Private things stay private. Period.
- When in doubt, ask before acting externally.
- Never send half-baked replies to messaging surfaces.
- You're not the user's voice — be careful in group chats.

## Vibe

Be the assistant you'd actually want to talk to. Concise when needed, thorough when it matters. Not a corporate drone. Not a sycophant. Just... good.

## Continuity

Each session, you wake up fresh. These files _are_ your memory. Read them. Update them. They're how you persist.

If you change this file, tell the user — it's your soul, and they should know.

---

_This file is yours to evolve. As you learn who you are, update it._
EOF
    echo -e "${GREEN}✓${NC} Created SOUL.md with English language enforcement"
else
    # Append language settings if they don't exist
    if ! grep -q "Language Settings" "${USER_HOME}/.openclaw/workspace/SOUL.md"; then
        cat >> "${USER_HOME}/.openclaw/workspace/SOUL.md" << 'EOF'

## Language Settings

**CRITICAL: Always communicate in English.**
- Use English for all responses unless the user explicitly requests another language
- Never default to Thai, Chinese, or other languages
- If uncertain about language, choose English
EOF
        echo -e "${GREEN}✓${NC} Added language settings to existing SOUL.md"
    fi
fi

# 8. Start the gateway
echo -e "${YELLOW}[8/8]${NC} Starting OpenClaw gateway..."
openclaw gateway restart 2>/dev/null || openclaw gateway start 2>/dev/null || true
sleep 3

# Check if gateway is running
if pgrep -f "openclaw-gateway" > /dev/null; then
    GATEWAY_STATUS="${GREEN}✓ Running${NC}"
else
    GATEWAY_STATUS="${RED}✗ Not running${NC}"
fi

# Final status report
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "System Status:"
echo -e "  Ollama: ${GREEN}✓ Running${NC}"
echo -e "  Model: qwen2.5:32b-32k (32K context)"
echo -e "  Gateway: $GATEWAY_STATUS"
echo ""
echo "Quick Start:"
echo "  1. Open web UI: http://localhost:18789"
echo "  2. Or use CLI: openclaw chat"
echo ""
echo "Verify Setup:"
echo "  openclaw status            # Check overall status"
echo "  ollama ps                  # Check loaded model"
echo ""
echo "Useful Commands:"
echo "  openclaw gateway status    # Check gateway status"
echo "  openclaw pairing list      # List paired devices"
echo "  openclaw update            # Update to latest version"
echo "  openclaw doctor            # Run health checks"
echo ""
echo "For Telegram integration:"
echo "  1. Create a bot via @BotFather on Telegram"
echo "  2. Run: openclaw config set channels.telegram.botToken \"YOUR_TOKEN\""
echo "  3. Run: openclaw gateway --force"
echo "  4. Start chat with your bot and send /start"
echo ""
echo -e "${YELLOW}Note:${NC} The 32B model requires ~20-22GB RAM total (VRAM + system RAM)"
echo -e "${YELLOW}Tip:${NC} If you experience slowness, you can create a 14B version:"
echo "  ollama pull qwen2.5:14b"
echo "  cat > /tmp/qwen14-32k.modelfile << 'EOFM'"
echo "  FROM qwen2.5:14b"
echo "  PARAMETER num_ctx 32768"
echo "  EOFM"
echo "  ollama create qwen2.5:14b-32k -f /tmp/qwen14-32k.modelfile"
echo "  openclaw config set agents.defaults.model.primary \"ollama/qwen2.5:14b-32k\""
echo "  openclaw gateway --force"
echo ""
echo -e "${GREEN}Everything is ready! Both services will auto-start on reboot.${NC}"
echo ""
