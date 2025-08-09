# Contributing to dcon

Thank you for your interest in contributing to dcon! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites

- Rust 1.70 or higher
- Git
- PostgreSQL server for testing (optional, can use Docker)

### Setting up the Development Environment

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/yourusername/dcon.git
   cd dcon
   ```

3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/emadbaqeri/dcon.git
   ```

4. Install dependencies and build:
   ```bash
   cargo build
   ```

5. **Set up Git hooks (Important!)**:
   ```bash
   ./scripts/install-git-hooks.sh install
   ./scripts/setup-git-hooks.sh
   ```

6. Run tests:
   ```bash
   cargo test
   ```

## 📝 Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and changelog generation.

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to the build process or auxiliary tools
- **ci**: Changes to CI configuration files and scripts
- **build**: Changes that affect the build system or external dependencies
- **revert**: Reverts a previous commit

### Examples

```bash
feat: add support for connection pooling
fix: resolve memory leak in query execution
docs: update installation instructions
feat!: change CLI argument structure (breaking change)
fix(auth): handle expired tokens correctly
```

### Setting up Commit Template

To use the provided commit message template:

```bash
git config commit.template .gitmessage
```

## 🔄 Development Workflow

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards

3. **Test your changes** (Git hooks will run automatically, but you can test manually):
   ```bash
   cargo test
   cargo clippy
   cargo fmt

   # Test Git hooks manually
   .git/hooks/pre-commit
   .git/hooks/pre-push origin main
   ```

4. **Commit your changes** using conventional commits:
   ```bash
   git add .
   git commit -m "feat: add your new feature"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request** on GitHub

## 🧪 Testing

### Running Tests

```bash
# Run all tests
cargo test

# Run tests with output
cargo test -- --nocapture

# Run specific test
cargo test test_name
```

### Test Database Setup

For integration tests, you can use the provided database setup script:

```bash
./scripts/create_seed_db.sh
```

This creates test databases with sample data.

## 📋 Code Style

This project uses standard Rust formatting and linting tools:

### Formatting

```bash
cargo fmt
```

### Linting

```bash
cargo clippy -- -D warnings
```

### Code Guidelines

- Follow Rust naming conventions
- Add documentation for public APIs
- Include tests for new functionality
- Keep functions focused and small
- Use meaningful variable and function names

## 🪝 Git Hooks

This project uses Git hooks to maintain code quality automatically. The hooks are designed to catch issues early and ensure consistent code standards.

### Automatic Setup

After cloning the repository, set up the Git hooks:

```bash
./scripts/install-git-hooks.sh install
./scripts/setup-git-hooks.sh
```

### Hook Details

#### Pre-commit Hook
Runs before each commit and checks:
- **Code formatting**: `cargo fmt --check`
- **Linting**: `cargo clippy` with strict settings
- **Compilation**: `cargo check --all-targets --all-features`
- **Semantic versioning**: Validates version format in Cargo.toml
- **Documentation coverage**: Warns about missing docs

#### Pre-push Hook
Runs before each push and performs:
- **Full test suite**: `cargo test --all-features`
- **Documentation tests**: `cargo test --doc`
- **Benchmark compilation**: Ensures benchmarks compile
- **TODO/FIXME check**: Warns about TODO comments in main branch
- **Security audit**: Runs `cargo audit` if available

### Bypassing Hooks

In emergency situations, you can bypass the hooks:

```bash
# Skip pre-commit checks
git commit --no-verify

# Skip pre-push checks
git push --no-verify
```

**Note**: Use `--no-verify` sparingly and only in genuine emergencies. The hooks are there to maintain code quality.

### Manual Testing

You can run the hooks manually to test your changes:

```bash
# Test pre-commit hook
.git/hooks/pre-commit

# Test pre-push hook
.git/hooks/pre-push origin main

# Run additional quality checks
.git/hooks/quality-checks.sh
```

### Troubleshooting Hooks

If hooks fail, common solutions include:

1. **Formatting issues**: Run `cargo fmt`
2. **Clippy warnings**: Fix the warnings shown in the output
3. **Compilation errors**: Fix the errors shown by `cargo check`
4. **Test failures**: Fix failing tests with `cargo test`
5. **Missing tools**: Install with `rustup component add clippy rustfmt`

## 🐛 Reporting Issues

When reporting issues, please include:

1. **Environment information**:
   - Operating system
   - Rust version (`rustc --version`)
   - dcon version

2. **Steps to reproduce** the issue

3. **Expected behavior**

4. **Actual behavior**

5. **Error messages** (if any)

6. **Sample data** or configuration (if relevant)

## 💡 Feature Requests

Feature requests are welcome! Please:

1. Check if the feature already exists or is planned
2. Describe the use case and benefits
3. Provide examples of how it would work
4. Consider implementation complexity

## 📦 Release Process

This project uses automated releases with semantic versioning:

1. **Commits** following conventional commit format trigger releases
2. **Semantic Release** automatically determines version bumps
3. **GitHub Actions** builds and publishes releases
4. **Changelogs** are automatically generated

### Version Bumping

- `fix:` → patch release (0.0.X)
- `feat:` → minor release (0.X.0)
- `feat!:` or `BREAKING CHANGE:` → major release (X.0.0)

## 🏷️ Labels

We use the following labels for issues and PRs:

- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Improvements or additions to documentation
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed
- `question` - Further information is requested

## 📄 License

By contributing to dcon, you agree that your contributions will be licensed under the MIT License.

## 🙏 Recognition

Contributors will be recognized in:
- The project's README
- Release notes for their contributions
- GitHub's contributor graph

Thank you for contributing to dcon! 🎉
