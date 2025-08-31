const std = @import("std");
const Allocator = std.mem.Allocator;
const eql = std.mem.eql;
const print = std.debug.print;

const Lexer = @import("Lexer.zig").Lexer;
const Token = @import("Lexer.zig").Token;
const N_TOKENS = @import("Lexer.zig").N_TOKENS;
const numTokens = @import("Lexer.zig").numTokens;
const LexerError = @import("Lexer.zig").LexerError;

const Direction = @import("Helpers.zig").Direction;
const T = @import("Helpers.zig").T;

// TODO: Handle inputs correctly

// Tag = List Of Commands
// Extends direction from helpers
const Tag = union(enum) {
    empty,
    start,
    auto,
    help,
    redo,
    undo,
    reset,
    quit,
    moves,
    num: T,
    dir: Direction,
};

const ParserError = error{
    InvalidInput,
    InvalidParse,
};

pub fn Parser(
    allo: Allocator,
    input: []const u8,
) (Allocator.Error || LexerError || ParserError || std.fmt.ParseIntError)!std.ArrayList(Tag) {
    var arr: std.ArrayList(Tag) = try .initCapacity(allo, 10);
    errdefer arr.deinit(allo);

    var tokens = [_]Token{.{ .start = 0, .end = 0, .tag = .null }} ** N_TOKENS;
    try Lexer(input, &tokens);

    const n_tokens: u8 = numTokens(&tokens);
    switch (n_tokens) {
        0 => arr.appendAssumeCapacity(.empty),
        1 => {
            const token = tokens[0];
            switch (token.tag) {
                .help => arr.appendAssumeCapacity(.help),
                .alpha => {
                    const start = token.start;
                    const end = token.end;
                    const n_chars = end - start;
                    switch (n_chars) {
                        0 => unreachable,
                        1 => switch (input[start]) {
                            'a' => arr.appendAssumeCapacity(.auto),
                            'r' => arr.appendAssumeCapacity(.redo),
                            'R' => arr.appendAssumeCapacity(.reset),
                            'q', 'Q' => arr.appendAssumeCapacity(.quit),
                            'u', 'U' => arr.appendAssumeCapacity(.undo),
                            'm', 'M' => arr.appendAssumeCapacity(.moves),
                            else => return ParserError.InvalidInput,
                        },
                        4 => {
                            const word = input[start..end];
                            const tags = [_]Tag{ .auto, .redo, .undo, .quit };
                            for (tags) |tag| {
                                if (eql(u8, word, @tagName(tag))) //
                                    arr.appendAssumeCapacity(tag);
                            }
                            return ParserError.InvalidInput;
                        },
                        5 => {
                            const word = input[start..end];
                            const tags = [_]Tag{ .moves, .reset, .start };
                            for (tags) |tag| {
                                if (eql(u8, word, @tagName(tag))) //
                                    arr.appendAssumeCapacity(tag);
                            }
                            return ParserError.InvalidInput;
                        },
                        else => return ParserError.InvalidInput,
                    }
                },
                else => return ParserError.InvalidInput,
            }
        },
        2 => {
            // start num
            // redo/undo num
            // dir num
            // num dir
            const t0 = tokens[0];
            switch (t0.tag) {
                .alpha => {
                    const t1 = tokens[1];
                    const seg = input[t0.start..t0.end];
                    const dir = Direction.parse(seg);
                    var match: bool = false;
                    if (dir != .None) {
                        arr.appendAssumeCapacity(.{ .dir = dir });
                        match = true;
                    } else {
                        const tags = [_]Tag{ .undo, .redo, .start };
                        for (tags) |tag| {
                            if (eql(u8, seg, @tagName(tag))) {
                                match = true;
                                arr.appendAssumeCapacity(tag);
                                break;
                            }
                        }
                    }
                    if (!match) return ParserError.InvalidInput;
                    const num = try std.fmt.parseInt(T, input[t1.start..t1.end], 10);
                    arr.appendAssumeCapacity(.{ .num = num });
                },
                .num => {
                    const num = try std.fmt.parseInt(T, input[t0.start..t0.end], 10);
                    const t1 = tokens[1];
                    const dir = Direction.parse(input[t1.start..t1.end]);
                    switch (dir) {
                        .None => return ParserError.InvalidInput,
                        else => {
                            arr.appendAssumeCapacity(.{ .num = num });
                            arr.appendAssumeCapacity(.{ .dir = dir });
                        }
                    }
                },
                else => return ParserError.InvalidInput,
            }
        },
        3 => {
            // num num dir
            // dir num num
            const t0 = tokens[0];
            const t1 = tokens[1];
            const t2 = tokens[2];
            var num1: T = undefined;
            var num2: T = undefined;
            var dir: Direction = undefined;
            switch (t0.tag) {
                .num => {
                    num1 = try std.fmt.parseInt(T, input[t0.start..t0.end], 10);
                    switch (t1.tag) {
                        .num => {
                            num2 = try std.fmt.parseInt(T, input[t1.start..t1.end], 10);
                            switch (t2.tag) {
                                .alpha => {
                                    dir = Direction.parse(input[t2.start..t2.end]);
                                    if (dir == .None) return ParserError.InvalidInput;
                                },
                                else => return ParserError.InvalidInput,
                            }
                        },
                        else => return ParserError.InvalidInput,
                    }
                },
                .alpha => {
                    dir = Direction.parse(input[t0.start..t0.end]);
                    if (dir == .None) return ParserError.InvalidInput;
                    switch (t1.tag) {
                        .num => {
                            num1 = try std.fmt.parseInt(T, input[t1.start..t1.end], 10);
                            switch (t2.tag) {
                                .num => {
                                    num2 = try std.fmt.parseInt(T, input[t2.start..t2.end], 10);
                                },
                                else => return ParserError.InvalidInput,
                            }
                        },
                        else => return ParserError.InvalidInput,
                    }
                },
                else => {
                    return ParserError.InvalidInput;
                },
            }
            arr.appendAssumeCapacity(.{ .num = num1 });
            arr.appendAssumeCapacity(.{ .num = num2 });
            arr.appendAssumeCapacity(.{ .dir = dir });
        },
        4 => {
            // num num num num
            for (tokens) |token| {
                if (token.tag != .num) return ParserError.InvalidInput;
                arr.appendAssumeCapacity(.{ .num = try std.fmt.parseInt(T, input[token.start..token.end], 10) });
            }
        },
        else => unreachable,
    }

    return arr;
}

