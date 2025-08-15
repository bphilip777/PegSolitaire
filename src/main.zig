const std = @import("std");

const createBoard = @import("Board.zig").createBoard;
const idx2pos = @import("Board.zig").idx2pos;
const pos2idx = @import("Board.zig").pos2idx;
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    const Board: type = createBoard(5);
    var b: Board = try .init(allo, 0);
    defer b.deinit();

    // b.printBoard();
    try b.updateMoves(0);
}

test "Run All Tests" {
    _ = @import("Board.zig");
}
