const std = @import("std");
const print = std.debug.print;

const Tag = enum(u8) {
    alpha,
    help,
    num,
    open_paren,
    close_paren,
    comma,
};

const Token = struct {
    start: u8,
    end: u8,
    tag: Tag,
};

const TokenError = error{
    InputTooSmall,
    InputTooLarge,
    TooManyTokens,
    InvalidCharacter,
};

pub fn lexer(input: []const u8, tokens: *[8]Token) !void {
    if (input.len == 0) return TokenError.InputTooSmall;
    if (input.len > std.math.maxInt(u8)) return TokenError.InputTooLarge;

    var token_position: u8 = 0;
    var i: u8 = 0;
    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            'a'...'z', 'A'...'Z' => {
                if (token_position == tokens.len) return TokenError.TooManyTokens;
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
                if (token_position == tokens.len) return TokenError.TooManyTokens;
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
            '?', '(', ')', ',' => |ch| {
                if (token_position == tokens.len) return TokenError.TooManyTokens;
                const tag: Tag = switch (ch) {
                    '?' => .help,
                    '(' => .open_paren,
                    ')' => .close_paren,
                    ',' => .comma,
                    else => unreachable,
                };
                tokens[token_position] = .{ .start = i, .end = i + 1, .tag = tag };
            },
            ' ' => continue,
            else => {
                print("Failed On: {s}\nAt {}: {c}\n", .{ input, i, input[i] });
                return TokenError.InvalidCharacter;
            },
        }
        token_position += 1;
    }
}

test "Positiive Lexer Tests" {
    const Instructions = struct { input: []const u8, tags: []const Tag };
    const instructions = [_]Instructions{
        .{ .input = "(hello, goodbye)", .tags = &.{ .open_paren, .alpha, .comma, .alpha, .close_paren } },
        .{ .input = "12, 45", .tags = &.{ .num, .comma, .num } },
        .{ .input = "redo, undo, quit", .tags = &.{ .num, .comma, .num, .comma, .alpha } },
    };

    for (instructions) |ins| {
        print("\nInput: {s}\n", .{ins.input});

        var tokens: [8]Token = undefined;
        resetTokens(&tokens);
        try lexer(ins.input, &tokens);

        const len = ins.tags.len;
        for (0..len) |i| {
            const tag1 = ins.tags[i];
            const tag2 = tokens[i].tag;
            print("{s} - {s}\n", .{ @tagName(tag1), @tagName(tag2) });
        }
    }
}

fn resetTokens(tokens: []Token) void {
    for (0..tokens.len) |i| {
        tokens[i].start = undefined;
        tokens[i].end = undefined;
        tokens[i].tag = undefined;
    }
}

test "Negative Lexer Tests" {
    const Instructions = struct { input: []const u8, token_error: TokenError };
    const instructions = [_]Instructions{
        .{ .input = "", .token_error = TokenError.InputTooSmall },
        .{ .input = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", .token_error = TokenError.InputTooLarge },
        .{ .input = "(hello, goodbye)()()()", .token_error = TokenError.TooManyTokens },
        .{ .input = "%$!\\", .token_error = TokenError.InvalidCharacter },
    };
    for (instructions) |ins| {
        var tokens: [8]Token = undefined;
        try std.testing.expectError(ins.token_error, lexer(ins.input, &tokens));
    }
}
