# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# Set theme to Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Basic plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-z)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Add Rust and UV to PATH
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

# # Python virtual environment configuration
# export VIRTUAL_ENV=/opt/venv
# export PATH="$VIRTUAL_ENV/bin:$PATH"
# export PYTHONPATH=/workspace
# export PYTHONDONTWRITEBYTECODE=1
# export PYTHONUNBUFFERED=1

# Tool aliases
alias cat='bat'
alias grep='rg'
alias top='btop'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Claude Code alias (default to dangerously-skip-permissions mode)
alias claude='command claude --dangerously-skip-permissions'

# Development aliases
alias pip='uv pip'
alias pip3='uv pip'
alias python-check='python --version && pip --version'
alias tools-check='/tmp/verify-tools.sh 2>/dev/null || echo "Tools verification script not found"'
alias env-check='env-check'
alias health-check='env-check'

# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Welcome function
show_welcome() {
    echo "Python Development Environment"
    echo ""
    echo "Enhanced Command Aliases:"
    echo "  cat  -> bat     (syntax highlighting & line numbers)"
    echo "  grep -> rg      (ripgrep - faster search)"
    echo "  top  -> btop    (modern system monitor)"
    echo "  pip  -> uv pip  (faster package manager)"
    echo "  pip3 -> uv pip  (faster package manager)"
    echo ""
    echo "Powerlevel10k Setup:"
    echo "  Run 'p10k configure' to customize your prompt theme"
    echo "  This will create a personalized .p10k.zsh configuration"
    echo ""
    echo "Use 'command <original>' to access original tools if needed"
    echo "Example: command cat file.txt"
    echo ""
    echo "Type 'show_welcome' to display this message again"
}

# Auto-update Everything Claude Code (checks once per day)
_ecc_auto_update() {
  local state="$HOME/.claude/ecc/install-state.json"
  local stamp="$HOME/.claude/ecc/.last-update-check"
  local now=$(date +%s)

  # Skip if checked within last 24 hours
  if [[ -f "$stamp" ]]; then
    local last=$(<"$stamp")
    (( now - last < 86400 )) && return 0
  fi

  # Get local and remote versions
  local local_ver=""
  [[ -f "$state" ]] && local_ver=$(python3 -c "import json;print(json.load(open('$state')).get('source',{}).get('version',''))" 2>/dev/null)

  local remote_ver=$(curl -sf \
    "https://raw.githubusercontent.com/affaan-m/everything-claude-code/main/package.json" \
    | python3 -c "import json,sys;print(json.load(sys.stdin).get('version',''))" 2>/dev/null)

  # Update timestamp
  mkdir -p "$HOME/.claude/ecc"
  echo "$now" > "$stamp"

  # Install if no local version or version mismatch
  if [[ -z "$local_ver" || "$local_ver" != "$remote_ver" ]]; then
    echo "[ECC] Updating: ${local_ver:-none} -> ${remote_ver}..."
    (
      cd /tmp &&
      rm -rf ecc-auto &&
      git clone --depth 1 https://github.com/affaan-m/everything-claude-code.git ecc-auto 2>/dev/null &&
      cd ecc-auto &&
      npm install --silent 2>/dev/null &&
      ./install.sh --profile full 2>/dev/null &&
      cd /tmp && rm -rf ecc-auto
    ) && echo "[ECC] Updated to ${remote_ver}." || echo "[ECC] Update failed."
  fi
}

# Auto-display welcome message for interactive shells
# Check if this is an interactive shell (ZSH-specific method)
if [[ -o interactive ]]; then
    show_welcome
    _ecc_auto_update &!
fi