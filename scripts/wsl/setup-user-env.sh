#!/bin/bash
#
# User environment setup script
# Creates directory structure, symlinks, and configures shell
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

CONFIG_DIR="${1:-$(dirname "$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")")/config}"

print_status "Setting up user environment..."

# Validate CONFIG_DIR exists and contains expected structure
if [[ ! -d "$CONFIG_DIR" ]]; then
    print_error "CONFIG_DIR not found: $CONFIG_DIR"
    print_error "Pass the correct config path as the first argument, e.g.:"
    print_error "  bash setup-user-env.sh /path/to/repo/config"
    exit 1
fi

if [[ ! -d "$CONFIG_DIR/.bashrc.d" ]]; then
    print_error "Expected directory missing: $CONFIG_DIR/.bashrc.d"
    print_error "The config directory appears incomplete. Re-clone the repository and try again."
    exit 1
fi

print_success "Config directory validated: $CONFIG_DIR"

# Create directory structure
print_status "Creating directory structure..."

mkdir -p ~/projects
mkdir -p ~/tools
mkdir -p ~/.config/ai-agents
mkdir -p ~/.local/bin
mkdir -p ~/.ssh
mkdir -p ~/.ssh/sockets

# Set proper permissions
chmod 700 ~/.ssh
chmod 700 ~/.ssh/sockets
chmod 700 ~/.config/ai-agents

print_success "Created directories: ~/projects, ~/tools, ~/.config/ai-agents, ~/.local/bin"

# Get Windows username for cross-environment symlinks
print_status "Setting up Windows integration..."

WIN_USER=""
if command -v cmd.exe &> /dev/null; then
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
fi

if [[ -n "$WIN_USER" ]]; then
    WIN_PROFILE="/mnt/c/Users/$WIN_USER"

    if [[ -d "$WIN_PROFILE" ]]; then
        # Create symlink to Windows Documents (optional, non-critical)
        if [[ -d "$WIN_PROFILE/Documents" ]] && [[ ! -L ~/win-documents ]]; then
            ln -sf "$WIN_PROFILE/Documents" ~/win-documents
            print_success "Created symlink: ~/win-documents -> $WIN_PROFILE/Documents"
        fi

        # Create symlink to Windows Downloads
        if [[ -d "$WIN_PROFILE/Downloads" ]] && [[ ! -L ~/win-downloads ]]; then
            ln -sf "$WIN_PROFILE/Downloads" ~/win-downloads
            print_success "Created symlink: ~/win-downloads -> $WIN_PROFILE/Downloads"
        fi

        print_success "Windows user detected: $WIN_USER"
    else
        print_warning "Windows profile not found at $WIN_PROFILE"
    fi
else
    print_warning "Could not detect Windows username (running in pure Linux?)"
fi

# Set up Docker Compose project isolation
print_status "Configuring Docker Compose project isolation..."

COMPOSE_PROJECT="${USER}-ai-dev"
mkdir -p ~/docker-projects/"$COMPOSE_PROJECT"

print_success "Created Docker project directory: ~/docker-projects/$COMPOSE_PROJECT"

# Install modular bashrc configuration
print_status "Installing shell configuration..."

BASHRC_D="$HOME/.bashrc.d"
mkdir -p "$BASHRC_D"

# Copy bashrc modules if they exist (skip files that already exist to preserve user customisations)
if [[ -d "$CONFIG_DIR/.bashrc.d" ]]; then
    for src_file in "$CONFIG_DIR/.bashrc.d/"*.sh; do
        [[ -f "$src_file" ]] || continue
        dest_file="$BASHRC_D/$(basename "$src_file")"
        if [[ ! -f "$dest_file" ]]; then
            cp "$src_file" "$dest_file"
            print_success "Installed bashrc module: $(basename "$src_file")"
        else
            print_status "Skipping existing bashrc module: $(basename "$src_file")"
        fi
    done
fi

