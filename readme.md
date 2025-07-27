# Python Development Environment

A clean Python development container with ZSH, Powerlevel10k, and essential development tools.

## ✨ Features
- **Python 3.11** with uv package manager
- **ZSH** with Oh My Zsh and Powerlevel10k theme
- **Development Tools**: ripgrep, bat, btop, yq, jq
- **Enhanced Terminal**: Auto-suggestions, syntax highlighting, smart directory jumping

## 🚀 Quick Start

```bash
# Build and start
docker compose up -d --build

# Enter development environment
docker compose exec python-dev zsh

# Check environment health
docker compose exec python-dev env-check
```

## 🛠️ Available Tools & Enhanced Aliases

### Enhanced Command Aliases
- `cat` → `bat` - Syntax highlighting & line numbers
- `grep` → `rg` - Faster search with better output
- `top` → `btop` - Modern system monitor
- `pip` → `uv pip` - Faster package manager
- `pip3` → `uv pip` - Faster package manager

### Additional Tools
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

## 📁 Project Structure
```
├── Dockerfile              # Container definition
├── docker-compose.yml      # Service configuration  
├── config/
│   ├── zsh/                # ZSH configuration
│   └── scripts/            # Utility scripts
└── README.md
```

## 📋 Utility Commands
- `env-check` - Environment health check
- `fallback-shell` - Basic shell if ZSH fails
