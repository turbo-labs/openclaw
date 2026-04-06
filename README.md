# OpenClaw on Railway

Self-hosted [OpenClaw](https://openclaw.ai) deployment with Go toolchain and persistent storage.

OpenClaw is a personal AI assistant platform that runs a gateway server on Node.js. The gateway acts as a control plane — it bridges multiple messaging channels (WhatsApp, Telegram, Discord, Slack, Signal, and more) into a unified interface, routing messages between channels and the AI agent runtime via WebSocket.

## Deploy

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/openclaw-secure?referralCode=NVdOal)

You'll be prompted for three variables:

1. **`OPENROUTER_API_KEY`** — get one at [openrouter.ai/keys](https://openrouter.ai/keys)
2. **`TELEGRAM_BOT_TOKEN`** — create a bot via [@BotFather](https://t.me/BotFather) on Telegram
3. **`OPENCLAW_AGENT_NAME`** — your agent's display name (e.g. "Jarvis")

That's it. Click deploy and your agent will be live on Telegram.

## What's included

- OpenClaw gateway (installed via public install script)
- Go runtime for running Go-based tools
- Persistent volume at `/data` for state, workspace, Go binaries, and npm modules

## Security

The container runs as a non-root user with hardened volume permissions, a restrictive umask, and binary integrity verification on startup.

## What it looks like

![OpenClaw Gateway Dashboard](assets/chat.png)

## Connecting to the gateway

The template auto-generates `OPENCLAW_GATEWAY_TOKEN` and `OPENCLAW_GATEWAY_PASSWORD` for you. To find them:

1. In the Railway dashboard, open your OpenClaw service
2. Go to **Variables**
3. Copy `OPENCLAW_GATEWAY_TOKEN` or `OPENCLAW_GATEWAY_PASSWORD`

Use the token or password to authenticate on the dashboard `/overview` page when connecting to your gateway.

![Gateway overview page with token and password configured](assets/overview.png)

## Environment variables

| Variable | Description |
|---|---|
| `OPENROUTER_API_KEY` | **Required.** Your OpenRouter API key |
| `TELEGRAM_BOT_TOKEN` | **Required.** Telegram bot token from @BotFather |
| `OPENCLAW_AGENT_NAME` | **Required.** Your agent's display name |
| `OPENCLAW_GATEWAY_TOKEN` | Auto-generated token for gateway authentication |
| `OPENCLAW_GATEWAY_PASSWORD` | Auto-generated password for gateway authentication |
| `PORT` | Automatically set by Railway |
