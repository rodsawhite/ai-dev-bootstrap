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
  "theme": "dark"
}
EOF
    print_success "Created Claude Code config template"
fi

# ============================================================
# Gemini CLI (Google)
# ============================================================
print_status "Installing Gemini CLI..."

if command -v node &> /dev/null; then
    if command -v gemini &> /dev/null; then
        print_success "Gemini CLI already installed: $(gemini --version 2>/dev/null || echo 'installed')"
    else
        npm install -g @google/gemini-cli 2>/dev/null || {
            print_warning "Gemini CLI installation failed via npm"
            print_status "You can try installing later with: npm install -g @google/gemini-cli"
        }

        if command -v gemini &> /dev/null; then
            print_success "Gemini CLI installed"
        fi
    fi
else
    print_warning "Node.js not available, skipping Gemini CLI"
    print_status "After installing Node.js, run: npm install -g @google/gemini-cli"
fi

# Create Gemini config directory
mkdir -p ~/.config/gemini
chmod 700 ~/.config/gemini

# ============================================================
# OpenCode (Open source AI coding agent)
# ============================================================
print_status "Installing OpenCode..."

if command -v node &> /dev/null; then
    if command -v opencode &> /dev/null; then
        print_success "OpenCode already installed: $(opencode --version 2>/dev/null || echo 'installed')"
    else
        npm install -g opencode-ai 2>/dev/null || {
            print_warning "OpenCode installation failed via npm"
            print_status "You can try installing later with: npm install -g opencode-ai"
            print_status "Or via curl: curl -fsSL https://opencode.ai/install | bash"
        }

        if command -v opencode &> /dev/null; then
            print_success "OpenCode installed"
        fi
    fi
else
    print_warning "Node.js not available, skipping OpenCode"
    print_status "After installing Node.js, run: npm install -g opencode-ai"
fi

# Create OpenCode config directory
mkdir -p ~/.config/opencode
chmod 700 ~/.config/opencode

# ============================================================
# Codex CLI (OpenAI)
# ============================================================
print_status "Installing Codex CLI..."

if command -v node &> /dev/null; then
    if command -v codex &> /dev/null; then
        print_success "Codex CLI already installed: $(codex --version 2>/dev/null || echo 'installed')"
    else
        npm install -g @openai/codex 2>/dev/null || {
            print_warning "Codex CLI installation failed via npm"
            print_status "You can try installing later with: npm install -g @openai/codex"
        }

        if command -v codex &> /dev/null; then
            print_success "Codex CLI installed"
        fi
    fi
else
    print_warning "Node.js not available, skipping Codex CLI"
    print_status "After installing Node.js, run: npm install -g @openai/codex"
fi

# Create Codex config directory
mkdir -p ~/.config/codex
chmod 700 ~/.config/codex

# Prompt user about ChatGPT account auth option
echo ""
print_status "Codex CLI authentication options:"
echo "  Option 1 (ChatGPT plan): run 'codex' and select 'Sign in with ChatGPT'"
echo "             Supports Plus, Pro, Team, Edu and Enterprise plans"
echo "  Option 2 (API key):      set OPENAI_API_KEY in ~/.config/ai-agents/env"
echo ""

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
      "title": "Claude Sonnet",
      "provider": "anthropic",
      "model": "claude-sonnet",
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
# OpenAI Python library (soft dependency for Aider/OpenCode)
# ============================================================
print_status "Installing OpenAI Python library..."
# Note: Codex CLI (npm) is the primary OpenAI terminal agent.
# This installs the openai pip package used by Aider and OpenCode.

if command -v python &> /dev/null || command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
    command -v python &> /dev/null || PYTHON_CMD="python3"

    if ! $PYTHON_CMD -c "import openai" 2>/dev/null; then
        $PYTHON_CMD -m pip install --user openai 2>/dev/null || true
        print_success "OpenAI Python library installed"
    else
        print_status "OpenAI Python library already installed"
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

# Shell aliases are provided via config/.bashrc.d/20-ai-agents.sh,
# which setup-user-env.sh copies to ~/.bashrc.d/ on first run.
# No action needed here.

print_success "AI agent shell integration configured (via ~/.bashrc.d/20-ai-agents.sh)"

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
echo "  GEMINI_API_KEY     - For Gemini CLI (or GOOGLE_API_KEY)"
echo "  OPENAI_API_KEY     - For Codex CLI (API key mode), Aider with GPT models, OpenCode"
echo ""
echo "GitHub Copilot uses your gh CLI authentication."
echo "OpenCode can use /connect command in TUI for OpenCode Zen auth."
echo ""

# ============================================================
# Summary
# ============================================================
print_success "AI Coding Agents installation complete!"
echo ""
echo "Installed agents:"
command -v claude &> /dev/null && echo "  ✓ Claude Code" || echo "  ○ Claude Code (needs Node.js)"
command -v gemini &> /dev/null && echo "  ✓ Gemini CLI" || echo "  ○ Gemini CLI (needs Node.js)"
command -v opencode &> /dev/null && echo "  ✓ OpenCode" || echo "  ○ OpenCode (needs Node.js)"
command -v codex &> /dev/null && echo "  ✓ Codex CLI" || echo "  ○ Codex CLI (needs Node.js)"
gh extension list 2>/dev/null | grep -q "copilot" && echo "  ✓ GitHub Copilot CLI" || echo "  ○ GitHub Copilot CLI (needs gh auth)"
command -v aider &> /dev/null && echo "  ✓ Aider" || echo "  ○ Aider (needs Python)"
command -v ollama &> /dev/null && echo "  ✓ Ollama" || echo "  ○ Ollama (optional)"
echo ""
echo "Run 'ai-help' for usage information"
