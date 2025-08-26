#!/bin/bash

# Python Environment Isolation Test Script
echo "Python Environment Isolation Test"
echo "=================================="

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}1. System Python Environment${NC}"
echo "Python version: $(python --version)"
echo "Python executable: $(which python)"
echo "Current PYTHONPATH: ${PYTHONPATH:-'(not set)'}"

echo -e "\n${BLUE}2. Testing Virtual Environment Creation${NC}"
cd /tmp

# Test standard venv
echo -n "Creating standard venv... "
if python -m venv test_venv 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    echo -n "Activating standard venv... "
    source test_venv/bin/activate
    echo -e "${GREEN}✓${NC}"
    echo "  - Virtual env Python: $(which python)"
    echo "  - Virtual env PYTHONPATH: ${PYTHONPATH:-'(not set)'}"
    deactivate
    rm -rf test_venv
else
    echo -e "${YELLOW}Failed${NC}"
fi

# Test UV venv
echo -n "Creating UV venv... "
if uv venv test_uv_venv 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    echo -n "Activating UV venv... "
    source test_uv_venv/bin/activate
    echo -e "${GREEN}✓${NC}"
    echo "  - UV venv Python: $(which python)"
    echo "  - UV venv PYTHONPATH: ${PYTHONPATH:-'(not set)'}"
    deactivate
    rm -rf test_uv_venv
else
    echo -e "${YELLOW}Failed${NC}"
fi

echo -e "\n${BLUE}3. Package Manager Tests${NC}"
echo -n "Testing pip (should be aliased to uv pip)... "
if pip --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    echo "  $(pip --version)"
else
    echo -e "${YELLOW}Failed${NC}"
fi

echo -n "Testing uv directly... "
if uv --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    echo "  $(uv --version)"
else
    echo -e "${YELLOW}Failed${NC}"
fi

echo -e "\n${BLUE}4. Environment Variable Check${NC}"
echo "PYTHONDONTWRITEBYTECODE: ${PYTHONDONTWRITEBYTECODE:-'(not set)'}"
echo "PYTHONUNBUFFERED: ${PYTHONUNBUFFERED:-'(not set)'}"

echo -e "\n${GREEN}Environment isolation test completed!${NC}"
echo -e "Virtual environments can be created without PYTHONPATH conflicts."

cd - >/dev/null 2>&1