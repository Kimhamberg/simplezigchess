const Color = @import("generation.zig").Color;
const Square = @import("generation.zig").Square;
const Piece = @import("generation.zig").Piece;
const Type = @import("generation.zig").Type;
const Move = @import("generation.zig").Move;
const Step = @import("generation.zig").Step;
const Position = @import("generation.zig").Position;
const getBoard = @import("utils.zig").getBoard;
const Moves = @import("generation.zig").Moves;
const PieceMoves = @import("generation.zig").PieceMoves;
const moveInBounds = @import("utils.zig").moveInBounds;
const makeMove = @import("utils.zig").makeMove;
const undoMove = @import("utils.zig").undoMove;
const pieceIsMyKing = @import("utils.zig").pieceIsMyKing;

pub fn inCheckAfterMove(position: *Position, move: Move) bool {
    makeMove(position, move);
    const inCheck = opponentGivesCheck(position);
    undoMove(position, move);
    return inCheck;
}

pub fn opponentGivesCheck(position: *Position, moves: Moves) bool {
    var index: usize = 0;
    moves.iMove = &index;
    for (position.board, 0..) |row, iRow| {
        for (row, 0..) |possiblePiece, iColumn| {
            if (possiblePiece) |piece| {
                if (piece.color != position.turn) {
                    if (pieceDoesCheck(position, Square{ .column = @intCast(iColumn), .row = @intCast(iRow) }, piece)) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

fn pieceDoesCheck(position: *Position, square: Square, piece: Piece) bool {
    switch (piece.type) {
        Type.Pawn => if (pawnDoesCheck(position, square)) {
            return true;
        },
        Type.Knight => if (knightDoesCheck(position, square)) {
            return true;
        },
        Type.Bishop => if (brqDoesCheck(position, square, PieceMoves.Bishop)) {
            return true;
        },
        Type.Rook => if (brqDoesCheck(position, square, PieceMoves.Rook)) {
            return true;
        },
        Type.Queen => if (brqDoesCheck(position, square, PieceMoves.Queen)) {
            return true;
        },
        Type.King => if (kingDoesCheck(position, square)) {
            return true;
        },
    }
    return false;
}

fn pawnDoesCheck(position: *Position, square: Square) bool {
    const oneStep: i64 = if (position.turn == Color.White) 1 else -1;

    const diagonalLeft = Square{ .row = square.row + oneStep, .column = square.column - 1 };
    if (moveInBounds(diagonalLeft)) {
        if (getBoard(position, diagonalLeft)) |attackedPiece| {
            if (pieceIsMyKing(position, attackedPiece)) {
                return true;
            }
        }
    }

    const diagonalRight = Square{ .row = square.row + oneStep, .column = square.column + 1 };
    if (moveInBounds(diagonalRight)) {
        if (getBoard(position, diagonalRight)) |attackedPiece| {
            if (pieceIsMyKing(position, attackedPiece)) {
                return true;
            }
        }
    }

    return false;
}

fn knightDoesCheck(position: *Position, square: Square) bool {
    for (PieceMoves.Knight) |knightMove| {
        const attackedSquare = Square{ .row = square.row + knightMove, .column = square.column + knightMove.column };
        if (moveInBounds(attackedSquare)) {
            if (getBoard(position, attackedSquare)) |attackedPiece| {
                if (pieceIsMyKing(position, attackedPiece)) {
                    return true;
                }
            }
        }
    }
    return false;
}

fn brqDoesCheck(position: *Position, square: Square, pieceMoves: []Step) bool {
    for (pieceMoves) |pieceMove| {
        const attackedSquare = Square{ .row = square.row + pieceMove.row, .column = square.column + pieceMove.column };
        while (moveInBounds(attackedSquare)) {
            if (getBoard(position, attackedSquare)) |attackedPiece| {
                if (pieceIsMyKing(position, attackedPiece)) {
                    return true;
                }
                break;
            }
            attackedSquare = Square{ .row = attackedSquare.row + pieceMove.row, .column = attackedSquare.column + pieceMove.column };
        }
    }
    return false;
}

fn kingDoesCheck(position: *Position, square: Square) bool {
    for (PieceMoves.King) |kingMove| {
        const attackedSquare = Square{ .row = square.row + kingMove.row, .column = square.column + kingMove.column };
        if (moveInBounds(attackedSquare)) {
            if (getBoard(position, attackedSquare)) |attackedPiece| {
                if (pieceIsMyKing(position, attackedPiece)) {
                    return true;
                }
            }
        }
    }
    return false;
}
