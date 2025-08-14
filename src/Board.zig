const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const Position = @import("Position.zig");
const Move = @import("Move.zig");
const Directions = @import("Directions.zig");
const Self = @This();

allo: Allocator,

// board: [][]bool,
board: std.BitSet,
past_moves: std.ArrayList(Move),
// new_moves: std.ArrayList(Move),

// previous_past_moves: std.ArrayList(std.ArrayList(Move)),
// previous_new_moves: std.ArrayList(std.ArrayList(Move)),
// previous_boards: std.ArrayList([][]bool),
// previous_totals: std.ArrayList(usize),

pub fn init(allo: Allocator, comptime size: usize, start: Position) !Self {
    // check inputs
    if (size == 0) return error.SizeMustBeGreaterThan0;
    if (size >= 10) return error.SizeMustBeLessThan10;
    if (start.row > size or start.col > start.row) return error.StartOutOfBounds;

    // init board
    const total_size = (size + 1) * (size + 2) / 2;
    const board = std.BitSet(total_size);
    

    // board[start.row][start.col] = false;

    // Add possible moves
    // const past_moves = std.ArrayList(Move).init(allo);
    const new_moves = try newMoves(allo, board, start);

    // const previous_past_moves = std.ArrayList(std.ArrayList(Move)).init(allo);
    // const previous_new_moves = std.ArrayList(std.ArrayList(Move)).init(allo);
    // const previous_boards = std.ArrayList([][]bool).init(allo);
    // const previous_totals = std.ArrayList(usize).init(allo);

    // fill out board
    return .{
        .allo = allo,
        .board = board,
        // .past_moves = past_moves,
        .new_moves = new_moves,

        // .previous_past_moves = previous_past_moves,
        // .previous_new_moves = previous_new_moves,
        // .previous_boards = previous_boards,
        // .previous_totals = previous_totals,
    };
}

pub fn deinit(self: *Self) void {
    const len = self.board.len;
    for (0..len) |r| self.allo.free(self.board[r]);
    self.allo.free(self.board);
    self.past_moves.deinit();
    self.new_moves.deinit();

    // for (self.previous_past_moves.items) |previous_past_moves| {
    //     previous_past_moves.deinit();
    // }
    // self.previous_past_moves.deinit();
    //
    // for (self.previous_new_moves.items) |prev_moves| {
    //     prev_moves.deinit();
    // }
    // self.previous_new_moves.deinit();
    //
    // for (self.previous_boards.items) |board| {
    //     for (board) |b| {
    //         self.allo.free(b);
    //     }
    //     self.allo.free(board);
    // }
    // self.previous_boards.deinit();
    //
    // self.previous_totals.deinit();
}

pub fn showBoard(self: *const Self) void {
    const n_rows = self.board.len;
    for (0..n_rows) |r| {
        const n_cols = self.board[r].len;
        for (0..n_rows - n_cols) |_| {
            print(" ", .{});
        }
        for (0..n_cols) |c| {
            if (self.board[r][c]) print("| ", .{}) else print("- ", .{});
        }
        for (0..n_rows - n_cols) |_| {
            print(" ", .{});
        }
        print("\n", .{});
    }
}

pub fn showNewMoves(self: *const Self) void {
    for (self.new_moves.items) |new_move| {
        var next_position: Position = nextPosition(new_move);
        next_position = nextPosition(Move{
            .curr = next_position,
            .dir = new_move.dir,
        });
        print("{}x{} -> {}x{}\n", .{
            new_move.curr.row,
            new_move.curr.col,
            next_position.row,
            next_position.col,
        });
    }
}

pub fn newMoves(allo: Allocator, board: [][]bool, blank: Position) !std.ArrayList(Move) {
    if (blank.row < blank.col) return error.ImpossiblePosition;
    if (board[blank.row][blank.col]) return error.BlankMustBeEmpty;

    var moves = std.ArrayList(Move).init(allo);

    if (isLeft(blank, board)) 
        try moves.append(Move{
            .curr = blank,
            .dir = .Left,
        });
    

    if (isUpLeft(blank, board)) 
        try moves.append(Move{
            .curr = blank,
            .dir = .UpLeft,
        });
    

    if (isUpRight(blank, board)) {
        try moves.append(Move{
            .curr = blank,
            .dir = .UpRight,
        });
    }

    if (isRight(blank, board)) {
        try moves.append(Move{
            .curr = blank,
            .dir = .Right,
        });
    }

    if (isDownRight(blank, board)) {
        try moves.append(Move{
            .curr = blank,
            .dir = .DownRight,
        });
    }

    if (isDownLeft(blank, board)) {
        try moves.append(Move{
            .curr = blank,
            .dir = .DownLeft,
        });
    }

    return moves;
}

