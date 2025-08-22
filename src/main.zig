const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board.zig").createBoard;
const N_ROWS = 5;
const Board: type = createBoard(N_ROWS) catch unreachable;
const Direction = @import("Board.zig").Direction;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var board: Board = try .init(allo, 0);
    defer board.deinit();

    const Instruction = struct { idx: u16, dir: Direction, value: u16 };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 3, .dir = .UpRight, .value = 32757 },
        .{ .idx = 5, .dir = .Left, .value = 32717 },
        .{ .idx = 0, .dir = .DownRight, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
        .{ .idx = 12, .dir = .Left, .value = 28960 },
        .{ .idx = 11, .dir = .Right, .value = 18720 },
        .{ .idx = 12, .dir = .UpRight, .value = 22528 },
        .{ .idx = 10, .dir = .Right, .value = 17408 },
    };
    // Original Moves
    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
    }
    // Undo
    for (0..list_of_instructions.len - 1) |i| {
        _ = i;
        // const instruction = list_of_instructions[i];
        board.undoMove();
        board.printBoard();
        try board.printMoves();
        // try std.testing.expectEqual(instruction.value, board.board.mask);
    }
    // Redo
    for (0..list_of_instructions.len - 1) |i| {
        _ = i;
        // const instruction = list_of_instructions[i];
        board.redoMove();
        board.printBoard();
        try board.printMoves();
        // try std.testing.expectEqual(instruction.value, board.board.mask);
    }
}

test "Undo Move + Redo Move" {
    const allo = std.testing.allocator;
    var board: Board = try .init(allo, 0);
    defer board.deinit();
}

test "Run All Tests" {
    _ = @import("Board.zig");
}
