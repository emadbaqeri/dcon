# Git Hooks for dcon

This directory contains Git hooks that automatically enforce code quality standards for the dcon project.

## Quick Setup

After cloning the repository, run:

```bash
./scripts/install-git-hooks.sh install
./scripts/setup-git-hooks.sh
```

## Hooks Overview

### Pre-commit Hook (`pre-commit`)
Runs before each commit to ensure code quality:
- ✅ **Code formatting**: `cargo fmt --check`
- ✅ **Linting**: `cargo clippy` with strict settings
- ✅ **Compilation**: `cargo check --all-targets --all-features`
- ✅ **Semantic versioning**: Validates version format in Cargo.toml
- ✅ **Documentation coverage**: Warns about missing docs

### Pre-push Hook (`pre-push`)
Runs before each push to ensure comprehensive testing:
- 🧪 **Full test suite**: `cargo test --all-features`
- 📚 **Documentation tests**: `cargo test --doc`
- 🏃 **Benchmark compilation**: Ensures benchmarks compile
- 🔍 **TODO/FIXME detection**: Warns about TODO comments in main branch
- 🔒 **Security audit**: Runs `cargo audit` if available

### Quality Checks Script (`quality-checks.sh`)
Shared utility script with additional quality checks:
- Semantic versioning validation
- Cargo.toml completeness check
- Documentation coverage analysis
- TODO/FIXME comment detection
- Security vulnerability scanning

## Manual Testing

You can run the hooks manually:

```bash
# Test pre-commit hook
.git/hooks/pre-commit

# Test pre-push hook
.git/hooks/pre-push origin main

# Run quality checks
.git/hooks/quality-checks.sh
```

## Bypassing Hooks

In emergency situations, you can bypass the hooks:

```bash
git commit --no-verify    # Skip pre-commit checks
git push --no-verify      # Skip pre-push checks
```

**Note**: Use `--no-verify` sparingly and only in genuine emergencies.

## Troubleshooting

### Common Issues

1. **Formatting errors**: Run `cargo fmt` to fix
2. **Clippy warnings**: Address the specific warnings shown
3. **Compilation errors**: Fix errors shown by `cargo check`
4. **Test failures**: Fix failing tests with `cargo test`
5. **Missing tools**: Install with `rustup component add clippy rustfmt`

### Hook Installation Issues

If hooks aren't working:

1. Ensure you're in the project root directory
2. Run `./scripts/setup-git-hooks.sh` to verify installation
3. Check that hooks are executable: `ls -la .git/hooks/`
4. Verify Rust toolchain: `cargo --version`

## Customization

The hooks are designed to be robust and work across different environments:
- Compatible with macOS, Linux, and Windows (via Git Bash)
- Gracefully handles missing optional tools (like `timeout`)
- Provides clear error messages and suggestions
- Allows emergency bypassing when needed

## Contributing

When modifying hooks:

1. Edit the hooks in `.git/hooks/`
2. Test thoroughly with `./scripts/setup-git-hooks.sh`
3. Export to tracked directory: `./scripts/install-git-hooks.sh export`
4. Commit the changes to share with other contributors
