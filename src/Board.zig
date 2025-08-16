const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

const Position: type = struct {
    row: u16,
    col: u16,
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

pub fn createBoard(comptime n_rows: u16) type {
    if (n_rows == 0 or n_rows > 362) return error.NRowsMustBeGT0orLT362;
    const n_indices = triNum(n_rows);

    return struct {
        const Self = @This();
        allo: Allocator,
        board: std.bit_set.IntegerBitSet(n_indices),
        moves: std.ArrayList(Moves),

        // all_boards: std.ArrayList(u16), // prob needs to be a hash fn - store board as just u16
        // all_moves: std.ArrayList(std.ArrayList(Moves)),

        pub fn init(allo: Allocator, start: u16) !Self {
            if (start >= n_indices) return error.StartMustBeLTNIndices;

            var board: std.bit_set.IntegerBitSet(n_indices) = .initFull();
            board.unset(start);

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
                    buffer[idx] = if (self.board.isSet(i)) '|' else '-';
                    buffer[idx + 1] = ' ';
                    i += 1;
                }
                print("{s}\n", .{&buffer});
            }
            print("\n", .{});
        }

        pub fn updateMoves(self: *Self, idx: u16) void {
            if (idx > self.board.capacity()) return; // remove this line once fn is priv
            var move: Moves = self.moves.items[idx];
            // if set, remove all moves
            if (self.board.isSet(idx)) {
                move = move.xorWith(move);
                self.moves.items[idx] = move;
                return;
            }
            // determine available moves
            const pos: Position = posFromIdx(idx);
            inline for (comptime std.meta.fieldNames(Move)) |fieldname| {
                if (self.hasMoveFrom(pos, @field(Move, fieldname)))
                    move.insert(@field(Move, fieldname));
            }
            self.moves.items[idx] = move;
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
            const idx1 = idxFromPos(pos) - 1;
            const idx2 = idx1 - 1;
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
            if (pos.col + 2 > pos.row) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row - 1, .col = pos.col });
            const idx2 = idxFromPos(Position{ .row = pos.row - 2, .col = pos.col });
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        inline fn hasFromRight(self: *const Self, pos: Position) bool {
            if (pos.col + 2 > pos.row) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row, .col = pos.col + 1 });
            const idx2 = idx1 + 1;
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        inline fn hasFromDownRight(self: *const Self, pos: Position) bool {
            if (pos.row + 2 > n_rows or pos.col + 2 > n_rows) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row + 1, .col = pos.col + 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row + 2, .col = pos.col + 2 });
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        inline fn hasFromDownLeft(self: *const Self, pos: Position) bool {
            if (pos.row + 2 > n_rows) return false;
            const idx1 = idxFromPos(Position{ .row = pos.row + 1, .col = pos.col });
            const idx2 = idxFromPos(Position{ .row = pos.row + 2, .col = pos.col });
            return self.board.isSet(idx1) and self.board.isSet(idx2);
        }

        pub fn printMoves(self: *const Self) void {
            for (self.moves.items, 0..) |move, i| {
                if (move.count() == 0) continue;
                print("{}: ", .{i});
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

        pub fn chooseMove(self: *Self, idx: u16, move: Move) void {
            if (idx > self.board.count()) return;
            // remove all moves at current idx - always gets filled in
            self.board.set(idx);
            self.updateMoves(idx);
            // add possible new moves
            switch (move) {
                .Left => self.moveLeft(idx),
                .UpLeft => self.moveUpLeft(idx),
                .UpRight => self.moveUpRight(idx),
                .Right => self.moveRight(idx),
                .DownRight => self.moveDownRight(idx),
                .DownLeft => self.moveDownLeft(idx),
            }
            // try self.all_boards.append(self.board);
        }

        inline fn moveLeft(self: *Self, idx: u16) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row, .col = pos.col - 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row, .col = pos.col - 2 });
            self.board.unset(idx1);
            self.board.unset(idx2);
            self.updateMoves(idx1);
            self.updateMoves(idx2);
        }

        inline fn moveUpLeft(self: *Self, idx: u16) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row - 1, .col = pos.col - 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row - 2, .col = pos.col - 2 });
            self.board.unset(idx1);
            self.board.unset(idx2);
            self.updateMoves(idx1);
            self.updateMoves(idx2);
        }

        inline fn moveUpRight(self: *Self, idx: u16) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row - 1, .col = pos.col });
            const idx2 = idxFromPos(Position{ .row = pos.row - 2, .col = pos.col });
            self.board.unset(idx1);
            self.board.unset(idx2);
            self.updateMoves(idx1);
            self.updateMoves(idx2);
        }

        inline fn moveRight(self: *Self, idx: u16) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row, .col = pos.col + 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row, .col = pos.col + 2 });
            self.board.unset(idx1);
            self.board.unset(idx2);
            self.updateMoves(idx1);
            self.updateMoves(idx2);
        }

        inline fn moveDownRight(self: *Self, idx: u16) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row + 1, .col = pos.col + 1 });
            const idx2 = idxFromPos(Position{ .row = pos.row + 2, .col = pos.col + 2 });
            self.board.unset(idx1);
            self.board.unset(idx2);
            self.updateMoves(idx1);
            self.updateMoves(idx2);
        }

        inline fn moveDownLeft(self: *Self, idx: u16) void {
            const pos = posFromIdx(idx);
            const idx1 = idxFromPos(Position{ .row = pos.row + 1, .col = pos.col });
            const idx2 = idxFromPos(Position{ .row = pos.row + 2, .col = pos.col });
            self.board.unset(idx1);
            self.board.unset(idx2);
            self.updateMoves(idx1);
            self.updateMoves(idx2);
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

fn triNum(n: u16) u16 {
    return (n * (n + 1)) / 2;
}

fn invTriNum(n: u16) u16 {
    return @intFromFloat((@sqrt(8 * @as(f16, @floatFromInt(n)) + 1) - 1) / 2);
}

pub fn posFromIdx(idx: u16) Position {
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

pub fn idxFromPos(pos: Position) u16 {
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

test "Has Move" {}

test "Make Move" {}
