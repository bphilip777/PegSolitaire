const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;
const eql = std.mem.eql;

const T: type = u16;
const MAX_INPUT_SIZE = if (eql(u8, @typeName(T), "u16")) 362 // u16
    else if (eql(u8, @typeName(T), "i16")) 182 // i16
    else unreachable;
const Position: type = struct {
    row: T,
    col: T,
};
const Allocator: type = std.mem.Allocator;
pub const Move: type = enum(u8) {
    Left,
    UpLeft,
    UpRight,
    Right,
    DownRight,
    DownLeft,
};
pub const Moves: type = std.enums.EnumSet(Move);

pub fn createBoard(comptime n_rows: T) type {
    // 362 = u16, 181 = i16
    if (n_rows <= 0 or n_rows > MAX_INPUT_SIZE) {
        print("# Of Rows: {} is Invalid. 0 < # of Rows < {}", .{ n_rows, MAX_INPUT_SIZE });
        return error.NRowsInvalid;
    }
    const n_indices = triNum(n_rows);

    return struct {
        const Self = @This();
        allo: Allocator,
        board: std.bit_set.IntegerBitSet(n_indices),
        moves: std.ArrayList(Moves),

        // all_boards: std.ArrayList(u16), // prob needs to be a hash fn - store board as just u16
        // all_moves: std.ArrayList(std.ArrayList(Moves)),

        pub fn init(allo: Allocator, start: T) !Self {
            if (start >= n_indices or start < 0) return error.StartMustBeGT0orLTTriNumOfNumOfRows;

            var board: std.bit_set.IntegerBitSet(n_indices) = .initFull();
            board.unset(@as(usize, @intCast(start)));

            var moves: std.ArrayList(Moves) = try .initCapacity(allo, n_indices);
            for (0..n_indices) |_| moves.appendAssumeCapacity(Moves.initEmpty());

            // const all_boards: std.ArrayList(u16) = .init(allo);
            // const all_moves: std.ArrayList(std.ArrayList(Move)) = .init(allo);

            var self: Self = .{
                .allo = allo,
                .board = board,
                .moves = moves,
            };
            self.updateMoves(start);

            return self;
        }

        pub fn deinit(self: *Self) void {
            self.moves.deinit();
        }

        pub fn printBoard(self: *const Self) void {
            const len = n_rows * 2 + 1;
            var buffer: [len]u8 = [_]u8{' '} ** len;
            var i: u16 = 0;

            for (0..n_rows + 1) |row| {
                const start = n_rows - row;
                for (0..row) |col| {
                    const idx = start + col * 2;
                    buffer[@intCast(idx)] = if (self.board.isSet(i)) '|' else '-';
                    buffer[idx + 1] = ' ';
                    i += 1;
                }
                print("{s}\n", .{&buffer});
            }
            print("\n", .{});
        }

        pub fn updateMoves(self: *Self, idx: T) void {
            if (idx > self.board.capacity() or idx < 0) return;
            var move: Moves = self.moves.items[@intCast(idx)];
            // sub all moves
            if (self.board.isSet(idx)) {
                move = move.xorWith(move);
                self.moves.items[@intCast(idx)] = move;
                return;
            }
            // add moves
            const pos: Position = posFromIdx(idx);
            inline for (comptime std.meta.fieldNames(Move)) |fieldname| {
                if (self.hasMoveFrom(pos, @field(Move, fieldname)))
                    move.insert(@field(Move, fieldname));
            }
            // set move
            self.moves.items[@intCast(idx)] = move;
        }

        fn updateAllMovesBruteForce(self: *Self) void {
            for (0..self.board.capacity()) |i| self.updateMoves(@truncate(i));
        }

        fn updateAllMovesOptimized(self: *Self, idx: T, move: Move) void {
            _ = self;
            _ = idx;
            _ = move;
        }

        fn hasMoveFrom(self: *const Self, pos: Position, move: Move) bool {
            return switch (move) {
                .Left => self.hasFromLeft(pos),
                .UpLeft => self.hasFromUpLeft(pos),
                .UpRight => self.hasFromUpRight(pos),
                .Right => self.hasFromRight(pos),
                .DownRight => self.hasFromDownRight(pos),
                .DownLeft => self.hasFromDownLeft(pos),
            };
        }

        inline fn hasFromLeft(self: *const Self, pos: Position) bool {
            if (pos.col < 2) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row, .col = pos.col - 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row, .col = pos.col - 2 });
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        inline fn hasFromUpLeft(self: *const Self, pos: Position) bool {
            if (pos.row < 2 or pos.col < 2) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row - 1, .col = pos.col - 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row - 2, .col = pos.col - 2 });
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        inline fn hasFromUpRight(self: *const Self, pos: Position) bool {
            if (pos.row < 2) return false;
            if (pos.col + 2 >= pos.row) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row - 1, .col = pos.col });
            const idx2 = idxFromPos(Position{ .row = pos.row - 2, .col = pos.col });
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        inline fn hasFromRight(self: *const Self, pos: Position) bool {
            if (pos.col + 2 >= pos.row) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row, .col = pos.col + 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row, .col = pos.col + 2 });
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        inline fn hasFromDownRight(self: *const Self, pos: Position) bool {
            if (pos.row + 2 >= n_rows or pos.col + 2 >= n_rows) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row + 1, .col = pos.col + 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row + 2, .col = pos.col + 2 });
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        inline fn hasFromDownLeft(self: *const Self, pos: Position) bool {
            if (pos.row + 2 >= n_rows) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row + 1, .col = pos.col });
            const idx2 = idxFromPos(Position{ .row = pos.row + 2, .col = pos.col });
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        pub fn printMoves(self: *const Self) void {
            for (self.moves.items, 0..) |move, i| {
                if (move.count() == 0) continue;
                const pos = posFromIdx(@intCast(@as(u16, @truncate(i))));
                print("({}, {}): ", .{ pos.row, pos.col });
                var it = move.iterator();
                while (it.next()) |item| {
                    print("{s} ", .{@tagName(item)});
                }
                print("\n", .{});
            }
        }

        // pub fn listOfMoves(self: *Self) !std.ArrayList(Moves) {
        //     var moves: std.ArrayList(Moves) = .init(self.allo);
        //     return moves;
        // }

        pub fn chooseMove(self: *Self, idx: T, move: Move) void {
            if (idx > self.board.count() or idx < 0) return;
            self.board.set(@intCast(idx));
            switch (move) {
                .Left => self.moveLeft(idx),
                .UpLeft => self.moveUpLeft(idx),
                .UpRight => self.moveUpRight(idx),
                .Right => self.moveRight(idx),
                .DownRight => self.moveDownRight(idx),
                .DownLeft => self.moveDownLeft(idx),
            }
            // update possible moves
            if (n_rows <= 7) {
                print("Brute Force\n", .{});
                self.updateAllMovesBruteForce();
            } else {
                print("Optimized\n", .{});
                self.updateAllMovesOptimized(idx, move);
            }

            // try self.all_boards.append(self.board);
        }

        inline fn moveLeft(self: *Self, idx: T) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row, .col = pos.col - 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row, .col = pos.col - 2 });
            self.board.unset(@intCast(idx1));
            self.board.unset(@intCast(idx2));
        }

        inline fn moveUpLeft(self: *Self, idx: T) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row - 1, .col = pos.col - 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row - 2, .col = pos.col - 2 });
            self.board.unset(@intCast(idx1));
            self.board.unset(@intCast(idx2));
        }

        inline fn moveUpRight(self: *Self, idx: T) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row - 1, .col = pos.col });
            const idx2 = idxFromPos(Position{ .row = pos.row - 2, .col = pos.col });
            self.board.unset(@intCast(idx1));
            self.board.unset(@intCast(idx2));
        }

        inline fn moveRight(self: *Self, idx: T) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row, .col = pos.col + 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row, .col = pos.col + 2 });
            self.board.unset(@intCast(idx1));
            self.board.unset(@intCast(idx2));
        }

        inline fn moveDownRight(self: *Self, idx: T) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row + 1, .col = pos.col + 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row + 2, .col = pos.col + 2 });
            self.board.unset(@intCast(idx1));
            self.board.unset(@intCast(idx2));
        }

        inline fn moveDownLeft(self: *Self, idx: T) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row + 1, .col = pos.col });
            const idx2 = idxFromPos(Position{ .row = pos.row + 2, .col = pos.col });
            self.board.unset(@intCast(idx1));
            self.board.unset(@intCast(idx2));
        }

        pub fn isWon(self: *const Self) bool {
            return self.board.count() == 1;
        }

        pub fn isLost(self: *const Self) bool {
            const no_moves: bool = blk: for (self.moves.items) |move| {
                if (move.count() > 0) break :blk false;
            } else break :blk false;
            return self.board.count() > 1 and no_moves;
        }

        pub fn isGameOver(self: *const Self) bool {
            return self.isWon() or self.isLost();
        }
    };
}

