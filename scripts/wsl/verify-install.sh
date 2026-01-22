#!/bin/bash
#
# Installation verification script
# Checks all components and reports status
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${CYAN}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_fail() { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              Installation Verification                        ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

PASSED=0
WARNED=0
FAILED=0

check_pass() {
    print_success "$1"
    ((PASSED++))
}

check_warn() {
    print_warning "$1"
    ((WARNED++))
}

check_fail() {
    print_fail "$1"
    ((FAILED++))
}

# Source environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$HOME/.local/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true
source "$HOME/.cargo/env" 2>/dev/null || true
export PATH="$PATH:/usr/local/go/bin"

# ============================================================
# System Tools
# ============================================================
echo -e "${YELLOW}System Tools${NC}"
echo "────────────────────────────────────"

# Git
if command -v git &> /dev/null; then
    check_pass "Git: $(git --version | cut -d' ' -f3)"
else
    check_fail "Git not installed"
fi

# Curl
if command -v curl &> /dev/null; then
    check_pass "curl: $(curl --version | head -1 | cut -d' ' -f2)"
else
    check_fail "curl not installed"
fi

# jq
if command -v jq &> /dev/null; then
    check_pass "jq: $(jq --version)"
else
    check_warn "jq not installed"
fi

echo ""

# ============================================================
# CLI Utilities
# ============================================================
echo -e "${YELLOW}CLI Utilities${NC}"
echo "────────────────────────────────────"

# ripgrep
if command -v rg &> /dev/null; then
    check_pass "ripgrep: $(rg --version | head -1 | cut -d' ' -f2)"
else
    check_warn "ripgrep not installed"
fi

# fd
if command -v fd &> /dev/null; then
    check_pass "fd: $(fd --version | cut -d' ' -f2)"
elif command -v fdfind &> /dev/null; then
    check_pass "fd (as fdfind): $(fdfind --version | cut -d' ' -f2)"
else
    check_warn "fd not installed"
fi

# fzf
if command -v fzf &> /dev/null; then
    check_pass "fzf: $(fzf --version | cut -d' ' -f1)"
else
    check_warn "fzf not installed"
fi

# bat
if command -v bat &> /dev/null; then
    check_pass "bat: $(bat --version | cut -d' ' -f2)"
elif command -v batcat &> /dev/null; then
    check_pass "bat (as batcat): $(batcat --version | cut -d' ' -f2)"
else
    check_warn "bat not installed"
fi

echo ""

# ============================================================
# Languages & Runtimes
# ============================================================
echo -e "${YELLOW}Languages & Runtimes${NC}"
echo "────────────────────────────────────"

# Node.js
if command -v node &> /dev/null; then
    check_pass "Node.js: $(node --version)"
else
    check_warn "Node.js not installed"
fi

# npm
if command -v npm &> /dev/null; then
    check_pass "npm: $(npm --version)"
else
    check_warn "npm not installed"
fi

# Python
if command -v python &> /dev/null; then
    check_pass "Python: $(python --version 2>&1 | cut -d' ' -f2)"
elif command -v python3 &> /dev/null; then
    check_pass "Python3: $(python3 --version 2>&1 | cut -d' ' -f2)"
else
    check_warn "Python not installed"
fi

# Rust
if command -v rustc &> /dev/null; then
    check_pass "Rust: $(rustc --version | cut -d' ' -f2)"
else
    check_warn "Rust not installed"
fi

# Go
if command -v go &> /dev/null; then
    check_pass "Go: $(go version | cut -d' ' -f3 | sed 's/go//')"
else
    check_warn "Go not installed"
fi

echo ""

# ============================================================
# Docker
# ============================================================
echo -e "${YELLOW}Docker${NC}"
echo "────────────────────────────────────"

# Docker CLI
if command -v docker &> /dev/null; then
    check_pass "Docker CLI: $(docker --version | cut -d' ' -f3 | tr -d ',')"

    # Docker connectivity
    if docker ps &>/dev/null; then
        check_pass "Docker daemon: connected"
    else
        check_warn "Docker daemon: not accessible (start Docker Desktop)"
    fi
else
    check_fail "Docker CLI not installed"
fi

# Docker Compose
if docker compose version &>/dev/null; then
    check_pass "Docker Compose: $(docker compose version | cut -d' ' -f4)"
elif command -v docker-compose &> /dev/null; then
    check_pass "docker-compose: $(docker-compose --version | cut -d' ' -f4)"
else
    check_warn "Docker Compose not installed"
fi

echo ""

# ============================================================
# GitHub Tools
# ============================================================
echo -e "${YELLOW}GitHub Tools${NC}"
echo "────────────────────────────────────"

# GitHub CLI
if command -v gh &> /dev/null; then
    check_pass "GitHub CLI: $(gh --version | head -1 | cut -d' ' -f3)"

    # gh authentication
    if gh auth status &>/dev/null; then
        check_pass "GitHub auth: authenticated"
    else
        check_warn "GitHub auth: not authenticated (run: gh auth login)"
    fi
else
    check_fail "GitHub CLI not installed"
fi

# SSH key
if [[ -f ~/.ssh/id_ed25519 ]]; then
    check_pass "SSH key: ~/.ssh/id_ed25519 exists"
else
    check_warn "SSH key: not found (run install-github.sh)"
fi

# SSH GitHub connectivity
if ssh -T git@github.com -o BatchMode=yes -o ConnectTimeout=5 2>&1 | grep -q "successfully authenticated"; then
    check_pass "SSH to GitHub: connected"
else
    check_warn "SSH to GitHub: not verified"
fi

echo ""

# ============================================================
# AI Coding Agents
# ============================================================
echo -e "${YELLOW}AI Coding Agents${NC}"
echo "────────────────────────────────────"

# Claude Code
if command -v claude &> /dev/null; then
    check_pass "Claude Code: installed"
else
    check_warn "Claude Code: not installed (npm i -g @anthropic-ai/claude-code)"
fi

# GitHub Copilot CLI
if gh extension list 2>/dev/null | grep -q "copilot"; then
    check_pass "GitHub Copilot CLI: installed"
else
    check_warn "GitHub Copilot CLI: not installed (gh extension install github/gh-copilot)"
fi

# Aider
if command -v aider &> /dev/null; then
    check_pass "Aider: installed"
elif [[ -f ~/.local/bin/aider ]]; then
    check_pass "Aider: installed (~/.local/bin)"
else
    check_warn "Aider: not installed (pip install aider-chat)"
fi

# Ollama
if command -v ollama &> /dev/null; then
    check_pass "Ollama: installed"
else
    check_warn "Ollama: not installed (optional)"
fi

echo ""

# ============================================================
# Configuration Files
# ============================================================
echo -e "${YELLOW}Configuration${NC}"
echo "────────────────────────────────────"

# bashrc.d
if [[ -d ~/.bashrc.d ]]; then
    check_pass "~/.bashrc.d: exists"
else
    check_warn "~/.bashrc.d: not found"
fi

# AI agents env
if [[ -f ~/.config/ai-agents/env ]]; then
    check_pass "API keys file: ~/.config/ai-agents/env exists"
else
    check_warn "API keys file: not found"
fi

# Projects directory
if [[ -d ~/projects ]]; then
    check_pass "Projects dir: ~/projects exists"
else
    check_warn "Projects dir: ~/projects not found"
fi

echo ""

# ============================================================
# Summary
# ============================================================
echo "════════════════════════════════════"
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${YELLOW}$WARNED warnings${NC}, ${RED}$FAILED failed${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    if [[ $WARNED -eq 0 ]]; then
        echo -e "${GREEN}All checks passed! Your environment is fully configured.${NC}"
    else
        echo -e "${YELLOW}Most checks passed. Review warnings above for optional improvements.${NC}"
    fi
    exit 0
else
    echo -e "${RED}Some required components are missing. Review failures above.${NC}"
    exit 1
fi
