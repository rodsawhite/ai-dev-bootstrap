#!/bin/bash
#
# Main WSL bootstrap script
# Orchestrates the installation of all components in the correct order
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() { echo -e "${CYAN}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="$BOOTSTRAP_DIR/config"

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         WSL AI Development Environment Setup                  ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_status "Bootstrap directory: $BOOTSTRAP_DIR"
print_status "Config directory: $CONFIG_DIR"
print_status "User: $USER"
print_status "Home: $HOME"

# Update system first
print_status "Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
print_success "System packages updated"

# Phase 1: User Environment Setup
echo ""
echo -e "${YELLOW}=== Phase 1: User Environment Setup ===${NC}"
if [[ -x "$SCRIPT_DIR/setup-user-env.sh" ]]; then
    bash "$SCRIPT_DIR/setup-user-env.sh" "$CONFIG_DIR"
else
    print_error "setup-user-env.sh not found or not executable"
    exit 1
fi

# Phase 2: GitHub Tools
echo ""
echo -e "${YELLOW}=== Phase 2: GitHub Tools Setup ===${NC}"
if [[ -x "$SCRIPT_DIR/install-github.sh" ]]; then
    bash "$SCRIPT_DIR/install-github.sh"
else
    print_error "install-github.sh not found or not executable"
    exit 1
fi

# Phase 3: Docker CLI
echo ""
echo -e "${YELLOW}=== Phase 3: Docker CLI Setup ===${NC}"
if [[ -x "$SCRIPT_DIR/install-docker.sh" ]]; then
    bash "$SCRIPT_DIR/install-docker.sh"
else
    print_error "install-docker.sh not found or not executable"
    exit 1
fi

# Phase 4: Development Tools
echo ""
echo -e "${YELLOW}=== Phase 4: Development Tools ===${NC}"
if [[ -x "$SCRIPT_DIR/install-dev-tools.sh" ]]; then
    bash "$SCRIPT_DIR/install-dev-tools.sh"
else
    print_error "install-dev-tools.sh not found or not executable"
    exit 1
fi

# Phase 5: AI Coding Agents
echo ""
echo -e "${YELLOW}=== Phase 5: AI Coding Agents ===${NC}"
if [[ -x "$SCRIPT_DIR/install-ai-agents.sh" ]]; then
    bash "$SCRIPT_DIR/install-ai-agents.sh"
else
    print_error "install-ai-agents.sh not found or not executable"
    exit 1
fi

# Phase 6: Verification
echo ""
echo -e "${YELLOW}=== Phase 6: Installation Verification ===${NC}"
if [[ -x "$SCRIPT_DIR/verify-install.sh" ]]; then
    bash "$SCRIPT_DIR/verify-install.sh"
else
    print_warning "verify-install.sh not found, skipping verification"
fi

# Cleanup
print_status "Cleaning up..."
sudo apt-get autoremove -y -qq
sudo apt-get clean -qq
print_success "Cleanup complete"

# Final message
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║             WSL Bootstrap Complete!                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
print_success "Your AI development environment is ready!"
echo ""
echo "Quick start:"
echo "  cd ~/projects        # Navigate to projects"
echo "  claude               # Start Claude Code"
echo "  gh copilot           # GitHub Copilot CLI"
echo "  aider                # Start Aider"
echo ""
echo "To reload your shell configuration:"
echo "  source ~/.bashrc"
echo ""