fn isLeft(blank: Position, board: [][]bool) bool {
    if (blank.row < 2) return false;
    if (!(blank.col >= 2)) return false;
    if (!(board[blank.row][blank.col - 1])) return false;
    if (!(board[blank.row][blank.col - 2])) return false;
    return true;
}

fn isUpLeft(blank: Position, board: [][]bool) bool {
    if (!(blank.row >= 2)) return false;
    if (!(blank.col >= 2)) return false;
    if (!(board[blank.row - 1][blank.col - 1])) return false;
    if (!(board[blank.row - 2][blank.col - 2])) return false;
    return true;
}

fn isUpRight(blank: Position, board: [][]bool) bool {
    if (!(blank.row >= 2)) return false;
    if (!(blank.col < board[blank.row - 2].len)) return false;
    if (!(board[blank.row - 1][blank.col])) return false;
    if (!(board[blank.row - 2][blank.col])) return false;
    return true;
}

fn isRight(blank: Position, board: [][]bool) bool {
    if (blank.row < 2) return false;
    if (!(blank.col < board[blank.row].len - 2)) return false;
    if (!(board[blank.row][blank.col + 1])) return false;
    if (!(board[blank.row][blank.col + 2])) return false;
    return true;
}

fn isDownRight(blank: Position, board: [][]bool) bool {
    if (!(blank.row < board.len - 2)) return false;
    if (!board[blank.row + 1][blank.col + 1]) return false;
    if (!board[blank.row + 2][blank.col + 2]) return false;
    return true;
}

fn isDownLeft(blank: Position, board: [][]bool) bool {
    if (!(blank.row < board.len - 2)) return false;
    if (!(board[blank.row + 1][blank.col])) return false;
    if (!(board[blank.row + 2][blank.col])) return false;
    return true;
}

pub fn isLost(self: *const Self) bool {
    return (self.total > 1 and self.moves.items.len == 0);
}

pub fn isWon(self: *const Self) bool {
    return self.total == 1;
}

pub fn chooseMove(self: *Self) !void {
    // 1. pop current move
    const move = self.moves.pop().?;

    // 2. store: board, moves, total
    // try self.past_moves.append(move);
    // try self.previous_totals.append(self.total);
    // try self.previous_boards.append(self.board);
    // try self.previous_moves.append(self.moves);

    // 3. update board
    self.board[move.curr.row][move.curr.col] = true;
    const np1 = nextPosition(move);
    self.board[np1.row][np1.col] = false;
    const np2 = nextPosition(Move{
        .curr = np1,
        .dir = move.dir,
    });
    self.board[np2.row][np2.col] = false;

    // 4. loop through all empties to create new list
    // inefficient + works
    self.moves.clearAndFree();
    for (0..self.board.len) |r| {
        for (0..self.board[r].len) |c| {
            if (!self.board[r][c]) {
                const new_moves = try newMoves(self.allo, self.board, Position{
                    .row = r,
                    .col = c,
                });
                defer new_moves.deinit();
                try self.moves.appendSlice(new_moves.items);
            }
        }
    }

    // update total
    self.total -= 1;
}

fn nextPosition(move: Move) Position {
    return switch (move.dir) {
        .Left => .{
            .row = move.curr.row,
            .col = move.curr.col - 1,
        },
        .UpLeft => .{
            .row = move.curr.row - 1,
            .col = move.curr.col - 1,
        },
        .UpRight => .{
            .row = move.curr.row - 1,
            .col = move.curr.col,
        },
        .Right => .{
            .row = move.curr.row,
            .col = move.curr.col + 1,
        },
        .DownRight => .{
            .row = move.curr.row + 1,
            .col = move.curr.col + 1,
        },
        .DownLeft => Position{
            .row = move.curr.row + 1,
            .col = move.curr.col,
        },
    };
}

// pub fn undoChosenMove(self: *Self) !void {
//     // reset total
//     if (self.moves.getLast())
//     self.total = self.previous_totals.items[self.previous_totals.items.len - 1];
//     if (self.moves.items > 0) {
//         self.moves.items
//     }
//     self.moves = self.previous_moves.items[self.previous_moves.items.len - 1];
// }

pub fn showAllMoves(self: *const Self) void {
    for (self.past_moves.items) |past_move| {
        print("{}x{}\n", .{past_move.curr.row, past_move.curr.col});
    }
}
