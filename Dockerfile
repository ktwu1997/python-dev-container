FROM python:3.11

# Install system dependencies and development tools in one layer
RUN apt-get update && apt-get install -y \
    # Essential build tools
    curl \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    gnupg \
    lsb-release \
    wget \
    unzip \
    # Development tools
    git \
    zsh \
    vim \
    net-tools \
    jq \
    btop \
    lftp \
    moreutils \
    tmux \
    mosh \
    # SSH server and sudo
    openssh-server \
    sudo \
    # Timezone data for Asia/Taipei (used by p10k time segment via TZ in .zshenv)
    tzdata \
    # Locale data（mosh-server 需要可用的 UTF-8 native locale，如 en_US.UTF-8）
    locales \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 產生 en_US.UTF-8 語系。
# mosh-server 需要一個「可用的」UTF-8 native locale 才會啟動；
# mosh 客戶端會把本機 LANG=en_US.UTF-8 帶進來，容器若沒產生此語系就會啟動失敗。
RUN sed -i '/^# *en_US.UTF-8 UTF-8/s/^# *//' /etc/locale.gen && locale-gen



# Install special tools (ripgrep, bat, yq) from GitHub releases.
# - ripgrep & bat .deb names embed the version, so query the GitHub API
#   (with retries; `jq -er` fails the build LOUDLY if rate-limited instead of
#   silently producing a "download/null/..." URL like the old version did).
# - yq asset name has no version, so use the redirect-style
#   releases/latest/download URL — no API call, immune to version surprises.
# - btop is installed via apt (see the apt-get list above) to avoid the
#   GitHub 404 that hit its renamed release assets.
RUN set -eu; \
    DPKG_ARCH="$(dpkg --print-architecture)"; \
    echo "Arch: $DPKG_ARCH"; \
    RG_TAG="$(curl -sfL --retry 3 --retry-delay 2 https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | jq -er .tag_name)"; \
    BAT_TAG="$(curl -sfL --retry 3 --retry-delay 2 https://api.github.com/repos/sharkdp/bat/releases/latest | jq -er .tag_name)"; \
    RG_VER="${RG_TAG#v}"; BAT_VER="${BAT_TAG#v}"; \
    echo "ripgrep ${RG_TAG} / bat ${BAT_TAG}"; \
    # ripgrep
    if [ "$DPKG_ARCH" = "arm64" ]; then \
      wget -nv -O /tmp/rg.tar.gz "https://github.com/BurntSushi/ripgrep/releases/download/${RG_TAG}/ripgrep-${RG_VER}-aarch64-unknown-linux-gnu.tar.gz"; \
      tar -xzf /tmp/rg.tar.gz -C /tmp; \
      install -m755 "/tmp/ripgrep-${RG_VER}-aarch64-unknown-linux-gnu/rg" /usr/local/bin/rg; \
      rm -rf /tmp/rg.tar.gz "/tmp/ripgrep-${RG_VER}-aarch64-unknown-linux-gnu"; \
    else \
      wget -nv -O /tmp/rg.deb "https://github.com/BurntSushi/ripgrep/releases/download/${RG_TAG}/ripgrep_${RG_VER}-1_amd64.deb"; \
      dpkg -i /tmp/rg.deb; rm /tmp/rg.deb; \
    fi; \
    # bat (.deb name = bat_<ver>_<dpkg-arch>.deb)
    wget -nv -O /tmp/bat.deb "https://github.com/sharkdp/bat/releases/download/${BAT_TAG}/bat_${BAT_VER}_${DPKG_ARCH}.deb"; \
    dpkg -i /tmp/bat.deb; rm /tmp/bat.deb; \
    # yq (single static binary)
    wget -nv -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${DPKG_ARCH}"; \
    chmod 755 /usr/local/bin/yq

# Copy and run tool verification script
COPY config/scripts/verify-tools.sh /tmp/verify-tools.sh
RUN chmod +x /tmp/verify-tools.sh && \
    /tmp/verify-tools.sh && \
    rm /tmp/verify-tools.sh

# Copy essential utility scripts
COPY config/scripts/env-check.sh /usr/local/bin/env-check
COPY config/scripts/fallback-shell.sh /usr/local/bin/fallback-shell
COPY config/scripts/docker-zsh-setup.sh /usr/local/bin/docker-zsh-setup
COPY config/scripts/test-terminal-output.sh /usr/local/bin/test-terminal
COPY config/scripts/ssh-setup.sh /usr/local/bin/ssh-setup
COPY config/scripts/test-ssh.sh /usr/local/bin/test-ssh
COPY config/scripts/test-python-env.sh /usr/local/bin/test-python-env
COPY config/scripts/safe-zsh-init.sh /usr/local/bin/safe-zsh-init
RUN chmod +x /usr/local/bin/env-check /usr/local/bin/fallback-shell /usr/local/bin/docker-zsh-setup /usr/local/bin/test-terminal /usr/local/bin/ssh-setup /usr/local/bin/test-ssh /usr/local/bin/test-python-env /usr/local/bin/safe-zsh-init

