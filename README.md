# 🐘 dcon - PostgreSQL Database Management Tool

[![Rust](https://img.shields.io/badge/rust-1.70+-orange.svg)](https://www.rust-lang.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![CLI](https://img.shields.io/badge/interface-CLI-blue.svg)]()
[![GUI](https://img.shields.io/badge/interface-GUI-green.svg)]()

A powerful, modern PostgreSQL database management tool built in Rust. **dcon** provides both command-line and graphical interfaces for managing PostgreSQL databases, executing queries, and performing database operations with beautiful formatted output.

## 🎯 Dual Interface Architecture

**dcon** offers two complementary interfaces:

- **🖥️ CLI (Command Line Interface)** - Perfect for automation, scripting, and terminal-based workflows
- **🖱️ GUI (Graphical User Interface)** - Modern desktop application with intuitive visual interface *(coming soon)*

Both interfaces share the same powerful core functionality, allowing you to choose the best tool for your workflow.

## ✨ Features

### 🚀 Core Features
- **Fast & Efficient** - Built with Rust for maximum performance
- **Secure Connections** - Support for various PostgreSQL authentication methods
- **Database Management** - Create, list, and manage databases
- **Table Operations** - Comprehensive table management and inspection
- **CRUD Operations** - Full Create, Read, Update, Delete functionality
- **Custom Queries** - Execute any SQL query with formatted results

### 💻 CLI Features
- **Beautiful Output** - Colored tables, JSON, and CSV formatting
- **Interactive Mode** - REPL-style interface for database exploration
- **Multiple Output Formats** - Table, JSON, and CSV support
- **Rich CLI Experience** - Progress indicators, colored output, and intuitive commands
- **Scriptable** - Perfect for automation and CI/CD pipelines

### 🖥️ GUI Features *(Coming Soon)*
- **Modern Interface** - Built with gpui-rs for native performance
- **Visual Query Builder** - Drag-and-drop query construction
- **Data Visualization** - Charts and graphs for query results
- **Connection Manager** - Save and organize database connections
- **Cross-Platform** - Native applications for macOS, Linux, and Windows

## 🚀 Installation

### 📦 Package Installers (Recommended)

#### macOS
```bash
# Download and install DMG
curl -L -o dcon.dmg https://github.com/emadbaqeri/dcon/releases/latest/download/dcon-2.1.0-macos.dmg
open dcon.dmg
```

#### Linux
```bash
# Ubuntu/Debian - Install DEB package
curl -L -o dcon.deb https://github.com/emadbaqeri/dcon/releases/latest/download/dcon_2.1.0_amd64.deb
sudo dpkg -i dcon.deb

# Or use AppImage (universal)
curl -L -o dcon.AppImage https://github.com/emadbaqeri/dcon/releases/latest/download/dcon-2.1.0-x86_64.AppImage
chmod +x dcon.AppImage
./dcon.AppImage
```

#### Windows
```powershell
# Download and extract ZIP package
Invoke-WebRequest -Uri "https://github.com/emadbaqeri/dcon/releases/latest/download/dcon-2.1.0-windows.zip" -OutFile "dcon.zip"
Expand-Archive -Path "dcon.zip" -DestinationPath "dcon"
cd dcon
.\install.bat
```

### 🔧 Alternative Installation Methods

#### Pre-built Binaries

Download the latest binaries from [GitHub Releases](https://github.com/emadbaqeri/dcon/releases/latest):

- **macOS**: `dcon-x86_64-apple-darwin` (Intel) or `dcon-aarch64-apple-darwin` (Apple Silicon)
- **Linux**: `dcon-x86_64-unknown-linux-gnu` (x86_64) or `dcon-aarch64-unknown-linux-gnu` (ARM64)
- **Windows**: `dcon-x86_64-pc-windows-msvc.exe` (x86_64) or `dcon-aarch64-pc-windows-msvc.exe` (ARM64)

#### Build from Source

```bash
# Clone the repository
git clone https://github.com/emadbaqeri/dcon.git
cd dcon

# Build CLI only
./scripts/build-cli.sh

# Or build all components (when GUI is available)
./scripts/build-all.sh

# Install CLI
./scripts/build-cli.sh --install
cd dcon

# Build the project
cargo build --release

# Install globally (optional)
cargo install --path .
```

For detailed installation instructions, see [INSTALL.md](INSTALL.md).

### Basic Usage

```bash
# Connect to a database
dcon -H localhost -P 5432 -u postgres -d mydb connect

# List all databases
dcon database list

# List tables in a database
dcon table list -d mydb

# Execute a custom query
dcon query -s "SELECT * FROM users LIMIT 10"

# Start interactive mode
dcon interactive -d mydb
```

## 📖 Usage Examples

### Database Operations

```bash
# List all databases
dcon database list

# Create a new database
dcon database create -n "my_new_db" -o postgres

# Drop a database
dcon database drop -n "old_db"

# Show database information
dcon database info -n "mydb"
```

### Table Operations

```bash
# List all tables
dcon table list -d mydb

# Show table structure
dcon table describe -t users -d mydb

# Show table data with pagination
dcon table show -t users -d mydb --limit 20 --offset 0

# Create a new table
dcon table create -t "new_table" -d mydb --columns "id SERIAL PRIMARY KEY, name VARCHAR(100)"
```

### CRUD Operations

```bash
# Insert data
dcon crud create -t users -d mydb --data '{"name": "John Doe", "email": "john@example.com"}'

# Read data with filters
dcon crud read -t users -d mydb --where "age > 25"

# Update records
dcon crud update -t users -d mydb --set '{"status": "active"}' --where "id = 1"

# Delete records
dcon crud delete -t users -d mydb --where "status = 'inactive'"
```

### Interactive Mode

```bash
# Start interactive session
dcon interactive -d mydb

# Inside interactive mode:
# \l          - List databases
# \d          - List tables
# \q or exit  - Quit
# help        - Show help
# Any SQL query will be executed directly
```

## 🔧 Configuration

### Connection Options

```bash
# Using individual parameters
dcon -H localhost -P 5432 -u postgres --password mypass -d mydb [command]

# Using connection URL
dcon --url "postgresql://postgres:mypass@localhost:5432/mydb" [command]

# Environment variables (optional)
export PGHOST=localhost
export PGPORT=5432
export PGUSER=postgres
export PGPASSWORD=mypass
export PGDATABASE=mydb
```

### Output Formats

```bash
# Table format (default)
dcon table list --format table

# JSON format
dcon table list --format json

# CSV format
dcon table list --format csv

# Disable colors
dcon table list --no-color
```

## 🏗️ Project Structure

```
src/
├── main.rs              # Entry point, CLI setup
├── lib.rs               # Library exports
├── cli/
│   ├── mod.rs           # CLI module exports
│   ├── commands.rs      # Command definitions
│   ├── args.rs          # Argument parsing
│   └── output.rs        # Output formatting
├── db/
│   ├── mod.rs           # Database module exports
│   ├── client.rs        # PostgreSQL client wrapper
│   ├── connection.rs    # Connection management
│   └── operations.rs    # CRUD operations
├── models/
│   ├── mod.rs           # Model exports
│   ├── database.rs      # Database-related structs
│   └── table.rs         # Table-related structs
└── utils/
    ├── mod.rs           # Utility exports
    ├── formatter.rs     # Output formatting utilities
    └── error.rs         # Custom error types
```

## 🛠️ Development

### Prerequisites

- Rust 1.70 or higher
- PostgreSQL server for testing

### Building from Source

```bash
# Clone the repository
git clone https://github.com/emadbaqeri/dcon.git
cd dcon

# Set up Git hooks for code quality (recommended for contributors)
./scripts/install-git-hooks.sh install
./scripts/setup-git-hooks.sh

# Run tests
cargo test

# Build in debug mode
cargo build

# Build optimized release
cargo build --release

# Run with cargo
cargo run -- --help
```

### Testing with Sample Data

The project includes a comprehensive database setup script:

```bash
# Set up test databases with sample data
./scripts/create_seed_db.sh

# This creates two databases:
# - food_delivery_db (restaurant/delivery app data)
# - school_management_db (educational institution data)
```

### Git Hooks for Code Quality

This project includes comprehensive Git hooks to maintain code quality and ensure all contributions meet our standards.

#### Automatic Setup (Recommended)

```bash
# After cloning the repository, run:
./scripts/install-git-hooks.sh install
./scripts/setup-git-hooks.sh
```

#### What the Hooks Do

**Pre-commit Hook:**
- ✅ Code formatting check (`cargo fmt --check`)
- ✅ Linting with strict Clippy rules (`cargo clippy`)
- ✅ Compilation check (`cargo check`)
- ✅ Semantic versioning validation
- ✅ Documentation coverage check

**Pre-push Hook:**
- 🧪 Full test suite (`cargo test`)
- 📚 Documentation tests (`cargo test --doc`)
- 🏃 Benchmark compilation check
- 🔍 TODO/FIXME detection (main branch)
- 🔒 Security audit (if `cargo-audit` installed)

#### Emergency Bypass

In emergency situations, you can bypass the hooks:

```bash
git commit --no-verify    # Skip pre-commit checks
git push --no-verify      # Skip pre-push checks
```

#### Manual Hook Testing

```bash
# Test pre-commit hook
.git/hooks/pre-commit

# Test pre-push hook
.git/hooks/pre-push origin main

# Run quality checks
.git/hooks/quality-checks.sh
```

## 📚 Commands Reference

### Global Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--host` | `-H` | Database host | localhost |
| `--port` | `-P` | Database port | 5432 |
| `--user` | `-u` | Username | postgres |
| `--password` | | Password (prompts if not provided) | |
| `--database` | `-d` | Database name | postgres |
| `--url` | | Full connection URL | |
| `--format` | | Output format (table/json/csv) | table |
| `--no-color` | | Disable colored output | false |

### Available Commands

| Command | Description |
|---------|-------------|
| `connect` | Test database connection |
| `database` | Database management operations |
| `table` | Table operations and management |
| `crud` | Create, Read, Update, Delete operations |
| `query` | Execute custom SQL queries |
| `interactive` | Start interactive mode |

## 🏗️ Project Architecture

**dcon** is built with a modular architecture that supports both CLI and GUI interfaces:

```
dcon/
├── crates/
│   ├── dcon-core/          # Shared core library
│   │   ├── src/
│   │   │   ├── connection.rs    # PostgreSQL connection management
│   │   │   ├── database.rs      # Database operations trait
│   │   │   ├── models/          # Data models and types
│   │   │   ├── query.rs         # Query building and execution
│   │   │   └── error.rs         # Error handling
│   │   └── Cargo.toml
│   ├── dcon-cli/           # Command-line interface
│   │   ├── src/
│   │   │   ├── cli/            # CLI argument parsing
│   │   │   ├── commands.rs     # Command implementations
│   │   │   ├── output.rs       # Output formatting
│   │   │   └── main.rs
│   │   └── Cargo.toml
│   └── dcon-gui/           # Graphical user interface (coming soon)
│       ├── src/
│       │   ├── app.rs          # Main application state
│       │   ├── ui/             # UI components
│       │   └── main.rs
│       └── Cargo.toml
├── scripts/                # Build and packaging scripts
├── packaging/              # Platform-specific packaging
└── Cargo.toml             # Workspace configuration
```

### Design Principles

- **Shared Core**: All database logic is in `dcon-core` to avoid duplication
- **Interface Separation**: CLI and GUI are separate binaries with their own UX patterns
- **Modular Design**: Each component has clear responsibilities and boundaries
- **Cross-Platform**: Native packaging for macOS, Linux, and Windows

## 🤝 Contributing

Contributions are welcome! We follow [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and changelog generation.

### Quick Start for Contributors

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following our [Contributing Guidelines](CONTRIBUTING.md)
4. Use conventional commits (`git commit -m 'feat: add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Commit Convention

We use conventional commits for automated releases:

- `feat:` - New features (minor version bump)
- `fix:` - Bug fixes (patch version bump)
- `feat!:` or `BREAKING CHANGE:` - Breaking changes (major version bump)
- `docs:`, `style:`, `refactor:`, `test:`, `chore:` - Other changes

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🏷️ Releases

This project uses automated semantic versioning:

- **Automated releases** triggered by conventional commits
- **Cross-platform binaries** built for Linux, macOS, and Windows
- **Changelog generation** from commit messages
- **GitHub Releases** with downloadable assets

### Download Latest Release

Visit the [Releases page](https://github.com/emadbaqeri/dcon/releases) to download pre-built binaries for your platform.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Rust](https://www.rust-lang.org/) 🦀
- PostgreSQL client powered by [tokio-postgres](https://github.com/sfackler/rust-postgres)
- CLI framework by [clap](https://github.com/clap-rs/clap)
- Beautiful tables with [tabled](https://github.com/zhiburt/tabled)
- Colored output via [colored](https://github.com/mackwic/colored)

---

<div align="center">
  <strong>Made with ❤️ and Rust</strong>
</div>
