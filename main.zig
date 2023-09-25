const Color = @import("generation.zig").Color;
const Move = @import("generation.zig").Move;
const Piece = @import("generation.zig").Piece;
const Square = @import("generation.zig").Square;
const Type = @import("generation.zig").Type;
const Moves = @import("generation.zig").Moves;
const getPlayerMoves = @import("generation.zig").getPlayerMoves;
const positionFromFEN = @import("utils.zig").positionFromFEN;
const squareDifferent = @import("utils.zig").squareDifferent;
const print = @import("std").debug.print;
const squareToNotation = @import("utils.zig").squareToNotation;

pub fn main() void {
    var leftPassantPosition = positionFromFEN("rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 3");
    var index: usize = 0;
    var moves = Moves{.playerMoves = [_]Move{undefined}**256, .iMove = &index};
    var actualLeftPassantPosition = leftPassantPosition catch return;
    getPlayerMoves(&actualLeftPassantPosition, &moves);
    getPlayerMoves(&leftPassantPosition, &moves);
    for (moves.playerMoves) |playerMove| {
        if (squareDifferent(playerMove.from, playerMove.to)) {
            print("from {s} to {s}", .{squareToNotation(playerMove.from), squareToNotation(playerMove.to)});
        }
    }
}
