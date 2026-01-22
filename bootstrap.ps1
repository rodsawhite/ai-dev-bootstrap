#Requires -Version 5.1
<#
.SYNOPSIS
    Bootstrap script for Windows AI Coding Agent development environment.

.DESCRIPTION
    This script sets up a complete AI coding agent development environment on Windows
    using WSL2, Ubuntu, and Docker Desktop. It supports multiple AI coding agents
    including Claude Code, GitHub Copilot CLI, and Aider.

.PARAMETER SkipWSL
    Skip WSL installation (use if already installed)

.PARAMETER SkipDocker
    Skip Docker Desktop installation (use if already installed)

.PARAMETER Force
    Force reinstallation of components

.EXAMPLE
    .\bootstrap.ps1
    Run full bootstrap process

.EXAMPLE
    .\bootstrap.ps1 -SkipWSL -SkipDocker
    Only run WSL bootstrap scripts (WSL and Docker already installed)
#>

[CmdletBinding()]
param(
    [switch]$SkipWSL,
    [switch]$SkipDocker,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptRoot = $PSScriptRoot

# Colors for output
function Write-Status { param($Message) Write-Host "[*] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[-] $Message" -ForegroundColor Red }

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-Elevation {
    if (-not (Test-Administrator)) {
        Write-Warning "This script requires administrator privileges for WSL/Docker installation."
        Write-Status "Requesting elevation..."

        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        if ($SkipWSL) { $arguments += " -SkipWSL" }
        if ($SkipDocker) { $arguments += " -SkipDocker" }
        if ($Force) { $arguments += " -Force" }

        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
        exit
    }
}

# Banner
Write-Host @"

 ╔═══════════════════════════════════════════════════════════════╗
 ║         Windows AI Coding Agent Bootstrap                     ║
 ║         WSL2 + Ubuntu + Docker + AI Tools                     ║
 ╚═══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Magenta

# Check if we need admin rights
$needsAdmin = (-not $SkipWSL) -or (-not $SkipDocker)
if ($needsAdmin) {
    Request-Elevation
}

Write-Status "Starting bootstrap process..."

# Phase 1: Check Prerequisites
Write-Host "`n=== Phase 1: Checking Prerequisites ===" -ForegroundColor Yellow
& "$ScriptRoot\scripts\windows\check-prerequisites.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Prerequisites check failed. Please resolve the issues above."
    exit 1
}

# Phase 2: Install WSL2
if (-not $SkipWSL) {
    Write-Host "`n=== Phase 2: Installing WSL2 ===" -ForegroundColor Yellow
    & "$ScriptRoot\scripts\windows\install-wsl.ps1" -Force:$Force
    if ($LASTEXITCODE -ne 0) {
        Write-Error "WSL installation failed."
        exit 1
    }
} else {
    Write-Status "Skipping WSL installation (--SkipWSL specified)"
}

# Phase 3: Install Docker Desktop
if (-not $SkipDocker) {
    Write-Host "`n=== Phase 3: Installing Docker Desktop ===" -ForegroundColor Yellow
    & "$ScriptRoot\scripts\windows\install-docker-desktop.ps1" -Force:$Force
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker Desktop installation failed."
        exit 1
    }
} else {
    Write-Status "Skipping Docker Desktop installation (--SkipDocker specified)"
}

# Phase 4: Configure WSL Integration
Write-Host "`n=== Phase 4: Configuring WSL Integration ===" -ForegroundColor Yellow
& "$ScriptRoot\scripts\windows\configure-wsl-integration.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "WSL integration configuration had warnings. Continuing..."
}

# Phase 5: Copy scripts to WSL and execute bootstrap
Write-Host "`n=== Phase 5: Running WSL Bootstrap ===" -ForegroundColor Yellow

# Determine WSL home directory
$wslUser = wsl -e whoami 2>$null
if (-not $wslUser) {
    Write-Error "Could not determine WSL user. Is Ubuntu installed?"
    exit 1
}
$wslUser = $wslUser.Trim()
$wslHome = "/home/$wslUser"

Write-Status "WSL user: $wslUser"
Write-Status "WSL home: $wslHome"

# Copy bootstrap files to WSL
$wslBootstrapDir = "$wslHome/.ai-dev-bootstrap"
Write-Status "Copying bootstrap files to WSL..."

wsl -e mkdir -p "$wslBootstrapDir/scripts/wsl"
wsl -e mkdir -p "$wslBootstrapDir/config/.bashrc.d"
wsl -e mkdir -p "$wslBootstrapDir/config/docker"
wsl -e mkdir -p "$wslBootstrapDir/config/ssh"

# Convert Windows paths to WSL paths and copy
$windowsScriptPath = (Get-Item "$ScriptRoot\scripts\wsl").FullName
$wslScriptPath = wsl -e wslpath -a "$windowsScriptPath"
wsl -e cp -r "$wslScriptPath/." "$wslBootstrapDir/scripts/wsl/"

$windowsConfigPath = (Get-Item "$ScriptRoot\config").FullName
$wslConfigPath = wsl -e wslpath -a "$windowsConfigPath"
wsl -e cp -r "$wslConfigPath/." "$wslBootstrapDir/config/"

# Make scripts executable
wsl -e chmod +x "$wslBootstrapDir/scripts/wsl/"*.sh

# Execute main bootstrap script in WSL
Write-Status "Executing WSL bootstrap script..."
wsl -e bash -c "cd '$wslBootstrapDir' && ./scripts/wsl/bootstrap.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Error "WSL bootstrap failed."
    exit 1
}

# Final summary
Write-Host @"

 ╔═══════════════════════════════════════════════════════════════╗
 ║                    Bootstrap Complete!                        ║
 ╚═══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Success "Your AI development environment is ready!"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open a new WSL terminal: wsl"
Write-Host "  2. Navigate to your projects: cd ~/projects"
Write-Host "  3. Start coding with AI agents:"
Write-Host "     - claude          # Claude Code"
Write-Host "     - gh copilot      # GitHub Copilot CLI"
Write-Host "     - aider           # Aider"
Write-Host ""
Write-Host "Windows project symlink: $env:USERPROFILE\wsl-projects" -ForegroundColor Yellow
Write-Host ""
