const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

// Helpers
// Data
const T = @import("Helpers.zig").T;
const Input = @import("Helpers.zig").Input;
const Direction = @import("Helpers.zig").Direction;
const Directions = @import("Helpers.zig").Directions;
const Position = @import("Helpers.zig").Position;
const Rotation = @import("Helpers.zig").Rotation;
// Fns
const numChars = @import("Helpers.zig").numChars;
const numCharsFromIdx = @import("Helpers.zig").numCharsFromIdx;
const numMoves = @import("Helpers.zig").numMoves;
const invTriNum = @import("Helpers.zig").invTriNum;
const triNum = @import("Helpers.zig").triNum;
const posFromIdx = @import("Helpers.zig").posFromIdx;
const idxFromPos = @import("Helpers.zig").idxFromPos;
const formatMove = @import("Helpers.zig").formatMove;
const flipFromIdx = @import("Helpers.zig").flipFromIdx;

const MAX_ROWS: T = invTriNum(std.math.maxInt(T)) - 1;

const Move = struct {
    idx: T,
    dir: Direction,

    pub fn flip(move: *const Move) Move {
        return .{
            .idx = flipFromIdx(move.idx),
            .dir = move.dir.flip(),
        };
    }
};

const GameErrors = error{
    NRowsTooSmall,
    NRowsTooLarge,
    StartMustBeLTNumIndices,
    InvalidMove,
    InvalidPosition,
};

