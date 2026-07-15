#!/bin/bash

# SSH Setup Script for Docker Container
echo "🔐 Setting up SSH service..."

# ── SSH host key 持久化 ──
# 讓容器重建後 host key 維持不變，避免用戶端每次都跳
# "REMOTE HOST IDENTIFICATION HAS CHANGED" 警告、還要手動刪 known_hosts。
# 流程：先從 /persistent 還原既有 host key → 沒有才產生 → 首次產生後備份回 /persistent。
HOSTKEY_STORE=/persistent/ssh_host_keys

# 1) 有持久化的 host key 就先還原到 /etc/ssh
if [ -d /persistent ] && ls "$HOSTKEY_STORE"/ssh_host_*_key >/dev/null 2>&1; then
    cp -a "$HOSTKEY_STORE"/ssh_host_* /etc/ssh/ 2>/dev/null || true
    chmod 600 /etc/ssh/ssh_host_*_key 2>/dev/null || true
    chmod 644 /etc/ssh/ssh_host_*_key.pub 2>/dev/null || true
    echo "✅ 已從 /persistent 還原 SSH host key（重建後 host key 不變）"
fi

# 2) 若還原後仍沒有 host key（首次啟動）才產生
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# 3) 首次產生的 host key 備份到 /persistent，供未來重建沿用
if [ -d /persistent ] && ! ls "$HOSTKEY_STORE"/ssh_host_*_key >/dev/null 2>&1; then
    mkdir -p "$HOSTKEY_STORE"
    cp -a /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub "$HOSTKEY_STORE"/ 2>/dev/null || true
    chmod 600 "$HOSTKEY_STORE"/ssh_host_*_key 2>/dev/null || true
    echo "✅ 已將 SSH host key 備份到 /persistent（首次）"
fi

