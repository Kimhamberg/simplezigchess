const std = @import("std");
const expect = std.testing.expect;
const assert = std.testing.assert;
const MoveGenerator = @import("generation.zig").MoveGenerator;
const setupBoard = @import("generation.zig").setupBoard;
const Color = @import("generation.zig").Color;
const Move = @import("generation.zig").Move;

var moveGenerator = MoveGenerator{ .board = undefined, .iMove = undefined, .playerColor = Color.White, .playerMoves = [_]Move{undefined} ** 256 };

test "Ensure valid moves for pawn" {
    
    // expect(moveGenerator.playerMoves[0].from == some_expected_value);
}

test "Ensure valid moves for rook" {
    // Similar structure as above. Initialize MoveGenerator, call function, check results.
}

// ... Write more tests for other pieces ...
