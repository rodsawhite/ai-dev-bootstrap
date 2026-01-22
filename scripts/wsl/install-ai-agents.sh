#!/bin/bash
#
# AI Coding Agents installation script
# Installs Claude Code, GitHub Copilot CLI, Aider, and other AI tools
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${CYAN}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

# Source environment to get nvm and pyenv
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true

source "$HOME/.cargo/env" 2>/dev/null || true

print_status "Installing AI Coding Agents..."

# ============================================================
# Claude Code
# ============================================================
print_status "Installing Claude Code..."

if command -v node &> /dev/null; then
    if command -v claude &> /dev/null; then
        print_success "Claude Code already installed: $(claude --version 2>/dev/null || echo 'installed')"
    else
        npm install -g @anthropic-ai/claude-code 2>/dev/null || {
            print_warning "Claude Code installation failed via npm"
            print_status "You can try installing later with: npm install -g @anthropic-ai/claude-code"
        }

        if command -v claude &> /dev/null; then
            print_success "Claude Code installed"
        fi
    fi
else
    print_warning "Node.js not available, skipping Claude Code"
    print_status "After installing Node.js, run: npm install -g @anthropic-ai/claude-code"
fi

# Create Claude Code config directory
mkdir -p ~/.config/claude
chmod 700 ~/.config/claude

# Create config template if not exists
if [[ ! -f ~/.config/claude/config.json ]]; then
    cat > ~/.config/claude/config.json << 'EOF'
{
  "theme": "dark",
  "model": "claude-sonnet-4-20250514"
}
EOF
    print_success "Created Claude Code config template"
fi

# ============================================================
# GitHub Copilot CLI
# ============================================================
print_status "Installing GitHub Copilot CLI..."

if command -v gh &> /dev/null; then
    if gh extension list 2>/dev/null | grep -q "copilot"; then
        print_success "GitHub Copilot CLI already installed"
    else
        gh extension install github/gh-copilot 2>/dev/null || {
            print_warning "GitHub Copilot CLI installation failed"
            print_status "You may need to authenticate first: gh auth login"
        }

        if gh extension list 2>/dev/null | grep -q "copilot"; then
            print_success "GitHub Copilot CLI installed"
        fi
    fi
else
    print_warning "GitHub CLI not available, skipping Copilot CLI"
fi

# ============================================================
# Aider
# ============================================================
print_status "Installing Aider..."

if command -v python &> /dev/null || command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
    command -v python &> /dev/null || PYTHON_CMD="python3"

    if command -v aider &> /dev/null; then
        print_success "Aider already installed: $(aider --version 2>/dev/null || echo 'installed')"
    else
        # Install aider with pip
        $PYTHON_CMD -m pip install --user aider-chat 2>/dev/null || {
            # Try with pipx if available
            if command -v pipx &> /dev/null; then
                pipx install aider-chat 2>/dev/null
            else
                print_warning "Aider installation failed"
            fi
        }

        # Check installation
        if command -v aider &> /dev/null || [[ -f ~/.local/bin/aider ]]; then
            print_success "Aider installed"
        else
            print_warning "Aider may need PATH update"
            print_status "Try: pip install --user aider-chat"
        fi
    fi
else
    print_warning "Python not available, skipping Aider"
fi

# Create Aider config directory and template
mkdir -p ~/.config/aider

if [[ ! -f ~/.aider.conf.yml ]]; then
    cat > ~/.aider.conf.yml << 'EOF'
# Aider Configuration
# See: https://aider.chat/docs/config.html

# Model settings (uncomment and configure as needed)
# model: gpt-4
# openai-api-key: your-key-here

# Editor settings
# auto-commits: true
# dirty-commits: true

# Display settings
# dark-mode: true
# pretty: true

# Git settings
# auto-commits: true
# attribute-author: true
# attribute-committer: true
EOF
    print_success "Created Aider config template"
fi

# ============================================================
# Continue (VS Code extension CLI companion)
# ============================================================
print_status "Setting up Continue configuration..."

mkdir -p ~/.continue

