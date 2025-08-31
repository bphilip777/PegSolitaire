const std = @import("std");
const print = std.debug.print;

const Direction = @import("Helpers.zig").Direction;

pub const N_TOKENS: comptime_int = 4;

const Tag = enum { // 2 bytes
    null, // uninit
    empty, // empty input
    num, // number
    alpha, // word
    help, // ? symbol
};

pub const Token = struct {
    start: u8,
    end: u8,
    tag: Tag,
};

pub const LexerError = error{
    // InputTooSmall,
    InputTooLarge,
    TooManyTokens,
    InvalidCharacter,
};

pub fn Lexer(input: []const u8, tokens: *[N_TOKENS]Token) !void {
    if (input.len == 0) {
        tokens[0] = .{
            .start = 0,
            .end = 0,
            .tag = .null,
        };
        return;
    }
    if (input.len > std.math.maxInt(u8)) return LexerError.InputTooLarge;

    resetTokens(tokens);

    var token_position: u8 = 0;
    var i: u8 = 0;
    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            'a'...'z', 'A'...'Z' => {
                if (token_position == tokens.len) return LexerError.TooManyTokens;
                const start: u8 = i;
                while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        'a'...'z', 'A'...'Z' => continue,
                        else => break,
                    }
                }
                const end = i;
                i -= 1;
                tokens[token_position] = .{ .start = start, .end = end, .tag = .alpha };
            },
            '0'...'9' => {
                if (token_position == tokens.len) return LexerError.TooManyTokens;
                const start: u8 = i;
                while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        '0'...'9' => continue,
                        else => break,
                    }
                }
                const end = i;
                i -= 1;
                tokens[token_position] = .{ .start = start, .end = end, .tag = .num };
            },
            '?' => |ch| {
                if (token_position == tokens.len) return LexerError.TooManyTokens;
                const tag: Tag = switch (ch) {
                    '?' => .help,
                    else => unreachable,
                };
                tokens[token_position] = .{ .start = i, .end = i + 1, .tag = tag };
            },
            ' ', '\r', '\n' => continue,
            else => {
                printError(input, i);
                return LexerError.InvalidCharacter;
            },
        }
        token_position += 1;
    }
}

fn printError(input: []const u8, i: u8) void {
    print("Failed On: {s}\nAt {}: {c}\n", .{ input, i, input[i] });
}

test "Positiive Lexer Tests" {
    const Instructions = struct { input: []const u8, tags: []const Tag };
    const instructions = [_]Instructions{
        .{ .input = "hello goodbye", .tags = &.{ .alpha, .alpha } },
        .{ .input = "12 45", .tags = &.{ .num, .num } },
        .{ .input = "redo undo quit", .tags = &.{ .alpha, .alpha, .alpha } },
        .{ .input = "0 dr", .tags = &.{ .num, .alpha } },
        .{ .input = "dr 0", .tags = &.{ .alpha, .num } },
    };

    for (instructions) |ins| {
        // print("\nInput: {s}\n", .{ins.input});

        var tokens = [_]Token{.{
            .start = 0,
            .end = 0,
            .tag = .null,
        }} ** N_TOKENS;
        try Lexer(ins.input, &tokens);

        const len = ins.tags.len;
        for (0..len) |i| {
            const tag1 = ins.tags[i];
            const tag2 = tokens[i].tag;
            try std.testing.expectEqual(tag1, tag2);
        }
    }
}

fn resetTokens(tokens: []Token) void {
    for (0..tokens.len) |i| {
        tokens[i].start = 0;
        tokens[i].end = 0;
        tokens[i].tag = .null;
    }
}

test "Negative Lexer Tests" {
    const Instructions = struct { input: []const u8, token_error: LexerError };
    const instructions = [_]Instructions{
        // .{ .input = "", .token_error = LexerError.InputTooSmall },
        .{ .input = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", .token_error = LexerError.InputTooLarge },
        .{ .input = "h h h h h h h h h h h h h h", .token_error = LexerError.TooManyTokens },
        .{ .input = "(hello, goodbye)()()()", .token_error = LexerError.InvalidCharacter },
        .{ .input = "%$!\\", .token_error = LexerError.InvalidCharacter },
    };
    for (instructions) |ins| {
        var tokens = [_]Token{.{ .start = 0, .end = 0, .tag = .null }} ** N_TOKENS;
        try std.testing.expectError(ins.token_error, Lexer(ins.input, &tokens));
    }
}

pub fn numTokens(tokens: *const [N_TOKENS]Token) u8 {
    var n_tokens: u8 = 0;
    for (tokens) |token| {
        n_tokens += @intFromBool(token.tag != .null);
    }
    return n_tokens;
}

test "Num Tokens" {
    const Instructions = struct { input: []const u8, tags: []const Tag };
    const instructions = [_]Instructions{
        .{ .input = "hello goodbye", .tags = &.{ .alpha, .alpha } },
        .{ .input = "12 45", .tags = &.{ .num, .num } },
        .{ .input = "redo undo quit", .tags = &.{ .alpha, .alpha, .alpha } },
    };

    for (instructions) |ins| {
        var tokens = [_]Token{.{
            .start = 0,
            .end = 0,
            .tag = .null,
        }} ** N_TOKENS;
        try Lexer(ins.input, &tokens);

        const num_tokens = numTokens(&tokens);
        try std.testing.expectEqual(num_tokens, ins.tags.len);
    }
}
