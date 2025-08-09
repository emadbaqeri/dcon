#!/bin/bash

# Script to manually trigger binary build for a specific release
# Usage: ./scripts/trigger-binary-build.sh [TAG]

set -e

TAG=${1:-"v1.0.0"}

echo "🚀 Triggering binary build workflow for tag: $TAG"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    echo ""
    echo "Alternative: Go to GitHub Actions and manually trigger the 'Build and Release Binaries' workflow"
    echo "URL: https://github.com/emadbaqeri/dcon/actions/workflows/release.yml"
    exit 1
fi

# Trigger the workflow
echo "📦 Triggering workflow dispatch..."
gh workflow run release.yml --field tag="$TAG"

echo "✅ Binary build workflow triggered successfully!"
echo ""
echo "🔍 Monitor progress at:"
echo "https://github.com/emadbaqeri/dcon/actions/workflows/release.yml"
echo ""
echo "📦 Once complete, binaries will be available at:"
echo "https://github.com/emadbaqeri/dcon/releases/tag/$TAG"
