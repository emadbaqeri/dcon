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

# Function to detect the user's current shell
detect_shell() {
    local detected_shell=""
    local shell_name=""

    # Method 1: Check environment variables (most reliable when available)
    if [ -n "$ZSH_VERSION" ]; then
        detected_shell="zsh"
        print_status "Shell detected via ZSH_VERSION: zsh"
    elif [ -n "$BASH_VERSION" ]; then
        detected_shell="bash"
        print_status "Shell detected via BASH_VERSION: bash"
    elif [ -n "$FISH_VERSION" ]; then
        detected_shell="fish"
        print_status "Shell detected via FISH_VERSION: fish"
    fi

    # Method 2: Check $SHELL environment variable
    if [ -z "$detected_shell" ] && [ -n "$SHELL" ]; then
        shell_name=$(basename "$SHELL")
        case "$shell_name" in
            zsh)
                detected_shell="zsh"
                print_status "Shell detected via \$SHELL: zsh ($SHELL)"
                ;;
            bash)
                detected_shell="bash"
                print_status "Shell detected via \$SHELL: bash ($SHELL)"
                ;;
            fish)
                detected_shell="fish"
                print_status "Shell detected via \$SHELL: fish ($SHELL)"
                ;;
            dash|sh)
                detected_shell="dash"
                print_status "Shell detected via \$SHELL: dash/sh ($SHELL)"
                ;;
            *)
                print_status "Unknown shell detected via \$SHELL: $shell_name ($SHELL)"
                ;;
        esac
    fi

    # Method 3: Check parent process (fallback method)
    if [ -z "$detected_shell" ]; then
        if command_exists ps; then
            local parent_cmd
            parent_cmd=$(ps -p $$ -o comm= 2>/dev/null | tr -d ' ')
            if [ -n "$parent_cmd" ]; then
                case "$parent_cmd" in
                    zsh)
                        detected_shell="zsh"
                        print_status "Shell detected via parent process: zsh"
                        ;;
                    bash)
                        detected_shell="bash"
                        print_status "Shell detected via parent process: bash"
                        ;;
                    fish)
                        detected_shell="fish"
                        print_status "Shell detected via parent process: fish"
                        ;;
                    dash|sh)
                        detected_shell="dash"
                        print_status "Shell detected via parent process: dash/sh"
                        ;;
                esac
            fi
        fi
    fi

    # Method 4: Final fallback - check what shells are available
    if [ -z "$detected_shell" ]; then
        print_warning "Could not detect shell automatically, using fallback detection"
        if command_exists zsh && [ -f "$HOME/.zshrc" ]; then
            detected_shell="zsh"
            print_status "Fallback: Found zsh and ~/.zshrc, assuming zsh"
        elif command_exists bash; then
            detected_shell="bash"
            print_status "Fallback: Found bash, assuming bash"
        else
            detected_shell="unknown"
            print_warning "Fallback: Could not determine shell, will try multiple config files"
        fi
    fi

    echo "$detected_shell"
}

# Function to get shell configuration file path
get_shell_config_file() {
    local shell_type="$1"
    local config_file=""

    case "$shell_type" in
        zsh)
            config_file="$HOME/.zshrc"
            ;;
        bash)
            # Prefer .bash_profile on macOS, .bashrc on Linux
            if [ "$OS" = "macos" ] && [ -f "$HOME/.bash_profile" ]; then
                config_file="$HOME/.bash_profile"
            elif [ -f "$HOME/.bashrc" ]; then
                config_file="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                config_file="$HOME/.bash_profile"
            else
                # Create .bashrc if neither exists
                config_file="$HOME/.bashrc"
            fi
            ;;
        fish)
            config_file="$HOME/.config/fish/config.fish"
            # Create fish config directory if it doesn't exist
            mkdir -p "$(dirname "$config_file")"
            ;;
        dash)
            # dash typically uses .profile
            config_file="$HOME/.profile"
            ;;
        *)
            # Unknown shell - try common files in order of preference
            if [ -f "$HOME/.zshrc" ]; then
                config_file="$HOME/.zshrc"
                print_status "Unknown shell: using existing ~/.zshrc"
            elif [ -f "$HOME/.bashrc" ]; then
                config_file="$HOME/.bashrc"
                print_status "Unknown shell: using existing ~/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                config_file="$HOME/.bash_profile"
                print_status "Unknown shell: using existing ~/.bash_profile"
            else
                # Default to .bashrc for unknown shells
                config_file="$HOME/.bashrc"
                print_status "Unknown shell: defaulting to ~/.bashrc"
            fi
            ;;
    esac

    echo "$config_file"
}

