const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
// helpers
const triNum = @import("helpers.zig").triNum;
// board
const createBoard = @import("Board.zig").createBoard;
const T = @import("helpers.zig").T;
const N_ROWS: T = 3;
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
    // _ = allo;
    // auto-solve board
    try dfs(allo, try .init(0));
}

fn dfs(allo: Allocator, start: Board) !void {
    // Aim: Get All Solutions
    // stack
    var stack: std.ArrayList(Board) = try .initCapacity(allo, 5);
    defer stack.deinit(allo);
    // add start position
    try stack.append(allo, start);
    // visited boards
    var visited: std.ArrayList(Board) = try .initCapacity(allo, 5);
    defer visited.deinit(allo);
    // loop
    while (stack.items.len > 0) {
        // moves stored in stack + visited
        const keep_on_stack = stack.getLast().nMoves() > 1;
        const prev_board = if (keep_on_stack) stack.getLast() else stack.pop().?;
        // check visited for prev_board
        const search = binarySearch(&visited, &prev_board);
        var board: Board = if (search.visited) visited.items[search.idx] else prev_board;
        // choose move
        const move = board.getMove();
        switch (move.dir) {
            .None => continue,
            else => {
                // copy board -> take move -> add to stack
                var new_board: Board = board.scopy();
                new_board.chooseMove(.{ .idx = move.idx }, move.dir);
                try stack.append(allo, new_board);
                // update stack + visited
                if (keep_on_stack) {
                    stack.items[stack.items.len - 1].moves[move.idx].remove(move.dir);
                }
                if (search.visited) {
                    visited.items[search.idx].moves[move.idx].remove(move.dir);
                } else {
                    if (search.idx >= visited.items.len) {
                        try visited.append(allo, board);
                    } else {
                        try visited.insert(allo, search.idx, board);
                    }
                }
            },
        }
    }
}

// future dfs - don't search every move, just unique ones

test "Run All Tests" {
    _ = @import("Board.zig");
}

const Search = struct {
    idx: T,
    visited: bool,
};

fn binarySearch(visited: *const std.ArrayList(Board), board: *const Board) Search {
    if (visited.items.len == 0) return .{ .idx = 0, .visited = false };
    var lo: T = 0;
    var hi: T = @truncate(visited.items.len - 1);
    var mid: T = (hi + lo) / 2;
    while (lo <= hi) {
        mid = (hi + lo) / 2;
        if (visited.items[mid].board.mask == board.board.mask) {
            return .{ .idx = mid, .visited = true };
        } else if (visited.items[mid].board.mask > board.board.mask) {
            if (mid == 0) break;
            hi = mid - 1;
        } else if (visited.items[mid].board.mask < board.board.mask) {
            if (mid == visited.items.len) break;
            lo = mid + 1;
        } else unreachable;
    }
    return .{ .idx = mid, .visited = false };
}

test "Binary Search" {
    // allocator
    const allo = std.testing.allocator;
    // values
    const values = [_]T{ 0, 1, 5, 9, 20, 30, 100 };
    // array containing boards
    var boards: std.ArrayList(Board) = try .initCapacity(allo, values.len);
    defer boards.deinit(allo);
    // create board values
    for (0..values.len) |i| {
        const value = values[i];
        try boards.append(allo, try Board.init(0));
        boards.items[i].board.mask = @truncate(value);
    }
    // create search values
    const search_values = [_]T{ 0, 4, 10, 30, 1_000 };
    var search_boards = [_]Board{try .init(0)} ** search_values.len;
    for (search_values, 0..search_boards.len) |value, i| {
        search_boards[i].board.mask = @truncate(value);
    }
    // create answers
    const answers = [_]Search{
        .{ .idx = 0, .visited = true },
        .{ .idx = 2, .visited = false },
        .{ .idx = 4, .visited = false },
        .{ .idx = 5, .visited = true },
        .{ .idx = 6, .visited = false },
    };
    // Test
    for (search_boards, answers) |search_board, answer| {
        const search = binarySearch(&boards, &search_board);
        try std.testing.expectEqual(search.visited, answer.visited);
        try std.testing.expectEqual(search.idx, answer.idx);
    }
}
