const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const T: type = u16;

fn numCharsFromDigit(digit: T) T {
    return @truncate(@max(@as(usize, @intFromFloat(@ceil(@log10(@as(f64, @floatFromInt(digit + 1)))))), 1));
}

test "Num Chars From Digit" {
    const inputs = [_]T{ 1, 10, 100, 1_000, 10_000 };
    const expected = [_]T{ 1, 2, 3, 4, 5 };
    for (inputs, expected) |input, expects| {
        const digits = numCharsFromDigit(input);
        try std.testing.expectEqual(expects, digits);
    }
}

fn numCharsFromIdx(idx: T) T {
    const pos = posFromIdx(idx);
    const row = numCharsFromDigit(pos.row);
    const col = numCharsFromDigit(pos.col);
    return row + col + 2;
}

test "Num Chars From Idx" {
    const n1 = numCharsFromIdx(0);
    try std.testing.expectEqual(n1, 4);
    const n2 = numCharsFromIdx(100);
    try std.testing.expectEqual(n2, 5);
}

pub fn triNum(n: T) !T {
    std.debug.assert(n <= 361);
    return (n / 2) * (n + 1);
}

test "Tri Num" {
    const expected_tri_nums = [_]T{ 0, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66 };
    for (expected_tri_nums, 0..) |expected_tri_num, i| {
        try std.testing.expectEqual(triNum(@truncate(i)), expected_tri_num);
    }
    try std.testing.expectError(triNum(362));
}

fn invTriNum(n: T) T {
    return @intFromFloat(@floor((@sqrt(8 * @as(f32, @floatFromInt(n)) + 1) - 1) / 2));
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

    // used to ensure first version is correct and how to use it
    for (inputs) |input| {
        const itn1 = invTriNum(input);
        const itn2 = invTriNum2(input);
        try std.testing.expectEqual(itn1, itn2);
    }
}

// find max value of u16 -> get triangle row number -> take floor = max number of rows
const MAX_INPUT_SIZE: u16 = invTriNum(std.math.maxInt(u16));

const Position = struct {
    row: T,
    col: T,
};

