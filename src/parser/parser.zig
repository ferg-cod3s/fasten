const std = @import("std");
const Token = @import("fasten_lib").lexer.Token;
const Node = @import("fasten_lib").ast.nodes.Node;
const NodeType = @import("fasten_lib").ast.nodes.NodeType;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Parser = struct {
    allocator: Allocator,
    tokens: []const Token,
    current: usize,
    errors: ArrayList(ParserError),

    const Self = @This();

    pub const ParserError = struct {
        message: []const u8,
        token: ?Token,
    };

    pub fn init(allocator: Allocator, tokens: []const Token) Self {
        return Self{
            .allocator = allocator,
            .tokens = tokens,
            .current = 0,
            .errors = ArrayList(ParserError).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.errors.deinit();
    }

    /// Check if the parser is at the end of the token stream
    pub fn isAtEnd(self: *Self) bool {
        return self.current >= self.tokens.len;
    }

    /// Look at the current token without consuming it
    pub fn peek(self: *Self) ?Token {
        if (self.isAtEnd()) return null;
        return self.tokens[self.current];
    }

    /// Look at the next token without consuming it
    pub fn peekNext(self: *Self) ?Token {
        if (self.current + 1 >= self.tokens.len) return null;
        return self.tokens[self.current + 1];
    }

    /// Get the current token and advance to the next one
    pub fn advance(self: *Self) Token {
        if (self.isAtEnd()) return null;
        const token = self.tokens[self.current];
        self.current += 1;
        return token;
    }

    /// Check if the current token matches the expected type
    pub fn check(self: *Self, token_type: Token.TokenType) bool {
        if (self.isAtEnd()) return false;
        return self.tokens[self.current].type == token_type;
    }

    /// If the current token matches the expect type, consume it and return true
    /// Otherwise, return false without consuming the current token
    pub fn match(self: *Self, token_type: Token.TokenType) bool {
        if (self.check(token_type)) {
            _ = self.advance();
            return true;
        }
        return false;
    }

    /// Get the previous token (useful for error reporting)
    pub fn previous(self: *Self) Token {
        if (self.current == 0) return null;
        return self.tokens[self.current - 1];
    }

    /// Parse a primary expression (literals, identifiers, parenthesized expressions)
    fn parsePrimary(self: *Self) !Node {
        if (self.isAtEnd()) {
            try self.errors.append(.{
                .message = "Unexpected end of input",
                .token = null,
            });
            return null;
        }

        const token = self.advance();
        return switch (token.type) {
            .NUMBER => Node.createNumberLiteral(token.lexeme, self.getLocation(token)),
            .STRING => Node.createStringLiteral(token.lexeme, self.getLocation(token)),
            .IDENTIFIER => Node.createIdentifier(token.lexeme, self.getLocation(token)),
            .TRUE, .FALSE => Node.createBooleanLiteral(token.type == .TRUE, self.getLocation(token)),
            .NULL => Node.createNullLiteral(self.getLocation(token)),
            .LPAREN => {
                const expr = try self.parseExpression();
                if (!self.match(.RPAREN)) {
                    try self.errors.append(.{
                        .message = "Expected ')' after expression",
                        .token = self.peek(),
                    });
                    return error.ParseError;
                }
                return expr;
            },
            else => {
                try self.errors.append(.{
                    .message = "Unexpected token: " ++ token.lexeme,
                    .token = self.peek(),
                });
            },
        };
    }

    /// Parse a binary expression with operator precedence
    fn parseBinary(self: *Self, min_precedence: u8) !Node {
        var left = try self.parsePrimary();

        while (true) {
            const token = self.peek() orelse break;
            const precedence = self.getOperatorPrecedence(token.type);

            if (precedence < min_precedence) break;

            const operator = self.advance();
            const right = try self.parsePrimary();

            left = Node.createBinaryExpression(
                left,
                operator,
                &right,
                self.getLocation(operator),
            );
        }

        return left;
    }

    /// parse a variable declaration statement
    fn parseVariableDeclaration(self: *Self) !Node {
        const keyword = self.advance(); // 'const', 'let', or 'var'
        const name = self.advance();

        if (name.type != .IDENTIFIER) {
            try self.errors.append(.{
                .message = "Expected variable name",
                .token = &name,
            });
            return error.ParseError;
        }

        if (!self.match(.ASSIGN)) {
            try self.errors.append(.{
                .message = "Expected '=' after variable name",
                .token = self.peek(),
            });
            return error.ParseError;
        }

        const initializer = try self.parseExpression();

        if (!self.match(.SEMICOLON)) {
            try self.errors.append(.{
                .message = "Expected ';' after variable declaration",
                .token = self.peek(),
            });
            return error.ParseError;
        }

        return Node.createVariableDeclaration(
            name.lexeme,
            &initializer,
            self.getLocation(keyword),
        );
    }

    /// Parse a statement
    fn parseStatement(self: *Self) !Node {
        return switch (self.peek().?.type) {
            .CONST, .LET, .VAR => self.parseVariableDeclaration(),
            .FUNCTION => self.parseFunctionDeclaration(),
            .RETURN => self.parseReturnStatement(),
            .IF => self.parseIfStatement(),
            .WHILE => self.parseWhileStatement(),
            .FOR => self.parseForStatement(),
            .BREAK => self.parseBreakStatement(),
            .CONTINUE => self.parseContinueStatement(),
            .TRY => self.parseTryStatement(),
            .THROW => self.parseThrowStatement(),
            .TRY_CATCH => self.parseTryCatchStatement(),
            .TRY_FINALLY => self.parseTryFinallyStatement(),
            .TRY_CATCH_FINALLY => self.parseTryCatchFinallyStatement(),
            .IMPORT => self.parseImportStatement(),
            .EXPORT => self.parseExportStatement(),
            .IMPORT_ALL => self.parseImportAllStatement(),
            .IMPORT_DEFAULT => self.parseImportDefaultStatement(),
            .IMPORT_NAMESPACE => self.parseImportNamespaceStatement(),
            .CLASS => self.parseClassDeclaration(),
            .INTERFACE => self.parseInterfaceDeclaration(),
            .TYPE => self.parseTypeDeclaration(),
            .ENUM => self.parseEnumDeclaration(),
            .SWITCH => self.parseSwitchStatement(),
            .DO => self.parseDoWhileStatement(),
            .WITH => self.parseWithStatement(),
            .DEBUGGER => self.parseDebuggerStatement(),
            .LABEL => self.parseLabeledStatement(),
            .BLOCK => self.parseBlockStatement(),
            else => self.parseExpression(),
        };
    }

    /// Parse the tokens into an AST
    pub fn parse(_: *Self) !Node {
        // TODO: implement parser logic
        // For now, just return a dummy program node
        return Node.createProgram(null);
    }
};

test "Parser should parse variable declaration" {
    const allocator = std.testing.allocator;

    // Create tokens for: const x = 42;
    const tokens = [_]Token{
        Token.initSimple(.CONST, "const"),
        Token.initSimple(.IDENTIFIER, "x"),
        Token.initSimple(.EQUAL, "="),
        Token.initSimple(.NUMBER, "42"),
        Token.initSimple(.SEMICOLON, ";"),
    };

    var parser = Parser.init(allocator, &tokens);
    defer parser.deinit();

    const ast = try parser.parse();
    try std.testing.expect(ast.node_type == NodeType.Program);
    try std.testing.expect(ast.children.len == 1);

    const var_decl = ast.children[0];
    try std.testing.expect(var_decl.node_type == NodeType.VariableDeclaration);
    try std.testing.expect(var_decl.children.len == 2);

    const var_name = var_decl.children[0];
    try std.testing.expect(var_name.node_type == NodeType.Identifier);
    try std.testing.expect(std.mem.eql(u8, var_name.value.string, "x"));

    const var_value = var_decl.children[1];
    try std.testing.expect(var_value.node_type == NodeType.NumberLiteral);
    try std.testing.expect(var_value.value.number == 42);

    try std.testing.expect(parser.errors.items.len == 0);
}

test "Parser token navigation" {
    const allocator = std.testing.allocator;

    // Create tokens for: const x = 42;
    const tokens = [_]Token{
        Token.initSimple(.CONST, "const"),
        Token.initSimple(.IDENTIFIER, "x"),
        Token.initSimple(.EQUAL, "="),
        Token.initSimple(.NUMBER, "42"),
        Token.initSimple(.SEMICOLON, ";"),
    };

    var parser = Parser.init(allocator, &tokens);
    defer parser.deinit();

    // Test peek
    try std.testing.expect(parser.peek().?.type == .CONST);
    try std.testing.expect(parser.peekNext().?.lexeme.len == 4);

    // Test advance
    const first_token = parser.advance();
    try std.testing.expect(first_token.type == .CONST);
    try std.testing.expect(parser.peek().?.type == .IDENTIFIER);

    // Test check
    try std.testing.expect(!parser.check(.CONST));
    try std.testing.expect(parser.check(.IDENTIFIER));

    // Test match
    try std.testing.expect(parser.match(.IDENTIFIER));
    try std.testing.expect(!parser.match(.CONST));
    try std.testing.expect(parser.peek().?.type == .ASSIGN);

    // Test previous
    try std.testing.expect(parser.previous().?.type == .IDENTIFIER);
}
