const std = @import("std");

const print = std.debug.print;
const eql = std.mem.eql;
const Allocator = std.mem.Allocator;

const T = @import("Helpers.zig");

// fuzzing book

// TODO:
// manual:
// - ignore trailing or starting whitespaces, commas, spaces
// - parse h, help, HELP, Help, ? = bring up help page
// - parse u, undo, UNDO, Undo = undo move
// - parse r, reset, RESET, reset = reset board
// - parse (num1, num2) as coordinate on board
// - parse directions:
//  - Left, L, l, .Left = .Left
// - parse toggles:
//  - show moves
//  - show positions
// - parse as moves:
//      - (num1, num2) -> (num1, num2)
//      - (num1, num2, dir)
//      - (num1, num2, dir)
//      - num1, num2 -> num1, num2
//      - num1, num2, num3, num4
//      - num1 num2 num3 num4
//      - num1 num2 DownLeft
// - error handling:
//  - input cannot be too long
//  - input cannot perform a random command - only internal commands
//  - input cannot escape string
//  - Ex: EndOfStream, TooLong, InvalidMove, InvalidIdx

fn singleCharMatches(input: []const u8) !Key {
    // q = quit, r = reset, u = undo
    std.debug.assert(input.len == 1);
    return switch (input[0]) {
        'r' => .reset,
        'u' => .undo,
        'q' => .quit,
        'h', '?' => .help,
        'b' => .board,
        'm' => .move,
        // 'l', 'r' => .dir, -- needs to be handled differently
        else => error.InvalidCharacter,
    };
}

fn doubleCharMatches(input: []const u8) !Key {
    std.debug.assert(input.len == 2);
    return switch (input[0]) {
        'd' => switch (input[1]) {
            'r', 'l' => .dir,
            else => error.InvalidCharacter,
        },
        'u' => switch (input[1]) {
            'r', 'l' => .dir,
            else => error.InvalidCharacter,
        },
        else => error.InvalidCharacter,
    };
}

fn isMatch(input: []const u8, key: []const u8) bool {
    if (input.len != key.len) return false;
    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        if (std.ascii.toLower(input[i]) != key[i]) return false;
    }
    return true;
}

test "Is Match" {
    const Instruction = struct { input: []const u8, command: []const u8, match: bool };
    const instructions = [_]Instruction{
        .{ .input = "redo", .command = "redo", .match = true },
        .{ .input = "r", .command = "redo", .match = false },
        .{ .input = "z", .command = "redo", .match = false },
        .{ .input = "undo", .command = "undo", .match = true },
        .{ .input = "u", .command = "undo", .match = false },
        .{ .input = "q", .command = "undo", .match = false },
        .{ .input = "reset", .command = "reset", .match = true },
        .{ .input = "r", .command = "reset", .match = false },
        .{ .input = "t", .command = "reset", .match = false },
    };
    for (instructions) |ins| {
        const match = isMatch(ins.input, ins.command);
        try std.testing.expectEqual(match, ins.match);
    }
}

const Token = struct { // 3 bytes
    start: u8,
    end: u8,
    key: Key,
};

const Key = enum { // 1 byte
    redo,
    undo,
    reset,
    help,
    quit,
    num,
    dir,
    board, // print board
    move, // print moves
};

pub fn tokenize(allo: Allocator, input: []const u8) !std.ArrayList(Token) {
    if (input.len > 255) return error.InputStrTooLong;

    var tokens: std.ArrayList(Token) = try .initCapacity(allo, 5);

    var i: u8 = 0;
    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            ' ', ',', '(', ')' => continue,
            '0'...'9' => {
                const start: u8 = i;
                i += 1;
                const end: u8 = loop: while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        '0'...'9' => continue,
                        ' ', ',' => break :loop i,
                        else => return error.InvalidCharacter,
                    }
                } else break :loop @truncate(input.len);
                try tokens.append(allo, .{
                    .start = start,
                    .end = end,
                    .key = .num,
                });
            },
            'a'...'z', 'A'...'Z' => {
                const start: u8 = i;
                i += 1;
                const end: u8 = loop: while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        'a'...'z', 'A'...'Z' => {},
                        ' ', ',' => break :loop i,
                        else => return error.InvalidCharacter,
                    }
                } else break :loop @truncate(input.len);
                const key: Key = if (input.len == 1) try singleCharMatches(input) //
                    else if (input.len == 2) try doubleCharMatches(input) //
                    else if (isMatch(input[start..end], "undo")) .undo //
                    else if (isMatch(input[start..end], "redo")) .redo //
                    else if (isMatch(input[start..end], "reset")) .reset //
                    else if (isMatch(input[start..end], "help")) .help //
                    else if (isMatch(input[start..end], "quit")) .quit //
                    else if (isMatch(input[start..end], "Left")) .dir //
                    else if (isMatch(input[start..end], "UpLeft")) .dir //
                    else if (isMatch(input[start..end], "UpRight")) .dir //
                    else if (isMatch(input[start..end], "Right")) .dir //
                    else if (isMatch(input[start..end], "DownRight")) .dir //
                    else if (isMatch(input[start..end], "DownLeft")) .dir //
                    else return error.InvalidString;

                try tokens.append(allo, .{
                    .start = start,
                    .end = end,
                    .key = key,
                });
            },
            else => return error.InvalidCharacter,
        }
    }
    return tokens;
}

test "Tokenize" {
    const allo = std.testing.allocator;

    const inputs = [_][]const u8{ "left", "right", "" };
    for (inputs) |input| {
        const tokens = try tokenize(allo, input);
        tokens.deinit(allo);
        for (tokens.items) |token| {
            print("{s} - {s}\n", .{ input[token.start..token.end], @tagName(token.key) });
        }
        print("\n", .{});
    }
}
