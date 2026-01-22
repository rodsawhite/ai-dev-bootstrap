#Requires -Version 5.1
<#
.SYNOPSIS
    Install and configure Docker Desktop for Windows.

.DESCRIPTION
    Downloads and installs Docker Desktop with WSL2 backend integration.

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

# Check if Docker Desktop is already installed
$dockerInstalled = $false
$dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"

if ((Test-Path $dockerPath) -and -not $Force) {
    Write-Success "Docker Desktop is already installed"
    $dockerInstalled = $true
}

# Also check if docker command works
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Success "Docker CLI available: $dockerVersion"
        $dockerInstalled = $true
    }
} catch {}

if (-not $dockerInstalled) {
    Write-Status "Installing Docker Desktop..."

    # Try winget first (preferred method)
    $wingetAvailable = $false
    try {
        $wingetVersion = winget --version 2>$null
        if ($wingetVersion) {
            $wingetAvailable = $true
        }
    } catch {}

    if ($wingetAvailable) {
        Write-Status "Installing via winget..."
        winget install --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker Desktop installed via winget"
        } else {
            Write-Warning "Winget installation failed, trying direct download..."
            $wingetAvailable = $false
        }
    }

    if (-not $wingetAvailable) {
        Write-Status "Downloading Docker Desktop installer..."

        $installerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"

        try {
            Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
            Write-Success "Downloaded Docker Desktop installer"
        } catch {
            Write-Failure "Failed to download Docker Desktop: $_"
            exit 1
        }

        Write-Status "Running Docker Desktop installer..."
        Write-Warning "Please follow the installer prompts..."

        # Run installer with WSL2 backend
        Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet", "--accept-license" -Wait

        if (Test-Path $dockerPath) {
            Write-Success "Docker Desktop installed successfully"
        } else {
            Write-Failure "Docker Desktop installation may have failed"
            exit 1
        }

        # Cleanup
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    }
}

# Start Docker Desktop if not running
Write-Status "Checking Docker Desktop status..."
$dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue

if (-not $dockerProcess) {
    Write-Status "Starting Docker Desktop..."

    if (Test-Path $dockerPath) {
        Start-Process $dockerPath

        Write-Status "Waiting for Docker to start (this may take a minute)..."
        $timeout = 120
        $elapsed = 0

        while ($elapsed -lt $timeout) {
            Start-Sleep -Seconds 5
            $elapsed += 5

            try {
                $dockerInfo = docker info 2>$null
                if ($dockerInfo) {
                    Write-Success "Docker is running"
                    break
                }
            } catch {}

            Write-Host "." -NoNewline
        }

        Write-Host ""

        if ($elapsed -ge $timeout) {
            Write-Warning "Docker may still be starting. Please wait for Docker Desktop to fully start."
        }
    } else {
        Write-Warning "Docker Desktop executable not found at expected location"
    }
} else {
    Write-Success "Docker Desktop is already running"
}

# Configure Docker for WSL2 integration
Write-Status "Configuring Docker WSL2 integration..."

$dockerSettingsPath = "$env:APPDATA\Docker\settings.json"

if (Test-Path $dockerSettingsPath) {
    try {
        $settings = Get-Content $dockerSettingsPath -Raw | ConvertFrom-Json

        # Ensure WSL2 backend is enabled
        $settings.wslEngineEnabled = $true

        # Enable WSL integration for all distros (including Ubuntu)
        if (-not $settings.PSObject.Properties["wslIntegrationEnabled"]) {
            $settings | Add-Member -NotePropertyName "wslIntegrationEnabled" -NotePropertyValue $true
        } else {
            $settings.wslIntegrationEnabled = $true
        }

        $settings | ConvertTo-Json -Depth 10 | Set-Content $dockerSettingsPath
        Write-Success "Docker settings updated for WSL2 integration"

        Write-Warning "You may need to restart Docker Desktop for settings to take effect"
    } catch {
        Write-Warning "Could not update Docker settings automatically: $_"
        Write-Warning "Please enable WSL2 integration manually in Docker Desktop settings"
    }
} else {
    Write-Status "Docker settings file not found (Docker may not have started yet)"
    Write-Warning "Please enable WSL2 integration manually in Docker Desktop settings"
}

# Verify Docker works from WSL
Write-Status "Verifying Docker accessibility from WSL..."
try {
    $wslDockerVersion = wsl -e docker --version 2>$null
    if ($wslDockerVersion) {
        Write-Success "Docker is accessible from WSL: $wslDockerVersion"
    } else {
        Write-Warning "Docker not yet accessible from WSL"
        Write-Warning "Please ensure Docker Desktop WSL2 integration is enabled for Ubuntu"
    }
} catch {
    Write-Warning "Could not verify Docker in WSL (this is normal if Docker is still starting)"
}

Write-Success "Docker Desktop setup complete!"
Write-Host ""
Write-Host "Note: If Docker is not accessible from WSL, please:" -ForegroundColor Yellow
Write-Host "  1. Open Docker Desktop" -ForegroundColor Yellow
Write-Host "  2. Go to Settings > Resources > WSL Integration" -ForegroundColor Yellow
Write-Host "  3. Enable integration for Ubuntu" -ForegroundColor Yellow
Write-Host ""

exit 0
