#!/bin/bash

# dcon Git Hooks Setup Script
# This script sets up Git hooks for the dcon project
# Run this script after cloning the repository to enable code quality checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[setup-hooks]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[setup-hooks]${NC} ✅ $1"
}

print_warning() {
    echo -e "${YELLOW}[setup-hooks]${NC} ⚠️  $1"
}

print_error() {
    echo -e "${RED}[setup-hooks]${NC} ❌ $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository"
        exit 1
    fi
    
    # Check if we're in the dcon project root
    if [ ! -f "Cargo.toml" ] || ! grep -q 'name = "dcon"' Cargo.toml; then
        print_error "Not in the dcon project root directory"
        exit 1
    fi
    
    # Check if Rust is installed
    if ! command -v cargo &> /dev/null; then
        print_error "Rust/Cargo not found. Please install Rust from https://rustup.rs/"
        exit 1
    fi
    
    # Check Rust components
    local missing_components=()
    
    if ! command -v rustfmt &> /dev/null; then
        missing_components+=("rustfmt")
    fi
    
    if ! command -v cargo-clippy &> /dev/null; then
        missing_components+=("clippy")
    fi
    
    if [ ${#missing_components[@]} -gt 0 ]; then
        print_warning "Missing Rust components: ${missing_components[*]}"
        print_status "Installing missing components..."
        for component in "${missing_components[@]}"; do
            rustup component add "$component"
        done
    fi
    
    print_success "Prerequisites check passed"
}

# Function to backup existing hooks
backup_existing_hooks() {
    local hooks_dir=".git/hooks"
    local backup_dir=".git/hooks-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -f "$hooks_dir/pre-commit" ] || [ -f "$hooks_dir/pre-push" ]; then
        print_status "Backing up existing hooks to $backup_dir"
        mkdir -p "$backup_dir"
        
        if [ -f "$hooks_dir/pre-commit" ]; then
            cp "$hooks_dir/pre-commit" "$backup_dir/"
            print_status "Backed up existing pre-commit hook"
        fi
        
        if [ -f "$hooks_dir/pre-push" ]; then
            cp "$hooks_dir/pre-push" "$backup_dir/"
            print_status "Backed up existing pre-push hook"
        fi
    fi
}

# Function to verify hooks are working
verify_hooks() {
    print_status "Verifying Git hooks installation..."
    
    local hooks_dir=".git/hooks"
    
    # Check if hooks exist and are executable
    for hook in "pre-commit" "pre-push" "quality-checks.sh"; do
        if [ ! -f "$hooks_dir/$hook" ]; then
            print_error "Hook $hook not found"
            return 1
        fi
        
        if [ ! -x "$hooks_dir/$hook" ]; then
            print_error "Hook $hook is not executable"
            return 1
        fi
    done
    
    # Test pre-commit hook with dry run
    print_status "Testing pre-commit hook..."
    if ! bash -n "$hooks_dir/pre-commit"; then
        print_error "Pre-commit hook has syntax errors"
        return 1
    fi
    
    # Test pre-push hook with dry run
    print_status "Testing pre-push hook..."
    if ! bash -n "$hooks_dir/pre-push"; then
        print_error "Pre-push hook has syntax errors"
        return 1
    fi
    
    # Test quality checks script
    print_status "Testing quality checks script..."
    if ! bash -n "$hooks_dir/quality-checks.sh"; then
        print_error "Quality checks script has syntax errors"
        return 1
    fi
    
    print_success "All hooks verified successfully"
    return 0
}

# Function to install optional tools
install_optional_tools() {
    print_status "Checking optional tools..."
    
    # Check for cargo-audit
    if ! command -v cargo-audit &> /dev/null; then
        print_warning "cargo-audit not found (used for security audits)"
        read -p "Install cargo-audit? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Installing cargo-audit..."
            cargo install cargo-audit
            print_success "cargo-audit installed"
        fi
    else
        print_success "cargo-audit is already installed"
    fi
}

# Function to show usage instructions
show_usage_instructions() {
    echo ""
    print_success "Git hooks setup completed! 🎉"
    echo ""
    echo "The following hooks are now active:"
    echo ""
    echo "📝 Pre-commit hook:"
    echo "   - Runs cargo fmt --check"
    echo "   - Runs cargo clippy with strict settings"
    echo "   - Runs cargo check"
    echo "   - Validates semantic versioning"
    echo ""
    echo "🚀 Pre-push hook:"
    echo "   - Runs full test suite (cargo test)"
    echo "   - Runs documentation tests (cargo test --doc)"
    echo "   - Runs benchmark compilation check"
    echo "   - Checks for TODO/FIXME in main branch"
    echo "   - Runs security audit (if available)"
    echo ""
    echo "🔧 To bypass hooks in emergency situations:"
    echo "   git commit --no-verify"
    echo "   git push --no-verify"
    echo ""
    echo "🧪 To test the hooks manually:"
    echo "   .git/hooks/pre-commit"
    echo "   .git/hooks/pre-push origin main"
    echo "   .git/hooks/quality-checks.sh"
    echo ""
}

# Main execution
main() {
    echo "🔧 Setting up Git hooks for dcon..."
    echo ""
    
    check_prerequisites
    backup_existing_hooks
    
    # The hooks should already be in place if this script is run from the repo
    if [ ! -f ".git/hooks/pre-commit" ]; then
        print_error "Git hooks not found. Please ensure you're running this from the dcon repository."
        exit 1
    fi
    
    verify_hooks
    install_optional_tools
    show_usage_instructions
}

# Run main function
main "$@"
