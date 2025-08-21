const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board1.zig").createBoard;
const N_ROWS = 5;
const Board: type = createBoard(N_ROWS) catch unreachable;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    // test win/loss conditions
    const start = 0;
    var board: Board = try .init(allo, start);
    defer board.deinit();
    board.printBoard();

    // const list_of_idxs = {start, 3, 5, 1, 2, 3, 0, 5, 12, 11, 12, };
    // const list_of_dirs = {}
    board.chooseMove(start, .DownLeft);
    board.printBoard();
    try board.printMoves();
    // board.chooseMove(3, .Right);
    // board.printBoard();
    // board.chooseMove(5, .UpLeft);
    // board.printBoard();
    // board.chooseMove(1, .DownLeft);
    // board.printBoard();
    // board.chooseMove(2, .DownRight);
    // board.printBoard();
    // board.chooseMove(3, .DownRight);
    // board.printBoard();
    // board.chooseMove(0, .DownLeft);
    // board.printBoard();
    // board.chooseMove(5, .UpLeft);
    // board.printBoard();
    // board.chooseMove(12, .Left);
    // board.printBoard();
    // board.chooseMove(11, .Right);
    // board.printBoard();
    // board.chooseMove(12, .UpRight);
    // board.printBoard();
    // board.chooseMove(10, .Right);
    // board.printBoard();
    print("{}\n", .{board.isLost()});

    // print("{}\n", .{board.isLost()});
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
