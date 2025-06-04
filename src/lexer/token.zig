const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

/// TokenType represents all possible token types in JavaScript
pub const TokenType = enum {
    // Keywords
    IMPORT,
    EXPORT,
    FUNCTION,
    CONST,
    LET,
    VAR,
    IF,
    ELSE,
    FOR,
    WHILE,
    RETURN,
    CLASS,
    EXTENDS,
    TRY,
    CATCH,
    FINALLY,
    THROW,
    NEW,
    THIS,
    SUPER,
    ASYNC,
    AWAIT,
    TRUE,
    FALSE,
    NULL,
    UNDEFINED,

    // Operators
    PLUS, // +
    MINUS, // -
    MULTIPLY, // *
    DIVIDE, // /
    MODULO, // %
    ASSIGN, // =
    PLUS_ASSIGN, // +=
    MINUS_ASSIGN, // -=
    MULTIPLY_ASSIGN, // *=
    DIVIDE_ASSIGN, // /=
    MODULO_ASSIGN, // %=
    EQUAL, // ==
    STRICT_EQUAL, // ===
    NOT_EQUAL, // !=
    STRICT_NOT_EQUAL, // !==
    LESS_THAN, // <
    LESS_EQUAL, // <=
    GREATER_THAN, // >
    GREATER_EQUAL, // >=
    LOGICAL_AND, // &&
    LOGICAL_OR, // ||
    LOGICAL_NOT, // !
    BITWISE_AND, // &
    BITWISE_OR, // |
    BITWISE_XOR, // ^
    BITWISE_NOT, // ~
    LEFT_SHIFT, // <<
    RIGHT_SHIFT, // >>
    UNSIGNED_RIGHT_SHIFT, // >>>
    INCREMENT, // ++
    DECREMENT, // --

    // Punctuation
    LPAREN, // (
    RPAREN, // )
    LBRACE, // {
    RBRACE, // }
    LBRACKET, // [
    RBRACKET, // ]
    SEMICOLON, // ;
    COMMA, // ,
    DOT, // .
    COLON, // :
    QUESTION, // ?
    ARROW, // =>

    // Literals
    IDENTIFIER,
    STRING,
    NUMBER,
    TEMPLATE_LITERAL,
    REGEX,

    // Special
    EOF,
    NEWLINE,
    WHITESPACE,
    COMMENT,
    BLOCK_COMMENT,

    // Error handling
    INVALID,

    /// Convert TokenType to string representation
    pub fn toString(self: TokenType) []const u8 {
        return switch (self) {
            // Keywords
            .IMPORT => "import",
            .EXPORT => "export",
            .FUNCTION => "function",
            .CONST => "const",
            .LET => "let",
            .VAR => "var",
            .IF => "if",
            .ELSE => "else",
            .FOR => "for",
            .WHILE => "while",
            .RETURN => "return",
            .CLASS => "class",
            .EXTENDS => "extends",
            .TRY => "try",
            .CATCH => "catch",
            .FINALLY => "finally",
            .THROW => "throw",
            .NEW => "new",
            .THIS => "this",
            .SUPER => "super",
            .ASYNC => "async",
            .AWAIT => "await",
            .TRUE => "true",
            .FALSE => "false",
            .NULL => "null",
            .UNDEFINED => "undefined",

            // Operators
            .PLUS => "+",
            .MINUS => "-",
            .MULTIPLY => "*",
            .DIVIDE => "/",
            .MODULO => "%",
            .ASSIGN => "=",
            .PLUS_ASSIGN => "+=",
            .MINUS_ASSIGN => "-=",
            .MULTIPLY_ASSIGN => "*=",
            .DIVIDE_ASSIGN => "/=",
            .MODULO_ASSIGN => "%=",
            .EQUAL => "==",
            .STRICT_EQUAL => "===",
            .NOT_EQUAL => "!=",
            .STRICT_NOT_EQUAL => "!==",
            .LESS_THAN => "<",
            .LESS_EQUAL => "<=",
            .GREATER_THAN => ">",
            .GREATER_EQUAL => ">=",
            .LOGICAL_AND => "&&",
            .LOGICAL_OR => "||",
            .LOGICAL_NOT => "!",
            .BITWISE_AND => "&",
            .BITWISE_OR => "|",
            .BITWISE_XOR => "^",
            .BITWISE_NOT => "~",
            .LEFT_SHIFT => "<<",
            .RIGHT_SHIFT => ">>",
            .UNSIGNED_RIGHT_SHIFT => ">>>",
            .INCREMENT => "++",
            .DECREMENT => "--",

            // Punctuation
            .LPAREN => "(",
            .RPAREN => ")",
            .LBRACE => "{",
            .RBRACE => "}",
            .LBRACKET => "[",
            .RBRACKET => "]",
            .SEMICOLON => ";",
            .COMMA => ",",
            .DOT => ".",
            .COLON => ":",
            .QUESTION => "?",
            .ARROW => "=>",

            // Literals
            .IDENTIFIER => "IDENTIFIER",
            .STRING => "STRING",
            .NUMBER => "NUMBER",
            .TEMPLATE_LITERAL => "TEMPLATE_LITERAL",
            .REGEX => "REGEX",

            // Special
            .EOF => "EOF",
            .NEWLINE => "NEWLINE",
            .WHITESPACE => "WHITESPACE",
            .COMMENT => "COMMENT",
            .BLOCK_COMMENT => "BLOCK_COMMENT",
            .INVALID => "INVALID",
        };
    }

    /// Check if this token type is a keyword
    pub fn isKeyword(self: TokenType) bool {
        return switch (self) {
            .IMPORT, .EXPORT, .FUNCTION, .CONST, .LET, .VAR, .IF, .ELSE, .FOR, .WHILE, .RETURN, .CLASS, .EXTENDS, .TRY, .CATCH, .FINALLY, .THROW, .NEW, .THIS, .SUPER, .ASYNC, .AWAIT, .TRUE, .FALSE, .NULL, .UNDEFINED => true,
            else => false,
        };
    }

    /// Check if this token type is an operator
    pub fn isOperator(self: TokenType) bool {
        return switch (self) {
            .PLUS, .MINUS, .MULTIPLY, .DIVIDE, .MODULO, .ASSIGN, .PLUS_ASSIGN, .MINUS_ASSIGN, .MULTIPLY_ASSIGN, .DIVIDE_ASSIGN, .MODULO_ASSIGN, .EQUAL, .STRICT_EQUAL, .NOT_EQUAL, .STRICT_NOT_EQUAL, .LESS_THAN, .LESS_EQUAL, .GREATER_THAN, .GREATER_EQUAL, .LOGICAL_AND, .LOGICAL_OR, .LOGICAL_NOT, .BITWISE_AND, .BITWISE_OR, .BITWISE_XOR, .BITWISE_NOT, .LEFT_SHIFT, .RIGHT_SHIFT, .UNSIGNED_RIGHT_SHIFT, .INCREMENT, .DECREMENT => true,
            else => false,
        };
    }

    /// Check if this token type is a literal
    pub fn isLiteral(self: TokenType) bool {
        return switch (self) {
            .IDENTIFIER, .STRING, .NUMBER, .TEMPLATE_LITERAL, .REGEX => true,
            else => false,
        };
    }
};