fn triNum(n: T) T {
    return (n * (n + 1)) / 2;
}

fn invTriNum(n: T) T {
    return @intFromFloat((@sqrt(8 * @as(f16, @floatFromInt(n)) + 1) - 1) / 2);
}

pub fn posFromIdx(idx: T) Position {
    const row = invTriNum(idx);
    const tri_num = triNum(row);
    const col = idx - tri_num;
    return Position{ .row = row, .col = col };
}

test "Idx 2 Pos" {
    const expected_positions = [_]Position{
        .{ .row = 0, .col = 0 },
        .{ .row = 1, .col = 0 },
        .{ .row = 1, .col = 1 },
        .{ .row = 2, .col = 0 },
        .{ .row = 2, .col = 1 },
        .{ .row = 2, .col = 2 },
        .{ .row = 3, .col = 0 },
        .{ .row = 3, .col = 1 },
        .{ .row = 3, .col = 2 },
        .{ .row = 3, .col = 3 },
        .{ .row = 4, .col = 0 },
        .{ .row = 4, .col = 1 },
        .{ .row = 4, .col = 2 },
        .{ .row = 4, .col = 3 },
        .{ .row = 4, .col = 4 },
    };
    for (0..expected_positions.len, expected_positions) |i, epos| {
        const pos = posFromIdx(@truncate(i));
        try expect(pos.row == epos.row and pos.col == epos.col);
    }
}