pub fn posFromIdx(idx: T) !Position {
    const row = invTriNum(idx);
    const tri_num = try triNum(row);
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

pub const Direction: type = enum { // 1 byte
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

pub const Move = struct { // 4 = wasted 1 byte
    idx: T, // 2
    dir: Direction, // 1 -> 2
};

fn getNumMoves(move: Directions) T {
    var n_items: T = 0;
    inline for (comptime std.meta.fieldNames(Direction)) |fieldName| {
        n_items += @intFromBool(move.contains(@field(Direction, fieldName)));
    }
    return n_items;
}

test "Get Number Of Moves" {
    const a: Directions = .initFull();
    const a_moves = getNumMoves(a);
    try std.testing.expectEqual(6, a_moves);

    var b: Directions = .initEmpty();
    b.insert(.Left);
    b.insert(.Right);
    const b_moves = getNumMoves(b);
    try std.testing.expectEqual(2, b_moves);
}

fn getNumChars(move: Directions) T {
    const n_items = getNumMoves(move);
    if (n_items == 0) return 0;
    var num_chars: T = 0;
    inline for (comptime std.meta.fieldNames(Direction)) |field_name| {
        const dir = @field(Direction, field_name);
        num_chars += @as(T, @intFromBool(move.contains(dir))) * @as(T, @truncate(field_name.len));
    }
    return if (n_items == 1) num_chars else num_chars + (2 * (n_items - 1));
}

test "Get Number of Characters" {
    var a: Directions = .initEmpty();
    a.insert(.Right);
    var num_chars = getNumChars(a);
    try std.testing.expectEqual(num_chars, 5);

    a.insert(.Left);
    num_chars = getNumChars(a);
    try std.testing.expectEqual(num_chars, 11);

    a.insert(.UpLeft);
    num_chars = getNumChars(a);
    try std.testing.expectEqual(num_chars, 19);
}

fn formatMove(allo: Allocator, move: Directions, max_moves_char: T) ![]u8 {
    // 2 problems to fix:
    // header spacing
    // removing trailing ,
    // empty strings
    const empty_buffer = [_]u8{' '} ** 1024;
    var moves_str: []u8 = try std.fmt.allocPrint(allo, "", .{});
    var tmp: []u8 = undefined;

    const n_items: T = getNumMoves(move);
    var first: bool = true;
    if (n_items > 0) {
        inline for (comptime std.meta.fieldNames(Direction)) |field_name| {
            const dir = @field(Direction, field_name);
            if (move.contains(dir)) {
                if (first) {
                    tmp = try std.fmt.allocPrint(allo, "{s}", .{field_name});
                    first = false;
                } else {
                    tmp = try std.fmt.allocPrint(
                        allo,
                        "{s}, {s}",
                        .{ moves_str, field_name },
                    );
                }
                allo.free(moves_str);
                moves_str = tmp;
            }
        }
    }

    if (moves_str.len < max_moves_char) {
        const diff = max_moves_char - moves_str.len;
        tmp = try std.fmt.allocPrint(
            allo,
            "{s}{s}",
            .{ moves_str, empty_buffer[0..diff] },
        );
        allo.free(moves_str);
        moves_str = tmp;
    }

    return moves_str;
}

test "Format Move" {
    const allo = std.testing.allocator;

    var move: Directions = .initEmpty();
    move.insert(.Right);
    move.insert(.DownRight);
    move.insert(.DownLeft);

    const max_moves_char = getNumChars(move);

    const moves_str = try formatMove(allo, move, max_moves_char);
    defer allo.free(moves_str);
    try std.testing.expectEqualStrings(moves_str, "Right, DownRight, DownLeft");
}

const GameErrors = error{
    NRowsTooSmall,
    NRowsTooLarge,
    StartMustBeGT0OrLTNumIndices,
    InvalidMove,
    InvalidPosition,
};

pub const Moves = struct { // 4
    idx: T, // 2
    dir: Direction, // 1 -> 2
};

pub fn createBoard(comptime n_rows: T) !type {
    if (n_rows < 3) return GameErrors.NRowsTooSmall;
    if (n_rows > MAX_INPUT_SIZE) return GameErrors.NRowsTooLarge;
    const n_indices = try triNum(n_rows);

    // 110 bytes
    // 110 * 65536 =  6_553_600 = just 6 MBs of data - easy to upfront allocate
    return struct {
        board: std.bit_set.IntegerBitSet(n_indices) = .initFull(), // 2 bytes
        start: T = 0, // 2 bytes
        moves: [n_indices]Directions = undefined, // store neg move, convert pos to neg, 1 byte
        chosen_moves: [n_indices]?Move = undefined, // store neg move, max moves = n_indices - 1, 1 byte,

        pub fn init(start: T) !@This() {
            // Validity Check
            if (start >= n_indices) return GameErrors.StartMustBeGT0OrLTNumIndices;
            // moves
            var moves: [n_indices]Directions = undefined;
            var chosen_moves: [n_indices]?Move = undefined;

            for (0..n_indices) |i| {
                moves[i] = .initEmpty();
                chosen_moves[i] = null;
            }

            var self = @This(){
                .start = start,
                .moves = moves,
                .chosen_moves = chosen_moves,
            };
            self.resetBoard();
            return self;
        }

        pub fn printBoard(self: *const @This()) void {
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

        fn computeAllMoves(self: *@This()) !void {
            for (0..n_indices) |i| {
                const idx0: T = @truncate(i);
                const pos0 = posFromIdx(idx0);
                for ([_]Direction{ .Left, .UpLeft, .UpRight, .Right, .DownRight, .DownLeft }) |dir| {
                    const pos1 = getRotation(pos0, dir, .full) orelse {
                        self.moves[i].remove(dir);
                        continue;
                    };
                    const pos2 = getRotation(pos1, dir, .full) orelse {
                        self.moves[i].remove(dir);
                        continue;
                    };
                    const idx1 = try idxFromPos(pos1);
                    const idx2 = try idxFromPos(pos2);
                    if (!self.isValidIdx(idx1) or !self.isValidIdx(idx2)) {
                        if (self.moves[i].contains(dir)) self.moves[i].remove(dir);
                        continue;
                    }

                    if (self.hasMove(&.{ idx0, idx1, idx2 })) {
                        self.moves[idx0].insert(dir);
                    } else {
                        self.moves[idx0].remove(dir);
                    }
                }
            }
        }

        fn computeOptimally(self: *@This(), idx: T, dir: Direction) void {
            // assumes idx0 is valid + dir is valid!
            // start form origin -> loop around it through rest of origins
            // for ring 2: get positions multiple ways
            //  Ring 0 (Origin):
            //     o o o -> 0 1 2
            //  Ring 1:
            //    x x x x      4 5 6 7
            //   x o o o x -> 3 o o o 8
            //    x x x x      2 1 0 9
            //  Ring 2:
            //    | | | | |        4 5 6 7 8
            //   | x x x x |        x x x x
            //  | x o o o x | -> 3 x o o o x 9
            //   | x x x x |        x x x x
            //    | | | | |        4 3 2 1 0
            // compute origins
            const start0 = posFromIdx(idx);
            const start1 = getRotation(start0, dir, .full);
            const start2 = getRotation(start1, dir, .full);
            const origins = [_]?Position{ start0, start1, start2 };

            for (origins) |origin| {
                if (origin) |pos0| { // otherwise skip missing origins
                    const idx0 = try idxFromPos(pos0);
                    // rotate about idx0
                    inline for (comptime std.meta.fieldNames(Direction)) |field_name| {
                        // compute directions
                        const new_dir = @field(Direction, field_name);
                        const opp_dir = Direction.opposite(new_dir);
                        // compute positions
                        const pos1 = getRotation(pos0, new_dir, .full);
                        const pos2 = getRotation(pos1, new_dir, .full);
                        const pos3 = getRotation(pos0, new_dir, .one_eighty);
                        // move = along all positions
                        if (pos1 != null and pos2 != null) {
                            const idx1 = try idxFromPos(pos1.?);
                            const idx2 = try idxFromPos(pos2.?);
                            if (self.isValidIdx(idx1) and self.isValidIdx(idx2)) {
                                // forwards
                                if (self.hasMove(&.{ idx0, idx1, idx2 })) {
                                    self.moves[idx0].insert(new_dir);
                                } else if (self.moves[idx0].contains(new_dir)) {
                                    self.moves[idx0].remove(new_dir);
                                }
                                // backwards
                                if (self.hasMove(&.{ idx2, idx1, idx0 })) {
                                    self.moves[idx2].insert(opp_dir);
                                } else if (self.moves[idx2].contains(opp_dir)) {
                                    self.moves[idx2].remove(opp_dir);
                                }
                            }
                        }
                        if (pos1 != null and pos3 != null) {
                            const idx1 = try idxFromPos(pos1.?);
                            const idx3 = try idxFromPos(pos3.?);
                            if (self.isValidIdx(idx1) and self.isValidIdx(idx3)) {
                                // centered
                                if (self.hasMove(&.{ idx1, idx0, idx3 })) {
                                    self.moves[idx1].insert(opp_dir);
                                } else if (self.moves[idx1].contains(opp_dir)) {
                                    self.moves[idx1].remove(opp_dir);
                                }
                            }
                        }
                    }
                }
            }
        }

        fn hasMove(self: *const @This(), idxs: []const T) bool {
            std.debug.assert(idxs.len == 3);
            inline for (0..3) |i| {
                if (!self.isValidIdx(idxs[i])) return false;
            }
            return if (self.board.isSet(idxs[0])) //
                (self.board.isSet(idxs[1]) and !self.board.isSet(idxs[2])) //
            else //
                (self.board.isSet(idxs[1]) and self.board.isSet(idxs[2]));
        }

        pub fn chooseMove(self: *@This(), idx0: T, dir: Direction) void {
            // if idx is not valid return
            if (!self.isValidIdx(idx0)) {
                print("Idx: {} not valid\n", .{idx0});
                return;
            }
            // get positions
            const p0 = posFromIdx(idx0);
            const p1 = getRotation(p0, dir, .full) orelse {
                print(
                    "1. Pos: ({}, {}), Dir: {s}, Does Not Exist\n",
                    .{ p0.row, p0.col, @tagName(dir) },
                );
                return;
            };
            const p2 = getRotation(p1, dir, .full) orelse {
                print(
                    "2. Pos: ({}, {}), Dir: {s}, Does Not Exist\n",
                    .{ p1.row, p1.col, @tagName(dir) },
                );
                return;
            };
            // get idxs
            const idx1 = try idxFromPos(p1);
            const idx2 = try idxFromPos(p2);
            // check move -> apply move = update board
            if (self.board.isSet(idx0)) { // pos
                if (!self.moves[idx2].contains(Direction.opposite(dir))) {
                    print(
                        "3. Pos: ({}, {}), Dir: {s}, Does Not Exist",
                        .{ p2.row, p2.col, @tagName(dir) },
                    );
                    return;
                }
                self.chosen_moves[self.board.count()] = Move{
                    .idx = idx2,
                    .dir = Direction.opposite(dir),
                };
                self.setPosMove(&.{ idx0, idx1, idx2 });
                // self.board.unset(idx0);
                // self.board.unset(idx1);
                // self.board.set(idx2);
            } else { // neg
                if (!self.moves[idx0].contains(dir)) {
                    print(
                        "4. Pos: ({}, {}), Dir: {s}, Does Not Exist\n",
                        .{ p0.row, p0.col, @tagName(dir) },
                    );
                    return;
                }
                self.chosen_moves[self.board.count()] = Move{
                    .idx = idx0,
                    .dir = dir,
                };
                self.setNegMove(&.{ idx0, idx1, idx2 });
                // self.board.set(idx0);
                // self.board.unset(idx1);
                // self.board.unset(idx2);
            }
            // update moves
            // try self.computeAllMoves();
            try self.computeOptimally(idx0, dir);
        }

        pub fn chooseMovePos(self: *@This(), pos: Position, dir: Direction) !void {
            const idx = try idxFromPos(pos);
            if (!self.isValidIdx(idx)) return;
            self.chooseMove(idx, dir);
        }

        pub fn resetBoard(self: *@This()) void {
            // set board to all 1s
            // set start position to 0
            // set moves to empty
            for (0..n_indices) |i| {
                self.board.set(i);
            }
            self.board.unset(self.start);
            try self.computeAllMoves();
        }

        pub fn undoMove(self: *@This()) !void {
            // get idx + move
            const idx = self.board.count() + 1;
            if (idx == n_indices) return;
            const move = self.chosen_moves[idx].?;
            // get positions
            const pos0 = try posFromIdx(move.idx);
            const pos1 = getRotation(pos0, move.dir, .full).?;
            const pos2 = getRotation(pos1, move.dir, .full).?;
            // get idxs
            const idx1 = try idxFromPos(pos1);
            const idx2 = try idxFromPos(pos2);
            // reset board positions
            self.unsetNegMove(&.{ move.idx, idx1, idx2 });
            // self.board.unset(move.idx);
            // self.board.set(idx1);
            // self.board.set(idx2);
            // reset move positions - incorrect
            try self.computeAllMoves();
        }

        pub fn redoMove(self: *@This()) !void {
            const idx = self.board.count();
            const move = self.chosen_moves[idx].?;
            try self.chooseMove(move.idx, move.dir);
        }

        fn setNegMove(self: *const @This(), idxs: []const T) void {
            std.debug.assert(idxs.len != 3);
            std.debug.assert(self.board.isSet(idxs[0]) or //
                !self.board.isSet(idxs[1]) or //
                !self.board.isSet(idxs[2]));
            self.board.set(idxs[0]);
            self.board.unset(idxs[1]);
            self.board.unset(idxs[2]);
        }

        fn setPosMove(self: *const @This(), idxs: []const T) void {
            std.debug.assert(idxs.len != 3);
            std.debug.assert(!self.board.isSet(idxs[0]) or //
                !self.board.isSet(idxs[1]) or //
                self.board.isSet(idxs[2]));
            self.board.unset(idxs[0]);
            self.board.unset(idxs[1]);
            self.board.set(idxs[2]);
        }

        fn unsetNegMove(self: *const @This(), idxs: []const T) void {
            std.debug.assert(idxs.len == 3);
            std.debug.assert(!self.board.isSet(idxs[0]) or //
                self.board.isSet(idxs[1]) or //
                self.board.isSet(idxs[2]));
            self.board.unset(idxs[0]);
            self.board.set(idxs[0]);
            self.board.set(idxs[0]);
        }

        fn unsetPosMove(self: *const @This(), idxs: []const T) void {
            std.debug.assert(idxs.len != 3);
            std.debug.assert(!self.board.isSet(idxs[0]) or //
                !self.board.isSet(idxs[1]) or //
                self.board.isSet(idxs[2]));
            self.board.set(idxs[0]);
            self.board.set(idxs[1]);
            self.board.unset(idxs[2]);
        }

        fn isValidIdx(self: *const @This(), idx: T) bool {
            return idx < self.board.capacity();
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

        pub fn isGameOver(self: *const @This()) bool {
            return self.isWon() or self.isLost();
        }

        pub fn isWon(self: *const @This()) bool {
            return self.board.count() == 1;
        }

        pub fn isLost(self: *const @This()) bool {
            var n_moves: usize = 0;
            for (0..self.board.capacity()) |i| {
                inline for (comptime std.meta.fieldNames(Direction)) |field_name| {
                    const dir = @field(Direction, field_name);
                    n_moves += @intFromBool(self.moves[i].contains(dir));
                }
                // if (n_moves > 0) break;
            }
            return (n_moves == 0 and self.board.count() > 1);
        }

        pub fn reset(self: *@This()) void {
            // set board to all on
            // set start position off
            // undo all moves
            // recompute start moves

            // set board to all on
            for (0..self.board.capacity()) |i| self.board.set(i);
            // set start pposition off
            self.board.unset(self.start);

            for (0..n_indices) |i| {
                // undo all moves
                self.moves[i] = .initEmpty();
                // reset chosen_moves
                self.chosen_moves = null;
            }
            // recompute start moves
            self.computeAllMoves();
        }

        pub fn printMoves(self: *@This(), allo: Allocator) !void {
            // allocator is passed in instead
            const headers = [_][]const u8{ "Coords", "Moves" };
            var max_moves_char: T = 0;
            for (self.moves) |move| {
                max_moves_char = @max(max_moves_char, getNumChars(move));
            }
            max_moves_char = @max(headers[1].len, max_moves_char);

            const column_buffer = " | ";

            {
                // coords header
                const coords_extra = "() ";
                const num_buffer = numCharsFromIdx(n_indices) + coords_extra.len;
                const coord_diff = num_buffer - headers[0].len;

                const diff = max_moves_char - headers[1].len;

                const empty_buffer = [_]u8{' '} ** 1024;
                const underline_buffer = [_]u8{'-'} ** 1024;
                print(
                    "{s}{s}{s}{s}{s}\n",
                    .{
                        headers[0],
                        empty_buffer[0..coord_diff],
                        column_buffer,
                        headers[1],
                        empty_buffer[0..diff],
                    },
                );
                const full_length = num_buffer + (column_buffer.len * 2) + max_moves_char;
                print("{s}\n", .{underline_buffer[0..full_length]});
            }

            // loop
            for (self.moves, 0..) |move, i| {
                const pos = posFromIdx(@truncate(i));
                const coords_str = try std.fmt.allocPrint(
                    allo,
                    "({}, {}) ",
                    .{ pos.row, pos.col },
                );
                defer allo.free(coords_str);

                if (getNumMoves(move) == 0) continue;

                const moves_str = try formatMove(allo, move, max_moves_char);
                defer allo.free(moves_str);
                print("{s}{s}{s}\n", .{ coords_str, column_buffer, moves_str });
            }
        }

        pub fn hasRemainingMoves(self: *const @This()) bool {
            for (self.moves) |move| {
                if (!move.eql(move.xorWith(move))) return true;
            } else return false;
        }
    };
}

test "Has Remaining Moves" {
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    var board: Board = try .init(0);

    const Instruction = struct { idx: u16, dir: Direction, hash_remaining_moves: bool };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .hash_remaining_moves = true },
        .{ .idx = 3, .dir = .Right, .hash_remaining_moves = true },
        .{ .idx = 5, .dir = .UpLeft, .hash_remaining_moves = true },
        .{ .idx = 1, .dir = .DownLeft, .hash_remaining_moves = true },
        .{ .idx = 2, .dir = .DownRight, .hash_remaining_moves = true },
        .{ .idx = 3, .dir = .DownRight, .hash_remaining_moves = true },
        .{ .idx = 0, .dir = .DownLeft, .hash_remaining_moves = true },
        .{ .idx = 5, .dir = .UpLeft, .hash_remaining_moves = true },
        .{ .idx = 12, .dir = .Left, .hash_remaining_moves = true },
        .{ .idx = 11, .dir = .Right, .hash_remaining_moves = true },
        .{ .idx = 12, .dir = .UpRight, .hash_remaining_moves = true },
        .{ .idx = 10, .dir = .Right, .hash_remaining_moves = false },
    };

    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
        try std.testing.expectEqual(
            board.hasRemainingMoves(),
            instruction.hash_remaining_moves,
        );
    }
}

test "Are Neg Moves Correct" {
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    var board: Board = try .init(0);

    const Instruction = struct { idx: u16, dir: Direction, value: u16 };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .value = 32757 },
        .{ .idx = 3, .dir = .Right, .value = 32717 },
        .{ .idx = 5, .dir = .UpLeft, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
        .{ .idx = 12, .dir = .Left, .value = 28960 },
        .{ .idx = 11, .dir = .Right, .value = 18720 },
        .{ .idx = 12, .dir = .UpRight, .value = 22528 },
        .{ .idx = 10, .dir = .Right, .value = 17408 },
    };

    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
        try std.testing.expectEqual(board.board.mask, instruction.value);
    }
}

