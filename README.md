# Fasten ⚡

A high-performance JavaScript bundler written in Zig - Fast ES Module bundling with deep insights into the build process.

## Overview

Fasten is a lightweight, lightning-fast JavaScript bundler built entirely in Zig. It focuses on modern ES Modules bundling with exceptional performance and minimal resource consumption. Unlike traditional bundlers, Fasten provides deep insights into the JavaScript build process while maintaining simplicity and speed.

## Features

- 🚀 **High Performance**: Built in Zig for maximum speed and minimal memory usage
- 📦 **ES Modules Focus**: First-class support for modern ES Module syntax
- 🪶 **Lightweight**: Minimal resource consumption and fast startup times
- 🔍 **Educational**: Clear insights into JavaScript parsing and optimization
- ⚙️ **Simple Configuration**: Straightforward CLI interface with minimal setup

## Goals

- Bundle ES Modules (import/export) into optimized JavaScript
- Achieve significantly faster bundling speeds than traditional bundlers
- Provide educational value for understanding build processes
- Maintain simplicity while delivering powerful performance

## Installation

### Prerequisites

- [Zig](https://ziglang.org/download/) 0.11.0 or later

### Building from Source

```bash
git clone https://github.com/ferg-cod3s/fasten.git
cd fasten
zig build
```

### Running
```bash
# Basic usage
./zig-out/bin/fasten input.js -o output.js

# With optimization
./zig-out/bin/fasten input.js -o output.js --minify
```

### Usage
```bash
fasten [input-file] [options]

Options:
  -o, --output <file>    Output file path (default: bundle.js)
  --minify              Enable minification (whitespace and comment removal)
  --help                Show this help message
  --version             Show version information
```

### Current Status

🚧 This project is in early development.

### Implemented Features

[] CLI interface

[] JavaScript lexer/tokenizer

[] ES Module parser

[] AST construction

[] Dependency graph building

[] Code generation

[] Basic minification

[] Tree shaking

### Roadmap

See our Product Requirements Document for detailed feature specifications and development roadmap.

### Architecture

Fasten follows a pipeline architecture:

1. Input Reading - Read source files from the file system

2. Lexing - Convert source code into token streams

3. Parsing - Build Abstract Syntax Trees (ASTs)

4. Dependency Analysis - Map module dependencies

5. Optimization - Apply minification and tree-shaking

6. Code Generation - Output optimized JavaScript bundles

## Development

### Building
```bash
zig build
```

### Benchmarking
```bash
zig build bench
```

### Contributing

We welcome contributions! Please see our development guidelines:

1. Fork the repository

2. Create a feature branch

3. Write tests for new functionality

4. Ensure all tests pass

5. Submit a pull request

### Performance Goals

- Bundle medium-sized projects (100-200 JS files, ~100KB) in under 1 second

- Minimize memory footprint

- Provide faster bundling than traditional tools like Webpack

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Acknowledgments

- Built with Zig for maximum performance

- Inspired by the need for faster, simpler JavaScript build tools

- Educational focus to help developers understand bundling internals
---
Fasten - Because your build process should be as fast as your code.
