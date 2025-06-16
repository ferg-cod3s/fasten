# Fasten Backend Architecture Document

**Document Version:** 1.0  
**Date:** June 2025 
**Project:** Fasten JavaScript Bundler  

## Overview

This document describes the backend architecture of Fasten, a high-performance JavaScript bundler written in Zig. While Fasten is primarily a CLI tool, its internal architecture follows backend system design principles with clear separation of concerns, data flow management, and modular design.

## System Architecture

### High-Level Architecture

Fasten follows a **Pipeline Architecture** pattern with six main stages:

```
Input → Lexer → Parser → Optimizer → CodeGen → Output
  ↓       ↓       ↓        ↓         ↓        ↓
 Files   Tokens   AST   Optimized  JavaScript Bundle
                        AST       
```

### Architectural Principles

1. **Single Responsibility**: Each module has one clear purpose
2. **Dependency Injection**: Allocators and configuration passed explicitly
3. **Error Propagation**: Consistent error handling through Zig's error unions
4. **Memory Safety**: Explicit allocation/deallocation with leak detection
5. **Performance First**: Designed for minimal memory usage and maximum speed

## Core Modules

### 1. Main Controller (`src/main.zig`)

**Responsibility:** Application entry point and orchestration

```zig
// Simplified structure
pub fn main() !void {
    // 1. Initialize allocators
    // 2. Parse CLI arguments
    // 3. Validate inputs
    // 4. Create pipeline
    // 5. Execute bundling process
    // 6. Handle results and cleanup
}
```

**Key Functions:**
- CLI argument parsing
- Error handling and reporting
- Resource management
- Pipeline orchestration

### 2. File System Interface (`src/utils/fs.zig`)

**Responsibility:** File system operations and path resolution

**API Design:**
```zig
pub const FileSystem = struct {
    allocator: std.mem.Allocator,
    
    pub fn readFile(self: *FileSystem, path: []const u8) ![]u8;
    pub fn writeFile(self: *FileSystem, path: []const u8, content: []const u8) !void;
    pub fn resolvePath(self: *FileSystem, base: []const u8, relative: []const u8) ![]u8;
    pub fn exists(self: *FileSystem, path: []const u8) bool;
};
```

**Features:**
- Cross-platform path handling
- Atomic file operations
- Permission checking
- Error recovery mechanisms

### 3. Lexical Analyzer (`src/lexer/`)

**Responsibility:** Convert JavaScript source code into token streams

**Architecture:**
```zig
pub const Lexer = struct {
    source: []const u8,
    position: usize,
    line: u32,
    column: u32,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator, source: []const u8) Lexer;
    pub fn nextToken(self: *Lexer) !Token;
    pub fn tokenize(self: *Lexer) ![]Token;
};

pub const Token = struct {
    type: TokenType,
    value: []const u8,
    position: Position,
};
```

**Token Types:**
- Keywords (`import`, `export`, `function`, etc.)
- Identifiers (variable names)
- Literals (strings, numbers, booleans)
- Operators (`+`, `-`, `===`, etc.)
- Punctuation (`{`, `}`, `;`, etc.)
- Comments (preserved for source maps)

**Performance Optimizations:**
- Single-pass tokenization
- Minimal memory allocations
- Efficient character classification
- Position tracking for error reporting

### 4. Parser (`src/parser/`)

**Responsibility:** Build Abstract Syntax Trees from token streams

**Architecture:**
```zig
pub const Parser = struct {
    tokens: []const Token,
    current: usize,
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator, tokens: []const Token) Parser;
    pub fn parseModule(self: *Parser) !*ast.Module;
    pub fn parseStatement(self: *Parser) !*ast.Statement;
    pub fn parseExpression(self: *Parser) !*ast.Expression;
};
```

**Parsing Strategy:**
- **Recursive Descent Parser**: Top-down approach
- **Precedence Climbing**: For expression parsing
- **Error Recovery**: Continue parsing after syntax errors
- **Memory Efficient**: Minimal AST node allocation

**Supported Constructs:**
- ES Module imports/exports
- Function declarations
- Variable declarations
- Expression statements
- Control flow statements

