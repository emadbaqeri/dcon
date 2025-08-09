# 📦 Installation Guide

This guide provides multiple ways to install **dcon** on different operating systems.

## 🚀 Quick Installation

### One-liner Installation (macOS & Linux)

```bash
curl -sSL https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install-oneliner.sh | bash
```

### PowerShell Installation (Windows)

```powershell
iwr -useb https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install.ps1 | iex
```

## 📋 Platform-Specific Installation

### 🍎 macOS

#### Option 1: Using the installation script
```bash
# Download and run the installation script
curl -sSL https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install.sh | bash

# Or download the script first and then run it
curl -O https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install.sh
chmod +x install.sh
./install.sh
```

#### Option 2: Manual installation
```bash
# Download the binary for your architecture
# For Intel Macs (x86_64)
curl -L -o dcon https://github.com/emadbaqeri/dcon/releases/download/v1.0.0/dcon-x86_64-apple-darwin

# For Apple Silicon Macs (M1/M2)
curl -L -o dcon https://github.com/emadbaqeri/dcon/releases/download/v1.0.0/dcon-aarch64-apple-darwin

# Make it executable and move to PATH
chmod +x dcon
sudo mv dcon /usr/local/bin/
```

### 🐧 Linux

#### Option 1: Using the installation script
```bash
# Download and run the installation script
curl -sSL https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install.sh | bash

# Or download the script first and then run it
wget https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install.sh
chmod +x install.sh
./install.sh
```

#### Option 2: Manual installation
```bash
# Download the binary for your architecture
# For x86_64 systems
curl -L -o dcon https://github.com/emadbaqeri/dcon/releases/download/v1.0.0/dcon-x86_64-unknown-linux-gnu

# For ARM64 systems
curl -L -o dcon https://github.com/emadbaqeri/dcon/releases/download/v1.0.0/dcon-aarch64-unknown-linux-gnu

# Make it executable and move to PATH
chmod +x dcon
sudo mv dcon /usr/local/bin/
```

### 🪟 Windows

#### Option 1: Using PowerShell script
```powershell
# Download and run the PowerShell installation script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install.ps1" -OutFile "install.ps1"
.\install.ps1

# Or run directly
iwr -useb https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install.ps1 | iex
```

#### Option 2: Using Batch script
```cmd
# Download and run the batch installation script
curl -O https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install.bat
install.bat
```

#### Option 3: Manual installation
1. Download the appropriate binary:
   - For x86_64: [dcon-x86_64-pc-windows-msvc.exe](https://github.com/emadbaqeri/dcon/releases/download/v1.0.0/dcon-x86_64-pc-windows-msvc.exe)
   - For ARM64: [dcon-aarch64-pc-windows-msvc.exe](https://github.com/emadbaqeri/dcon/releases/download/v1.0.0/dcon-aarch64-pc-windows-msvc.exe)

2. Rename the downloaded file to `dcon.exe`
3. Move it to a directory in your PATH (e.g., `C:\Windows\System32` or create `%USERPROFILE%\.local\bin`)
4. Add the directory to your PATH if necessary

## ⚙️ Advanced Installation Options

### Custom Installation Directory

#### Unix-like systems (macOS & Linux)
```bash
# Install to a custom directory
./install.sh --dir /opt/dcon/bin

# Or use environment variable
export DCON_INSTALL_DIR="/opt/dcon/bin"
./install.sh
```

#### Windows
```powershell
# Install to a custom directory
.\install.ps1 -InstallDir "C:\tools\dcon"

# Or use environment variable
$env:DCON_INSTALL_DIR = "C:\tools\dcon"
.\install.ps1
```

### Specific Version Installation

```bash
# Unix-like systems
./install.sh --version v1.0.0

# Windows PowerShell
.\install.ps1 -Version v1.0.0
```

## 🔧 Building from Source

If you prefer to build from source or the pre-built binaries don't work for your system:

```bash
# Prerequisites: Rust toolchain (https://rustup.rs/)
git clone https://github.com/emadbaqeri/dcon.git
cd dcon
cargo build --release

# The binary will be available at target/release/dcon
# Copy it to your PATH
cp target/release/dcon ~/.local/bin/  # Unix-like
# or
copy target\release\dcon.exe %USERPROFILE%\.local\bin\  # Windows
```

## ✅ Verification

After installation, verify that dcon is working correctly:

```bash
# Check version
dcon --version

# Show help
dcon --help

# Test connection (replace with your database details)
dcon -H localhost -P 5432 -u postgres -d postgres connect
```

## 🗑️ Uninstallation

To uninstall dcon:

### Unix-like systems (macOS & Linux)
```bash
# Remove the binary
rm ~/.local/bin/dcon

# Remove from PATH (edit your shell profile file)
# Remove the line: export PATH="$PATH:$HOME/.local/bin"
```

### Windows
```powershell
# Remove the binary
Remove-Item "$env:USERPROFILE\.local\bin\dcon.exe"

# Remove from PATH using System Properties > Environment Variables
# Or use PowerShell:
$path = [Environment]::GetEnvironmentVariable("PATH", "User")
$newPath = $path -replace ";$env:USERPROFILE\\\.local\\bin", ""
[Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
```

## 🆘 Troubleshooting

### Permission Denied
If you get permission denied errors:
- On Unix-like systems: Use `sudo` for system-wide installation or install to user directory
- On Windows: Run PowerShell as Administrator

### Binary Not Found After Installation
- Restart your terminal/command prompt
- Check that the installation directory is in your PATH
- Verify the binary exists in the installation directory

### Download Failures
- Check your internet connection
- Verify the release exists at: https://github.com/emadbaqeri/dcon/releases/tag/v1.0.0
- Try downloading manually from the GitHub releases page

### Architecture Issues
The installation scripts automatically detect your system architecture. Supported architectures:
- **x86_64** (Intel/AMD 64-bit)
- **aarch64** (ARM 64-bit, including Apple Silicon)

If you have an unsupported architecture, you'll need to build from source.

## 📞 Support

If you encounter any issues:
- 📖 Check the [documentation](https://github.com/emadbaqeri/dcon)
- 🐛 Report bugs at [GitHub Issues](https://github.com/emadbaqeri/dcon/issues)
- 💬 Ask questions in [GitHub Discussions](https://github.com/emadbaqeri/dcon/discussions)
