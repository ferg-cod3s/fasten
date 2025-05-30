# Contributing to Fasten ⚡

Thank you for your interest in contributing to Fasten! This document outlines the guidelines and standards for contributing to this high-performance JavaScript bundler written in Zig.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Development Environment](#development-environment)
- [Code Standards](#code-standards)
- [Testing Guidelines](#testing-guidelines)
- [Performance Requirements](#performance-requirements)
- [Submission Process](#submission-process)
- [Architecture Guidelines](#architecture-guidelines)

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please be respectful, constructive, and professional in all interactions.

## Development Environment

### Prerequisites

- **Zig 0.11.0 or later** - [Download here](https://ziglang.org/download/)
- **Git** for version control
- **Basic understanding of JavaScript parsing and bundling concepts**

### Setup

```bash
git clone https://github.com/ferg-cod3s/fasten.git
cd fasten
zig build
```

### Building and Testing

```bash
# Build the project
zig build

# Run tests
zig build test

# Run benchmarks
zig build bench

# Build with optimizations
zig build -Doptimize=ReleaseFast
```

## Code Standards

### Zig Code Style

#### Naming Conventions
- **Functions**: `camelCase` (e.g., `parseExpression`, `buildDependencyGraph`)
- **Variables**: `snake_case` (e.g., `token_stream`, `ast_node`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `MAX_FILE_SIZE`, `DEFAULT_BUFFER_SIZE`)
- **Types/Structs**: `PascalCase` (e.g., `TokenType`, `AstNode`, `DependencyGraph`)
- **Enums**: `PascalCase` with `PascalCase` variants (e.g., `TokenType.Identifier`)

#### Code Organization
- **File Structure**: Organize code into logical modules (lexer, parser, codegen, etc.)
- **Function Length**: Keep functions under 50 lines when possible
- **Complexity**: Maximum cyclomatic complexity of 10 per function
- **Documentation**: Document all public functions and complex algorithms

#### Memory Management
- **Allocators**: Always use explicit allocators, prefer `std.heap.ArenaAllocator` for temporary allocations
- **Resource Cleanup**: Ensure all allocated resources are properly freed
- **Error Handling**: Use Zig's error handling mechanisms consistently

#### Example Code Style

```zig
const std = @import("std");
const Allocator = std.mem.Allocator;

/// Represents a token in the JavaScript source code
pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: u32,
    column: u32,

    /// Creates a new token with the given parameters
    pub fn init(token_type: TokenType, lexeme: []const u8, line: u32, column: u32) Token {
        return Token{
            .type = token_type,
            .lexeme = lexeme,
            .line = line,
            .column = column,
        };
    }
};

/// Tokenizes JavaScript source code into a stream of tokens
pub fn tokenize(allocator: Allocator, source: []const u8) ![]Token {
    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();
    
    // Implementation here...
    
    return tokens.toOwnedSlice();
}
```

### Error Handling Standards

#### Error Types
- Define specific error types for different failure modes
- Use descriptive error names (e.g., `UnexpectedToken`, `FileNotFound`, `CircularDependency`)
- Include context information in error messages

#### Error Reporting
- Always include line and column information for syntax errors
- Provide helpful suggestions when possible
- Use consistent error message formatting

```zig
pub const ParseError = error{
    UnexpectedToken,
    UnexpectedEndOfFile,
    InvalidSyntax,
    CircularDependency,
};

pub fn parseExpression(tokens: []const Token, index: *usize) ParseError!AstNode {
    if (index.* >= tokens.len) {
        return ParseError.UnexpectedEndOfFile;
    }
    
    const token = tokens[index.*];
    if (token.type != .Identifier) {
        std.log.err("Expected identifier at line {}, column {}, found '{s}'", 
                   .{ token.line, token.column, token.lexeme });
        return ParseError.UnexpectedToken;
    }
    
    // Implementation...
}
```

## Testing Guidelines

### Test Organization
- **Unit Tests**: Test individual functions and modules in isolation
- **Integration Tests**: Test the complete bundling pipeline
- **Performance Tests**: Benchmark critical paths and overall performance
- **Error Tests**: Verify proper error handling and reporting

### Test Naming
- Use descriptive test names that explain what is being tested
- Format: `test "should [expected behavior] when [condition]"`

### Test Structure
```zig
test "should tokenize simple import statement" {
    const allocator = std.testing.allocator;
    const source = "import { foo } from './bar.js';";
    
    const tokens = try tokenize(allocator, source);
    defer allocator.free(tokens);
    
    try std.testing.expect(tokens.len == 8);
    try std.testing.expectEqual(TokenType.Import, tokens[0].type);
    try std.testing.expectEqualStrings("import", tokens[0].lexeme);
}
```

### Performance Testing
- Benchmark critical functions with realistic data sizes
- Set performance targets and fail tests if they're not met
- Test memory usage and allocation patterns

## Performance Requirements

### Speed Targets
- **Medium projects** (100-200 JS files, ~100KB): Bundle in under 1 second
- **Large projects** (500+ JS files, ~500KB): Bundle in under 5 seconds
- **Startup time**: Tool should start in under 100ms

### Memory Constraints
- **Peak memory usage**: Should not exceed 2x the total input file size
- **Memory leaks**: Zero tolerance for memory leaks
- **Allocation efficiency**: Minimize allocations in hot paths

### Benchmarking
```zig
test "benchmark tokenization performance" {
    const allocator = std.testing.allocator;
    const large_source = // ... generate or load large JS file
    
    const start = std.time.nanoTimestamp();
    const tokens = try tokenize(allocator, large_source);
    const end = std.time.nanoTimestamp();
    
    defer allocator.free(tokens);
    
    const duration_ms = @intCast(f64, end - start) / 1_000_000.0;
    try std.testing.expect(duration_ms < 100.0); // Should complete in under 100ms
}
```

## Submission Process

### Before Submitting

1. **Run all tests**: `zig build test`
2. **Check formatting**: Ensure code follows style guidelines
3. **Run benchmarks**: Verify performance hasn't regressed
4. **Update documentation**: Update relevant docs and comments
5. **Test edge cases**: Verify your changes handle error conditions

### Pull Request Guidelines

#### PR Title Format
- Use conventional commit format: `type(scope): description`
- Types: `feat`, `fix`, `perf`, `refactor`, `test`, `docs`
- Examples:
  - `feat(lexer): add support for template literals`
  - `fix(parser): handle empty import statements`
  - `perf(codegen): optimize string concatenation`

#### PR Description Template
```markdown
## Description
Brief description of the changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Performance improvement
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Performance benchmarks pass
- [ ] Manual testing completed

## Performance Impact
Describe any performance implications of your changes.

## Checklist
- [ ] Code follows the style guidelines
- [ ] Self-review completed
- [ ] Code is commented, particularly in hard-to-understand areas
- [ ] Documentation updated
- [ ] No new warnings introduced
```

### Review Process

1. **Automated checks**: CI must pass (tests, formatting, benchmarks)
2. **Code review**: At least one maintainer review required
3. **Performance review**: Performance-critical changes need benchmark validation
4. **Documentation review**: Ensure docs are accurate and complete

## Architecture Guidelines

### Module Organization

```
src/
├── main.zig              # CLI entry point
├── lexer/
│   ├── tokenizer.zig     # Core tokenization logic
│   ├── token.zig         # Token definitions
│   └── keywords.zig      # JavaScript keyword handling
├── parser/
│   ├── parser.zig        # Main parser logic
│   ├── ast.zig           # AST node definitions
│   └── expressions.zig   # Expression parsing
├── analyzer/
│   ├── dependency.zig    # Dependency graph building
│   └── resolver.zig      # Module resolution
├── optimizer/
│   ├── minifier.zig      # Code minification
│   └── tree_shaker.zig   # Dead code elimination
├── codegen/
│   └── generator.zig     # Code generation
└── utils/
    ├── allocator.zig     # Memory management utilities
    └── errors.zig        # Error handling utilities
```

### Design Principles

1. **Single Responsibility**: Each module should have one clear purpose
2. **Explicit Dependencies**: Make all dependencies explicit and minimal
3. **Error Propagation**: Use Zig's error handling consistently
4. **Performance First**: Optimize for speed and memory efficiency
5. **Testability**: Design for easy unit testing
6. **Extensibility**: Plan for future features without over-engineering

### API Design

- **Consistent Interfaces**: Similar functions should have similar signatures
- **Resource Management**: Clear ownership of allocated resources
- **Error Context**: Provide meaningful error information
- **Documentation**: Document all public APIs

## Getting Help

- **Issues**: Use GitHub issues for bug reports and feature requests
- **Discussions**: Use GitHub discussions for questions and ideas
- **Documentation**: Check the README and PRD for project context

## Recognition

Contributors will be recognized in the project's acknowledgments. Significant contributions may result in maintainer status.

---

Thank you for contributing to Fasten! Together, we're building the fastest JavaScript bundler in the ecosystem. ⚡ 