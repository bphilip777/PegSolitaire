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
    var stack: std.ArrayList(Board) = .initCapacity(allo, N_ROWS);
    defer stack.deinit();
    // null for initialization
    var visited: std.ArrayList(?Board) = .initCapacity(allo, N_INDICES);
    defer visited.deinit();
    for (0..N_INDICES) |i| visited.items[i] = null;
    // add starting board
    const start_board = Board.init(start);
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
        if (visited.items[board.board.capacity()]) |visited_board| {
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
                    visited.items[board.board.capacity()].?.moves[move.idx].remove(dir);
                } else {
                    var new_board = board;
                    new_board.moves[move.idx].remove(dir);
                    visited.items[board.board.capacity()] = new_board;
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

// Leaving this here for now - may not cause trouble
fn binarySearch(boards: *const std.ArrayList(*Board), board: *const Board) Search {
    // assumes boards is sorted
    // Search:
    // visited = bool = does it exist
    // idx = where in array would mask be found if it did exist
    std.debug.assert(boards.items.len < std.math.maxInt(u16));
    if (boards.items.len == 0) return Search{ .visited = false, .idx = 0 };
    const mask = board.board.mask;
    var lo: u16 = 0;
    var hi: u16 = @truncate(boards.items.len - 1);
    var mid: u16 = undefined;
    while (lo <= hi) {
        mid = (lo + hi) / 2;
        const new_mask = boards.items[mid].board.mask;
        if (new_mask == mask) {
            return .{
                .visited = true,
                .idx = mid,
            };
        }
        if (mid == 0 or mid == boards.items.len) break;
        if (new_mask > mask) {
            hi = mid - 1;
        } else if (new_mask < mask) {
            lo = mid + 1;
        }
    }
    return .{
        .visited = false,
        .idx = mid,
    };
}

// Needs to be held in another meta-file
test "Binary Search" {
    const allo = std.testing.allocator;
    // states
    const states = [_]u16{ 1, 3, 5, 7, 20, 30, 40 };
    // create array
    var arr: std.ArrayList(*Board) = try .initCapacity(allo, states.len);
    defer arr.deinit();
    defer for (arr.items) |board| board.deinit();
    // add in new boards
    for (states) |v| {
        var board: Board = try .init(allo, 0);
        board.board.mask = @truncate(v);
        try arr.append(allo, &board);
    }
    // create inputs
    var inputs: std.ArrayList(*Board) = try .initCapacity(allo, 4);
    defer inputs.deinit(allo);
    defer for (inputs.items) |board| board.*.deinit(allo);
    // create board
    for ([_]u16{ 4, 9, 30, 20 }) |v| {
        var board: Board = try .init(allo, 0);
        board.board.mask = @truncate(v);
        try inputs.append(allo, &board);
    }

    const answers = [_]Search{
        .{ .visited = false, .idx = 3 },
        .{ .visited = false, .idx = 4 },
        .{ .visited = true, .idx = 5 },
        .{ .visited = true, .idx = 4 },
    };
    // check answers
    for (inputs.items, answers) |input, answer| {
        const new_search = binarySearch(&arr, input);
        try std.testing.expect(answer.visited == new_search.visited);
        if (answer.visited == true) {
            try std.testing.expectEqual(answer.idx, new_search.idx);
        }
    }
}
