# Claude Code Proxy

Use Claude Code with GitHub Copilot models through a LiteLLM proxy.

## Overview

This project allows you to proxy Claude Code API calls to GitHub Copilot models. It uses LiteLLM as a proxy layer to translate requests, enabling access to various AI models available through GitHub Copilot.

### Available Models

- **Anthropic**: Claude Sonnet 4.5, Claude Opus 4.5, Claude Haiku 4.5, etc.
- **OpenAI**: GPT-4.1, GPT-5, GPT-5.1, GPT-5.2, and variants
- **Google**: Gemini 2.5 Pro, Gemini 3 Flash, Gemini 3 Pro
- **xAI**: Grok Code Fast 1
- **Fine-tuned**: Raptor Mini

## Prerequisites

- Docker and Docker Compose
- GitHub account with Copilot access
- Homebrew (for installing Claude Code on macOS)

## Quick Start

1. **Run the setup script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   or

   ```bash
   bash setup.sh
   ```

   The script will:
   - Generate API keys in `.env`
   - Configure Claude Code settings
   - Start Docker containers
   - **Automatically copy the device code to clipboard** and open your browser for GitHub authentication

2. **Complete GitHub authentication:**
   - The browser will open to `https://github.com/login/device`
   - Paste the code (already copied to clipboard) or enter the highlighted code from terminal
   - Authorize the application

3. **Restart Claude Code** to use the new settings.

## Manual Setup

If you prefer to set things up manually:

1. Create `.env` file with your keys:
   ```bash
   echo LITELLM_MASTER_KEY="litellm-$(uuidgen)" > .env
   echo LITELLM_SALT_KEY="litellm-$(uuidgen)" >> .env
   ```

2. Start the services:
   ```bash
   docker compose up -d
   ```

3. Watch logs for the authentication code:
   ```bash
   docker compose logs -f litellm
   ```

4. Visit https://github.com/login/device and enter the code.

5. Configure Claude Code settings in `~/.claude/settings.json`:
   ```json
   {
     "env": {
       "ANTHROPIC_AUTH_TOKEN": "<your-master-key>",
       "ANTHROPIC_BASE_URL": "http://localhost:4000",
       "ANTHROPIC_MODEL": "claude-sonnet-4.5"
     }
   }
   ```

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `LITELLM_MASTER_KEY` | API key for authenticating with the proxy |
| `LITELLM_SALT_KEY` | Salt key for LiteLLM |

### Claude Code Settings

The setup script automatically configures these in `~/.claude/settings.json`:

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_AUTH_TOKEN` | Your LiteLLM master key |
| `ANTHROPIC_BASE_URL` | Proxy URL (`http://localhost:4000`) |
| `ANTHROPIC_MODEL` | Default model to use |

## Services

| Service | Port | Description |
|---------|------|-------------|
| LiteLLM | 4000 | API proxy server |
| PostgreSQL | 5432 | Database for LiteLLM |
| Prometheus | 9090 | Metrics collection |

## Troubleshooting

### LiteLLM not starting
```bash
docker compose logs -f litellm
```

### Re-authenticate with GitHub
```bash
docker compose down
docker compose up -d
docker compose logs -f litellm
```

### Health check
```bash
curl http://localhost:4000/health/liveliness
```

## References

- [Claude Code LLM Gateway Documentation](https://code.claude.com/docs/en/llm-gateway#basic-litellm-setup)
- [Claude Code Model Configuration](https://code.claude.com/docs/en/model-config#environment-variables)
- [LiteLLM Documentation](https://docs.litellm.ai/)
- [GitHub Copilot Models](https://docs.github.com/en/copilot/reference/ai-models/supported-models)

## License

MIT
