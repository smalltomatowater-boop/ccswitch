# ccswitch

Switch Claude Code AI model backends with one command.

Supports **Claude (Anthropic)**, **Qwen (DashScope)**, **GLM (Z.ai)**, and **proxy mode** with interactive `/model` switching.

## Features

- One-command model switching
- No API keys committed — all keys via environment variables
- Interactive menu when run without arguments
- Proxy mode for hot-switching models without changing config files
- Status display to check current configuration

## Quick Start

```bash
# Download
curl -O https://raw.githubusercontent.com/smalltomatowater-boop/ccswitch/main/ccswitch.sh
chmod +x ccswitch.sh

# Set up your API keys
export DASHSCOPE_API_KEY="sk-..."   # for Qwen
export ZAI_API_KEY="..."             # for GLM

# Switch to a model
./ccswitch.sh qwen
./ccswitch.sh claude
./ccswitch.sh glm
./ccswitch.sh proxy    # interactive mode with /model
./ccswitch.sh status   # check current config
```

## Supported Models

| Command | Model | API Key |
|---|---|---|
| `claude` | Claude Sonnet 4.6 (Anthropic) | — (uses Anthropic account) |
| `qwen` | Qwen3.6-Plus (DashScope) | `DASHSCOPE_API_KEY` |
| `qwen35` | Qwen3.5-Plus (DashScope CodingPlus) | `DASHSCOPE_CODING_API_KEY` |
| `qwen-think` | Qwen3.6-Plus with thinking mode | `DASHSCOPE_API_KEY` |
| `glm` | GLM-5.1 (Z.ai) | `ZAI_API_KEY` |
| `proxy` | Proxy mode (hot-switch via `/model`) | — |

## Proxy Mode

Proxy mode runs a local server that routes requests to different backends. Start it with:

```bash
./ccswitch.sh proxy
```

Then use `/model` inside Claude Code to switch models on the fly:

```
/model claude-sonnet-4-6
/model qwen3.6-plus
/model glm-5.1
```

> [!NOTE]
> The proxy script (`ccproxy.js`) is **not** included in this repository. You need to set it up separately on your own machine.

## Installation

### Option 1: Direct download

```bash
curl -O https://raw.githubusercontent.com/smalltomatowater-boop/ccswitch/main/ccswitch.sh
chmod +x ccswitch.sh
sudo mv ccswitch.sh /usr/local/bin/ccswitch
```

Then just run `ccswitch` from anywhere.

### Option 2: Clone

```bash
git clone https://github.com/smalltomatowater-boop/ccswitch.git
cd ccswitch
ln -s "$PWD/ccswitch.sh" /usr/local/bin/ccswitch
```

## Configuration

Set environment variables in your shell profile (`~/.zshrc` / `~/.bashrc`):

```bash
# DashScope (Qwen)
export DASHSCOPE_API_KEY="sk-..."

# DashScope CodingPlus (Qwen3.5)
export DASHSCOPE_CODING_API_KEY="sk-..."

# Z.ai (GLM)
export ZAI_API_KEY="..."
```

## License

MIT
