#!/bin/bash
set -e

echo "🦞 Installing skill dependencies..."

# GitHub CLI
echo "Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
fi

# Summarize dependencies
echo "Installing summarize dependencies..."
pip install yt-dlp --break-system-packages
sudo apt install ffmpeg -y 2>/dev/null || true

# Polymarket
echo "Installing Polymarket client..."
pip install py-clob-client --break-system-packages

# Create custom skills
echo "Creating custom skills..."
mkdir -p ~/.openclaw/skills/user/{polymarket,vscode,snapshots}

cat > ~/.openclaw/skills/user/polymarket/SKILL.md << 'POLYEOF'
# Polymarket Trading

Use for prediction market trading and analysis.

## Check Markets
```python
from py_clob_client.client import ClobClient
client = ClobClient("https://clob.polymarket.com")
markets = client.get_markets()
for m in markets[:5]:
    print(f"{m['question']}: ${m.get('lastPrice', 'N/A')}")
```
POLYEOF

cat > ~/.openclaw/skills/user/vscode/SKILL.md << 'VSCEOF'
# VS Code Control
```bash
code <file>           # Open file
code -r <file>        # Reuse window
code --diff f1 f2     # Compare files
```
VSCEOF

cat > ~/.openclaw/skills/user/snapshots/SKILL.md << 'SNAPEOF'
# Automated Snapshots

Use browser + message + cron tools together.
Example: "Screenshot hackernews every 4 hours and send to Telegram"
SNAPEOF

openclaw gateway restart

echo "✅ Done! Skills are ready."
echo ""
echo "Test with:"
echo "  'Check GitHub repo: https://github.com/torvalds/linux'"
echo "  'What are the top Polymarket markets right now?'"
echo "  'Take a screenshot of news.ycombinator.com and send to my Telegram'"
