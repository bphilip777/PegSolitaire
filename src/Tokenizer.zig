const std = @import("std");

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

fn isMatch(input: []const u8, key: []const u8) bool {
    // shortcut - may not work
    if (input.len == 1 and std.ascii.toLower(input[0]) == std.ascii.toLower(key[0])) //
        return true;
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
        .{ .input = "r", .command = "redo", .match = true },
        .{ .input = "z", .command = "redo", .match = false },
        .{ .input = "undo", .command = "undo", .match = true },
        .{ .input = "u", .command = "undo", .match = true },
        .{ .input = "q", .command = "undo", .match = false },
        .{ .input = "reset", .command = "reset", .match = true },
        .{ .input = "r", .command = "reset", .match = true },
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

const Key = enum {
    redo,
    undo,
    reset,
    help,
    quit,
    num,
    dir,
};

pub fn tokenize(allo: Allocator, input: []const u8) !std.ArrayList(Token) {
    if (input.len > 255) return error.InputStrTooLong;

    var tokens: std.ArrayList(Token) = try .initCapacity(allo, 5);

    var i: u8 = 0;
    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            ' ', ',' => continue,
            '0'...'9' => {
                const start: u8 = i;
                i += 1;
                const end: u8 = loop: while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        '0'...'9' => continue,
                        else => break :loop i,
                    }
                };
                try tokens.append(.{
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
                        else => break :loop i,
                    }
                };
                const key: Key = if (isMatch(input[start..end], "undo")) .undo //
                    else if (isMatch(input[start..end], "redo")) .redo //
                    else if (isMatch(input[start..end], "reset")) .reset //
                    else if (isMatch(input[start..end], "help")) .help //
                    else if (isMatch(input[start..end], "quit")) .quit //
                    else return error.InvalidString;

                try tokens.append(.{
                    .start = start,
                    .end = end,
                    .key = key,
                });
            },
            else => return error.InvalidCharacter,
        }
    }

    // loop through .str and find which type it is

    return tokens;
}

// test "Tokenize" {
//     const allo = std.testing.allocator;
//
//     const tokens = try tokenize(allo, input);
//     tokens.deinit(allo);
// }
