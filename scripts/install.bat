@echo off
setlocal enabledelayedexpansion

REM dcon Installation Script for Windows (Batch)
REM This script downloads and installs the latest version of dcon

REM Configuration
set "REPO=emadbaqeri/dcon"
set "VERSION=v1.0.0"
set "BINARY_NAME=dcon.exe"
set "INSTALL_DIR=%USERPROFILE%\.local\bin"

REM Override install directory if environment variable is set
if defined DCON_INSTALL_DIR (
    set "INSTALL_DIR=%DCON_INSTALL_DIR%"
)

REM Colors (limited in batch)
set "INFO=[INFO]"
set "SUCCESS=[SUCCESS]"
set "WARNING=[WARNING]"
set "ERROR=[ERROR]"

echo %INFO% Starting dcon installation...

REM Detect architecture
set "ARCH=x86_64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=aarch64"

echo %INFO% Detected architecture: %ARCH%

REM Construct binary filename
set "BINARY_FILE=dcon-%ARCH%-pc-windows-msvc.exe"
set "DOWNLOAD_URL=https://github.com/%REPO%/releases/download/%VERSION%/%BINARY_FILE%"
set "TEMP_FILE=%TEMP%\%BINARY_FILE%"

echo %INFO% Downloading dcon %VERSION% for Windows %ARCH%...
echo %INFO% Download URL: %DOWNLOAD_URL%

REM Download using PowerShell (more reliable than curl in batch)
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_FILE%' -UseBasicParsing}"

if not exist "%TEMP_FILE%" (
    echo %ERROR% Failed to download the binary
    exit /b 1
)

REM Create install directory if it doesn't exist
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)

REM Copy the binary
copy "%TEMP_FILE%" "%INSTALL_DIR%\%BINARY_NAME%" >nul
if errorlevel 1 (
    echo %ERROR% Failed to copy binary to install directory
    exit /b 1
)

REM Clean up
del "%TEMP_FILE%"

echo %SUCCESS% dcon installed successfully to %INSTALL_DIR%\%BINARY_NAME%

REM Check if install directory is in PATH
echo %PATH% | findstr /i "%INSTALL_DIR%" >nul
if errorlevel 1 (
    echo %INFO% Adding %INSTALL_DIR% to user PATH...
    
    REM Add to user PATH using PowerShell
    powershell -Command "& {$path = [Environment]::GetEnvironmentVariable('PATH', 'User'); if ($path -notlike '*%INSTALL_DIR%*') { [Environment]::SetEnvironmentVariable('PATH', $path + ';%INSTALL_DIR%', 'User') }}"
    
    echo %WARNING% Please restart your command prompt or PowerShell session.
) else (
    echo %INFO% %INSTALL_DIR% is already in PATH
)

REM Verify installation
if exist "%INSTALL_DIR%\%BINARY_NAME%" (
    echo %SUCCESS% Installation verified!
    echo %INFO% Run 'dcon --help' to get started
) else (
    echo %ERROR% Installation verification failed
    exit /b 1
)

echo.
echo %SUCCESS% dcon installation completed!
echo.
echo %INFO% 🎉 Welcome to dcon - PostgreSQL CLI Tool!
echo %INFO% 📖 Documentation: https://github.com/emadbaqeri/dcon
echo %INFO% 🐛 Report issues: https://github.com/emadbaqeri/dcon/issues
echo.
echo %INFO% Get started with: dcon --help

pause
