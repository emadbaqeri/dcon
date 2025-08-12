#!/bin/bash
# Build script for CLI-only version

set -e

echo "🔨 Building dcon CLI..."

# Build the CLI binary
cargo build --release -p dcon

echo "✅ CLI build complete!"
echo "📦 Binary location: target/release/dcon"

# Optional: Create a simple installer
if [ "$1" = "--install" ]; then
    echo "📥 Installing dcon CLI..."
    cargo install --path crates/dcon-cli --force
    echo "✅ dcon CLI installed successfully!"
fi
