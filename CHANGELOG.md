## [2.1.1](https://github.com/emadbaqeri/dcon/compare/v2.1.0...v2.1.1) (2025-08-10)

### 🐛 Bug Fixes

* **install:** resolve shell detection issue causing "command not found" on macOS/zsh ([18252ca](https://github.com/emadbaqeri/dcon/commit/18252ca2a2e25cd6db167738270ba9e40c598c20))

## [2.1.0](https://github.com/emadbaqeri/dcon/compare/v2.0.4...v2.1.0) (2025-08-10)

### 🚀 Features

* **install:** make dcon command immediately available after installation ([08e4a5a](https://github.com/emadbaqeri/dcon/commit/08e4a5a85cc49eb2be959a59b9cd0feabe3fe2b2))

## [2.0.4](https://github.com/emadbaqeri/dcon/compare/v2.0.3...v2.0.4) (2025-08-10)

### 🐛 Bug Fixes

* correct binary name and version reporting ([bccb591](https://github.com/emadbaqeri/dcon/commit/bccb591244fe56558c4ff7eed1a71444a7319d43))

## [2.0.3](https://github.com/emadbaqeri/dcon/compare/v2.0.2...v2.0.3) (2025-08-09)

### 🐛 Bug Fixes

* **ci:** use target-specific strip commands for cross-compiled binaries ([2f2a074](https://github.com/emadbaqeri/dcon/commit/2f2a07403dacfe4177f6b470fc94978af6875f74))

## [2.0.2](https://github.com/emadbaqeri/dcon/compare/v2.0.1...v2.0.2) (2025-08-09)

### 🐛 Bug Fixes

* **ci:** simplify semantic-release configuration and clean up version update script ([e578140](https://github.com/emadbaqeri/dcon/commit/e578140f89a203c9061f6992825b309f7f39c797))

## [2.0.1](https://github.com/emadbaqeri/dcon/compare/v2.0.0...v2.0.1) (2025-08-09)

### 🐛 Bug Fixes

* **ci:** add explicit bash shell to workflow steps to prevent PowerShell parsing errors ([c4972f9](https://github.com/emadbaqeri/dcon/commit/c4972f9dd9ec21dd2e3b8e2f71489ae0e8120503))

## [2.0.0](https://github.com/emadbaqeri/dcon/compare/v1.0.0...v2.0.0) (2025-08-09)

### ⚠ BREAKING CHANGES

* Installation process now uses pre-built binaries instead of requiring Rust toolchain. Users can now install with a single command without needing to build from source.

### 🚀 Features

* add comprehensive cross-platform installation system ([99a5a8d](https://github.com/emadbaqeri/dcon/commit/99a5a8d9306f9305bac8a599bf208a1ed59e7e82))

## 1.0.0 (2025-08-09)

### ⚠ BREAKING CHANGES

* Contributors must now run ./scripts/install-git-hooks.sh
after cloning to enable automatic code quality enforcement.

### 🚀 Features

* add comprehensive CI/CD pipeline and project documentation ([d266d25](https://github.com/emadbaqeri/dcon/commit/d266d253a1d8904ed8659afb01a08910f06b2f1e))
* implement comprehensive Git hooks and fix all code quality issues ([fb23ce6](https://github.com/emadbaqeri/dcon/commit/fb23ce68c7ba0b0601fcb0d936d53f0365040dd6))
* implement comprehensive Git hooks for code quality and testing ([bf2a65f](https://github.com/emadbaqeri/dcon/commit/bf2a65f0de3b3b40853e3fbd34db35ac4ee06ea2))

### 🐛 Bug Fixes

* prevent Cargo.toml corruption during semantic-release version updates ([1d3e03d](https://github.com/emadbaqeri/dcon/commit/1d3e03d3937998e8807e467ea97dcf833137dd18))
* resolve semantic-release dependencies and module not found errors ([c4abdd3](https://github.com/emadbaqeri/dcon/commit/c4abdd3474cfe6f5a2bfd51542285111bfc22251))
* resolve semantic-release npm dependencies and enable GitHub Actions caching ([1a675f9](https://github.com/emadbaqeri/dcon/commit/1a675f9f1dc632b4dc6eb05f9add35af62e849c3))
* update GitHub Actions to use SEMANTIC_RELEASE_TOKEN for proper permissions ([6845850](https://github.com/emadbaqeri/dcon/commit/6845850f24bf21e825b0f8520ae98a1a55e5fbec))

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### 🚀 Features
- Initial release of dcon PostgreSQL CLI tool
- Database connection and management
- Table operations and inspection
- CRUD operations with multiple output formats
- Interactive mode for database exploration
- Cross-platform support (Linux, macOS, Windows)

### 📚 Documentation
- Comprehensive README with usage examples
- MIT license
- Contributing guidelines
- Installation instructions

### 🏗️ Build System
- GitHub Actions CI/CD pipeline
- Automated releases with semantic versioning
- Cross-platform binary builds
- Security auditing
