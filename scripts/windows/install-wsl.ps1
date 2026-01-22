#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Install and configure WSL2 with Ubuntu.

.DESCRIPTION
    Enables WSL2 features, sets WSL2 as default, and installs Ubuntu distribution.

.PARAMETER Force
    Force reinstallation even if already installed
#>

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Status { param($Message) Write-Host "[*] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Failure { param($Message) Write-Host "[-] $Message" -ForegroundColor Red }

$rebootRequired = $false

# Check if WSL is already properly installed
$wslInstalled = $false
try {
    $wslVersion = wsl --version 2>$null
    if ($wslVersion -and -not $Force) {
        Write-Success "WSL is already installed"
        $wslInstalled = $true
    }
} catch {}

if (-not $wslInstalled) {
    Write-Status "Installing WSL2..."

    # Enable WSL feature
    Write-Status "Enabling Windows Subsystem for Linux..."
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    if ($wslFeature.State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        $rebootRequired = $true
        Write-Success "WSL feature enabled"
    } else {
        Write-Success "WSL feature already enabled"
    }

    # Enable Virtual Machine Platform
    Write-Status "Enabling Virtual Machine Platform..."
    $vmpFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    if ($vmpFeature.State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        $rebootRequired = $true
        Write-Success "Virtual Machine Platform enabled"
    } else {
        Write-Success "Virtual Machine Platform already enabled"
    }

    # If reboot is required, notify and exit
    if ($rebootRequired) {
        Write-Warning "A system restart is required to complete WSL installation."
        Write-Warning "Please restart your computer and run this script again."

        $restart = Read-Host "Would you like to restart now? (y/N)"
        if ($restart -eq "y" -or $restart -eq "Y") {
            Write-Status "Restarting in 10 seconds... Press Ctrl+C to cancel"
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        }
        exit 0
    }

    # Update WSL
    Write-Status "Updating WSL..."
    wsl --update

    # Set WSL2 as default
    Write-Status "Setting WSL2 as default version..."
    wsl --set-default-version 2
    Write-Success "WSL2 set as default"
}

# Check for Ubuntu installation
Write-Status "Checking Ubuntu installation..."
$ubuntuInstalled = $false
try {
    $distros = wsl --list --quiet 2>$null
    if ($distros -match "Ubuntu") {
        $ubuntuInstalled = $true
        Write-Success "Ubuntu is already installed"
    }
} catch {}

if (-not $ubuntuInstalled -or $Force) {
    Write-Status "Installing Ubuntu..."

    # Use wsl --install for Ubuntu (simplest method)
    # This handles kernel updates and distribution installation
    wsl --install -d Ubuntu --no-launch

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Ubuntu installation initiated"
    } else {
        # Try alternative installation via winget
        Write-Warning "Standard installation failed, trying winget..."
        winget install --id Canonical.Ubuntu.2204 --accept-source-agreements --accept-package-agreements
    }

    Write-Status "Launching Ubuntu for initial setup..."
    Write-Warning "Please complete the Ubuntu initial setup (create username/password)"
    Write-Warning "After setup completes, type 'exit' to continue with bootstrap"

    # Launch Ubuntu for initial setup
    Start-Process "ubuntu.exe" -Wait

    Write-Success "Ubuntu initial setup complete"
}

# Verify installation
Write-Status "Verifying WSL2 installation..."
$wslList = wsl --list --verbose 2>$null
if ($wslList) {
    Write-Host $wslList

    # Check if Ubuntu is running WSL2
    if ($wslList -match "Ubuntu.*2") {
        Write-Success "Ubuntu is running on WSL2"
    } elseif ($wslList -match "Ubuntu.*1") {
        Write-Warning "Ubuntu is running on WSL1, converting to WSL2..."
        wsl --set-version Ubuntu 2
        Write-Success "Converted Ubuntu to WSL2"
    }
} else {
    Write-Failure "Could not verify WSL installation"
    exit 1
}

# Set Ubuntu as default distribution
Write-Status "Setting Ubuntu as default distribution..."
wsl --set-default Ubuntu
Write-Success "Ubuntu set as default WSL distribution"

Write-Success "WSL2 installation complete!"
exit 0
