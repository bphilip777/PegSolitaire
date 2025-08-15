const std = @import("std");
const print = std.debug.print;
const Allocator: type = std.mem.Allocator;
const EnumSet: type = std.enums.EnumSet;

pub fn createBoard(comptime n_rows: u16) type {
    if (n_rows == 0 or n_rows > 362) return error.NRowsMustBeGT0orLT362;
    const n_indices = triangleNumber(n_rows);

    return struct {
        const Self = @This();
        allo: Allocator,
        board: std.bit_set.IntegerBitSet(n_indices),
        moves: std.ArrayList(Moves), // array of moves

        pub fn init(allo: Allocator, start: u16) !Self {
            if (start >= n_indices) return error.StartMustBeLTNIndices;

            var board: std.bit_set.IntegerBitSet(n_indices) = .initFull();
            board.unset(start);

            const moves: std.ArrayList(std.ArrayList(Moves)) = try .initCapacity(allo, n_indices);
            for (moves.items) |*move| move.init(allo);

            return Self{
                .allo = allo,
                .board = board,
                .moves = moves,
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.moves.items) |*move| move.deinit();
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
            var moves = self.moves.items;
        }

        fn hasMove(self: *Self, idx: u16, move: Move) !bool {
            if (idx >= self.moves.items.len) return error.IdxOutOfBounds;
            const moves = self.moves.items[idx];
            for (moves.items) |move| {}
        }
    };
}

fn triangleNumber(n: u16) u16 {
    return (n * (n + 1)) / 2;
}

// sqrt of possible things you want to view

const Directions = enum(u8) {
    Left,
    UpLeft,
    UpRight,
    Right,
    DownRight,
    DownLeft,
};

const Moves: type = EnumSet(Directions);
