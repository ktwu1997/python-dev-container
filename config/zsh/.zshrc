# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# Set theme to Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Basic plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Python virtual environment configuration
export VIRTUAL_ENV=/opt/venv
export PATH="$VIRTUAL_ENV/bin:$PATH"
export PYTHONPATH=/app
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Tool aliases
alias cat='bat'
alias grep='rg'
alias top='btop'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Development aliases
alias pip='uv pip'
alias pip3='uv pip'
alias python-check='python --version && pip --version'
alias tools-check='/tmp/verify-tools.sh 2>/dev/null || echo "Tools verification script not found"'
alias env-check='env-check'
alias health-check='env-check'

# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Auto-activate virtual environment with error handling
if [[ -n "$VIRTUAL_ENV" ]]; then
    if [[ -d "$VIRTUAL_ENV" ]]; then
        if [[ "$VIRTUAL_ENV/bin" != *"$PATH"* ]]; then
            export PATH="$VIRTUAL_ENV/bin:$PATH"
        fi
    else
        echo "⚠️  Virtual environment path not found: $VIRTUAL_ENV"
        echo "    Creating new virtual environment..."
        python -m venv "$VIRTUAL_ENV" 2>/dev/null || echo "❌ Failed to create virtual environment"
    fi
else
    echo "⚠️  VIRTUAL_ENV not set. Python packages will be installed globally."
fi

# Welcome message
echo "Python Development Environment"
echo ""
echo "📋 Enhanced Command Aliases:"
echo "  cat  → bat     (syntax highlighting & line numbers)"
echo "  grep → rg      (ripgrep - faster search)"
echo "  top  → btop    (modern system monitor)"
echo "  pip  → uv pip  (faster package manager)"
echo "  pip3 → uv pip  (faster package manager)"
echo ""
echo "💡 Use 'command <original>' to access original tools if needed"
echo "   Example: command cat file.txt"