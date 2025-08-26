const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
// helpers
const triNum = @import("helpers.zig").triNum;
// board
const createBoard = @import("Board.zig").createBoard;
const T = @import("helpers.zig").T;
const N_ROWS: T = 5;
const N_INDICES = triNum(N_ROWS);
const Board = createBoard(5) catch unreachable;

// TODO:
// Play Game:
// - Manual:
//  - need an external library for argument parsing
//  - zig-cli
//  - sigargs ... whatever
//  - another option is to parse inputs into main from commandline - currently empty
// - Auto:

pub fn main() !void {
    // memory
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    // auto-solve board
    try dfs(allo, 0);
}

fn dfs(allo: Allocator, start: T) !void {
    // Reduce memory footprint by using a multiarraylist over an arraylist
    var stack: std.ArrayList(Board) = try .initCapacity(allo, N_ROWS);
    defer stack.deinit();
    // null for initialization
    var visited: std.ArrayList(?Board) = try .initCapacity(allo, N_INDICES);
    defer visited.deinit();
    for (0..N_INDICES) |i| visited.items[i] = null;
    // add starting board
    const start_board: Board = .init(start);
    try stack.append(start_board);
    // loop
    while (stack.items.len > 0) {
        // get last board on stack
        const stack_board = stack.getLast();
        // check if game over for early break
        if (stack_board.isGameOver()) {
            stack_board.printBoard();
            stack_board.isWon();
        }
        // check if board was visited
        var was_visited: bool = undefined;
        var board: Board = undefined;
        if (visited.items[board.board.count()]) |visited_board| {
            board = visited_board;
            was_visited = true;
        } else {
            board = stack_board;
            was_visited = false;
        }
        // choose move
        const move = board.getMove();
        switch (move.dir) {
            .None => {
                _ = stack.pop().?;
            },
            else => |dir| {
                if (was_visited) {
                    visited.items[board.board.count()].?.moves[move.idx].remove(dir);
                } else {
                    var new_board = board;
                    new_board.moves[move.idx].remove(dir);
                    visited.items[board.board.count()] = new_board;
                }
                board.chooseMove(dir);
            },
        }
    }
}

test "Run All Tests" {
    _ = @import("Board.zig");
}

const Search = struct {
    idx: T,
    visited: bool,
};
