const std = @import("std");
const token = @import("token.zig");
const Token = token.Token;
const TokenType = token.TokenType;
const TokenUtils = token.TokenUtils;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

/// Tokenizer converts JavaScript source code into a stream of tokens
pub const Tokenizer = struct {
    source: []const u8,
    current: usize,
    line: u32,
    column: u32,
    allocator: Allocator,

    /// Initialize a new tokenizer with the given source code
    pub fn init(source: []const u8, allocator: Allocator) Tokenizer {
        return Tokenizer{
            .source = source,
            .current = 0,
            .line = 1,
            .column = 1,
            .allocator = allocator,
        };
    }
    /// Check if we've reached the end of the source
    fn isAtEnd(self: *Tokenizer) bool {
        return self.current >= self.source.len;
    }

    /// Get the current character without advancing
    fn peek(self: *Tokenizer) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    /// Get the next character without advancing
    fn peekNext(self: *Tokenizer) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    /// Advance to the next character and return the current one
    fn advance(self: *Tokenizer) u8 {
        if (self.isAtEnd()) return 0;

        const c = self.source[self.current];
        self.current += 1;

        if (c == '\n') {
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }

        return c;
    }

    /// Check if current character matches expected, advance if so
    fn match(self: *Tokenizer, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;

        _ = self.advance();
        return true;
    }

    /// Create a token with current position information
    fn makeToken(self: *Tokenizer, token_type: TokenType, start: usize) Token {
        const lexeme = self.source[start..self.current];
        return Token.init(token_type, lexeme, self.line, self.column - @as(u32, @intCast(lexeme.len)));
    }

    /// Create an error token with current position
    fn errorToken(self: *Tokenizer, message: []const u8) Token {
        return Token.init(.INVALID, message, self.line, self.column);
    }

    /// Skip whitespace characters (spaces, tabs, carriage returns)
    fn skipWhitespace(self: *Tokenizer) void {
        while (!self.isAtEnd()) {
            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => {
                    _ = self.advance();
                },
                else => break,
            }
        }
    }

    /// Check if character is alphabetic or underscore (valid identifier start)
    fn isAlpha(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
    }

    /// Check if character is alphanumeric or underscore (valid identifier continuation)
    fn isAlphaNumeric(c: u8) bool {
        return isAlpha(c) or (c >= '0' and c <= '9');
    }

    /// Check if character is a digit
    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    /// Scan an identifier or keyword
    fn scanIdentifier(self: *Tokenizer) Token {
        const start = self.current;

        while (isAlphaNumeric(self.peek())) {
            _ = self.advance();
        }

        const lexeme = self.source[start..self.current];
        const token_type = TokenUtils.getKeywordType(lexeme);

        return Token.init(token_type, lexeme, self.line, self.column - @as(u32, @intCast(lexeme.len)));
    }

    /// Scan a number literal
    fn scanNumber(self: *Tokenizer) Token {
        const start = self.current;

        while (isDigit(self.peek())) {
            _ = self.advance();
        }

        // Look for decimal part
        if (self.peek() == '.' and isDigit(self.peekNext())) {
            _ = self.advance(); // Consume the '.'
            while (isDigit(self.peek())) {
                _ = self.advance();
            }
        }

        return self.makeToken(.NUMBER, start);
    }

    /// Scan a string literal (single or double quoted)
    fn scanString(self: *Tokenizer, quote: u8) Token {
        const start = self.current - 1; // Include the opening quote

        while (!self.isAtEnd() and self.peek() != quote) {
            if (self.peek() == '\n') {
                // JavaScript allows multi-line strings with escape
                // For now, we'll advance and let the line tracking work
            }
            if (self.peek() == '\\') {
                _ = self.advance(); // Skip escape character
                if (!self.isAtEnd()) {
                    _ = self.advance(); // Skip escaped character
                }
            } else {
                _ = self.advance();
            }
        }

        if (self.isAtEnd()) {
            return self.errorToken("Unterminated string");
        }

        _ = self.advance(); // Consume closing quote
        return self.makeToken(.STRING, start);
    }

    /// Scan a single-line comment
    fn scanLineComment(self: *Tokenizer) Token {
        const start = self.current - 2; // Include the '//'

        while (!self.isAtEnd() and self.peek() != '\n') {
            _ = self.advance();
        }

        return self.makeToken(.COMMENT, start);
    }

    /// Scan a block comment
    fn scanBlockComment(self: *Tokenizer) Token {
        const start = self.current - 2; // Include the '/*'

        while (!self.isAtEnd()) {
            if (self.peek() == '*' and self.peekNext() == '/') {
                _ = self.advance(); // Consume '*'
                _ = self.advance(); // Consume '/'
                break;
            }
            _ = self.advance();
        }

        return self.makeToken(.BLOCK_COMMENT, start);
    }

    /// Scan the next token from the source
    fn scanToken(self: *Tokenizer) !Token {
        self.skipWhitespace();

        if (self.isAtEnd()) {
            return Token.init(.EOF, "", self.line, self.column);
        }

        const start = self.current;
        const c = self.advance();

        // Handle identifiers and keywords
        if (isAlpha(c)) {
            self.current -= 1; // Back up to re-scan
            return self.scanIdentifier();
        }

        // Handle numbers
        if (isDigit(c)) {
            self.current -= 1; // Back up to re-scan
            return self.scanNumber();
        }

        // Handle single-character and multi-character tokens
        switch (c) {
            // Single-character tokens
            '(' => return self.makeToken(.LPAREN, start),
            ')' => return self.makeToken(.RPAREN, start),
            '{' => return self.makeToken(.LBRACE, start),
            '}' => return self.makeToken(.RBRACE, start),
            '[' => return self.makeToken(.LBRACKET, start),
            ']' => return self.makeToken(.RBRACKET, start),
            ';' => return self.makeToken(.SEMICOLON, start),
            ',' => return self.makeToken(.COMMA, start),
            '.' => return self.makeToken(.DOT, start),
            ':' => return self.makeToken(.COLON, start),
            '?' => return self.makeToken(.QUESTION, start),
            '~' => return self.makeToken(.BITWISE_NOT, start),

            // Potentially multi-character tokens
            '+' => {
                if (self.match('+')) {
                    return self.makeToken(.INCREMENT, start);
                } else if (self.match('=')) {
                    return self.makeToken(.PLUS_ASSIGN, start);
                } else {
                    return self.makeToken(.PLUS, start);
                }
            },
            '-' => {
                if (self.match('-')) {
                    return self.makeToken(.DECREMENT, start);
                } else if (self.match('=')) {
                    return self.makeToken(.MINUS_ASSIGN, start);
                } else {
                    return self.makeToken(.MINUS, start);
                }
            },
            '*' => {
                if (self.match('=')) {
                    return self.makeToken(.MULTIPLY_ASSIGN, start);
                } else {
                    return self.makeToken(.MULTIPLY, start);
                }
            },
            '/' => {
                if (self.match('/')) {
                    return self.scanLineComment();
                } else if (self.match('*')) {
                    return self.scanBlockComment();
                } else if (self.match('=')) {
                    return self.makeToken(.DIVIDE_ASSIGN, start);
                } else {
                    return self.makeToken(.DIVIDE, start);
                }
            },
            '%' => {
                if (self.match('=')) {
                    return self.makeToken(.MODULO_ASSIGN, start);
                } else {
                    return self.makeToken(.MODULO, start);
                }
            },
            '=' => {
                if (self.match('=')) {
                    if (self.match('=')) {
                        return self.makeToken(.STRICT_EQUAL, start);
                    } else {
                        return self.makeToken(.EQUAL, start);
                    }
                } else if (self.match('>')) {
                    return self.makeToken(.ARROW, start);
                } else {
                    return self.makeToken(.ASSIGN, start);
                }
            },
            '!' => {
                if (self.match('=')) {
                    if (self.match('=')) {
                        return self.makeToken(.STRICT_NOT_EQUAL, start);
                    } else {
                        return self.makeToken(.NOT_EQUAL, start);
                    }
                } else {
                    return self.makeToken(.LOGICAL_NOT, start);
                }
            },
            '<' => {
                if (self.match('<')) {
                    return self.makeToken(.LEFT_SHIFT, start);
                } else if (self.match('=')) {
                    return self.makeToken(.LESS_EQUAL, start);
                } else {
                    return self.makeToken(.LESS_THAN, start);
                }
            },
            '>' => {
                if (self.match('>')) {
                    if (self.match('>')) {
                        return self.makeToken(.UNSIGNED_RIGHT_SHIFT, start);
                    } else {
                        return self.makeToken(.RIGHT_SHIFT, start);
                    }
                } else if (self.match('=')) {
                    return self.makeToken(.GREATER_EQUAL, start);
                } else {
                    return self.makeToken(.GREATER_THAN, start);
                }
            },
            '&' => {
                if (self.match('&')) {
                    return self.makeToken(.LOGICAL_AND, start);
                } else {
                    return self.makeToken(.BITWISE_AND, start);
                }
            },
            '|' => {
                if (self.match('|')) {
                    return self.makeToken(.LOGICAL_OR, start);
                } else {
                    return self.makeToken(.BITWISE_OR, start);
                }
            },
            '^' => return self.makeToken(.BITWISE_XOR, start),

            // String literals
            '"' => return self.scanString('"'),
            '\'' => return self.scanString('\''),

            // Newlines
            '\n' => return self.makeToken(.NEWLINE, start),

            else => {
                return self.errorToken("Unexpected character");
            },
        }
    }

    /// Tokenize the entire source and return a list of tokens
    pub fn tokenize(self: *Tokenizer) !ArrayList(Token) {
        var tokens = ArrayList(Token).init(self.allocator);

        while (!self.isAtEnd()) {
            const current_token = try self.scanToken();

            // Skip whitespace tokens but include others
            if (current_token.type != .WHITESPACE) {
                try tokens.append(current_token);
            }

            // Break on EOF
            if (current_token.type == .EOF) {
                break;
            }
        }

        // Ensure we have EOF token
        if (tokens.items.len == 0 or tokens.items[tokens.items.len - 1].type != .EOF) {
            try tokens.append(Token.init(.EOF, "", self.line, self.column));
        }

        return tokens;
    }
};

