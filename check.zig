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

pub fn inCheckAfterMove(position: *Position, move: Move) !bool {
    const oldPosition = try makeMove(position, move);
    defer undoMove(position, oldPosition) catch unreachable;
    const inCheck = try opponentGivesCheck(position);
    return inCheck;
}

pub fn opponentGivesCheck(position: *Position) !bool {
    for (position.board, 0..) |row, iRow| {
        for (row, 0..) |possiblePiece, iColumn| {
            if (possiblePiece) |piece| {
                if (piece.color != position.turn) {
                    if (try pieceDoesCheck(position, Square{ .column = @intCast(iColumn), .row = @intCast(iRow) }, piece)) {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

fn pieceDoesCheck(position: *Position, square: Square, piece: Piece) !bool {
    switch (piece.type) {
        Type.Pawn => if (try pawnDoesCheck(position, square)) {
            return true;
        },
        Type.Knight => if (try knightDoesCheck(position, square)) {
            return true;
        },
        Type.Bishop => if (try brqDoesCheck(position, square, PieceMoves.Bishop[0..])) {
            return true;
        },
        Type.Rook => if (try brqDoesCheck(position, square, PieceMoves.Rook[0..])) {
        },
        Type.Queen => if (try brqDoesCheck(position, square, PieceMoves.Queen[0..])) {
            return true;
        },
        Type.King => if (try kingDoesCheck(position, square)) {
            return true;
        },
    }
    return false;
}

fn pawnDoesCheck(position: *Position, square: Square) !bool {
    const oneStep: i64 = if (position.turn == Color.White) 1 else -1;

    const diagonalLeft = Square{ .row = square.row + oneStep, .column = square.column - 1 };
    if (try moveInBounds(diagonalLeft)) {
        if (try getBoard(position, diagonalLeft)) |attackedPiece| {
            if (try pieceIsMyKing(position, attackedPiece)) {
                return true;
            }
        }
    }

    const diagonalRight = Square{ .row = square.row + oneStep, .column = square.column + 1 };
    if (try moveInBounds(diagonalRight)) {
        if (try getBoard(position, diagonalRight)) |attackedPiece| {
            if (try pieceIsMyKing(position, attackedPiece)) {
                return true;
            }
        }
    }

    return false;
}

fn knightDoesCheck(position: *Position, square: Square) !bool {
    for (PieceMoves.Knight) |knightMove| {
        const attackedSquare = Square{ .row = square.row + knightMove.row, .column = square.column + knightMove.column };
        if (try moveInBounds(attackedSquare)) { 
            if (try getBoard(position, attackedSquare)) |attackedPiece| { 
                if (try pieceIsMyKing(position, attackedPiece)) { 
                    return true;
                }
            }
        }
    }
    return false;
}

fn brqDoesCheck(position: *Position, square: Square, pieceMoves: []const Step) !bool {
    for (pieceMoves) |pieceMove| {
        var attackedSquare = Square{ .row = square.row + pieceMove.row, .column = square.column + pieceMove.column };
        while (try moveInBounds(attackedSquare)) {
            if (try getBoard(position, attackedSquare)) |attackedPiece| {
                if (try pieceIsMyKing(position, attackedPiece)) {
                    return true;
                }
                break;
            }
            attackedSquare = Square{ .row = attackedSquare.row + pieceMove.row, .column = attackedSquare.column + pieceMove.column };
        }
    }
    return false;
}

fn kingDoesCheck(position: *Position, square: Square) !bool {
    for (PieceMoves.King) |kingMove| {
        const attackedSquare = Square{ .row = square.row + kingMove.row, .column = square.column + kingMove.column };
        if (try moveInBounds(attackedSquare)) {
            if (try getBoard(position, attackedSquare)) |attackedPiece| {
                if (try pieceIsMyKing(position, attackedPiece)) {
                    return true;
                }
            }
        }
    }
    return false;
}
