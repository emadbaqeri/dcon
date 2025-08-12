# 🛠️ dcon Development Guide

This guide covers development setup, architecture, and contribution guidelines for **dcon**.

## 🚀 Quick Start

### Prerequisites

- **Rust 1.70+** - [Install via rustup](https://rustup.rs/)
- **Git** - Version control
- **PostgreSQL** - For testing (optional, can use Docker)

### Setup

```bash
# Clone the repository
git clone https://github.com/emadbaqeri/dcon.git
cd dcon

# Build the project
cargo build

# Run tests
cargo test --workspace

# Run CLI in development
cargo run -p dcon -- --help
```

### Development Database (Optional)

```bash
# Using Docker
docker run --name dcon-dev-db -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres:15

# Or install PostgreSQL locally
# macOS: brew install postgresql
# Ubuntu: sudo apt-get install postgresql
```

## 🏗️ Project Architecture

### Workspace Structure

```
dcon/
├── crates/
│   ├── dcon-core/          # 📚 Shared core library
│   ├── dcon-cli/           # 💻 Command-line interface
│   └── dcon-gui/           # 🖥️ Graphical interface (WIP)
├── scripts/                # 🔧 Build and utility scripts
├── packaging/              # 📦 Platform-specific packaging
├── docs/                   # 📖 Documentation
└── .github/workflows/      # 🚀 CI/CD workflows
```

### Core Library (`dcon-core`)

The heart of dcon, containing all database logic:

- **`connection.rs`** - PostgreSQL connection management
- **`database.rs`** - Database operations trait and implementations
- **`models/`** - Data structures and types
- **`query.rs`** - Query building and execution
- **`error.rs`** - Error handling and types

### CLI (`dcon-cli`)

Command-line interface implementation:

- **`cli/`** - Argument parsing with clap
- **`commands.rs`** - Command implementations
- **`output.rs`** - Formatted output (tables, JSON, CSV)
- **`main.rs`** - Entry point and CLI orchestration

### GUI (`dcon-gui`) - Work in Progress

Graphical interface using gpui-rs:

- **`app.rs`** - Main application state
- **`ui/`** - UI components and panels
- **`state.rs`** - Application state management

## 🔧 Development Workflow

### Building

```bash
# Build everything
cargo build --workspace

# Build specific components
cargo build -p dcon-core
cargo build -p dcon
cargo build -p dcon-gui  # Currently has compilation issues

# Release builds
cargo build --release --workspace
```

### Testing

```bash
# Run all tests
cargo test --workspace

# Run specific crate tests
cargo test -p dcon-core
cargo test -p dcon

# Run with output
cargo test --workspace -- --nocapture

# Run specific test
cargo test -p dcon-core connection_tests
```

### Code Quality

```bash
# Format code
cargo fmt --all

# Run clippy
cargo clippy --workspace --all-targets -- -D warnings

# Check for security vulnerabilities
cargo audit
```

### Running in Development

```bash
# Run CLI with arguments
cargo run -p dcon -- connect --host localhost --user postgres

# Run with environment variables
DCON_HOST=localhost DCON_USER=postgres cargo run -p dcon -- database list

# Run in interactive mode
cargo run -p dcon -- interactive
```

## 🧪 Testing Strategy

### Unit Tests

Located alongside source code in each module:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_connection_config() {
        // Test implementation
    }
}
```

### Integration Tests

Located in `tests/` directories:

```bash
# Run integration tests
cargo test --test integration_tests
```

### Manual Testing

Use the development database:

```bash
# Test connection
cargo run -p dcon -- connect --host localhost --user postgres --password password

# Test database operations
cargo run -p dcon -- database list --host localhost --user postgres --password password
```

## 📦 Building Packages

### Local Packaging

```bash
# Build CLI package
./scripts/build-cli.sh

# Build all packages for current platform
./scripts/package-all.sh

# Platform-specific packaging
./packaging/macos/build-dmg.sh      # macOS DMG
./packaging/linux/build-deb.sh     # Linux DEB
./packaging/linux/build-appimage.sh # Linux AppImage
```

### Cross-Platform Builds

```bash
# Add targets
rustup target add x86_64-pc-windows-msvc
rustup target add aarch64-apple-darwin

# Build for specific target
cargo build --release --target x86_64-pc-windows-msvc -p dcon
```

## 🤝 Contributing

### Code Style

- Follow Rust standard formatting (`cargo fmt`)
- Use meaningful variable and function names
- Add documentation for public APIs
- Write tests for new functionality

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new database connection pooling
fix: resolve connection timeout issue
docs: update installation guide
test: add integration tests for CRUD operations
```

### Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feat/amazing-feature`
3. **Make** your changes with tests
4. **Ensure** all tests pass: `cargo test --workspace`
5. **Format** code: `cargo fmt --all`
6. **Check** with clippy: `cargo clippy --workspace --all-targets -- -D warnings`
7. **Commit** with conventional commit messages
8. **Push** to your fork: `git push origin feat/amazing-feature`
9. **Create** a Pull Request

### Adding New Features

#### CLI Commands

1. Add command definition in `crates/dcon-cli/src/cli/types.rs`
2. Implement command logic in `crates/dcon-cli/src/commands.rs`
3. Add tests in `crates/dcon-cli/tests/`
4. Update documentation

#### Core Functionality

1. Add functionality to `crates/dcon-core/src/`
2. Update the `DatabaseOperations` trait if needed
3. Add comprehensive tests
4. Update both CLI and GUI to use new functionality

## 🐛 Debugging

### Logging

Enable debug logging:

```bash
RUST_LOG=debug cargo run -p dcon -- your-command
RUST_LOG=dcon_core=trace cargo run -p dcon -- your-command
```

### Database Debugging

```bash
# Enable PostgreSQL query logging
RUST_LOG=sqlx=debug cargo run -p dcon -- your-command
```

### Common Issues

**Build Failures:**
- Ensure Rust version is 1.70+
- Clear cargo cache: `cargo clean`
- Update dependencies: `cargo update`

**Test Failures:**
- Ensure PostgreSQL is running for integration tests
- Check database credentials and permissions

**GUI Compilation Issues:**
- GUI is currently disabled due to GPUI API changes
- Focus on CLI development for now

## 📚 Resources

- [Rust Book](https://doc.rust-lang.org/book/)
- [Cargo Book](https://doc.rust-lang.org/cargo/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Tokio-Postgres Docs](https://docs.rs/tokio-postgres/)
- [Clap Documentation](https://docs.rs/clap/)

## 🎯 Roadmap

### Short Term
- [ ] Fix GUI compilation issues with latest GPUI
- [ ] Add connection pooling
- [ ] Implement configuration file support
- [ ] Add more output formats (XML, YAML)

### Long Term
- [ ] Complete GUI implementation
- [ ] Add support for other databases (MySQL, SQLite)
- [ ] Plugin system for custom commands
- [ ] Web interface option

## 💬 Getting Help

- **Issues**: [GitHub Issues](https://github.com/emadbaqeri/dcon/issues)
- **Discussions**: [GitHub Discussions](https://github.com/emadbaqeri/dcon/discussions)
- **Email**: hey@emaaad.com

Happy coding! 🚀
