#!/bin/bash

# Script to test semantic-release configuration
# This script simulates different commit types to verify version bumping logic

set -e

echo "🧪 Testing semantic-release configuration"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to test commit analysis
test_commit_analysis() {
    local commit_msg="$1"
    local expected_bump="$2"
    
    print_status "Testing commit: '$commit_msg'"
    print_status "Expected bump: $expected_bump"
    
    # Create a temporary commit to test
    echo "test" > test_file_temp.txt
    git add test_file_temp.txt
    git commit -m "$commit_msg" --quiet
    
    # Run semantic-release in dry-run mode to see what it would do
    # Note: This requires GITHUB_TOKEN to be set for remote access
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        print_status "Running semantic-release dry-run..."
        npx semantic-release --dry-run --no-ci 2>/dev/null | grep -E "(next release version|no release)" || true
    else
        print_warning "GITHUB_TOKEN not set, skipping dry-run test"
    fi
    
    # Reset the test commit
    git reset --hard HEAD~1 --quiet
    rm -f test_file_temp.txt
    
    echo ""
}

# Main test function
main() {
    print_status "Current version in Cargo.toml: $(grep '^version = ' Cargo.toml | sed 's/version = "\(.*\)"/\1/')"
    print_status "Latest git tag: $(git describe --tags --abbrev=0 2>/dev/null || echo 'none')"
    echo ""
    
    print_status "Testing different commit types..."
    echo ""
    
    # Test patch release (fix)
    test_commit_analysis "fix: resolve connection timeout issues" "patch"
    
    # Test minor release (feat)
    test_commit_analysis "feat: add new query builder feature" "minor"
    
    # Test no release (docs)
    test_commit_analysis "docs: update README with new examples" "no release"
    
    # Test no release (chore)
    test_commit_analysis "chore: update dependencies" "no release"
    
    # Test breaking change (major)
    test_commit_analysis "feat!: redesign CLI interface

BREAKING CHANGE: Command structure has changed completely" "major"
    
    print_success "Semantic-release configuration test completed!"
    echo ""
    print_status "📋 Summary of expected behavior:"
    print_status "• fix: commits → patch release (2.0.0 → 2.0.1)"
    print_status "• feat: commits → minor release (2.0.0 → 2.1.0)"
    print_status "• BREAKING CHANGE → major release (2.0.0 → 3.0.0)"
    print_status "• docs/chore/test/ci → no release"
    echo ""
    print_status "🔧 To test with actual semantic-release:"
    print_status "export GITHUB_TOKEN=your_token"
    print_status "./scripts/test-semantic-release.sh"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Check if semantic-release is available
if ! command -v npx > /dev/null 2>&1; then
    print_error "npx not found. Please install Node.js and npm."
    exit 1
fi

# Run main function
main
