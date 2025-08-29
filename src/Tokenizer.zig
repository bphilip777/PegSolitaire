const std = @import("std");

const print = std.debug.print;
const eql = std.mem.eql;
const Allocator = std.mem.Allocator;

const toLower = std.ascii.toLower;

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
    undo,
    help,
    reset,
    redo,
    quit,
    num,
    dir,
};

const Keyword = struct { str: []const u8, tag: Tag };

const keywords = [_]Keyword{
    .{ .str = "Undo", .tag = .undo },
    .{ .str = "Help", .tag = .help },
    .{ .str = "Reset", .tag = .reset },
    .{ .str = "Redo", .tag = .redo },
    .{ .str = "Quit", .tag = .quit },
    .{ .str = "Left", .tag = .dir },
    .{ .str = "UpLeft", .tag = .dir },
    .{ .str = "UpRight", .tag = .dir },
    .{ .str = "Right", .tag = .dir },
    .{ .str = "DownRight", .tag = .dir },
    .{ .str = "DownLeft", .tag = .dir },
};

const Token = struct {
    start: u8,
    end: u8,
    tag: Tag,
};

fn tokenize(allo: Allocator, input: []const u8) !std.ArrayList(Token) {
    if (input.len > std.math.maxInt(u8)) return error.IncorrectStringSize;

    var tokens: std.ArrayList(Token) = try .initCapacity(allo, 5);
    errdefer tokens.deinit(allo);

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
                const word = input[start..end];
                var tag: Tag = undefined;
                if (word.len == 1) { // 1 letter combo
                    // "u", "h", "q", "l", "r",
                    tag = switch (input[start]) {
                        'u' => .undo,
                        'h' => .help,
                        'q' => .quit,
                        'l' => .dir,
                        'r' => .dir,
                        else => return error.InvalidCharacter,
                    };
                } else if (word.len == 2) { // two letter combo
                    const value: u16 = (@as(u16, toLower(input[start])) << 8) + @as(u16, toLower(input[end]));
                    const kws = [_]u16{
                        @as(u16, 'u' << 8) + @as(u16, 'l'),
                        @as(u16, 'u' << 8) + @as(u16, 'r'),
                        @as(u16, 'd' << 8) + @as(u16, 'l'),
                        @as(u16, 'd' << 8) + @as(u16, 'r'),
                    };
                    tag = switch (value) {
                        kws[0], kws[1], kws[2], kws[3] => .dir,
                        else => {
                            print("\nFailed on {s}!!!\n", .{word});
                            return error.InvalidInput;
                        },
                    };
                } else { // longer inputs
                    var match: bool = false;
                    outer: for (keywords) |keyword| {
                        if (keyword.str.len != word.len) continue :outer;
                        for (keyword.str, word) |ch1, ch2| {
                            if (toLower(ch1) != toLower(ch2)) continue :outer;
                        }
                        tag = keyword.tag;
                        match = true;
                        break :outer;
                    }
                    if (!match) return error.InvalidInput;
                }
                try tokens.append(allo, .{ .start = start, .end = end, .tag = tag });
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

    // Expect these to pass
    const Instruction = struct { input: []const u8, tags: []const Tag };
    const instructions = [_]Instruction{
        // show order does not matter at this point
        .{ .input = "0 0 right", .tags = &.{ .num, .num, .dir } },
        .{ .input = "right 0 0", .tags = &.{ .dir, .num, .num } },
        .{ .input = "0 right 0", .tags = &.{ .num, .dir, .num } },
        // show that single values or double values or full values don't matter
        .{ .input = "ul l h", .tags = &.{ .dir, .dir, .help } },
        // .{ .input = "ur ? dr", .tags = &.{ .dir, .help, .dir } },
        // .{ .input = "ul q r", .tags = &.{ .dir, .quit, .dir } },
    };
    for (instructions) |ins| {
        var tokens: std.ArrayList(Token) = try tokenize(allo, ins.input);
        defer tokens.deinit(allo);
        // check length
        std.testing.expect(ins.tags.len == tokens.items.len) catch |err| {
            print("{} - {}\n", .{ ins.tags.len, tokens.items.len });
            return err;
        };
        // check each tag
        for (tokens.items, ins.tags) |token, tag| {
            try std.testing.expectEqual(token.tag, tag);
        }
    }

    // Expect these to fail
}