# Function to update PATH and make command immediately available
update_path() {
    local shell_type
    local shell_profile
    local path_updated=false

    # Detect the user's shell
    shell_type=$(detect_shell)

    # Get the appropriate configuration file
    shell_profile=$(get_shell_config_file "$shell_type")

    print_status "Detected shell: $shell_type"
    print_status "Configuration file: $shell_profile"

    # Check if the install directory is already in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        print_status "Adding $INSTALL_DIR to PATH in $shell_profile"

        # Create the config file if it doesn't exist
        if [ ! -f "$shell_profile" ]; then
            touch "$shell_profile"
            print_status "Created configuration file: $shell_profile"
        fi

        # Add PATH export based on shell type
        echo "" >> "$shell_profile"
        echo "# Added by dcon installer" >> "$shell_profile"

        case "$shell_type" in
            fish)
                echo "set -gx PATH \$PATH $INSTALL_DIR" >> "$shell_profile"
                print_status "Added fish-style PATH export to $shell_profile"
                ;;
            *)
                echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$shell_profile"
                print_status "Added POSIX-style PATH export to $shell_profile"
                ;;
        esac

        # Update PATH in current session
        export PATH="$PATH:$INSTALL_DIR"
        path_updated=true
        print_status "Updated PATH in current session"
    else
        print_status "$INSTALL_DIR is already in PATH"
    fi

    # Refresh command hash table for immediate availability
    print_status "Refreshing command cache for immediate availability..."
    if command -v hash >/dev/null 2>&1; then
        hash -r 2>/dev/null || true
        print_status "Command cache refreshed"
    fi

    # Shell-specific cache refresh
    case "$shell_type" in
        zsh)
            if command -v rehash >/dev/null 2>&1; then
                rehash 2>/dev/null || true
                print_status "Refreshed zsh command cache"
            fi
            ;;
        fish)
            # Fish automatically updates its command cache
            print_status "Fish shell will automatically update command cache"
            ;;
    esac

    # Provide user feedback about next steps
    if [ "$path_updated" = true ]; then
        echo ""
        print_success "✓ Updated PATH in $shell_profile"
        case "$shell_type" in
            zsh)
                print_status "💡 To use dcon in new terminal sessions, restart your terminal or run:"
                print_status "   source ~/.zshrc"
                ;;
            bash)
                print_status "💡 To use dcon in new terminal sessions, restart your terminal or run:"
                if [[ "$shell_profile" == *".bash_profile"* ]]; then
                    print_status "   source ~/.bash_profile"
                else
                    print_status "   source ~/.bashrc"
                fi
                ;;
            fish)
                print_status "💡 To use dcon in new terminal sessions, restart your terminal or run:"
                print_status "   source ~/.config/fish/config.fish"
                ;;
            *)
                print_status "💡 To use dcon in new terminal sessions, restart your terminal or run:"
                print_status "   source $shell_profile"
                ;;
        esac
        echo ""
    fi
}

# Function to provide manual installation instructions as fallback
provide_manual_instructions() {
    local shell_type="$1"
    local shell_profile="$2"

    echo ""
    print_warning "⚠️  Automatic shell configuration may not have worked perfectly."
    print_status "📋 Manual setup instructions:"
    echo ""

    case "$shell_type" in
        zsh)
            print_status "1. Add dcon to your PATH by running:"
            print_status "   echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> ~/.zshrc"
            print_status "2. Reload your shell configuration:"
            print_status "   source ~/.zshrc"
            ;;
        bash)
            print_status "1. Add dcon to your PATH by running:"
            if [[ "$shell_profile" == *".bash_profile"* ]]; then
                print_status "   echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> ~/.bash_profile"
                print_status "2. Reload your shell configuration:"
                print_status "   source ~/.bash_profile"
            else
                print_status "   echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> ~/.bashrc"
                print_status "2. Reload your shell configuration:"
                print_status "   source ~/.bashrc"
            fi
            ;;
        fish)
            print_status "1. Add dcon to your PATH by running:"
            print_status "   echo 'set -gx PATH \$PATH $INSTALL_DIR' >> ~/.config/fish/config.fish"
            print_status "2. Reload your shell configuration:"
            print_status "   source ~/.config/fish/config.fish"
            ;;
        *)
            print_status "1. Add dcon to your PATH by adding this line to your shell's configuration file:"
            print_status "   export PATH=\"\$PATH:$INSTALL_DIR\""
            print_status "2. Common configuration files to try:"
            print_status "   ~/.zshrc (for zsh), ~/.bashrc (for bash), ~/.profile (for dash/sh)"
            print_status "3. Reload your shell configuration or restart your terminal"
            ;;
    esac

    echo ""
    print_status "3. Test the installation:"
    print_status "   dcon --version"
    echo ""
    print_status "4. If you continue to have issues:"
    print_status "   - Try restarting your terminal completely"
    print_status "   - Check that $INSTALL_DIR is in your PATH: echo \$PATH"
    print_status "   - Run the binary directly: $INSTALL_DIR/dcon --version"
    echo ""
}