pub fn idxFromPos(pos: Position) T {
    return triNum(pos.row) + pos.col;
}

test "Pos 2 Idx" {
    const positions = [_]Position{
        .{ .row = 0, .col = 0 },
        .{ .row = 1, .col = 0 },
        .{ .row = 1, .col = 1 },
        .{ .row = 2, .col = 0 },
        .{ .row = 2, .col = 1 },
        .{ .row = 2, .col = 2 },
        .{ .row = 3, .col = 0 },
        .{ .row = 3, .col = 1 },
        .{ .row = 3, .col = 2 },
        .{ .row = 3, .col = 3 },
        .{ .row = 4, .col = 0 },
        .{ .row = 4, .col = 1 },
        .{ .row = 4, .col = 2 },
        .{ .row = 4, .col = 3 },
        .{ .row = 4, .col = 4 },
    };
    for (0..positions.len, positions) |expected_idx, pos| {
        const idx = idxFromPos(pos);
        try expect(idx == @as(u16, @truncate(expected_idx)));
    }
}

// Swapped Position from u16 to i16

// Total # Of Neighbors:
//    x x x x x
//   | - - - - |      o = 3 originals
//  x - o o o - x     - = 10 first neighbors
// | | - - - - | |    x = 12 2nd neighbors
//| | x x x x x |     Total Updates = 25

// implement above
// simplify the code
// should get all moves available
// should update code in a simpler manner
