# Fasten Code Style Guide

This document defines the coding standards and style guidelines for the Fasten JavaScript bundler project.

## Zig Language Standards

### File Organization

#### File Structure
```zig
// 1. Standard library imports
const std = @import("std");
const Allocator = std.mem.Allocator;

// 2. Local imports (relative to project)
const Token = @import("token.zig").Token;
const AstNode = @import("ast.zig").AstNode;

// 3. Constants
const MAX_TOKEN_LENGTH = 1024;
const DEFAULT_BUFFER_SIZE = 4096;

// 4. Type definitions
pub const TokenType = enum {
    Identifier,
    Keyword,
    Operator,
    // ...
};

// 5. Public functions
pub fn tokenize(allocator: Allocator, source: []const u8) ![]Token {
    // Implementation
}

// 6. Private functions
fn isWhitespace(char: u8) bool {
    return char == ' ' or char == '\t' or char == '\n' or char == '\r';
}

// 7. Tests
test "tokenize should handle empty input" {
    // Test implementation
}
```

### Naming Conventions

#### Functions
- **Public functions**: `camelCase`
- **Private functions**: `camelCase`
- **Test functions**: `snake_case` with descriptive names

```zig
// ✅ Good
pub fn parseExpression(tokens: []const Token) !AstNode { }
fn skipWhitespace(source: []const u8, index: *usize) void { }

// ❌ Bad
pub fn ParseExpression(tokens: []const Token) !AstNode { }
pub fn parse_expression(tokens: []const Token) !AstNode { }
```

#### Variables and Fields
- **Local variables**: `snake_case`
- **Struct fields**: `snake_case`
- **Function parameters**: `snake_case`

```zig
// ✅ Good
const token_stream = try tokenize(allocator, source);
const current_token = tokens[index];

pub const Token = struct {
    token_type: TokenType,
    line_number: u32,
    column_number: u32,
};

// ❌ Bad
const tokenStream = try tokenize(allocator, source);
const currentToken = tokens[index];
```

#### Constants
- **Global constants**: `SCREAMING_SNAKE_CASE`
- **Local constants**: `SCREAMING_SNAKE_CASE`

```zig
// ✅ Good
const MAX_FILE_SIZE = 1024 * 1024; // 1MB
const DEFAULT_TIMEOUT_MS = 5000;

// ❌ Bad
const maxFileSize = 1024 * 1024;
const default_timeout_ms = 5000;
```

#### Types and Structs
- **Structs**: `PascalCase`
- **Enums**: `PascalCase`
- **Enum variants**: `PascalCase`
- **Type aliases**: `PascalCase`

```zig
// ✅ Good
pub const TokenType = enum {
    Identifier,
    StringLiteral,
    NumberLiteral,
    LeftParen,
    RightParen,
};

pub const AstNode = struct {
    node_type: NodeType,
    children: []AstNode,
};

// ❌ Bad
pub const tokenType = enum { ... };
pub const Token_Type = enum { ... };
```

### Code Formatting

#### Indentation
- Use **4 spaces** for indentation
- No tabs allowed
- Align continuation lines with the opening delimiter

```zig
// ✅ Good
const result = try parseExpression(
    allocator,
    tokens,
    &index,
    ParseOptions{ .allow_trailing_comma = true }
);

// ❌ Bad
const result = try parseExpression(
  allocator,
  tokens,
  &index,
  ParseOptions{ .allow_trailing_comma = true }
);
```

#### Line Length
- **Maximum line length**: 100 characters
- Break long lines at logical points
- Prefer breaking after operators and commas

```zig
// ✅ Good
if (token.type == .Identifier and 
    token.lexeme.len > 0 and 
    isValidIdentifier(token.lexeme)) {
    // Process token
}

// ❌ Bad
if (token.type == .Identifier and token.lexeme.len > 0 and isValidIdentifier(token.lexeme)) {
    // Process token
}
```

#### Spacing
- One space around binary operators
- No space around unary operators
- One space after commas and semicolons
- No trailing whitespace

```zig
// ✅ Good
const sum = a + b * c;
const negated = -value;
const array = [_]u32{ 1, 2, 3, 4 };

// ❌ Bad
const sum = a+b*c;
const negated = - value;
const array = [_]u32{1,2,3,4};
```

