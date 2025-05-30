# Performance Guidelines

This document outlines the performance standards, benchmarking practices, and optimization strategies for the Fasten JavaScript bundler.

## Performance Targets

### Speed Benchmarks

| Project Size | File Count | Total Size | Target Time | Memory Limit |
|-------------|------------|------------|-------------|--------------|
| Small       | 1-10       | < 10KB     | < 100ms     | < 10MB       |
| Medium      | 10-100     | 10-100KB   | < 500ms     | < 50MB       |
| Large       | 100-500    | 100KB-1MB  | < 2s        | < 200MB      |
| Extra Large | 500+       | > 1MB      | < 10s       | < 500MB      |

### Component Performance Targets

| Component | Target Performance | Memory Usage |
|-----------|-------------------|--------------|
| Lexer     | > 1MB/s          | < 2x input   |
| Parser    | > 500KB/s        | < 3x input   |
| Analyzer  | > 1MB/s          | < 1.5x input|
| Optimizer | > 2MB/s          | < 2x input   |
| Codegen   | > 5MB/s          | < 1.5x input|

### Startup Performance
- **Cold start**: < 50ms
- **Warm start**: < 10ms
- **Memory footprint**: < 5MB base usage

## Benchmarking Framework

### Benchmark Structure

```zig
const std = @import("std");
const testing = std.testing;
const Timer = std.time.Timer;

/// Benchmark configuration
pub const BenchmarkConfig = struct {
    iterations: u32 = 100,
    warmup_iterations: u32 = 10,
    max_duration_ns: u64 = 10_000_000_000, // 10 seconds
    memory_limit_bytes: usize = 1024 * 1024 * 1024, // 1GB
};

/// Benchmark result
pub const BenchmarkResult = struct {
    name: []const u8,
    iterations: u32,
    total_time_ns: u64,
    avg_time_ns: u64,
    min_time_ns: u64,
    max_time_ns: u64,
    memory_used_bytes: usize,
    throughput_bytes_per_sec: f64,
};

/// Run a benchmark with the given function
pub fn benchmark(
    allocator: std.mem.Allocator,
    comptime name: []const u8,
    config: BenchmarkConfig,
    input_size: usize,
    benchmark_fn: anytype,
    args: anytype,
) !BenchmarkResult {
    // Warmup
    var i: u32 = 0;
    while (i < config.warmup_iterations) : (i += 1) {
        _ = try benchmark_fn(args);
    }
    
    // Actual benchmark
    var timer = try Timer.start();
    var min_time: u64 = std.math.maxInt(u64);
    var max_time: u64 = 0;
    var total_time: u64 = 0;
    
    i = 0;
    while (i < config.iterations) : (i += 1) {
        const start = timer.read();
        _ = try benchmark_fn(args);
        const end = timer.read();
        
        const iteration_time = end - start;
        total_time += iteration_time;
        min_time = @min(min_time, iteration_time);
        max_time = @max(max_time, iteration_time);
        
        if (total_time > config.max_duration_ns) break;
    }
    
    const avg_time = total_time / i;
    const throughput = if (input_size > 0) 
        @intToFloat(f64, input_size * i * 1_000_000_000) / @intToFloat(f64, total_time)
    else 
        0.0;
    
    return BenchmarkResult{
        .name = name,
        .iterations = i,
        .total_time_ns = total_time,
        .avg_time_ns = avg_time,
        .min_time_ns = min_time,
        .max_time_ns = max_time,
        .memory_used_bytes = 0, // TODO: Implement memory tracking
        .throughput_bytes_per_sec = throughput,
    };
}
```

### Example Benchmarks

