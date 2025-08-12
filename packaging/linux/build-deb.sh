#!/bin/bash
# Linux DEB packaging script for dcon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION="2.1.0"
ARCH="amd64"  # Change to arm64 for ARM builds

echo "🐧 Building Linux DEB package for dcon v$VERSION..."

cd "$PROJECT_ROOT"

# Build the CLI binary for Linux
echo "🔨 Building CLI binary..."
cargo build --release -p dcon

# Create package directory structure
PKG_DIR="target/linux/dcon_${VERSION}_${ARCH}"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/doc/dcon"
mkdir -p "$PKG_DIR/usr/share/man/man1"

# Copy binary
cp "target/release/dcon" "$PKG_DIR/usr/bin/"
chmod +x "$PKG_DIR/usr/bin/dcon"

# Create control file
cat > "$PKG_DIR/DEBIAN/control" << EOF
Package: dcon
Version: $VERSION
Section: database
Priority: optional
Architecture: $ARCH
Depends: libc6 (>= 2.31), libssl3 (>= 3.0.0)
Maintainer: Emad <hey@emaaad.com>
Description: PostgreSQL Database Management Tool
 A powerful PostgreSQL command-line tool for database operations built in Rust.
 Features include database connection management, table operations, query execution,
 and interactive mode for database administration.
Homepage: https://github.com/emadbaqeri/dcon
EOF

# Create postinst script
cat > "$PKG_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Update man database
if command -v mandb >/dev/null 2>&1; then
    mandb -q
fi

echo "dcon has been installed successfully!"
echo "Run 'dcon --help' to get started."
EOF

chmod +x "$PKG_DIR/DEBIAN/postinst"

# Create prerm script
cat > "$PKG_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e

echo "Removing dcon..."
EOF

chmod +x "$PKG_DIR/DEBIAN/prerm"

# Copy documentation
if [ -f "README.md" ]; then
    cp "README.md" "$PKG_DIR/usr/share/doc/dcon/"
fi

# Create changelog
cat > "$PKG_DIR/usr/share/doc/dcon/changelog" << EOF
dcon ($VERSION) stable; urgency=medium

  * Initial release with dual CLI/GUI architecture
  * PostgreSQL database management capabilities
  * Interactive query execution
  * Cross-platform support

 -- Emad <hey@emaaad.com>  $(date -R)
EOF

gzip -9 "$PKG_DIR/usr/share/doc/dcon/changelog"

# Create copyright file
cat > "$PKG_DIR/usr/share/doc/dcon/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: dcon
Upstream-Contact: Emad <hey@emaaad.com>
Source: https://github.com/emadbaqeri/dcon

Files: *
Copyright: 2024 Emad
License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

# Build the package
echo "📦 Building DEB package..."
DEB_PATH="target/linux/dcon_${VERSION}_${ARCH}.deb"
dpkg-deb --build "$PKG_DIR" "$DEB_PATH"

echo "✅ DEB package created: $DEB_PATH"
echo "📦 Size: $(du -h "$DEB_PATH" | cut -f1)"

# Verify package
echo "🔍 Verifying package..."
dpkg-deb --info "$DEB_PATH"
dpkg-deb --contents "$DEB_PATH"

echo "✅ Package verification complete!"
echo "📥 Install with: sudo dpkg -i $DEB_PATH"