pub fn createBoard(comptime n_rows: T) !type {
    if (n_rows < 3) return GameErrors.NRowsTooSmall;
    if (n_rows > MAX_ROWS) return GameErrors.NRowsTooLarge;
    const n_indices = triNum(n_rows);

    return struct {
        board: std.bit_set.IntegerBitSet(n_indices) = .initFull(), // current board value
        moves: [n_indices]Directions = [_]Directions{.initEmpty()} ** n_indices, // list of possible moves
        chosen_idxs: [n_indices]T = [_]T{0} ** n_indices, // list of chosen idxs
        chosen_dirs: [n_indices]Direction = [_]Direction{.None} ** n_indices, // list of chosen moves

        pub fn init(start_idx: T) !@This() {
            // Validity Check
            if (start_idx >= n_indices) return GameErrors.StartMustBeLTNumIndices;
            // create self
            var self = @This(){};
            self.chosen_idxs[n_indices - 1] = start_idx;
            self.resetBoard();
            return self;
        }

        pub fn printBoard(self: *const @This()) void {
            const len = n_rows * 2 + 1;
            var buffer: [len]u8 = [_]u8{' '} ** len;
            var i: T = 0;

            for (0..n_rows + 1) |row| {
                const start = n_rows - row;
                for (0..row) |col| {
                    const idx = start + col * 2;
                    buffer[@intCast(idx)] = if (self.board.isSet(i)) '|' else '-';
                    buffer[idx + 1] = ' ';
                    i += 1;
                }
                var match: bool = true;
                buffer_loop: for (buffer) |ch| {
                    if (ch != ' ') {
                        match = false;
                        break :buffer_loop;
                    }
                }
                if (!match) print("{}: {s}\n", .{ row - 1, &buffer });
            }
            print("\n", .{});
        }

        fn computeAllMoves(self: *@This()) void {
            // loop through indices
            for (0..n_indices) |i| {
                const idx0: T = @truncate(i);
                const pos0 = posFromIdx(idx0);
                for ([_]Direction{
                    .Left,
                    .UpLeft,
                    .UpRight,
                    .Right,
                    .DownRight,
                    .DownLeft,
                }) |dir| {
                    // get positions
                    const pos1 = getRotation(pos0, dir, .full) orelse {
                        self.moves[i].remove(dir);
                        continue;
                    };
                    const pos2 = getRotation(pos1, dir, .full) orelse {
                        self.moves[i].remove(dir);
                        continue;
                    };
                    // convert to indices + validate
                    const idx1 = idxFromPos(pos1);
                    const idx2 = idxFromPos(pos2);
                    if (!self.isValidIdx(idx1) or !self.isValidIdx(idx2)) {
                        if (self.moves[i].contains(dir)) self.moves[i].remove(dir);
                        continue;
                    }
                    // check that move is possible
                    if (self.hasMove(&.{ idx0, idx1, idx2 })) {
                        self.moves[idx0].insert(dir);
                    } else {
                        self.moves[idx0].remove(dir);
                    }
                }
            }
        }

        fn computeOptimally(self: *@This(), idx: T, dir: Direction) void {
            // assumes idx0 is valid + dir is valid!
            // start form origin -> loop around it through rest of origins
            // for ring 2: get positions multiple ways
            //  Ring 0 (Origin):
            //     o o o -> 0 1 2
            //  Ring 1:
            //    x x x x      4 5 6 7
            //   x o o o x -> 3 o o o 8
            //    x x x x      2 1 0 9
            //  Ring 2:
            //    | | | | |        4 5 6 7 8
            //   | x x x x |        x x x x
            //  | x o o o x | -> 3 x o o o x 9
            //   | x x x x |        x x x x
            //    | | | | |        4 3 2 1 0

            // compute ring0 - should always exist
            const start0 = posFromIdx(idx);
            const start1 = getRotation(start0, dir, .full);
            const start2 = getRotation(start1, dir, .full);
            std.debug.assert(start1 != null and start2 != null);
            const ring0 = [_]Position{ start0, start1.?, start2.? };
            // loop through origins
            for (ring0) |pos0| {
                // if (origin) |pos0| { // otherwise skip missing origins - test this
                const idx0 = idxFromPos(pos0);
                // rotate about idx0
                inline for (comptime std.meta.fieldNames(Direction)) |field_name| {
                    // compute directions
                    const new_dir = @field(Direction, field_name);
                    switch (new_dir) {
                        .None => {},
                        else => {
                            const opp_dir = new_dir.opposite();
                            // compute positions
                            const pos1 = getRotation(pos0, new_dir, .full);
                            const pos2 = getRotation(pos1, new_dir, .full);
                            const pos3 = getRotation(pos0, new_dir, .one_eighty);
                            // move = along all positions
                            if (pos1 != null and pos2 != null) {
                                const idx1 = idxFromPos(pos1.?);
                                const idx2 = idxFromPos(pos2.?);
                                if (self.isValidIdx(idx1) and self.isValidIdx(idx2)) {
                                    // forwards
                                    if (self.hasMove(&.{ idx0, idx1, idx2 })) {
                                        self.moves[idx0].insert(new_dir);
                                    } else if (self.moves[idx0].contains(new_dir)) {
                                        self.moves[idx0].remove(new_dir);
                                    }
                                    // backwards
                                    if (self.hasMove(&.{ idx2, idx1, idx0 })) {
                                        self.moves[idx2].insert(opp_dir);
                                    } else if (self.moves[idx2].contains(opp_dir)) {
                                        self.moves[idx2].remove(opp_dir);
                                    }
                                }
                            }
                            if (pos1 != null and pos3 != null) {
                                const idx1 = idxFromPos(pos1.?);
                                const idx3 = idxFromPos(pos3.?);
                                if (self.isValidIdx(idx1) and self.isValidIdx(idx3)) {
                                    // centered
                                    if (self.hasMove(&.{ idx1, idx0, idx3 })) {
                                        self.moves[idx1].insert(opp_dir);
                                    } else if (self.moves[idx1].contains(opp_dir)) {
                                        self.moves[idx1].remove(opp_dir);
                                    }
                                }
                            }
                        }
                    }
                }
                // }
            }
        }

        fn hasMove(self: *const @This(), idxs: []const T) bool {
            std.debug.assert(idxs.len == 3);
            inline for (0..3) |i| {
                if (!self.isValidIdx(idxs[i])) return false;
            }
            return if (self.board.isSet(idxs[0])) // pos mave
                (self.board.isSet(idxs[1]) and !self.board.isSet(idxs[2])) //
            else // neg move
                (self.board.isSet(idxs[1]) and self.board.isSet(idxs[2]));
        }

        pub fn chooseMove(self: *@This(), input: Input, dir: Direction) void {
            switch (input) {
                .idx => |idx| self.chooseMoveIdx(idx, dir),
                .pos => |pos| self.chooseMovePos(pos, dir),
            }
        }

        pub fn chooseMoveIdx(self: *@This(), idx0: T, dir: Direction) void {
            // if idx is not valid return
            if (!self.isValidIdx(idx0)) {
                print("Idx: {} not valid\n", .{idx0});
                return;
            }
            // get positions
            const p0 = posFromIdx(idx0);
            const p1 = getRotation(p0, dir, .full) orelse {
                print(
                    "1. Pos: ({}, {}), Dir: {s}, Does Not Exist\n",
                    .{ p0.row, p0.col, @tagName(dir) },
                );
                return;
            };
            const p2 = getRotation(p1, dir, .full) orelse {
                print(
                    "2. Pos: ({}, {}), Dir: {s}, Does Not Exist\n",
                    .{ p1.row, p1.col, @tagName(dir) },
                );
                return;
            };
            // get idxs
            const idx1 = idxFromPos(p1);
            const idx2 = idxFromPos(p2);
            // check move -> apply move = update board
            if (self.board.isSet(idx0)) { // pos
                if (!self.moves[idx2].contains(dir.opposite())) {
                    print(
                        "3. Pos: ({}, {}), Dir: {s}, Does Not Exist",
                        .{ p2.row, p2.col, @tagName(dir) },
                    );
                    return;
                }
                // update
                self.chosen_idxs[self.board.count()] = idx2;
                self.chosen_dirs[self.board.count()] = dir.opposite();
                self.setPosMove([3]T{ idx0, idx1, idx2 });
            } else { // neg
                if (!self.moves[idx0].contains(dir)) {
                    print(
                        "4. Pos: ({}, {}), Dir: {s}, Does Not Exist\n",
                        .{ p0.row, p0.col, @tagName(dir) },
                    );
                    return;
                }
                // update
                self.chosen_idxs[self.board.count()] = idx0;
                self.chosen_dirs[self.board.count()] = dir;
                self.setNegMove([3]T{ idx0, idx1, idx2 });
            }
            // update moves - problem - chosen moves are not entirely updated - need to develop test
            // self.computeAllMoves();
            self.computeOptimally(idx0, dir);
        }

        pub fn chooseMovePos(self: *@This(), pos: Position, dir: Direction) void {
            const idx = idxFromPos(pos);
            if (!self.isValidIdx(idx)) return;
            self.chooseMoveIdx(idx, dir);
        }

        pub fn resetBoard(self: *@This()) void {
            // set board to all 1s
            // set start position to 0
            // set moves to empty
            for (0..n_indices) |i| self.board.set(i);
            self.board.unset(self.chosen_idxs[n_indices - 1]);
            self.computeAllMoves();
        }

        pub fn undoMove(self: *@This()) void {
            // assumes NOT auto mode
            // get idx
            const idx = self.board.count() + 1;
            // if idx == n_indices = @ start
            if (idx >= n_indices - 1) return;
            // get move idx + move direction
            const move_idx = self.chosen_idxs[idx];
            const move_dir = self.chosen_dirs[idx];
            std.debug.assert(move_dir != .None);
            // get positions
            const pos0 = posFromIdx(move_idx);
            const pos1 = getRotation(pos0, move_dir, .full).?;
            const pos2 = getRotation(pos1, move_dir, .full).?;
            // get idxs
            const idx1 = idxFromPos(pos1);
            const idx2 = idxFromPos(pos2);
            // reset board positions
            self.unsetNegMove([3]T{ move_idx, idx1, idx2 });
            // reset moves
            // self.computeAllMoves();
            self.computeOptimally(move_idx, move_dir);
        }

        pub fn redoMove(self: *@This()) void {
            // assumes NOT auto mode
            // get board idx
            const idx = self.board.count();
            if (idx >= self.board.capacity()) return;
            // grab chosen values
            const chosen_idx = self.chosen_idxs[idx];
            const chosen_dir = self.chosen_dirs[idx];
            // assert that it is not a none case
            std.debug.assert(chosen_dir != .None);
            // choose move
            self.chooseMove(.{ .idx = chosen_idx }, chosen_dir);
        }

        fn setNegMove(self: *@This(), idxs: [3]T) void {
            // asserts
            std.debug.assert(idxs.len == 3);
            std.debug.assert(!self.board.isSet(idxs[0]) or //
                self.board.isSet(idxs[1]) or //
                self.board.isSet(idxs[2]));
            // set neg mave
            self.board.set(idxs[0]);
            self.board.unset(idxs[1]);
            self.board.unset(idxs[2]);
        }

        fn setPosMove(self: *@This(), idxs: [3]T) void {
            // asserts
            std.debug.assert(idxs.len == 3);
            std.debug.assert(self.board.isSet(idxs[0]) or //
                self.board.isSet(idxs[1]) or //
                !self.board.isSet(idxs[2]));
            // set pos move
            self.board.unset(idxs[0]);
            self.board.unset(idxs[1]);
            self.board.set(idxs[2]);
        }

        fn unsetNegMove(self: *@This(), idxs: [3]T) void {
            // assert
            std.debug.assert(self.board.isSet(idxs[0]) or //
                !self.board.isSet(idxs[1]) or //
                !self.board.isSet(idxs[2]));
            // unset neg move
            self.board.unset(idxs[0]);
            self.board.set(idxs[1]);
            self.board.set(idxs[2]);
        }

        fn unsetPosMove(self: *@This(), idxs: [3]T) void {
            // assert
            std.debug.assert(!self.board.isSet(idxs[0]) or //
                !self.board.isSet(idxs[1]) or //
                self.board.isSet(idxs[2]));
            // unset pos move
            self.board.set(idxs[0]);
            self.board.set(idxs[1]);
            self.board.unset(idxs[2]);
        }

        fn isValidIdx(self: *const @This(), idx: T) bool {
            return idx < self.board.capacity();
        }

        fn getLeft(pos: Position) ?Position {
            if (pos.col == 0) return null;
            return Position{
                .row = pos.row,
                .col = pos.col - 1,
            };
        }

        fn getUpLeft(pos: Position) ?Position {
            if (pos.row == 0 or pos.col == 0) return null;
            return Position{
                .row = pos.row - 1,
                .col = pos.col - 1,
            };
        }

        fn getUpRight(pos: Position) ?Position {
            if (pos.row == 0 or pos.col >= pos.row) return null;
            return Position{
                .row = pos.row - 1,
                .col = pos.col,
            };
        }

        fn getRight(pos: Position) ?Position {
            if (pos.col >= pos.row) return null;
            return Position{
                .row = pos.row,
                .col = pos.col + 1,
            };
        }

        fn getDownRight(pos: Position) ?Position {
            if (pos.row >= n_rows or pos.col >= n_rows) return null;
            return Position{
                .row = pos.row + 1,
                .col = pos.col + 1,
            };
        }

        fn getDownLeft(pos: Position) ?Position {
            if (pos.row >= n_rows or pos.col > pos.row) return null;
            return Position{
                .row = pos.row + 1,
                .col = pos.col,
            };
        }

        pub fn getRotation(pos: ?Position, dir: Direction, rot: Rotation) ?Position {
            if (pos) |p| {
                switch (rot) {
                    .sixty => return switch (dir) {
                        .Left => getLeft(p),
                        .UpLeft => getUpRight(p),
                        .UpRight => getRight(p),
                        .Right => getDownRight(p),
                        .DownRight => getDownLeft(p),
                        .DownLeft => getLeft(p),
                        else => null,
                    },
                    .one_twenty => return switch (dir) {
                        .Left => getUpRight(p),
                        .UpLeft => getRight(p),
                        .UpRight => getDownRight(p),
                        .Right => getDownLeft(p),
                        .DownRight => getLeft(p),
                        .DownLeft => getUpLeft(p),
                        else => null,
                    },
                    .one_eighty => return switch (dir) {
                        .Left => getRight(p),
                        .UpLeft => getDownRight(p),
                        .UpRight => getDownLeft(p),
                        .Right => getLeft(p),
                        .DownRight => getUpLeft(p),
                        .DownLeft => getUpRight(p),
                        else => null,
                    },
                    .two_forty => return switch (dir) {
                        .Left => getDownRight(p),
                        .UpLeft => getDownLeft(p),
                        .UpRight => getLeft(p),
                        .Right => getUpLeft(p),
                        .DownRight => getUpRight(p),
                        .DownLeft => getRight(p),
                        else => null,
                    },
                    .three_hundo => return switch (dir) {
                        .Left => getDownLeft(p),
                        .UpLeft => getLeft(p),
                        .UpRight => getUpLeft(p),
                        .Right => getUpRight(p),
                        .DownRight => getRight(p),
                        .DownLeft => getDownRight(p),
                        else => null,
                    },
                    .full => return switch (dir) {
                        .Left => getLeft(p),
                        .UpLeft => getUpLeft(p),
                        .UpRight => getUpRight(p),
                        .Right => getRight(p),
                        .DownRight => getDownRight(p),
                        .DownLeft => getDownLeft(p),
                        else => null,
                    },
                }
            }
            return null;
        }

        pub fn isGameOver(self: *const @This()) bool {
            return self.isWon() or self.isLost();
        }

        pub fn isWon(self: *const @This()) bool {
            return self.board.count() == 1;
        }

        pub fn numMovesLeft(self: *const @This()) T {
            var n_moves: T = 0;
            for (0..self.board.capacity()) |i| n_moves += numMoves(self.moves[i]);
            return n_moves;
        }

        pub fn isLost(self: *const @This()) bool {
            return (self.numMovesLeft() == 0 and self.board.count() > 1);
        }

        pub fn reset(self: *@This()) void {
            // set board to all on
            // set start position off
            // undo all moves
            // recompute start moves

            // set board to all on
            for (0..self.board.capacity()) |i| self.board.set(i);
            // set start pposition off
            self.board.unset(self.start_idx);

            for (0..n_indices) |i| {
                // undo all moves
                self.moves[i] = .initEmpty();
                // reset chosen_moves
                self.chosen_idxs[i] = 0;
                self.chosen_dirs[i] = .initEmpty();
            }
            // recompute start moves
            self.computeAllMoves();
        }

        pub fn printMoves(self: *const @This(), allo: Allocator) !void {
            // pass in allocator
            const headers = [_][]const u8{ "Coords", "Moves" };
            // compute max chars per line
            var max_moves_char: T = 0;
            for (self.moves) |move| {
                max_moves_char = @max(max_moves_char, numChars(move));
            }
            max_moves_char = @max(headers[1].len, max_moves_char);
            const column_buffer = " | ";
            {
                // coords header
                const coords_extra = "(, ) ";
                const num_buffer = numCharsFromIdx(n_indices) + coords_extra.len;
                const coord_diff = num_buffer - headers[0].len;
                const diff = max_moves_char - headers[1].len;
                const empty_buffer = [_]u8{' '} ** 1024;
                const underline_buffer = [_]u8{'-'} ** 1024;
                // print table header
                print(
                    "{s}{s}{s}{s}{s}\n",
                    .{
                        headers[0],
                        empty_buffer[0..coord_diff],
                        column_buffer,
                        headers[1],
                        empty_buffer[0..diff],
                    },
                );
                const full_length = num_buffer + (column_buffer.len * 2) + max_moves_char;
                print("{s}\n", .{underline_buffer[0..full_length]});
            }
            // loop
            for (self.moves, 0..) |move, i| {
                // skip
                if (numMoves(move) == 0) continue;
                // get position
                const pos = posFromIdx(@truncate(i));
                // coords
                const coords_str = try std.fmt.allocPrint(
                    allo,
                    "({}, {}) ",
                    .{ pos.row, pos.col },
                );
                defer allo.free(coords_str);
                // format moves
                const moves_str = try formatMove(allo, move, max_moves_char);
                defer allo.free(moves_str);
                // print line
                print("{s}{s}{s}\n", .{ coords_str, column_buffer, moves_str });
            }
        }

        pub fn hasRemainingMoves(self: *const @This()) bool {
            for (self.moves) |move| {
                if (!move.eql(move.xorWith(move))) return true;
            } else return false;
        }

        pub fn getMove(self: *const @This()) Move {
            for (self.moves, 0..self.moves.len) |move, i| {
                if (move.contains(.None)) continue;
                for ([_]Direction{
                    .Left,
                    .UpLeft,
                    .UpRight,
                    .Right,
                    .DownRight,
                    .DownLeft,
                }) |dir| {
                    if (move.contains(dir)) return .{
                        .idx = @truncate(i),
                        .dir = dir,
                    };
                }
            } else return .{ .idx = 0, .dir = .None };
        }

        pub fn flip(self: *const @This()) @This() {
            var flipped: @This() = self.*;
            // flip board
            for (0..n_rows) |row| {
                for (0..row / 2) |col1| {
                    const col2 = row - col1;
                    const idx1 = idxFromPos(.{ .row = @truncate(row), .col = @truncate(col1) });
                    if (col2 == col1) continue;
                    const idx2 = idxFromPos(.{ .row = @truncate(row), .col = @truncate(col2) });
                    if (self.board.isSet(idx1) == self.board.isSet(idx2)) continue;
                    flipped.board.toggle(idx1);
                    flipped.board.toggle(idx2);
                }
            }
            // flip chosen dirs + idxs + moves
            for (
                self.chosen_dirs,
                self.chosen_idxs,
                self.moves,
                0..self.chosen_dirs.len,
            ) |chosen_dir, chosen_idx, move, i| {
                if (chosen_dir == .None) continue;
                flipped.chosen_dirs[i] = chosen_dir.flip();
                flipped.chosen_idxs[i] = flipFromIdx(chosen_idx);
                // move
                var flipped_move: Directions = .initEmpty();
                inline for ([_]Direction{
                    .Left,
                    .UpLeft,
                    .UpRight,
                    .Right,
                    .DownRight,
                    .DownLeft,
                }) |dir| {
                    if (move.contains(dir)) {
                        flipped_move.insert(dir.flip());
                    }
                }
            }
            return flipped;
        }

        pub fn changeStart(self: *@This(), input: Input) !void {
            switch (input) {
                .idx => |idx| self.changeStartIdx(idx),
                .pos => |pos| self.changeStartPos(pos),
            }
        }

        fn changeStartPos(self: *@This(), pos: Position) !void {
            const idx = idxFromPos(pos);
            try self.changeStart(idx);
        }

        fn changeStartIdx(self: *@This(), idx: u16) !void {
            if (self.board.capacity() - 1 != self.board.count()) //
                return error.BoardInPlay;
            const prev_start = self.chosen_idxs[n_indices - 1];
            self.board.set(prev_start);
            self.board.unset(idx);
        }

        pub fn dfs(start: *const @This(), allo: Allocator) !void {
            // Finds First Solution And Prints It
            // stack
            var stack: std.ArrayList(@This()) = try .initCapacity(allo, 5);
            defer stack.deinit(allo);
            // append initial board state
            try stack.append(allo, start);
            // previously visited boards
            var visited: std.ArrayList(@This()) = try .initCapacity(allo, 5);
            defer visited.deinit(allo);
            // check if won
            var winning_board: ?@This() = null;
            // // loop
            while (stack.items.len > 0) {
                // pop previous board
                const prev_board = stack.pop().?;
                if (prev_board.isLost()) continue;
                if (prev_board.isWon()) {
                    winning_board = prev_board;
                    break;
                }
                const search = binarySearch(&visited, &prev_board);
                var board = if (search.visited) visited.items[search.idx] //
                    else prev_board;
                // get move
                const move = board.getMove();
                if (move.dir == .None) continue;
                // choose move
                var new_board = board;
                new_board.chooseMove(.{ .idx = move.idx }, move.dir);
                // Get symmetrical board
                const flip_prev_board = prev_board.flip();
                const search2 = binarySearch(&visited, &flip_prev_board);
                var flipped_board = if (search2.visited) visited.items[search2.idx] //
                    else flip_prev_board;
                const flip_move = move.flip();
                { // Remove Moves
                    board.moves[move.idx].remove(move.dir);
                    const mid_idx = getRotation(posFromIdx(move.idx), move.dir, .full).?;
                    const other_idx = idxFromPos(getRotation(mid_idx, move.dir, .full).?);
                    const other_dir = move.dir.opposite();
                    board.moves[other_idx].remove(other_dir);
                    // if board has moves, append onto stack
                    if (board.numMovesLeft() > 0) {
                        try stack.append(allo, board);
                    }
                    // if board was visited, modify, if board wasn't append
                    if (search.visited) {
                        visited.items[search.idx] = board;
                    } else {
                        try visited.append(allo, board);
                    }
                }
                { // Remove symmetrical moves
                    flipped_board.moves[flip_move.idx].remove(flip_move.dir);
                    const flip_mid_idx = getRotation(posFromIdx(flip_move.idx), flip_move.dir, .full).?;
                    const flip_other_idx = idxFromPos(getRotation(flip_mid_idx, flip_move.dir, .full).?);
                    const flip_other_dir = flip_move.dir.opposite();
                    flipped_board.moves[flip_other_idx].remove(flip_other_dir);
                    // if flipboard was visited, modify, if flipped board wasn't append
                    if (search2.visited) {
                        visited.items[search2.idx] = flipped_board;
                    } else {
                        try visited.append(allo, flipped_board);
                    }
                }
                // update stack with new board
                try stack.append(allo, new_board);
            }
            if (winning_board) |win| {
                print("Winning Sequence:\n", .{});
                for (0..win.chosen_idxs.len) |i| {
                    const j = win.board.capacity() - i - 1;
                    if (winning_board.?.chosen_dirs[j] == .None) break;
                    print("{}: {s}\n", .{ win.chosen_idxs[j], @tagName(win.chosen_dirs[j]) });
                }
            } else {
                print("No Solutions Found for {} rows!\n", .{MAX_ROWS});
            }
        }

        pub fn dfsAll(start: *const @This(), allo: Allocator) !void {
            // stack
            var stack: std.ArrayList(@This()) = try .initCapacity(allo, 5);
            defer stack.deinit(allo);
            // append initial board state
            try stack.append(allo, start);
            // previously visited boards
            var visited: std.ArrayList(@This()) = try .initCapacity(allo, 5);
            defer visited.deinit(allo);
            // store wins
            var wins: std.ArrayList(@This()) = try .initCapacity(allo, 5);
            defer wins.deinit(allo);
            // loop
            while (stack.items.len > 0) {
                // pop previous board
                const prev_board = stack.pop().?;
                if (prev_board.isWon()) {
                    // ordered insert into list
                    const search = binarySearch(&wins, &prev_board);
                    if (search.visited) {
                        try wins.insert(allo, search.idx, prev_board);
                    } else {
                        if (search.idx < wins.items.len) {
                            try wins.insert(allo, search.idx, prev_board);
                        } else {
                            try wins.append(allo, prev_board);
                        }
                    }
                }
                if (prev_board.isGameOver()) continue;
                const search = binarySearch(&visited, &prev_board);
                var board = if (search.visited) visited.items[search.idx] //
                    else prev_board;
                // get move
                const move = board.getMove();
                if (move.dir == .None) continue;
                // choose move
                var new_board = board;
                new_board.chooseMove(.{ .idx = move.idx }, move.dir);

                { // Remove Moves
                    board.moves[move.idx].remove(move.dir);
                    const mid_idx = getRotation(posFromIdx(move.idx), move.dir, .full).?;
                    const other_idx = idxFromPos(getRotation(mid_idx, move.dir, .full).?);
                    const other_dir = move.dir.opposite();
                    board.moves[other_idx].remove(other_dir);
                    if (board.numMovesLeft() > 0) { // append to stack
                        try stack.append(allo, board);
                    }
                    if (search.visited) { // modify visited
                        visited.items[search.idx] = board;
                    } else { // append visited
                        try visited.append(allo, board);
                    }
                }
                { // Remove symmetrical moves
                    // Get symmetrical board
                    const flip_prev_board = prev_board.flip();
                    const search2 = binarySearch(&visited, &flip_prev_board);
                    var flipped_board = if (search2.visited) visited.items[search2.idx] //
                        else flip_prev_board;
                    const flip_move = move.flip();
                    // make sure it has that move
                    if (flipped_board.moves[flip_move.idx].contains(flip_move.dir)) {
                        // remove moves
                        flipped_board.moves[flip_move.idx].remove(flip_move.dir);
                        const flip_mid_idx = getRotation(posFromIdx(flip_move.idx), flip_move.dir, .full).?;
                        const flip_other_idx = idxFromPos(getRotation(flip_mid_idx, flip_move.dir, .full).?);
                        const flip_other_dir = flip_move.dir.opposite();
                        flipped_board.moves[flip_other_idx].remove(flip_other_dir);
                        // if flipped was visited, modify, if flipped board wasn't append
                        if (search2.visited) {
                            visited.items[search2.idx] = flipped_board;
                        } else {
                            try visited.append(allo, flipped_board);
                        }
                    }
                }
                // update stack with new board
                try stack.append(allo, new_board);
            }
            // Prune Wins
            if (wins.items.len > 0) {
                print("# of Wins: {}\n", .{wins.items.len});
                var i: usize = 0;
                var n_wins: usize = wins.items.len;
                while (i <= n_wins - 2) : (i += 1) {
                    var j: usize = i + 1;
                    const curr = wins.items[i];
                    const curr_flip = curr.flip();
                    while (j <= n_wins - 1) : (j += 1) {
                        const next = wins.items[j];
                        if (curr.board.mask == next.board.mask or curr_flip.board.mask == next.board.mask) {
                            _ = wins.swapRemove(j);
                            n_wins -= 1;
                        }
                    }
                }
                print("# of Wins: {}\n", .{wins.items.len});
            } else {
                print("No Solutions Found for {} rows!\n", .{MAX_ROWS});
            }
            // Print All Wins - Should separate these features
            for (0..wins.items.len) |i| {
                const curr = wins.items[i];
                print("Solution {}:\n", .{i});
                var initial: @This() = start;
                for (0..n_indices) |j| {
                    const k = n_indices - j - 1;
                    const idx = curr.chosen_idxs[k];
                    const dir = curr.chosen_dirs[k];
                    if (dir == .None) break;
                    print("{}: {s} ", .{ idx, @tagName(dir) });
                    initial.chooseMove(.{ .idx = idx }, dir);
                    initial.printBoard();
                }
                print("\n", .{});
            }
        }

        fn binarySearch(board: *const @This(), visited: *const std.ArrayList(@This())) Search {
            if (visited.items.len == 0) return .{ .idx = 0, .visited = false };
            var lo: T = 0;
            var hi: T = @truncate(visited.items.len - 1);
            var mid: T = lo + (hi - lo) / 2;
            while (lo <= hi) {
                mid = lo + (hi - lo) / 2;
                if (visited.items[mid].board.mask == board.board.mask) {
                    return .{ .idx = mid, .visited = true };
                } else if (visited.items[mid].board.mask > board.board.mask) {
                    if (mid == 0) break;
                    hi = mid - 1;
                } else if (visited.items[mid].board.mask < board.board.mask) {
                    if (mid == visited.items.len) break;
                    lo = mid + 1;
                } else unreachable;
            }
            return .{ .idx = mid, .visited = false };
        }
    };
}

