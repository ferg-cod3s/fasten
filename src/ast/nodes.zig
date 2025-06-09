const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const Token = @import("../lexer/token.zig").Token;
const TokenType = @import("../lexer/token.zig").TokenType;

pub const SourceLocation = struct {
    line: u16,
    column: u16,
};

pub const Node = struct {
    node_type: NodeType,
    location: ?SourceLocation,
    data: NodeData,

    const Self = @This();

    pub const NodeData = union(NodeType) {
        // === Program Structure ===
        Program: void,

        // === Import/Export System ===
        ImportDeclaration: void, // TODO: implement later
        ImportSpecifier: void, // TODO: implement later
        ExportDeclaration: void, // TODO: implement later
        ExportDefaultDeclaration: void, // TODO: implement later

        // === Statements ===
        VariableDeclaration: void, // TODO: implement later
        FunctionDeclaration: void, // TODO: implement later
        ExpressionStatement: void, // TODO: implement later
        ReturnStatement: void, // TODO: implement later
        IfStatement: void, // TODO: implement later

        // === Expressions ===
        Identifier: []const u8,
        Literal: LiteralValue,
        CallExpression: void, // TODO: implement later
        BinaryExpression: BinaryExpressionData,
        MemberExpression: void, // TODO: implement later
    };

    pub const LiteralValue = union(enum) {
        String: []const u8,
        Number: f64,
        Boolean: bool,
        Null,
        Undefined,
    };

    pub const BinaryExpressionData = struct {
        left: *Node, // Pointer to left operand
        operator: []const u8, // Operator as a string
        right: *Node, // Pointer to right operand
    };

    /// Create a new identifier node
    pub fn createIdentifier(name: []const u8, location: ?SourceLocation) Self {
        return Self{
            .node_type = .Identifier,
            .location = location,
            .data = .{ .Identifier = name },
        };
    }

    /// Create a new string literal node
    pub fn createStringLiteral(value: []const u8, location: ?SourceLocation) Self {
        return Self{
            .node_type = .Literal,
            .location = location,
            .data = .{ .Literal = .{ .String = value } },
        };
    }

    /// Create a new program node
    pub fn createProgram(location: ?SourceLocation) Self {
        return Self{
            .node_type = .Program,
            .location = location,
            .data = .{ .Program = {} },
        };
    }

    /// Create a new binary expression node
    pub fn createBinaryExpression(left: *Node, operator: []const u8, right: *Node, location: ?SourceLocation) Self {
        return Self{
            .node_type = .BinaryExpression,
            .location = location,
            .data = .{ .BinaryExpression = .{
                .left = left,
                .operator = operator,
                .right = right,
            } },
        };
    }
};

pub const NodeType = enum {
    // === Program Structure ===
    Program, // Root of the AST

    // === Import/Export System ===
    ImportDeclaration, // import { x } from "y"
    ImportSpecifier, // the "x" part
    ExportDeclaration, // export { x }
    ExportDefaultDeclaration, // export default x

    // === Statements (things that DO stuff) ===
    VariableDeclaration, // const x = 1
    FunctionDeclaration, // function foo() {}
    ExpressionStatement, // someFunction();
    ReturnStatement, // return x;
    IfStatement, // if (condition) { ... }

    // === Expressions (things that PRODUCE values) ===
    Identifier, // variable names
    Literal, // "string", 123, true
    CallExpression, // foo()
    BinaryExpression, // x + y
    MemberExpression, // obj.prop

    pub fn toString(self: NodeType) []const u8 {
        return switch (self) {
            .Program => "Program",
            .ImportDeclaration => "ImportDeclaration",
            .ImportSpecifier => "ImportSpecifier",
            .ExportDeclaration => "ExportDeclaration",
            .ExportDefaultDeclaration => "ExportDefaultDeclaration",
            .VariableDeclaration => "VariableDeclaration",
            .FunctionDeclaration => "FunctionDeclaration",
            .ExpressionStatement => "ExpressionStatement",
            .ReturnStatement => "ReturnStatement",
            .IfStatement => "IfStatement",
            .Identifier => "Identifier",
            .Literal => "Literal",
            .CallExpression => "CallExpression",
            .BinaryExpression => "BinaryExpression",
            .MemberExpression => "MemberExpression",
        };
    }

    pub fn isExpression(self: NodeType) bool {
        return switch (self) {
            .Identifier, .Literal, .CallExpression, .BinaryExpression => true,
            else => false,
        };
    }
};

test "NodeType basic functionality" {
    const node_type = NodeType.Identifier;

    // Test toString method
    try std.testing.expect(std.mem.eql(u8, node_type.toString(), "Identifier"));

    // Test switch statement
    const result = switch (node_type) {
        .Identifier => "is_identifier",
        else => "not_identifier",
    };

    try std.testing.expect(std.mem.eql(u8, result, "is_identifier"));
}

test "NodeType toString method" {
    // Test a few different node types
    try std.testing.expect(std.mem.eql(u8, NodeType.Program.toString(), "Program"));
    try std.testing.expect(std.mem.eql(u8, NodeType.Identifier.toString(), "Identifier"));
    try std.testing.expect(std.mem.eql(u8, NodeType.ImportDeclaration.toString(), "ImportDeclaration"));
}

test "NodeType switch statements work" {
    const node_type = NodeType.Identifier;

    const result = switch (node_type) {
        .Program => "program",
        .Identifier => "identifier",
        .ImportDeclaration => "import",
        else => "other",
    };

    try std.testing.expect(std.mem.eql(u8, result, "identifier"));
}

test "NodeType classification methods" {
    // If you added helper methods like isExpression()
    try std.testing.expect(NodeType.Identifier.isExpression());
    try std.testing.expect(!NodeType.Program.isExpression());
}

test "Node creation and basic functionality" {
    const location = SourceLocation{ .line = 10, .column = 5 };

    // Test identifier creation
    const identifier = Node.createIdentifier("myVariable", location);
    try std.testing.expect(identifier.node_type == .Identifier);
    try std.testing.expect(std.mem.eql(u8, identifier.data.Identifier, "myVariable"));
    try std.testing.expect(identifier.location.?.line == 10);

    // Test string literal creation
    const literal = Node.createStringLiteral("hello", location);
    try std.testing.expect(literal.node_type == .Literal);
    try std.testing.expect(std.mem.eql(u8, literal.data.Literal.String, "hello"));

    // Test program creation
    const program = Node.createProgram(null);
    try std.testing.expect(program.node_type == .Program);
    try std.testing.expect(program.location == null);
}

test "BinaryExpression node creation" {
    const allocator = std.testing.allocator;

    // Create left and right operands
    const left = try allocator.create(Node);
    defer allocator.destroy(left);
    left.* = Node.createIdentifier("x", null);

    const right = try allocator.create(Node);
    defer allocator.destroy(right);
    right.* = Node.createIdentifier("y", null);

    // Create binary expression: x + y
    const binary_expr = Node.createBinaryExpression(left, "+", right, null);

    try std.testing.expect(binary_expr.node_type == .BinaryExpression);
    try std.testing.expect(std.mem.eql(u8, binary_expr.data.BinaryExpression.operator, "+"));
    try std.testing.expect(binary_expr.data.BinaryExpression.left.node_type == .Identifier);
    try std.testing.expect(binary_expr.data.BinaryExpression.right.node_type == .Identifier);

    // Check that BinaryExpression is classified as an expression
    try std.testing.expect(NodeType.BinaryExpression.isExpression());
}
