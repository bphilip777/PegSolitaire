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
    // loop
    loop: while (stack.items.len > 0) {
        // Pop
        var new_board: Board = stack.pop().?.*;
        // check: 1. Was Visited 2. Sorted Index
        const search = binarySearch(&visited, &new_board);
        print("{any}\n", .{search});
        if (!search.visited) { // Not Visited
            // Store at index
            try visited.insert(search.idx, new_board);
        }
        // Duplicate board -> take move with new board
        var copied_board: Board = try allo.dupe(allo, Board, new_board);
        // choose dir
        var new_idx: u16 = 0;
        var new_dir: Direction = .None;
        outer: for (copied_board.moves, 0..) |move, i| {
            for ([_]Direction{ .Left, .UpLeft, .UpRight, .Right, .DownRight, .DownLeft }) |dir| {
                if (move.contains(dir)) {
                    new_idx = @truncate(i);
                    new_dir = dir;
                    break :outer;
                }
            }
        }
        // if chosen move == .none -> do not take move + do not remove -> otherwise remove
        switch (new_dir) {
            .None => continue :loop,
            else => {
                // take move
                copied_board.chooseMove(new_idx, new_dir);
                // remove move from original
                new_board.moves[new_idx].remove(new_dir);
                if (new_board.moves[new_idx] == 0)
                    new_board.moves[new_idx].set(.None);
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

// test "Binary Search" {
//     // create allocator
//     const allocator = std.testing.allocator;
//     // create board states
//     const states = [_]u16{ 1, 3, 5, 7, 20, 30, 40 };
//     // create board substates
//     const SubState = struct {
//         idx: u16,
//         symbol: u8,
//         valid: bool,
//     };
//     // create board
//     const MyBoard = struct {
//         states: SubState,
//
//         pub fn init(allo: Allocator) @This() {
//             var possible_states: std.MultiArrayList(SubState) = {};
//             try possible_states.ensureUnusedCapacity(allo, n_indices);
//             return .{
//                 .states = possible_states,
//             };
//         }
//
//         pub fn deinit(self: *@This(), allo: Allocator) void {
//             self.states.deinit(allo);
//         }
//     };
//     // create array
//     var arr: std.ArrayList(*MyBoard) = try .initCapacity(allocator, states.len);
//     defer {
//         for (arr.items) |board| board.deinit(allocator);
//         arr.deinit(allocator);
//     }
//     // set board state
//     for (states) |v| {
//         var board: MyBoard = try .init(allo, 0);
//         board.idx = v;
//         board.symbol = 'a';
//         board.valid = true;
//     }
// }

// test "Old Binary Search" {
//     const allo = std.testing.allocator;
//     // states
//     const states = [_]u16{ 1, 3, 5, 7, 20, 30, 40 };
//     // create array
//     var arr: std.ArrayList(*Board) = try .initCapacity(allo, states.len);
//     defer {
//         arr.items[0].deinit(allo);
//         arr.deinit(allo);
//     }
//     // add in new boards
//     for (states) |v| {
//         var board: Board = try .init(allo, 0);
//         board.board.mask = @truncate(v);
//         try arr.append(allo, &board);
//     }
//
//     var inputs: std.ArrayList(*Board) = try .initCapacity(allo, 4);
//     defer inputs.deinit(allo);
//     defer for (inputs.items) |board| board.*.deinit(allo);
//
//     for ([_]u16{ 4, 9, 30, 20 }) |v| {
//         var board: Board = try .init(allo, 0);
//         board.board.mask = @truncate(v);
//         try inputs.append(allo, &board);
//     }
//
//     const answers = [_]Search{
//         .{ .visited = false, .idx = 3 },
//         .{ .visited = false, .idx = 4 },
//         .{ .visited = true, .idx = 5 },
//         .{ .visited = true, .idx = 4 },
//     };
//
//     for (inputs.items, answers) |input, answer| {
//         const new_search = binarySearch(&arr, input);
//         try std.testing.expect(answer.visited == new_search.visited);
//         if (answer.visited == true) {
//             try std.testing.expectEqual(answer.idx, new_search.idx);
//         }
//     }
// }

test "Run All Tests" {
    _ = @import("Board.zig");
}
