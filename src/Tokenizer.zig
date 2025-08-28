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
    const input_strings = [_][]const u8{ "redo", "r", "z", "undo", "u", "q", "reset", "r", "t" };
    const command_strings = [_][]const u8{ "redo", "redo", "redo", "undo", "undo", "undo", "reset", "reset", "reset" };
    const exp_matches = [_]bool{ true, true, false, true, true, false, true, true, false };
    for (command_strings, input_strings, exp_matches) |command, input, exp_match| {
        const got_match = isMatch(input, command);
        try std.testing.expectEqual(exp_match, got_match);
    }
}

// const Token = enum {
//     redo,
//     undo,
//     reset,
//     help,
//     identifier = struct {},
// };
//
// pub fn tokenize(allo: Allocator, input: []const u8) !std.ArrayList(Token) {
//     var tokens: std.ArrayList(Token) = try .initCapacity(allo, 5);
//
//     var i: usize = 0;
//     while (i < input.len) : (i += 1) {
//         switch (input[i]) {
//             ' ' => continue,
//             '0'...'9' => {
//                 const start: usize = 0;
//                 const end: usize = loop: while (i < input.len) : (i += 1) {
//                     switch (input[i]) {
//                         '0'...'9' => continue,
//                         else => break :loop i,
//                     }
//                 };
//                 const num = try std.fmt.parseInt(T, input[start..end], 10);
//                 try tokens.append();
//             },
//         }
//     }
//
//     return tokens;
// }
//
// test "Tokenize" {
//     const allo = std.testing.allocator;
//
//     const tokens = try tokenize(allo, input);
//     tokens.deinit(allo);
// }
