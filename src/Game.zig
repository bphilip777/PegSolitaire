const std = @import("std");
const Allocator = std.mem.Allocator;

const createBoard = @import("helpers.zig");

const Board = createBoard(5) catch unreachable;

// Goal - handle manual + automatic here
