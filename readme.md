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

## 🛠️ Available Tools & Aliases
- `rg` (ripgrep) - Fast text search
- `bat` - Enhanced cat with syntax highlighting  
- `btop` - Modern system monitor
- `yq` - YAML/JSON processor
- `uv` - Fast Python package manager

**Aliases**: `cat`→`bat`, `grep`→`rg`, `top`→`btop`, `pip`→`uv pip`

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
