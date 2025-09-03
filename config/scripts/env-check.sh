#!/bin/bash

# Enhanced Python Development Environment Check Script
echo "Enhanced Python Development Environment - Health Check"
echo "========================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check command and version in current environment
check_command() {
    local cmd=$1
    local expected_pattern=$2
    local description=$3
    
    echo -n "Checking $description... "
    
    if command -v "$cmd" >/dev/null 2>&1; then
        version_output=$($cmd --version 2>&1 | head -1)
        if [[ -n "$expected_pattern" && ! "$version_output" =~ $expected_pattern ]]; then
            echo -e "${YELLOW}WARNING${NC}: $version_output (unexpected format)"
        else
            echo -e "${GREEN}✓${NC} $version_output"
        fi
    else
        echo -e "${RED}✗${NC} Not found"
        return 1
    fi
}

# Function to check command in ZSH environment
check_command_zsh() {
    local cmd=$1
    local expected_pattern=$2
    local description=$3
    
    echo -n "Checking $description (ZSH env)... "
    
    if command -v zsh >/dev/null 2>&1; then
        result=$(zsh -c "source ~/.zshrc >/dev/null 2>&1; command -v '$cmd' >/dev/null 2>&1 && $cmd --version 2>&1 | head -1" 2>/dev/null)
        if [[ -n "$result" ]]; then
            if [[ -n "$expected_pattern" && ! "$result" =~ $expected_pattern ]]; then
                echo -e "${YELLOW}WARNING${NC}: $result (unexpected format)"
            else
                echo -e "${GREEN}✓${NC} $result"
            fi
        else
            echo -e "${RED}✗${NC} Not found in ZSH environment"
            return 1
        fi
    else
        echo -e "${RED}✗${NC} ZSH not available"
        return 1
    fi
}

# Function to check file exists
check_file() {
    local file=$1
    local description=$2
    
    echo -n "Checking $description... "
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} Found"
    else
        echo -e "${RED}✗${NC} Not found: $file"
        return 1
    fi
}

# Function to check environment variable
check_env_var() {
    local var_name=$1
    local description=$2
    
    echo -n "Checking $description... "
    
    if [[ -n "${!var_name}" ]]; then
        echo -e "${GREEN}✓${NC} ${!var_name}"
    else
        echo -e "${YELLOW}WARNING${NC}: $var_name not set"
        return 1
    fi
}

echo -e "\n${BLUE}1. System Information${NC}"
echo "Architecture: $(uname -m)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Shell: $SHELL"

echo -e "\n${BLUE}2. Python Environment${NC}"
check_command "python" "Python 3\.11" "Python 3.11"

# Check Python environment in ZSH
echo -n "Checking Python in ZSH environment... "
if command -v zsh >/dev/null 2>&1; then
    zsh_python_info=$(zsh -c "source ~/.zshrc >/dev/null 2>&1; python --version 2>&1" 2>/dev/null)
    if [[ -n "$zsh_python_info" ]]; then
        echo -e "${GREEN}✓${NC} $zsh_python_info"
    else
        echo -e "${RED}✗${NC} Python not accessible in ZSH"
    fi
else
    echo -e "${RED}✗${NC} ZSH not available"
fi

echo -e "\n${BLUE}3. Package Managers${NC}"
# Check UV in ZSH environment (primary environment)
check_command_zsh "uv" "uv" "UV Package Manager"
check_command "pip" "" "Pip (should be aliased to uv pip)"

echo -e "\n${BLUE}4. Development Tools${NC}"
check_command "git" "git version" "Git"
check_command "vim" "VIM.*Vi.*IMproved" "Vim"
check_command "rg" "ripgrep" "Ripgrep"
check_command "bat" "bat" "Bat"
check_command "btop" "" "Btop"
check_command "yq" "yq.*version" "YQ"
check_command "jq" "jq" "JQ"

echo -e "\n${BLUE}5. ZSH Environment${NC}"
check_command "zsh" "zsh" "ZSH Shell"
check_file "$HOME/.oh-my-zsh/oh-my-zsh.sh" "Oh My Zsh installation"
check_file "$HOME/.zshrc" "ZSH configuration"
check_file "$HOME/.p10k.zsh" "Powerlevel10k configuration"