# Function to verify installation and test immediate availability
verify_installation() {
    local shell_type="$1"
    local shell_profile="$2"

    if [ -x "$INSTALL_DIR/$BINARY_NAME" ]; then
        print_status "Verifying installation..."

        # Test that the binary works with full path
        if ! "$INSTALL_DIR/$BINARY_NAME" --version >/dev/null 2>&1; then
            print_error "Binary verification failed - dcon binary is not working correctly"
            print_error "The downloaded binary may be corrupted or incompatible with your system"
            print_error "Please check: $INSTALL_DIR/$BINARY_NAME"
            exit 1
        fi

        local version_output
        version_output=$("$INSTALL_DIR/$BINARY_NAME" --version 2>&1)
        print_status "✓ Binary verification successful: $version_output"

        # Test that the command is available in current session
        local max_attempts=5
        local attempt=1
        local command_available=false

        print_status "Testing command availability in current session..."
        while [ $attempt -le $max_attempts ]; do
            if command_exists "$BINARY_NAME"; then
                print_status "Testing dcon command (attempt $attempt/$max_attempts)..."
                if "$BINARY_NAME" --version >/dev/null 2>&1; then
                    command_available=true
                    break
                fi
            fi

            # If command not available, try various refresh methods
            if [ $attempt -lt $max_attempts ]; then
                print_status "Command not immediately available, trying refresh methods..."

                # Method 1: Standard hash refresh
                if command -v hash >/dev/null 2>&1; then
                    hash -r 2>/dev/null || true
                fi

                # Method 2: Shell-specific refresh
                case "$shell_type" in
                    zsh)
                        if command -v rehash >/dev/null 2>&1; then
                            rehash 2>/dev/null || true
                        fi
                        ;;
                    fish)
                        # Fish doesn't need manual cache refresh
                        ;;
                esac

                # Method 3: Re-export PATH
                export PATH="$PATH:$INSTALL_DIR"

                sleep 1
            fi

            attempt=$((attempt + 1))
        done

        if [ "$command_available" = true ]; then
            local final_version
            final_version=$("$BINARY_NAME" --version 2>&1)
            print_success "🎉 Installation verified! dcon command is ready to use."
            print_status "✓ Final test: $final_version"
            return 0
        else
            print_warning "Installation completed but dcon command is not immediately available in current session"
            print_status "The binary is installed at: $INSTALL_DIR/$BINARY_NAME"
            print_status "This is normal when installing via curl | bash"

            # Provide manual instructions
            provide_manual_instructions "$shell_type" "$shell_profile"

            # Don't exit with error - installation was successful, just needs manual activation
            return 1
        fi
    else
        print_error "Installation verification failed - binary not found or not executable"
        print_error "Expected location: $INSTALL_DIR/$BINARY_NAME"
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

    # Update PATH and get shell information
    shell_type=$(detect_shell)
    shell_profile=$(get_shell_config_file "$shell_type")
    update_path

    # Verify installation
    if verify_installation "$shell_type" "$shell_profile"; then
        # Command is immediately available
        print_success "dcon installation completed successfully!"
        echo ""
        print_status "🎉 Welcome to dcon - PostgreSQL CLI Tool!"
        print_status "📖 Documentation: https://github.com/emadbaqeri/dcon"
        print_status "🐛 Report issues: https://github.com/emadbaqeri/dcon/issues"
        echo ""
        print_success "✓ dcon is ready to use! Try: dcon --help"
    else
        # Command needs manual activation
        print_success "dcon installation completed successfully!"
        echo ""
        print_status "🎉 Welcome to dcon - PostgreSQL CLI Tool!"
        print_status "📖 Documentation: https://github.com/emadbaqeri/dcon"
        print_status "🐛 Report issues: https://github.com/emadbaqeri/dcon/issues"
        echo ""
        print_warning "⚠️  Please follow the manual setup instructions above to use dcon"
        print_status "After setup, try: dcon --help"
    fi
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
