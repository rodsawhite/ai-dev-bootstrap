#Requires -Version 5.1
<#
.SYNOPSIS
    Configure WSL integration settings.

.DESCRIPTION
    Sets up WSL memory limits, creates Windows-side symlinks, and configures
    integration between Windows and WSL environments.
#>

$ErrorActionPreference = "Stop"

function Write-Status { param($Message) Write-Host "[*] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[!] $Message" -ForegroundColor Yellow }

# Configure .wslconfig for resource limits
Write-Status "Configuring WSL resource limits..."

$wslConfigPath = "$env:USERPROFILE\.wslconfig"
$totalRAM = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)

# Allocate 50-75% of RAM to WSL, minimum 4GB, maximum 16GB for typical use
$wslMemory = [math]::Min([math]::Max([math]::Floor($totalRAM * 0.5), 4), 16)
$wslSwap = [math]::Min($wslMemory, 8)
$wslProcessors = [math]::Min((Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors, 8)

$wslConfig = @"
[wsl2]
memory=${wslMemory}GB
swap=${wslSwap}GB
processors=$wslProcessors

# Reclaim unused memory
autoMemoryReclaim=gradual

# Enable nested virtualization (useful for Docker)
nestedVirtualization=true

# Limit disk size growth
sparseVhd=true

[experimental]
# Automatic disk space reclaim
autoMemoryReclaim=dropcache
"@

if (Test-Path $wslConfigPath) {
    Write-Warning "Existing .wslconfig found. Backing up..."
    Copy-Item $wslConfigPath "$wslConfigPath.backup"
}

$wslConfig | Set-Content $wslConfigPath -Encoding UTF8
Write-Success "WSL configured with ${wslMemory}GB RAM, ${wslSwap}GB swap, $wslProcessors processors"

# Get WSL user info
$wslUser = wsl -e whoami 2>$null
if (-not $wslUser) {
    Write-Warning "Could not determine WSL user. Skipping symlink creation."
    exit 0
}
$wslUser = $wslUser.Trim()

# Create Windows-side symlink to WSL projects
Write-Status "Creating Windows symlink to WSL projects..."

$windowsProjectsLink = "$env:USERPROFILE\wsl-projects"
$wslProjectsPath = "\\wsl$\Ubuntu\home\$wslUser\projects"

# Create projects directory in WSL first
wsl -e mkdir -p "/home/$wslUser/projects"

if (Test-Path $windowsProjectsLink) {
    $item = Get-Item $windowsProjectsLink -Force
    if ($item.LinkType -eq "SymbolicLink") {
        Write-Success "Symlink already exists: $windowsProjectsLink"
    } else {
        Write-Warning "$windowsProjectsLink exists but is not a symlink"
    }
} else {
    try {
        # Need admin for symlinks on older Windows
        New-Item -ItemType SymbolicLink -Path $windowsProjectsLink -Target $wslProjectsPath -Force | Out-Null
        Write-Success "Created symlink: $windowsProjectsLink -> $wslProjectsPath"
    } catch {
        Write-Warning "Could not create symlink (may require admin rights): $_"
        Write-Status "You can access WSL files at: $wslProjectsPath"
    }
}

# Configure Windows Terminal settings for better WSL experience (if installed)
Write-Status "Checking Windows Terminal..."

$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $wtSettingsPath) {
    Write-Success "Windows Terminal detected"
    Write-Status "Windows Terminal will use Ubuntu as a profile automatically"
} else {
    Write-Status "Windows Terminal not found (optional)"
    Write-Status "Consider installing Windows Terminal for a better WSL experience:"
    Write-Status "  winget install Microsoft.WindowsTerminal"
}

# Create a convenience script to launch WSL with Docker
Write-Status "Creating convenience scripts..."

$scriptsDir = "$env:USERPROFILE\bin"
if (-not (Test-Path $scriptsDir)) {
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
}

# WSL launcher script
$wslLauncherContent = @'
@echo off
wsl -d Ubuntu %*
'@
$wslLauncherContent | Set-Content "$scriptsDir\dev.cmd"
Write-Success "Created dev.cmd launcher in $scriptsDir"

# Add scripts dir to PATH if not already
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$scriptsDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$scriptsDir", "User")
    Write-Success "Added $scriptsDir to user PATH"
    Write-Warning "Restart your terminal to use the 'dev' command"
}

# Remind about WSL restart for config changes
Write-Host ""
Write-Warning "WSL configuration updated. To apply changes, run:"
Write-Host "  wsl --shutdown" -ForegroundColor Yellow
Write-Host "  wsl" -ForegroundColor Yellow
Write-Host ""

Write-Success "WSL integration configuration complete!"
exit 0
