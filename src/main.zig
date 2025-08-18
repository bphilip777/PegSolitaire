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

    // make this a test - ensure each start + direction works
    {
        const start = 0;
        var board: Board = try .init(allo, start);
        defer board.deinit();

        board.chooseMove(start, .DownLeft);
        board.printBoard();
        board.chooseMove(start, .DownRight);
        board.printBoard();
    }

    {
        const start = 8;
        var board: Board = try .init(allo, start);
        defer board.deinit();
        board.printBoard();

        board.chooseMove(start, .Left);
        board.printBoard();
        // board.chooseMove(start, .UpLeft);
        // board.printBoard();
    }

    {
        const start = 3;
        var board: Board = try .init(allo, start);
        defer board.deinit();
        board.chooseMove(start, .Right);
        board.printBoard();
        board.chooseMove(start, .UpRight);
        board.printBoard();
    }
}

// test "Set + Unsets Correct Pieces" {
//     // assumes board size of 5
//     // const start: []const u16 =  &.{0, 3, 8};
//     // const directions: []const []const Direction = &.{&.{.DownLeft, .DownRight}, &.{.UpLeft, .Left}, &.{.Right, .UpRight} };
//     // const expected_count: []const [] const u16 =  &.{&.{111111}, &.{}, &.{}};
//     // for (start, directions) |s, dirs| {
//     //     for (dirs) {
//     //         board.chooseMove(start, dir);
//     //         try std.testing.expect(board.board.eql(expected_count));
//     //     }
//     // }
// }

test "Run All Tests" {
    _ = @import("Board1.zig");
}