test "Positive Parser" {
    const allo = std.testing.allocator;
    const Instruction = struct { input: []const u8, tags: []const Tag };
    const instructions = [_]Instruction{
        // none
        .{ .input = "", .tags = &.{.empty} },
        // single
        .{ .input = "r", .tags = &.{.redo} },
        .{ .input = "R", .tags = &.{.reset} },
        .{ .input = "q", .tags = &.{.quit} },
        .{ .input = "Q", .tags = &.{.quit} },
        .{ .input = "u", .tags = &.{.undo} },
        .{ .input = "U", .tags = &.{.undo} },
        .{ .input = "m", .tags = &.{.moves} },
        .{ .input = "M", .tags = &.{.moves} },
        // double
        .{ .input = "redo 5", .tags = &.{ .redo, .{ .num = 5 } } }, // fails
        .{ .input = "undo 7", .tags = &.{ .undo, .{ .num = 7 } } }, // fails
        .{ .input = "19 r", .tags = &.{ .{ .num = 19 }, .{ .dir = .Right } } },
        .{ .input = "ur 4", .tags = &.{ .{ .dir = .UpRight }, .{ .num = 4 } } }, // if i want redo - i can't accept this?
        // triple
        .{ .input = "10 7 r", .tags = &.{ .{ .num = 10 }, .{ .num = 7 }, .{ .dir = .Right } } },
        .{ .input = "r 7 10", .tags = &.{ .{ .num = 7 }, .{ .num = 10 }, .{ .dir = .Right } } },
        .{ .input = "left 0 1", .tags = &.{ .{ .num = 0 }, .{ .num = 1 }, .{ .dir = .Left } } },
        .{ .input = "upleft 1 1", .tags = &.{ .{ .num = 1 }, .{ .num = 1 }, .{ .dir = .UpLeft } } },
        .{ .input = "UR 1 1", .tags = &.{ .{ .num = 1 }, .{ .num = 1 }, .{ .dir = .UpRight } } },
        .{ .input = "ur 1 1", .tags = &.{ .{ .num = 1 }, .{ .num = 1 }, .{ .dir = .UpRight } } },
        .{ .input = "uR 1 1", .tags = &.{ .{ .num = 1 }, .{ .num = 1 }, .{ .dir = .UpRight } } },
        .{ .input = "Ur 1 1", .tags = &.{ .{ .num = 1 }, .{ .num = 1 }, .{ .dir = .UpRight } } },
        // quadruple
        .{ .input = "1 1 1 1", .tags = &.{ .{ .num = 1 }, .{ .num = 1 }, .{ .num = 1 }, .{ .num = 1 } } },
    };

    for (instructions) |ins| {
        var parsed_tokens = try Parser(allo, ins.input);
        defer parsed_tokens.deinit(allo);

        try std.testing.expectEqual(ins.tags.len, parsed_tokens.items.len);
        for (parsed_tokens.items, ins.tags) |pt, tag| {
            try std.testing.expectEqual(tag, pt);
        }
    }
}