echo -e "\n${BLUE}6. ZSH Plugins${NC}"
check_file "$HOME/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" "Powerlevel10k theme"
check_file "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" "ZSH Autosuggestions"
check_file "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "ZSH Syntax Highlighting"
check_file "$HOME/.oh-my-zsh/custom/plugins/zsh-z/zsh-z.plugin.zsh" "ZSH-Z plugin"

echo -e "\n${BLUE}7. Tool Aliases${NC}"
echo -n "Checking aliases... "

# Create a temporary script to run in ZSH environment
temp_alias_check=$(mktemp)
cat > "$temp_alias_check" << 'EOF'
#!/bin/zsh
source ~/.zshrc >/dev/null 2>&1

aliases_ok=true

# Check key aliases
if ! alias cat 2>/dev/null | grep -q "bat"; then
    echo "WARNING: cat alias not set to bat"
    aliases_ok=false
fi

if ! alias grep 2>/dev/null | grep -q "rg"; then
    echo "WARNING: grep alias not set to rg"
    aliases_ok=false
fi

if ! alias top 2>/dev/null | grep -q "btop"; then
    echo "WARNING: top alias not set to btop"
    aliases_ok=false
fi

if ! alias pip 2>/dev/null | grep -q "uv pip"; then
    echo "WARNING: pip alias not set to uv pip"
    aliases_ok=false
fi

if $aliases_ok; then
    echo "SUCCESS: All key aliases configured"
fi
EOF
chmod +x "$temp_alias_check"

# Run the check in ZSH
if command -v zsh >/dev/null 2>&1; then
    result=$(zsh "$temp_alias_check" 2>&1)
    if echo "$result" | grep -q "SUCCESS"; then
        echo -e "${GREEN}✓${NC} All key aliases configured"
    else
        echo -e "${YELLOW}WARNING${NC}: Some aliases missing"
        echo "$result" | grep "WARNING" | sed 's/^/  /'
    fi
else
    echo -e "${YELLOW}WARNING${NC}: ZSH not available for alias checking"
fi

# Clean up
rm -f "$temp_alias_check"

echo -e "\n${BLUE}8. Network and System Tools${NC}"
check_command "netstat" "" "Netstat"
check_command "lftp" "" "LFTP"

# Special handling for sponge to avoid timeout
echo -n "Checking Sponge (moreutils)... "
if command -v sponge >/dev/null 2>&1; then
    # Quick test instead of --version which might hang
    if echo "test" | sponge /tmp/sponge_test 2>/dev/null && [ -f /tmp/sponge_test ]; then
        rm -f /tmp/sponge_test
        echo -e "${GREEN}✓${NC} Sponge is working"
    else
        echo -e "${YELLOW}WARNING${NC}: Sponge found but not functioning properly"
    fi
else
    echo -e "${RED}✗${NC} Not found"
fi

echo -e "\n${BLUE}9. Rust Environment${NC}"
check_command "rustc" "rustc" "Rust Compiler"
check_command "cargo" "cargo" "Cargo"

echo -e "\n${BLUE}10. Final Environment Test${NC}"
echo -n "Testing Python import... "
if python -c "import sys; print(f'Python {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Python imports working"
else
    echo -e "${RED}✗${NC} Python import failed"
fi

echo -n "Testing UV in ZSH environment... "
if command -v zsh >/dev/null 2>&1; then
    if zsh -c "source ~/.zshrc >/dev/null 2>&1; uv --version >/dev/null 2>&1" 2>/dev/null; then
        uv_version=$(zsh -c "source ~/.zshrc >/dev/null 2>&1; uv --version" 2>/dev/null)
        echo -e "${GREEN}✓${NC} UV working in ZSH: $uv_version"
    else
        echo -e "${RED}✗${NC} UV not working in ZSH environment"
    fi
else
    echo -e "${RED}✗${NC} ZSH not available"
fi

echo -e "\n${BLUE}11. Environment Summary${NC}"
echo "Primary Shell: ZSH (for development)"
echo "Health Check Shell: BASH (for compatibility)"
echo "UV Package Manager: Available in ZSH environment"
echo "Python Development: Ready in ZSH environment"

echo -e "\n${GREEN}Environment check completed!${NC}"
echo "If you see any warnings or errors above, please check the installation."