const Search = struct {
    idx: T,
    visited: bool,
};

test "Binary Search" {
    const Board = createBoard(5) catch unreachable;
    // allocator
    const allo = std.testing.allocator;
    // values
    const values = [_]T{ 0, 1, 5, 9, 20, 30, 100 };
    // array containing boards
    var boards: std.ArrayList(Board) = try .initCapacity(allo, values.len);
    defer boards.deinit(allo);
    // create board values
    for (0..values.len) |i| {
        const value = values[i];
        try boards.append(allo, try Board.init(0));
        boards.items[i].board.mask = @truncate(value);
    }
    // create search values
    const search_values = [_]T{ 0, 4, 10, 30, 1_000 };
    var search_boards = [_]Board{try .init(0)} ** search_values.len;
    for (search_values, 0..search_boards.len) |value, i| {
        search_boards[i].board.mask = @truncate(value);
    }
    // create answers
    const answers = [_]Search{
        .{ .idx = 0, .visited = true },
        .{ .idx = 2, .visited = false },
        .{ .idx = 4, .visited = false },
        .{ .idx = 5, .visited = true },
        .{ .idx = 6, .visited = false },
    };
    // Test
    for (search_boards, answers) |search_board, answer| {
        const search = search_board.binarySearch(&boards);
        try std.testing.expectEqual(search.visited, answer.visited);
        try std.testing.expectEqual(search.idx, answer.idx);
    }
}

