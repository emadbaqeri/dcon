#!/bin/bash
# Build script for GUI-only version

set -e

echo "🔨 Building dcon GUI..."

# Check if GUI dependencies are available
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust compiler not found. Please install Rust."
    exit 1
fi

# Build the GUI binary (when GPUI issues are resolved)
echo "⚠️  GUI build is currently disabled due to GPUI API compatibility issues."
echo "    The GUI implementation needs to be updated for the latest GPUI version."
echo "    For now, use the CLI version: ./scripts/build-cli.sh"

# Uncomment when GUI is fixed:
# cargo build --release -p dcon-gui

# echo "✅ GUI build complete!"
# echo "📦 Binary location: target/release/dcon-gui"

# Optional: Create a simple installer
if [ "$1" = "--install" ]; then
    echo "📥 GUI installation is currently disabled."
    echo "    Please use the CLI version instead."
    # cargo install --path crates/dcon-gui --force
    # echo "✅ dcon GUI installed successfully!"
fi
