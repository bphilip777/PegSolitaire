const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;
const Allocator: type = std.mem.Allocator;

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
            var i: u16 = 0;
            var row_length: u16 = 1;
            while (i < n_indices) {
                const ends: u16 = (n_indices - row_length) / 2 + @as(u16, @intFromBool((row_length & 1) > 0));
                for (0..ends) |_| print("  ", .{});
                for (0..row_length) |j| {
                    const k: u16 = @as(u16, @truncate(j)) + i;
                    if (self.board.isSet(k)) print("| ", .{}) else print("- ", .{});
                }
                for (0..ends) |_| print("  ", .{});
                print("\n", .{});
                i += row_length;
                row_length += 1;
            }
        }

        pub fn updateMoves(self: *Self, idx: u16) !void {
            // check l, ul, ur, r, dr, dl
            self.moves.items[idx].insert(.left);
        }

        fn hasMove(self: *Self, idx: u16, move: Move) !bool {
            _ = self;
            _ = idx;
            _ = move;
            // if (idx >= self.moves.items.len) return error.IdxOutOfBounds;
            // var possible_moves: *Move = &self.moves.items[idx];
            // switch (move) {
            //     .Left => {
            //         if ()
            //     },
            //     .UpLeft => {},
            //     .UpRight => {},
            //     .Right => {},
            //     .DownRight => {},
            //     .DownLeft => {},
            // }
        }
    };
}

const Position = struct {
    row: u16,
    col: u16,
};

fn triNum(n: u16) u16 {
    return (n * (n + 1)) / 2;
}

fn invTriNum(n: u16) u16 {
    return @intFromFloat((@sqrt(8 * @as(f16, @floatFromInt(n)) + 1) - 1) / 2);
}

pub fn idx2pos(idx: u16) Position {
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
        const pos = idx2pos(@truncate(i));
        try expect(pos.row == epos.row and pos.col == epos.col);
    }
}

pub fn pos2idx(pos: Position) u16 {
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
        const idx = pos2idx(pos);
        try expect(idx == @as(u16, @truncate(expected_idx)));
    }
}

const Move = enum(u8) {
    Left,
    UpLeft,
    UpRight,
    Right,
    DownRight,
    DownLeft,
};

const Moves: type = std.enums.EnumSet(Move);

test "Print Board" {
    // testing proper printing of board
}
