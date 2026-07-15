# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a containerized Python 3.11 development environment template with enhanced tooling, ZSH shell configuration, and SSH access. Designed for clean virtual environment isolation without PYTHONPATH conflicts, making it ideal for distributing to multiple developers and projects.

## Architecture

The development environment consists of:

- **Base Container**: Python 3.11-slim with enhanced development tools
- **Package Management**: UV (faster alternative to pip) as the primary package manager
- **Shell Environment**: ZSH with Oh My Zsh, Powerlevel10k theme, and productivity plugins
- **Enhanced Tools**: Modern replacements for common commands (bat, ripgrep, btop, etc.)
- **SSH Access**: Configurable SSH server for remote development
- **Volume Mounting**: Host directory mounted to `/workspace` for persistent development

## Commands

### Container Management
```bash
# Start the development environment
docker compose up -d --build

# Enter the container
docker compose exec python-dev zsh

# Stop the environment
docker compose down
```

### Environment Setup
```bash
# Copy and configure environment variables
cp .env.example .env
# Edit .env to customize CONTAINER_NAME, HOST_WORK_DIR, SSH_PORT, SSH_USER, SSH_PASSWORD

# Configure Powerlevel10k theme (first time setup)
p10k configure

# Run environment health check
env-check

# Test Python virtual environment isolation
test-python-env
```

### SSH Access
```bash
# Connect via SSH (from host)
ssh -p 2222 developer@localhost

# Test SSH configuration
docker compose exec python-dev test-ssh
```

### Python Development
```bash
# Create project virtual environment (recommended)
python -m venv .venv
source .venv/bin/activate

# Or use UV (faster)
uv venv
source .venv/bin/activate

# Install packages in virtual environment
pip install package-name  # Uses uv pip via alias

# Deactivate virtual environment
deactivate

# Python environment checks
python-check        # Basic Python version check
test-python-env     # Virtual environment isolation test
```

### Enhanced Tool Aliases

The environment includes several enhanced command aliases:
- `cat` → `bat` (syntax highlighting)
- `grep` → `rg` (ripgrep)
- `top` → `btop` (modern system monitor)
- `pip` / `pip3` → `uv pip` (faster package manager)

To use original commands when needed: `command <original-command>`

## Configuration Files

### Environment Configuration
- `.env` - Container environment variables (SSH config, volume mounts)
- `.env.example` - Template for environment configuration

### Container Configuration
- `Dockerfile` - Multi-stage container build with development tools
- `docker-compose.yml` - Service definition and networking

### Shell Configuration
- `config/zsh/.zshrc` - ZSH configuration with plugins and aliases
- `config/zsh/.p10k.zsh` - Powerlevel10k theme configuration

### Utility Scripts (in `config/scripts/`)
- `env-check.sh` - Comprehensive environment health check
- `ssh-setup.sh` - SSH server initialization
- `test-ssh.sh` - SSH connection testing
- `test-python-env.sh` - Python virtual environment isolation testing
- `verify-tools.sh` - Tool installation verification

## Development Workflow

1. **Template Setup**: Copy template to your project directory
2. **Configuration**: Copy `.env.example` to `.env` and customize CONTAINER_NAME, paths, etc.
3. **Container Start**: `docker compose up -d --build`
4. **Environment Verification**: Run `env-check` and `test-python-env`
5. **Shell Configuration**: Run `p10k configure` for personalized prompt
6. **Project Development**: Create venv in your project, activate, and develop

## Python Environment Best Practices

- **No Global PYTHONPATH**: Intentionally omitted to prevent venv conflicts
- **Project Isolation**: Each project should use its own virtual environment
- **UV Integration**: Faster package management with `uv venv` and `uv pip`
- **Testing**: Use `test-python-env` to verify isolation works correctly

## Working Directory & Volume Mounting

The container's working directory is `/workspace`, which is mounted from the host directory specified in `HOST_WORK_DIR` environment variable.

### Important Mounting Guidelines

**❌ Avoid Recursive Mounting:**
```bash
# DON'T do this if your template is inside the directory you're mounting
HOST_WORK_DIR=../  # This creates recursive /workspace/workspace/workspace/... structure
```

**✅ Correct Mounting Examples:**
```bash
# Option 1: Mount your general work directory
HOST_WORK_DIR=/Users/yourusername/projects
HOST_WORK_DIR=~/work

# Option 2: Mount current directory (only if template is IN your project)
HOST_WORK_DIR=.

# Option 3: Mount specific project directory
HOST_WORK_DIR=/Users/yourusername/my-python-project
```

### Template Usage Patterns

**As Standalone Template:**
1. Copy this template to a new location for each project
2. Set `HOST_WORK_DIR` to your project directory
3. Configure unique `CONTAINER_NAME` for each project

**As Shared Development Environment:**
1. Keep template in a central location
2. Set `HOST_WORK_DIR` to your general work directory
3. Access different projects within `/workspace`

## Network Configuration

- SSH access available on configurable port (default: 2222)
- Container uses bridge networking
- SSH user has full sudo privileges within container