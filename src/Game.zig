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
const Position = @import("Helpers.zig").Position;
const T = @import("Helpers.zig").T;

// Parser
const Parser = @import("Parser.zig").Parser;
const Tag = @import("Parser.zig").Tag;

// board
const createBoard = @import("Board.zig").createBoard;
const N_ROWS: T = 5;
const N_INDICES: T = triNum(N_ROWS);
const Board: type = createBoard(N_ROWS) catch unreachable;

// Game
const MAX_BUFFER_LEN: u16 = 255;

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
    loop: while (!is_quit) {
        if (board.isGameOver()) {
            is_quit = true;
            continue;
        }
        // show board
        board.printBoard();
        // get input
        const len = try in.read(&buf);
        const input = buf[0..len];
        print("{}: {s}\n", .{ len, input });
        // parse input
        var parsed_tokens = Parser(allo, input) catch |err| {
            print("Failed: {}\n", .{err});
            print("To exit: press q\n", .{});
            print("For help: press ?\n", .{});
            continue :loop;
        };
        defer parsed_tokens.deinit(allo);
        // print parsed input
        print("Parsed Tokens:\n", .{});
        for (parsed_tokens.items, 0..) |pt, i| {
            print("{}: {any}\n", .{ i, pt });
        }
        // call appropriate functions
        switch (parsed_tokens.items.len) {
            1 => {
                // Empty, auto, redo, reset, quit, undo, moves
                switch (parsed_tokens.items[0]) {
                    .empty => continue :loop,
                    .auto => {
                        board.dfs(allo) catch unreachable;
                    },
                    .redo => board.redo(.{}),
                    .reset => board.reset(),
                    .quit => is_quit = true,
                    .undo => board.undo(.{}),
                    .moves => board.printMoves(allo) catch unreachable,
                    else => {
                        print("Invalid Input\n", .{});
                        print("Valid Single Inputs:\n", .{});
                        const tags = [_]Tag{ .empty, .auto, .redo, .reset, .quit, .undo, .moves };
                        for (0..tags.len) |i| {
                            const tag_name = @tagName(tags[i]);
                            print("{c}\n", .{tag_name[0]});
                            // print("{}: {s}\n", .{ i, @tagName(tags[i]) });
                        }
                        print("\n", .{});
                        continue :loop;
                    },
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
                            else => {
                                print("start takes a num\nEx: start 1\n", .{});
                                continue :loop;
                            }
                        };
                        board.changeStart(.{ .idx = num }) catch |err| {
                            print("{}\n", .{err});
                            continue :loop;
                        };
                    },
                    .undo => {
                        const num = switch (pt1) {
                            .num => |n| n,
                            else => {
                                print("undo takes a num\nEx: undo 1\n", .{});
                                continue :loop;
                            }
                        };
                        board.undo(.{ .n = num });
                    },
                    .redo => {
                        const num = switch (pt1) {
                            .num => |n| n,
                            else => {
                                print("redo takes a num\nEx: redo 1\n", .{});
                                continue :loop;
                            }
                        };
                        board.redo(.{ .n = num });
                    },
                    .num => |num| {
                        const dir = switch (pt1) {
                            .dir => |d| d,
                            else => {
                                print("Choosing a move takes num and dir\nEx: 0 downright\n", .{});
                                continue :loop;
                            },
                        };
                        board.chooseMove(.{ .idx = num }, dir);
                    },
                    .dir => |dir| {
                        const num = switch (pt1) {
                            .num => |n| n,
                            else => {
                                print("Choosing a move takes dir and num\nEx: downright 0\n", .{});
                                continue :loop;
                            },
                        };
                        board.chooseMove(.{ .idx = num }, dir);
                    },
                    else => {
                        print("Invalid Input\n", .{});
                        print("Valid Double Inputs:\n", .{});
                        const tags = [_]Tag{ .start, .undo, .redo, .{ .num = 0 }, .{ .dir = .None } };
                        for (0..tags.len) |i| {
                            const tag = tags[i];
                            print("{}: {s}\n", .{ i, @tagName(tag) });
                        }
                        print("\n", .{});
                        continue :loop;
                    },
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
                    .start => {
                        const error_str = "start takes num and num\nEx: start 2 2\n";
                        const num1 = switch (pt1) {
                            .num => |n1| n1,
                            else => {
                                print("{s}", .{error_str});
                                continue :loop;
                            },
                        };
                        const num2 = switch (pt2) {
                            .num => |n2| n2,
                            else => {
                                print("{s}", .{error_str});
                                continue :loop;
                            },
                        };
                        const pos: Position = .{ .row = num1, .col = num2 };
                        board.changeStart(.{ .pos = pos }) catch |err| {
                            print("{}\n", .{err});
                            continue :loop;
                        };
                    },
                    .dir => |dir| {
                        const error_str = "Choosing a move takes dir num num\nEx: dr 0 0\n";
                        const num1 = switch (pt1) {
                            .num => |n| n,
                            else => {
                                print("{s}", .{error_str});
                                continue :loop;
                            },
                        };
                        const num2 = switch (pt2) {
                            .num => |n| n,
                            else => {
                                print("{s}", .{error_str});
                                continue :loop;
                            },
                        };
                        const pos: Position = .{ .row = num1, .col = num2 };
                        board.chooseMove(.{ .pos = pos }, dir);
                    },
                    .num => |num1| {
                        const error_str = "Choosing a move takes num num dir\nEx: 0 0 dr\n";
                        const num2 = switch (pt1) {
                            .num => |n2| n2,
                            else => {
                                print("{s}", .{error_str});
                                continue :loop;
                            },
                        };
                        const dir = switch (pt2) {
                            .dir => |d| d,
                            else => {
                                print("{s}", .{error_str});
                                continue :loop;
                            },
                        };
                        const pos: Position = .{ .row = num1, .col = num2 };
                        board.chooseMove(.{ .pos = pos }, dir);
                    },
                    else => {
                        print("Only 3 commands take 3 inputs:\n1. Start: num num\n2. Dir: num num\n3. Num: num dir\n", .{});
                        continue :loop;
                    },
                }
            },
            4 => {
                // num num num num
                var nums: [4]u16 = undefined;
                for (parsed_tokens.items, 0..) |pt, i| {
                    switch (pt) {
                        .num => |n| nums[i] = n,
                        else => {
                            print("Only 1 commands take 4 inputs:\nPosition Position\nEx 0 0 2 0\n", .{});
                            continue :loop;
                        },
                    }
                }
                const pos1: Position = .{ .row = nums[0], .col = nums[1] };
                const pos2: Position = .{ .row = nums[2], .col = nums[3] };
                const dir = pos1.dir(&pos2) catch |err| {
                    print("{}\n", .{err});
                    print("Choose Two Valid Positions\n", .{});
                    continue :loop;
                };
                board.chooseMove(.{ .pos = pos1 }, dir);
            },
            else => {
                print("Game not take more than 4 inputs\n", .{});
                // change below to a help page
                print("For help, enter ?\n", .{});
                continue;
            },
        }
        // output result
        try out.writeAll(input);
    }
}

pub fn auto(allo: Allocator) !void {
    const board: Board = try .init(0);
    // try board.dfs(allo);
    try board.dfsAll(allo);
}

fn greetings() void {
    const strs = [_][]const u8{
        "Welcome To Peg Solitaire!!!",
        "Press ? for help menu",
    };
    for (strs) |str| print("{s}\n", .{str});
}

fn help() void {
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
