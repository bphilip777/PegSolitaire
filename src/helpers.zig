const std = @import("std");
const Allocator = std.mem.Allocator;

pub const T: type = u16;

pub inline fn numCharsFromDigit(digit: T) T {
    return @truncate(@max(@as(usize, @intFromFloat(@ceil(@log10(@as(f64, @floatFromInt(digit + 1)))))), 1));
}

pub fn numCharsFromIdx(idx: T) T {
    return numCharsFromDigit(idx);
}

test "Num Chars From Idx" {
    const inputs = [_]T{ 1, 10, 100, 1_000, 10_000 };
    const expected = [_]T{ 1, 2, 3, 4, 5 };
    for (inputs, expected) |input, expects| {
        const digits = numCharsFromIdx(input);
        try std.testing.expectEqual(expects, digits);
    }
}

pub fn numCharsFromPos(pos: Position) T {
    const n_row_chars = numCharsFromDigit(pos.row);
    const n_col_chars = numCharsFromDigit(pos.col);
    return n_row_chars + n_col_chars;
}

test "Num Chars From Pos" {
    const inputs = [_]T{ 0, 10, 100, 1_000, 10_000 };
    const answers = [_]T{ 2, 2, 3, 4, 6 };
    for (inputs, answers) |input, answer| {
        const pos = posFromIdx(input);
        const num_chars = numCharsFromPos(pos);
        try std.testing.expectEqual(answer, num_chars);
    }
}

pub fn triNum(n: T) T {
    std.debug.assert(n <= 361);
    return if ((n & 1) == 0) (n / 2) * (n + 1) else ((n + 1) / 2) * n;
}

test "Tri Num" {
    const expected_tri_nums = [_]T{ 0, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66 };
    for (expected_tri_nums, 0..) |expected_tri_num, i| {
        try std.testing.expectEqual(triNum(@truncate(i)), expected_tri_num);
    }
}

pub fn invTriNum(n: T) T {
    return @intFromFloat((@sqrt(8 * @as(f32, @floatFromInt(n)) + 1) - 1) / 2);
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

pub fn invTriNum2(n: T) T {
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

pub const Position = struct {
    row: T,
    col: T,

    pub fn eql(pos1: Position, pos2: Position) bool {
        return pos1.row == pos2.row and pos1.col == pos2.col;
    }

    pub fn dst(pos1: Position, pos2: Position) T {
        const max_row = @max(pos1.row, pos2.row);
        const min_row = @min(pos1.row, pos2.row);
        const max_col = @max(pos1.col, pos2.col);
        const min_col = @min(pos1.col, pos2.col);
        return @max(max_row - min_row, max_col - min_col);
    }

    pub fn flip(pos: *const Position) Position {
        return Position{
            .row = pos.row,
            .col = pos.row - pos.col,
        };
    }
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

pub fn idxFromFlip(pos: Position) T {
    return triNum(pos.row) + pos.col;
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

pub const Rotation: type = enum(u8) {
    sixty = 1,
    one_twenty = 2,
    one_eighty = 3,
    two_forty = 4,
    three_hundo = 5,
    full = 6,

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

pub const Direction: type = enum(u8) {
    None = 0,
    Left = 1,
    UpLeft = 2,
    UpRight = 3,
    Right = 4,
    DownRight = 5,
    DownLeft = 6,

    pub fn opposite(input: *const Direction) Direction {
        return switch (input.*) {
            .Left => .Right,
            .UpLeft => .DownRight,
            .UpRight => .DownLeft,
            .Right => .Left,
            .DownRight => .UpLeft,
            .DownLeft => .UpRight,
            else => .None,
        };
    }

    pub fn flip(input: *const Direction) Direction {
        return switch (input.*) {
            .Left => .Right,
            .UpLeft => .UpRight,
            .UpRight => .UpLeft,
            .Right => .Left,
            .DownRight => .DownLeft,
            .DownLeft => .DownRight,
            else => .None,
        };
    }
};

pub const Directions: type = std.enums.EnumSet(Direction);

pub fn numMoves(move: Directions) T {
    var n_items: T = 0;
    inline for (comptime std.meta.fieldNames(Direction)) |field_name| {
        const dir = @field(Direction, field_name);
        n_items += switch (dir) {
            .None => 0,
            else => @intFromBool(move.contains(dir)),
        };
    }
    return n_items;
}

test "Get Number Of Moves" {
    const a: Directions = .initFull();
    const a_moves = numMoves(a);
    try std.testing.expectEqual(6, a_moves);

    var b: Directions = .initEmpty();
    b.insert(.Left);
    b.insert(.Right);
    const b_moves = numMoves(b);
    try std.testing.expectEqual(2, b_moves);
}

pub fn getAllMoves(moves: []const Directions) T {
    var total: T = 0;
    for (moves) |move| total += numMoves(move);
    return total;
}

test "Get All Moves" {
    // Assumes no overflow
    const a = [_]Directions{.initFull()} ** 5;
    const total_a_moves = getAllMoves(&a);
    try std.testing.expectEqual(30, total_a_moves);

    var b: Directions = .initEmpty();
    b.insert(.Left);
    b.insert(.Right);

    var c: Directions = .initEmpty();
    c.insert(.UpLeft);
    c.insert(.None);
    c.insert(.DownLeft);

    const bc = [2]Directions{ b, c };
    const total_bc_moves = getAllMoves(&bc);
    try std.testing.expectEqual(4, total_bc_moves);
}

pub fn numChars(move: Directions) T {
    const n_items = numMoves(move);
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
    var num_chars = numChars(a);
    try std.testing.expectEqual(num_chars, 5);

    a.insert(.Left);
    num_chars = numChars(a);
    try std.testing.expectEqual(num_chars, 11);

    a.insert(.UpLeft);
    num_chars = numChars(a);
    try std.testing.expectEqual(num_chars, 19);
}

pub fn formatMove(allo: Allocator, move: Directions, max_moves_char: T) ![]u8 {
    // inits
    const empty_buffer = [_]u8{' '} ** 1024;
    var moves_str: []u8 = try std.fmt.allocPrint(allo, "", .{});
    var tmp: []u8 = undefined;
    //
    const n_items: T = numMoves(move);
    var first: bool = true;
    if (n_items > 0) {
        for ([_]Direction{
            .Left,
            .UpLeft,
            .UpRight,
            .Right,
            .DownRight,
            .DownLeft,
        }) |dir| {
            if (move.contains(dir)) {
                if (first) {
                    tmp = try std.fmt.allocPrint(allo, "{s}", .{@tagName(dir)});
                    first = false;
                } else {
                    tmp = try std.fmt.allocPrint(
                        allo,
                        "{s}, {s}",
                        .{ moves_str, @tagName(dir) },
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

    const max_moves_char = numChars(move);

    const moves_str = try formatMove(allo, move, max_moves_char);
    defer allo.free(moves_str);
    try std.testing.expectEqualStrings(moves_str, "Right, DownRight, DownLeft");
}

pub const Input = union(enum(u8)) {
    idx: T,
    pos: Position,
};

pub fn flipIdx(idx: T) T {
    const pos = posFromIdx(idx);
    const flip_pos = pos.flip();
    return idxFromPos(flip_pos);
}

test "Idx From Flip" {
    // 0
    // 1 2
    // 3 4 5
    // 6 7 8 9
    const values = [_]T{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    const expects = [_]T{ 0, 2, 1, 5, 4, 3, 9, 8, 7, 6 };
    for (values, expects) |value, expect| {
        const answer = flipIdx(value);
        try std.testing.expectEqual(expect, answer);
    }
}
