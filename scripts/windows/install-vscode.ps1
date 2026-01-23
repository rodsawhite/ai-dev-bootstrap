#Requires -Version 5.1
<#
.SYNOPSIS
    Install and configure Visual Studio Code.

.DESCRIPTION
    Downloads and installs VS Code with recommended extensions for AI-assisted development.

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

# Check if VS Code is already installed
$vscodeInstalled = $false
$vscodePath = "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe"
$vscodePathAlt = "${env:ProgramFiles}\Microsoft VS Code\Code.exe"

if ((Test-Path $vscodePath) -or (Test-Path $vscodePathAlt)) {
    if (-not $Force) {
        Write-Success "Visual Studio Code is already installed"
        $vscodeInstalled = $true
    }
}

# Also check if code command works
try {
    $codeVersion = code --version 2>$null
    if ($codeVersion) {
        Write-Success "VS Code CLI available: $($codeVersion[0])"
        $vscodeInstalled = $true
    }
} catch {}

if (-not $vscodeInstalled) {
    Write-Status "Installing Visual Studio Code..."

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
        winget install --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements -e

        if ($LASTEXITCODE -eq 0) {
            Write-Success "VS Code installed via winget"
        } else {
            Write-Warning "Winget installation failed, trying direct download..."
            $wingetAvailable = $false
        }
    }

    if (-not $wingetAvailable) {
        Write-Status "Downloading VS Code installer..."

        $installerUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
        $installerPath = "$env:TEMP\VSCodeSetup.exe"

        try {
            Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
            Write-Success "Downloaded VS Code installer"
        } catch {
            Write-Failure "Failed to download VS Code: $_"
            exit 1
        }

        Write-Status "Running VS Code installer..."

        # Silent install with PATH and context menu options
        $installArgs = @(
            "/VERYSILENT",
            "/NORESTART",
            "/MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
        )

        Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait

        # Cleanup
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue

        Write-Success "VS Code installed"
    }

    # Refresh PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Install recommended extensions
Write-Status "Installing recommended VS Code extensions..."

# Refresh PATH again to ensure code command is available
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$extensions = @(
    # WSL Integration (essential)
    "ms-vscode-remote.remote-wsl",

    # AI Coding Assistants
    "github.copilot",
    "github.copilot-chat",
    "continue.continue",

    # Language Support
    "ms-python.python",
    "ms-python.vscode-pylance",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "rust-lang.rust-analyzer",
    "golang.go",

    # Git Integration
    "eamodio.gitlens",
    "mhutchie.git-graph",

    # Docker
    "ms-azuretools.vscode-docker",

    # General Development
    "editorconfig.editorconfig",
    "streetsidesoftware.code-spell-checker",
    "usernamehw.errorlens"
)

$codeCmd = $null
if (Get-Command code -ErrorAction SilentlyContinue) {
    $codeCmd = "code"
} elseif (Test-Path $vscodePath) {
    $codeCmd = "`"$vscodePath`""
} elseif (Test-Path $vscodePathAlt) {
    $codeCmd = "`"$vscodePathAlt`""
}

if ($codeCmd) {
    foreach ($ext in $extensions) {
        Write-Status "Installing extension: $ext"
        try {
            $result = Invoke-Expression "$codeCmd --install-extension $ext --force 2>&1"
            if ($result -match "successfully installed") {
                Write-Success "  Installed: $ext"
            } elseif ($result -match "already installed") {
                Write-Status "  Already installed: $ext"
            } else {
                Write-Warning "  May have failed: $ext"
            }
        } catch {
            Write-Warning "  Could not install: $ext"
        }
    }
} else {
    Write-Warning "VS Code CLI not found. Extensions will need to be installed manually."
    Write-Status "Recommended extensions:"
    foreach ($ext in $extensions) {
        Write-Host "  - $ext"
    }
}

# Configure VS Code settings for WSL
Write-Status "Configuring VS Code settings..."

$vscodeSettingsDir = "$env:APPDATA\Code\User"
$vscodeSettingsPath = "$vscodeSettingsDir\settings.json"

# Create settings directory if needed
if (-not (Test-Path $vscodeSettingsDir)) {
    New-Item -ItemType Directory -Path $vscodeSettingsDir -Force | Out-Null
}

# Default settings for AI development
$defaultSettings = @{
    # WSL Integration
    "remote.WSL.fileWatcher.polling" = $false

    # Editor settings
    "editor.fontSize" = 14
    "editor.tabSize" = 4
    "editor.formatOnSave" = $true
    "editor.minimap.enabled" = $false
    "editor.wordWrap" = "on"
    "editor.bracketPairColorization.enabled" = $true

    # Terminal
    "terminal.integrated.defaultProfile.windows" = "Ubuntu (WSL)"
    "terminal.integrated.fontSize" = 14

    # Files
    "files.autoSave" = "afterDelay"
    "files.autoSaveDelay" = 1000
    "files.trimTrailingWhitespace" = $true
    "files.insertFinalNewline" = $true

    # Git
    "git.autofetch" = $true
    "git.confirmSync" = $false

    # Copilot
    "github.copilot.enable" = @{
        "*" = $true
        "plaintext" = $false
        "markdown" = $true
    }
}

if (Test-Path $vscodeSettingsPath) {
    Write-Status "Existing settings.json found, merging settings..."
    try {
        $existingSettings = Get-Content $vscodeSettingsPath -Raw | ConvertFrom-Json -AsHashtable
        foreach ($key in $defaultSettings.Keys) {
            if (-not $existingSettings.ContainsKey($key)) {
                $existingSettings[$key] = $defaultSettings[$key]
            }
        }
        $existingSettings | ConvertTo-Json -Depth 10 | Set-Content $vscodeSettingsPath
        Write-Success "Settings merged"
    } catch {
        Write-Warning "Could not merge settings: $_"
    }
} else {
    $defaultSettings | ConvertTo-Json -Depth 10 | Set-Content $vscodeSettingsPath
    Write-Success "Created default settings.json"
}

Write-Success "Visual Studio Code setup complete!"
Write-Host ""
Write-Host "To open a WSL project in VS Code:" -ForegroundColor Yellow
Write-Host "  1. Open WSL terminal: wsl" -ForegroundColor Yellow
Write-Host "  2. Navigate to project: cd ~/projects/myproject" -ForegroundColor Yellow
Write-Host "  3. Open in VS Code: code ." -ForegroundColor Yellow
Write-Host ""

exit 0