```zig
test "benchmark lexer performance" {
    const allocator = testing.allocator;
    
    // Generate test data
    const test_sizes = [_]usize{ 1024, 10240, 102400, 1024000 };
    
    for (test_sizes) |size| {
        const source = try generateJavaScriptSource(allocator, size);
        defer allocator.free(source);
        
        const result = try benchmark(
            allocator,
            "lexer",
            BenchmarkConfig{},
            source.len,
            tokenize,
            .{ allocator, source },
        );
        
        // Assert performance targets
        try testing.expect(result.throughput_bytes_per_sec > 1_000_000); // > 1MB/s
        try testing.expect(result.avg_time_ns < 1_000_000_000); // < 1s
        
        std.log.info("Lexer benchmark ({}KB): {d:.2} MB/s, {d:.2}ms avg", .{
            size / 1024,
            result.throughput_bytes_per_sec / 1_000_000,
            @intToFloat(f64, result.avg_time_ns) / 1_000_000,
        });
    }
}

test "benchmark end-to-end bundling" {
    const allocator = testing.allocator;
    
    const test_cases = [_]struct {
        name: []const u8,
        file_count: u32,
        avg_file_size: usize,
        max_time_ms: u64,
    }{
        .{ .name = "small", .file_count = 5, .avg_file_size = 1024, .max_time_ms = 100 },
        .{ .name = "medium", .file_count = 50, .avg_file_size = 2048, .max_time_ms = 500 },
        .{ .name = "large", .file_count = 200, .avg_file_size = 5120, .max_time_ms = 2000 },
    };
    
    for (test_cases) |test_case| {
        const project = try generateTestProject(allocator, test_case.file_count, test_case.avg_file_size);
        defer freeTestProject(allocator, project);
        
        const result = try benchmark(
            allocator,
            test_case.name,
            BenchmarkConfig{ .iterations = 10 },
            project.total_size,
            bundleProject,
            .{ allocator, project },
        );
        
        const avg_time_ms = result.avg_time_ns / 1_000_000;
        try testing.expect(avg_time_ms < test_case.max_time_ms);
        
        std.log.info("{s} project benchmark: {d}ms avg, {d:.2} MB/s", .{
            test_case.name,
            avg_time_ms,
            result.throughput_bytes_per_sec / 1_000_000,
        });
    }
}
```

## Memory Management

### Memory Allocation Strategies

#### Arena Allocators for Temporary Data
```zig
pub fn parseWithArena(allocator: Allocator, tokens: []const Token) !AstNode {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_allocator = arena.allocator();
    
    // Use arena for temporary data structures
    var stack = std.ArrayList(AstNode).init(temp_allocator);
    var symbol_table = std.HashMap([]const u8, Symbol, std.hash_map.StringContext, 80).init(temp_allocator);
    
    // Parse using temporary allocations
    const result = try parseInternal(temp_allocator, tokens, &stack, &symbol_table);
    
    // Clone result to main allocator
    return try cloneAstNode(allocator, result);
}
```

#### Pool Allocators for Frequent Allocations
```zig
pub const TokenPool = struct {
    pool: std.heap.MemoryPool(Token),
    
    pub fn init(allocator: Allocator) TokenPool {
        return TokenPool{
            .pool = std.heap.MemoryPool(Token).init(allocator),
        };
    }
    
    pub fn deinit(self: *TokenPool) void {
        self.pool.deinit();
    }
    
    pub fn create(self: *TokenPool) !*Token {
        return self.pool.create();
    }
    
    pub fn destroy(self: *TokenPool, token: *Token) void {
        self.pool.destroy(token);
    }
};
```

### Memory Profiling

```zig
pub const MemoryProfiler = struct {
    allocator: Allocator,
    peak_usage: usize,
    current_usage: usize,
    allocation_count: usize,
    
    pub fn init(child_allocator: Allocator) MemoryProfiler {
        return MemoryProfiler{
            .allocator = child_allocator,
            .peak_usage = 0,
            .current_usage = 0,
            .allocation_count = 0,
        };
    }
    
    pub fn allocator(self: *MemoryProfiler) Allocator {
        return Allocator.init(self, alloc, resize, free);
    }
    
    fn alloc(self: *MemoryProfiler, len: usize, alignment: u29, len_align: u29, ret_addr: usize) ![]u8 {
        const result = try self.allocator.rawAlloc(len, alignment, len_align, ret_addr);
        self.current_usage += len;
        self.peak_usage = @max(self.peak_usage, self.current_usage);
        self.allocation_count += 1;
        return result;
    }
    
    fn resize(self: *MemoryProfiler, buf: []u8, buf_align: u29, new_len: usize, len_align: u29, ret_addr: usize) ?usize {
        const old_len = buf.len;
        const result = self.allocator.rawResize(buf, buf_align, new_len, len_align, ret_addr);
        if (result) |new_size| {
            self.current_usage = self.current_usage - old_len + new_size;
            self.peak_usage = @max(self.peak_usage, self.current_usage);
        }
        return result;
    }
    
    fn free(self: *MemoryProfiler, buf: []u8, buf_align: u29, ret_addr: usize) void {
        self.allocator.rawFree(buf, buf_align, ret_addr);
        self.current_usage -= buf.len;
    }
};
```