test "Will MultiArrayList Help" {
    const Board = createBoard(5) catch unreachable;
    const al = std.ArrayList(Board);
    const ma = std.MultiArrayList(Board);
    try std.testing.expect(@sizeOf(al) == @sizeOf(ma));
}

test "Flip Board" {
    // Define board
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    // Create board
    var board: Board = try .init(0);
    // Define moves
    const Instruction = struct { idx: u16, dir: Direction, flip_mask: T };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .flip_mask = 32733 },
        .{ .idx = 3, .dir = .Right, .flip_mask = 32741 },
        .{ .idx = 5, .dir = .UpLeft, .flip_mask = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .flip_mask = 32202 },
        .{ .idx = 2, .dir = .DownRight, .flip_mask = 32134 },
    };
    for (list_of_instructions) |instruction| {
        board.chooseMove(.{ .idx = instruction.idx }, instruction.dir);
        const flipped_board = board.flip();
        try std.testing.expectEqual(flipped_board.board.mask, instruction.flip_mask);
    }
}

test "Num Moves" {
    // const allo = std.testing.allocator;
    // Define Board
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    // Create Board
    var board: Board = try .init(0);
    // Define num moves
    const Instruction = struct { idx: u16, dir: Direction, num_moves: T };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .num_moves = 8 },
        .{ .idx = 3, .dir = .Right, .num_moves = 12 },
        .{ .idx = 5, .dir = .UpLeft, .num_moves = 8 },
        .{ .idx = 1, .dir = .DownLeft, .num_moves = 10 },
        .{ .idx = 2, .dir = .DownRight, .num_moves = 12 },
        .{ .idx = 3, .dir = .DownRight, .num_moves = 10 },
        .{ .idx = 0, .dir = .DownLeft, .num_moves = 8 },
        .{ .idx = 5, .dir = .UpLeft, .num_moves = 8 },
        .{ .idx = 12, .dir = .Left, .num_moves = 4 },
        .{ .idx = 11, .dir = .Right, .num_moves = 2 },
        .{ .idx = 12, .dir = .UpRight, .num_moves = 4 },
        .{ .idx = 10, .dir = .Right, .num_moves = 0 },
    };
    // Test
    try std.testing.expectEqual(board.numMovesLeft(), 4);

    for (list_of_instructions) |instruction| {
        board.chooseMove(.{ .idx = instruction.idx }, instruction.dir);

        try std.testing.expectEqual(board.numMovesLeft(), instruction.num_moves);
    }
}

