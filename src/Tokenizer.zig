const std = @import("std");
const print = std.debug.print;

const Tag = enum(u8) {
    alpha,
    help,
    num,
};

const Token = struct {
    start: u8,
    end: u8,
    tag: Tag,
};

const TokenError = error{};

pub fn lexer(input: []const u8, tokens: [4]Token) !void {
    std.debug.assert(input.len > 0 and input.len < std.math.maxInt(u8));
    var tok_pos: u8 = 0;
    var i: u8 = 0;
    while (i < input.len) : (i += 1) {
        switch (input[i]) {
            'a'...'z', 'A'...'Z' => {
                const start: u8 = i;
                i += 1;
                while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        'a'...'z', 'A'...'Z' => continue,
                        else => break,
                    }
                }
                const end = i;
                tokens[tok_pos] = .{ .start = start, .end = end, .tag = .alpha };
            },
            '0'...'9' => {
                const start: u8 = i;
                i += 1;
                while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        '0'...'9' => continue,
                        else => break,
                    }
                }
                const end = i;
                tokens[tok_pos] = .{ .start = start, .end = end, .tag = .num };
            },
            '?' => {
                const start: u8 = i;
                i += 1;
                while (i < input.len) : (i += 1) {
                    switch (input[i]) {
                        '?' => continue,
                        else => break,
                    }
                }
                const end = i;
                tokens[tok_pos] = .{ .start = start, .end = end, .tag = .help };
            },
            ' ' => continue,
            else => {
                print("Failed On {s}\nAt {}: {c}\n", .{ input, i, input[i] });
                return error.InvalidCharacter;
            },
        }
        tok_pos += 1;
    }
}

test "Lexer" {}
