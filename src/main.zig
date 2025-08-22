const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board.zig").createBoard;
const N_ROWS = 5;
const Board: type = createBoard(N_ROWS) catch unreachable;

// TODO:
// Play Game:
// - through cli
//  - zig-cli
//  - implement index vs positional moves
//  - implement positive vs negative moves
// - through automatic
//  - dfs - more optimized?
//  - bfs
// - document fns in document.md + add notes in README.md

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    _ = allo;

    // // DFS to auto-solve board
    // const start = 0;
    // var board = Board.init(start);
    //
    // // contains list of board
    // var stack = std.ArrayList(Board).init(allo);
    // defer stack.deinit();
    //
    // // contains list of visited states - turn off used moves
    // var visited = std.ArrayList(Board).init(allo);
    // defer visited.deinit();
    //
    // while (!board.isGameOver()) {
    //     // select move
    //     for (self.moves[idx]) |move| {
    //         if (move.)
    //     }
    //     //
    //     board.chooseMove();
    // }
    //
    // const end_str = if (board.isLost()) "You Lose!" else if (board.isWon()) "You Won!";
    // print("State: {s}\n", .{end_str});
}

test "Run All Tests" {
    _ = @import("Board.zig");
}