### 5. AST Definition (`src/ast/`)

**Responsibility:** Define Abstract Syntax Tree node types

**Node Hierarchy:**
```zig
pub const Node = union(enum) {
    module: Module,
    statement: Statement,
    expression: Expression,
    declaration: Declaration,
};

pub const Module = struct {
    body: []Statement,
    imports: []ImportDeclaration,
    exports: []ExportDeclaration,
    source_file: []const u8,
};

pub const Statement = union(enum) {
    expression: ExpressionStatement,
    variable: VariableDeclaration,
    function: FunctionDeclaration,
    return_stmt: ReturnStatement,
    // ... other statement types
};
```

**Design Principles:**
- **Tagged Unions**: Type-safe node variants
- **Memory Compact**: Minimal memory overhead
- **Visitor Pattern**: Support for tree traversal
- **Position Information**: Source location tracking

### 6. Dependency Resolver (`src/resolver/`)

**Responsibility:** Build module dependency graph

**Architecture:**
```zig
pub const DependencyGraph = struct {
    modules: std.HashMap([]const u8, *Module, std.hash_map.StringContext, std.hash_map.default_max_load_percentage),
    dependencies: std.HashMap([]const u8, [][]const u8, std.hash_map.StringContext, std.hash_map.default_max_load_percentage),
    
    pub fn addModule(self: *DependencyGraph, path: []const u8, module: *Module) !void;
    pub fn resolveDependencies(self: *DependencyGraph) !void;
    pub fn detectCircularDependencies(self: *DependencyGraph) ![]CircularDependency;
    pub fn getTopologicalOrder(self: *DependencyGraph) ![][]const u8;
};
```

**Resolution Strategy:**
- **Depth-First Search**: Discover all dependencies
- **Cycle Detection**: Identify circular dependencies
- **Topological Sort**: Determine bundle order
- **Caching**: Avoid redundant module parsing

### 7. Optimizer (`src/optimizer/`)

**Responsibility:** Apply code optimizations and transformations

**Optimization Passes:**
```zig
pub const Optimizer = struct {
    allocator: std.mem.Allocator,
    options: OptimizationOptions,
    
    pub fn optimize(self: *Optimizer, module: *ast.Module) !*ast.Module;
    pub fn treeShake(self: *Optimizer, graph: *DependencyGraph) !void;
    pub fn minify(self: *Optimizer, module: *ast.Module) !void;
};

pub const OptimizationOptions = struct {
    tree_shaking: bool = true,
    minification: bool = false,
    dead_code_elimination: bool = true,
    constant_folding: bool = true,
};
```

**Optimization Techniques:**
- **Tree Shaking**: Remove unused exports
- **Dead Code Elimination**: Remove unreachable code
- **Constant Folding**: Evaluate constant expressions
- **Minification**: Remove whitespace and comments

### 8. Code Generator (`src/codegen/`)

**Responsibility:** Generate JavaScript code from optimized AST

**Architecture:**
```zig
pub const CodeGenerator = struct {
    allocator: std.mem.Allocator,
    options: CodeGenOptions,
    output: std.ArrayList(u8),
    
    pub fn generate(self: *CodeGenerator, modules: []const *ast.Module) ![]u8;
    pub fn generateModule(self: *CodeGenerator, module: *ast.Module) !void;
    pub fn generateStatement(self: *CodeGenerator, stmt: ast.Statement) !void;
};
```

**Generation Strategy:**
- **Module Wrapping**: IIFE pattern for module isolation
- **Import Resolution**: Convert imports to runtime lookups
- **Source Maps**: Optional debugging information
- **Minification**: Optional whitespace removal

## Data Flow Architecture

### Input Phase
```
File Path → File System → Source Code → Validation
```

### Processing Pipeline
```
Source Code → Lexer → Tokens → Parser → AST → 
Dependency Resolver → Module Graph → Optimizer → 
Optimized AST → Code Generator → JavaScript Bundle
```

### Error Handling Flow
```
Error Occurrence → Error Context → Error Propagation → 
User-Friendly Message → Exit with Error Code
```

