const std = @import("std");
const Allocator = std.mem.Allocator;
const Game = @This();

// Will contain auto and manual code

allo: Allocator,

pub fn init() Game {
    return Game{};
}

pub fn deinit() void {}
