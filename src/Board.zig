const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

const Position: type = struct {
    row: u16,
    col: u16,
};
const Allocator: type = std.mem.Allocator;
const Move: type = enum(u8) {
    Left,
    UpLeft,
    UpRight,
    Right,
    DownRight,
    DownLeft,
};
const Moves: type = std.enums.EnumSet(Move);

pub fn createBoard(comptime n_rows: u16) type {
    if (n_rows == 0 or n_rows > 362) return error.NRowsMustBeGT0orLT362;
    const n_indices = triNum(n_rows);

    return struct {
        const Self = @This();
        allo: Allocator,
        board: std.bit_set.IntegerBitSet(n_indices),
        moves: std.ArrayList(Moves), // array of moves

        pub fn init(allo: Allocator, start: u16) !Self {
            if (start >= n_indices) return error.StartMustBeLTNIndices;

            var board: std.bit_set.IntegerBitSet(n_indices) = .initFull();
            board.unset(start);

            var moves: std.ArrayList(Moves) = try .initCapacity(allo, n_indices);
            var i: u16 = 0;
            while (i < moves.items.len) : (i +%= 1) {
                moves.items[i] = Moves.initEmpty();
            }

            return Self{
                .allo = allo,
                .board = board,
                .moves = moves,
            };
        }

        pub fn deinit(self: *Self) void {
            self.moves.deinit();
        }

        pub fn printBoard(self: *const Self) void {
            const len = n_rows * 2 + 1;
            var buffer: [len]u8 = [_]u8{' '} ** len;

            var i: u16 = 0;
            for (0..n_rows) |row| {
                const start = n_rows - row;
                for (0..row) |col| {
                    buffer[start + col * 2] = if (self.board.isSet(i)) '|' else '-';
                    buffer[start + col * 2 - 1] = ' ';
                    i += 1;
                }
                print("{s}\n", .{&buffer});
            }
        }

        pub fn updateMoves(self: *Self, idx: u16) !void {
            inline for (comptime std.meta.fieldNames(Move)) |fieldname| {
                print("{s}\n", .{fieldname});
                if (self.hasMoveFrom(idx, @field(Move, fieldname)))
                    self.moves.items[idx].insert(@field(Move, fieldname));
            }
            print("{any}", .{self.moves.items[idx]});
        }

        fn hasMoveFrom(self: *const Self, idx: u16, move: Move) bool {
            if (idx > self.board.capacity()) return false;
            if (self.board.isSet(idx)) return false;
            const pos: Position = posFromIdx(idx);
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
