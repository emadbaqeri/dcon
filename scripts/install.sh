#!/bin/bash

# dcon Installation Script for Unix-like systems (macOS and Linux)
# This script downloads and installs the latest version of dcon

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO="emadbaqeri/dcon"
VERSION=""  # Will be set dynamically
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="dcon"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to detect OS and architecture
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case "$os" in
        linux*)
            OS="linux"
            ;;
        darwin*)
            OS="macos"
            ;;
        *)
            print_error "Unsupported operating system: $os"
            exit 1
            ;;
    esac
    
    case "$arch" in
        x86_64|amd64)
            ARCH="x86_64"
            ;;
        arm64|aarch64)
            ARCH="aarch64"
            ;;
        *)
            print_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    # Construct the binary name based on platform
    if [ "$OS" = "macos" ]; then
        BINARY_FILE="${BINARY_NAME}-${ARCH}-apple-darwin"
    else
        BINARY_FILE="${BINARY_NAME}-${ARCH}-unknown-linux-gnu"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get the latest release version
get_latest_version() {
    print_status "Fetching latest release version..."

    if command_exists curl; then
        VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    elif command_exists wget; then
        VERSION=$(wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        print_error "Neither curl nor wget is available. Please install one of them."
        exit 1
    fi

    if [ -z "$VERSION" ]; then
        print_error "Failed to fetch the latest version"
        exit 1
    fi

    print_status "Latest version: ${VERSION}"
}

# Function to download the binary
download_binary() {
    local download_url="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY_FILE}"
    local temp_file="/tmp/${BINARY_FILE}"

    print_status "Downloading dcon ${VERSION} for ${OS} ${ARCH}..."
    print_status "Download URL: ${download_url}"

    if command_exists curl; then
        if ! curl -L -o "$temp_file" "$download_url"; then
            print_error "Failed to download the binary from ${download_url}"
            exit 1
        fi
    elif command_exists wget; then
        if ! wget -O "$temp_file" "$download_url"; then
            print_error "Failed to download the binary from ${download_url}"
            exit 1
        fi
    else
        print_error "Neither curl nor wget is available. Please install one of them."
        exit 1
    fi

    if [ ! -f "$temp_file" ]; then
        print_error "Failed to download the binary - file does not exist"
        exit 1
    fi

    # Check if the downloaded file is actually a binary (not an error page)
    local file_size=$(wc -c < "$temp_file")
    if [ "$file_size" -lt 1000 ]; then
        print_error "Downloaded file is too small (${file_size} bytes) - likely an error page"
        print_error "Please check if the release exists: https://github.com/${REPO}/releases/tag/${VERSION}"
        rm -f "$temp_file"
        exit 1
    fi

    print_status "Successfully downloaded binary (${file_size} bytes)"
    echo "$temp_file"
}

# Function to install the binary
install_binary() {
    local temp_file="$1"
    
    # Create install directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"
    
    # Copy and make executable
    cp "$temp_file" "$INSTALL_DIR/$BINARY_NAME"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
    
    # Clean up
    rm -f "$temp_file"
    
    print_success "dcon installed successfully to $INSTALL_DIR/$BINARY_NAME"
}

# Function to update PATH
update_path() {
    local shell_profile=""
    
    # Detect shell and set appropriate profile file
    if [ -n "$ZSH_VERSION" ]; then
        shell_profile="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        if [ -f "$HOME/.bash_profile" ]; then
            shell_profile="$HOME/.bash_profile"
        else
            shell_profile="$HOME/.bashrc"
        fi
    elif [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
        shell_profile="$HOME/.zshrc"
    else
        shell_profile="$HOME/.bashrc"
    fi
    
    # Check if the install directory is already in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        print_status "Adding $INSTALL_DIR to PATH in $shell_profile"
        echo "" >> "$shell_profile"
        echo "# Added by dcon installer" >> "$shell_profile"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$shell_profile"
        print_warning "Please restart your terminal or run: source $shell_profile"
    else
        print_status "$INSTALL_DIR is already in PATH"
    fi
}

# Function to verify installation
verify_installation() {
    if [ -x "$INSTALL_DIR/$BINARY_NAME" ]; then
        print_success "Installation verified!"
        print_status "Run 'dcon --help' to get started"
        
        # Try to run the binary if it's in PATH
        if command_exists "$BINARY_NAME"; then
            print_status "Testing installation..."
            "$BINARY_NAME" --version || true
        fi
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Main installation process
main() {
    print_status "Starting dcon installation..."

    # Detect platform
    detect_platform
    print_status "Detected platform: ${OS} ${ARCH}"

    # Get latest version if not specified
    if [ -z "$VERSION" ]; then
        get_latest_version
    fi

    # Download binary
    temp_file=$(download_binary)

    # Install binary
    install_binary "$temp_file"

    # Update PATH
    update_path

    # Verify installation
    verify_installation

    print_success "dcon installation completed!"
    echo ""
    print_status "🎉 Welcome to dcon - PostgreSQL CLI Tool!"
    print_status "📖 Documentation: https://github.com/emadbaqeri/dcon"
    print_status "🐛 Report issues: https://github.com/emadbaqeri/dcon/issues"
    echo ""
    print_status "Get started with: dcon --help"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "dcon Installation Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --version, -v  Install specific version (default: latest)"
        echo "  --dir DIR      Install to specific directory (default: $INSTALL_DIR)"
        echo ""
        echo "Environment Variables:"
        echo "  DCON_INSTALL_DIR   Override default installation directory"
        echo ""
        exit 0
        ;;
    --version|-v)
        if [ -n "$2" ]; then
            VERSION="$2"
            print_status "Installing version: $VERSION"
            shift 2
        else
            print_error "Version argument required"
            exit 1
        fi
        ;;
    --dir)
        if [ -n "$2" ]; then
            INSTALL_DIR="$2"
            print_status "Installing to: $INSTALL_DIR"
            shift 2
        else
            print_error "Directory argument required"
            exit 1
        fi
        ;;
esac

# Override install directory if environment variable is set
if [ -n "$DCON_INSTALL_DIR" ]; then
    INSTALL_DIR="$DCON_INSTALL_DIR"
fi

# Run main installation
main
