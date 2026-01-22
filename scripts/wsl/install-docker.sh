#!/bin/bash
#
# Docker CLI installation script
# Installs Docker CLI tools that connect to Docker Desktop on Windows
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

print_status "Setting up Docker CLI..."

# Check if Docker is already accessible (from Docker Desktop WSL integration)
if command -v docker &> /dev/null && docker ps &>/dev/null; then
    print_success "Docker is already accessible via Docker Desktop integration"
    docker --version
    echo ""

    # Just ensure docker-compose is available
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose v1 available: $(docker-compose --version)"
    fi

    if docker compose version &>/dev/null; then
        print_success "Docker Compose v2 available: $(docker compose version)"
    fi

    print_success "Docker setup complete (using Docker Desktop)"
    exit 0
fi

# If Docker Desktop integration isn't working, install Docker CLI manually
print_warning "Docker Desktop integration not detected, installing Docker CLI..."

# Install prerequisites
print_status "Installing prerequisites..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
print_status "Adding Docker repository..."

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker CLI (not the daemon - we'll use Docker Desktop)
print_status "Installing Docker CLI..."
sudo apt-get update -qq
sudo apt-get install -y -qq docker-ce-cli docker-compose-plugin docker-buildx-plugin

print_success "Docker CLI installed"

# Add user to docker group (if it exists)
if getent group docker > /dev/null 2>&1; then
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        print_success "Added $USER to docker group"
        print_warning "You may need to log out and back in for group changes to take effect"
    fi
fi

# Configure Docker to use Docker Desktop socket
print_status "Configuring Docker to use Docker Desktop..."

# Create Docker config directory
mkdir -p ~/.docker

# Docker Desktop exposes its socket at /var/run/docker.sock via WSL integration
# But if that's not working, we might need to configure the host

DOCKER_HOST_CONFIG='
# Docker Desktop WSL2 Integration
# The Docker socket should be available at /var/run/docker.sock
# If not, Docker Desktop WSL integration may need to be enabled

# Uncomment below if Docker Desktop socket is at a different location:
# export DOCKER_HOST="unix:///mnt/wsl/docker-desktop/shared-sockets/guest-services/docker.sock"
'

if ! grep -q "DOCKER_HOST" ~/.bashrc 2>/dev/null; then
    echo "$DOCKER_HOST_CONFIG" >> ~/.bashrc
fi

# Test Docker connection
print_status "Testing Docker connection..."

if docker ps &>/dev/null; then
    print_success "Docker is working!"
    docker --version
else
    print_warning "Docker command failed"
    echo ""
    echo "Docker Desktop may not be running or WSL integration may be disabled."
    echo ""
    echo "To fix this:"
    echo "  1. Open Docker Desktop on Windows"
    echo "  2. Go to Settings > Resources > WSL Integration"
    echo "  3. Enable integration for Ubuntu"
    echo "  4. Click 'Apply & Restart'"
    echo ""
    echo "After that, try running: docker ps"
fi

# Install docker-compose v1 (standalone) as fallback
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing docker-compose standalone..."

    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)

    if [[ -n "$COMPOSE_VERSION" ]]; then
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>/dev/null
        sudo chmod +x /usr/local/bin/docker-compose
        print_success "docker-compose installed: $(docker-compose --version 2>/dev/null || echo 'version check failed')"
    else
        print_warning "Could not determine latest docker-compose version"
    fi
fi

# Verify installations
print_status "Verifying Docker tools..."

echo ""
echo "Docker CLI:"
docker --version 2>/dev/null || echo "  Not available"

echo ""
echo "Docker Compose:"
docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || echo "  Not available"

echo ""
echo "Docker Buildx:"
docker buildx version 2>/dev/null || echo "  Not available"

print_success "Docker CLI setup complete!"
