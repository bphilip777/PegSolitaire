const std = @import("std");
const auto = @import("Game.zig").auto;
const manual = @import("Game.zig").manual;

pub fn main() !void {
    // try auto();
    try manual();
}

test "Run All Tests" {
    _ = @import("Board.zig");
    _ = @import("Helpers.zig");
    _ = @import("Tokenizer.zig");
    _ = @import("Game.zig");
}
