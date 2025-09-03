# ZSH Environment Configuration
# This file is loaded for all ZSH shells (interactive and non-interactive)

# Add essential paths
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/games"

# Load Rust environment if available
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi