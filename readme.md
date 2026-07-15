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

The image ships with **Claude Code** (+ the ECC plugin and Anthropic skills marketplace)
and **Gemini CLI**. These are installed at *build time* as Claude Code **plugins** —
nothing is copied into `~/.claude` by hand, so they update via `claude plugin update`
and don't get duplicated on rebuilds.

State survives container rebuilds/recreates through **one** host directory bind-mounted at
`/persistent` (host path from `PERSIST_HOME_DIR` in `.env`, e.g. `~/.devcontainer-home`).
每次啟動時，`ssh-setup.sh` 會把下列資料還原到 SSH 使用者的家目錄：

| 持久項目 | 機制 | 內容 |
|---|---|---|
| SSH host keys    | `/persistent/ssh_host_keys` | 容器重建後 host key 不變（不再每次跳指紋警告） |
| SSH private keys | 從 `/persistent/.ssh` 複製 | 家目錄的 `~/.ssh` 私鑰 |
| Claude 對話/resume | symlink → `/persistent` | `~/.claude/projects`、`todos`、`history.jsonl`、`~/.claude.json`（`claude --resume` 讀這裡） |
| Codex CLI        | symlink → `/persistent` | 整個 `~/.codex`（sessions、history、config、auth） |

SSH 登入為**僅金鑰**（不開密碼、不開 root）：你在 `config/authorized_keys` 維護的用戶端
公鑰清單會掛載到 `/tmp/authorized_keys`，並套用到 `~/.ssh/authorized_keys`。

> **首次設定**：把 `PERSIST_HOME_DIR` 指到一個主機目錄即可（空目錄會在首次啟動時自動建立內容）。
> 若要沿用既有容器的資料，在第一次 `docker compose up` 前，把 `~/.ssh`、`~/.claude/projects`、
> `~/.claude.json`、`~/.codex` 複製進那個目錄。

## 📁 Project Structure

```
├── Dockerfile              # Container definition
├── docker-compose.yml      # Service configuration (base, no GPU)
├── docker-compose.gpu.yml  # GPU override (NVIDIA Linux hosts only)
├── config/
│   ├── zsh/                # ZSH configuration
│   ├── tmux/               # tmux configuration
│   ├── authorized_keys.example  # 公鑰清單範本（複製成 authorized_keys 使用）
│   └── scripts/            # Utility scripts
└── README.md
```

## 📋 Utility Commands

- `env-check` - Environment health check
- `fallback-shell` - Basic shell if ZSH fails
- `test-ssh` - Test SSH connection configuration
- `ssh-setup` - Initialize SSH service (runs automatically)
