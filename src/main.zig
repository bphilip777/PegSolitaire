const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board.zig").createBoard;
const N_ROWS = 5;
const Board: type = createBoard(N_ROWS) catch unreachable;

// TODO:
// Play Game:
// - through cli
// - through automatic
// - document fns in document.md + add notes in README.md

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    _ = allo;

    // now i need to add automatic search functionality
}

test "Run All Tests" {
    _ = @import("Board.zig");
}
