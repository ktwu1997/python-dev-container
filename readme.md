# Python Development Environment

A clean Python development container with ZSH, Powerlevel10k, and essential development tools.

## ✨ Features

- **Python 3.11** with uv package manager
- **ZSH** with Oh My Zsh and Powerlevel10k theme
- **Development Tools**: ripgrep, bat, btop, yq, jq
- **Enhanced Terminal**: Auto-suggestions, syntax highlighting, smart directory jumping

## 🚀 Quick Start

```bash
# Copy environment configuration
cp .env.example .env

# Customize your configuration in .env file
# Edit HOST_WORK_DIR, SSH_PORT, SSH_USER, SSH_PASSWORD as needed

# Build and start
docker compose up -d --build

# Enter development environment
docker compose exec python-dev zsh

# Configure Powerlevel10k theme (first time setup)
p10k configure

# Check environment health
docker compose exec python-dev env-check
```

## 🔐 SSH Access

The container automatically starts SSH service with configurable credentials:

### Configuration

First, copy the example environment file and customize it:

```bash
cp .env.example .env
```

Edit `.env` file to configure your environment:

```bash
# Volume mount - specify your local work directory
HOST_WORK_DIR=./                    # Current directory (default)
# HOST_WORK_DIR=/path/to/your/code  # Or absolute path

# SSH Configuration
SSH_PORT=2222           # External SSH port
SSH_USER=developer      # SSH username  
SSH_PASSWORD=dev123456  # SSH password (change this!)
```

### Connect via SSH

```bash
# Connect to container via SSH
ssh -p 2222 developer@localhost

# Test SSH connection
docker compose exec python-dev test-ssh
```

The SSH user has full sudo privileges within the container.

## 🛠️ Available Tools & Enhanced Aliases

### Enhanced Command Aliases

- `cat` → `bat` - Syntax highlighting & line numbers
- `grep` → `rg` - Faster search with better output
- `top` → `btop` - Modern system monitor
- `pip` → `uv pip` - Faster package manager
- `pip3` → `uv pip` - Faster package manager

### Additional Tools

- `vim` - Text editor
- `yq` - YAML/JSON processor
- `jq` - JSON processor
- Standard `ls` aliases: `ll`, `la`, `l`

### Accessing Original Commands

If you need the original command behavior:

```bash
command cat file.txt    # Use original cat
command grep pattern    # Use original grep
command top            # Use original top
```

## ⚡ Powerlevel10k Configuration

### First Time Setup

When you first enter the container, run the configuration wizard:

```bash
p10k configure
```

This interactive wizard will help you:

- Choose your preferred prompt style
- Configure icons and symbols
- Set up Git integration
- Customize colors and layout

### Reconfigure Anytime

You can reconfigure your prompt at any time:

```bash
p10k configure    # Run configuration wizard again
```

### Manual Configuration

The configuration is stored in `~/.p10k.zsh`. You can:

- Edit this file directly for advanced customization
- Backup your configuration for reuse
- Share configurations between containers

## 🤖 AI Tooling & Persistence

The image ships with **Claude Code** (+ the ECC plugin and Anthropic skills marketplace),
**Gemini CLI**, and **MemPalace** (AI memory). All of these are installed at *build time* as
Claude Code **plugins** — nothing is copied into `~/.claude` by hand, so they update via
`claude plugin update` and don't get duplicated on rebuilds.

Two host directories are bind-mounted so state survives container rebuilds/recreates:

| Container path | Host path (`.env`) | What it holds |
|---|---|---|
| `~/.claude`    | `HOST_CLAUDE_DIR` (default `./.persist/claude`)       | Claude Code config: `settings.json`, `CLAUDE.md`, `skills/learned/`, plugin cache |
| `~/.mempalace` | `HOST_MEMPALACE_DIR` (default `./.persist/mempalace`) | MemPalace memory: vector store + knowledge graph (**not reproducible — back this up**) |

`ssh-setup.sh` seeds these from the build-time install **only when they're empty**, so an
existing palace is never overwritten.

**First-time migration** (if you already have a running container with data): copy your
current dirs into the host paths *before* the first `docker compose up` with the new mounts —
from inside the running container, e.g.:

```bash
mkdir -p /workspace/.persist
cp -a ~/.claude     /workspace/.persist/claude
cp -a ~/.mempalace  /workspace/.persist/mempalace
# (adjust if HOST_WORK_DIR is not this project dir)
```

## 📁 Project Structure

```
├── Dockerfile              # Container definition
├── docker-compose.yml      # Service configuration
├── config/
│   ├── zsh/                # ZSH configuration
│   └── scripts/            # Utility scripts
├── .persist/               # Bind-mounted ~/.claude & ~/.mempalace (gitignored)
└── README.md
```

## 📋 Utility Commands

- `env-check` - Environment health check
- `fallback-shell` - Basic shell if ZSH fails
- `test-ssh` - Test SSH connection configuration
- `ssh-setup` - Initialize SSH service (runs automatically)
