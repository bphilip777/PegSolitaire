const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board.zig").createBoard;
const N_ROWS = 5;
const Board: type = createBoard(N_ROWS) catch unreachable;
const Direction = @import("Board.zig").Direction;
const Move = @import("Board.zig").Move;

// TODO:
// Play Game:
// - through cli
//  - zig-cli
//  - implement index vs positional moves
//  - implement positive vs negative moves
// - through automatic
//  - implement binary search for visited nodes
//      - maybe have upfront allocation cost - number of indices combinations =
//  - dfs - more optimized?
//  - bfs
// - document fns in document.md + add notes in README.md
// - how to iterate over the fields of an enum
// should I implement a std.MultiArrayListof these values
// Optimize:
//  - reduce # of bytes:
//  - used null (Total 110 Bytes)
//  - changed to enum (80 Bytes) - still wasting 15 bytes
//  - MultiArrayList (48 Bytes)
//  _ swapped above for arrays -> 64 bytes instead

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allo = gpa.allocator();
    // defer std.debug.assert(gpa.deinit() == .ok);

    // var board = try Board.init(allo, 0);
    var board = try Board.init(0);
    // defer board.deinit(allo);

    print("Direction: {}\n", .{@sizeOf(Direction)});
    print("Move Idx: {}\n", .{@sizeOf(u16)});
    print("Move: {}\n", .{@sizeOf(Move)});
    print("{} Moves: {}\n", .{ board.board.capacity(), board.board.capacity() * @sizeOf(Move) });
    // print("Max u16: {}\n", .{std.math.maxInt(u16)});
    print("Board: {}\n", .{@sizeOf(Board)});
}

// pub fn main() !void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     const allo = gpa.allocator();
//     defer std.debug.assert(gpa.deinit() == .ok);
//     _ = allo;
//
//     // DFS to auto-solve board
//     const start = 0;
//     var board = Board.init(start);
//
//     // contains list of board
//     var stack = std.ArrayList(Board).init(allo);
//     defer stack.deinit();
//     try stack.append(board);
//
//     // contains list of visited states - turn off used moves
//     var visited = std.ArrayList(Board).init(allo);
//     defer visited.deinit();
//
//     loop: while (stack.items.len > 0) {
//         // Steps:
//         // 0. pop board state
//         // 1. check if board was visited
//         //  - if visited ->
//         //      use visited version b/c it has fewer moves ->
//         //      if 0 moves continue outer loop
//         // 1. add board state
//         // 2. select move
//         // 3. choose move
//         // 4. create new board state
//
//         // pop board state
//         var current_board = stack.pop().?;
//
//         // search through previous visited boards for it
//         for (visited.items, 0..) |visited_board, i| {
//             if (visited_board.board.eql(board.board)) {
//                 // check remaining moves
//                 if (!visited_board.hasRemainingMoves()) continue :loop;
//                 // matches but has moves
//                 current_board = visited_board;
//             }
//         }
//
//         // select move
//         const idx: @TypeOf(board.start), const chosen_move: Direction = blk: {
//             var idx: @TypeOf(board.start) = undefined;
//             var chosen_move: Direction = undefined;
//             for (board.moves, 0..) |move, i| {
//                 for ([_]Direction{
//                     .Left,
//                     .UpLeft,
//                     .UpRight,
//                     .Right,
//                     .DownRight,
//                     .DownLeft,
//                 }) |dir| {
//                     if (move.contains(dir)) {
//                         // get idx + move
//                         chosen_move = dir;
//                         idx = @truncate(i);
//                         // turn off old move
//                         board.moves[idx].remove(chosen_move);
//                         // return idx + move
//                         break :blk .{ idx, chosen_move };
//                     }
//                 }
//             }
//             unreachable;
//         };
//
//         // choose move -> creates new board
//         board.chooseMove(idx, chosen_move);
//     }
//
//     const end_str = if (board.isLost()) "You Lose!" else if (board.isWon()) "You Won!";
//     print("State: {s}\n", .{end_str});
// }

test "Run All Tests" {
    _ = @import("Board.zig");
}