test "Has Remaining Moves" {
    // Define board
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    // Create board
    var board: Board = try .init(0);
    // Define Whether Board Has Remaining Moves
    const Instruction = struct { idx: u16, dir: Direction, hash_remaining_moves: bool };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .hash_remaining_moves = true },
        .{ .idx = 3, .dir = .Right, .hash_remaining_moves = true },
        .{ .idx = 5, .dir = .UpLeft, .hash_remaining_moves = true },
        .{ .idx = 1, .dir = .DownLeft, .hash_remaining_moves = true },
        .{ .idx = 2, .dir = .DownRight, .hash_remaining_moves = true },
        .{ .idx = 3, .dir = .DownRight, .hash_remaining_moves = true },
        .{ .idx = 0, .dir = .DownLeft, .hash_remaining_moves = true },
        .{ .idx = 5, .dir = .UpLeft, .hash_remaining_moves = true },
        .{ .idx = 12, .dir = .Left, .hash_remaining_moves = true },
        .{ .idx = 11, .dir = .Right, .hash_remaining_moves = true },
        .{ .idx = 12, .dir = .UpRight, .hash_remaining_moves = true },
        .{ .idx = 10, .dir = .Right, .hash_remaining_moves = false },
    };
    // Test
    for (list_of_instructions) |instruction| {
        board.chooseMove(.{ .idx = instruction.idx }, instruction.dir);
        try std.testing.expectEqual(
            board.hasRemainingMoves(),
            instruction.hash_remaining_moves,
        );
    }
}