## Optimization Strategies

### Hot Path Optimization

#### Fast Path for Common Cases
```zig
pub fn tokenizeOptimized(allocator: Allocator, source: []const u8) ![]Token {
    var tokens = std.ArrayList(Token).init(allocator);
    var index: usize = 0;
    
    while (index < source.len) {
        const char = source[index];
        
        // Fast path for ASCII letters (most common case)
        if ((char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == '_' or char == '$') {
            const start = index;
            index += 1;
            
            // Optimized identifier scanning
            while (index < source.len) {
                const c = source[index];
                if ((c >= 'a' and c <= 'z') or 
                    (c >= 'A' and c <= 'Z') or 
                    (c >= '0' and c <= '9') or 
                    c == '_' or c == '$') {
                    index += 1;
                } else {
                    break;
                }
            }
            
            try tokens.append(Token{
                .type = .Identifier,
                .lexeme = source[start..index],
                .line = 1, // TODO: Track line numbers
                .column = @intCast(u32, start),
            });
            continue;
        }
        
        // Fast path for whitespace
        if (char == ' ' or char == '\t' or char == '\n' or char == '\r') {
            index += 1;
            continue;
        }
        
        // Slow path for other characters
        const token = try tokenizeSlow(source, &index);
        try tokens.append(token);
    }
    
    return tokens.toOwnedSlice();
}
```

#### SIMD Optimizations (Future)
```zig
// Example of potential SIMD optimization for whitespace skipping
fn skipWhitespaceSimd(source: []const u8, start: usize) usize {
    var index = start;
    
    // Process 16 bytes at a time using SIMD when available
    while (index + 16 <= source.len) {
        const chunk = source[index..index + 16];
        
        // Check if all bytes are whitespace using SIMD
        if (std.simd.allTrue(isWhitespaceVector(chunk))) {
            index += 16;
        } else {
            // Fall back to scalar processing for this chunk
            break;
        }
    }
    
    // Process remaining bytes
    while (index < source.len and isWhitespace(source[index])) {
        index += 1;
    }
    
    return index;
}
```

### Data Structure Optimization

#### Efficient String Interning
```zig
pub const StringInterner = struct {
    map: std.HashMap([]const u8, u32, std.hash_map.StringContext, 80),
    strings: std.ArrayList([]const u8),
    allocator: Allocator,
    
    pub fn init(allocator: Allocator) StringInterner {
        return StringInterner{
            .map = std.HashMap([]const u8, u32, std.hash_map.StringContext, 80).init(allocator),
            .strings = std.ArrayList([]const u8).init(allocator),
            .allocator = allocator,
        };
    }
    
    pub fn intern(self: *StringInterner, string: []const u8) !u32 {
        if (self.map.get(string)) |id| {
            return id;
        }
        
        const owned_string = try self.allocator.dupe(u8, string);
        const id = @intCast(u32, self.strings.items.len);
        try self.strings.append(owned_string);
        try self.map.put(owned_string, id);
        return id;
    }
    
    pub fn getString(self: *StringInterner, id: u32) []const u8 {
        return self.strings.items[id];
    }
};
```

