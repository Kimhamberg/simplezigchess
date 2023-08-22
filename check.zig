const MoveGenerator = @import("generation.zig").MoveManager;
const Color = @import("generation.zig").Color;
const Square = @import("generation.zig").Square;
const Piece = @import("generation.zig").Piece;
const Type = @import("generation.zig").Type;
const Move = @import("generation.zig").Move;
const Step = @import("generation.zig").Step;
const getBoard = @import("utils.zig").getBoard;
const PieceMoves = @import("generation.zig").PieceMoves;
const moveInBounds = @import("utils.zig").moveInBounds;
const pieceIsMyKing = @import("utils.zig").pieceIsMyKing;
const makeMove = @import("utils.zig").makeMove;
const undoMove = @import("utils.zig").undoMove;

pub fn inCheckAfterMove(self: *MoveGenerator, move: Move) bool {
    makeMove(self, move);
    const opponentGivesCheck = opponentDoesCheck(self);
    undoMove(self, move);
    return opponentGivesCheck;
}

pub fn opponentDoesCheck(self: *MoveGenerator) bool {
    var index: usize = 0;
    self.iMove = &index;
    for (self.board, 0..) |row, iRow| {
        for (row, 0..) |possiblePiece, iColumn| {
            if (possiblePiece) |piece| {
                if (piece.color != self.playerColor) {
                    if (pieceDoesCheck(self, Square{ .column = @intCast(iColumn), .row = @intCast(iRow) }, piece)) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

fn pieceDoesCheck(self: *MoveGenerator, square: Square, piece: Piece) bool {
    switch (piece.type) {
        Type.Pawn => if (pawnDoesCheck(self, square)) {
            return true;
        },
        Type.Knight => if (knightDoesCheck(self, square)) {
            return true;
        },
        Type.Bishop => if (brqDoesCheck(self, square, PieceMoves.Bishop)) {
            return true;
        },
        Type.Rook => if (brqDoesCheck(self, square, PieceMoves.Rook)) {
            return true;
        },
        Type.Queen => if (brqDoesCheck(self, square, PieceMoves.Queen)) {
            return true;
        },
        Type.King => if (kingDoesCheck(self, square)) {
            return true;
        },
    }
    return false;
}

fn pawnDoesCheck(self: *MoveGenerator, square: Square) bool {
    const oneStep: i64 = if (self.playerColor == Color.White) 1 else -1;

    const diagonalLeft = Square{ .row = square.row + oneStep, .column = square.column - 1 };
    if (moveInBounds(diagonalLeft)) {
        if (getBoard(self, diagonalLeft)) |attackedPiece| {
            if (pieceIsMyKing(self, attackedPiece)) {
                return true;
            }
        }
    }

    const diagonalRight = Square{ .row = square.row + oneStep, .column = square.column + 1 };
    if (moveInBounds(diagonalRight)) {
        if (getBoard(self, diagonalRight)) |attackedPiece| {
            if (pieceIsMyKing(self, attackedPiece)) {
                return true;
            }
        }
    }

    return false;
}

fn knightDoesCheck(self: *MoveGenerator, square: Square) bool {
    for (PieceMoves.Knight) |knightMove| {
        const attackedSquare = Square{ .row = square.row + knightMove, .column = square.column + knightMove.column };
        if (moveInBounds(attackedSquare)) {
            if (getBoard(self, attackedSquare)) |attackedPiece| {
                if (pieceIsMyKing(self, attackedPiece)) {
                    return true;
                }
            }
        }
    }
    return false;
}

fn brqDoesCheck(self: *MoveGenerator, square: Square, pieceMoves: []Step) bool {
    for (pieceMoves) |pieceMove| {
        const attackedSquare = Square{ .row = square.row + pieceMove.row, .column = square.column + pieceMove.column };
        while (moveInBounds(attackedSquare)) {
            if (getBoard(self, attackedSquare)) |attackedPiece| {
                if (pieceIsMyKing(self, attackedPiece)) {
                    return true;
                }
                break;
            }
            attackedSquare = Square{ .row = attackedSquare.row + pieceMove.row, .column = attackedSquare.column + pieceMove.column };
        }
    }
    return false;
}

fn kingDoesCheck(self: *MoveGenerator, square: Square) bool {
    for (PieceMoves.King) |kingMove| {
        const attackedSquare = Square{ .row = square.row + kingMove.row, .column = square.column + kingMove.column };
        if (moveInBounds(attackedSquare)) {
            if (getBoard(self, attackedSquare)) |attackedPiece| {
                if (pieceIsMyKing(self, attackedPiece)) {
                    return true;
                }
            }
        }
    }
    return false;
}
