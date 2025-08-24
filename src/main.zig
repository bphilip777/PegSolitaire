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
    // memory
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

var arr: std.ArrayList(u16) = try .initCapacity(allo, 7);
    defer arr.deinit(allo);
    for ([_]u16{ 1, 3, 5, 7, 20, 30, 40 }) |v| try arr.append(allo, v);

    const inputs = [_]u16{ 4, 9, 30, 20 };
    const answers = [_]Search{
        .{ .visited = false, .idx = 0 },
        .{ .visited = false, .idx = 0 },
        .{ .visited = true, .idx = 5 },
        .{ .visited = false, .idx = 0 },
    };

    for (inputs, answers) |input, answer| {
        const new_search = binarySearch(&arr, input);
        print("New Search: {}\n", .{new_search});
        // try std.testing.expect(answer.visited == new_search.visited);
        if (answer.visited == true) {
            // try std.testing.expectEqual(answer.idx, new_search.idx);
        }
    }


    // // first board
    // const start = 0;
    // var start_board = try Board.init(allo, start);
    // defer start_board.deinit(allo);
    // // stack
    // var stack: std.ArrayList(*Board) = .initCapacity(allo, n_indices);
    // defer stack.deinit();
    // try stack.append(allo, &start_board);
    // // visited
    // var visited_boards: std.ArrayList(u16) = //
    //     try .initCapacity(allo, n_indices);
    // defer visited_boards.deinit(allo);
    // var visited_moves: std.ArrayList([n_indices]Directions) = try .initCapacity(n_indices);
    // defer visited_moves.deinit(allo);
    // // pop
    // const new_board = stack.pop().?;
    // // check if board was visited - use binary search to find a previous visited board
    // // var was_visited: bool = false;
    // // var visited_idx: u16 = 0;
    // // choose idx + dir
    // var new_idx: u16 = 0;
    // var new_dir: Direction = undefined;
    // outer: for (new_board.moves, 0..) |move, i| {
    //     for ([_]Direction{ .Left, .UpLeft, .UpRight, .Right, .DownRight, .DownLeft }) |dir| {
    //         if (move.contains(dir)) {
    //             new_idx = @truncate(i);
    //             new_dir = dir;
    //             break :outer;
    //         }
    //     }
    // }
    // // unset chosen moves
    // start_board.moves[new_idx].remove(new_dir);
    // // take move
    // start_board.chooseMove(new_idx, new_dir);
    // // add board?
}

const Search = struct { // 4 bytes
    visited: bool = false,
    idx: u16,
};

fn binarySearch(boards: *const std.ArrayList(u16), board: u16) Search {
    // assumes boards is sorted
    std.debug.assert(boards.items.len < std.math.maxInt(u16));
    var lo: u16 = 0;
    var hi: u16 = @truncate(boards.items.len - 1);
    while (lo <= hi and n_loops < 10) :(n_loops += 1) {
        const mid = (lo + hi) / 2;
        std.log.info("{} {} {}\n", .{lo, mid, hi});
        const new_board = boards.items[mid];
        if (new_board == board) {
            return .{
                .visited = true,
                .idx = mid,
            };
        } else if (new_board > board) {
            hi = mid - 1;
        } else if (new_board < board) {
            lo = mid + 1;
        }
    }
    return .{
        .visited = false,
        .idx = undefined,
    };
}

test "Binary Search" {
    const allo = std.testing.allocator;
    var arr: std.ArrayList(u16) = try .initCapacity(allo, 7);
    defer arr.deinit(allo);
    for ([_]u16{ 1, 3, 5, 7, 20, 30, 40 }) |v| try arr.append(allo, v);

    const inputs = [_]u16{ 4, 9, 30, 20 };
    const answers = [_]Search{
        .{ .visited = false, .idx = 0 },
        .{ .visited = false, .idx = 0 },
        .{ .visited = true, .idx = 5 },
        .{ .visited = false, .idx = 0 },
    };

    for (inputs, answers) |input, answer| {
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