/// Token represents a single lexical token with position information
pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: u32,
    column: u32,

    /// Create a new token
    pub fn init(token_type: TokenType, lexeme: []const u8, line: u32, column: u32) Token {
        return Token{
            .type = token_type,
            .lexeme = lexeme,
            .line = line,
            .column = column,
        };
    }

    /// Create a token with default position (useful for testing)
    pub fn initSimple(token_type: TokenType, lexeme: []const u8) Token {
        return Token.init(token_type, lexeme, 1, 1);
    }

    /// Format token for debugging output
    pub fn format(
        self: Token,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Token{{ .type = {s}, .lexeme = \"{s}\", .line = {d}, .column = {d} }}", .{
            self.type.toString(),
            self.lexeme,
            self.line,
            self.column,
        });
    }

    /// Print token to stdout (useful for debugging)
    pub fn print(self: Token) void {
        std.debug.print("{}\n", .{self});
    }

    /// Check if token represents end of file
    pub fn isEof(self: Token) bool {
        return self.type == .EOF;
    }

    /// Check if token should be ignored during parsing (whitespace, comments)
    pub fn shouldIgnore(self: Token) bool {
        return switch (self.type) {
            .WHITESPACE, .COMMENT, .BLOCK_COMMENT => true,
            else => false,
        };
    }
};

