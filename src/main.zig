const std = @import("std");
const auto = @import("Game.zig").auto;
const manual = @import("Game.zig").manual;

pub fn main() !void {
    // handle memory - should be moved to main
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    // try auto(allo);
    try manual(allo);
}

test "Run All Tests" {
    _ = @import("Helpers.zig");
    _ = @import("Lexer.zig");
    _ = @import("Parser.zig");
    _ = @import("Board.zig");
    _ = @import("Game.zig");
}
