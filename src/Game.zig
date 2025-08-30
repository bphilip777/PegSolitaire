const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

// helpers
const triNum = @import("Helpers.zig").triNum;
const numMoves = @import("Helpers.zig").numMoves;
const idxFromPos = @import("Helpers.zig").idxFromPos;
const posFromIdx = @import("Helpers.zig").posFromIdx;
const flipFromIdx = @import("Helpers.zig").flipFromIdx;
const Direction = @import("Helpers.zig").Direction;
const T = @import("Helpers.zig").T;

// board
const createBoard = @import("Board.zig").createBoard;
const N_ROWS: T = 5; // 7 -> 86 -> 768
const N_INDICES: T = triNum(N_ROWS);
const Board: type = createBoard(N_ROWS) catch unreachable;

// Game
const MAX_BUFFER_LEN: u16 = 255; // should match input to lexer

// Parser
const Parser = @import("Parser.zig").Parser;

pub fn manual() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);

    var board: Board = try .init(0);
    greetings();

    var quit:bool = false;

    while (!quit) {
    if (board.isGameOver()) {
        is_quit = true;
        continue;
    }
    var buf = [_]u8{' '} ** MAX_BUFFER_LEN; // resets buffer every loop
    var in = std.fs.File.stdin().reader(&buf);
    var out = std.fs.File.stdout();

    // show board
    board.printBoard();
    // get input
    const len = try in.read(&buf); // EndOfStream, ReadFailed
    const input = buf[0..len];
    print("{}: {s}\n", .{ len, input });
    // parse input
    var parsed_tokens = try Parser(allo, input);
    defer parsed_tokens.deinit(allo);
    // print parsed input
    print("Parsed Tokens:\n", .{});
    for (parsed_tokens.items, 0..) |pt, i| {
        print("{}: {any}\n", .{ i, pt });
    }
    // call appropriate functions
    switch (parsed_tokens.items.len) {
        0 => {}, // continue,
        1 => {
            switch (parsed_tokens.items[0]) {
                .auto => dfs(),
                .redo => board.redo(),
                .reset => board.reset(),
                .quit => {
                    is_quit = true;
                    continue;
                },
                .undo => board.undo(),
                .moves => try board.printMoves(allo),
                else => unreachable,
            },
    },
        2 => {
            var n_
            if ()
    },
        3 => {},
        4 => {},
        5 => {},
        else => unreachable,
    }
    // output result
    try out.writeAll(input);
    }
}

pub fn auto() !void {
    // Auto-Solve Board
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allo = gpa.allocator();
    defer std.debug.assert(gpa.deinit() == .ok);


    // try dfsFirst(allo, try .init(0));
    try dfsAll(allo, try .init(0));
}

fn greetings() void {
    const strs = [_][]const u8{
        "Welcome To Peg Solitaire!!!",
        "Press ? for help menu",
    };
    for (strs) |str| print("{s}\n", .{str});
}

fn helpStatement() void {
    // if they choose help 3x -> show them auto
    const help_strs = [_][]const u8{
        "Choose Eiter:\n",
        "1. Index + Direction: 0 DownRight\n",
        "2. Index + Index: 0 2\n",
        "3. Position + Direction\n",
        "4. Position + Position: 0 0 1 1\n",
        "Choose a row and col and a direction to play\n",
    };
    for (help_strs) |help_str| print("{s}\n", .{help_str});
    const main_dirs = [_]Direction{ .Left, .UpLeft, .UpRight, .Right, .DownRight, .DownLeft };
    for (main_dirs, 0..main_dirs.len) |dir, i| {
        if (i < main_dirs.len - 1) {
            print("{s} ", .{@tagName(dir)});
        } else {
            print("{s}\n", .{@tagName(dir)});
        }
    }
}
