const std = @import("std");
const print = std.debug.print;
const Position = @import("Position.zig");
const Move = @import("Move.zig");
const Directions = @import("Directions.zig").Directions;

const Allocator = std.mem.Allocator;
const IntegerBitSet = std.bit_set.IntegerBitSet;

pub fn createBoard(comptime size: u8) !type {
    if (size == 0 or size > 10) return  error.IncorrectSize;
    const total_size =  triangleNumber(size);

    return struct{
        const Self = @This();

        allo: Allocator,
        board: std.bit_set.IntegerBitSet(total_size),
        moves: std.ArrayList(Move),

        pub fn init(allo: Allocator, start: Position) !Self {
            var board = std.bit_set.IntegerBitSet(total_size).initFull();
            const start_idx = sub2idx(start);
            if (start_idx > total_size) return error.ImpossibleStart;
            board.unset(start_idx);

            var self: Self = undefined;
            self.allo = allo;
            self.board = board;
            self.moves = try self.newMoves(start);
            return self;
        }

        pub fn showBoard(self: *const Self) void {
            var i: usize = 0;
            for (0..size) |r| {
                const diff = (size - r);
                for (0..diff) |_| print(" ", .{});
                for (0..r) |_| {
                    if (self.board.isSet(i)) print("| ", .{}) else print("- ", .{});
                    i += 1;
                }
                for (0..diff) |_| print(" ", .{});
                print("\n", .{});
            }
        }

        pub fn deinit(self: *const Self) void {
            self.moves.deinit();
        }

        pub fn newMoves(self: *Self, blank: Position) !std.ArrayList(Move) {
            if (blank.row > size or blank.col > size) return error.ImpossiblePosition;
            if (sub2idx(blank) > total_size) return error.ImposiblePosition;

            var new_moves = std.ArrayList(Move).init(self.allo);
            
            if (self.isLeft(blank)) try new_moves.append(Move{ .curr = blank, .dir = .Left });
            if (self.isUpLeft(blank)) try new_moves.append(Move{ .curr = blank, .dir = .UpLeft });
            if (self.isUpRight(blank)) try new_moves.append(Move{ .curr = blank, .dir = .UpRight });
            if (self.isRight(blank)) try new_moves.append(Move{ .curr = blank, .dir = .Right });
            if (self.isDownRight(blank)) try new_moves.append(Move{ .curr = blank, .dir = .DownRight });
            if (self.isDownLeft(blank)) try new_moves.append(Move{ .curr = blank, .dir = .DownLeft });

            return new_moves;
        }

        fn isLeft(self: *const Self, blank: Position) bool {
             if (blank.col < 2) return false;
             const idx = sub2idx(blank);
             if (!self.board.isSet(idx - 1) or !self.board.isSet(idx - 2)) return false;
             return true;
        }

        fn isUpLeft(self: *const Self, blank: Position) bool {
            if (blank.row < 2 or blank.col < 2) return false;
            const idx1 = sub2idx(Position{ .row = blank.row - 1, .col = blank.col - 1});
            const idx2 = sub2idx(Position{.row = blank.row - 2, .col = blank.col - 2});
            if (!self.board.isSet(idx1) or !self.board.isSet(idx2)) return false;
            return true;
        }

        fn isUpRight(self: *const Self, blank: Position) bool {
            if (blank.row < 2 or blank.col + 2 > size) return false;
            const idx1 = sub2idx(Position{.row = blank.row - 1, .col = blank.col + 1});
            const idx2 = sub2idx(Position{.row = blank.row - 2, .col = blank.col + 2});
            if (!self.board.isSet(idx1) or !self.board.isSet(idx2)) return false;
            return true;
        }

        fn isRight(self: *const Self, blank: Position) bool {
            if (blank.col + 2 > size) return false;
            const idx = sub2idx(blank);
            if (!self.board.isSet(idx + 1) or !self.board.isSet(idx + 2)) return false;
            return true;
        }

        fn isDownRight(self: *const Self, blank: Position) bool {
            if (blank.row + 2 > size or blank.col + 2 > size) return false;
            const idx1 = sub2idx(Position{.row = blank.row + 1, .col = blank.col + 1});
            const idx2 = sub2idx(Position{.row = blank.row + 2, .col = blank.col + 2});
            if (!self.board.isSet(idx1) or !self.board.isSet(idx2)) return false;
            return true;
        }

        fn isDownLeft(self: *const Self, blank: Position) bool {
            if (blank.row < 2 or blank.col + 2 > size) return false;
            const idx1 = sub2idx(Position{.row = blank.row + 1, .col = blank.col - 1});
            const idx2 = sub2idx(Position{.row = blank.row + 2, .col = blank.col - 2});
            if (!self.board.isSet(idx1) or !self.board.isSet(idx2)) return false;
            return true;
        }

        fn sub2idx(sub: Position) u8 {
            return (sub.row * sub.row - sub.row) / 2 + sub.col;
        }

        fn nextSub2Idx(sub: Position, dir: Direction) u8 {
            return sub2idx()
        }

        pub fn showMoves(self: *const Self) void {
            for (self.moves.items) |move| {
                const curr = move.curr;
                const next = switch (move.dir) {
                    .Left => Position{ .row = move.curr.row - },
                    .UpLeft => {},
                    .UpRight => {},
                    .Right => {},
                    .DownRight => {},
                    .DownLeft => {},
                }
                print("{}x{} - {s}\n", .{move.curr.row, move.curr.col, @tagName(move.dir)});
            }
        }

        pub fn isWon(self: *const Self) bool {
            return self.board.count() == 0;
        }

        pub fn isLost(self: *const Self) bool {
            return self.moves.items.len == 0 and self.board.count() > 0;
        }
    };
}

inline fn triangleNumber(size: usize) usize {
    return (size * (size + 1)) / 2;
}
