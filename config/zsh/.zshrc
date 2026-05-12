# Welcome function defined early so we can print the banner BEFORE p10k instant
# prompt takes over the screen. Anything printed after the instant_prompt block
# below will race with the cached prompt and trip p10k's console-I/O warning.
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

# Auto-display welcome for interactive shells — MUST run before instant_prompt
# so the output lands before p10k's cached prompt takes the screen.
[[ -o interactive ]] && show_welcome

# Enable Powerlevel10k instant prompt. Must stay near the top of ~/.zshrc.
# Console I/O ABOVE this line is fine; I/O BELOW it will trigger the warning.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
# Override container-inherited ZSH_CUSTOM that points to /root
export ZSH_CUSTOM="$ZSH/custom"

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

# Everything Claude Code (ECC) is installed as a Claude Code plugin
# (`claude plugin install ecc@ecc`) and updates via marketplace auto-update /
# `claude plugin update`. No shell-side auto-updater here on purpose — the old
# `_ecc_auto_update` ran ECC's `install.sh --profile full` daily, which dumped
# ~200 files into ~/.claude (agents/ commands/ rules/ scripts/ ...) and shadowed
# the plugin. If you ever want to force a plugin refresh: `claude plugin update`.

# Load user-local env if present (e.g. uv installed in $HOME/.local)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
