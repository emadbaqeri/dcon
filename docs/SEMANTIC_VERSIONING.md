# 📋 Semantic Versioning Guide

This document explains how semantic versioning works in the dcon project and how to use conventional commits to trigger the correct version bumps.

## 🎯 Current Status

- **Current Version**: 2.0.0
- **Semantic-Release**: ✅ Properly configured
- **Version Synchronization**: ✅ All files synchronized

## 📈 Version Bumping Rules

### Patch Releases (X.Y.Z → X.Y.Z+1)
**For bug fixes and small improvements**

```bash
git commit -m "fix: resolve connection timeout issues"
git commit -m "fix: handle null values in query results"
git commit -m "perf: optimize database connection pooling"
```

**Result**: 2.0.0 → 2.0.1 → 2.0.2 → 2.0.3

### Minor Releases (X.Y.Z → X.Y+1.0)
**For new features that don't break existing functionality**

```bash
git commit -m "feat: add query history feature"
git commit -m "feat: implement connection profiles"
git commit -m "feat: add CSV export functionality"
```

**Result**: 2.0.3 → 2.1.0 → 2.2.0 → 2.3.0

### Major Releases (X.Y.Z → X+1.0.0)
**For breaking changes that affect existing users**

#### Method 1: Using `feat!` with BREAKING CHANGE footer
```bash
git commit -m "feat!: redesign CLI interface

BREAKING CHANGE: Command structure has changed. Use 'dcon connect' instead of 'dcon -c'"
```

#### Method 2: Any commit type with BREAKING CHANGE footer
```bash
git commit -m "refactor: simplify configuration format

BREAKING CHANGE: Configuration file format has changed from TOML to JSON"
```

**Result**: 2.3.0 → 3.0.0

### No Release
**For changes that don't affect end users**

```bash
git commit -m "docs: update installation guide"
git commit -m "test: add unit tests for connection module"
git commit -m "chore: update dependencies"
git commit -m "ci: improve GitHub Actions workflow"
git commit -m "style: fix code formatting"
```

**Result**: No version bump, no release created

## 🔍 How It Works

### 1. Commit Analysis
When you push to `main`, semantic-release:
1. Analyzes all commits since the last release
2. Determines the highest version bump needed
3. Creates a new release with the appropriate version

### 2. Breaking Change Detection
Breaking changes are detected by:
- `!` after the commit type: `feat!:`, `fix!:`, etc.
- `BREAKING CHANGE:` footer in the commit message
- `BREAKING CHANGES:` footer in the commit message

### 3. Version Update Process
1. Semantic-release determines the new version
2. Runs `./scripts/update-version.sh ${nextRelease.version}`
3. Updates `Cargo.toml` with the new version
4. Commits the changes with `chore(release): X.Y.Z [skip ci]`
5. Creates a git tag `vX.Y.Z`
6. Triggers the binary build workflow

## 📝 Best Practices

### Writing Good Commit Messages
```bash
# Good examples
git commit -m "feat: add connection pooling support"
git commit -m "fix: resolve memory leak in query execution"
git commit -m "docs: add troubleshooting section to README"

# Bad examples (avoid these)
git commit -m "update stuff"
git commit -m "fix bug"
git commit -m "add feature"
```

### When to Use Breaking Changes
Only use `BREAKING CHANGE:` when:
- Changing CLI command structure
- Removing or renaming configuration options
- Changing output formats in incompatible ways
- Removing public API functions

### Testing Before Release
```bash
# Test your changes locally
cargo test --all-features
cargo clippy --all-targets --all-features

# Use conventional commit messages
git commit -m "feat: add your new feature"
git push origin main
```

## 🛠️ Troubleshooting

### "Wrong version bump"
If semantic-release creates the wrong version bump:
1. Check your commit messages for unintended `BREAKING CHANGE:` footers
2. Verify the commit type matches your intention
3. Review the [conventional commits specification](https://www.conventionalcommits.org/)

### "No release created"
If no release is created when you expect one:
1. Ensure your commit type triggers a release (`feat`, `fix`, `perf`, `revert`, `refactor`)
2. Check that commits aren't marked with `[skip ci]`
3. Verify the semantic-release workflow ran successfully

### "Version not updated in Cargo.toml"
If the version isn't updated:
1. Check the `scripts/update-version.sh` script logs
2. Verify the script has proper permissions
3. Ensure `Cargo.toml` syntax is valid

## 🔧 Testing Configuration

Run the test script to verify your setup:
```bash
./scripts/test-semantic-release.sh
```

For full testing with GitHub integration:
```bash
export GITHUB_TOKEN=your_github_token
./scripts/test-semantic-release.sh
```

## 📊 Monitoring Releases

- **All Releases**: https://github.com/emadbaqeri/dcon/releases
- **Workflow Runs**: https://github.com/emadbaqeri/dcon/actions/workflows/semantic-release.yml
- **Latest Release**: https://github.com/emadbaqeri/dcon/releases/latest
