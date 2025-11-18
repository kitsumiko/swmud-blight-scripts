# SWMud Blight Scripts Installer for Windows (PowerShell)
# This script installs the SWMud Blight Scripts to your Blightmud configuration directory

#Requires -Version 3.0

# Set error action preference
$ErrorActionPreference = "Stop"

# Script directory (where this script is located)
# Go up one level to the repository root
$ScriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Colors for output (using Write-Host with colors)
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Function to find Blightmud config directory
function Find-BlightmudConfig {
    $configDirs = @(
        "$env:APPDATA\blightmud",
        "$env:LOCALAPPDATA\blightmud"
    )
    
    foreach ($dir in $configDirs) {
        if (Test-Path $dir) {
            return $dir
        }
    }
    
    # Default to APPDATA if not found
    $defaultDir = "$env:APPDATA\blightmud"
    Write-Info "Blightmud config directory not found. Will create: $defaultDir"
    return $defaultDir
}

# Function to check if Blightmud is installed
function Test-Blightmud {
    if (Test-Command "blightmud") {
        Write-Success "Blightmud is installed"
        try {
            $version = & blightmud --version 2>&1 | Select-Object -First 1
            if ($version) {
                Write-Info "Blightmud version: $version"
            }
        } catch {
            # Version check failed, but that's okay
        }
        return $true
    } else {
        Write-Warning "Blightmud command not found in PATH"
        Write-Info "This might be okay if Blightmud is installed but not in PATH"
        return $false
    }
}

# Function to backup existing files
function Backup-Existing {
    param([string]$ConfigDir)
    
    $hasExisting = $false
    
    if (Test-Path "$ConfigDir\swmud") {
        $hasExisting = $true
    }
    if (Test-Path "$ConfigDir\000_connect.lua") {
        $hasExisting = $true
    }
    
    if ($hasExisting) {
        Write-Warning "Existing installation found. Creating backup..."
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupDir = "$ConfigDir.backup.$timestamp"
        
        try {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            
            if (Test-Path "$ConfigDir\swmud") {
                Copy-Item -Path "$ConfigDir\swmud" -Destination "$backupDir\swmud" -Recurse -Force
            }
            
            if (Test-Path "$ConfigDir\000_connect.lua") {
                Copy-Item -Path "$ConfigDir\000_connect.lua" -Destination "$backupDir\000_connect.lua" -Force
            }
            
            Write-Success "Backup created at: $backupDir"
        } catch {
            Write-Warning "Failed to create backup: $_"
        }
    }
}

# Function to copy files
function Copy-Files {
    param([string]$ConfigDir)
    
    Write-Info "Installing files to: $ConfigDir"
    
    # Create config directory if it doesn't exist
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    
    # Copy swmud directory
    $swmudSource = Join-Path $ScriptDir "swmud"
    if (Test-Path $swmudSource) {
        Write-Info "Copying swmud directory..."
        $swmudDest = Join-Path $ConfigDir "swmud"
        Copy-Item -Path $swmudSource -Destination $swmudDest -Recurse -Force
        Write-Success "swmud directory copied"
    } else {
        Write-Error "swmud directory not found in $ScriptDir"
        return $false
    }
    
    # Copy 000_connect.lua
    $connectSource = Join-Path $ScriptDir "000_connect.lua"
    if (Test-Path $connectSource) {
        Write-Info "Copying 000_connect.lua..."
        $connectDest = Join-Path $ConfigDir "000_connect.lua"
        Copy-Item -Path $connectSource -Destination $connectDest -Force
        Write-Success "000_connect.lua copied"
    } else {
        Write-Error "000_connect.lua not found in $ScriptDir"
        return $false
    }
    
    # Copy settings.ron if it exists (optional)
    $settingsSource = Join-Path $ScriptDir "settings.ron"
    if (Test-Path $settingsSource) {
        $settingsDest = Join-Path $ConfigDir "settings.ron"
        if (-not (Test-Path $settingsDest)) {
            Write-Info "Copying settings.ron..."
            Copy-Item -Path $settingsSource -Destination $settingsDest -Force
            Write-Success "settings.ron copied"
        } else {
            Write-Info "settings.ron already exists, skipping (to preserve your settings)"
        }
    }
    
    # Create private directory if it doesn't exist
    $privateDir = Join-Path $ConfigDir "private"
    if (-not (Test-Path $privateDir)) {
        Write-Info "Creating private directory..."
        New-Item -ItemType Directory -Path $privateDir -Force | Out-Null
        Write-Success "private directory created"
    }
    
    return $true
}

# Function to verify installation
function Test-Installation {
    param([string]$ConfigDir)
    
    Write-Info "Verifying installation..."
    $errors = 0
    
    # Check for required files
    if (-not (Test-Path "$ConfigDir\000_connect.lua")) {
        Write-Error "000_connect.lua not found"
        $errors++
    }
    
    if (-not (Test-Path "$ConfigDir\swmud")) {
        Write-Error "swmud directory not found"
        $errors++
    }
    
    # Check for required subdirectories
    $requiredDirs = @("core", "utils", "ui", "commands", "parsers", "services", "models", "data")
    foreach ($dir in $requiredDirs) {
        $dirPath = Join-Path $ConfigDir "swmud\$dir"
        if (-not (Test-Path $dirPath)) {
            Write-Error "swmud\$dir directory not found"
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "Installation verified successfully!"
        return $true
    } else {
        Write-Error "Installation verification failed with $errors error(s)"
        return $false
    }
}

# Main installation function
function Main {
    Write-Host ""
    Write-Info "SWMud Blight Scripts Installer"
    Write-Info "=============================="
    Write-Host ""
    
    # Check execution policy (informational)
    $execPolicy = Get-ExecutionPolicy
    if ($execPolicy -eq "Restricted") {
        Write-Warning "Execution policy is Restricted. You may need to run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    }
    Write-Host ""
    
    # Check for Blightmud (non-fatal)
    $blightmudInstalled = Test-Blightmud
    if (-not $blightmudInstalled) {
        Write-Warning "Could not verify Blightmud installation. Continuing anyway..."
    }
    Write-Host ""
    
    # Find config directory
    $configDir = Find-BlightmudConfig
    if (-not $configDir) {
        Write-Error "Could not determine Blightmud config directory"
        exit 1
    }
    Write-Info "Blightmud config directory: $configDir"
    Write-Host ""
    
    # Backup existing installation
    Backup-Existing -ConfigDir $configDir
    Write-Host ""
    
    # Copy files
    try {
        if (-not (Copy-Files -ConfigDir $configDir)) {
            Write-Error "Failed to copy files"
            exit 1
        }
    } catch {
        Write-Error "Error copying files: $_"
        exit 1
    }
    Write-Host ""
    
    # Verify installation
    if (-not (Test-Installation -ConfigDir $configDir)) {
        Write-Error "Installation verification failed"
        exit 1
    }
    Write-Host ""
    
    # Success message
    Write-Success "Installation completed successfully!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "  1. Launch Blightmud: blightmud"
    Write-Host "  2. The scripts will automatically load when you connect to SWMud"
    Write-Host "  3. Use '/reload' in-game to reload scripts after making changes"
    Write-Host ""
    Write-Info "Config directory: $configDir"
    Write-Info "For character-specific scripts, create: $configDir\private\020_character.lua"
    Write-Host ""
}

# Run main function
try {
    Main
} catch {
    Write-Error "Installation failed: $_"
    exit 1
}