# Set ZSH as default shell
RUN chsh -s $(which zsh)
ENV SHELL=/bin/zsh

# Install Oh My Zsh (unattended mode)
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Powerlevel10k theme
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install ZSH plugins in one layer
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/agkozak/zsh-z ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-z

# Copy ZSH configuration
COPY config/zsh/.zshrc /root/.zshrc
COPY config/zsh/.zshenv /root/.zshenv
COPY config/zsh/.p10k.zsh /root/.p10k.zsh

# Set basic environment variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TERM=xterm-256color
ENV PATH="/root/.cargo/bin:$PATH"
# Timezone (matches TZ in config/zsh/.zshenv so non-interactive shells agree)
ENV TZ=Asia/Taipei
# Set ZSH environment variables
ENV ZSH_CUSTOM=/root/.oh-my-zsh/custom
ENV POWERLEVEL9K_DISABLE_GITSTATUS=false
# Powerlevel10k Nerd Font mode (matches POWERLEVEL9K_MODE in .p10k.zsh — host
# terminal must use a Nerd Font like MesloLGS NF for glyphs to render)
ENV POWERLEVEL9K_MODE=nerdfont-complete

# Install Rust and UV, setup Python environment in one layer
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /root/.bashrc

# Install Node.js 22 (required for Claude Code / npm-based tooling)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Claude Code (official native installer)
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/root/.local/bin:$PATH"

# Install OpenAI Codex CLI + Claude Code globally (npm -g 落在 /usr/bin，所有使用者可用)。
# 上面的原生 Claude Code 只裝在 /root/.local/bin（root 專屬），非 root 的 SSH 使用者
# (tsung) 讀不到，因此這裡用全域安裝讓 root 與 tsung 都能執行 claude / codex。
RUN npm install -g @openai/codex @anthropic-ai/claude-code

# Install Antigravity CLI (agy) — Gemini CLI 的接班人
# gemini-cli 個人版 2026-06-18 停用，npm 套件 @google/gemini-cli 已改為官方安裝腳本
# 安裝原生 Go binary（預設落在 ~/.local/bin/agy），這裡搬到 /usr/local/bin 讓 root 與
# SSH user 都能在 PATH 取得，對齊原本 npm -g 的全域行為。
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash && \
    if [ -f /root/.local/bin/agy ]; then mv /root/.local/bin/agy /usr/local/bin/agy; fi && \
    chmod +x /usr/local/bin/agy && \
    agy --version || true

# Setup GitHub SSH host key & fix git credential helper for HTTPS
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null && \
    git config --global credential.helper store

# Install Anthropic skills marketplace
RUN mkdir -p /root/.claude && \
    claude plugins marketplace add https://github.com/anthropics/skills.git

# Install MemPalace (AI memory) — Python package + Claude Code plugin.
# The palace DATA lives at ~/.mempalace and is persisted via a host volume
# (see docker-compose.yml); only the install is baked into the image here.
RUN pip install --no-cache-dir mempalace && \
    mkdir -p /root/.claude && \
    claude plugin marketplace add https://github.com/milla-jovovich/mempalace.git && \
    claude plugin install mempalace@mempalace

# Enable marketplace auto-update, register MemPalace auto-save hooks, Gemini config
RUN python3 -c "\
import json, pathlib; \
p = pathlib.Path('/root/.claude/settings.json'); \
s = json.loads(p.read_text()) if p.exists() else {}; \
s.setdefault('extraKnownMarketplaces', {}); \
[s['extraKnownMarketplaces'].setdefault(k, {}).update({'autoUpdate': True}) for k in s['extraKnownMarketplaces']]; \
s['autoUpdaterStatus'] = 'enabled'; \
h = s.setdefault('hooks', {}); \
mp = lambda hook: [{'matcher': '', 'hooks': [{'type': 'command', 'command': '/usr/local/bin/python3 -m mempalace hook run --hook ' + hook + ' --harness claude-code'}]}]; \
h.setdefault('Stop', mp('stop')); \
h.setdefault('PreCompact', mp('precompact')); \
p.write_text(json.dumps(s, indent=2))" && \
    mkdir -p /root/.gemini && echo '{}' > /root/.gemini/projects.json

# Create SSH directory and configure sudo
RUN mkdir -p /var/run/sshd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Expose SSH port
EXPOSE 22

WORKDIR /workspace

# Ensure /workspace directory has proper permissions
RUN chmod 755 /workspace

# Create startup script that switches to non-root user after init
RUN cat > /usr/local/bin/docker-entrypoint.sh << 'SCRIPT'
#!/bin/bash
# Run SSH setup as root (creates user, starts sshd)
ssh-setup

# Switch to SSH_USER if set, so claude --dangerously-skip-permissions works
if [ -n "$SSH_USER" ] && id "$SSH_USER" &>/dev/null; then
    exec su - "$SSH_USER" -c "exec safe-zsh-init $*"
else
    exec safe-zsh-init "$@"
fi
SCRIPT

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD []