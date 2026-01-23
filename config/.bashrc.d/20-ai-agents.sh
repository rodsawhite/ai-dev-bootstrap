# AI Coding Agents Configuration
# Aliases and functions for AI development tools

# ────────────────────────────────────
# Claude Code
# ────────────────────────────────────
alias cc='claude'
alias claude-chat='claude'

# ────────────────────────────────────
# Gemini CLI (Google)
# ────────────────────────────────────
alias gg='gemini'
alias gemini-chat='gemini'

# ────────────────────────────────────
# GitHub Copilot CLI
# ────────────────────────────────────
alias copilot='gh copilot'
alias suggest='gh copilot suggest'
alias explain='gh copilot explain'

# Quick command suggestion
ghcs() {
    gh copilot suggest "$*"
}

# Quick explanation
ghce() {
    gh copilot explain "$*"
}

# ────────────────────────────────────
# Aider
# ────────────────────────────────────
alias ai='aider'
alias aider-gpt4='aider --model gpt-4'
alias aider-claude='aider --model claude-3-opus-20240229'
alias aider-sonnet='aider --model claude-sonnet-4-20250514'
alias aider-gemini='aider --model gemini/gemini-1.5-pro-latest'

# ────────────────────────────────────
# Ollama (Local LLM)
# ────────────────────────────────────
alias ollama-run='ollama run'
alias ollama-list='ollama list'

# Quick chat with local model
chat() {
    local model="${1:-llama2}"
    ollama run "$model"
}

# ────────────────────────────────────
# AI Development Helpers
# ────────────────────────────────────

# Show available AI tools and status
ai-status() {
    echo "AI Coding Agents Status"
    echo "═══════════════════════════════════"
    echo ""

    # Claude Code
    if command -v claude &> /dev/null; then
        echo "✓ Claude Code: installed"
        if [[ -n "$ANTHROPIC_API_KEY" ]]; then
            echo "  API Key: configured"
        else
            echo "  API Key: NOT SET"
        fi
    else
        echo "○ Claude Code: not installed"
    fi
    echo ""

    # Gemini CLI
    if command -v gemini &> /dev/null; then
        echo "✓ Gemini CLI: installed"
        if [[ -n "$GEMINI_API_KEY" ]] || [[ -n "$GOOGLE_API_KEY" ]]; then
            echo "  API Key: configured"
        else
            echo "  API Key: NOT SET"
        fi
    else
        echo "○ Gemini CLI: not installed"
    fi
    echo ""

    # GitHub Copilot
    if gh extension list 2>/dev/null | grep -q "copilot"; then
        echo "✓ GitHub Copilot CLI: installed"
    else
        echo "○ GitHub Copilot CLI: not installed"
    fi
    echo ""

    # Aider
    if command -v aider &> /dev/null; then
        echo "✓ Aider: installed"
        if [[ -n "$OPENAI_API_KEY" ]]; then
            echo "  OpenAI Key: configured"
        else
            echo "  OpenAI Key: NOT SET"
        fi
        if [[ -n "$ANTHROPIC_API_KEY" ]]; then
            echo "  Anthropic Key: configured"
        fi
    else
        echo "○ Aider: not installed"
    fi
    echo ""

    # Ollama
    if command -v ollama &> /dev/null; then
        echo "✓ Ollama: installed"
        if pgrep -x "ollama" > /dev/null; then
            echo "  Status: running"
        else
            echo "  Status: not running"
        fi
    else
        echo "○ Ollama: not installed"
    fi
    echo ""
}

# Quick help for AI tools
ai-help() {
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                  AI Coding Agents Help                        ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Available Commands:"
    echo "───────────────────────────────────"
    echo ""
    echo "  Claude Code:"
    echo "    claude / cc     Start Claude Code session"
    echo ""
    echo "  Gemini CLI:"
    echo "    gemini / gg     Start Gemini CLI session"
    echo ""
    echo "  GitHub Copilot:"
    echo "    suggest <task>  Get command suggestion"
    echo "    explain <cmd>   Explain a command"
    echo "    gh copilot      Full Copilot CLI"
    echo ""
    echo "  Aider:"
    echo "    aider / ai      Start Aider session"
    echo "    aider <files>   Start with specific files"
    echo "    aider-sonnet    Use Claude Sonnet model"
    echo "    aider-gemini    Use Gemini Pro model"
    echo "    aider-gpt4      Use GPT-4 model"
    echo ""
    echo "  Ollama:"
    echo "    ollama run <model>  Run a local model"
    echo "    chat [model]        Quick chat (default: llama2)"
    echo ""
    echo "  Utilities:"
    echo "    ai-status       Check AI tools status"
    echo "    ai-help         Show this help"
    echo ""
    echo "API Keys Location: ~/.config/ai-agents/env"
    echo ""
}

# Start a new project with AI assistance
ai-project() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: ai-project <project-name>"
        return 1
    fi

    mkdir -p ~/projects/"$name"
    cd ~/projects/"$name"

    # Initialize git
    git init

    # Create basic structure
    mkdir -p src tests docs

    # Create README
    cat > README.md << EOF
# $name

## Description

TODO: Add project description

## Setup

\`\`\`bash
# TODO: Add setup instructions
\`\`\`

## Usage

\`\`\`bash
# TODO: Add usage examples
\`\`\`
EOF

    echo "Created project: ~/projects/$name"
    echo ""
    echo "Next steps:"
    echo "  cd ~/projects/$name"
    echo "  claude  # or aider, or your preferred AI tool"
}
