#!/bin/bash

# dcon Git Hooks Installation Script
# This script copies the Git hooks from the hooks/ directory to .git/hooks/
# Run this after cloning the repository to enable the hooks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[install-hooks]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[install-hooks]${NC} ✅ $1"
}

print_warning() {
    echo -e "${YELLOW}[install-hooks]${NC} ⚠️  $1"
}

print_error() {
    echo -e "${RED}[install-hooks]${NC} ❌ $1"
}

# Function to create hooks directory structure
create_hooks_directory() {
    print_status "Creating hooks directory structure..."
    
    # Create hooks directory in the repository (tracked by Git)
    mkdir -p hooks
    
    print_success "Hooks directory created"
}

# Function to copy hooks to the tracked directory
copy_hooks_to_tracked_dir() {
    print_status "Copying hooks to tracked hooks/ directory..."
    
    # Copy hooks from .git/hooks to hooks/ (so they can be tracked)
    if [ -f ".git/hooks/pre-commit" ]; then
        cp .git/hooks/pre-commit hooks/
        print_success "Copied pre-commit hook"
    fi
    
    if [ -f ".git/hooks/pre-push" ]; then
        cp .git/hooks/pre-push hooks/
        print_success "Copied pre-push hook"
    fi
    
    if [ -f ".git/hooks/quality-checks.sh" ]; then
        cp .git/hooks/quality-checks.sh hooks/
        print_success "Copied quality-checks script"
    fi
    
    # Make sure they're executable
    chmod +x hooks/* 2>/dev/null || true
}

# Function to install hooks from tracked directory
install_hooks_from_tracked_dir() {
    print_status "Installing hooks from hooks/ directory..."
    
    if [ ! -d "hooks" ]; then
        print_error "hooks/ directory not found. Please run this from the dcon repository root."
        exit 1
    fi
    
    # Copy hooks from hooks/ to .git/hooks/
    for hook_file in hooks/*; do
        if [ -f "$hook_file" ]; then
            hook_name=$(basename "$hook_file")
            cp "$hook_file" ".git/hooks/$hook_name"
            chmod +x ".git/hooks/$hook_name"
            print_success "Installed $hook_name"
        fi
    done
}

# Function to show help
show_help() {
    echo "dcon Git Hooks Installation Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install    Install hooks from hooks/ directory to .git/hooks/"
    echo "  export     Export hooks from .git/hooks/ to hooks/ directory"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install    # Install hooks (run after cloning)"
    echo "  $0 export     # Export hooks (run after creating/modifying hooks)"
    echo ""
}

# Main execution
main() {
    local command="${1:-install}"
    
    case "$command" in
        "install")
            print_status "Installing Git hooks for dcon..."
            install_hooks_from_tracked_dir
            print_success "Git hooks installation completed! 🎉"
            echo ""
            echo "Run './scripts/setup-git-hooks.sh' to verify the installation."
            ;;
        "export")
            print_status "Exporting Git hooks to tracked directory..."
            create_hooks_directory
            copy_hooks_to_tracked_dir
            print_success "Git hooks exported to hooks/ directory! 📦"
            echo ""
            echo "The hooks are now tracked by Git and can be shared with other contributors."
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
