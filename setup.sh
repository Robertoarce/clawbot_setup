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
echo -e "${YELLOW}[1/9]${NC} Checking Ollama installation..."
if ! command -v ollama &> /dev/null; then
    echo "Ollama not found. Installing..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo -e "${GREEN}✓${NC} Ollama already installed"
fi

# 2. Start Ollama service (if not running)
echo -e "${YELLOW}[2/9]${NC} Ensuring Ollama service is running..."
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
echo -e "${YELLOW}[3/9]${NC} Pulling Qwen 2.5 32B model (optimized for tool use)..."
echo "This may take 15-20 minutes depending on your connection..."

if ollama list | grep -q "qwen2.5:32b-instruct-q4_K_M"; then
    echo -e "${GREEN}✓${NC} Base model already exists"
else
    ollama pull qwen2.5:32b-instruct-q4_K_M
fi
echo -e "${GREEN}✓${NC} Base model ready"

# 3.5. Create model with 32K context window (CRITICAL!)
echo -e "${YELLOW}[3.5/9]${NC} Creating model with 32K context window..."
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
echo -e "${YELLOW}[4/9]${NC} Installing OpenClaw..."
if ! command -v openclaw &> /dev/null; then
    npm install -g openclaw
else
    echo -e "${GREEN}✓${NC} OpenClaw already installed"
    # Check for updates
    echo "Checking for updates..."
    openclaw update 2>/dev/null || true
fi

# 5. Configure OpenClaw
echo -e "${YELLOW}[5/9]${NC} Configuring OpenClaw..."

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
mkdir -p "${USER_HOME}/.openclaw/skills/user"

# Set proper permissions
chmod 700 "${USER_HOME}/.openclaw/credentials" 2>/dev/null || true

# 6. Install Skill Dependencies
echo -e "${YELLOW}[6/9]${NC} Installing skill dependencies..."

# GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update -qq
    sudo apt install gh -y
    echo -e "${GREEN}✓${NC} GitHub CLI installed"
else
    echo -e "${GREEN}✓${NC} GitHub CLI already installed"
fi

# Summarize dependencies
echo "Installing video/audio processing tools..."
pip install yt-dlp --break-system-packages 2>/dev/null || pip install yt-dlp
sudo apt install -y ffmpeg 2>/dev/null || true

# Polymarket
echo "Installing Polymarket client..."
pip install py-clob-client --break-system-packages 2>/dev/null || pip install py-clob-client

echo -e "${GREEN}✓${NC} Skill dependencies installed"

# 6.5. Create Custom Skills
echo -e "${YELLOW}[6.5/9]${NC} Creating custom skills..."

# Polymarket skill
mkdir -p "${USER_HOME}/.openclaw/skills/user/polymarket"
cat > "${USER_HOME}/.openclaw/skills/user/polymarket/SKILL.md" << 'POLYEOF'
# Polymarket Trading

Use when interacting with Polymarket prediction markets for trading, monitoring positions, or analyzing markets.

## Dependencies
```bash
