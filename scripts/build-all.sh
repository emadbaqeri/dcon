#!/bin/bash
# Build script for both CLI and GUI versions

set -e

echo "🔨 Building all dcon components..."

# Build core library first
echo "📚 Building dcon-core..."
cargo build --release -p dcon-core

# Build CLI
echo "💻 Building dcon CLI..."
cargo build --release -p dcon

# Build GUI (when available)
echo "🖥️  Building dcon GUI..."
echo "⚠️  GUI build is currently disabled due to GPUI API compatibility issues."
# cargo build --release -p dcon-gui

echo "✅ Build complete!"
echo "📦 CLI Binary: target/release/dcon"
echo "📦 GUI Binary: target/release/dcon-gui (when available)"

# Optional: Install both
if [ "$1" = "--install" ]; then
    echo "📥 Installing dcon components..."
    cargo install --path crates/dcon-cli --force
    echo "✅ dcon CLI installed successfully!"
    
    echo "⚠️  GUI installation is currently disabled."
    # cargo install --path crates/dcon-gui --force
    # echo "✅ dcon GUI installed successfully!"
fi
