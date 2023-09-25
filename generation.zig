const moveInBounds = @import("utils.zig").moveInBounds;
const squaresBetweenEmpty = @import("utils.zig").squaresBetweenEmpty;
const addMove = @import("utils.zig").addMove;
const getBoard = @import("utils.zig").getBoard;
const print = @import("std").debug.print;
const inCheckAfterMove = @import("check.zig").inCheckAfterMove;
const opponentGivesCheck = @import("check.zig").opponentGivesCheck;

pub const Type = enum { Pawn, Knight, Bishop, Rook, Queen, King };
pub const Color = enum { White, Black };
pub const Piece = struct { type: Type, color: Color };
pub const Board = [8][8]?Piece;

pub const Square = struct {
    column: i64,
    row: i64,
};

pub const Step = struct {
    column: i64,
    row: i64,
};

pub const PieceMoves = struct {
    pub const Knight = [8]Step{
        Step{ .column = -1, .row = 2 }, // UUL
        Step{ .column = 1, .row = 2 }, // UUR
        Step{ .column = -2, .row = 1 }, // LLU
        Step{ .column = 2, .row = 1 }, // RRU
        Step{ .column = -2, .row = -1 }, // LLD
        Step{ .column = 2, .row = -1 }, // RRD
        Step{ .column = -1, .row = -2 }, // DDL
        Step{ .column = 1, .row = -2 }, // DDR
    };
    pub const Bishop = [4]Step{
        Step{ .column = -1, .row = 1 }, // UL
        Step{ .column = 1, .row = 1 }, // UR
        Step{ .column = -1, .row = -1 }, // DL
        Step{ .column = 1, .row = -1 }, // DR
    };
    pub const Rook = [4]Step{
        Step{ .column = -1, .row = 0 }, // L
        Step{ .column = 1, .row = 0 }, // R
        Step{ .column = 0, .row = 1 }, // U
        Step{ .column = 0, .row = -1 }, // D
    };
    pub const Queen = [8]Step{
        Step{ .column = -1, .row = 1 }, // UL
        Step{ .column = 1, .row = 1 }, // UR
        Step{ .column = -1, .row = -1 }, // DL
        Step{ .column = 1, .row = -1 }, // DR
        Step{ .column = -1, .row = 0 }, // L
        Step{ .column = 1, .row = 0 }, // R
        Step{ .column = 0, .row = 1 }, // U
        Step{ .column = 0, .row = -1 }, // D
    };
    pub const King = [8]Step{
        Step{ .column = -1, .row = 1 }, // UL
        Step{ .column = 1, .row = 1 }, // UR
        Step{ .column = -1, .row = -1 }, // DL
        Step{ .column = 1, .row = -1 }, // DR
        Step{ .column = -1, .row = 0 }, // L
        Step{ .column = 1, .row = 0 }, // R
        Step{ .column = 0, .row = 1 }, // U
        Step{ .column = 0, .row = -1 }, // D
    };
};

pub const Move = struct {
    from: Square,
    to: Square,
    castlingRookFrom: ?Square = null,
    castlingRookTo: ?Square = null,
    promotion: ?Type = null,
};

pub const Moves = struct {
    playerMoves: [256]Move,
    iMove: *usize,
};

pub const Position = struct {
    board: Board = undefined,
    turn: Color = Color.White,
    canWhiteShortCastle: bool = true,
    canWhiteLongCastle: bool = true,
    canBlackShortCastle: bool = true,
    canBlackLongCastle: bool = true,
    enPassantSquare: ?Square = null,
    halfMoveClock: usize = 0,
    fullMoveNumber: usize = 1,
};

pub fn getPlayerMoves(position: *Position, moves: *Moves) void {
    for (position.board, 0..) |row, iRow| {
        for (row, 0..) |possiblePiece, iColumn| {
            if (possiblePiece) |piece| {
                if (piece.color == position.turn) {
                    getPieceMoves(position, Square{ .column = @intCast(iColumn), .row = @intCast(iRow) }, piece, moves);
                }
            }
        }
    }
}

