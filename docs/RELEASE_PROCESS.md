# 🚀 Release Process Documentation

This document explains how the automated release and binary building process works for dcon.

## 📋 Overview

The release process consists of two main workflows:

1. **Semantic Release** (`semantic-release.yml`) - Creates GitHub releases with changelogs
2. **Binary Build** (`release.yml`) - Builds and uploads cross-platform binaries

## 🔄 Automated Workflow

### 1. Code Changes → Release
When you push commits to the `main` branch with conventional commit messages:

```bash
git commit -m "feat: add new database connection feature"
git push origin main
```

### 2. Semantic Release Triggers
- Analyzes commit messages using conventional commits
- Determines version bump (major/minor/patch)
- Creates GitHub release with changelog
- Updates `Cargo.toml` version
- Creates and pushes a new git tag

### 3. Binary Build Triggers
- Automatically triggered after semantic-release creates a new tag
- Builds binaries for all supported platforms:
  - **Linux**: x86_64, aarch64 (ARM64)
  - **macOS**: x86_64 (Intel), aarch64 (Apple Silicon)
  - **Windows**: x86_64, aarch64 (ARM64)

### 4. Binary Upload
- Uploads binaries to the GitHub release as assets
- Uses consistent naming convention for installation scripts

## 🎯 Supported Platforms & Binary Names

| Platform | Architecture | Binary Name |
|----------|-------------|-------------|
| Linux | x86_64 | `dcon-x86_64-unknown-linux-gnu` |
| Linux | ARM64 | `dcon-aarch64-unknown-linux-gnu` |
| macOS | Intel | `dcon-x86_64-apple-darwin` |
| macOS | Apple Silicon | `dcon-aarch64-apple-darwin` |
| Windows | x86_64 | `dcon-x86_64-pc-windows-msvc.exe` |
| Windows | ARM64 | `dcon-aarch64-pc-windows-msvc.exe` |

## 🛠️ Manual Triggers

### For Existing Releases
If you need to build binaries for an existing release:

```bash
# Using the trigger script
./scripts/trigger-binary-build.sh v1.0.0

# Or manually via GitHub CLI
gh workflow run release.yml --field tag="v1.0.0"
```

### Via GitHub Web Interface
1. Go to [Actions → Build and Release Binaries](https://github.com/emadbaqeri/dcon/actions/workflows/release.yml)
2. Click "Run workflow"
3. Enter the release tag (e.g., `v1.0.0`)
4. Click "Run workflow"

## 🔧 Troubleshooting

### Binary Build Workflow Didn't Trigger
If semantic-release creates a release but binaries aren't built:

1. Check the [Semantic Release workflow](https://github.com/emadbaqeri/dcon/actions/workflows/semantic-release.yml)
2. Manually trigger binary build: `./scripts/trigger-binary-build.sh <TAG>`
3. Check workflow permissions and tokens

### Cross-compilation Issues
- **Linux ARM64**: Requires `gcc-aarch64-linux-gnu` (automatically installed)
- **Windows ARM64**: Uses native MSVC cross-compilation
- **macOS**: Both architectures build on `macos-latest` runners

### Missing Binaries in Release
1. Check the [Binary Build workflow logs](https://github.com/emadbaqeri/dcon/actions/workflows/release.yml)
2. Verify the release tag exists: `git tag -l`
3. Manually trigger if needed

## 📝 Conventional Commits

Use these commit message prefixes to trigger releases:

- `feat:` - New feature (minor version bump)
- `fix:` - Bug fix (patch version bump)
- `perf:` - Performance improvement (patch version bump)
- `BREAKING CHANGE:` - Breaking change (major version bump)
- `docs:`, `style:`, `test:`, `chore:` - No release

### Examples:
```bash
git commit -m "feat: add connection pooling support"
git commit -m "fix: resolve connection timeout issues"
git commit -m "feat!: redesign CLI interface

BREAKING CHANGE: Command structure has changed"
```

## 🔐 Required Secrets

Ensure these secrets are configured in your GitHub repository:

- `SEMANTIC_RELEASE_TOKEN` - GitHub token with repo permissions
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

## 🎯 Installation Script Integration

The installation scripts automatically:
1. Detect user's OS and architecture
2. Download the correct binary from GitHub releases
3. Install to `~/.local/bin` (Unix) or `%USERPROFILE%\.local\bin` (Windows)
4. Update PATH environment variable
5. Verify installation

### Installation Commands:
```bash
# macOS & Linux
curl -sSL https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install-oneliner.sh | bash

# Windows PowerShell
iwr -useb https://raw.githubusercontent.com/emadbaqeri/dcon/main/scripts/install.ps1 | iex
```

## 🚀 Next Release Process

For your next release, simply:

1. Make your changes with conventional commit messages
2. Push to main branch
3. Semantic-release will automatically:
   - Create the GitHub release
   - Trigger binary builds
   - Upload binaries as release assets
4. Users can immediately install using the installation scripts

## 📊 Monitoring

Monitor the release process:
- [All Actions](https://github.com/emadbaqeri/dcon/actions)
- [Releases](https://github.com/emadbaqeri/dcon/releases)
- [Latest Release](https://github.com/emadbaqeri/dcon/releases/latest)
