const setupBoard = @import("generation.zig").setupBoard;
const Color = @import("generation.zig").Color;
const Move = @import("generation.zig").Move;
const MoveGenerator = @import("generation.zig").MoveGenerator;
const Piece = @import("generation.zig").Piece;
const Square = @import("generation.zig").Square;
const Type = @import("generation.zig").Type;
const getPlayerMoves = @import("generation.zig").getPlayerMoves;
const print = @import("std").debug.print;
const squareToCoordinate = @import("utils.zig").squareToNotation;
const gameFromFEN = @import("utils.zig").gameFromFEN;

pub fn main() void {
    var game = gameFromFEN("r1bqkb1r/ppp2ppp/2n5/1B1pP3/4n3/2N2Q2/PPPP2PP/R1B1K1NR b KQkq - 3 6");
    getPlayerMoves(&game);
    for (game.moveManager.playerMoves) |move| {
        const from = move.from;
        const to = move.to;
        if (from.column != to.column or from.row != to.row) {
            print("{s} to {s}\n", .{ squareToCoordinate(from), squareToCoordinate(to) });
        }
    }
}
