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

const Tag = enum {
    help,
    reset,
    redo,
    undo,
    quit,
    num,
    dir,
};

const Token = struct {
    start: u8,
    end: u8,
    tag: Tag,
};

fn tokenize(allo: Allocator, input: []const u8) !std.ArrayList(Token) {
    if (input.len > std.math.maxInt(u8)) return error.IncorrectStringSize;
    var tokens: std.ArrayList(Token) = try .initCapacity(allo, 5);

    var i: u8 = 0;
    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            '0'...'9' => {
                const start = i;
                inner: while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        '0'...'9' => continue,
                        else => break :inner,
                    }
                }
                const end = i;
                try tokens.append(allo, .{ .start = start, .end = end, .tag = .num });
            },
            'a'...'z', 'A'...'Z' => {
                const start = i;
                inner: while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        'a'...'z', 'A'...'Z' => continue,
                        else => break :inner,
                    }
                }
                const end = i;
                // identify tag
                try tokens.append(allo, .{ .start = start, .end = end, .tag = .dir });
            },
            '?' => {
                if (i == 0) //
                    try tokens.append(allo, .{ .start = 0, .end = 1, .tag = .help }) //
                else //
                    return error.InvalidCharacter;
            },
            ' ', ',', '(', ')' => continue,
            else => return error.InvalidCharacter,
        }
    }

    return tokens;
}

test "Tokenizer" {
    const allo = std.testing.allocator;
    const Instruction = struct {input: []const u8, outputs: [3], };
    const instructions = [_]Instruction {
        .{.input = "redo 5 5",  .output = ""};
    }
    var tokens = try tokenize(allo, "redo 5 5");
    defer tokens.deinit(allo);
}
