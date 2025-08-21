const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board1.zig").createBoard;
const N_ROWS = 5;
const Board: type = createBoard(N_ROWS) catch unreachable;
const Direction = @import("Board1.zig").Direction;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    // test win/loss conditions
    const start = 0;
    var board: Board = try .init(allo, start);
    defer board.deinit();
    board.printBoard();

    const Instruction = struct { idx: u16, dir: Direction };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft },
        // .{ .idx = 3, .dir = .Right },
        // .{ .idx = 5, .dir = .UpLeft },
        // .{ .idx = 1, .dir = .DownLeft },
        // .{ .idx = 2, .dir = .DownRight },
        // .{ .idx = 3, .dir = .DownRight },
        // .{ .idx = 0, .dir = .DownLeft },
        // .{ .idx = 5, .dir = .UpLeft },
        // .{ .idx = 12, .dir = .Left },
        // .{ .idx = 11, .dir = .Right },
        // .{ .idx = 12, .dir = .UpRight },
        // .{ .idx = 10, .dir = .Right },
    };
    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
        board.printBoard();
        try board.printMoves();
        print("{}\n", .{board.isLost()});
    }
}

// test "Lose Condition" {
//
// }

test "Run All Tests" {
    _ = @import("Board1.zig");
}

// 0
// 1 2
// 3 4 5
// 6 7 8 9
// 0 1 2 3 4