pub fn getPieceMoves(position: *Position, square: Square, piece: Piece, moves: *Moves) void {
    switch (piece.type) {
        Type.Pawn => return getPawnMoves(position, square, moves),
        Type.Knight => return getKnightMoves(position, square, moves),
        Type.Bishop => return getBRQMoves(position, square, moves, PieceMoves.Bishop[0..]),
        Type.Rook => return getBRQMoves(position, square, moves, PieceMoves.Rook[0..]),
        Type.Queen => return getBRQMoves(position, square, moves, PieceMoves.Queen[0..]),
        Type.King => return getKingMoves(position, square, moves),
    }
}

fn getPawnMoves(position: *Position, square: Square, moves: *Moves) void {
    const oneStep: i64 = if (position.turn == Color.White) 1 else -1;
    const oneStepSquare = Square{ .column = square.column, .row = square.row + oneStep };
    if (moveInBounds(oneStepSquare)) {
        const oneStepMove = Move{ .from = square, .to = oneStepSquare };
        if (inCheckAfterMove(position, oneStepMove)) |inCheck| {
            if (getBoard(position, oneStepSquare) == null and !inCheck) {
                addMove(moves, oneStepMove);
                const twoStepSquare = Square{ .column = square.column, .row = square.row + 2 * oneStep };
                if (moveInBounds(twoStepSquare)) {
                    const twoStepMove = Move{ .from = square, .to = twoStepSquare };
                    const isStartingRow = if (position.turn == Color.White) square.row == 1 else square.row == 6;
                    if (getBoard(position, twoStepSquare) == null and isStartingRow and !inCheckAfterMove(position, twoStepMove)) {
                        addMove(moves, twoStepMove);
                    }
                }
            }
        }
    }

    const diagonalLeftSquare = Square{ .column = square.column - 1, .row = square.row + oneStep };
    if (moveInBounds(diagonalLeftSquare)) {
        const diagonalLeftMove = Move{ .from = square, .to = diagonalLeftSquare };
        if (getBoard(position, diagonalLeftSquare)) |targetPiece| {
            if (inCheckAfterMove(position, diagonalLeftMove)) |inCheck| {
                if (targetPiece.color != position.turn and !inCheck) {
                    addMove(moves, diagonalLeftMove);
                }
            }
        } else if (position.enPassantSquare) |enPassantTarget| {
            if (enPassantTarget.column == square.column - 1 and enPassantTarget.row == square.row + oneStep) {
                const leftPassant = Move{ .from = square, .to = diagonalLeftSquare };
                if (inCheckAfterMove(position, leftPassant)) |inCheck| {
                    if (!inCheck) {
                        addMove(moves, leftPassant);
                    }
                }
            }
        }
    }
    const diagonalRightSquare = Square{ .column = square.column + 1, .row = square.row + oneStep };
    if (moveInBounds(diagonalRightSquare)) {
        const diagonalRightMove = Move{ .from = square, .to = diagonalRightSquare };
        if (getBoard(position, diagonalRightSquare)) |targetPiece| {
            if (inCheckAfterMove(position, diagonalRightMove)) |inCheck| {
                if (targetPiece.color != position.turn and !inCheck) {
                    addMove(moves, diagonalRightMove);
                }
            }
        } else if (position.enPassantSquare) |enPassantTarget| {
            if (enPassantTarget.column == square.column + 1 and enPassantTarget.row == square.row + oneStep) {
                const rightPassant = Move{ .from = square, .to = diagonalRightSquare };
                if (inCheckAfterMove(position, rightPassant)) |inCheck| {
                    if (!inCheck) {
                        addMove(moves, rightPassant);
                    }
                }
            }
        }
    }
}

