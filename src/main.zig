const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const createBoard = @import("Board.zig").createBoard;
const T = @import("helpers.zig").T;
const N_ROWS: T = 5;
const Board = createBoard(5);

// TODO:
// Play Game:
// - Manual:
//  - need an external library for argument parsing
//  - zig-cli
//  - sigargs ... whatever
//  - another option is to parse inputs into main from commandline - currently empty
// - Auto:

pub fn main() !void {
    // memory
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);
    // auto-solve board
    try dfs(allo, 0);
}

fn dfs(allo: Allocator, start: T) !void {
    _ = start;
    var arr: std.MultiArrayList(Board) = .init(){};
    defer arr.deinit(allo);
}

test "Run All Tests" {
    _ = @import("Board.zig");
}
