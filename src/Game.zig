const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

// TODO:
// need to add start + num = changes start posiiton so long as board is at the start
// ability to load and unload a game - should be automatic

// GamerErrors:
// print out the error ->continue to next line

// helpers
const triNum = @import("Helpers.zig").triNum;
const numMoves = @import("Helpers.zig").numMoves;
const idxFromPos = @import("Helpers.zig").idxFromPos;
const posFromIdx = @import("Helpers.zig").posFromIdx;
const flipFromIdx = @import("Helpers.zig").flipFromIdx;
const Direction = @import("Helpers.zig").Direction;
const Position = @import("Helpers.zig").Position;
const T = @import("Helpers.zig").T;

// board
const createBoard = @import("Board.zig").createBoard;
const N_ROWS: T = 5;
const N_INDICES: T = triNum(N_ROWS);
const Board: type = createBoard(N_ROWS) catch unreachable;

// Game
const MAX_BUFFER_LEN: u16 = 255; // should match input to lexer

// Parser
const Parser = @import("Parser.zig").Parser;

pub fn manual(allo: Allocator) !void {
    // init board
    var board: Board = try .init(0);
    // print greetings
    greetings();
    // ending check
    var is_quit: bool = false;
    // handle input output
    var buf = [_]u8{' '} ** MAX_BUFFER_LEN;
    var in = std.fs.File.stdin().reader(&buf);
    var out = std.fs.File.stdout();
    // loop
    while (!is_quit) {
        if (board.isGameOver()) {
            is_quit = true;
            continue;
        }
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
            1 => {
                switch (parsed_tokens.items[0]) {
                    .empty => continue,
                    .auto => {
                        _ = try board.dfs(allo);
                    },
                    .redo => board.redo(.{}),
                    .reset => board.reset(),
                    .quit => {
                        is_quit = true;
                        continue;
                    },
                    .undo => board.undo(.{}),
                    .moves => try board.printMoves(allo),
                    else => unreachable,
                }
            },
            2 => {
                // start num
                // redo/undo num
                // dir num
                // num dir
                const pt0 = parsed_tokens.items[0];
                const pt1 = parsed_tokens.items[1];
                switch (pt0) {
                    .start => {
                        const num = switch (pt1) {
                            .num => |n| n,
                            else => return error.StartTakesTwoNums,
                        };
                        try board.changeStart(.{ .idx = num });
                    },
                    .undo => {
                        const num = switch (pt1) {
                            .num => |n| n,
                            else => return error.UndoTakesANum,
                        };
                        board.undo(.{ .n = num });
                    },
                    .redo => board.redo(.{ .n = pt1.num }),
                    .num => |n| {
                        const d = pt1.dir;
                        board.chooseMove(.{ .idx = n }, d);
                    },
                    .dir => |d| {
                        const n = pt1.num;
                        board.chooseMove(.{ .idx = n }, d);
                    },
                    else => unreachable,
                }
            },
            3 => {
                // start num num
                // num num dir
                // dir num num
                const pt0 = parsed_tokens.items[0];
                const pt1 = parsed_tokens.items[1];
                const pt2 = parsed_tokens.items[2];

                switch (pt0) {
                    .dir => |d| {
                        const dir = d;
                        const num1 = switch (pt1) {
                            .num => |n| n,
                            else => return error.InvalidToken,
                        };
                        const num2 = switch (pt2) {
                            .num => |n| n,
                            else => return error.InvalidToken,
                        };
                        const pos: Position = .{ .row = num1, .col = num2 };
                        board.chooseMove(.{ .pos = pos }, dir);
                    },
                    .num => |num1| {
                        const num2 = switch (pt1) {
                            .num => |n2| n2,
                            else => return error.InvalidToken,
                        };
                        const dir = switch (pt2) {
                            .dir => |d| d,
                            else => unreachable,
                        };
                        const pos: Position = .{ .row = num1, .col = num2 };
                        board.chooseMove(.{ .pos = pos }, dir);
                    },
                    .start => {
                        const num1 = switch (pt1) {
                            .num => |n1| n1,
                            else => return error.InvalidToken,
                        };
                        const num2 = switch (pt2) {
                            .num => |n2| n2,
                            else => return error.InvalidToken,
                        };
                        const pos: Position = .{ .row = num1, .col = num2 };
                        try board.changeStart(.{ .pos = pos });
                    },
                    else => unreachable,
                }
            },
            // 4 => {
            //     // num num num num
            //     var nums: [4]u16 = undefined;
            //     for (parsed_tokens.items, 0..) |pt, i| {
            //         switch (pt) {
            //             .num => |n| nums[i] = n,
            //             else => unreachable,
            //         }
            //     }
            //     const pos1: Position = .{ .row = nums[0], .col = nums[1] };
            //     const pos2: Position = .{ .row = nums[2], .col = nums[3] };
            //     const dir = pos1.dir(&pos2);
            //     board.chooseMove(.{ .pos = pos1 }, dir);
            // },
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

    const board: Board = try .init(0);
    // try dfs(allo, try .init(0));
    try board.dfsAll(allo);
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

test "Game" {
    // Goal = test all inputs to game.zig
}
