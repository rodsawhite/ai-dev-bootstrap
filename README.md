# Windows AI Coding Agent Bootstrap

Bootstrap a Windows system for AI-assisted development using WSL2, Ubuntu, Docker Desktop, and multiple AI coding agents.

## Features

- **Multi-agent support**: Claude Code, GitHub Copilot CLI, Aider, and Ollama
- **Modern CLI tools**: ripgrep, fd, fzf, bat, eza
- **Language runtimes**: Node.js (nvm), Python (pyenv), Rust (rustup), Go
- **Docker integration**: Docker Desktop with WSL2 backend
- **GitHub integration**: gh CLI with SSH key setup
- **User isolation**: Per-user Docker Compose projects
- **Idempotent**: Safe to run multiple times

## Prerequisites

- Windows 10 (Build 19041+) or Windows 11
- Administrator access
- Virtualization enabled in BIOS (VT-x/AMD-V)
- Internet connection
- At least 20GB free disk space
- 8GB+ RAM recommended

## Quick Start

1. **Clone or download this repository**

2. **Open PowerShell as Administrator**

3. **Run the bootstrap script**:
   ```powershell
   .\bootstrap.ps1
   ```

4. **Follow the prompts** to:
   - Install/configure WSL2 and Ubuntu
   - Install Docker Desktop
   - Set up GitHub authentication
   - Configure AI coding agents

5. **Start using AI agents**:
   ```bash
   wsl
   cd ~/projects
   claude  # or aider, gh copilot, etc.
   ```

## Installation Options

### Full Installation
```powershell
.\bootstrap.ps1
```

### Skip WSL (already installed)
```powershell
.\bootstrap.ps1 -SkipWSL
```

### Skip Docker (already installed)
```powershell
.\bootstrap.ps1 -SkipDocker
```

### Skip Both (WSL-only bootstrap)
```powershell
.\bootstrap.ps1 -SkipWSL -SkipDocker
```

## What Gets Installed

### Windows Side
- WSL2 with Ubuntu
- Docker Desktop with WSL2 integration
- Convenience scripts in `%USERPROFILE%\bin`
- Symlink to WSL projects: `%USERPROFILE%\wsl-projects`

### WSL/Ubuntu Side

#### System Tools
- `build-essential`, `git`, `curl`, `wget`, `jq`
- `vim`, `tmux`, `htop`, `tree`

#### Modern CLI Tools
- `ripgrep` (rg) - Fast grep replacement
- `fd` - Fast find replacement
- `fzf` - Fuzzy finder
- `bat` - Cat with syntax highlighting
- `eza` - Modern ls replacement

#### Languages & Runtimes
- **Node.js** via nvm (LTS version)
- **Python** via pyenv (3.12.x)
- **Rust** via rustup
- **Go** 1.22.x

#### AI Coding Agents
- **Claude Code** - Anthropic's CLI coding assistant
- **GitHub Copilot CLI** - Command suggestions and explanations
- **Aider** - AI pair programming in terminal
- **Ollama** - Local LLM runner (optional)

## Directory Structure

After installation, your WSL environment will have:

```
~/
├── projects/           # Your coding projects
├── tools/              # Development tools
├── docker-projects/    # Docker Compose projects
├── .config/
│   ├── ai-agents/
│   │   └── env         # API keys (edit this!)
│   ├── claude/         # Claude Code config
│   └── aider/          # Aider config
├── .bashrc.d/          # Modular bash config
│   ├── 00-path.sh
│   ├── 10-aliases.sh
│   └── 20-ai-agents.sh
└── .ssh/
    ├── id_ed25519      # SSH key
    └── config          # SSH config
```

## Configuration

### API Keys

Edit `~/.config/ai-agents/env` to add your API keys:

```bash
# Anthropic API Key (for Claude Code)
export ANTHROPIC_API_KEY="sk-ant-..."

# OpenAI API Key (for Aider with GPT models)
export OPENAI_API_KEY="sk-..."
```

### GitHub Authentication

If not completed during setup:

```bash
# Browser-based auth (recommended)
gh auth login --web

# Add SSH key to GitHub
gh ssh-key add ~/.ssh/id_ed25519.pub
```

### Git Configuration

```bash
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

## Usage

### AI Agents

```bash
# Claude Code
claude                  # Start interactive session
cc                      # Alias for claude

# GitHub Copilot
gh copilot suggest "create a python script to process CSV"
gh copilot explain "git rebase -i HEAD~5"
suggest "deploy docker container"  # Alias

# Aider
aider                   # Start with current directory
aider main.py utils.py  # Work on specific files
aider-sonnet           # Use Claude Sonnet
aider-gpt4             # Use GPT-4

# Ollama (local models)
ollama run llama2       # Run Llama 2
chat codellama          # Quick chat function
```

### Helpful Commands

```bash
ai-help     # Show AI tools help
ai-status   # Check AI tools status and API keys
ai-project myapp  # Create new project directory
```

### Common Aliases

```bash
# Navigation
projects    # cd ~/projects
..          # cd ..

# Git
gs          # git status
ga          # git add
gc          # git commit
gp          # git push

# Docker
d           # docker
dc          # docker compose
dps         # docker ps

# Files
ll          # ls -la (or eza)
```

## Troubleshooting

### WSL Issues

**WSL not installing:**
```powershell
# Enable required features manually
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# Restart computer, then run:
wsl --install -d Ubuntu
```

**Ubuntu not using WSL2:**
```powershell
wsl --set-version Ubuntu 2
```

### Docker Issues

**Docker not accessible in WSL:**
1. Open Docker Desktop
2. Go to Settings > Resources > WSL Integration
3. Enable integration for Ubuntu
4. Click "Apply & Restart"

**Docker daemon not running:**
- Ensure Docker Desktop is running on Windows
- Check if Docker Desktop is set to start automatically

### GitHub Authentication

**gh auth login fails:**
```bash
# Try with HTTPS token instead
gh auth login --with-token < ~/token.txt
```

**SSH key not working:**
```bash
# Test SSH connection
ssh -T git@github.com

# Check SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### Node.js/Python Not Found

After installation, you may need to reload your shell:
```bash
source ~/.bashrc
```

Or restart your terminal session.

## Re-running Bootstrap

The bootstrap script is idempotent - you can run it again to:
- Install missing components
- Update existing tools
- Re-apply configurations

```powershell
.\bootstrap.ps1 -SkipWSL -SkipDocker  # Just re-run WSL setup
```

Or within WSL:
```bash
~/.ai-dev-bootstrap/scripts/wsl/bootstrap.sh
```

## Verification

Run the verification script to check your installation:

```bash
~/.ai-dev-bootstrap/scripts/wsl/verify-install.sh
```

This will show:
- Installed tools and versions
- Authentication status
- Configuration status
- Any issues that need attention

## Uninstallation

### Remove AI Agents
```bash
npm uninstall -g @anthropic-ai/claude-code
gh extension remove github/gh-copilot
pip uninstall aider-chat
```

### Remove WSL Ubuntu
```powershell
wsl --unregister Ubuntu
```

### Remove Docker Desktop
- Uninstall via Windows Settings > Apps

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - See LICENSE file for details.
