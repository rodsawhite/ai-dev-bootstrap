#!/bin/bash
#
# Development tools installation script
# Installs build tools, languages, and CLI utilities
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

# Install core build tools
print_status "Installing core build tools..."

sudo apt-get update -qq
sudo apt-get install -y -qq \
    build-essential \
    git \
    curl \
    wget \
    jq \
    unzip \
    zip \
    htop \
    tree \
    vim \
    tmux \
    make \
    cmake \
    pkg-config \
    libssl-dev \
    libffi-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    liblzma-dev

print_success "Core build tools installed"

# Install modern CLI utilities
print_status "Installing modern CLI utilities..."

# ripgrep (rg) - faster grep
if ! command -v rg &> /dev/null; then
    sudo apt-get install -y -qq ripgrep || {
        print_status "Installing ripgrep from GitHub..."
        RG_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
        curl -LO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep_${RG_VERSION#v}_amd64.deb" 2>/dev/null
        sudo dpkg -i ripgrep_*.deb
        rm -f ripgrep_*.deb
    }
    print_success "ripgrep installed"
else
    print_status "ripgrep already installed"
fi

# fd-find (fd) - faster find
if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
    sudo apt-get install -y -qq fd-find || {
        print_status "Installing fd from GitHub..."
        FD_VERSION=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
        curl -LO "https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd_${FD_VERSION#v}_amd64.deb" 2>/dev/null
        sudo dpkg -i fd_*.deb
        rm -f fd_*.deb
    }
    # Create fd symlink if fdfind exists
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
    fi
    print_success "fd installed"
else
    print_status "fd already installed"
fi

# fzf - fuzzy finder
if ! command -v fzf &> /dev/null; then
    print_status "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 2>/dev/null || true
    ~/.fzf/install --key-bindings --completion --no-update-rc --no-bash --no-zsh --no-fish
    print_success "fzf installed"
else
    print_status "fzf already installed"
fi

# bat - better cat
if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
    sudo apt-get install -y -qq bat || {
        print_status "Installing bat from GitHub..."
        BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
        curl -LO "https://github.com/sharkdp/bat/releases/download/${BAT_VERSION}/bat_${BAT_VERSION#v}_amd64.deb" 2>/dev/null
        sudo dpkg -i bat_*.deb
        rm -f bat_*.deb
    }
    # Create bat symlink if batcat exists
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        sudo ln -sf "$(which batcat)" /usr/local/bin/bat
    fi
    print_success "bat installed"
else
    print_status "bat already installed"
fi

# eza - modern ls replacement (formerly exa)
if ! command -v eza &> /dev/null; then
    print_status "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null || true
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update -qq
    sudo apt-get install -y -qq eza || print_warning "eza installation failed (optional)"
fi

# Node.js via nvm
print_status "Setting up Node.js via nvm..."

export NVM_DIR="$HOME/.nvm"

if [[ ! -d "$NVM_DIR" ]]; then
    print_status "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Load nvm for current session
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    print_success "nvm installed"
else
    print_status "nvm already installed"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install Node.js LTS
if command -v nvm &> /dev/null; then
    if ! command -v node &> /dev/null; then
        print_status "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'
        print_success "Node.js installed: $(node --version)"
    else
        print_status "Node.js already installed: $(node --version)"
    fi

    # Install global npm packages
    print_status "Installing global npm packages..."
    npm install -g npm@latest 2>/dev/null || true
    npm install -g yarn pnpm typescript ts-node 2>/dev/null || true
    print_success "Global npm packages installed"
else
    print_warning "nvm not available in current session"
    print_status "Restart your shell and run: nvm install --lts"
fi

# Python via pyenv
print_status "Setting up Python via pyenv..."

export PYENV_ROOT="$HOME/.pyenv"

if [[ ! -d "$PYENV_ROOT" ]]; then
    print_status "Installing pyenv..."
    curl https://pyenv.run | bash

    # Add pyenv to path for current session
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    print_success "pyenv installed"
else
    print_status "pyenv already installed"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
fi

# Add pyenv to bashrc if not present
if ! grep -q "PYENV_ROOT" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true
EOF
fi

# Install Python
if command -v pyenv &> /dev/null; then
    PYTHON_VERSION="3.12.1"

    if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
        print_status "Installing Python $PYTHON_VERSION (this may take a while)..."
        pyenv install "$PYTHON_VERSION" || {
            print_warning "Python $PYTHON_VERSION installation failed, trying 3.11"
            PYTHON_VERSION="3.11.7"
            pyenv install "$PYTHON_VERSION" || print_warning "Python installation failed"
        }
    fi

    if pyenv versions | grep -q "$PYTHON_VERSION"; then
        pyenv global "$PYTHON_VERSION"
        print_success "Python installed: $(python --version 2>&1)"

        # Upgrade pip
        pip install --upgrade pip setuptools wheel 2>/dev/null || true
        print_success "pip upgraded"
    fi
else
    print_warning "pyenv not available in current session"
    print_status "Restart your shell and run: pyenv install 3.12.1"
fi

# Rust via rustup
print_status "Setting up Rust via rustup..."

if ! command -v rustc &> /dev/null; then
    print_status "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

    # Add Rust to path for current session
    source "$HOME/.cargo/env" 2>/dev/null || true

    print_success "Rust installed: $(rustc --version 2>/dev/null || echo 'restart shell to verify')"
else
    print_status "Rust already installed: $(rustc --version)"
fi

# Add Rust to bashrc if not present
if ! grep -q "cargo/env" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Rust
. "$HOME/.cargo/env" 2>/dev/null || true
EOF
fi

# Go installation
print_status "Setting up Go..."

GO_VERSION="1.22.0"

if ! command -v go &> /dev/null; then
    print_status "Installing Go $GO_VERSION..."

    curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" 2>/dev/null
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm -f "go${GO_VERSION}.linux-amd64.tar.gz"

    print_success "Go installed"
else
    print_status "Go already installed: $(go version)"
fi

# Add Go to bashrc if not present
if ! grep -q "/usr/local/go/bin" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Go
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
EOF
fi

# Summary
print_success "Development tools installation complete!"
echo ""
echo "Installed tools:"
echo "  - Build tools: gcc, make, cmake, etc."
echo "  - CLI utilities: ripgrep, fd, fzf, bat, eza"
echo "  - Node.js: via nvm (LTS)"
echo "  - Python: via pyenv (3.12.x)"
echo "  - Rust: via rustup"
echo "  - Go: $GO_VERSION"
echo ""
echo "Restart your shell or run: source ~/.bashrc"
