// const std = @import("std");
// const Board = @import("board.zig");
// const Moves = @import("moves.zig");

// pub fn runUCILoop() void {
//     var line: [256]u8 = undefined;
//     while (true) {
//         const len = std.io.getStdIn().readUntilDelimiterOrEof(&line, '\n') catch break;
//         handleUCICommand(line[0..len]);
//     }
// }

// fn handleUCICommand(command: []u8) void {
//     _ = command;
// }
