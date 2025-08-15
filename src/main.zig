const std = @import("std");

const createBoard = @import("Board.zig").createBoard;
const Moves = @import("Board.zig").Moves;
const print = std.debug.print;

const MovePair = struct { idx: u16, moves: Moves };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    const Board: type = createBoard(5);
    var b: Board = try .init(allo, 0);
    defer b.deinit();

    // create a dfs search to find where is won occurs
    // stack
    var all_boards: std.ArrayList(u16) = .init(allo);
    defer all_boards.deinit();
    // moves
    var all_moves: std.ArrayList(std.ArrayList(MovePair)) = .init(allo);
    defer all_moves.deinit();

    b.printBoard();
    // get all moves
    var mps = std.ArrayList(MovePair).init(allo);
    defer mps.deinit();
    for (b.moves.items, 0..) |moves, i| {
        if (moves.count() == 0) continue;
        const mp = MovePair{ .idx = @truncate(i), .moves = moves };
        try mps.append(mp);
    }
    print("MP List:\n", .{});
    for (mps.items) |mp| {
        print("{}: ", .{mp.idx});
        var it = mp.moves.iterator();
        while (it.next()) |item| print("{s} ", .{@tagName(item)});
        print("\n", .{});
    }

    // Manual:
    // b.printBoard();
    // b.printMoves();
    //
    // b.chooseMove(0, .DownRight);
    // b.printBoard();
    // b.printMoves();
}

test "Run All Tests" {
    _ = @import("Board.zig");
}
