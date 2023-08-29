const moveInBounds = @import("utils.zig").moveInBounds;
const squaresBetweenEmpty = @import("utils.zig").squaresBetweenEmpty;
const addMove = @import("utils.zig").addMove;
const getBoard = @import("utils.zig").getBoard;
const print = @import("std").debug.print;
const inCheckAfterMove = @import("check.zig").inCheckAfterMove;

pub const Type = enum { Pawn, Knight, Bishop, Rook, Queen, King };
pub const Color = enum { White, Black };
pub const Piece = struct { type: Type, color: Color };
pub const Board = [8][8]?Piece;

pub const Square = struct {
    column: i4,
    row: i4,
};

pub const Step = struct {
    column: i4,
    row: i4,
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
    var index: usize = 0;
    moves.iMove = &index;
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

pub fn getPieceMoves(position: *Position, square: Square, piece: Piece, moves: Moves) void {
    switch (piece.type) {
        Type.Pawn => return getPawnMoves(position, square, piece, moves),
        Type.Knight => return getKnightMoves(position, square, piece, moves),
        Type.Bishop => return getBRQMoves(position, square, piece, moves, PieceMoves.Bishop[0..]),
        Type.Rook => return getBRQMoves(position, square, piece, moves, PieceMoves.Rook[0..]),
        Type.Queen => return getBRQMoves(position, square, piece, moves, PieceMoves.Queen[0..]),
        Type.King => return getKingMoves(position, square, piece, moves),
    }
}

fn getPawnMoves(position: *Position, square: Square, piece: Piece, moves: Moves) void {
    const oneStep: i4 = if (position.turn == Color.White) 1 else -1;
    const oneStepSquare = Square{ .column = square.column, .row = square.row + oneStep };
    if (moveInBounds(oneStepSquare)) {
        const oneStepMove = Move{ .from = square, .to = oneStepSquare };
        if (getBoard(position, oneStepSquare) == null and !inCheckAfterMove(position, oneStepMove)) {
            addMove(moves, oneStepMove);
            const twoStep: i4 = if (position.moveManager.playerColor == Color.White) 2 else -2;
            const twoStepSquare = Square{ .column = square.column, .row = square.row + twoStep };
            if (moveInBounds(twoStepSquare)) {
                const twoStepMove = Move{ .from = square, .to = twoStepSquare };
                const isStartingRow = if (position.turn == Color.White) square.row == 1 else square.row == 6;
                if (getBoard(position, twoStepSquare) == null and isStartingRow and !inCheckAfterMove(position, twoStepMove)) {
                    addMove(moves, twoStepMove);
                }
            }
        }
    }

    const diagonalLeftSquare = Square{ .column = square.column - 1, .row = square.row + oneStep };
    if (moveInBounds(diagonalLeftSquare)) {
        const diagonalLeftMove = Move{ .from = square, .to = diagonalLeftSquare };
        if (getBoard(position, diagonalLeftSquare) ) |capturedPiece| {
            if (capturedPiece.color != position.moveManager.playerColor and !inCheckAfterMove(position, diagonalLeftMove)) {
                addMove(position, diagonalLeftMove);
            }
        } else if (position.moveManager.lastMove) |move| {
            const twoOppositeStep = -2 * oneStep;
            if (move.movingPiece.type == Type.Pawn and
                (square.column - 1) == move.to.column and
                (move.from.row + twoOppositeStep) == square.row)
            {
                const leftPassant = Move{ .from = square, .to = diagonalLeftSquare, .movingPiece = piece, .landingSquare = null, .enPassantSquare = move.to };
                if (!inCheckAfterMove(position, leftPassant)) {
                    addMove(position, leftPassant);
                }
            }
        }
    }
    const diagonalRightSquare = Square{ .column = square.column + 1, .row = square.row + oneStep };
    if (moveInBounds(diagonalRightSquare)) {
        const diagonalRightMove = Move{ .from = square, .to = diagonalRightSquare, .movingPiece = piece, .landingSquare = getBoard(position, diagonalRightSquare) };
        if (diagonalRightMove.landingSquare) |capturedPiece| {
            if (capturedPiece.color != position.moveManager.playerColor and !inCheckAfterMove(position, diagonalRightMove)) {
                addMove(position, diagonalRightMove);
            }
        } else if (position.moveManager.lastMove) |move| {
            const twoOppositeStep = -2 * oneStep;
            if (move.movingPiece.type == Type.Pawn and
                (square.column + 1) == move.to.column and
                (move.from.row + twoOppositeStep) == square.row)
            {
                const rightPassant = Move{ .from = square, .to = diagonalRightSquare, .movingPiece = piece, .landingSquare = null, .enPassantSquare = move.to };
                if (!inCheckAfterMove(position, rightPassant)) {
                    addMove(position, rightPassant);
                }
            }
        }
    }
}

fn getKnightMoves(self: *Position, square: Square, piece: Piece) void {
    for (PieceMoves.Knight) |knightMove| {
        const targetSquare = Square{ .column = square.column + knightMove.column, .row = square.row + knightMove.row };
        if (moveInBounds(targetSquare)) {
            const move = Move{ .from = square, .to = targetSquare, .movingPiece = piece, .landingSquare = getBoard(self, targetSquare) };
            if (move.landingSquare) |toPiece| {
                if (toPiece.color == self.moveManager.playerColor) {
                    continue;
                }
            }
            if (!inCheckAfterMove(self, move)) {
                addMove(self, move);
            }
        }
    }
}

fn getBRQMoves(self: *Position, square: Square, piece: Piece, pieceMoves: []const Step) void {
    for (pieceMoves) |pieceMove| {
        var targetSquare = Square{ .column = square.column + pieceMove.column, .row = square.row + pieceMove.row };
        while (moveInBounds(targetSquare)) {
            const move = Move{ .from = square, .to = targetSquare, .movingPiece = piece, .landingSquare = getBoard(self, targetSquare) };
            if (!inCheckAfterMove(self, move)) {
                if (move.landingSquare) |toPiece| {
                    if (toPiece.color != self.moveManager.playerColor) {
                        addMove(self, move);
                    }
                    break;
                }
                addMove(self, move);
                targetSquare = Square{ .column = targetSquare.column + pieceMove.column, .row = targetSquare.row + pieceMove.row };
            }
        }
    }
}

fn getKingMoves(self: *Position, square: Square, piece: Piece) void {
    for (PieceMoves.King) |kingMove| {
        const targetSquare = Square{ .column = square.column + kingMove.column, .row = square.row + kingMove.row };
        if (moveInBounds(targetSquare)) {
            const move = Move{ .from = square, .to = targetSquare, .movingPiece = piece, .landingSquare = getBoard(self, targetSquare) };
            if (move.landingSquare) |toPiece| {
                if (toPiece.color == self.moveManager.playerColor) {
                    continue;
                }
            }
            if (!inCheckAfterMove(self, move)) {
                addMove(self, move);
            }
        }
    }
    if (!piece.hasMoved) {
        const longRookSquare = Square{ .column = square.column - 4, .row = square.row };
        const possibleLongRook = getBoard(self, longRookSquare);
        if (possibleLongRook) |longRook| {
            if (longRook.type == Type.Rook and longRook.color == piece.color and !longRook.hasMoved and squaresBetweenEmpty(self, longRookSquare, square)) {
                const oneLeft = Move{ .from = square, .to = Square{ .column = square.column - 1, .row = square.row }, .movingPiece = piece, .landingSquare = null };
                const longCastle = Move{ .from = square, .to = Square{ .column = square.column - 2, .row = square.row }, .movingPiece = piece, .landingSquare = null, .castlingRookFrom = longRookSquare, .castlingRookTo = Square{ .column = longRookSquare.column + 3, .row = longRookSquare.row } };
                if (!inCheckAfterMove(self, oneLeft) and !inCheckAfterMove(self, longCastle)) {
                    addMove(self, longCastle);
                }
            }
        }
        const shortRookSquare = Square{ .column = square.column + 3, .row = square.row };
        const possibleShortRook = getBoard(self, shortRookSquare);
        if (possibleShortRook) |shortRook| {
            if (shortRook.type == Type.Rook and shortRook.color == piece.color and !shortRook.hasMoved and squaresBetweenEmpty(self, square, shortRookSquare)) {
                const oneRight = Move{ .from = square, .to = Square{ .column = square.column - 1, .row = square.row }, .movingPiece = piece, .landingSquare = null };
                const shortCastle = Move{ .from = square, .to = Square{ .column = square.column + 2, .row = square.row }, .movingPiece = piece, .landingSquare = null, .castlingRookFrom = shortRookSquare, .castlingRookTo = Square{ .column = shortRookSquare.column - 2, .row = shortRookSquare.row } };
                if (!inCheckAfterMove(self, oneRight) and !inCheckAfterMove(self, shortCastle)) {
                    addMove(self, shortCastle);
                }
            }
        }
    }
}
