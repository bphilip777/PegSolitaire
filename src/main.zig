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
    // first board
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
    // DFS
    while (stack.items.len > 0) {
        // pop
        var new_board: Board = stack.pop().?.*;
        // check if board was visited: yes = use its moves, no = don't
        const search = binarySearch(&visited, new_board.board.mask);
        if (search.visited) {} else {
            try visited.append(allo, &new_board);
        }
        // choose dir
        var new_idx: u16 = 0;
        var new_dir: Direction = .None;
        outer: for (new_board.moves, 0..) |move, i| {
            for ([_]Direction{ .Left, .UpLeft, .UpRight, .Right, .DownRight, .DownLeft }) |dir| {
                if (move.contains(dir)) {
                    new_idx = @truncate(i);
                    new_dir = dir;
                    break :outer;
                }
            }
        }
        print("{}: {s}\n", .{ new_idx, @tagName(new_dir) });
        // take move
        new_board.chooseMove(new_idx, new_dir);
        // add board?
    }
}

const Search = struct { // 4 bytes
    visited: bool = false,
    idx: u16,
};

fn binarySearch(boards: *const std.ArrayList(Board), mask: u16) Search {
    // assumes boards is sorted
    // Search:
    // visited = bool = does it exist
    // idx = where in array would mask be found if it did exist
    std.debug.assert(boards.items.len < std.math.maxInt(u16));
    if (boards.items.len == 0) return .{ .visited = false, .idx = 0 };
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
        } else if (new_mask > mask) {
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
    var arr: std.ArrayList(u16) = try .initCapacity(allo, 7);
    defer arr.deinit(allo);
    for ([_]u16{ 1, 3, 5, 7, 20, 30, 40 }) |v| try arr.append(allo, v);

    const inputs = [_]u16{ 4, 9, 30, 20 };
    const answers = [_]Search{
        .{ .visited = false, .idx = 3 },
        .{ .visited = false, .idx = 4 },
        .{ .visited = true, .idx = 5 },
        .{ .visited = true, .idx = 4 },
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