fn getKnightMoves(position: *Position, square: Square, moves: *Moves) void {
    for (PieceMoves.Knight) |knightMove| {
        const targetSquare = Square{ .column = square.column + knightMove.column, .row = square.row + knightMove.row };
        if (moveInBounds(targetSquare)) {
            const move = Move{ .from = square, .to = targetSquare };
            if (getBoard(position, targetSquare)) |targetPiece| {
                if (targetPiece.color == position.turn) {
                    continue;
                }
            }
            if (inCheckAfterMove(position, move)) |inCheck| {
                if (!inCheck) {
                    addMove(moves, move);
                }
            }
        }
    }
}

fn getBRQMoves(position: *Position, square: Square, moves: *Moves, pieceMoves: []const Step) void {
    for (pieceMoves) |pieceMove| {
        var targetSquare = Square{ .column = square.column + pieceMove.column, .row = square.row + pieceMove.row };
        while (moveInBounds(targetSquare)) {
            const move = Move{ .from = square, .to = targetSquare };
            if (inCheckAfterMove(position, move)) |inCheck| {
                if (!inCheck) {
                    if (getBoard(position, targetSquare)) |targetPiece| {
                        if (targetPiece.color != position.turn) {
                            addMove(moves, move);
                        }
                        break;
                    }
                    addMove(moves, move);
                    targetSquare = Square{ .column = targetSquare.column + pieceMove.column, .row = targetSquare.row + pieceMove.row };
                }
            }
        }
    }
}

fn getKingMoves(position: *Position, square: Square, moves: *Moves) void {
    for (PieceMoves.King) |kingMove| {
        const targetSquare = Square{ .column = square.column + kingMove.column, .row = square.row + kingMove.row };
        if (moveInBounds(targetSquare)) {
            const move = Move{ .from = square, .to = targetSquare };
            if (getBoard(position, targetSquare)) |targetPiece| {
                if (targetPiece.color == position.turn) {
                    continue;
                }
            }
            if (inCheckAfterMove(position, move)) |inCheck| {
                if (!inCheck) {
                    addMove(moves, move);
                }
            }
        }
    }
    if (!opponentGivesCheck(position)) {
        const canLongCastle = if (position.turn == Color.White) position.canWhiteLongCastle else position.canBlackLongCastle;
        if (canLongCastle) {
            const longRookSquare = Square{ .column = square.column - 4, .row = square.row };
            if (squaresBetweenEmpty(position, longRookSquare, square)) {
                const oneLeft = Move{ .from = square, .to = Square{ .column = square.column - 1, .row = square.row } };
                const longCastle = Move{ .from = square, .to = Square{ .column = square.column - 2, .row = square.row }, .castlingRookFrom = longRookSquare, .castlingRookTo = Square{ .column = longRookSquare.column + 3, .row = longRookSquare.row } };
                if (inCheckAfterMove(position, oneLeft)) |inCheckAfterLeft| {
                    if (inCheckAfterMove(position, longCastle)) |inCheckAfterLongCastle| {
                        if (!inCheckAfterLeft and !inCheckAfterLongCastle) {
                            addMove(moves, longCastle);
                        }
                    }
                }
            }
        }

        const canShortCastle = if (position.turn == Color.White) position.canWhiteShortCastle else position.canBlackShortCastle;
        if (canShortCastle) {
            const shortRookSquare = Square{ .column = square.column + 3, .row = square.row };
            if (squaresBetweenEmpty(position, square, shortRookSquare)) {
                const oneRight = Move{ .from = square, .to = Square{ .column = square.column + 1, .row = square.row } };
                const shortCastle = Move{ .from = square, .to = Square{ .column = square.column + 2, .row = square.row }, .castlingRookFrom = shortRookSquare, .castlingRookTo = Square{ .column = shortRookSquare.column - 2, .row = shortRookSquare.row } };
                if (!inCheckAfterMove(position, oneRight) and !inCheckAfterMove(position, shortCastle)) {
                    addMove(moves, shortCastle);
                }
            }
        }
    }
}
