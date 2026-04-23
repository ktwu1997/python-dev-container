#!/bin/bash

# SSH Setup Script for Docker Container
echo "🔐 Setting up SSH service..."

# Generate SSH host keys if they don't exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Create SSH user if specified (only on first run)
if [ -n "$SSH_USER" ] && [ -n "$SSH_PASSWORD" ]; then
    if ! id "$SSH_USER" &>/dev/null; then
        # First run: create user and full setup
        useradd -m -s /bin/zsh "$SSH_USER"

        # Add user to sudo and root groups
        usermod -aG sudo "$SSH_USER"
        usermod -aG root "$SSH_USER"

        # Install Oh My Zsh for the SSH user
        sudo -u "$SSH_USER" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        # Install Powerlevel10k theme for SSH user
        sudo -u "$SSH_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "/home/$SSH_USER/.oh-my-zsh/custom/themes/powerlevel10k"

        # Install ZSH plugins for SSH user
        sudo -u "$SSH_USER" git clone https://github.com/zsh-users/zsh-autosuggestions "/home/$SSH_USER/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
        sudo -u "$SSH_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "/home/$SSH_USER/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
        sudo -u "$SSH_USER" git clone https://github.com/agkozak/zsh-z "/home/$SSH_USER/.oh-my-zsh/custom/plugins/zsh-z"

        # Copy ZSH configuration to user home with proper ownership
        cp /root/.zshrc "/home/$SSH_USER/.zshrc"
        cp /root/.zshenv "/home/$SSH_USER/.zshenv"
        cp /root/.p10k.zsh "/home/$SSH_USER/.p10k.zsh"

        # Fix ZSH configuration paths for the SSH user
        sed -i "s|/root/.oh-my-zsh|/home/$SSH_USER/.oh-my-zsh|g" "/home/$SSH_USER/.zshrc"

        # Fix pip aliases to use user's local UV installation
        sed -i "s|/root/.local/bin/uv|uv|g" "/home/$SSH_USER/.zshrc"

        # Create .local/bin directory and ensure proper PATH setup
        sudo -u "$SSH_USER" mkdir -p "/home/$SSH_USER/.local/bin"

        # Install UV for the SSH user (ensure it's in user space)
        sudo -u "$SSH_USER" curl -LsSf https://astral.sh/uv/install.sh | sudo -u "$SSH_USER" sh

        # Create .cargo/bin directory for Rust tools if needed
        sudo -u "$SSH_USER" mkdir -p "/home/$SSH_USER/.cargo/bin"

        # Create a symbolic link from user home to /workspace for convenience
        # Use -n to prevent following existing symlinks
        ln -sfn /workspace "/home/$SSH_USER/workspace"

        # Copy Claude Code config to SSH user (plugins, settings, ECC, etc.)
        if [ -d /root/.claude ]; then
            cp -r /root/.claude "/home/$SSH_USER/.claude"
            # Fix any hardcoded /root/ paths in ECC and Claude config files
            find "/home/$SSH_USER/.claude" -type f \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) \
                -exec sed -i "s|/root|/home/$SSH_USER|g" {} + 2>/dev/null || true
        fi

        # Copy Gemini config to SSH user
        if [ -d /root/.gemini ]; then
            cp -r /root/.gemini "/home/$SSH_USER/.gemini"
        fi

        # Copy Node.js global config if exists
        if [ -d /root/.npm ]; then
            cp -r /root/.npm "/home/$SSH_USER/.npm"
        fi

        # Set proper ownership (-h: don't follow symlinks)
        chown -Rh "$SSH_USER:$SSH_USER" "/home/$SSH_USER"

        # Give user write permissions to /workspace directory (non-recursive to avoid symlink issues)
        chown "$SSH_USER:$SSH_USER" /workspace
        chmod 755 /workspace

        echo "✅ SSH user '$SSH_USER' created with sudo privileges and /workspace access"
    else
        echo "✅ SSH user '$SSH_USER' already exists, skipping setup"
    fi

    # Always update password (in case it changed)
    echo "$SSH_USER:$SSH_PASSWORD" | chpasswd

    # Setup SSH key authentication from mounted host key
    if [ -f /tmp/host_ssh_key.pub ]; then
        mkdir -p "/home/$SSH_USER/.ssh"
        cp /tmp/host_ssh_key.pub "/home/$SSH_USER/.ssh/authorized_keys"
        chmod 700 "/home/$SSH_USER/.ssh"
        chmod 600 "/home/$SSH_USER/.ssh/authorized_keys"
        chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER/.ssh"
        echo "✅ SSH key authentication configured for '$SSH_USER'"
    fi
fi

# Configure SSH daemon
cat > /etc/ssh/sshd_config << EOF
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Start SSH service
service ssh start

echo "✅ SSH service started on port 22"