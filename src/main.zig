const std = @import("std");
const print = std.debug.print;
// const Board = @import("Board.zig");
const createBoard = @import("Board1.zig").createBoard;
const Position = @import("Position.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    const Board = try createBoard(5);
    const board = try Board.init(allo, Position{.row = 0, .col = 0});
    defer board.deinit();
    board.showBoard();
    board.showMoves();
    // try board.newMoves();


    // Tests with bit sets

        // var board = try Board.init(allo, 5, .{ .row = 0, .col = 0 });
    // defer board.deinit();
    // board.showBoard();
    // board.showNewMoves();

    // while (!board.isLost()) {
    //     try board.chooseMove();
    //     board.showBoard();
    //     board.showNewMoves();
    // }
    // print("Game {s}\n", .{if (board.isLost()) "Lost" else "Won"});

    // board.showAllMoves();
}

test "Basic Board Inputs" {
    // var board = try Board.init(allo, 6, .{ .row = 1, .col = 0 });
    // defer board.deinit();
    // board.showBoard();
    // board.showMoves();
    // expect 3x0 -> 1x0, 3x2 -> 1x0
}

