#!/bin/bash

# dcon Quality Checks Script
# Additional quality checks for the dcon project
# This script can be sourced by other hooks or run independently

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[quality-check]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[quality-check]${NC} ✅ $1"
}

print_warning() {
    echo -e "${YELLOW}[quality-check]${NC} ⚠️  $1"
}

print_error() {
    echo -e "${RED}[quality-check]${NC} ❌ $1"
}

# Function to check for TODO/FIXME comments in main branch
check_todo_fixme() {
    print_status "Checking for TODO/FIXME comments..."
    
    # Get current branch
    current_branch=$(git branch --show-current)
    
    # Only check on main/master branch
    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        # Find TODO/FIXME comments in Rust files
        todo_count=$(find src -name "*.rs" -exec grep -n -i "TODO\|FIXME" {} + 2>/dev/null | wc -l)
        
        if [ "$todo_count" -gt 0 ]; then
            print_warning "Found $todo_count TODO/FIXME comments in main branch:"
            find src -name "*.rs" -exec grep -n -i --color=always "TODO\|FIXME" {} + 2>/dev/null | head -10
            if [ "$todo_count" -gt 10 ]; then
                echo "... and $((todo_count - 10)) more"
            fi
            print_warning "Consider resolving these before releasing"
            return 1
        fi
    fi
    
    print_success "No TODO/FIXME comments found (or not on main branch)"
    return 0
}

# Function to check documentation coverage
check_doc_coverage() {
    print_status "Checking documentation coverage..."
    
    # Check if cargo-doc is available
    if ! command -v cargo &> /dev/null; then
        print_error "cargo not found"
        return 1
    fi
    
    # Generate docs and check for missing documentation warnings
    doc_output=$(cargo doc --no-deps --document-private-items 2>&1)
    missing_docs=$(echo "$doc_output" | grep -c "missing documentation" || true)
    
    if [ "$missing_docs" -gt 0 ]; then
        print_warning "Found $missing_docs items with missing documentation:"
        echo "$doc_output" | grep "missing documentation" | head -5
        if [ "$missing_docs" -gt 5 ]; then
            echo "... and $((missing_docs - 5)) more"
        fi
        print_warning "Consider adding documentation for public items"
        return 1
    fi
    
    print_success "Documentation coverage looks good"
    return 0
}

# Function to validate semantic versioning in Cargo.toml
check_semantic_versioning() {
    print_status "Checking semantic versioning in Cargo.toml..."
    
    if [ ! -f "Cargo.toml" ]; then
        print_error "Cargo.toml not found"
        return 1
    fi
    
    # Extract version from Cargo.toml
    version=$(grep '^version = ' Cargo.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
    
    if [ -z "$version" ]; then
        print_error "Could not find version in Cargo.toml"
        return 1
    fi
    
    # Check if version follows semantic versioning (X.Y.Z or X.Y.Z-suffix)
    if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
        print_error "Version '$version' does not follow semantic versioning (X.Y.Z)"
        print_warning "Expected format: MAJOR.MINOR.PATCH (e.g., 1.2.3)"
        return 1
    fi
    
    print_success "Version '$version' follows semantic versioning"
    return 0
}

# Function to check for security vulnerabilities
check_security_audit() {
    print_status "Running security audit..."
    
    # Check if cargo-audit is installed
    if ! command -v cargo-audit &> /dev/null; then
        print_warning "cargo-audit not found. Install with: cargo install cargo-audit"
        print_warning "Skipping security audit"
        return 0
    fi
    
    # Run security audit with timeout (if available)
    if command -v timeout &> /dev/null; then
        timeout_cmd="timeout 30s"
    else
        timeout_cmd=""
    fi

    if ! $timeout_cmd cargo audit; then
        print_error "Security audit failed or timed out"
        print_warning "Review security vulnerabilities above"
        return 1
    fi
    
    print_success "Security audit passed"
    return 0
}

# Function to check Cargo.toml formatting and completeness
check_cargo_toml() {
    print_status "Checking Cargo.toml completeness..."
    
    if [ ! -f "Cargo.toml" ]; then
        print_error "Cargo.toml not found"
        return 1
    fi
    
    # Check for required fields for publishing
    required_fields=("name" "version" "edition" "description" "license" "authors")
    missing_fields=()
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "^$field = " Cargo.toml; then
            missing_fields+=("$field")
        fi
    done
    
    if [ ${#missing_fields[@]} -gt 0 ]; then
        print_warning "Missing recommended fields in Cargo.toml: ${missing_fields[*]}"
        print_warning "These fields are recommended for publishing to crates.io"
    else
        print_success "Cargo.toml has all recommended fields"
    fi
    
    return 0
}

# Main function to run all quality checks
run_all_quality_checks() {
    print_status "Running additional quality checks..."
    
    failed=0
    
    # Run all checks (some are warnings only)
    if ! check_semantic_versioning; then
        failed=1
    fi
    
    check_cargo_toml  # Warning only
    
    if ! check_doc_coverage; then
        # Don't fail for missing docs, just warn
        print_warning "Documentation coverage could be improved"
    fi
    
    if ! check_todo_fixme; then
        # Don't fail for TODO/FIXME, just warn
        print_warning "Consider resolving TODO/FIXME comments"
    fi
    
    check_security_audit  # Warning only if not installed
    
    return $failed
}

# If script is run directly, run all checks
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_quality_checks
    exit $?
fi
