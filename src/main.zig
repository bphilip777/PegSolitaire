const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board.zig").createBoard;
const N_ROWS = 5;
const Board: type = createBoard(N_ROWS) catch unreachable;
const Direction = @import("Board.zig").Direction;
const Directions = @import("Board.zig").Directions;
const Move = @import("Board.zig").Move;
const n_indices = @import("Board.zig").triNum(N_ROWS);
const getAllMoves = @import("Board.zig").getAllMoves;

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
//      - want few multiarraylists - reduce that overhead rather than what i am doing

pub fn main() !void {
    // memory
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    // auto-solve board
    try dfs(allo);
}

fn dfs(allo: Allocator) !void {
    // init board
    const start = 0;
    var start_board: Board = try .init(allo, start);
    // stack
    var stack: std.ArrayList(*Board) = try .initCapacity(allo, n_indices);
    defer stack.deinit(allo);
    try stack.append(allo, &start_board);
    // visited
    var visited: std.ArrayList(*Board) = try .initCapacity(allo, n_indices);
    defer visited.deinit(allo);
    defer for (visited.items) |board| board.deinit(allo);
    // limiter = for testing
    var limiter: u16 = 0;
    // loop
    while (stack.items.len > 0 and limiter < 10) : (limiter += 1) {
        //  in stack -> if last item has 2+ moves - getLast() = keeps on stack
        //           -> else pop()
        const new_board: *Board = //
            if (getAllMoves(&(stack.getLast().*.moves)) > 1)
                stack.getLast() //
            else //
                stack.pop().?; //
        // check: Was Visited + Sorted Index
        const search = binarySearch(&visited, new_board);
        print("{any}\n", .{search});
        if (!search.visited) { // Not Visited
            // Store at index = store in order
            try visited.insert(allo, search.idx, new_board);
        }
        // Duplicate board -> take move with duplicated board
        var copied_board: *Board = @ptrCast(try allo.dupe(Board, @ptrCast(new_board)));
        // choose dir
        var new_idx: u16 = 0;
        var new_dir: Direction = .None;
        outer: for (copied_board.moves, 0..) |move, i| {
            for ([_]Direction{
                .Left,
                .UpLeft,
                .UpRight,
                .Right,
                .DownRight,
                .DownLeft,
            }) |dir| {
                if (move.contains(dir)) {
                    new_idx = @truncate(i);
                    new_dir = dir;
                    break :outer;
                }
            }
        }
        // if chosen move == .None
        //      -> check if game was won
        //          -> print winning moves
        // if chosen move != .None
        //      -> choose move
        //      -> remove move from old board
        //      -> add new board to stack
        switch (new_dir) {
            .None => {
                if (copied_board.isWon()) return;
            },
            else => {
                copied_board.chooseMove(new_idx, new_dir);
                new_board.moves[new_idx].remove(new_dir);
                try stack.append(allo, copied_board);
            },
        }
    }
}

const Search = struct { // 4 bytes
    visited: bool = false,
    idx: u16,
};

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

test "Run All Tests" {
    _ = @import("Board.zig");
}
