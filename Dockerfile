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
    lftp \
    moreutils \
    # SSH server and sudo
    openssh-server \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*



# Install special tools from GitHub releases in one optimized layer
RUN ARCH=$(dpkg --print-architecture) && echo "Architecture: $ARCH" && \
    # Get all versions at once
    RIPGREP_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | jq -r .tag_name) && \
    BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | jq -r .tag_name) && \
    BTOP_VERSION=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | jq -r .tag_name) && \
    YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name) && \
    # Install ripgrep
    if [ "$ARCH" = "arm64" ]; then \
    wget -O /tmp/ripgrep.tar.gz "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION#v}-aarch64-unknown-linux-gnu.tar.gz" && \
    tar -xzf /tmp/ripgrep.tar.gz -C /tmp && \
    cp /tmp/ripgrep-${RIPGREP_VERSION#v}-aarch64-unknown-linux-gnu/rg /usr/local/bin/ && \
    chmod +x /usr/local/bin/rg && \
    rm -rf /tmp/ripgrep.tar.gz /tmp/ripgrep-${RIPGREP_VERSION#v}-aarch64-unknown-linux-gnu; \
    else \
    wget -O /tmp/ripgrep.deb "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep_${RIPGREP_VERSION#v}-1_amd64.deb" && \
    dpkg -i /tmp/ripgrep.deb && \
    rm /tmp/ripgrep.deb; \
    fi && \
    # Install bat
    if [ "$ARCH" = "arm64" ]; then \
    wget -O /tmp/bat.deb "https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat_${BAT_VERSION#v}_arm64.deb"; \
    else \
    wget -O /tmp/bat.deb "https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat_${BAT_VERSION#v}_amd64.deb"; \
    fi && \
    dpkg -i /tmp/bat.deb && \
    rm /tmp/bat.deb && \
    # Install btop
    if [ "$ARCH" = "arm64" ]; then \
    wget -O /tmp/btop.tbz "https://github.com/aristocratos/btop/releases/download/${BTOP_VERSION}/btop-aarch64-linux-musl.tbz"; \
    else \
    wget -O /tmp/btop.tbz "https://github.com/aristocratos/btop/releases/download/${BTOP_VERSION}/btop-x86_64-linux-musl.tbz"; \
    fi && \
    tar -xjf /tmp/btop.tbz -C /tmp && \
    cp /tmp/btop/bin/btop /usr/local/bin/ && \
    chmod +x /usr/local/bin/btop && \
    rm -rf /tmp/btop.tbz /tmp/btop && \
    # Install yq
    if [ "$ARCH" = "arm64" ]; then \
    wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_arm64"; \
    else \
    wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"; \
    fi && \
    chmod +x /usr/local/bin/yq

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
RUN chmod +x /usr/local/bin/env-check /usr/local/bin/fallback-shell /usr/local/bin/docker-zsh-setup /usr/local/bin/test-terminal /usr/local/bin/ssh-setup /usr/local/bin/test-ssh /usr/local/bin/test-python-env

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

# Copy ZSH configuration files
COPY config/zsh/.zshrc /root/.zshrc
COPY config/zsh/.p10k.zsh /root/.p10k.zsh

# Set basic environment variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TERM=xterm-256color
ENV PATH="/root/.cargo/bin:$PATH"

# Install Rust and UV, setup Python environment in one layer
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /root/.bashrc

# Create SSH directory and configure sudo
RUN mkdir -p /var/run/sshd && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Expose SSH port
EXPOSE 22

WORKDIR /app

# Ensure /app directory has proper permissions
RUN chmod 755 /app

# Create startup script
RUN echo '#!/bin/bash\nssh-setup\nexec "$@"' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["zsh"]