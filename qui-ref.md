# OpenClaw Quick Reference

## One-Command Setup
```bash
bash setup.sh
```

## Essential Commands

### Testing
```bash
# Quick test
openclaw agent --local --to +15555550123 --message "test"

# With thinking
openclaw agent --local --to +15555550123 --message "analyze this" --thinking medium
```

### Gateway
```bash
openclaw gateway start      # Start
openclaw gateway stop       # Stop
openclaw gateway restart    # Restart
openclaw gateway status     # Check status
openclaw dashboard          # Open web UI
```

### Models
```bash
openclaw models list        # List configured models
openclaw models set MODEL   # Set default model
ollama list                 # List Ollama models
ollama pull MODEL           # Download new model
```

### Troubleshooting
```bash
openclaw doctor --fix       # Auto-fix config issues
openclaw logs               # View logs
openclaw status             # Check health
```

## Config Files
- `~/.openclaw/openclaw.json` - Main config
- `~/.openclaw/credentials/auth-profiles.json` - Auth profiles
- `/tmp/openclaw/openclaw-*.log` - Logs

## Recommended Models
1. `qwen2.5:14b` ⭐ (best for OpenClaw)
2. `qwen2.5:7b` (lighter)
3. `mistral:latest` (alternative)

❌ Avoid: `llama3.1:8b` (not compatible)

## Environment Variables
```bash
export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_API_KEY=ollama
```

## Reset & Reinstall
```bash
openclaw reset              # Reset config (keeps CLI)
openclaw uninstall          # Full uninstall
bash setup.sh               # Reinstall everything
```