const setupBoard = @import("generation.zig").setupBoard;
const Color = @import("generation.zig").Color;
const Move = @import("generation.zig").Move;
const MoveGenerator = @import("generation.zig").MoveGenerator;
const Piece = @import("generation.zig").Piece;
const Square = @import("generation.zig").Square;
const Type = @import("generation.zig").Type;
const getPlayerMoves = @import("generation.zig").getPlayerMoves;
const print = @import("std").debug.print;
const squareToCoordinate = @import("utils.zig").squareToCoordinate;

pub fn main() void {
    // UCI.runUCILoop();
    var moveGenerator = MoveGenerator{ .board = undefined, .iMove = undefined, .playerColor = Color.White, .playerMoves = [_]Move{undefined} ** 256 };
    setupBoard(&moveGenerator);
    const whitePawn = moveGenerator.board[1][4];
    moveGenerator.board[1][4] = null;
    moveGenerator.board[4][4] = whitePawn;
    const blackPawn = moveGenerator.board[6][3];
    moveGenerator.board[6][3] = null;
    moveGenerator.board[4][3] = blackPawn;
    moveGenerator.lastMove = Move{ .from = Square{ .column = 3, .row = 6 }, .to = Square{ .column = 3, .row = 4 }, .movingPiece = Piece{ .type = Type.Pawn, .color = Color.Black }, .landingSquare = null };
    getPlayerMoves(&moveGenerator);
    for (moveGenerator.playerMoves) |move| {
        const from = move.from;
        const to = move.to;
        if (from.column != to.column or from.row != to.row) {
            print("{s} to {s}\n", .{ squareToCoordinate(from), squareToCoordinate(to) });
        }
    }
}