/// Utility functions for working with tokens
pub const TokenUtils = struct {
    /// Get TokenType for a given identifier string, or IDENTIFIER if not a keyword
    pub fn getKeywordType(lexeme: []const u8) TokenType {
        // Use a simple switch statement instead of StaticStringMap for better compatibility
        // This is actually more efficient for this specific use case since we have a known set of keywords
        if (std.mem.eql(u8, lexeme, "import")) return .IMPORT;
        if (std.mem.eql(u8, lexeme, "export")) return .EXPORT;
        if (std.mem.eql(u8, lexeme, "function")) return .FUNCTION;
        if (std.mem.eql(u8, lexeme, "const")) return .CONST;
        if (std.mem.eql(u8, lexeme, "let")) return .LET;
        if (std.mem.eql(u8, lexeme, "var")) return .VAR;
        if (std.mem.eql(u8, lexeme, "if")) return .IF;
        if (std.mem.eql(u8, lexeme, "else")) return .ELSE;
        if (std.mem.eql(u8, lexeme, "for")) return .FOR;
        if (std.mem.eql(u8, lexeme, "while")) return .WHILE;
        if (std.mem.eql(u8, lexeme, "return")) return .RETURN;
        if (std.mem.eql(u8, lexeme, "class")) return .CLASS;
        if (std.mem.eql(u8, lexeme, "extends")) return .EXTENDS;
        if (std.mem.eql(u8, lexeme, "try")) return .TRY;
        if (std.mem.eql(u8, lexeme, "catch")) return .CATCH;
        if (std.mem.eql(u8, lexeme, "finally")) return .FINALLY;
        if (std.mem.eql(u8, lexeme, "throw")) return .THROW;
        if (std.mem.eql(u8, lexeme, "new")) return .NEW;
        if (std.mem.eql(u8, lexeme, "this")) return .THIS;
        if (std.mem.eql(u8, lexeme, "super")) return .SUPER;
        if (std.mem.eql(u8, lexeme, "async")) return .ASYNC;
        if (std.mem.eql(u8, lexeme, "await")) return .AWAIT;
        if (std.mem.eql(u8, lexeme, "true")) return .TRUE;
        if (std.mem.eql(u8, lexeme, "false")) return .FALSE;
        if (std.mem.eql(u8, lexeme, "null")) return .NULL;
        if (std.mem.eql(u8, lexeme, "undefined")) return .UNDEFINED;

        return .IDENTIFIER;
    }

    /// Create a list of tokens from a slice
    pub fn createTokenList(allocator: Allocator) ArrayList(Token) {
        return ArrayList(Token).init(allocator);
    }

    /// Print a list of tokens (useful for debugging)
    pub fn printTokens(tokens: []const Token) void {
        print("Tokens ({d}):\n", .{tokens.len});
        for (tokens, 0..) |token, i| {
            print("  [{d:2}] {}\n", .{ i, token });
        }
    }
};

// Unit tests
test "TokenType toString" {
    try std.testing.expect(std.mem.eql(u8, TokenType.IMPORT.toString(), "import"));
    try std.testing.expect(std.mem.eql(u8, TokenType.PLUS.toString(), "+"));
    try std.testing.expect(std.mem.eql(u8, TokenType.LPAREN.toString(), "("));
    try std.testing.expect(std.mem.eql(u8, TokenType.IDENTIFIER.toString(), "IDENTIFIER"));
}

test "TokenType classification" {
    try std.testing.expect(TokenType.IMPORT.isKeyword());
    try std.testing.expect(!TokenType.PLUS.isKeyword());

    try std.testing.expect(TokenType.PLUS.isOperator());
    try std.testing.expect(!TokenType.IMPORT.isOperator());

    try std.testing.expect(TokenType.IDENTIFIER.isLiteral());
    try std.testing.expect(!TokenType.PLUS.isLiteral());
}

test "Token creation and formatting" {
    const token = Token.init(.IMPORT, "import", 1, 5);

    try std.testing.expect(token.type == .IMPORT);
    try std.testing.expect(std.mem.eql(u8, token.lexeme, "import"));
    try std.testing.expect(token.line == 1);
    try std.testing.expect(token.column == 5);
    try std.testing.expect(!token.isEof());
    try std.testing.expect(!token.shouldIgnore());

    const simple_token = Token.initSimple(.STRING, "\"hello\"");
    try std.testing.expect(simple_token.line == 1);
    try std.testing.expect(simple_token.column == 1);
}

test "TokenUtils keyword lookup" {
    try std.testing.expect(TokenUtils.getKeywordType("import") == .IMPORT);
    try std.testing.expect(TokenUtils.getKeywordType("function") == .FUNCTION);
    try std.testing.expect(TokenUtils.getKeywordType("myVariable") == .IDENTIFIER);
    try std.testing.expect(TokenUtils.getKeywordType("unknown") == .IDENTIFIER);
}

test "Token ignore logic" {
    const whitespace = Token.initSimple(.WHITESPACE, " ");
    const comment = Token.initSimple(.COMMENT, "// comment");
    const identifier = Token.initSimple(.IDENTIFIER, "myVar");

    try std.testing.expect(whitespace.shouldIgnore());
    try std.testing.expect(comment.shouldIgnore());
    try std.testing.expect(!identifier.shouldIgnore());
}

test "EOF token" {
    const eof_token = Token.initSimple(.EOF, "");
    try std.testing.expect(eof_token.isEof());

    const regular_token = Token.initSimple(.IDENTIFIER, "test");
    try std.testing.expect(!regular_token.isEof());
}
