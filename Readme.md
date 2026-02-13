# ClawBot Setup

Automated setup for OpenClaw with Ollama local LLM.

## Quick Start

```bash
# Clone the repo
git clone git@github.com:Robertoarce/clawbot_setup.git
cd clawbot_setup

# Run the setup script
bash setup.sh
```

That's it! The script will:
1. ✅ Install Ollama (if not already installed)
2. ✅ Start Ollama service
3. ✅ Pull Qwen 2.5 14B model
4. ✅ Install OpenClaw
5. ✅ Configure everything automatically
6. ✅ Start the gateway

## Test Your Setup

```bash
# Test the agent
openclaw agent --local --to +15555550123 --message "Hello, test"

# Check status
openclaw models list
openclaw gateway status

# Open web dashboard
openclaw dashboard
```

## Manual Setup (if needed)

If you prefer to do it manually or the script fails:

### 1. Install Ollama
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama serve  # Start service
```

### 2. Pull Model
```bash
ollama pull qwen2.5:14b
```

### 3. Install OpenClaw
```bash
npm install -g openclaw
```

### 4. Configure
```bash
# Add auth profile
openclaw models auth add
# Select: custom → ollama → paste token → enter "ollama"

# Set default model
openclaw models set ollama/qwen2.5:14b

# Set environment variables
export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_API_KEY=ollama

# Add to your shell profile
echo 'export OLLAMA_BASE_URL=http://localhost:11434' >> ~/.bashrc
echo 'export OLLAMA_API_KEY=ollama' >> ~/.bashrc
```

### 5. Start Gateway
```bash
openclaw gateway restart
```

## Important Notes

### ✅ Compatible Models
- `qwen2.5:14b` (recommended)
- `qwen2.5:7b` (lighter alternative)
- `mistral:latest`

### ❌ Incompatible Models
- `llama3.1:8b` (doesn't work with OpenClaw's tool requirements)

### Configuration Files
- Config: `~/.openclaw/openclaw.json`
- Auth: `~/.openclaw/credentials/auth-profiles.json`
- Logs: `/tmp/openclaw/openclaw-*.log`

### Common Commands

```bash
# Gateway control
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
openclaw gateway status

# Model management
openclaw models list
openclaw models set <model>
openclaw models auth add

# Agent testing
openclaw agent --local --to +1234567890 --message "your message"

# Troubleshooting
openclaw doctor --fix
openclaw logs
```

## Troubleshooting

### "Unknown model" error
```bash
# Verify model is pulled
ollama list

# Set it again
openclaw models set ollama/qwen2.5:14b

# Restart gateway
openclaw gateway restart
```

### Gateway won't start
```bash
# Check if port 18789 is in use
lsof -i :18789

# Check gateway status
openclaw gateway status

# View logs
openclaw logs
```

### Model not responding correctly
```bash
# Try a different model
ollama pull qwen2.5:7b
openclaw models set ollama/qwen2.5:7b
openclaw gateway restart
```

### Reset everything
```bash
openclaw reset  # Keeps CLI installed
# Then run setup.sh again
```

## Environment Variables

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_API_KEY=ollama
```

## Architecture

```
┌─────────────────┐
│   Your Client   │
│  (Terminal/App) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ OpenClaw Gateway│
│  (port 18789)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Ollama Service  │
│  (port 11434)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Qwen 2.5 14B   │
│  (Local Model)  │
└─────────────────┘
```

## License

MIT

## Support

For OpenClaw issues: https://docs.openclaw.ai
For Ollama issues: https://ollama.com/docs