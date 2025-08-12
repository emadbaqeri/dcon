#!/bin/bash
# Linux AppImage packaging script for dcon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION="2.1.0"

echo "🐧 Building Linux AppImage for dcon v$VERSION..."

cd "$PROJECT_ROOT"

# Build the CLI binary for Linux
echo "🔨 Building CLI binary..."
cargo build --release -p dcon

# Create AppDir structure
APPDIR="target/linux/dcon.AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy binary
cp "target/release/dcon" "$APPDIR/usr/bin/"
chmod +x "$APPDIR/usr/bin/dcon"

# Create desktop file
cat > "$APPDIR/usr/share/applications/dcon.desktop" << EOF
[Desktop Entry]
Type=Application
Name=dcon
Comment=PostgreSQL Database Management Tool
Exec=dcon
Icon=dcon
Categories=Development;Database;
Terminal=true
EOF

# Create AppRun script
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${PATH}"
exec "${HERE}/usr/bin/dcon" "$@"
EOF

chmod +x "$APPDIR/AppRun"

# Create a simple icon (text-based for now)
cat > "$APPDIR/dcon.desktop" << EOF
[Desktop Entry]
Type=Application
Name=dcon
Comment=PostgreSQL Database Management Tool
Exec=dcon
Icon=dcon
Categories=Development;Database;
Terminal=true
EOF

# Create a simple PNG icon (placeholder)
# In a real implementation, you'd have a proper icon file
echo "⚠️  Using placeholder icon. Add a proper dcon.png icon to improve the AppImage."

# Download appimagetool if not present
APPIMAGETOOL="target/linux/appimagetool-x86_64.AppImage"
if [ ! -f "$APPIMAGETOOL" ]; then
    echo "📥 Downloading appimagetool..."
    wget -O "$APPIMAGETOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGETOOL"
fi

# Build AppImage
echo "📦 Building AppImage..."
APPIMAGE_PATH="target/linux/dcon-$VERSION-x86_64.AppImage"
"$APPIMAGETOOL" "$APPDIR" "$APPIMAGE_PATH"

echo "✅ AppImage created: $APPIMAGE_PATH"
echo "📦 Size: $(du -h "$APPIMAGE_PATH" | cut -f1)"
echo "🚀 Run with: ./$APPIMAGE_PATH"

# Make it executable
chmod +x "$APPIMAGE_PATH"

echo "✅ AppImage build complete!"