if [[ ! -f ~/.continue/config.json ]]; then
    cat > ~/.continue/config.json << 'EOF'
{
  "models": [
    {
      "title": "Claude 3.5 Sonnet",
      "provider": "anthropic",
      "model": "claude-sonnet-4-20250514",
      "apiKey": ""
    }
  ],
  "tabAutocompleteModel": {
    "title": "Starcoder",
    "provider": "ollama",
    "model": "starcoder2:3b"
  },
  "customCommands": [],
  "contextProviders": [
    { "name": "code" },
    { "name": "docs" },
    { "name": "diff" },
    { "name": "terminal" },
    { "name": "problems" },
    { "name": "folder" },
    { "name": "codebase" }
  ],
  "slashCommands": [
    { "name": "edit", "description": "Edit selected code" },
    { "name": "comment", "description": "Add comments to code" },
    { "name": "share", "description": "Export conversation" },
    { "name": "cmd", "description": "Generate shell command" }
  ]
}
EOF
    print_success "Created Continue config template"
fi

# ============================================================
# OpenAI CLI (optional, for GPT models)
# ============================================================
print_status "Installing OpenAI CLI..."

if command -v python &> /dev/null || command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
    command -v python &> /dev/null || PYTHON_CMD="python3"

    if ! $PYTHON_CMD -c "import openai" 2>/dev/null; then
        $PYTHON_CMD -m pip install --user openai 2>/dev/null || true
        print_success "OpenAI Python package installed"
    else
        print_status "OpenAI Python package already installed"
    fi
fi

# ============================================================
# Ollama (local LLM runner)
# ============================================================
print_status "Installing Ollama..."

if command -v ollama &> /dev/null; then
    print_success "Ollama already installed: $(ollama --version 2>/dev/null || echo 'installed')"
else
    curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null || {
        print_warning "Ollama installation failed (requires systemd, may not work in WSL)"
        print_status "You can install Ollama on Windows instead and access it from WSL"
    }

    if command -v ollama &> /dev/null; then
        print_success "Ollama installed"
    fi
fi

# ============================================================
# Shell Integration / Aliases
# ============================================================
print_status "Setting up AI agent shell integration..."

# Create AI agents bashrc module
cat > ~/.bashrc.d/20-ai-agents.sh << 'EOF'
# AI Coding Agents Configuration

# Claude Code aliases
alias cc='claude'
alias claude-chat='claude'

# GitHub Copilot aliases
alias copilot='gh copilot'
alias suggest='gh copilot suggest'
alias explain='gh copilot explain'

# Aider aliases
alias ai='aider'
alias aider-gpt4='aider --model gpt-4'
alias aider-claude='aider --model claude-3-opus-20240229'

# Quick AI help
ai-help() {
    echo "Available AI Coding Agents:"
    echo ""
    echo "  claude / cc       - Claude Code (Anthropic)"
    echo "  gh copilot        - GitHub Copilot CLI"
    echo "  aider / ai        - Aider (multi-model)"
    echo "  ollama            - Local LLM runner"
    echo ""
    echo "Common commands:"
    echo "  claude            - Start Claude Code session"
    echo "  suggest <task>    - Get Copilot command suggestion"
    echo "  explain <cmd>     - Explain a command with Copilot"
    echo "  aider <files>     - Start Aider with files"
    echo ""
    echo "API Keys:"
    echo "  Edit ~/.config/ai-agents/env to set API keys"
    echo ""
}
EOF

print_success "AI agent shell integration configured"

# ============================================================
# API Key Reminder
# ============================================================
echo ""
print_warning "API Keys Required"
echo ""
echo "Most AI agents require API keys. Edit the following file:"
echo "  ~/.config/ai-agents/env"
echo ""
echo "Required keys:"
echo "  ANTHROPIC_API_KEY  - For Claude Code"
echo "  OPENAI_API_KEY     - For Aider with GPT models"
echo ""
echo "GitHub Copilot uses your gh CLI authentication."
echo ""

# ============================================================
# Summary
# ============================================================
print_success "AI Coding Agents installation complete!"
echo ""
echo "Installed agents:"
command -v claude &> /dev/null && echo "  ✓ Claude Code" || echo "  ○ Claude Code (needs Node.js)"
gh extension list 2>/dev/null | grep -q "copilot" && echo "  ✓ GitHub Copilot CLI" || echo "  ○ GitHub Copilot CLI (needs gh auth)"
command -v aider &> /dev/null && echo "  ✓ Aider" || echo "  ○ Aider (needs Python)"
command -v ollama &> /dev/null && echo "  ✓ Ollama" || echo "  ○ Ollama (optional)"
echo ""
echo "Run 'ai-help' for usage information"