test "Are Pos Moves Correct" {
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    var board: Board = try .init(0);

    const Instruction = struct { idx: u16, dir: Direction, value: u16 };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 3, .dir = .UpRight, .value = 32757 },
        .{ .idx = 5, .dir = .Left, .value = 32717 },
        .{ .idx = 0, .dir = .DownRight, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
        .{ .idx = 12, .dir = .Left, .value = 28960 },
        .{ .idx = 11, .dir = .Right, .value = 18720 },
        .{ .idx = 12, .dir = .UpRight, .value = 22528 },
        .{ .idx = 10, .dir = .Right, .value = 17408 },
    };

    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
        try std.testing.expectEqual(board.board.mask, instruction.value);
    }
}

test "Is Lost" {
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    var board: Board = try .init(0);

    const Instruction = struct { idx: u16, dir: Direction, is_lost: bool };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 3, .dir = .Right, .is_lost = false },
        .{ .idx = 5, .dir = .UpLeft, .is_lost = false },
        .{ .idx = 1, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 2, .dir = .DownRight, .is_lost = false },
        .{ .idx = 3, .dir = .DownRight, .is_lost = false },
        .{ .idx = 0, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 5, .dir = .UpLeft, .is_lost = false },
        .{ .idx = 12, .dir = .Left, .is_lost = false },
        .{ .idx = 11, .dir = .Right, .is_lost = false },
        .{ .idx = 12, .dir = .UpRight, .is_lost = false },
        .{ .idx = 10, .dir = .Right, .is_lost = true },
    };

    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
        try std.testing.expectEqual(board.isLost(), instruction.is_lost);
    }
}

