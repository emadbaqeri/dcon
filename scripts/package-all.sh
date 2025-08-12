#!/bin/bash
# Master packaging script for all platforms

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📦 dcon Cross-Platform Packaging"
echo "================================="

cd "$PROJECT_ROOT"

# Detect current platform
PLATFORM=$(uname -s)
ARCH=$(uname -m)

echo "🖥️  Current platform: $PLATFORM ($ARCH)"
echo ""

# Build CLI first
echo "🔨 Building CLI binary..."
./scripts/build-cli.sh

case "$PLATFORM" in
    "Darwin")
        echo "🍎 Building macOS packages..."
        if [ -d "packaging/macos" ]; then
            ./packaging/macos/build-dmg.sh
            echo "✅ macOS DMG created"
        else
            echo "⚠️  macOS packaging scripts not found"
        fi
        ;;
    
    "Linux")
        echo "🐧 Building Linux packages..."
        
        # Build DEB package
        if command -v dpkg-deb >/dev/null 2>&1; then
            echo "📦 Building DEB package..."
            ./packaging/linux/build-deb.sh
            echo "✅ DEB package created"
        else
            echo "⚠️  dpkg-deb not found, skipping DEB package"
        fi
        
        # Build AppImage
        echo "📦 Building AppImage..."
        ./packaging/linux/build-appimage.sh
        echo "✅ AppImage created"
        ;;
    
    "MINGW"*|"MSYS"*|"CYGWIN"*)
        echo "🪟 Building Windows packages..."
        if command -v powershell.exe >/dev/null 2>&1; then
            powershell.exe -ExecutionPolicy Bypass -File "packaging/windows/build-installer.ps1"
            echo "✅ Windows package created"
        else
            echo "⚠️  PowerShell not found, skipping Windows package"
        fi
        ;;
    
    *)
        echo "❌ Unsupported platform: $PLATFORM"
        echo "   Supported platforms: macOS (Darwin), Linux, Windows (MINGW/MSYS/Cygwin)"
        exit 1
        ;;
esac

echo ""
echo "✅ Packaging complete!"
echo "📁 Check the target/ directory for packages:"
echo "   - target/macos/     (macOS .dmg files)"
echo "   - target/linux/     (Linux .deb and .AppImage files)"
echo "   - target/windows/   (Windows .zip and .msi files)"
echo ""
echo "🚀 Ready for distribution!"