# Add bashrc.d sourcing to .bashrc if not already present
if ! grep -q "bashrc.d" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Source modular bashrc configurations
if [[ -d ~/.bashrc.d ]]; then
    for file in ~/.bashrc.d/*.sh; do
        [[ -r "$file" ]] && source "$file"
    done
fi
EOF
    print_success "Added bashrc.d sourcing to ~/.bashrc"
else
    print_status "bashrc.d already configured in ~/.bashrc"
fi

# Add common environment variables to .bashrc
if ! grep -q "COMPOSE_PROJECT_NAME" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << EOF

# Docker Compose project isolation
export COMPOSE_PROJECT_NAME="$COMPOSE_PROJECT"

# Local bin directory
export PATH="\$HOME/.local/bin:\$PATH"

# Editor preferences
export EDITOR=vim
export VISUAL=vim
EOF
    print_success "Added environment variables to ~/.bashrc"
fi

# Create .bash_profile to source .bashrc for login shells (only if absent)
if [[ ! -f ~/.bash_profile ]]; then
    cat > ~/.bash_profile << 'EOF'
# Source .bashrc for login shells
if [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi
EOF
    print_success "Created ~/.bash_profile"
else
    print_status "~/.bash_profile already exists, skipping"
fi

# Set up SSH config directory with template
print_status "Setting up SSH configuration..."

if [[ -f "$CONFIG_DIR/ssh/config.template" ]]; then
    if [[ ! -f ~/.ssh/config ]]; then
        cp "$CONFIG_DIR/ssh/config.template" ~/.ssh/config
        chmod 600 ~/.ssh/config
        print_success "Installed SSH config template"
    else
        print_status "SSH config already exists, skipping template"
    fi
fi

# Create AI agents config directory structure
print_status "Setting up AI agents configuration..."

mkdir -p ~/.config/claude
mkdir -p ~/.config/gemini
mkdir -p ~/.config/aider
mkdir -p ~/.config/codex
mkdir -p ~/.continue

# Create placeholder for API keys (user must fill in)
if [[ ! -f ~/.config/ai-agents/env ]]; then
    cat > ~/.config/ai-agents/env << 'EOF'
# AI Agent API Keys
# Fill in your API keys below

# Anthropic API Key (for Claude Code)
# export ANTHROPIC_API_KEY="your-key-here"

# Google Gemini API Key (for Gemini CLI)
# export GEMINI_API_KEY="your-key-here"
# export GOOGLE_API_KEY="your-key-here"  # Alternative

# OpenAI API Key (for Codex CLI in API key mode, Aider with GPT models, OpenCode)
# Codex CLI can also authenticate via ChatGPT account (no API key needed).
# Run 'codex' after install and select 'Sign in with ChatGPT'.
# export OPENAI_API_KEY="your-key-here"

# Other API keys as needed
# export GROQ_API_KEY="your-key-here"
# export TOGETHER_API_KEY="your-key-here"
EOF
    chmod 600 ~/.config/ai-agents/env
    print_success "Created API keys template at ~/.config/ai-agents/env"
fi

# Source API keys file in bashrc
if ! grep -q "ai-agents/env" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Source AI agent API keys
if [[ -f ~/.config/ai-agents/env ]]; then
    source ~/.config/ai-agents/env
fi
EOF
    print_success "Added AI agents env sourcing to ~/.bashrc"
fi

# Copy Docker compose template if available (skip if already exists to preserve user modifications)
print_status "Setting up Docker compose template..."

if [[ -f "$CONFIG_DIR/docker/compose-template.yml" ]] && \
   [[ ! -f ~/docker-projects/"$COMPOSE_PROJECT"/docker-compose.yml ]]; then
    cp "$CONFIG_DIR/docker/compose-template.yml" ~/docker-projects/"$COMPOSE_PROJECT"/docker-compose.yml
    print_success "Copied Docker compose template"
elif [[ -f ~/docker-projects/"$COMPOSE_PROJECT"/docker-compose.yml ]]; then
    print_status "docker-compose.yml already exists, skipping (preserving user modifications)"
fi

print_success "User environment setup complete!"