test "Are Neg Moves Correct" {
    // Define Board
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    // Create Board
    var board: Board = try .init(0);
    // Define Negative Moves + Resulting Board States
    const Instruction = struct { idx: u16, dir: Direction, value: u16 };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .value = 32757 },
        .{ .idx = 3, .dir = .Right, .value = 32717 },
        .{ .idx = 5, .dir = .UpLeft, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
        .{ .idx = 12, .dir = .Left, .value = 28960 },
        .{ .idx = 11, .dir = .Right, .value = 18720 },
        .{ .idx = 12, .dir = .UpRight, .value = 22528 },
        .{ .idx = 10, .dir = .Right, .value = 17408 },
    };
    // Test
    for (list_of_instructions) |instruction| {
        board.chooseMove(.{ .idx = instruction.idx }, instruction.dir);
        try std.testing.expectEqual(board.board.mask, instruction.value);
    }
}

test "Are Pos Moves Correct" {
    // Define Board
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    // Create Board
    var board: Board = try .init(0);
    // Define Positive Moves + Resulting Board States
    const Instruction = struct { idx: u16, dir: Direction, value: u16 };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 3, .dir = .UpRight, .value = 32757 },
        .{ .idx = 5, .dir = .Left, .value = 32717 },
        .{ .idx = 0, .dir = .DownRight, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
        .{ .idx = 12, .dir = .Left, .value = 28960 },
        .{ .idx = 11, .dir = .Right, .value = 18720 },
        .{ .idx = 12, .dir = .UpRight, .value = 22528 },
        .{ .idx = 10, .dir = .Right, .value = 17408 },
    };
    // Test
    for (list_of_instructions) |instruction| {
        board.chooseMove(.{ .idx = instruction.idx }, instruction.dir);
        try std.testing.expectEqual(board.board.mask, instruction.value);
    }
}

