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

const TokenError = error{
    InputTooSmall,
    InputTooLarge,
    InvalidInput,
};

fn tokenize(allo: Allocator, input: []const u8) (Allocator.Error || TokenError)!std.ArrayList(Token) {
    // only goal is to parse into tokens - not necessarily validate tokens
    if (input.len == 0) return TokenError.InputTooSmall;
    if (input.len > std.math.maxInt(u8)) return TokenError.InputTooLarge;

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
                        ' ', ',', ')', 'a'...'z', 'A'...'Z' => break :inner,
                        else => {
                            if (@import("builtin").mode == .debug) //
                                print("Failed On: {s}\n", .{input[start .. i + 1]});
                            return TokenError.InvalidInput;
                        },
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
                        '(', ')', ',', ' ' => break :inner,
                        else => {
                            if (@import("builtin").mode == .debug) //
                                print("Failed On: {s}\n", .{input[start .. i + 1]});
                            return TokenError.InvalidInput;
                        },
                    }
                }
                const end = i;
                // identify tag
                const word = input[start..end];
                // print("Word: {s}\n", .{word});
                var tag: Tag = undefined;
                if (word.len == 1) { // 1 letter combo
                    // "u", "h", "q", "l", "r",
                    tag = switch (input[start]) {
                        'u' => .undo,
                        'h' => .help,
                        'q' => .quit,
                        'l' => .dir,
                        'r' => .dir,
                        else => {
                            if (@import("builtin").mode == .debug) //
                                print("Failed On: {s}\n", .{input[start .. start + 1]});
                            return TokenError.InvalidInput;
                        },
                    };
                } else if (word.len == 2) { // two letter combo
                    const kws = [_][]const u8{ "ul", "ur", "dl", "dr" };
                    var match: bool = false;
                    for (kws) |kw| {
                        if (eql(u8, kw, word)) {
                            tag = .dir;
                            match = true;
                        }
                    }
                    if (!match) {
                        if (@import("builtin").mode == .debug) //
                            print("Failed On: {s}\n", .{word});
                        return TokenError.InvalidInput;
                    }
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
                    if (!match) {
                        if (@import("builtin").mode == .debug) //
                            print("Failed On: {s}\n", .{word});
                        return TokenError.InvalidInput;
                    }
                }
                try tokens.append(allo, .{ .start = start, .end = end, .tag = tag });
            },
            '?' => {
                try tokens.append(allo, .{ .start = 0, .end = 1, .tag = .help });
            },
            ' ', ',', '(', ')' => continue,
            else => {
                if (@import("builtin").mode == .debug) //
                    print("Failed On: {s}\n", .{input[i .. i + 1]});
                return TokenError.InvalidInput;
            },
        }
    }
    return tokens;
}

test "Successful Tokenizer" {
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
        .{ .input = "ur ?)(, dr", .tags = &.{ .dir, .help, .dir } },
        .{ .input = "ul q r", .tags = &.{ .dir, .quit, .dir } },
        .{ .input = "ul)(, q r", .tags = &.{ .dir, .quit, .dir } },
        .{ .input = "quit q ?", .tags = &.{ .quit, .quit, .help } },
        // show that whitespaces and '(' ')' and ',' don't matter
        .{ .input = "(5, 6) r", .tags = &.{ .num, .num, .dir } },
        .{ .input = "r (5, 6)", .tags = &.{ .dir, .num, .num } },
        .{ .input = "r (5, 6)", .tags = &.{ .dir, .num, .num } },
        .{ .input = "r, (5, 6)", .tags = &.{ .dir, .num, .num } },
        .{ .input = "r (5) 6)", .tags = &.{ .dir, .num, .num } },
        .{ .input = "r                 (5) ()())() 6)", .tags = &.{ .dir, .num, .num } },
        .{ .input = "r (5) 6)", .tags = &.{ .dir, .num, .num } },
    };
    // loop
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
}

test "Failing Tokenizer" {
    const allo = std.testing.allocator;
    // Expect these to fail
    // show that there is an input size limit
    const Instruction = struct { input: []const u8, error_tag: TokenError };
    const instructions = [_]Instruction{
        // show order does not matter at this point
        .{ .input = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", .error_tag = TokenError.InputTooLarge },
        .{ .input = "", .error_tag = TokenError.InputTooSmall },
        .{ .input = "39%2", .error_tag = TokenError.InvalidInput },
        .{ .input = "39!2", .error_tag = TokenError.InvalidInput },
        .{ .input = "39<2", .error_tag = TokenError.InvalidInput },
    };
    // loop
    for (instructions) |ins| {
        try std.testing.expectError(ins.error_tag, tokenize(allo, ins.input));
    }
}

fn validateTokens(tokens: *const std.ArrayList(Token)) !bool {
    var is_valid: bool = false;
    switch (tokens.len) {
        0 => is_valid = true,
        1 => {
            switch (tokens.items[0].tag) {
                .undo, .help, .reset, .redo, .quit => is_valid = true,
                .num, .dir => return false,
            }
        },
        2 => {
            for (tokens.items) |token| {
                switch (token.tag) {
                    .undo, .help, .reset, .redo, .quit => is_valid = true,
                    .num, .dir => return false,
                }
            }
        },
        3 => {
            for (tokens.items) |token| {
                var n_dirs: u8 = 0;
                var n_nums: u8 = 0;
                switch (token.tag) {
                    .num => n_nums += 1,
                    .dir => n_dirs += 1,
                    else => return false,
                }
                is_valid = (n_dirs == 1) and (n_nums == 2);
            }
        },
        4 => {
            for (tokens.items) |token| {
                switch (token.tag) {
                    .num => continue,
                    else => return false,
                }
            }
        },
        else => return false,
    }
    return is_valid;
}

test "Validate Tokens" {}
