# Development Guide

This document provides comprehensive instructions for setting up and working with the Fasten development environment.

## Quick Start

### Prerequisites

- **Zig 0.11.0 or later** - [Download here](https://ziglang.org/download/)
- **Git** for version control
- **A text editor or IDE** (VS Code, Vim, Emacs, etc.)

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/ferg-cod3s/fasten.git
cd fasten

# Build the project
zig build

# Run tests
zig build test

# Run the bundler
./zig-out/bin/fasten --help
```

## Development Environment

### Zig Installation

#### macOS
```bash
# Using Homebrew
brew install zig

# Or download directly from ziglang.org
curl -L https://ziglang.org/download/0.11.0/zig-macos-x86_64-0.11.0.tar.xz | tar -xJ
export PATH=$PATH:$(pwd)/zig-macos-x86_64-0.11.0
```

#### Linux
```bash
# Download and extract
wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
tar -xf zig-linux-x86_64-0.11.0.tar.xz
export PATH=$PATH:$(pwd)/zig-linux-x86_64-0.11.0
```

#### Windows
```powershell
# Download from ziglang.org and add to PATH
# Or use Chocolatey
choco install zig
```

### Editor Setup

#### VS Code
Install the Zig extension for syntax highlighting and language support:
```bash
code --install-extension ziglang.vscode-zig
```

Recommended VS Code settings (`.vscode/settings.json`):
```json
{
    "zig.path": "zig",
    "zig.zls.path": "zls",
    "editor.formatOnSave": true,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true
}
```

#### Vim/Neovim
Add Zig support with vim-zig:
```vim
" Using vim-plug
Plug 'ziglang/zig.vim'

" Or using packer.nvim
use 'ziglang/zig.vim'
```

## Project Structure

```
fasten/
├── src/                    # Source code
│   ├── main.zig           # CLI entry point
│   ├── lexer/             # Lexical analysis
│   ├── parser/            # Syntax analysis
│   ├── analyzer/          # Semantic analysis
│   ├── optimizer/         # Code optimization
│   ├── codegen/           # Code generation
│   └── utils/             # Utility functions
├── tests/                 # Test files
├── benchmarks/            # Performance benchmarks
├── examples/              # Example JavaScript files
├── docs/                  # Documentation
├── build.zig              # Build configuration
├── README.md              # Project overview
├── CONTRIBUTING.md        # Contribution guidelines
├── CODE_STYLE.md          # Code style guide
├── SECURITY.md            # Security policy
├── PERFORMANCE.md         # Performance guidelines
└── DEVELOPMENT.md         # This file
```

## Build System

### Build Commands

```bash
# Standard build
zig build

# Debug build (with debug symbols)
zig build -Doptimize=Debug

# Release build (optimized)
zig build -Doptimize=ReleaseFast

# Safe release build (with safety checks)
zig build -Doptimize=ReleaseSafe

# Small release build (optimized for size)
zig build -Doptimize=ReleaseSmall
```

### Build Options

The `build.zig` file supports several options:

```bash
# Enable/disable features
zig build -Denable-benchmarks=true
zig build -Denable-profiling=true

# Set target platform
zig build -Dtarget=x86_64-linux
zig build -Dtarget=aarch64-macos
```

### Custom Build Targets

```bash
# Run tests
zig build test

# Run benchmarks
zig build bench

# Generate documentation
zig build docs

# Install to system
zig build install

# Clean build artifacts
zig build clean
```

## Testing

### Running Tests

```bash
# Run all tests
zig build test

# Run specific test file
zig test src/lexer/tokenizer.zig

# Run tests with verbose output
zig build test -- --verbose

# Run tests with memory leak detection
zig build test -Dtest-leak-detection=true
```

### Test Organization

Tests are organized into several categories:

1. **Unit Tests**: Test individual functions and modules
2. **Integration Tests**: Test component interactions
3. **Performance Tests**: Benchmark critical paths
4. **Regression Tests**: Prevent known issues from reoccurring

### Writing Tests

```zig
const std = @import("std");
const testing = std.testing;
const tokenize = @import("../lexer/tokenizer.zig").tokenize;

test "tokenize should handle empty input" {
    const allocator = testing.allocator;
    const tokens = try tokenize(allocator, "");
    defer allocator.free(tokens);
    
    try testing.expect(tokens.len == 0);
}

test "tokenize should handle simple identifier" {
    const allocator = testing.allocator;
    const tokens = try tokenize(allocator, "hello");
    defer allocator.free(tokens);
    
    try testing.expect(tokens.len == 1);
    try testing.expectEqualStrings("hello", tokens[0].lexeme);
}
```

## Debugging

### Debug Builds

```bash
# Build with debug information
zig build -Doptimize=Debug

# Run with debugger
gdb ./zig-out/bin/fasten
lldb ./zig-out/bin/fasten
```

### Logging

Use Zig's built-in logging:

```zig
const std = @import("std");

pub fn main() !void {
    std.log.info("Starting Fasten bundler", .{});
    std.log.debug("Processing file: {s}", .{filename});
    std.log.warn("Large file detected: {}KB", .{size_kb});
    std.log.err("Failed to parse: {}", .{err});
}
```

### Memory Debugging

```bash
# Build with memory safety checks
zig build -Doptimize=Debug -Dsafety=true

# Use Valgrind (Linux)
valgrind --leak-check=full ./zig-out/bin/fasten input.js

# Use AddressSanitizer
zig build -Doptimize=Debug -Dsanitize-thread=true
```

## Performance Profiling

### Built-in Profiling

```bash
# Build with profiling enabled
zig build -Denable-profiling=true

# Run with profiling
./zig-out/bin/fasten input.js --profile
```

### External Profilers

#### Linux (perf)
```bash
# Record performance data
perf record ./zig-out/bin/fasten input.js

# Analyze results
perf report
```

#### macOS (Instruments)
```bash
# Profile with Instruments
instruments -t "Time Profiler" ./zig-out/bin/fasten input.js
```

### Memory Profiling

```bash
# Build with memory profiling
zig build -Denable-memory-profiling=true

# Use Heaptrack (Linux)
heaptrack ./zig-out/bin/fasten input.js
heaptrack_gui heaptrack.fasten.*.gz
```

## Benchmarking

### Running Benchmarks

```bash
# Run all benchmarks
zig build bench

# Run specific benchmark
zig build bench -- --filter=lexer

# Run benchmarks with detailed output
zig build bench -- --verbose

# Save benchmark results
zig build bench -- --output=benchmark-results.json
```

### Creating Benchmarks

```zig
const std = @import("std");
const benchmark = @import("../utils/benchmark.zig");

test "benchmark tokenization" {
    const allocator = std.testing.allocator;
    
    const source = try generateLargeJavaScript(allocator, 100_000);
    defer allocator.free(source);
    
    const result = try benchmark.run(
        allocator,
        "tokenization",
        tokenize,
        .{ allocator, source },
    );
    
    std.log.info("Tokenization: {d:.2} MB/s", .{
        result.throughput_mb_per_sec
    });
}
```

## Code Quality

### Formatting

```bash
# Format all source files
zig fmt src/

# Format specific file
zig fmt src/main.zig

# Check formatting without modifying
zig fmt --check src/
```

### Linting

```bash
# Check for common issues
zig build check

# Run static analysis
zig build analyze
```

### Documentation

```bash
# Generate documentation
zig build docs

# Serve documentation locally
zig build docs-serve
```

## Continuous Integration

### GitHub Actions

The project uses GitHub Actions for CI/CD:

- **Build**: Compile on multiple platforms
- **Test**: Run all test suites
- **Benchmark**: Performance regression testing
- **Security**: Vulnerability scanning
- **Documentation**: Generate and deploy docs

### Local CI Simulation

```bash
# Run the same checks as CI
./scripts/ci-check.sh

# Or manually:
zig build test
zig build bench
zig fmt --check src/
zig build -Doptimize=ReleaseFast
```

## Release Process

### Version Management

1. Update version in `build.zig`
2. Update `CHANGELOG.md`
3. Create git tag: `git tag v0.1.0`
4. Push tag: `git push origin v0.1.0`

### Building Releases

```bash
# Build release binaries for all targets
zig build release

# Build for specific target
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseFast

# Create distribution package
zig build package
```

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clean and rebuild
zig build clean
zig build

# Check Zig version
zig version

# Update Zig if needed
```

#### Test Failures
```bash
# Run tests with verbose output
zig build test -- --verbose

# Run specific failing test
zig test src/path/to/test.zig
```

#### Performance Issues
```bash
# Profile the application
zig build -Denable-profiling=true
./zig-out/bin/fasten input.js --profile

# Check for memory leaks
zig build test -Dtest-leak-detection=true
```

### Getting Help

- **Documentation**: Check the `docs/` directory
- **Issues**: Search existing GitHub issues
- **Discussions**: Use GitHub discussions for questions
- **Code Review**: Submit a draft PR for feedback

## Development Workflow

### Feature Development

1. **Create Branch**: `git checkout -b feature/new-feature`
2. **Write Tests**: Add tests for new functionality
3. **Implement**: Write the feature code
4. **Test**: Ensure all tests pass
5. **Benchmark**: Check performance impact
6. **Document**: Update relevant documentation
7. **Submit PR**: Create pull request for review

### Bug Fixes

1. **Reproduce**: Create a test that reproduces the bug
2. **Fix**: Implement the fix
3. **Verify**: Ensure the test now passes
4. **Regression Test**: Add test to prevent future regressions
5. **Submit PR**: Create pull request with fix

### Code Review Process

1. **Self Review**: Review your own code first
2. **Automated Checks**: Ensure CI passes
3. **Peer Review**: Get review from maintainers
4. **Address Feedback**: Make requested changes
5. **Merge**: Maintainer merges approved PR

---

This development guide should help you get started with contributing to Fasten. For more specific guidelines, see the other documentation files in this repository. 