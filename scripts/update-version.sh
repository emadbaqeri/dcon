#!/bin/bash

# Script to update version in Cargo.toml for semantic-release
# Usage: ./scripts/update-version.sh <new_version>

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <new_version>"
    echo "Example: $0 1.2.3"
    exit 1
fi

NEW_VERSION="$1"

# Validate semantic version format
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
    echo "Error: Invalid semantic version format: $NEW_VERSION"
    echo "Expected format: X.Y.Z or X.Y.Z-suffix"
    exit 1
fi

# Check if Cargo.toml exists
if [ ! -f "Cargo.toml" ]; then
    echo "Error: Cargo.toml not found"
    exit 1
fi

# Create a backup
cp Cargo.toml Cargo.toml.backup

# Update only the first version line (package version) using awk
awk -v new_version="$NEW_VERSION" '
/^version = / && !updated {
    print "version = \"" new_version "\""
    updated = 1
    next
}
{ print }
' Cargo.toml.backup > Cargo.toml

# Verify the change was made
if ! grep -q "^version = \"$NEW_VERSION\"" Cargo.toml; then
    echo "Error: Failed to update version in Cargo.toml"
    mv Cargo.toml.backup Cargo.toml
    exit 1
fi

# Verify Cargo.toml is still valid
if ! cargo check --quiet; then
    echo "Error: Cargo.toml is invalid after version update"
    mv Cargo.toml.backup Cargo.toml
    exit 1
fi

# Clean up backup
rm Cargo.toml.backup

echo "Successfully updated version to $NEW_VERSION in Cargo.toml"
