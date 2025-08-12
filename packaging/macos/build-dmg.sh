#!/bin/bash
# macOS DMG packaging script for dcon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION="2.1.0"
APP_NAME="dcon"

echo "🍎 Building macOS package for dcon v$VERSION..."

cd "$PROJECT_ROOT"

# Build the CLI binary for macOS
echo "🔨 Building CLI binary..."
cargo build --release -p dcon

# Create app bundle structure
BUNDLE_DIR="target/macos/$APP_NAME.app"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Copy binary
cp "target/release/dcon" "$BUNDLE_DIR/Contents/MacOS/"

# Create Info.plist
cat > "$BUNDLE_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>dcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.emaaad.dcon</string>
    <key>CFBundleName</key>
    <string>dcon</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
EOF

# Create DMG
echo "📦 Creating DMG..."
DMG_NAME="dcon-$VERSION-macos"
DMG_PATH="target/macos/$DMG_NAME.dmg"

# Remove existing DMG
rm -f "$DMG_PATH"

# Create temporary DMG directory
TEMP_DMG_DIR="target/macos/dmg_temp"
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# Copy app bundle to temp directory
cp -R "$BUNDLE_DIR" "$TEMP_DMG_DIR/"

# Create symlink to Applications
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "dcon $VERSION" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_PATH"

# Clean up
rm -rf "$TEMP_DMG_DIR"

echo "✅ macOS DMG created: $DMG_PATH"
echo "📦 Size: $(du -h "$DMG_PATH" | cut -f1)"

# Optional: Create installer package
if [ "$1" = "--pkg" ]; then
    echo "📦 Creating installer package..."
    PKG_PATH="target/macos/dcon-$VERSION-macos.pkg"
    
    # Create package
    pkgbuild --root "$BUNDLE_DIR" \
             --identifier "com.emaaad.dcon" \
             --version "$VERSION" \
             --install-location "/Applications" \
             "$PKG_PATH"
    
    echo "✅ Installer package created: $PKG_PATH"
fi