## Memory Management Architecture

### Allocator Strategy

**Arena Allocator Pattern:**
```zig
pub fn bundleFiles(allocator: std.mem.Allocator, entry_path: []const u8) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit(); // Cleanup all temporary allocations
    
    const arena_allocator = arena.allocator();
    
    // All temporary allocations use arena_allocator
    // Final result is allocated with the parent allocator
}
```

**Allocation Responsibilities:**
- **Main Allocator**: Long-lived data (configuration, results)
- **Arena Allocator**: Temporary data (tokens, intermediate AST)
- **Fixed Buffer**: Small, stack-allocated data structures

### Resource Management

**RAII Pattern:**
```zig
pub const ResourceManager = struct {
    files: std.ArrayList(*File),
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *ResourceManager) void {
        for (self.files.items) |file| {
            file.close();
        }
        self.files.deinit();
    }
};
```

## Error Handling Architecture

### Error Types

```zig
pub const FastenError = error{
    // File System Errors
    FileNotFound,
    PermissionDenied,
    InvalidPath,
    
    // Parsing Errors
    UnexpectedToken,
    InvalidSyntax,
    UnterminatedString,
    
    // Resolution Errors
    UnresolvedImport,
    CircularDependency,
    
    // System Errors
    OutOfMemory,
    SystemError,
};
```

### Error Context

```zig
pub const ErrorContext = struct {
    file: []const u8,
    line: u32,
    column: u32,
    message: []const u8,
    
    pub fn format(self: ErrorContext, writer: anytype) !void {
        try writer.print("fasten: error: {s}\n  at {s}:{d}:{d}\n", 
                        .{ self.message, self.file, self.line, self.column });
    }
};
```

## Performance Architecture

### Optimization Strategies

1. **Single Pass Processing**: Minimize data traversals
2. **Memory Locality**: Keep related data together
3. **Lazy Evaluation**: Process only what's needed
4. **Caching**: Store expensive computations
5. **Parallel Processing**: Future enhancement for large projects

### Performance Monitoring

```zig
pub const PerformanceMetrics = struct {
    lexing_time: u64,
    parsing_time: u64,
    optimization_time: u64,
    codegen_time: u64,
    total_time: u64,
    peak_memory: usize,
    file_count: usize,
    bundle_size: usize,
};
```

## Configuration Architecture

### Build-Time Configuration

```zig
// build.zig options
const build_options = @import("build_options");

pub const Config = struct {
    enable_benchmarks: bool = build_options.enable_benchmarks,
    enable_profiling: bool = build_options.enable_profiling,
    enable_verbose: bool = build_options.enable_verbose,
};
```

### Runtime Configuration

```zig
pub const BundleOptions = struct {
    entry_point: []const u8,
    output_path: []const u8,
    minify: bool = false,
    tree_shake: bool = true,
    verbose: bool = false,
};
```

## Testing Architecture

### Test Organization

```
tests/
├── unit/           # Individual function tests
├── integration/    # Module interaction tests
├── benchmarks/     # Performance tests
└── fixtures/       # Test data
```

### Test Utilities

```zig
pub const TestHelper = struct {
    pub fn createTempFile(content: []const u8) ![]const u8;
    pub fn assertTokens(expected: []const Token, actual: []const Token) !void;
    pub fn assertAST(expected: *ast.Node, actual: *ast.Node) !void;
};
```

## Future Architecture Considerations

### Planned Enhancements

1. **Plugin System**: Dynamic extension loading
2. **Incremental Compilation**: Only reprocess changed files
3. **Parallel Processing**: Multi-threaded bundling
4. **Source Maps**: Debug information generation
5. **Hot Module Replacement**: Development server integration

### Scalability Considerations

1. **Memory Streaming**: Handle large files without loading entirely
2. **Disk-Based Caching**: Persistent intermediate results
3. **Distributed Processing**: Network-based bundling
4. **Database Integration**: Dependency caching

---

**Note:** This architecture document will evolve as the system grows and new requirements emerge. All architectural decisions prioritize performance, memory safety, and maintainability. 