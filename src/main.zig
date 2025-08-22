const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board.zig").createBoard;
const N_ROWS = 5;
const Board: type = createBoard(N_ROWS) catch unreachable;
const Direction = @import("Borad.zig").Direction;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    _ = allo;
}

test "Undo Move" {
    const allo = std.testing.allocator;
    var board: Board = try .init(allo, 0);
    defer board.deinit();

    const Instruction = struct { idx: u16, dir: Direction, is_won: bool };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .value = 32757 },
        .{ .idx = 3, .dir = .Right, .value = 32717 },
        .{ .idx = 5, .dir = .UpLeft, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
    };

    for (list_of_instructions) |instruction| {
        try board.chooseMove(instruction.idx, instruction.dir);
    }

    for (0..list_of_instructions.len - 1) |i| {
        const j = list_of_instructions.len - 1 - i;
        const instruction = list_of_instructions[j];
        try board.undoMove();
        try std.testing.expectEqual(board.board.mask, instruction.value);
    }
}

test "Run All Tests" {
    _ = @import("Board.zig");
}