test "Is Lost" {
    // Define Board
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    // Create Board
    var board: Board = try .init(0);
    // Define Lost State
    const Instruction = struct { idx: u16, dir: Direction, is_lost: bool };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 3, .dir = .Right, .is_lost = false },
        .{ .idx = 5, .dir = .UpLeft, .is_lost = false },
        .{ .idx = 1, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 2, .dir = .DownRight, .is_lost = false },
        .{ .idx = 3, .dir = .DownRight, .is_lost = false },
        .{ .idx = 0, .dir = .DownLeft, .is_lost = false },
        .{ .idx = 5, .dir = .UpLeft, .is_lost = false },
        .{ .idx = 12, .dir = .Left, .is_lost = false },
        .{ .idx = 11, .dir = .Right, .is_lost = false },
        .{ .idx = 12, .dir = .UpRight, .is_lost = false },
        .{ .idx = 10, .dir = .Right, .is_lost = true },
    };
    // Test
    for (list_of_instructions) |instruction| {
        board.chooseMove(.{ .idx = instruction.idx }, instruction.dir);
        try std.testing.expectEqual(board.isLost(), instruction.is_lost);
    }
}

test "Is Won" {
    // Define Board
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    // Create Board
    var board: Board = try .init(0);
    // Define Won State
    const Instruction = struct { idx: u16, dir: Direction, is_won: bool };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .is_won = false },
        .{ .idx = 3, .dir = .Right, .is_won = false },
        .{ .idx = 5, .dir = .UpLeft, .is_won = false },
        .{ .idx = 1, .dir = .DownLeft, .is_won = false },
        .{ .idx = 2, .dir = .DownRight, .is_won = false },
        .{ .idx = 3, .dir = .DownRight, .is_won = false },
        .{ .idx = 0, .dir = .DownLeft, .is_won = false },
        .{ .idx = 5, .dir = .UpLeft, .is_won = false },
        .{ .idx = 12, .dir = .Left, .is_won = false },
        .{ .idx = 11, .dir = .Right, .is_won = false },
        .{ .idx = 12, .dir = .UpRight, .is_won = false },
        .{ .idx = 11, .dir = .Right, .is_won = false },
        .{ .idx = 14, .dir = .Left, .is_won = true },
    };
    // Test
    for (list_of_instructions) |instruction| {
        board.chooseMove(.{ .idx = instruction.idx }, instruction.dir);
        try std.testing.expectEqual(board.isWon(), instruction.is_won);
    }
}