#### Braces and Brackets
- Opening brace on the same line
- Closing brace on its own line
- Always use braces for control structures

```zig
// ✅ Good
if (condition) {
    doSomething();
} else {
    doSomethingElse();
}

while (hasMoreTokens()) {
    processToken();
}

// ❌ Bad
if (condition)
{
    doSomething();
}

if (condition) doSomething();
```

### Documentation

#### Function Documentation
- Document all public functions
- Use triple-slash comments (`///`)
- Include parameter descriptions and return values
- Mention error conditions

```zig
/// Tokenizes JavaScript source code into a stream of tokens.
/// 
/// This function performs lexical analysis on the input source code,
/// breaking it down into individual tokens that can be processed by the parser.
/// 
/// Parameters:
///   - allocator: Memory allocator for token storage
///   - source: JavaScript source code as UTF-8 bytes
/// 
/// Returns:
///   Array of tokens representing the lexical structure of the source code.
///   Caller owns the returned memory and must free it.
/// 
/// Errors:
///   - OutOfMemory: If allocation fails
///   - InvalidCharacter: If source contains invalid UTF-8 or unsupported characters
///   - UnterminatedString: If a string literal is not properly closed
pub fn tokenize(allocator: Allocator, source: []const u8) ![]Token {
    // Implementation
}
```

#### Inline Comments
- Use `//` for single-line comments
- Explain complex algorithms and non-obvious code
- Avoid obvious comments

```zig
// ✅ Good
// Skip UTF-8 BOM if present at the start of the file
if (source.len >= 3 and std.mem.eql(u8, source[0..3], "\xEF\xBB\xBF")) {
    index = 3;
}

// Fast path for ASCII identifiers (most common case)
if (char >= 'a' and char <= 'z') {
    return scanIdentifier(source, index);
}

// ❌ Bad
index += 1; // Increment index
const char = source[index]; // Get character at index
```

### Error Handling

#### Error Types
- Define specific error enums for each module
- Use descriptive error names
- Group related errors together

```zig
pub const LexError = error{
    UnexpectedCharacter,
    UnterminatedString,
    UnterminatedComment,
    InvalidNumber,
    InvalidEscape,
    OutOfMemory,
};

pub const ParseError = error{
    UnexpectedToken,
    UnexpectedEndOfFile,
    InvalidSyntax,
    MissingClosingBrace,
    MissingClosingParen,
    CircularDependency,
};
```

#### Error Propagation
- Use `try` for error propagation
- Use `catch` only when you can meaningfully handle the error
- Provide context in error messages

```zig
// ✅ Good
pub fn parseStatement(tokens: []const Token, index: *usize) ParseError!AstNode {
    const token = tokens[index.*];
    
    return switch (token.type) {
        .Var => try parseVariableDeclaration(tokens, index),
        .Function => try parseFunctionDeclaration(tokens, index),
        .If => try parseIfStatement(tokens, index),
        else => {
            std.log.err("Unexpected token '{s}' at line {}, column {}", 
                       .{ token.lexeme, token.line, token.column });
            return ParseError.UnexpectedToken;
        },
    };
}

// ❌ Bad
pub fn parseStatement(tokens: []const Token, index: *usize) ParseError!AstNode {
    const token = tokens[index.*];
    
    return switch (token.type) {
        .Var => parseVariableDeclaration(tokens, index) catch return ParseError.InvalidSyntax,
        .Function => parseFunctionDeclaration(tokens, index) catch return ParseError.InvalidSyntax,
        else => ParseError.UnexpectedToken,
    };
}
```

### Memory Management

#### Allocator Usage
- Always pass allocators explicitly
- Use `ArenaAllocator` for temporary allocations
- Use `GeneralPurposeAllocator` for long-lived allocations
- Document memory ownership clearly

```zig
// ✅ Good
/// Parses tokens into an AST. Caller owns the returned memory.
pub fn parse(allocator: Allocator, tokens: []const Token) !AstNode {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_allocator = arena.allocator();
    
    // Use temp_allocator for temporary data structures
    var stack = std.ArrayList(AstNode).init(temp_allocator);
    
    // Use main allocator for the result
    const result = try allocator.create(AstNode);
    // ... populate result
    
    return result.*;
}

// ❌ Bad
pub fn parse(tokens: []const Token) !AstNode {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // ... implementation without clear ownership
}
```

