# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a bootstrap repository for setting up Windows systems for AI-assisted development. It installs WSL2, Ubuntu, Docker Desktop, VS Code, and multiple AI coding agents (Claude Code, Gemini CLI, GitHub Copilot CLI, Aider, Ollama).

## Commands

**Test the verification script:**
```bash
bash scripts/wsl/verify-install.sh
```

**Run the full bootstrap (on Windows PowerShell as Admin):**
```powershell
.\bootstrap.ps1
```

**Run only WSL bootstrap (from within WSL):**
```bash
bash scripts/wsl/bootstrap.sh
```

## Architecture

The bootstrap operates in two phases:

### Phase 1: Windows Side (PowerShell)
`bootstrap.ps1` orchestrates Windows-side installation:
1. `scripts/windows/check-prerequisites.ps1` - Validates Windows version, virtualization, disk space
2. `scripts/windows/install-wsl.ps1` - Enables WSL2 features, installs Ubuntu
3. `scripts/windows/install-docker-desktop.ps1` - Installs Docker Desktop via winget or direct download
4. `scripts/windows/install-vscode.ps1` - Installs VS Code with AI/dev extensions
5. `scripts/windows/configure-wsl-integration.ps1` - Sets up .wslconfig, symlinks, resource limits

### Phase 2: WSL Side (Bash)
`scripts/wsl/bootstrap.sh` orchestrates Ubuntu-side setup:
1. `setup-user-env.sh` - Creates ~/projects, ~/.config/ai-agents, installs .bashrc.d modules
2. `install-github.sh` - Installs gh CLI, generates SSH keys, configures git
3. `install-docker.sh` - Installs Docker CLI (connects to Docker Desktop)
4. `install-dev-tools.sh` - Installs nvm/Node.js, pyenv/Python, rustup/Rust, Go, CLI tools
5. `install-ai-agents.sh` - Installs Claude Code, Gemini CLI, Copilot CLI, Aider, Ollama
6. `verify-install.sh` - Validates installation status

### Configuration Files
- `config/.bashrc.d/` - Modular shell config (PATH, aliases, AI agent shortcuts)
- `config/docker/compose-template.yml` - Per-user Docker Compose template
- `config/ssh/config.template` - SSH config for GitHub

## Key Design Principles

1. **Idempotent**: All scripts check for existing installations and skip if present
2. **User isolation**: Per-user Docker Compose projects via COMPOSE_PROJECT_NAME
3. **Modular config**: Shell configuration split into .bashrc.d/*.sh files
4. **Skip flags**: bootstrap.ps1 accepts -SkipWSL, -SkipDocker, -SkipVSCode, -Force

## Script Conventions

- All bash scripts use color-coded output functions: `print_status`, `print_success`, `print_warning`, `print_error`
- PowerShell scripts use: `Write-Status`, `Write-Success`, `Write-Warning`, `Write-Error`
- Scripts source environment setup silently to avoid errors when tools aren't installed yet
- Version detection uses grep/cut patterns that handle edge cases (WSL integration messages, etc.)

## Code Review Workflow

**After completing any code changes**, invoke the `pr-code-reviewer` agent before presenting the work as ready for commit. This ensures:

- Code quality and consistency with project conventions
- Proper commenting where logic isn't self-evident
- README accuracy if user-facing behavior changed
- No security vulnerabilities introduced

**When to trigger review:**
- After implementing new features or scripts
- After refactoring existing code
- After fixing bugs that required code changes
- Before suggesting the user run `git commit`

**Do not trigger review for:**
- Documentation-only changes (markdown files)
- Config file tweaks with no logic changes
- Exploratory/research tasks with no code written

This review step is mandatory before any commit suggestion.
