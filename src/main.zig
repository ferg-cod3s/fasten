//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const fasten_lib = @import("fasten_lib");
const build_options = @import("build_options");

// Version information
const VERSION = "0.0.1";
const VERSION_ASCII =
    \\  ______        _             
    \\ |  ____|      | |            
    \\ | |__ __ _ ___| |_ ___ _ __   
    \\ |  __/ _` / __| __/ _ \ '_ \  
    \\ | | | (_| \__ \ ||  __/ | | | 
    \\ |_|  \__,_|___/\__\___|_| |_| 
    \\                              
    \\ Fast JavaScript Bundler
    \\
;

const Args = struct {
    input_file: ?[]const u8 = null,
    output_file: ?[]const u8 = null,
    minify: bool = false,
    source_map: bool = false,
    watch: bool = false,
    verbose: bool = false,
    help: bool = false,
    version: bool = false,

    const Self = @This();

    pub fn parse(allocator: Allocator) !Self {
        var args = Self{};
        var arg_it = try std.process.argsWithAllocator(allocator);
        defer arg_it.deinit();

        // Skip program name
        _ = arg_it.skip();

        while (arg_it.next()) |arg| {
            if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
                args.help = true;
            } else if (std.mem.eql(u8, arg, "--version") or std.mem.eql(u8, arg, "-v")) {
                args.version = true;
            } else if (std.mem.eql(u8, arg, "--minify") or std.mem.eql(u8, arg, "-m")) {
                args.minify = true;
            } else if (std.mem.eql(u8, arg, "--verbose") or std.mem.eql(u8, arg, "-V")) {
                args.verbose = true;
            } else if (std.mem.eql(u8, arg, "--source-map") or std.mem.eql(u8, arg, "-s")) {
                args.source_map = true;
            } else if (std.mem.eql(u8, arg, "--watch") or std.mem.eql(u8, arg, "-w")) {
                args.watch = true;
            } else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
                args.output_file = arg_it.next() orelse return error.MissingOutputFile;
            } else if (std.mem.eql(u8, arg, "--input") or std.mem.eql(u8, arg, "-i")) {
                args.input_file = arg_it.next() orelse return error.MissingInputFile;
            } else if (args.input_file == null) {
                // First non-flag argument is the input file
                args.input_file = arg;
            } else {
                print("Error: Unexpected argument: {s}\n", .{arg});
                return error.UnexpectedArgument;
            }
        }

        return args;
    }
};

// Error types
const FastenError = error{
    MissingInputFile,
    MissingOutputFile,
    FileNotFound,
    UnexpectedArgument,
    InvalidInput,
};

/// Display usage information
fn showUsage() void {
    print("Usage: fasten [options] <input-file>\n", .{});
    print("Try 'fasten --help' for more information.\n", .{});
}

/// Display help information
fn showHelp() void {
    print(VERSION_ASCII, .{});
    print("Version: {s}\n\n", .{VERSION});
    print("USAGE:\n", .{});
    print("    fasten [OPTIONS] <INPUT>\n\n", .{});
    print("ARGS:\n", .{});
    print("    <INPUT>    Input JavaScript file to bundle\n\n", .{});
    print("OPTIONS:\n", .{});
    print("    -h, --help         Show this help message\n", .{});
    print("    -v, --version      Show version information\n", .{});
    print("    -o, --output <FILE> Output file (default: bundle.js)\n", .{});
    print("    -m, --minify       Minify the output\n", .{});
    print("    -s, --source-map   Generate source map\n", .{});
    print("    -w, --watch        Watch for file changes\n", .{});
    print("    -V, --verbose      Enable verbose output\n", .{});
}

/// Display version information
fn showVersion() void {
    print(VERSION_ASCII, .{});
    print("Version: {s}\n", .{VERSION});
}

/// Read a file into memory
fn readFile(allocator: Allocator, file_path: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| switch (err) {
        error.FileNotFound => return error.FileNotFound,
        error.AccessDenied => return error.AccessDenied,
        else => return err,
    };
    defer file.close();

    const file_size = try file.getEndPos();
    const contents = try allocator.alloc(u8, file_size);
    _ = try file.readAll(contents);
    return contents;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = Args.parse(allocator) catch |err| switch (err) {
        error.MissingInputFile => {
            print("Error: Missing input file after -i/--input flag\n", .{});
            showUsage();
            return;
        },
        error.MissingOutputFile => {
            print("Error: Missing output file after -o/--output flag\n", .{});
            showUsage();
            return;
        },
        error.UnexpectedArgument => {
            showUsage();
            return;
        },
        else => return err,
    };

    if (args.help) {
        showHelp();
        return;
    }

    if (args.version) {
        showVersion();
        return;
    }

    const input_file = args.input_file orelse {
        print("Error: Missing input file\n", .{});
        showUsage();
        return;
    };

    const output_file = args.output_file orelse "bundle.js";
    const verbose = args.verbose or build_options.enable_verbose;

    if (verbose) {
        print("Fasten {s}\n", .{VERSION});
        print("Input file: {s}\n", .{input_file});
        print("Output file: {s}\n", .{output_file});
        print("Minify: {}\n", .{args.minify});
        print("Source map: {}\n", .{args.source_map});
        print("Watch: {}\n", .{args.watch});
        print("Verbose: {}\n", .{args.verbose});
    }

    // Try to read the input file
    const file_content = readFile(allocator, input_file) catch |err| switch (err) {
        error.FileNotFound => {
            print("Error: Input file '{s}' not found\n", .{input_file});
            return;
        },
        error.AccessDenied => {
            print("Error: Permission denied reading '{s}'\n", .{input_file});
            return;
        },
        else => return err,
    };
    defer allocator.free(file_content);

    if (verbose) {
        print("Read {d} bytes from input file\n", .{file_content.len});
    }

    // For now, just demonstrate that we can read and process the file
    // TODO: Replace this with actual bundling logic
    print("Successfully read JavaScript file: {s}\n", .{input_file});
    print("File size: {d} bytes\n", .{file_content.len});

    // Basic validation
    if (std.mem.indexOf(u8, file_content, "import") != null or
        std.mem.indexOf(u8, file_content, "export") != null or
        std.mem.indexOf(u8, file_content, "require") != null)
    {
        print("✓ Detected JavaScript/ES module syntax\n", .{});
    } else {
        if (verbose) {
            print("✗ No JavaScript/ES module syntax detected\n", .{});
        }
    }

    if (verbose) {
        print("Read {d} bytes from input file\n", .{file_content.len});
    }

    // ✨ NEW: Tokenize the JavaScript file
    var file_tokenizer = fasten_lib.lexer.Tokenizer.init(file_content, allocator);
    const tokens = file_tokenizer.tokenize() catch |err| switch (err) {
        error.OutOfMemory => {
            print("Error: Out of memory during tokenization\n", .{});
            return;
        },
        else => return err,
    };
    defer tokens.deinit();

    if (verbose) {
        print("Tokenized into {d} tokens\n", .{tokens.items.len});
        print("\n--- TOKENS ---\n", .{});
        fasten_lib.lexer.TokenUtils.printTokens(tokens.items);
        print("--- END TOKENS ---\n\n", .{});
    }

    // Basic validation - now using tokenizer
    var has_import = false;
    var has_export = false;
    for (tokens.items) |token| {
        if (token.type == .IMPORT) has_import = true;
        if (token.type == .EXPORT) has_export = true;
    }

    if (has_import or has_export) {
        print("✓ Detected ES module syntax (import/export)\n", .{});
    } else {
        if (verbose) {
            print("✗ No ES module syntax detected\n", .{});
        }
    }

    print("Bundle would be written to: {s}\n", .{output_file});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "use other module" {
    try std.testing.expectEqual(@as(i32, 150), fasten_lib.add(100, 50));
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}

test "token system basic functionality" {
    const Token = fasten_lib.lexer.Token;
    const TokenType = fasten_lib.lexer.TokenType;
    const TokenUtils = fasten_lib.lexer.TokenUtils;

    // Test token creation
    const import_token = Token.init(.IMPORT, "import", 1, 1);
    try std.testing.expect(import_token.type == .IMPORT);
    try std.testing.expect(std.mem.eql(u8, import_token.lexeme, "import"));
    try std.testing.expect(import_token.line == 1);
    try std.testing.expect(import_token.column == 1);

    // Test keyword recognition
    try std.testing.expect(TokenUtils.getKeywordType("import") == .IMPORT);
    try std.testing.expect(TokenUtils.getKeywordType("function") == .FUNCTION);
    try std.testing.expect(TokenUtils.getKeywordType("myVariable") == .IDENTIFIER);

    // Test token properties
    try std.testing.expect(TokenType.IMPORT.isKeyword());
    try std.testing.expect(TokenType.PLUS.isOperator());
    try std.testing.expect(TokenType.STRING.isLiteral());

    print("✓ Token system tests passed!\n", .{});
}
