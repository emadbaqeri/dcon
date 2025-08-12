# Windows installer script for dcon
# Requires: Rust toolchain with windows target, WiX Toolset (optional)

param(
    [string]$Version = "2.1.0",
    [switch]$Msi = $false
)

Write-Host "🪟 Building Windows package for dcon v$Version..." -ForegroundColor Cyan

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $ProjectRoot

# Build the CLI binary for Windows
Write-Host "🔨 Building CLI binary..." -ForegroundColor Yellow
cargo build --release -p dcon

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

# Create package directory
$PackageDir = "target\windows\dcon-$Version-windows"
if (Test-Path $PackageDir) {
    Remove-Item -Recurse -Force $PackageDir
}
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
New-Item -ItemType Directory -Path "$PackageDir\bin" -Force | Out-Null
New-Item -ItemType Directory -Path "$PackageDir\docs" -Force | Out-Null

# Copy binary
Copy-Item "target\release\dcon.exe" "$PackageDir\bin\"

# Create batch wrapper for easier execution
@"
@echo off
"%~dp0bin\dcon.exe" %*
"@ | Out-File -FilePath "$PackageDir\dcon.bat" -Encoding ASCII

# Copy documentation
if (Test-Path "README.md") {
    Copy-Item "README.md" "$PackageDir\docs\"
}

# Create installation script
@"
@echo off
echo Installing dcon...

REM Add to PATH (requires admin privileges)
setx PATH "%PATH%;%~dp0bin" /M 2>nul
if %errorlevel% neq 0 (
    echo Warning: Could not add to system PATH. You may need to run as administrator.
    echo You can manually add %~dp0bin to your PATH environment variable.
)

echo.
echo dcon has been installed!
echo Run 'dcon --help' to get started.
echo.
pause
"@ | Out-File -FilePath "$PackageDir\install.bat" -Encoding ASCII

# Create uninstallation script
@"
@echo off
echo Uninstalling dcon...

REM Remove from PATH (basic removal - may need manual cleanup)
echo Please manually remove the dcon installation directory from your PATH environment variable.
echo Installation directory: %~dp0

echo.
echo dcon uninstallation complete.
pause
"@ | Out-File -FilePath "$PackageDir\uninstall.bat" -Encoding ASCII

# Create ZIP package
Write-Host "📦 Creating ZIP package..." -ForegroundColor Yellow
$ZipPath = "target\windows\dcon-$Version-windows.zip"
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath
}

# Use PowerShell's Compress-Archive
Compress-Archive -Path "$PackageDir\*" -DestinationPath $ZipPath

Write-Host "✅ ZIP package created: $ZipPath" -ForegroundColor Green
Write-Host "📦 Size: $((Get-Item $ZipPath).Length / 1MB) MB" -ForegroundColor Green

# Optional: Create MSI installer using WiX (if available and requested)
if ($Msi) {
    Write-Host "📦 Creating MSI installer..." -ForegroundColor Yellow
    
    # Check if WiX is available
    $wixPath = Get-Command "candle.exe" -ErrorAction SilentlyContinue
    if (-not $wixPath) {
        Write-Warning "WiX Toolset not found. Skipping MSI creation."
        Write-Host "Install WiX Toolset from: https://wixtoolset.org/" -ForegroundColor Yellow
    } else {
        # Create WiX source file
        $wxsContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="dcon" Language="1033" Version="$Version" Manufacturer="Emad" UpgradeCode="12345678-1234-1234-1234-123456789012">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" />
    
    <MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed." />
    <MediaTemplate EmbedCab="yes" />
    
    <Feature Id="ProductFeature" Title="dcon" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
    </Feature>
  </Product>
  
  <Fragment>
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="dcon" />
      </Directory>
    </Directory>
  </Fragment>
  
  <Fragment>
    <ComponentGroup Id="ProductComponents" Directory="INSTALLFOLDER">
      <Component Id="ProductComponent">
        <File Id="dcon.exe" Source="target\release\dcon.exe" />
      </Component>
    </ComponentGroup>
  </Fragment>
</Wix>
"@
        
        $wxsPath = "target\windows\dcon.wxs"
        $wxsContent | Out-File -FilePath $wxsPath -Encoding UTF8
        
        # Build MSI
        $wixObjPath = "target\windows\dcon.wixobj"
        $msiPath = "target\windows\dcon-$Version-windows.msi"
        
        & candle.exe -out $wixObjPath $wxsPath
        if ($LASTEXITCODE -eq 0) {
            & light.exe -out $msiPath $wixObjPath
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ MSI installer created: $msiPath" -ForegroundColor Green
            } else {
                Write-Warning "MSI creation failed during linking."
            }
        } else {
            Write-Warning "MSI creation failed during compilation."
        }
    }
}

Write-Host "✅ Windows packaging complete!" -ForegroundColor Green
Write-Host "📦 Package location: $PackageDir" -ForegroundColor Cyan
Write-Host "📥 Install by extracting ZIP and running install.bat" -ForegroundColor Cyan
