const expect = @import("std").testing.expect;
const assert = @import("std").testing.assert;
const Color = @import("generation.zig").Color;
const Move = @import("generation.zig").Move;
const positionFromFEN = @import("utils.zig").positionFromFEN;
const Position = @import("generation.zig").Position;
const Moves = @import("generation.zig").Moves;
const getPlayerMoves = @import("generation.zig").getPlayerMoves;
const moveCount = @import("utils.zig").moveCount;
const squareDifferent = @import("utils.zig").squareDifferent;
const print = @import("std").debug.print;
const squareToCoordinate = @import("utils.zig").squareToNotation;

test "Ensure valid moves for pawn" {
    // var leftPassantPosition = positionFromFEN("rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3");
    // var index: usize = 0;
    // var moves = Moves{.playerMoves = [_]Move{undefined}**256, .iMove = &index};
    // getPlayerMoves(&leftPassantPosition, &moves);
    // for (moves.playerMoves) |playerMove| {
    //     if (squareDifferent(playerMove.from, playerMove.to)) {
    //         print("from {} to {}", .{playerMove.from, playerMove.to});
    //     }
    // }
}

test "Ensure valid moves for rook" {
    // Similar structure as above. Initialize MoveGenerator, call function, check results.
}

// ... Write more tests for other pieces ...