#### Compact AST Representation
```zig
pub const CompactAstNode = packed struct {
    type: NodeType, // 8 bits
    flags: u8,      // 8 bits for various flags
    data: u48,      // 48 bits for data (indices, values, etc.)
    
    pub fn getChildren(self: CompactAstNode, ast: *const CompactAst) []CompactAstNode {
        return ast.getNodeChildren(self.data);
    }
    
    pub fn getStringValue(self: CompactAstNode, ast: *const CompactAst) []const u8 {
        return ast.getString(@intCast(u32, self.data));
    }
};
```

## Performance Testing

### Continuous Performance Monitoring

```zig
// Performance regression test
test "performance regression check" {
    const allocator = testing.allocator;
    
    // Load baseline performance data
    const baseline = try loadBaselinePerformance(allocator);
    defer allocator.free(baseline);
    
    // Run current benchmarks
    const current = try runAllBenchmarks(allocator);
    defer allocator.free(current);
    
    // Check for regressions (> 10% slower)
    for (current) |result, i| {
        const baseline_result = baseline[i];
        const regression_threshold = baseline_result.avg_time_ns * 110 / 100; // 10% slower
        
        if (result.avg_time_ns > regression_threshold) {
            std.log.err("Performance regression detected in {s}: {d}ns vs {d}ns baseline", .{
                result.name,
                result.avg_time_ns,
                baseline_result.avg_time_ns,
            });
            return error.PerformanceRegression;
        }
    }
}
```

### Memory Leak Detection

```zig
test "memory leak detection" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) {
            std.log.err("Memory leak detected!");
            return error.MemoryLeak;
        }
    }
    
    const allocator = gpa.allocator();
    
    // Run bundling process
    const source = "import { foo } from './bar.js'; export default foo;";
    const tokens = try tokenize(allocator, source);
    defer allocator.free(tokens);
    
    const ast = try parse(allocator, tokens);
    defer freeAst(allocator, ast);
    
    const bundle = try generateCode(allocator, ast);
    defer allocator.free(bundle);
}
```

## Performance Monitoring in Production

### Metrics Collection

```zig
pub const PerformanceMetrics = struct {
    bundling_time_ms: u64,
    memory_peak_mb: u64,
    input_size_kb: u64,
    output_size_kb: u64,
    file_count: u32,
    
    pub fn log(self: PerformanceMetrics) void {
        std.log.info("Bundle metrics: {}ms, {}MB peak, {} files, {:.2}x compression", .{
            self.bundling_time_ms,
            self.memory_peak_mb,
            self.file_count,
            @intToFloat(f64, self.input_size_kb) / @intToFloat(f64, self.output_size_kb),
        });
    }
};
```

### Performance Alerts

```zig
pub fn checkPerformanceThresholds(metrics: PerformanceMetrics) !void {
    // Alert if bundling takes too long
    if (metrics.bundling_time_ms > 10000) { // 10 seconds
        std.log.warn("Slow bundling detected: {}ms", .{metrics.bundling_time_ms});
    }
    
    // Alert if memory usage is excessive
    if (metrics.memory_peak_mb > 1000) { // 1GB
        std.log.warn("High memory usage detected: {}MB", .{metrics.memory_peak_mb});
    }
    
    // Alert if compression ratio is poor
    const compression_ratio = @intToFloat(f64, metrics.input_size_kb) / @intToFloat(f64, metrics.output_size_kb);
    if (compression_ratio < 1.1) {
        std.log.warn("Poor compression ratio: {:.2}x", .{compression_ratio});
    }
}
```

## Optimization Checklist

### Before Optimizing
- [ ] Profile the code to identify actual bottlenecks
- [ ] Establish baseline performance measurements
- [ ] Set specific performance targets
- [ ] Ensure correctness tests are in place

### During Optimization
- [ ] Focus on the hottest code paths first
- [ ] Measure the impact of each optimization
- [ ] Maintain code readability and maintainability
- [ ] Document optimization techniques used

### After Optimization
- [ ] Verify all tests still pass
- [ ] Update performance benchmarks
- [ ] Document performance characteristics
- [ ] Monitor for regressions in CI/CD

---

Following these performance guidelines ensures that Fasten maintains its position as the fastest JavaScript bundler while remaining maintainable and reliable. 