// Unit tests
test "Tokenizer initialization" {
    const allocator = std.testing.allocator;
    const source = "test";
    const tokenizer = Tokenizer.init(source, allocator);

    try std.testing.expect(tokenizer.current == 0);
    try std.testing.expect(tokenizer.line == 1);
    try std.testing.expect(tokenizer.column == 1);
}

test "Character navigation" {
    const allocator = std.testing.allocator;
    const source = "abc\ndef";
    const tokenizer = Tokenizer.init(source, allocator);

    try std.testing.expect(tokenizer.peek() == 'a');
    try std.testing.expect(tokenizer.advance() == 'a');
    try std.testing.expect(tokenizer.column == 2);

    try std.testing.expect(tokenizer.peekNext() == 'c');
    try std.testing.expect(tokenizer.advance() == 'b');

    _ = tokenizer.advance(); // 'c'
    _ = tokenizer.advance(); // '\n'
    try std.testing.expect(tokenizer.line == 2);
    try std.testing.expect(tokenizer.column == 1);
}

test "Simple tokenization" {
    const allocator = std.testing.allocator;
    const source = "const x = 42;";
    const tokenizer = Tokenizer.init(source, allocator);

    const tokens = try tokenizer.tokenize();
    defer tokens.deinit();

    try std.testing.expect(tokens.items.len == 6); // const, x, =, 42, ;, EOF
    try std.testing.expect(tokens.items[0].type == .CONST);
    try std.testing.expect(tokens.items[1].type == .IDENTIFIER);
    try std.testing.expect(tokens.items[2].type == .ASSIGN);
    try std.testing.expect(tokens.items[3].type == .NUMBER);
    try std.testing.expect(tokens.items[4].type == .SEMICOLON);
    try std.testing.expect(tokens.items[5].type == .EOF);
}

