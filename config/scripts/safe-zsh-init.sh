#!/bin/bash

# Safe ZSH Initialization Script
# Ensures terminal compatibility before loading ZSH with P10k

echo "Initializing safe ZSH environment..."

# Test terminal capabilities
test_terminal() {
    # Check if we're in a proper terminal
    if [ ! -t 1 ]; then
        echo "Warning: Not running in a terminal, using fallback mode"
        return 1
    fi
    
    # Test unicode support
    if ! printf "\u2713" 2>/dev/null | grep -q "✓"; then
        echo "Warning: Limited Unicode support detected"
        export POWERLEVEL9K_MODE='ascii'
        export LC_ALL=C
    fi
    
    # Test color support
    if ! tput colors >/dev/null 2>&1 || [ "$(tput colors)" -lt 256 ]; then
        echo "Warning: Limited color support, adjusting terminal settings"
        export TERM=xterm
    fi
    
    return 0
}

# Set safe defaults
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export TERM=${TERM:-xterm-256color}

# Test and adjust if needed
test_terminal

# Ensure proper PATH
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

echo "Terminal initialization complete"

# Start ZSH if everything looks good
if command -v zsh >/dev/null 2>&1; then
    exec zsh "$@"
else
    echo "ZSH not found, falling back to bash"
    exec bash "$@"
fi