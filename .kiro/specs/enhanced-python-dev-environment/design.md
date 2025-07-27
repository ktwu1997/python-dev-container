# Design Document

## Overview

本設計文件描述如何增強現有的 Python 開發環境，將其升級為一個功能完整的開發容器。設計重點包括：升級到 Python 3.11、整合多種開發工具、配置 ZSH 終端機環境，以及確保與現有 Docker Compose 工作流程的相容性。

## Architecture

### Container Architecture
```
┌─────────────────────────────────────────┐
│           Enhanced Python Dev           │
│              Container                  │
├─────────────────────────────────────────┤
│  ZSH + Oh My Zsh + Powerlevel10k       │
│  ├── zsh-autosuggestions               │
│  ├── zsh-syntax-highlighting           │
│  └── zsh-z                             │
├─────────────────────────────────────────┤
│  Development Tools                      │
│  ├── git                               │
│  ├── net-tools                         │
│  ├── ripgrep                           │
│  ├── jq                                │
│  ├── lftp                              │
│  ├── moreutils                         │
│  ├── btop                              │
│  ├── yq                                │
│  └── bat                               │
├─────────────────────────────────────────┤
│  Python 3.11 + uv + Virtual Env        │
├─────────────────────────────────────────┤
│  Base OS: Debian (python:3.11-slim)    │
└─────────────────────────────────────────┘
```

### Installation Strategy
採用分層安裝策略，確保安裝過程的穩定性和可維護性：

1. **Base Layer**: 系統套件和依賴項
2. **Tools Layer**: 開發工具安裝
3. **Shell Layer**: ZSH 和 Oh My Zsh 配置
4. **Theme Layer**: Powerlevel10k 主題配置
5. **Plugins Layer**: ZSH 外掛安裝和配置

## Components and Interfaces

### 1. Base System Components

#### Python Environment
- **Base Image**: `python:3.11-slim`
- **Package Manager**: uv (保持現有配置)
- **Virtual Environment**: `/opt/venv` (保持現有路徑)

#### System Dependencies
```dockerfile
# Essential build tools and dependencies
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    wget \
    unzip \
    zsh
```

### 2. Development Tools Components

#### Package Installation Strategy
使用 apt 套件管理器安裝大部分工具，特殊工具使用直接下載方式：

```dockerfile
# Standard tools via apt
RUN apt-get install -y \
    git \
    net-tools \
    jq \
    lftp \
    moreutils

# Special installations
# ripgrep: GitHub releases
# bat: GitHub releases  
# btop: GitHub releases
# yq: GitHub releases
```

#### Tool Configuration
- **ripgrep**: 設定別名 `rg` 和基本配置
- **bat**: 配置語法高亮主題和 Git 整合
- **btop**: 基本系統監控配置
- **yq**: 支援多格式解析配置

### 3. Shell Environment Components

#### ZSH Installation and Configuration
```bash
# Install ZSH and set as default shell
RUN chsh -s $(which zsh)

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```

#### Oh My Zsh Configuration Structure
```
~/.oh-my-zsh/
├── themes/
│   └── powerlevel10k/
├── plugins/
│   ├── zsh-autosuggestions/
│   ├── zsh-syntax-highlighting/
│   └── zsh-z/
└── custom/
    └── themes/
```

### 4. Theme and Plugin Components

#### Powerlevel10k Theme
- **Installation**: Git clone 到 Oh My Zsh themes 目錄
- **Configuration**: 透過 `.zshrc` 設定 `ZSH_THEME="powerlevel10k/powerlevel10k"`
- **System Monitoring**: 配置顯示 CPU、RAM、磁碟使用率

#### ZSH Plugins Configuration
```bash
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-z
)
```

## Data Models

### Configuration Files Structure

#### .zshrc Configuration
```bash
# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugin configuration
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-z)

# Custom aliases for development tools
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cat='bat'
alias grep='rg'

# Python environment
source /opt/venv/bin/activate
export PYTHONPATH=/app
```

#### Powerlevel10k Configuration
```bash
# System monitoring elements
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir
    vcs
    disk_usage
    ram
    load
)

POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status
    time
)
```

### Environment Variables
保持現有環境變數並新增 ZSH 相關配置：
```dockerfile
ENV SHELL=/bin/zsh
ENV ZSH_THEME=powerlevel10k/powerlevel10k
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
```

## Error Handling

### Installation Error Handling
1. **Network Issues**: 使用 retry 機制和 fallback URLs
2. **Package Conflicts**: 明確指定套件版本和依賴關係
3. **Permission Issues**: 確保正確的使用者權限設定

### Runtime Error Handling
1. **Shell Startup**: 提供 fallback 到 bash 的機制
2. **Plugin Loading**: 個別外掛載入失敗不影響整體功能
3. **Tool Availability**: 提供工具可用性檢查和友善錯誤訊息

### Dockerfile Error Handling Strategy
```dockerfile
# Use set -e for immediate error exit
RUN set -e && \
    # Installation commands with error checking
    command1 && \
    command2 || { echo "Installation failed"; exit 1; }
```

## Testing Strategy

### Build Testing
1. **Multi-stage Build Validation**: 確保每個安裝階段成功完成
2. **Tool Availability Testing**: 驗證所有工具都能正確執行
3. **Shell Environment Testing**: 確保 ZSH 和外掛正常載入

### Integration Testing
1. **Docker Compose Integration**: 驗證與現有 compose 配置的相容性
2. **Volume Mount Testing**: 確保工作目錄正確掛載
3. **Network Configuration**: 驗證網路設定正常運作

### Functional Testing
```dockerfile
# Add testing layer
RUN python --version | grep "3.11" && \
    zsh --version && \
    rg --version && \
    jq --version && \
    bat --version && \
    btop --version && \
    yq --version && \
    echo "All tools installed successfully"
```

### User Acceptance Testing
1. **Terminal Experience**: 驗證 Powerlevel10k 主題正確顯示
2. **Plugin Functionality**: 測試自動建議、語法高亮、目錄跳轉功能
3. **Development Workflow**: 確保 Python 開發工作流程正常運作

## Implementation Considerations

### Performance Optimization
1. **Layer Caching**: 優化 Dockerfile 層級結構以提高建置速度
2. **Package Cleanup**: 清理不必要的套件快取和暫存檔案
3. **Startup Time**: 優化 ZSH 啟動時間和外掛載入速度

### Security Considerations
1. **Minimal Base Image**: 使用 slim 版本減少攻擊面
2. **Package Verification**: 驗證下載套件的完整性
3. **User Permissions**: 適當的檔案和目錄權限設定

### Maintainability
1. **Version Pinning**: 固定重要套件版本以確保可重現性
2. **Modular Configuration**: 分離配置檔案便於維護
3. **Documentation**: 詳細的安裝和配置說明