test "Import statement tokenization" {
    const allocator = std.testing.allocator;
    const source = "import { foo } from './bar.js';";
    const tokenizer = Tokenizer.init(source, allocator);

    const tokens = try tokenizer.tokenize();
    defer tokens.deinit();

    try std.testing.expect(tokens.items[0].type == .IMPORT);
    try std.testing.expect(tokens.items[1].type == .LBRACE);
    try std.testing.expect(tokens.items[2].type == .IDENTIFIER);
    try std.testing.expect(std.mem.eql(u8, tokens.items[2].lexeme, "foo"));
    try std.testing.expect(tokens.items[3].type == .RBRACE);
    try std.testing.expect(tokens.items[4].type == .IDENTIFIER);
    try std.testing.expect(std.mem.eql(u8, tokens.items[4].lexeme, "from"));
    try std.testing.expect(tokens.items[5].type == .STRING);
    try std.testing.expect(tokens.items[6].type == .SEMICOLON);
    try std.testing.expect(tokens.items[7].type == .EOF);
}

test "Operators tokenization" {
    const allocator = std.testing.allocator;
    const source = "=== !== >= <=";
    const tokenizer = Tokenizer.init(source, allocator);

    const tokens = try tokenizer.tokenize();
    defer tokens.deinit();

    try std.testing.expect(tokens.items[0].type == .STRICT_EQUAL);
    try std.testing.expect(tokens.items[1].type == .STRICT_NOT_EQUAL);
    try std.testing.expect(tokens.items[2].type == .GREATER_EQUAL);
    try std.testing.expect(tokens.items[3].type == .LESS_EQUAL);
    try std.testing.expect(tokens.items[4].type == .EOF);
}

test "Comments tokenization" {
    const allocator = std.testing.allocator;
    const source = "// Line comment\n/* Block comment */";
    const tokenizer = Tokenizer.init(source, allocator);

    const tokens = try tokenizer.tokenize();
    defer tokens.deinit();

    try std.testing.expect(tokens.items[0].type == .COMMENT);
    try std.testing.expect(tokens.items[1].type == .NEWLINE);
    try std.testing.expect(tokens.items[2].type == .BLOCK_COMMENT);
    try std.testing.expect(tokens.items[3].type == .EOF);
}
