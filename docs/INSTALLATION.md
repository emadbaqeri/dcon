# 📦 dcon Installation Guide

This guide covers all installation methods for **dcon**, the PostgreSQL database management tool.

## 🎯 Choose Your Installation Method

### 📦 Package Installers (Recommended)

Package installers provide the easiest installation experience with proper system integration.

#### 🍎 macOS

**Option 1: DMG Installer**
```bash
# Download the latest DMG
curl -L -o dcon.dmg https://github.com/emadbaqeri/dcon/releases/latest/download/dcon-2.1.0-macos.dmg

# Open the DMG and drag dcon to Applications
open dcon.dmg
```

**Option 2: Homebrew** *(Coming Soon)*
```bash
brew install emadbaqeri/tap/dcon
```

#### 🐧 Linux

**Ubuntu/Debian (DEB Package)**
```bash
# Download and install DEB package
curl -L -o dcon.deb https://github.com/emadbaqeri/dcon/releases/latest/download/dcon_2.1.0_amd64.deb
sudo dpkg -i dcon.deb

# Fix dependencies if needed
sudo apt-get install -f
```

**Universal Linux (AppImage)**
```bash
# Download AppImage
curl -L -o dcon.AppImage https://github.com/emadbaqeri/dcon/releases/latest/download/dcon-2.1.0-x86_64.AppImage

# Make executable and run
chmod +x dcon.AppImage
./dcon.AppImage

# Optional: Integrate with system
./dcon.AppImage --appimage-extract
sudo mv squashfs-root/usr/bin/dcon /usr/local/bin/
```

**Arch Linux** *(Coming Soon)*
```bash
yay -S dcon
```

#### 🪟 Windows

**Option 1: ZIP Package**
```powershell
# Download and extract
Invoke-WebRequest -Uri "https://github.com/emadbaqeri/dcon/releases/latest/download/dcon-2.1.0-windows.zip" -OutFile "dcon.zip"
Expand-Archive -Path "dcon.zip" -DestinationPath "dcon"
cd dcon

# Run installer (adds to PATH)
.\install.bat
```

**Option 2: MSI Installer** *(Coming Soon)*
```powershell
# Download and run MSI installer
Invoke-WebRequest -Uri "https://github.com/emadbaqeri/dcon/releases/latest/download/dcon-2.1.0-windows.msi" -OutFile "dcon.msi"
Start-Process msiexec.exe -ArgumentList "/i dcon.msi" -Wait
```

**Option 3: Chocolatey** *(Coming Soon)*
```powershell
choco install dcon
```

### 🔧 Pre-built Binaries

For manual installation or custom setups:

1. **Download** the appropriate binary from [GitHub Releases](https://github.com/emadbaqeri/dcon/releases/latest)
2. **Extract** (if compressed) and place in your PATH
3. **Make executable** (Unix systems): `chmod +x dcon`

**Available Targets:**
- `dcon-x86_64-apple-darwin` - macOS Intel
- `dcon-aarch64-apple-darwin` - macOS Apple Silicon
- `dcon-x86_64-unknown-linux-gnu` - Linux x86_64
- `dcon-aarch64-unknown-linux-gnu` - Linux ARM64
- `dcon-x86_64-pc-windows-msvc.exe` - Windows x86_64
- `dcon-aarch64-pc-windows-msvc.exe` - Windows ARM64

### 🛠️ Build from Source

**Prerequisites:**
- Rust 1.70+ ([Install Rust](https://rustup.rs/))
- Git

**Steps:**
```bash
# Clone repository
git clone https://github.com/emadbaqeri/dcon.git
cd dcon

# Build CLI only
./scripts/build-cli.sh

# Install CLI to system
./scripts/build-cli.sh --install

# Or build all components
./scripts/build-all.sh
```

**Development Build:**
```bash
# Debug build
cargo build -p dcon

# Release build
cargo build --release -p dcon

# Run tests
cargo test --workspace
```

## ✅ Verify Installation

After installation, verify dcon is working:

```bash
# Check version
dcon --version

# Test help
dcon --help

# Test connection (requires PostgreSQL server)
dcon connect --host localhost --user postgres
```

## 🔧 Configuration

### Environment Variables

Set these environment variables for default connection settings:

```bash
export DCON_HOST=localhost
export DCON_PORT=5432
export DCON_USER=postgres
export DCON_DATABASE=postgres
```

### Configuration File *(Coming Soon)*

Create `~/.dcon/config.toml`:

```toml
[default]
host = "localhost"
port = 5432
user = "postgres"
database = "postgres"

[connections.production]
host = "prod.example.com"
port = 5432
user = "app_user"
database = "app_db"
```

## 🚨 Troubleshooting

### Common Issues

**"Command not found"**
- Ensure dcon is in your PATH
- On Windows, restart your terminal after installation

**"Permission denied"**
- Make the binary executable: `chmod +x dcon`
- On macOS, you may need to allow the app in Security & Privacy settings

**"Connection refused"**
- Ensure PostgreSQL server is running
- Check host, port, and credentials
- Verify firewall settings

**Linux: "No such file or directory" (despite file existing)**
- Install required libraries: `sudo apt-get install libc6 libssl3`
- For older systems, try the static binary build

### Getting Help

- 📖 [Documentation](https://github.com/emadbaqeri/dcon/wiki)
- 🐛 [Report Issues](https://github.com/emadbaqeri/dcon/issues)
- 💬 [Discussions](https://github.com/emadbaqeri/dcon/discussions)

## 🔄 Updating

### Package Managers
- **macOS DMG**: Download and install new version
- **Linux DEB**: `sudo dpkg -i dcon_new_version.deb`
- **AppImage**: Download new AppImage file

### Manual Updates
1. Download the latest release
2. Replace the old binary
3. Restart your terminal

### From Source
```bash
cd dcon
git pull origin main
./scripts/build-cli.sh --install
```

## 🗑️ Uninstallation

### Package Installers
- **macOS**: Drag dcon from Applications to Trash
- **Linux DEB**: `sudo apt-get remove dcon`
- **Windows**: Run `uninstall.bat` or use Add/Remove Programs

### Manual Installation
```bash
# Remove binary
sudo rm /usr/local/bin/dcon  # or wherever you installed it

# Remove configuration (optional)
rm -rf ~/.dcon
```
