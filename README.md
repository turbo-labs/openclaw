# OpenClaw on Railway

Self-hosted [OpenClaw](https://openclaw.ai) deployment with Go toolchain and persistent storage.

OpenClaw is a personal AI assistant platform that runs a gateway server on Node.js. The gateway acts as a control plane — it bridges multiple messaging channels (WhatsApp, Telegram, Discord, Slack, Signal, and more) into a unified interface, routing messages between channels and the AI agent runtime via WebSocket.

## Deploy

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/openclaw-secure?referralCode=NVdOal)

## What's included

- OpenClaw gateway (installed via public install script)
- Go runtime for running Go-based tools
- Persistent volume at `/data` for state, workspace, Go binaries, and npm modules

## Security

The container runs as a non-root user with hardened volume permissions, a restrictive umask, and binary integrity verification on startup.

## Setup

OpenClaw requires an Anthropic API key to chat with Claude. For an out-of-the-box experience, add it during the template deployment prompt before launch. Otherwise, you can add it after deploying:

1. In the Railway dashboard, open your OpenClaw service
2. Go to **Variables**
3. Add `ANTHROPIC_API_KEY` with your key from [console.anthropic.com](https://console.anthropic.com/)
4. Redeploy the service

## Connecting to the gateway

The template auto-generates `OPENCLAW_GATEWAY_TOKEN` and `OPENCLAW_GATEWAY_PASSWORD` for you. To find them:

1. In the Railway dashboard, open your OpenClaw service
2. Go to **Variables**
3. Copy `OPENCLAW_GATEWAY_TOKEN` or `OPENCLAW_GATEWAY_PASSWORD`

Use the token or password to authenticate on the dashboard `/overview` page when connecting to your gateway.

## Environment variables

| Variable | Description |
|---|---|
| `ANTHROPIC_API_KEY` | **Required.** Your Anthropic API key for Claude |
| `OPENCLAW_GATEWAY_TOKEN` | Auto-generated token for gateway authentication |
| `OPENCLAW_GATEWAY_PASSWORD` | Auto-generated password for gateway authentication |
| `PORT` | Automatically set by Railway |
