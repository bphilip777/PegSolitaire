const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

// TODO:
// Enable positive and negative moves
// - currently only negative moves

const T: type = u16;

pub fn triNum(n: T) T {
    return (n * (n + 1)) / 2;
}

test "Tri Num" {
    const expected_tri_nums = [_]T{ 0, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66 };
    for (expected_tri_nums, 0..) |expected_tri_num, i| {
        try std.testing.expectEqual(triNum(@truncate(i)), expected_tri_num);
    }
}

fn invTriNum(n: T) T {
    // does f16 or f32 matter?
    return @intFromFloat((@sqrt(8 * @as(f16, @floatFromInt(n)) + 1) - 1) / 2);
}

test "Inv Tri Num" {
    //     0
    //    1 2
    //   3 4 5
    //  6 7 8 9
    // 0 1 2 3 4
    const inputs = [_]T{ 0, 1, 3, 5, 6, 10 };
    const answers = [_]T{ 0, 1, 2, 2, 3, 4 };
    for (inputs, answers) |input, answer| {
        try std.testing.expectEqual(invTriNum(input), answer);
    }
}

fn invTriNum2(n: T) T {
    var sum: T = 0;
    var i: T = 1;
    while (true) {
        if (sum >= n) break;
        i += 1;
        sum += i;
    }
    return i - 1;
}

test "Inv Tri Num 2 - Brute Force" {
    const inputs = [_]T{ 0, 1, 3, 5, 6, 10 };
    const rows = [_]T{ 0, 1, 2, 2, 3, 4 };
    for (inputs, rows) |input, row| {
        const itn = invTriNum2(input);
        try std.testing.expectEqual(itn, row);
    }

    for (inputs) |input| {
        const itn1 = invTriNum(input);
        const itn2 = invTriNum2(input);
        try std.testing.expectEqual(itn1, itn2);
    }
}

// find max value of u16 -> get triangle row number -> take floor = max number of rows
const MAX_INPUT_SIZE: u16 = @intFromFloat(@floor((@sqrt(8 * @as(f32, @floatFromInt(std.math.maxInt(u16))) + 1) - 1) / 2));

const Position = struct {
    row: T,
    col: T,
};

pub fn posFromIdx(idx: T) Position {
    const row = invTriNum(idx);
    const tri_num = triNum(row);
    const col = idx - tri_num;
    return Position{ .row = row, .col = col };
}

test "Position From Idx" {
    var pos: Position = Position{
        .row = 0,
        .col = 0,
    };
    for (0..15) |i| {
        const new_pos = posFromIdx(@truncate(i));
        try std.testing.expectEqual(pos.row, new_pos.row);
        try std.testing.expectEqual(pos.col, new_pos.col);
        pos.col += 1;
        if (pos.col > pos.row) {
            pos.row += 1;
            pos.col = 0;
        }
    }
}

pub fn idxFromPos(pos: Position) T {
    return triNum(pos.row) + pos.col;
}

test "Idx From Position" {
    var pos: Position = Position{
        .row = 0,
        .col = 0,
    };
    for (0..15) |i| {
        const idx = idxFromPos(pos);
        try std.testing.expectEqual(idx, @as(T, @truncate(i)));
        pos.col += 1;
        if (pos.col > pos.row) {
            pos.row += 1;
            pos.col = 0;
        }
    }
}

const Rotation: type = enum {
    sixty,
    one_twenty,
    one_eighty,
    two_forty,
    three_hundo,
    full,

    pub fn opposite(input: Rotation) Rotation {
        return switch (input) {
            .sixty => .two_forty,
            .one_twenty => .three_hundo,
            .one_eighty => .full,
            .two_forty => .sixty,
            .three_hundo => .one_twenty,
            .full => .one_eighty,
        };
    }
};

const Direction: type = enum {
    Left,
    UpLeft,
    UpRight,
    Right,
    DownRight,
    DownLeft,

    pub fn opposite(input: Direction) Direction {
        return switch (input) {
            .Left => .Right,
            .UpLeft => .DownRight,
            .UpRight => .DownLeft,
            .Right => .Left,
            .DownRight => .UpLeft,
            .DownLeft => .UpRight,
        };
    }
};

pub const Directions: type = std.enums.EnumSet(Direction);

const GameErrors = error{
    InvalidMove,
    InvalidPosition,
};

