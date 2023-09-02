const Color = @import("generation.zig").Color;
const Move = @import("generation.zig").Move;
const Piece = @import("generation.zig").Piece;
const Square = @import("generation.zig").Square;
const Type = @import("generation.zig").Type;
const Moves = @import("generation.zig").Moves;
const getPlayerMoves = @import("generation.zig").getPlayerMoves;
const print = @import("std").debug.print;
const squareToCoordinate = @import("utils.zig").squareToNotation;
const gameFromFEN = @import("utils.zig").gameFromFEN;

pub fn main() void {
    var moves = Moves(undefined ** 256, undefined);
    var position = gameFromFEN("r1bqkb1r/ppp2ppp/2n5/1B1pP3/4n3/2N2Q2/PPPP2PP/R1B1K1NR b KQkq - 3 6");
    getPlayerMoves(&position);
    for (moves.playerMoves) |move| {
        const from = move.from;
        const to = move.to;
        if (from.column != to.column or from.row != to.row) {
            print("{s} to {s}\n", .{ squareToCoordinate(from), squareToCoordinate(to) });
        }
    }
}
