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

    _ = allo;
}

// test "Lose Condition" {
//
// }

test "Run All Tests" {
    _ = @import("Board.zig");
}

test "Is Lost" {
    const allo = std.testing.allocator;
    var board: Board = try .init(allo, 0);
    defer board.deinit();

    const Instruction = struct { idx: u16, dir: Direction, is_lost: bool };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 3, .dir = .Right, .is_lost = false },
        .{ .idx = 5, .dir = .UpLeft, .is_lost = false },
        .{ .idx = 1, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 2, .dir = .DownRight, .is_lost = false },
        .{ .idx = 3, .dir = .DownRight, .is_lost = false },
        .{ .idx = 0, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 5, .dir = .UpLeft, .is_lost = false },
        .{ .idx = 12, .dir = .Left, .is_lost = false },
        .{ .idx = 11, .dir = .Right, .is_lost = false },
        .{ .idx = 12, .dir = .UpRight, .is_lost = false },
        .{ .idx = 10, .dir = .Right, .is_lost = true },
    };

    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
        try std.testing.expectEqual(board.isLost(), instruction.is_lost);
    }
}

test "Is Won" {
    const allo = std.testing.allocator;
    var board: Board = try .init(allo, 0);
    defer board.deinit();

    const Instruction = struct { idx: u16, dir: Direction, is_lost: bool };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 3, .dir = .Right, .is_lost = false },
        .{ .idx = 5, .dir = .UpLeft, .is_lost = false },
        .{ .idx = 1, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 2, .dir = .DownRight, .is_lost = false },
        .{ .idx = 3, .dir = .DownRight, .is_lost = false },
        .{ .idx = 0, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 5, .dir = .UpLeft, .is_lost = false },
        .{ .idx = 12, .dir = .Left, .is_lost = false },
        .{ .idx = 11, .dir = .Right, .is_lost = false },
        .{ .idx = 12, .dir = .UpRight, .is_lost = false },
        .{ .idx = 10, .dir = .Right, .is_lost = true },
    };

    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
        try std.testing.expectEqual(board.isLost(), instruction.is_lost);
    }
}