test "Is Won" {
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    var board: Board = try .init(0);

    const Instruction = struct { idx: u16, dir: Direction, is_won: bool };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .is_won = false },
        .{ .idx = 3, .dir = .Right, .is_won = false },
        .{ .idx = 5, .dir = .UpLeft, .is_won = false },
        .{ .idx = 1, .dir = .DownLeft, .is_won = false },
        .{ .idx = 2, .dir = .DownRight, .is_won = false },
        .{ .idx = 3, .dir = .DownRight, .is_won = false },
        .{ .idx = 0, .dir = .DownLeft, .is_won = false },
        .{ .idx = 5, .dir = .UpLeft, .is_won = false },
        .{ .idx = 12, .dir = .Left, .is_won = false },
        .{ .idx = 11, .dir = .Right, .is_won = false },
        .{ .idx = 12, .dir = .UpRight, .is_won = false },
        .{ .idx = 11, .dir = .Right, .is_won = false },
        .{ .idx = 14, .dir = .Left, .is_won = true },
    };

    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
        try std.testing.expectEqual(board.isWon(), instruction.is_won);
    }
}

test "Reset Board" {
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    var board: Board = try .init(0);

    const start_value: T = board.board.mask;
    const Instruction = struct { idx: u16, dir: Direction, value: u16 };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .value = 32757 },
        .{ .idx = 3, .dir = .Right, .value = 32717 },
        .{ .idx = 5, .dir = .UpLeft, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
        .{ .idx = 12, .dir = .Left, .value = 28960 },
        .{ .idx = 11, .dir = .Right, .value = 18720 },
        .{ .idx = 12, .dir = .UpRight, .value = 22528 },
        .{ .idx = 10, .dir = .Right, .value = 17408 },
    };

    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
    }
    board.resetBoard();
    try std.testing.expectEqual(board.board.mask, start_value);
}

test "Undo Move + Redo Move" {
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    var board: Board = try .init(0);

    const Instruction = struct { idx: u16, dir: Direction, value: u16 };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 3, .dir = .UpRight, .value = 32757 },
        .{ .idx = 5, .dir = .Left, .value = 32717 },
        .{ .idx = 0, .dir = .DownRight, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
        .{ .idx = 12, .dir = .Left, .value = 28960 },
        .{ .idx = 11, .dir = .Right, .value = 18720 },
        .{ .idx = 12, .dir = .UpRight, .value = 22528 },
        .{ .idx = 10, .dir = .Right, .value = 17408 },
    };
    // Original Moves
    for (list_of_instructions) |instruction| {
        board.chooseMove(instruction.idx, instruction.dir);
    }
    // Undo
    for (0..list_of_instructions.len - 1) |i| {
        const j = list_of_instructions.len - i - 2;
        const instruction = list_of_instructions[j];
        try board.undoMove();
        try std.testing.expectEqual(instruction.value, board.board.mask);
    }
    // Redo
    for (0..list_of_instructions.len - 1) |i| {
        const instruction = list_of_instructions[i + 1];
        board.redoMove();
        try std.testing.expectEqual(instruction.value, board.board.mask);
    }
}