test "Reset Board" {
    // Define Board
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    // Create Board
    var board: Board = try .init(0);
    // Define Restarting + Resulting Board State
    const start_value: T = board.board.mask;
    const Instruction = struct { idx: u16, dir: Direction, value: u16 };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 0, .dir = .DownLeft, .value = 32757 },
        .{ .idx = 3, .dir = .Right, .value = 32717 },
        .{ .idx = 5, .dir = .UpLeft, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
        .{ .idx = 12, .dir = .Left, .value = 28960 },
        .{ .idx = 11, .dir = .Right, .value = 18720 },
        .{ .idx = 12, .dir = .UpRight, .value = 22528 },
        .{ .idx = 10, .dir = .Right, .value = 17408 },
    };
    // Test
    for (list_of_instructions) |instruction| {
        board.chooseMove(.{ .idx = instruction.idx }, instruction.dir);
    }
    board.resetBoard();
    try std.testing.expectEqual(board.board.mask, start_value);
}

test "Undo Move + Redo Move" {
    // Define Board
    const N_ROWS = 5;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    // Create Board
    var board: Board = try .init(0);
    // Define Undo + Redo + Resulting Board States
    const Instruction = struct { idx: u16, dir: Direction, value: u16 };
    const list_of_instructions = [_]Instruction{
        .{ .idx = 3, .dir = .UpRight, .value = 32757 },
        .{ .idx = 5, .dir = .Left, .value = 32717 },
        .{ .idx = 0, .dir = .DownRight, .value = 32744 },
        .{ .idx = 1, .dir = .DownLeft, .value = 32674 },
        .{ .idx = 2, .dir = .DownRight, .value = 32134 },
        .{ .idx = 3, .dir = .DownRight, .value = 27918 },
        .{ .idx = 0, .dir = .DownLeft, .value = 27909 },
        .{ .idx = 5, .dir = .UpLeft, .value = 27936 },
        .{ .idx = 12, .dir = .Left, .value = 28960 },
        .{ .idx = 11, .dir = .Right, .value = 18720 },
        .{ .idx = 12, .dir = .UpRight, .value = 22528 },
        .{ .idx = 10, .dir = .Right, .value = 17408 },
    };
    // Test
    // Original Moves
    for (list_of_instructions) |instruction| {
        board.chooseMove(.{ .idx = instruction.idx }, instruction.dir);
    }
    // Undo
    for (0..list_of_instructions.len - 1) |i| {
        const j = list_of_instructions.len - i - 2;
        const instruction = list_of_instructions[j];
        board.undoMove();
        try std.testing.expectEqual(instruction.value, board.board.mask);
    }
    // Redo
    for (0..list_of_instructions.len - 1) |i| {
        const instruction = list_of_instructions[i + 1];
        board.redoMove();
        try std.testing.expectEqual(instruction.value, board.board.mask);
    }
}

test "Reduced Memory Footprint" {
    // Define board
    const N_ROWS = 360;
    const Board: type = createBoard(N_ROWS) catch unreachable;
    try std.testing.expectEqual(@sizeOf(Board), 268048);
    try std.testing.expectEqual(@sizeOf(std.MultiArrayList(Board)), 24); // list of slices
}
