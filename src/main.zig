const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board.zig").createBoard;
const N_ROWS = 5;
const Board: type = createBoard(N_ROWS) catch unreachable;
const Direction = @import("Board.zig").Direction;
const Move = @import("Board.zig").Move;
const n_indices = @import("Board.zig").triNum(N_ROWS);

// TODO:
// Play Game:
// - through cli
//  - zig-cli
//  - implement index vs positional moves
//  - implement positive vs negative moves
// - through automatic
//  - implement binary search for visited nodes
//      - maybe have upfront allocation cost - number of indices combinations =
//  - dfs - better for board game?

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    // init board
    const start = 0;
    var start_board = try Board.init(allo, start);
    defer start_board.deinit(allo);

    // contains list of board
    var stack: std.ArrayList(Board) = try .initCapacity(allo, n_indices);
    defer stack.deinit(allo);
    try stack.append(allo, start_board);

    var visited: std.ArrayList(Board) = try .initCapacity(allo, n_indices);
    defer visited.deinit(allo);
    defer for (visited.items) |*visited_board| visited_board.deinit(allo);

    var board = stack.pop().?;
    // choose move
    const sliced = board.chosen_moves.slice();
    const chosen_dirs = sliced.items(.dir);
    for (chosen_dirs) |dir| print("{s}\n", .{@tagName(dir)});

    // while (true) {
    //     const board = stack.pop() orelse break;
    //
    //     // search visited
    //     for (visited.items) |visited_board| {
    //         // matched
    //         if (visited_board.board.mask == board.board.mask) {
    //             // check moves
    //             if (visited_board.hasRemainingMoves()) {
    //                 // pop off move -> turn off move -> move that direction -> append new board
    //                 const new_move =
    //             }
    //         }
    //     }
    // }
}

test "Run All Tests" {
    _ = @import("Board.zig");
    // DFS to auto-solve board
}
