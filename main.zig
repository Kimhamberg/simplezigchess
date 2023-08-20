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

pub fn main() void {
    // UCI.runUCILoop();
    var moveGenerator = MoveGenerator{ .board = undefined, .iMove = undefined, .playerColor = Color.White, .playerMoves = [_]Move{undefined} ** 256 };
    setupBoard(&moveGenerator);
    // black bishop from f8 to b4
    const blackBishop = moveGenerator.board[7][5];
    moveGenerator.board[7][5] = null;
    moveGenerator.board[3][1] = blackBishop;
    // white pawn from d2 to d3
    const whitePawn = moveGenerator.board[1][3];
    moveGenerator.board[1][3] = null;
    moveGenerator.board[2][3] = whitePawn;
    // white knight from b1 to c3
    const whiteKnight = moveGenerator.board[0][1];
    moveGenerator.board[0][1] = null;
    moveGenerator.board[2][2] = whiteKnight;

    getPlayerMoves(&moveGenerator);
    for (moveGenerator.playerMoves) |move| {
        const from = move.from;
        const to = move.to;
        if (from.column != to.column or from.row != to.row) {
            print("{s} to {s}\n", .{ squareToCoordinate(from), squareToCoordinate(to) });
        }
    }
}
