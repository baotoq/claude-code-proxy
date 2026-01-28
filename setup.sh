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
CLAUDE_SETTINGS_DIR="./.claude"
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

# Function to copy to clipboard cross-platform
copy_to_clipboard() {
    if command -v pbcopy &> /dev/null; then
        echo -n "$1" | pbcopy  # macOS
        return 0
    elif command -v xclip &> /dev/null; then
        echo -n "$1" | xclip -selection clipboard  # Linux
        return 0
    elif command -v xsel &> /dev/null; then
        echo -n "$1" | xsel --clipboard  # Linux alternative
        return 0
    else
        return 1
    fi
}

echo ""
echo "📜 Streaming LiteLLM logs (Ctrl+C to stop)..."
docker compose logs -f litellm &
LOG_STREAM_PID=$!

trap "kill $LOG_STREAM_PID 2>/dev/null" EXIT

echo ""
echo "🔐 Waiting for GitHub device code..."

(
    timeout 90 docker compose logs -f litellm 2>&1 | while read -r line; do
        CODE=$(grep -oE "\b[A-Z0-9]{4}-[A-Z0-9]{4}\b" <<< "$line" | head -1)

        if [ -n "$CODE" ]; then
            echo ""
            echo "════════════════════════════════════════════════"
            echo ""
            echo "   📋 GitHub Device Code:  >>>  $CODE  <<<"
            echo ""
            copy_to_clipboard "$CODE" && echo "   ✅ Code copied to clipboard!"
            echo "════════════════════════════════════════════════"
            open_url "https://github.com/login/device"
            break
        fi
    done
) &

echo ""
echo "📋 Next steps:"
echo "1. Browser will open automatically when auth code appears"
echo "2. Enter the code shown in the terminal"
echo "3. Restart Claude Code to use the new settings"
echo ""
echo "💡 Tip: Run 'docker compose logs -f litellm' to see the auth code if browser didn't open"
echo ""
echo "🎉 Setup complete!"