#### Resource Cleanup
- Use `defer` for cleanup
- Ensure all allocated resources are freed
- Handle cleanup in error cases

```zig
// ✅ Good
pub fn processFile(allocator: Allocator, file_path: []const u8) !void {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    
    const content = try file.readToEndAlloc(allocator, MAX_FILE_SIZE);
    defer allocator.free(content);
    
    const tokens = try tokenize(allocator, content);
    defer allocator.free(tokens);
    
    // Process tokens...
}
```

### Testing Standards

#### Test Organization
- Group related tests together
- Use descriptive test names
- Test both success and error cases

```zig
// ✅ Good
test "tokenize should handle empty input" {
    const allocator = std.testing.allocator;
    const tokens = try tokenize(allocator, "");
    defer allocator.free(tokens);
    
    try std.testing.expect(tokens.len == 0);
}

test "tokenize should handle simple identifier" {
    const allocator = std.testing.allocator;
    const tokens = try tokenize(allocator, "hello");
    defer allocator.free(tokens);
    
    try std.testing.expect(tokens.len == 1);
    try std.testing.expectEqual(TokenType.Identifier, tokens[0].type);
    try std.testing.expectEqualStrings("hello", tokens[0].lexeme);
}

test "tokenize should return error for invalid character" {
    const allocator = std.testing.allocator;
    try std.testing.expectError(LexError.UnexpectedCharacter, 
                               tokenize(allocator, "hello@world"));
}
```

#### Test Data
- Use realistic test data
- Include edge cases
- Test with various input sizes

```zig
test "tokenize should handle complex JavaScript" {
    const allocator = std.testing.allocator;
    const source = 
        \\import { Component } from 'react';
        \\
        \\export default function App() {
        \\    const [count, setCount] = useState(0);
        \\    return <div>{count}</div>;
        \\}
    ;
    
    const tokens = try tokenize(allocator, source);
    defer allocator.free(tokens);
    
    // Verify token structure...
}
```

### Performance Guidelines

#### Hot Path Optimization
- Minimize allocations in frequently called functions
- Use stack allocation when possible
- Profile before optimizing

```zig
// ✅ Good - Stack allocation for small, fixed-size data
fn scanIdentifier(source: []const u8, start: usize) []const u8 {
    var end = start;
    while (end < source.len and isIdentifierChar(source[end])) {
        end += 1;
    }
    return source[start..end];
}

// ❌ Bad - Unnecessary allocation
fn scanIdentifier(allocator: Allocator, source: []const u8, start: usize) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    var index = start;
    while (index < source.len and isIdentifierChar(source[index])) {
        try result.append(source[index]);
        index += 1;
    }
    return result.toOwnedSlice();
}
```

#### Memory Efficiency
- Reuse buffers when possible
- Use appropriate data structures
- Avoid unnecessary copying

```zig
// ✅ Good - Reuse buffer
pub const Tokenizer = struct {
    source: []const u8,
    index: usize,
    line: u32,
    column: u32,
    buffer: [MAX_TOKEN_LENGTH]u8,
    
    pub fn nextToken(self: *Tokenizer) !Token {
        // Reuse self.buffer for token content
    }
};

// ❌ Bad - Allocate for each token
pub fn nextToken(allocator: Allocator, source: []const u8, index: *usize) !Token {
    const content = try allocator.alloc(u8, token_length);
    // ... populate content
    return Token{ .lexeme = content, ... };
}
```

## Project-Specific Guidelines

### Module Boundaries
- Keep modules focused on single responsibilities
- Minimize dependencies between modules
- Use clear interfaces between components

### Error Messages
- Include file, line, and column information
- Provide helpful suggestions when possible
- Use consistent formatting

```zig
// ✅ Good
std.log.err("Unexpected token '{s}' at {}:{} - expected identifier or keyword", 
           .{ token.lexeme, token.line, token.column });

// ❌ Bad
std.log.err("Parse error");
```

### Performance Targets
- Tokenization: < 1ms per 1KB of source code
- Parsing: < 5ms per 1KB of source code
- Memory usage: < 2x input file size peak usage

---

Following these guidelines ensures consistent, maintainable, and high-performance code across the Fasten project. 