# Create SSH user if specified (only on first run)
if [ -n "$SSH_USER" ] && [ -n "$SSH_PASSWORD" ]; then
    if ! id "$SSH_USER" &>/dev/null; then
        # First run: create user and full setup
        useradd -m -s /bin/zsh "$SSH_USER"

        # /home/$SSH_USER may already exist (Docker pre-creates it as root when
        # host dirs are bind-mounted into it), in which case `useradd -m`
        # leaves it root-owned. Fix that now so the `sudo -u $SSH_USER` steps
        # below (oh-my-zsh, p10k, uv, cargo) can write into it.
        chown "$SSH_USER:$SSH_USER" "/home/$SSH_USER"

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

        # Install Claude Code for the SSH user — its own copy under ~/.local/bin.
        # The Dockerfile only installs claude for root (/root/.local/bin), which
        # the SSH user can't reach; and ~/.local isn't on a persisted volume, so
        # without this it only appears after the user first runs `claude` (which
        # self-bootstraps). Same pattern as the uv install above.
        sudo -u "$SSH_USER" curl -fsSL https://claude.ai/install.sh | sudo -u "$SSH_USER" bash

        # Create .cargo/bin directory for Rust tools if needed
        sudo -u "$SSH_USER" mkdir -p "/home/$SSH_USER/.cargo/bin"

        # Create a symbolic link from user home to /workspace for convenience
        # Skip if home dir is inside /workspace (would create circular symlink)
        if [[ ! "/home/$SSH_USER" -ef "/workspace" ]] && [[ ! "/home/$SSH_USER" == /workspace/* ]]; then
            ln -sfn /workspace "/home/$SSH_USER/workspace"
        fi

        # Copy Claude Code config to SSH user (plugins, settings, etc.)
        if [ -d /root/.claude ]; then
            cp -r /root/.claude "/home/$SSH_USER/.claude"
            # Fix any hardcoded /root/ paths in Claude config files
            find "/home/$SSH_USER/.claude" -type f \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) \
                -exec sed -i "s|/root|/home/$SSH_USER|g" {} + 2>/dev/null || true
        fi

        # Register the ECC marketplace and install the plugin at RUNTIME (after
        # the bind-mount): the Dockerfile's build-time `claude plugin install`
        # lands in /root/.claude, which the SSH user's bind-mounted ~/.claude
        # shadows, so the build-time install never reaches this user. All
        # idempotent; failures are non-fatal.
        CLAUDE_BIN="/home/$SSH_USER/.local/bin/claude"
        if [ -x "$CLAUDE_BIN" ]; then
            # Drop a stale plugin id a migrated ~/.claude may carry (ECC's plugin
            # was renamed everything-claude-code -> ecc upstream).
            sudo -u "$SSH_USER" "$CLAUDE_BIN" plugin uninstall everything-claude-code@everything-claude-code >/dev/null 2>&1 || true
            sudo -u "$SSH_USER" "$CLAUDE_BIN" plugin marketplace add https://github.com/affaan-m/everything-claude-code.git >/dev/null 2>&1 || true
            sudo -u "$SSH_USER" "$CLAUDE_BIN" plugin install ecc@ecc >/dev/null 2>&1 || true
        fi

        # Codex config dir (auth.json, config.toml, AGENTS.md) — persisted via
        # host volume. The CLI itself is installed system-wide in the Dockerfile;
        # only the config/auth needs to survive a recreate. Nothing to seed: an
        # empty dir just means `codex login` has not run yet. The chown below
        # fixes ownership when Docker creates the host dir as root.
        mkdir -p "/home/$SSH_USER/.codex"

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

    # Setup SSH key authentication.
    # 授權來源優先序：
    #   1) /tmp/authorized_keys —— 你在 repo 自維護的公鑰清單（config/authorized_keys），
    #      與「跑在哪台主機」無關，本機 / VPS 都用同一份（建議做法）。
    #   2) /tmp/host_ssh_key.pub —— 舊機制：掛載主機自己的公鑰（向後相容）。
    if [ -f /tmp/authorized_keys ]; then
        AUTH_KEYS_SRC=/tmp/authorized_keys
    elif [ -f /tmp/host_ssh_key.pub ]; then
        AUTH_KEYS_SRC=/tmp/host_ssh_key.pub
    else
        AUTH_KEYS_SRC=""
    fi
    if [ -n "$AUTH_KEYS_SRC" ]; then
        mkdir -p "/home/$SSH_USER/.ssh"
        cp "$AUTH_KEYS_SRC" "/home/$SSH_USER/.ssh/authorized_keys"
        chmod 700 "/home/$SSH_USER/.ssh"
        chmod 600 "/home/$SSH_USER/.ssh/authorized_keys"
        chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER/.ssh"
        echo "✅ SSH key authentication configured for '$SSH_USER' (source: $AUTH_KEYS_SRC)"
    fi

    # ── 持久家目錄資料自動還原（survives container recreate）──
    # 持久資料放在主機，透過 /persistent 掛載進來，每次啟動自動還原到家目錄。
    # 要新增其他持久資料，把對應目錄放進主機的 .devcontainer-home 即可。
    if [ -d /persistent ]; then
        # SSH 私鑰：複製進家目錄並修好嚴格權限（金鑰是靜態的，用複製最安全）
        if [ -d /persistent/.ssh ]; then
            mkdir -p "/home/$SSH_USER/.ssh"
            cp -a /persistent/.ssh/. "/home/$SSH_USER/.ssh/" 2>/dev/null || true
            # authorized_keys 以掛載的公鑰清單為準（優先 /tmp/authorized_keys，
            # 相容舊的 /tmp/host_ssh_key.pub），確保還原後 SSH 登入仍正常。
            [ -n "$AUTH_KEYS_SRC" ] && cp "$AUTH_KEYS_SRC" "/home/$SSH_USER/.ssh/authorized_keys"
            chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER/.ssh"
            chmod 700 "/home/$SSH_USER/.ssh"
            chmod 600 "/home/$SSH_USER/.ssh/"* 2>/dev/null || true
        fi

        # ── 持久化 Claude / Codex 的對話與 resume 紀錄 ──
        # 這些資料會持續寫入，用 symlink 直接指向 /persistent（掛載到主機），
        # 讓 `claude --resume`、codex 的歷史在容器重建後依然保留。
        # 要新增其他要持久化的家目錄路徑，照樣加一行 persist_link 即可。
        persist_link() {  # $1=家目錄相對路徑  $2=dir|file|json
            local rel="$1" kind="$2" home="/home/$SSH_USER"
            local src="/persistent/$rel" dst="$home/$rel"
            mkdir -p "$(dirname "$src")" "$(dirname "$dst")"
            case "$kind" in
                dir)  mkdir -p "$src" ;;
                json) [ -e "$src" ] || echo '{}' > "$src" ;;   # 種一個合法空 JSON，避免程式讀到壞檔
                *)    [ -e "$src" ] || : > "$src" ;;            # 空檔（.jsonl 空內容是合法的）
            esac
            rm -rf "$dst"
            ln -sfn "$src" "$dst"
            chown -h "$SSH_USER:$SSH_USER" "$dst"
            chown -R "$SSH_USER:$SSH_USER" "$src" 2>/dev/null || true
        }
        # Claude Code：對話 transcript（--resume 讀這裡）、todo、歷史、專案/帳號狀態
        persist_link ".claude/projects"      dir
        persist_link ".claude/todos"         dir
        persist_link ".claude/history.jsonl" file
        persist_link ".claude.json"          json
        # Codex CLI：整個 ~/.codex（sessions、history、config、auth 都在裡面）
        persist_link ".codex"                dir

        echo "✅ 持久家目錄資料已從 /persistent 還原（含 Claude/Codex 對話與 resume 紀錄）"
    fi
fi

# Configure SSH daemon
# 安全性：僅允許金鑰登入，關閉密碼與 root 直接登入。
#   - 登入方式：以 $SSH_USER + 你維護的公鑰清單（config/authorized_keys）。
#   - 前提：docker-compose.yml 掛載 config/authorized_keys，且裡面至少有一把
#     你用戶端的公鑰，否則會無法登入。
#   - 若臨時需要密碼登入救援，可將 PasswordAuthentication 暫時改回 yes 再重建。
cat > /etc/ssh/sshd_config << EOF
Port 22
PermitRootLogin no
PasswordAuthentication no
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