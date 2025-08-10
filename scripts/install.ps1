# dcon Installation Script for Windows
# This script downloads and installs the latest version of dcon

param(
    [string]$Version = "",
    [string]$InstallDir = "$env:USERPROFILE\.local\bin",
    [switch]$Help
)

# Configuration
$Repo = "emadbaqeri/dcon"
$BinaryName = "dcon.exe"

# Colors for output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
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

# Function to show help
function Show-Help {
    Write-Host "dcon Installation Script for Windows"
    Write-Host ""
    Write-Host "Usage: .\install.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Version VERSION   Install specific version (default: latest)"
    Write-Host "  -InstallDir DIR    Install to specific directory (default: $InstallDir)"
    Write-Host "  -Help              Show this help message"
    Write-Host ""
    Write-Host "Environment Variables:"
    Write-Host "  DCON_INSTALL_DIR   Override default installation directory"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1                           # Install latest version"
    Write-Host "  .\install.ps1 -Version v2.0.3          # Install specific version"
    Write-Host "  .\install.ps1 -InstallDir C:\tools     # Install to custom directory"
    exit 0
}

# Function to get the latest release version
function Get-LatestVersion {
    Write-Status "Fetching latest release version..."

    try {
        $ApiUrl = "https://api.github.com/repos/$Repo/releases/latest"
        $Response = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing
        $LatestVersion = $Response.tag_name

        if (-not $LatestVersion) {
            throw "Failed to fetch the latest version"
        }

        Write-Status "Latest version: $LatestVersion"
        return $LatestVersion
    }
    catch {
        Write-Error "Failed to fetch the latest version: $($_.Exception.Message)"
        exit 1
    }
}

# Function to detect architecture
function Get-Architecture {
    $arch = $env:PROCESSOR_ARCHITECTURE
    switch ($arch) {
        "AMD64" { return "x86_64" }
        "ARM64" { return "aarch64" }
        default {
            Write-Error "Unsupported architecture: $arch"
            exit 1
        }
    }
}

# Function to download the binary
function Download-Binary {
    param([string]$Arch)

    $BinaryFile = "dcon-$Arch-pc-windows-msvc.exe"
    $DownloadUrl = "https://github.com/$Repo/releases/download/$Version/$BinaryFile"
    $TempFile = "$env:TEMP\$BinaryFile"

    Write-Status "Downloading dcon $Version for Windows $Arch..."
    Write-Status "Download URL: $DownloadUrl"

    try {
        # Use Invoke-WebRequest to download
        $ProgressPreference = 'SilentlyContinue'  # Disable progress bar for faster download
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempFile -UseBasicParsing
        $ProgressPreference = 'Continue'  # Re-enable progress bar

        if (-not (Test-Path $TempFile)) {
            throw "Download failed - file not found"
        }

        # Check if the downloaded file is actually a binary (not an error page)
        $FileSize = (Get-Item $TempFile).Length
        if ($FileSize -lt 1000) {
            Write-Error "Downloaded file is too small ($FileSize bytes) - likely an error page"
            Write-Error "Please check if the release exists: https://github.com/$Repo/releases/tag/$Version"
            Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
            exit 1
        }

        Write-Status "Successfully downloaded binary ($FileSize bytes)"
        return $TempFile
    }
    catch {
        Write-Error "Failed to download the binary: $($_.Exception.Message)"
        exit 1
    }
}

# Function to install the binary
function Install-Binary {
    param([string]$TempFile)
    
    # Create install directory if it doesn't exist
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    
    $InstallPath = Join-Path $InstallDir $BinaryName
    
    try {
        # Copy the binary
        Copy-Item $TempFile $InstallPath -Force
        
        # Clean up
        Remove-Item $TempFile -Force
        
        Write-Success "dcon installed successfully to $InstallPath"
        return $InstallPath
    }
    catch {
        Write-Error "Failed to install the binary: $($_.Exception.Message)"
        exit 1
    }
}

# Function to update PATH
function Update-Path {
    # Check if the install directory is already in PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    
    if ($currentPath -notlike "*$InstallDir*") {
        Write-Status "Adding $InstallDir to user PATH..."
        
        try {
            $newPath = if ($currentPath) { "$currentPath;$InstallDir" } else { $InstallDir }
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
            
            # Update PATH for current session
            $env:PATH = "$env:PATH;$InstallDir"
            
            Write-Warning "PATH updated. Please restart your terminal or PowerShell session."
        }
        catch {
            Write-Warning "Failed to update PATH automatically. Please add $InstallDir to your PATH manually."
        }
    }
    else {
        Write-Status "$InstallDir is already in PATH"
    }
}

# Function to verify installation
function Test-Installation {
    param([string]$InstallPath)
    
    if (Test-Path $InstallPath) {
        Write-Success "Installation verified!"
        Write-Status "Run 'dcon --help' to get started"
        
        # Try to run the binary
        try {
            Write-Status "Testing installation..."
            & $InstallPath --version
        }
        catch {
            Write-Warning "Binary installed but couldn't run version check. You may need to restart your terminal."
        }
    }
    else {
        Write-Error "Installation verification failed"
        exit 1
    }
}

# Main installation process
function Main {
    if ($Help) {
        Show-Help
    }
    
    # Override install directory if environment variable is set
    if ($env:DCON_INSTALL_DIR) {
        $InstallDir = $env:DCON_INSTALL_DIR
    }
    
    Write-Status "Starting dcon installation..."

    # Get latest version if not specified
    if (-not $Version) {
        $Version = Get-LatestVersion
    }

    # Detect architecture
    $arch = Get-Architecture
    Write-Status "Detected architecture: $arch"

    # Download binary
    $tempFile = Download-Binary -Arch $arch
    
    # Install binary
    $installPath = Install-Binary -TempFile $tempFile
    
    # Update PATH
    Update-Path
    
    # Verify installation
    Test-Installation -InstallPath $installPath
    
    Write-Success "dcon installation completed!"
    Write-Host ""
    Write-Status "🎉 Welcome to dcon - PostgreSQL CLI Tool!"
    Write-Status "📖 Documentation: https://github.com/emadbaqeri/dcon"
    Write-Status "🐛 Report issues: https://github.com/emadbaqeri/dcon/issues"
    Write-Host ""
    Write-Status "Get started with: dcon --help"
}

# Run main function
Main
