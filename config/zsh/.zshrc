# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# Set theme to Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Basic plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Add Rust and UV to PATH
export PATH="$HOME/.cargo/bin:$PATH"

# # Python virtual environment configuration
# export VIRTUAL_ENV=/opt/venv
# export PATH="$VIRTUAL_ENV/bin:$PATH"
# export PYTHONPATH=/app
# export PYTHONDONTWRITEBYTECODE=1
# export PYTHONUNBUFFERED=1

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

# Function to show welcome message after prompt is ready
show_welcome() {
    echo "Python Development Environment"
    echo ""
    echo "📋 Enhanced Command Aliases:"
    echo "  cat  → bat     (syntax highlighting & line numbers)"
    echo "  grep → rg      (ripgrep - faster search)"
    echo "  top  → btop    (modern system monitor)"
    echo "  pip  → uv pip  (faster package manager)"
    echo "  pip3 → uv pip  (faster package manager)"
    echo ""
    echo "⚡ Powerlevel10k Setup:"
    echo "  Run 'p10k configure' to customize your prompt theme"
    echo "  This will create a personalized .p10k.zsh configuration"
    echo ""
    echo "💡 Use 'command <original>' to access original tools if needed"
    echo "   Example: command cat file.txt"
}

# Show welcome message after prompt is ready (deferred execution)
# This prevents interference with Powerlevel10k instant prompt
if [[ -o interactive ]]; then
    # Schedule welcome message to run after current command completes
    zle -N show_welcome_widget
    show_welcome_widget() { show_welcome }
    # Use precmd hook to show welcome message on first interactive prompt
    precmd_show_welcome() {
        show_welcome
        # Remove this function after first execution
        unfunction precmd_show_welcome 2>/dev/null
    }
    # Only add if not already in precmd_functions
    if [[ ! " ${precmd_functions[*]} " =~ " precmd_show_welcome " ]]; then
        precmd_functions+=(precmd_show_welcome)
    fi
fi