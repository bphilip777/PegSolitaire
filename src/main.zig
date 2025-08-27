const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
// helpers
const triNum = @import("helpers.zig").triNum;
const numMoves = @import("helpers.zig").numMoves;
const idxFromPos = @import("helpers.zig").idxFromPos;
const posFromIdx = @import("helpers.zig").posFromIdx;
const Direction = @import("helpers.zig").Direction;
// board
const createBoard = @import("Board.zig").createBoard;
const T = @import("helpers.zig").T;
const N_ROWS: T = 3;
const N_INDICES = triNum(N_ROWS);
const Board = createBoard(N_ROWS) catch unreachable;

// TODO:
// Play Game:
// - Manual:
//  - need an external library for argument parsing
//  - zig-cli
//  - sigargs ... whatever
//  - another option is to parse inputs into main from commandline - currently empty

pub fn main() !void {
    // memory
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    // _ = allo;
    // auto-solve board
    try dfs(allo, try .init(0));
}

// Move All Of Below Into Auto Section of Game
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

fn dfs(allo: Allocator, start: Board) !void {
    // To Do:
    // - reduce memory foot print with std.MultiArrayList
    // - reduce number of solutions checked by removing symmetrical answers

    // stack
    var stack: std.ArrayList(Board) = try .initCapacity(allo, 5);
    defer stack.deinit(allo);
    // append initial board state
    try stack.append(allo, start);
    // previously visited boards
    var visited: std.ArrayList(Board) = try .initCapacity(allo, 5);
    defer visited.deinit(allo);
    // loop controls
    // var loop: usize = 0;
    // const limit: usize = 1_024;
    // // loop
    // while (stack.items.len > 0 and loop < limit) : (loop += 1) {
    print("Loop: {}\n", .{loop});
    print("Stack Depth: {}\n", .{stack.items.len});
    // pop previous board
    const prev_board = stack.pop().?;
    prev_board.printBoard();
    if (prev_board.isLost()) continue;
    if (prev_board.isWon()) {
        print("Winning Sequence:\n", .{});
        for (0..prev_board.chosen_idxs.len) |i| {
            const j = prev_board.board.capacity() - i - 1;
            if (prev_board.chosen_dirs[j] == .None) break;
            print("{}: {s}\n", .{ prev_board.chosen_idxs[j], @tagName(prev_board.chosen_dirs[j]) });
        }
        break;
    }
    const search = binarySearch(&visited, &prev_board);
    var board = if (search.visited) visited.items[search.idx] //
        else prev_board;
    const num_moves = board.numMovesLeft();
    print("Num Moves: {}\n", .{num_moves});
    try board.printMoves(allo);
    const move = board.getMove();
    if (move.dir == .None) continue;
    var new_board = board;
    new_board.chooseMove(.{ .idx = move.idx }, move.dir);
    // remove moves
    board.moves[move.idx].remove(move.dir);
    const other_idx = idxFromPos(Board.getRotation(Board.getRotation(posFromIdx(move.idx), move.dir, .full).?, move.dir, .full).?);
    const other_dir = Direction.opposite(move.dir);
    board.moves[other_idx].remove(other_dir);
    // flip board
    const flip_prev_board = prev_board.flip();
    const search2 = binarySearch(&visited, &flip_prev_board);
    var flip_board = if (search2.visited) visited.items[search2.idx] //
        else flip_prev_board;
    flip_board.moves[move.idx].remove(Direction.flip(move.dir));
    // remove flip moves
    flip_board.moves[flip_move.idx]
    // if board has moves, append onto stack
    if (board.numMovesLeft() > 0) {
        try stack.append(allo, board);
    }
    // if board was visited, modify, if board wasn't append
    if (search.visited) {
        visited.items[search.idx] = board;
    } else {
        try visited.append(allo, board);
    }
    // update stack with new board
    try stack.append(allo, new_board);
    // }
}

// future dfs - don't search every move, just unique ones

test "Run All Tests" {
    _ = @import("Board.zig");
}

// Board Size 3 = Unwinnable
// Board Size 4 = Unwinnable
