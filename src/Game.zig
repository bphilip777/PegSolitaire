const std = @import("std");
const Allocator = std.mem.Allocator;
const Game = @This();

allo: Allocator,

pub fn init() Game {
    return Game{};
}

pub fn deinit() void {}
