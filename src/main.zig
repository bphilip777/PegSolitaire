const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board.zig").createBoard;
const Board: type = createBoard(5);
const Move = @import("Board.zig").Move;
const Moves = @import("Board.zig").Moves;
const IdxMoves = struct { idx: u16, moves: Moves }; // list of moves
const IdxMove = struct { idx: u16, move: Move }; // idx + move

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var b: Board = try .init(allo, 0);
    defer b.deinit();

    // DFS through all possible boards and moves to print win conditions
    var all_boards = std.ArrayList(u16).init(allo);
    defer all_boards.deinit();

    var all_moves = std.ArrayList(*std.ArrayList(IdxMoves)).init(allo);
    defer all_moves.deinit();

    b.printBoard();
    var new_moves: std.ArrayList(IdxMoves) = try getMoves(allo, &b);
    defer new_moves.deinit();

    const new_move: IdxMove = getMove(&new_moves);
    print("Move: {s}\n", .{@tagName(new_move.move)});
    b.chooseMove(new_move.idx, new_move.move);
    b.printBoard();
}

fn getMoves(allo: Allocator, b: *const Board) !std.ArrayList(IdxMoves) {
    var mps = std.ArrayList(IdxMoves).init(allo);
    // defer mps.deinit();
    for (b.moves.items, 0..) |moves, i| {
        if (moves.count() == 0) continue;
        const mp = IdxMoves{ .idx = @truncate(i), .moves = moves };
        try mps.append(mp);
    }
    return mps;
}

fn getMove(mps: *std.ArrayList(IdxMoves)) IdxMove {
    var mp = mps.*.items[mps.*.items.len - 1];
    var it = mp.moves.iterator();
    const move = it.next().?;
    mp.moves.remove(move);
    if (mp.moves.count() == 0) {
        _ = mps.*.pop().?;
    } else {
        mps.*.items[mps.*.items.len - 1] = mp;
    }
    return .{
        .idx = mp.idx,
        .move = move,
    };
}

fn reachedPreviousBoardState(all_boards: *const std.ArrayList(u16), b: *const Board) ?u16 {
    const curr_board: u16 = @truncate(b.board.count());
    for (all_boards.*.items, 0..) |prev_board, i| {
        if (curr_board == prev_board) return @truncate(i);
    } else return null;
}

fn printMPs(mps: *std.ArrayList(IdxMoves)) void {
    print("MP List\n", .{});
    for (mps.*.items) |mp| {
        print("{}: ", .{mp.idx});
        var it = mp.moves.iterator();
        while (it.next()) |item| print("{s} ", .{@tagName(item)});
        print("\n", .{});
    }
}

test "Run All Tests" {
    _ = @import("Board.zig");
}
