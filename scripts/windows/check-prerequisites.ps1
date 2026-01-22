#Requires -Version 5.1
<#
.SYNOPSIS
    Check Windows prerequisites for AI development environment.

.DESCRIPTION
    Validates that the Windows system meets requirements for WSL2 and Docker Desktop:
    - Windows version (Build 19041+)
    - Virtualization enabled
    - Hyper-V capability
#>

$ErrorActionPreference = "Stop"

function Write-Status { param($Message) Write-Host "[*] $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[+] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Failure { param($Message) Write-Host "[-] $Message" -ForegroundColor Red }

$allPassed = $true

Write-Status "Checking Windows prerequisites..."

# Check Windows Version
Write-Status "Checking Windows version..."
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$buildNumber = [int](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber

if ($buildNumber -ge 19041) {
    Write-Success "Windows build $buildNumber meets requirements (19041+)"
} else {
    Write-Failure "Windows build $buildNumber is too old. WSL2 requires build 19041 or later."
    Write-Failure "Please update Windows to continue."
    $allPassed = $false
}

# Check Windows Edition
$edition = (Get-WindowsEdition -Online).Edition
Write-Status "Windows Edition: $edition"

if ($edition -match "Home|Pro|Enterprise|Education") {
    Write-Success "Windows edition '$edition' supports WSL2"
} else {
    Write-Warning "Windows edition '$edition' may have limited WSL2 support"
}

# Check Virtualization
Write-Status "Checking virtualization support..."

# Check if virtualization is enabled in BIOS
$vmInfo = Get-CimInstance -ClassName Win32_ComputerSystem
if ($vmInfo.HypervisorPresent) {
    Write-Success "Hypervisor is present and enabled"
} else {
    # Check CPU virtualization capability
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $vmxSupport = $cpuInfo.VirtualizationFirmwareEnabled

    if ($vmxSupport -eq $true) {
        Write-Success "CPU virtualization is enabled"
    } elseif ($vmxSupport -eq $false) {
        Write-Failure "CPU virtualization is disabled in BIOS/UEFI"
        Write-Failure "Please enable VT-x (Intel) or AMD-V (AMD) in your BIOS settings"
        $allPassed = $false
    } else {
        Write-Warning "Could not determine virtualization status"
        Write-Warning "If WSL2 installation fails, check BIOS virtualization settings"
    }
}

# Check Hyper-V capability
Write-Status "Checking Hyper-V capability..."

$hyperVFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
if ($hyperVFeature) {
    if ($hyperVFeature.State -eq "Enabled") {
        Write-Success "Hyper-V is enabled"
    } else {
        Write-Status "Hyper-V is available but not enabled (will be enabled during WSL setup)"
    }
} else {
    # On Windows Home, Hyper-V isn't available but WSL2 can still work
    if ($edition -match "Home") {
        Write-Status "Hyper-V not available on Windows Home (WSL2 will use alternative virtualization)"
    } else {
        Write-Warning "Hyper-V feature not found"
    }
}

# Check Virtual Machine Platform
Write-Status "Checking Virtual Machine Platform..."
$vmpFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
if ($vmpFeature -and $vmpFeature.State -eq "Enabled") {
    Write-Success "Virtual Machine Platform is enabled"
} else {
    Write-Status "Virtual Machine Platform will be enabled during WSL setup"
}

# Check WSL feature
Write-Status "Checking WSL feature..."
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
if ($wslFeature -and $wslFeature.State -eq "Enabled") {
    Write-Success "WSL feature is already enabled"
} else {
    Write-Status "WSL feature will be enabled during setup"
}

# Check existing WSL installation
Write-Status "Checking existing WSL installation..."
$wslVersion = $null
try {
    $wslVersion = wsl --version 2>$null
    if ($wslVersion) {
        Write-Success "WSL is installed"
        $wslVersion -split "`n" | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }
} catch {
    Write-Status "WSL is not yet installed"
}

# Check for existing Ubuntu
try {
    $distros = wsl --list --quiet 2>$null
    if ($distros -match "Ubuntu") {
        Write-Success "Ubuntu distribution is already installed"
    } else {
        Write-Status "Ubuntu will be installed during setup"
    }
} catch {
    Write-Status "No WSL distributions detected"
}

# Check available disk space
Write-Status "Checking disk space..."
$systemDrive = Get-PSDrive -Name C
$freeSpaceGB = [math]::Round($systemDrive.Free / 1GB, 2)

if ($freeSpaceGB -ge 20) {
    Write-Success "Sufficient disk space available: ${freeSpaceGB}GB free"
} elseif ($freeSpaceGB -ge 10) {
    Write-Warning "Low disk space: ${freeSpaceGB}GB free (20GB+ recommended)"
} else {
    Write-Failure "Insufficient disk space: ${freeSpaceGB}GB free (minimum 10GB required)"
    $allPassed = $false
}

# Check RAM
Write-Status "Checking system memory..."
$totalRAM = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)

if ($totalRAM -ge 16) {
    Write-Success "System RAM: ${totalRAM}GB (excellent)"
} elseif ($totalRAM -ge 8) {
    Write-Success "System RAM: ${totalRAM}GB (good)"
} elseif ($totalRAM -ge 4) {
    Write-Warning "System RAM: ${totalRAM}GB (minimum - may experience slowdowns)"
} else {
    Write-Failure "System RAM: ${totalRAM}GB (insufficient - 4GB minimum required)"
    $allPassed = $false
}

# Check internet connectivity
Write-Status "Checking internet connectivity..."
try {
    $response = Invoke-WebRequest -Uri "https://github.com" -Method Head -TimeoutSec 10 -UseBasicParsing
    Write-Success "Internet connectivity confirmed"
} catch {
    Write-Failure "Cannot reach github.com - internet connection required"
    $allPassed = $false
}

# Summary
Write-Host ""
if ($allPassed) {
    Write-Success "All prerequisites passed!"
    exit 0
} else {
    Write-Failure "Some prerequisites failed. Please resolve the issues above."
    exit 1
}
