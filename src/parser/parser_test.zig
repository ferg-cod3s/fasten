const std = @import("std");
const Token = @import("fasten_lib").lexer.Token;
const Parser = @import("parser.zig").Parser;
const NodeType = @import("fasten_lib").ast.nodes.NodeType;

test "Parser should handle empty input" {
    const allocator = std.testing.allocator;
    const tokens = [_]Token{}; // Empty token array
    var parser = Parser.init(allocator, &tokens);
    defer parser.deinit();

    const ast = try parser.parse();
    try std.testing.expect(ast.node_type == NodeType.Program);
    try std.testing.expect(ast.children.len == 0);
    try std.testing.expect(parser.errors.items.len == 0);
}
