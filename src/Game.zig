const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
// helpers
const triNum = @import("helpers.zig").triNum;
const numMoves = @import("helpers.zig").numMoves;
const idxFromPos = @import("helpers.zig").idxFromPos;
const posFromIdx = @import("helpers.zig").posFromIdx;
const flipIdx = @import("helpers.zig").flipIdx;
const Direction = @import("helpers.zig").Direction;
// board
const createBoard = @import("Board.zig").createBoard;
const T = @import("helpers.zig").T;
const N_ROWS: T = 5; // 7 -> 86 -> 768
const N_INDICES: T = triNum(N_ROWS);
const Board: type = createBoard(N_ROWS) catch unreachable;

pub fn manual() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    _ = allo;
}

pub fn auto() !void {
    // Auto-Solve Board
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    // try dfsFirst(allo, try .init(0));
    try dfsAll(allo, try .init(0));
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

fn dfsFirst(allo: Allocator, start: Board) !void {
    // Finds First Solution And Prints It
    // stack
    var stack: std.ArrayList(Board) = try .initCapacity(allo, 5);
    defer stack.deinit(allo);
    // append initial board state
    try stack.append(allo, start);
    // previously visited boards
    var visited: std.ArrayList(Board) = try .initCapacity(allo, 5);
    defer visited.deinit(allo);
    // check if won
    var winning_board: ?Board = null;
    // loop controls
    var loop: usize = 0;
    const limit: usize = std.math.maxInt(T);
    // // loop
    while (stack.items.len > 0 and loop < limit) : (loop += 1) {
        // print("Loop: {}\n", .{loop});
        // print("Stack Depth: {}\n", .{stack.items.len});
        // pop previous board
        const prev_board = stack.pop().?;
        // prev_board.printBoard();
        if (prev_board.isLost()) continue;
        if (prev_board.isWon()) {
            winning_board = prev_board;
            break;
        }
        const search = binarySearch(&visited, &prev_board);
        var board = if (search.visited) visited.items[search.idx] //
            else prev_board;
        // const num_moves = board.numMovesLeft();
        // print("Num Moves: {}\n", .{num_moves});
        // try board.printMoves(allo);
        // get move
        const move = board.getMove();
        if (move.dir == .None) continue;
        // choose move
        var new_board = board;
        new_board.chooseMove(.{ .idx = move.idx }, move.dir);
        // Get symmetrical board
        const flip_prev_board = prev_board.flip();
        const search2 = binarySearch(&visited, &flip_prev_board);
        var flipped_board = if (search2.visited) visited.items[search2.idx] //
            else flip_prev_board;
        const flip_move = move.flip();
        { // Remove Moves
            board.moves[move.idx].remove(move.dir);
            const mid_idx = Board.getRotation(posFromIdx(move.idx), move.dir, .full).?;
            const other_idx = idxFromPos(Board.getRotation(mid_idx, move.dir, .full).?);
            const other_dir = move.dir.opposite();
            board.moves[other_idx].remove(other_dir);
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
        }
        { // Remove symmetrical moves
            flipped_board.moves[flip_move.idx].remove(flip_move.dir);
            const flip_mid_idx = Board.getRotation(posFromIdx(flip_move.idx), flip_move.dir, .full).?;
            const flip_other_idx = idxFromPos(Board.getRotation(flip_mid_idx, flip_move.dir, .full).?);
            const flip_other_dir = flip_move.dir.opposite();
            flipped_board.moves[flip_other_idx].remove(flip_other_dir);
            // if flipboard was visited, modify, if flipped board wasn't append
            if (search2.visited) {
                visited.items[search2.idx] = flipped_board;
            } else {
                try visited.append(allo, flipped_board);
            }
        }
        // update stack with new board
        try stack.append(allo, new_board);
    }
    if (winning_board) |win| {
        print("Winning Sequence:\n", .{});
        for (0..win.chosen_idxs.len) |i| {
            const j = win.board.capacity() - i - 1;
            if (winning_board.?.chosen_dirs[j] == .None) break;
            print("{}: {s}\n", .{ win.chosen_idxs[j], @tagName(win.chosen_dirs[j]) });
        }
    } else {
        print("No Solutions Found for {} rows!\n", .{N_ROWS});
    }
}

test "Will MultiArrayList Help" {
    const al = std.ArrayList(Board);
    const ma = std.MultiArrayList(Board);
    try std.testing.expect(@sizeOf(al) == @sizeOf(ma));
    print("Memory Size: {} - {}\n", .{ @sizeOf(std.ArrayList(Board)), @sizeOf(std.MultiArrayList(Board)) });
}

fn dfsAll(allo: Allocator, start: Board) !void {
    // stack
    var stack: std.ArrayList(Board) = try .initCapacity(allo, 5);
    defer stack.deinit(allo);
    // append initial board state
    try stack.append(allo, start);
    // previously visited boards
    var visited: std.ArrayList(Board) = try .initCapacity(allo, 5);
    defer visited.deinit(allo);
    // store wins
    var wins: std.ArrayList(Board) = try .initCapacity(allo, 5);
    defer wins.deinit(allo);
    // loop
    // var loop: usize = 0;
    // const limit: usize = std.math.maxInt(u16);
    // while (stack.items.len > 0 and loop < limit) : (loop += 1) {
    while (stack.items.len > 0) {
        // pop previous board
        const prev_board = stack.pop().?;
        // if (prev_board.isLost()) continue;
        if (prev_board.isWon()) {
            // ordered insert into list
            const search = binarySearch(&wins, &prev_board);
            if (search.visited) {
                try wins.insert(allo, search.idx, prev_board);
            } else {
                if (search.idx < wins.items.len) {
                    try wins.insert(allo, search.idx, prev_board);
                } else {
                    try wins.append(allo, prev_board);
                }
            }
        }
        if (prev_board.isGameOver()) continue;
        const search = binarySearch(&visited, &prev_board);
        var board = if (search.visited) visited.items[search.idx] //
            else prev_board;
        // get move
        const move = board.getMove();
        if (move.dir == .None) continue;
        // choose move
        var new_board = board;
        new_board.chooseMove(.{ .idx = move.idx }, move.dir);
        // Get symmetrical board
        const flip_prev_board = prev_board.flip();
        const search2 = binarySearch(&visited, &flip_prev_board);
        var flipped_board = if (search2.visited) visited.items[search2.idx] //
            else flip_prev_board;
        const flip_move = move.flip();
        { // Remove Moves
            board.moves[move.idx].remove(move.dir);
            const mid_idx = Board.getRotation(posFromIdx(move.idx), move.dir, .full).?;
            const other_idx = idxFromPos(Board.getRotation(mid_idx, move.dir, .full).?);
            const other_dir = move.dir.opposite();
            board.moves[other_idx].remove(other_dir);
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
        }
        { // Remove symmetrical moves
            flipped_board.moves[flip_move.idx].remove(flip_move.dir);
            const flip_mid_idx = Board.getRotation(posFromIdx(flip_move.idx), flip_move.dir, .full).?;
            const flip_other_idx = idxFromPos(Board.getRotation(flip_mid_idx, flip_move.dir, .full).?);
            const flip_other_dir = flip_move.dir.opposite();
            flipped_board.moves[flip_other_idx].remove(flip_other_dir);
            // if flipboard was visited, modify, if flipped board wasn't append
            if (search2.visited) {
                visited.items[search2.idx] = flipped_board;
            } else {
                try visited.append(allo, flipped_board);
            }
        }
        // update stack with new board
        try stack.append(allo, new_board);
    }
    // Prune Wins
    if (wins.items.len > 0) {
        print("# of Wins: {}\n", .{wins.items.len});
        var i: usize = 0;
        var n_wins: usize = wins.items.len;
        while (i <= n_wins - 2) : (i += 1) {
            var j: usize = i + 1;
            const curr = wins.items[i];
            const flip = curr.flip();
            while (j <= n_wins - 1) : (j += 1) {
                const next = wins.items[j];
                if (curr.board.mask == next.board.mask or flip.board.mask == next.board.mask) {
                    _ = wins.swapRemove(j);
                    n_wins -= 1;
                }
            }
        }
        print("# of Wins: {}\n", .{wins.items.len});
    } else {
        print("No Solutions Found for {} rows!\n", .{N_ROWS});
    }
    // Print All Wins
    for (0..wins.items.len) |i| {
        const curr = wins.items[i];
        print("Solution {}:\n", .{i});
        var initial: Board = start;
        for (0..N_INDICES) |j| {
            const k = N_INDICES - j - 1;
            const idx = curr.chosen_idxs[k];
            const dir = curr.chosen_dirs[k];
            print("{}: {s} ", .{ idx, @tagName(dir) });
            initial.chooseMove(.{ .idx = idx }, dir);
            initial.printBoard();
        }
        print("\n", .{});
    }
}