pub fn createBoard(comptime n_rows: T) !type {
    if (n_rows <= 0 or n_rows > MAX_INPUT_SIZE) return error.NRowsTooSmallOrTooLarge;
    const n_indices = triNum(n_rows);

    return struct {
        const Self = @This();
        allo: Allocator,
        board: std.bit_set.IntegerBitSet(n_indices),
        pos_moves: [n_indices]Directions,
        neg_moves: [n_indices]Directions,

        pub fn init(allo: Allocator, start: T) !Self {
            if (start >= n_indices) return error.STartMustBeGT0OrLTNumIndices;

            var board: std.bit_set.IntegerBitSet(n_indices) = .initFull();
            board.unset(@as(usize, @intCast(start)));

            // Directions
            var pos_moves: [n_indices]Directions = undefined;
            var neg_moves: [n_indices]Directions = undefined;
            for (0..n_indices) |i| {
                pos_moves[i] = .initEmpty();
                neg_moves[i] = .initEmpty();
            }
            var self = Self{
                .allo = allo,
                .board = board,
                .pos_moves = pos_moves,
                .neg_moves = neg_moves,
            };

            // Initial moves
            self.updateNegMove(start);

            return self;
        }

        pub fn deinit(self: *Self) void {
            _ = self;
        }

        pub fn printBoard(self: *const Self) void {
            const len = n_rows * 2 + 1;
            var buffer: [len]u8 = [_]u8{' '} ** len;
            var i: T = 0;

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

        pub fn chooseMove(self: *Self, idx: T, dir: Direction) !void {
            // TODO: double check self.directions on whether the move can be taken
            if (self.board.isSet(idx)) return GameErrors.InvalidMove;
            var positions: [25]?Position = undefined;
            // only ring 0 gauranteed!
            // Priority: Origin -> Origin Neighbors -> Ring +1 near origin -> Ring +1 near neighbors
            // ring 0 (o): Clockwise from 0 (origin)
            // o o o -> 0 1 2
            // original position
            positions[0] = posFromIdx(idx);
            // get initial line
            positions[1] = getRotation(positions[0], dir, .full);
            positions[2] = getRotation(positions[1], dir, .full);
            for (positions[1..3]) |new_position| {
                const new_pos = new_position orelse
                    return GameErrors.InvalidPosition;
                if (!self.board.isSet(idxFromPos(new_pos)))
                    return GameErrors.InvalidMove;
            }
            // ring 1 (x): Clockwise from 3
            //   x x x x      4 5 6 7
            //  x o o o x -> 3 o o o 8
            //   x x x x      2 1 0 9
            // opposite direction
            positions[3] = getRotation(positions[0], dir, .one_eighty);
            // +60 rot
            positions[4] = getRotation(positions[0], dir, .two_forty);
            // straight line above
            positions[5] = getRotation(positions[0], dir, .three_hundo);
            positions[6] = getRotation(positions[1], dir, .three_hundo);
            positions[7] = getRotation(positions[2], dir, .three_hundo);
            // same direction
            positions[8] = getRotation(positions[2], dir, .full);
            // straight line below
            positions[9] = getRotation(positions[2], dir, .sixty);
            positions[10] = getRotation(positions[1], dir, .sixty);
            positions[11] = getRotation(positions[0], dir, .sixty);
            // +60 deg rot
            positions[12] = getRotation(positions[0], dir, .one_twenty);
            // ring 2 (|): Clockwise from 3
            //   | | | | |         4 5 6 7 8
            //    x x x x           x x x x
            // | x o o o x | ->  3 x o o o x 9
            //    x x x x           x x x x
            //   | | | | |         4 3 2 1 0
            // opposite direction
            positions[13] = getRotation(positions[3], dir, .one_eighty);
            // +60 rot
            positions[14] = getRotation(positions[4], dir, .two_forty);
            // straight line
            positions[15] = getRotation(positions[4], dir, .three_hundo);
            positions[16] = getRotation(positions[5], dir, .three_hundo);
            positions[17] = getRotation(positions[6], dir, .three_hundo);
            positions[18] = getRotation(positions[7], dir, .three_hundo);
            // same dir
            positions[19] = getRotation(positions[8], dir, .full);
            // +60
            positions[20] = getRotation(positions[9], dir, .sixty);
            // straight line
            positions[21] = getRotation(positions[10], dir, .sixty);
            positions[22] = getRotation(positions[11], dir, .sixty);
            positions[23] = getRotation(positions[12], dir, .sixty);
            positions[24] = getRotation(positions[12], dir, .one_twenty);
            // set ring 0 values
            self.board.set(idxFromPos(positions[0].?));
            self.board.unset(idxFromPos(positions[1].?));
            self.board.unset(idxFromPos(positions[2].?));
            // Redundancies: TODO
            // Update directions
            for (positions) |position| {
                if (position) |pos| {
                    self.updateDirections(idxFromPos(pos));
                }
            }
        }

        pub fn updateDirections(self: *Self, idx: T) void {
            if (self.board.isSet(idx)) {
                self.updatePosMoves(idx);
            } else {
                self.updateNegMoves(idx);
            }
            var dir: Directions = self.directions.items[idx];
            if (self.board.isSet(idx)) {
                dir = dir.xorWith(dir);
                self.directions.items[idx] = dir;
                return;
            }
            const pos: Position = posFromIdx(idx);
            for ([_]Direction{ .Left, .UpLeft, .UpRight, .Right, .DownRight, .DownLeft }) |iter_dir| {
                const pos1 = getRotation(pos, iter_dir, .full) orelse continue;
                const pos2 = getRotation(pos, iter_dir, .full) orelse continue;
                const idx1 = idxFromPos(pos1);
                if (idx1 >= self.board.capacity()) continue;
                const idx2 = idxFromPos(pos2);
                if (idx2 >= self.board.capacity()) continue;
                if (!self.board.isSet(idx1) or !self.board.isSet(idx2)) continue;
                dir.insert(iter_dir);
            }
            self.directions.items[idx] = dir;
        }

        pub fn updatePosMove(self: *Self, idx: T) void {
            // have peg at idx
            // check if next two neighbors:
            // neighbor = exist + set
            // next to neighbor = exist + set
            if (!self.board.isSet(idx)) return;
            const pos = posFromIdx(idx);
            inline for (comptime std.meta.fieldNames(Direction)) |fieldname| {
                const dir = @field(Direction, fieldname);
                const pos_ring1 = getRotation(pos, dir, .full);
                const pos_ring2 = getRotation(pos_ring1, dir, .full);
                // origin
                if (pos_ring1 != null and pos_ring2 != null) {
                    self.pos_moves[idx].insert(dir);
                    const idx2 = idxFromPos(pos_ring2.?);
                    const opp_dir = Direction.opposite(dir);
                    self.neg_moves[idx2].insert(opp_dir);
                }
            }
        }

        pub fn updateNegMove(self: *Self, idx: T) void {
            // have hole at idx,
            // check if next two neighbors:
            // neighbor = exist + set
            // next to neighbor = exist + set
            if (self.board.isSet(idx)) return;
            const pos = posFromIdx(idx);
            inline for (comptime std.meta.fieldNames(Direction)) |fieldname| {
                const dir = @field(Direction, fieldname);
                const pos_ring1 = getRotation(pos, dir, .full);
                const pos_ring2 = getRotation(pos_ring1, dir, .full);
                // origin
                if (pos_ring1 != null and pos_ring2 != null) {
                    self.neg_moves[idx].insert(dir);
                    const idx2 = idxFromPos(pos_ring2.?);
                    const opp_dir = Direction.opposite(dir);
                    self.pos_moves[idx2].insert(opp_dir);
                }
                // update non-origin
            }
        }

        fn getPosFromIdx(self: *const Self, idx: T) ?Position {
            if (idx > self.board.capacity()) return null;
            return posFromIdx(idx);
        }

        fn getLeft(pos: Position) ?Position {
            if (pos.col == 0) return null;
            return Position{
                .row = pos.row,
                .col = pos.col - 1,
            };
        }

        fn getUpLeft(pos: Position) ?Position {
            if (pos.row == 0 or pos.col == 0) return null;
            return Position{
                .row = pos.row - 1,
                .col = pos.col - 1,
            };
        }

        fn getUpRight(pos: Position) ?Position {
            if (pos.row == 0 or pos.col >= pos.row) return null;
            return Position{
                .row = pos.row - 1,
                .col = pos.col,
            };
        }

        fn getRight(pos: Position) ?Position {
            if (pos.col >= pos.row) return null;
            return Position{
                .row = pos.row,
                .col = pos.col + 1,
            };
        }

        fn getDownRight(pos: Position) ?Position {
            if (pos.row >= n_rows or pos.col >= n_rows) return null;
            return Position{
                .row = pos.row + 1,
                .col = pos.col + 1,
            };
        }

        fn getDownLeft(pos: Position) ?Position {
            if (pos.row >= n_rows or pos.col > pos.row) return null;
            return Position{
                .row = pos.row + 1,
                .col = pos.col,
            };
        }

        fn getRotation(pos: ?Position, dir: Direction, rot: Rotation) ?Position {
            if (pos) |p| {
                switch (rot) {
                    .sixty => return switch (dir) {
                        .Left => getLeft(p),
                        .UpLeft => getUpRight(p),
                        .UpRight => getRight(p),
                        .Right => getDownRight(p),
                        .DownRight => getDownLeft(p),
                        .DownLeft => getLeft(p),
                    },
                    .one_twenty => return switch (dir) {
                        .Left => getUpRight(p),
                        .UpLeft => getRight(p),
                        .UpRight => getDownRight(p),
                        .Right => getDownLeft(p),
                        .DownRight => getLeft(p),
                        .DownLeft => getUpLeft(p),
                    },
                    .one_eighty => return switch (dir) {
                        .Left => getRight(p),
                        .UpLeft => getDownRight(p),
                        .UpRight => getDownLeft(p),
                        .Right => getLeft(p),
                        .DownRight => getUpLeft(p),
                        .DownLeft => getUpRight(p),
                    },
                    .two_forty => return switch (dir) {
                        .Left => getDownRight(p),
                        .UpLeft => getDownLeft(p),
                        .UpRight => getLeft(p),
                        .Right => getUpLeft(p),
                        .DownRight => getUpRight(p),
                        .DownLeft => getRight(p),
                    },
                    .three_hundo => return switch (dir) {
                        .Left => getDownLeft(p),
                        .UpLeft => getLeft(p),
                        .UpRight => getUpLeft(p),
                        .Right => getUpRight(p),
                        .DownRight => getRight(p),
                        .DownLeft => getDownRight(p),
                    },
                    .full => return switch (dir) {
                        .Left => getLeft(p),
                        .UpLeft => getUpLeft(p),
                        .UpRight => getUpRight(p),
                        .Right => getRight(p),
                        .DownRight => getDownRight(p),
                        .DownLeft => getDownLeft(p),
                    },
                }
            }
            return null;
        }

        pub fn isWon(self: *const Self) bool {
            return self.board.count() == 1;
        }

        pub fn isLost(self: *const Self) bool {
            const len = self.board.capacity();
            for (0..len) |i| {
                print("{}\n", .{i});
            }
            return false;
            // return self.board.count() > 0;
        }

        pub fn printMoves(self: *const Self) void {
            print("Negative Moves:\n", .{});
            for (self.neg_moves, 0..) |neg_move, i| {
                print("{}: {}\n", .{ i, neg_move.count() });
            }
            print("Positive Moves\n", .{});
            for (self.pos_moves, 0..) |pos_move, i| {
                print("{}: {}\n", .{ i, pos_move.count() });
            }
        }
    };
}

test "Set + Unsets Correct Pieces" {
    // needs to be fixed
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;

    const allo = std.testing.allocator;
    const starts = [_]T{ 0, 3, 8 };
    const directions: []const []const Direction = &.{
        &.{ .DownLeft, .DownRight },
        &.{ .Right, .UpRight },
        &.{ .UpLeft, .Left },
    };
    const expected_counts = [_]T{ 32760, 32741, 32367 };

    for (starts, directions, expected_counts) |start, dirs, expected_count| {
        var board: Board = try .init(allo, start);
        defer board.deinit();
        for (dirs) |dir| {
            try board.chooseMove(start, dir);
        }
        try std.testing.expectEqual(board.board.mask, expected_count);
    }
}

test "Win Condition" {
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;

    const allo = std.testing.allocator;
    const start = 0;

    var board: Board = try .init(allo, start);
    defer board.deinit();

    try board.chooseMove(start, .DownLeft);
    try board.chooseMove(3, .Right);
    try board.chooseMove(5, .UpLeft);
    try board.chooseMove(1, .DownLeft);
    try board.chooseMove(2, .DownRight);
    try board.chooseMove(3, .DownRight);
    try board.chooseMove(0, .DownLeft);
    try board.chooseMove(5, .UpLeft);
    try board.chooseMove(12, .Left);
    try board.chooseMove(11, .Right);
    try board.chooseMove(12, .UpRight);
    try board.chooseMove(13, .Left);
    try board.chooseMove(12, .Right);

    try std.testing.expect(board.isWon());
}

test "Lose Condition" {}
