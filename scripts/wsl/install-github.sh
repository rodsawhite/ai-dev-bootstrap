#!/bin/bash
#
# GitHub tools installation script
# Installs gh CLI and configures SSH keys
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

# Install GitHub CLI
print_status "Installing GitHub CLI..."

if command -v gh &> /dev/null; then
    print_success "GitHub CLI already installed: $(gh --version | head -1)"
else
    # Add GitHub CLI repository
    print_status "Adding GitHub CLI repository..."

    # Install dependencies
    sudo apt-get install -y -qq curl gnupg

    # Download and install GPG key
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

    # Add repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    # Install gh
    sudo apt-get update -qq
    sudo apt-get install -y -qq gh

    print_success "GitHub CLI installed: $(gh --version | head -1)"
fi

# SSH Key Setup
print_status "Setting up SSH keys..."

SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_KEY_COMMENT="${USER}@$(hostname)-wsl"

if [[ -f "$SSH_KEY" ]]; then
    print_success "SSH key already exists: $SSH_KEY"
else
    print_status "Generating new ED25519 SSH key..."

    ssh-keygen -t ed25519 -C "$SSH_KEY_COMMENT" -f "$SSH_KEY" -N ""

    print_success "Generated SSH key: $SSH_KEY"
    print_status "Public key fingerprint:"
    ssh-keygen -lf "$SSH_KEY.pub"
fi

# Configure SSH for GitHub
print_status "Configuring SSH for GitHub..."

SSH_CONFIG="$HOME/.ssh/config"

# Ensure config file exists with correct permissions
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

# Add GitHub configuration if not present
if ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << 'EOF'

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddKeysToAgent yes
EOF
    print_success "Added GitHub SSH configuration"
else
    print_status "GitHub SSH configuration already exists"
fi

# Start ssh-agent and add key
print_status "Setting up SSH agent..."

# Add ssh-agent startup to bashrc if not present
if ! grep -q "ssh-agent" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# SSH Agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
EOF
    print_success "Added SSH agent configuration to .bashrc"
fi

# Start agent for current session
eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add "$SSH_KEY" 2>/dev/null || true

# GitHub CLI Authentication
print_status "Checking GitHub CLI authentication..."

if gh auth status &>/dev/null; then
    print_success "Already authenticated with GitHub CLI"
    gh auth status
else
    print_warning "GitHub CLI not authenticated"
    echo ""
    echo "To authenticate with GitHub, you have two options:"
    echo ""
    echo "Option 1 - Browser authentication (recommended):"
    echo "  gh auth login --web --git-protocol https"
    echo ""
    echo "Option 2 - Token authentication:"
    echo "  1. Go to: https://github.com/settings/tokens"
    echo "  2. Generate a new token with 'repo', 'read:org', 'workflow' scopes"
    echo "  3. Run: gh auth login --with-token < your-token-file"
    echo ""

    # Ask if user wants to authenticate now
    read -p "Would you like to authenticate with GitHub now? (y/N) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Starting GitHub authentication..."

        # Try web authentication
        gh auth login --web --git-protocol https

        if gh auth status &>/dev/null; then
            print_success "GitHub authentication successful!"

            # Configure git to use gh for credentials
            gh auth setup-git
            print_success "Git configured to use GitHub CLI for authentication"
        else
            print_error "GitHub authentication failed"
        fi
    else
        print_warning "Skipping GitHub authentication (run 'gh auth login' later)"
    fi
fi

# Add SSH key to GitHub
print_status "Checking SSH key on GitHub..."

if gh auth status &>/dev/null; then
    # Check if key already exists on GitHub
    KEY_FINGERPRINT=$(ssh-keygen -lf "$SSH_KEY.pub" | awk '{print $2}')
    KEY_TITLE="$(hostname)-wsl-$(date +%Y%m%d)"

    if gh ssh-key list 2>/dev/null | grep -q "$KEY_FINGERPRINT"; then
        print_success "SSH key already registered with GitHub"
    else
        print_status "Adding SSH key to GitHub..."

        read -p "Would you like to add your SSH key to GitHub? (y/N) " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if gh ssh-key add "$SSH_KEY.pub" --title "$KEY_TITLE"; then
                print_success "SSH key added to GitHub as '$KEY_TITLE'"
            else
                print_error "Failed to add SSH key to GitHub"
                echo "You can add it manually at: https://github.com/settings/keys"
            fi
        else
            print_warning "Skipping SSH key registration"
            echo "Add your key manually at: https://github.com/settings/keys"
            echo "Public key:"
            cat "$SSH_KEY.pub"
        fi
    fi
else
    print_warning "Skipping SSH key registration (not authenticated with gh)"
    echo "After authenticating, add your key with:"
    echo "  gh ssh-key add ~/.ssh/id_ed25519.pub --title \"$(hostname)-wsl\""
fi

# Test SSH connection to GitHub
print_status "Testing SSH connection to GitHub..."

if ssh -T git@github.com -o StrictHostKeyChecking=accept-new 2>&1 | grep -q "successfully authenticated"; then
    print_success "SSH connection to GitHub verified!"
else
    print_warning "SSH connection test inconclusive"
    print_status "You may need to add your SSH key to GitHub first"
fi

# Configure Git defaults
print_status "Configuring Git defaults..."

# Set default branch name
git config --global init.defaultBranch main 2>/dev/null || true

# Set pull strategy
git config --global pull.rebase false 2>/dev/null || true

# Enable credential helper
git config --global credential.helper store 2>/dev/null || true

# Check if user info is configured
if [[ -z "$(git config --global user.email 2>/dev/null)" ]]; then
    print_warning "Git user email not configured"

    if gh auth status &>/dev/null; then
        # Try to get email from GitHub
        GH_EMAIL=$(gh api user/emails 2>/dev/null | grep -o '"email": "[^"]*"' | head -1 | cut -d'"' -f4)
        GH_NAME=$(gh api user 2>/dev/null | grep -o '"name": "[^"]*"' | head -1 | cut -d'"' -f4)

        if [[ -n "$GH_EMAIL" ]]; then
            git config --global user.email "$GH_EMAIL"
            print_success "Set git email from GitHub: $GH_EMAIL"
        fi

        if [[ -n "$GH_NAME" ]]; then
            git config --global user.name "$GH_NAME"
            print_success "Set git name from GitHub: $GH_NAME"
        fi
    fi

    if [[ -z "$(git config --global user.email 2>/dev/null)" ]]; then
        echo "Configure your Git identity with:"
        echo "  git config --global user.email 'you@example.com'"
        echo "  git config --global user.name 'Your Name'"
    fi
fi

print_success "GitHub tools setup complete!"
