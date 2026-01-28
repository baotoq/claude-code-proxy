#!/bin/bash
set -e

echo "🚀 Setting up Claude Code with LiteLLM proxy..."

# Generate API keys if .env doesn't exist
if [ ! -f .env ]; then
    echo "📝 Generating API keys..."
    echo LITELLM_MASTER_KEY="litellm-$(uuidgen)" > .env
    echo LITELLM_SALT_KEY="litellm-$(uuidgen)" >> .env
else
    echo "✅ .env already exists, skipping key generation"
fi

# Read the master key from .env
MASTER_KEY=$(grep LITELLM_MASTER_KEY .env | cut -d'=' -f2)

# Create Claude Code settings directory if it doesn't exist
CLAUDE_SETTINGS_DIR="$HOME/.claude"
CLAUDE_SETTINGS_FILE="$CLAUDE_SETTINGS_DIR/settings.json"

mkdir -p "$CLAUDE_SETTINGS_DIR"

# Create or update Claude Code settings
echo "⚙️  Configuring Claude Code settings..."
cat > "$CLAUDE_SETTINGS_FILE" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "$MASTER_KEY",
    "ANTHROPIC_BASE_URL": "http://localhost:4000",
    "ANTHROPIC_MODEL": "claude-sonnet-4.5",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-4.5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4.5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4.5"
  }
}
EOF
echo "✅ Claude Code settings saved to $CLAUDE_SETTINGS_FILE"

# Start Docker Compose
echo "🐳 Starting Docker Compose..."
docker compose up -d

# Wait for LiteLLM to be healthy
echo "⏳ Waiting for LiteLLM to start..."
sleep 10

# Check health
if curl -s http://localhost:4000/health/liveliness | grep -q "alive"; then
    echo "✅ LiteLLM is running!"
else
    echo "⚠️  LiteLLM may still be starting. Check logs with: docker compose logs -f"
fi

# Watch for GitHub device code and open browser automatically
echo "🔐 Watching for GitHub authentication code..."
echo "   (Will automatically open browser when code appears)"
echo ""

# Function to open URL cross-platform
open_url() {
    if command -v open &> /dev/null; then
        open "$1"  # macOS
    elif command -v xdg-open &> /dev/null; then
        xdg-open "$1"  # Linux
    elif command -v start &> /dev/null; then
        start "$1"  # Windows (Git Bash)
    else
        echo "⚠️  Could not open browser automatically. Please visit: $1"
    fi
}

# Monitor logs for the device code (timeout after 60 seconds)
timeout 60 docker compose logs -f litellm 2>&1 | while read -r line; do
    echo "$line"
    # Look for the GitHub device code pattern
    if echo "$line" | grep -q "https://github.com/login/device"; then
        echo ""
        echo "🌐 Opening GitHub authentication page..."
        open_url "https://github.com/login/device"
        break
    fi
    # Also check for the code itself (usually appears as "code: XXXX-XXXX")
    if echo "$line" | grep -qE "code[:\s]+[A-Z0-9]{4}-[A-Z0-9]{4}"; then
        CODE=$(echo "$line" | grep -oE "[A-Z0-9]{4}-[A-Z0-9]{4}")
        echo ""
        echo "📋 Your code is: $CODE"
        echo "🌐 Opening GitHub authentication page..."
        open_url "https://github.com/login/device"
        break
    fi
done &

echo ""
echo "📋 Next steps:"
echo "1. Browser will open automatically when auth code appears"
echo "2. Enter the code shown in the terminal"
echo "3. Restart Claude Code to use the new settings"
echo ""
echo "💡 Tip: Run 'docker compose logs -f litellm' to see the auth code if browser didn't open"
echo ""
echo "🎉 Setup complete!"
