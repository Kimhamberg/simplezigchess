const moveInBounds = @import("utils.zig").moveInBounds;
const squaresBetweenEmpty = @import("utils.zig").squaresBetweenEmpty;
const addMove = @import("utils.zig").addMove;
const getBoard = @import("utils.zig").getBoard;
const movePutsYouInCheck = @import("check.zig").movePutsYouInCheck;
const print = @import("std").debug.print;
const inCheckAfterMove = @import("check.zig").inCheckAfterMove;

pub const Type = enum { Pawn, Knight, Bishop, Rook, Queen, King };
pub const Color = enum { White, Black };
pub const Piece = struct { type: Type, color: Color };
pub const Board = [8][8]?Piece;

pub fn setupBoard(self: *MoveManager) void {
    self.board[0][0] = Piece{ .type = Type.Rook, .color = Color.White }; // a1
    self.board[0][1] = Piece{ .type = Type.Knight, .color = Color.White }; // b1
    self.board[0][2] = Piece{ .type = Type.Bishop, .color = Color.White }; // c1
    self.board[0][3] = Piece{ .type = Type.Queen, .color = Color.White }; // d1
    self.board[0][4] = Piece{ .type = Type.King, .color = Color.White }; // e1
    self.board[0][5] = Piece{ .type = Type.Bishop, .color = Color.White }; // f1
    self.board[0][6] = Piece{ .type = Type.Knight, .color = Color.White }; // g1
    self.board[0][7] = Piece{ .type = Type.Rook, .color = Color.White }; // h1

    self.board[1][0] = Piece{ .type = Type.Pawn, .color = Color.White };
    self.board[1][1] = Piece{ .type = Type.Pawn, .color = Color.White };
    self.board[1][2] = Piece{ .type = Type.Pawn, .color = Color.White };
    self.board[1][3] = Piece{ .type = Type.Pawn, .color = Color.White };
    self.board[1][4] = Piece{ .type = Type.Pawn, .color = Color.White };
    self.board[1][5] = Piece{ .type = Type.Pawn, .color = Color.White };
    self.board[1][6] = Piece{ .type = Type.Pawn, .color = Color.White };
    self.board[1][7] = Piece{ .type = Type.Pawn, .color = Color.White };

    self.board[2][0] = null;
    self.board[2][1] = null;
    self.board[2][2] = null;
    self.board[2][3] = null;
    self.board[2][4] = null;
    self.board[2][5] = null;
    self.board[2][6] = null;
    self.board[2][7] = null;

    self.board[3][0] = null;
    self.board[3][1] = null;
    self.board[3][2] = null;
    self.board[3][3] = null;
    self.board[3][4] = null;
    self.board[3][5] = null;
    self.board[3][6] = null;
    self.board[3][7] = null;

    self.board[4][0] = null;
    self.board[4][1] = null;
    self.board[4][2] = null;
    self.board[4][3] = null;
    self.board[4][4] = null;
    self.board[4][5] = null;
    self.board[4][6] = null;
    self.board[4][7] = null;

    self.board[5][0] = null;
    self.board[5][1] = null;
    self.board[5][2] = null;
    self.board[5][3] = null;
    self.board[5][4] = null;
    self.board[5][5] = null;
    self.board[5][6] = null;
    self.board[5][7] = null;

    self.board[6][0] = Piece{ .type = Type.Pawn, .color = Color.Black };
    self.board[6][1] = Piece{ .type = Type.Pawn, .color = Color.Black };
    self.board[6][2] = Piece{ .type = Type.Pawn, .color = Color.Black };
    self.board[6][3] = Piece{ .type = Type.Pawn, .color = Color.Black };
    self.board[6][4] = Piece{ .type = Type.Pawn, .color = Color.Black };
    self.board[6][5] = Piece{ .type = Type.Pawn, .color = Color.Black };
    self.board[6][6] = Piece{ .type = Type.Pawn, .color = Color.Black };
    self.board[6][7] = Piece{ .type = Type.Pawn, .color = Color.Black };

    self.board[7][0] = Piece{ .type = Type.Rook, .color = Color.Black }; // a8
    self.board[7][1] = Piece{ .type = Type.Knight, .color = Color.Black }; // b8
    self.board[7][2] = Piece{ .type = Type.Bishop, .color = Color.Black }; // c8
    self.board[7][3] = Piece{ .type = Type.Queen, .color = Color.Black }; // d8
    self.board[7][4] = Piece{ .type = Type.King, .color = Color.Black }; // e8
    self.board[7][5] = Piece{ .type = Type.Bishop, .color = Color.Black }; // f8
    self.board[7][6] = Piece{ .type = Type.Knight, .color = Color.Black }; // g8
    self.board[7][7] = Piece{ .type = Type.Rook, .color = Color.Black }; // h8
}

pub const Square = struct {
    column: i64,
    row: i64,
};

pub const Step = struct {
    column: i64,
    row: i64,
};

pub const PieceMoves = struct {
    const Knight = [8]Step{
        Step{ .column = -1, .row = 2 }, // UUL
        Step{ .column = 1, .row = 2 }, // UUR
        Step{ .column = -2, .row = 1 }, // LLU
        Step{ .column = 2, .row = 1 }, // RRU
        Step{ .column = -2, .row = -1 }, // LLD
        Step{ .column = 2, .row = -1 }, // RRD
        Step{ .column = -1, .row = -2 }, // DDL
        Step{ .column = 1, .row = -2 }, // DDR
    };
    const Bishop = [4]Step{
        Step{ .column = -1, .row = 1 }, // UL
        Step{ .column = 1, .row = 1 }, // UR
        Step{ .column = -1, .row = -1 }, // DL
        Step{ .column = 1, .row = -1 }, // DR
    };
    const Rook = [4]Step{
        Step{ .column = -1, .row = 0 }, // L
        Step{ .column = 1, .row = 0 }, // R
        Step{ .column = 0, .row = 1 }, // U
        Step{ .column = 0, .row = -1 }, // D
    };
    const Queen = [8]Step{
        Step{ .column = -1, .row = 1 }, // UL
        Step{ .column = 1, .row = 1 }, // UR
        Step{ .column = -1, .row = -1 }, // DL
        Step{ .column = 1, .row = -1 }, // DR
        Step{ .column = -1, .row = 0 }, // L
        Step{ .column = 1, .row = 0 }, // R
        Step{ .column = 0, .row = 1 }, // U
        Step{ .column = 0, .row = -1 }, // D
    };
    const King = [8]Step{
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
    movingPiece: Piece,
    landingSquare: ?Piece,
    castlingRookFrom: ?Square = null,
    castlingRookTo: ?Square = null,
    enPassantSquare: ?Square = null,
};

pub const MoveManager = struct {
    playerColor: Color,
    playerMoves: [256]Move,
    iMove: *usize,
    lastMove: ?Move = null,
};

pub const GameState = struct {
    board: Board,
    toMove: Color,
    canWhiteShortCastle: bool,
    canWhiteLongCastle: bool,
    canBlackShortCastle: bool,
    canBlackLongCastle: bool,
    enPassantSquare: ?Square = null,
    halfMoveClock: usize,
    fullMoveNumber: usize,
    moveManager: MoveManager,
};

pub fn getPlayerMoves(self: *MoveManager) void {
    var index: usize = 0;
    self.iMove = &index;
    for (self.board, 0..) |row, iRow| {
        for (row, 0..) |possiblePiece, iColumn| {
            if (possiblePiece) |piece| {
                if (piece.color == self.playerColor) {
                    getPieceMoves(self, Square{ .column = @intCast(iColumn), .row = @intCast(iRow) }, piece);
                }
            }
        }
    }
}

pub fn getPieceMoves(self: *MoveManager, square: Square, piece: Piece) void {
    switch (piece.type) {
        Type.Pawn => return getPawnMoves(self, square, piece),
        Type.Knight => return getKnightMoves(self, square, piece),
        Type.Bishop => return getBRQMoves(self, square, piece, PieceMoves.Bishop[0..]),
        Type.Rook => return getBRQMoves(self, square, piece, PieceMoves.Rook[0..]),
        Type.Queen => return getBRQMoves(self, square, piece, PieceMoves.Queen[0..]),
        Type.King => return getKingMoves(self, square, piece),
    }
}

fn getPawnMoves(self: *MoveManager, square: Square, piece: Piece) void {
    const oneStep: i64 = if (self.playerColor == Color.White) 1 else -1;
    const oneStepSquare = Square{ .column = square.column, .row = square.row + oneStep };
    if (moveInBounds(oneStepSquare)) {
        const oneStepMove = Move{ .from = square, .to = oneStepSquare, .movingPiece = piece, .landingSquare = getBoard(self, oneStepSquare) };
        if (oneStepMove.landingSquare == null and !inCheckAfterMove(self, oneStepMove)) {
            addMove(self, oneStepMove);
            const twoStep: i64 = if (self.playerColor == Color.White) 2 else -2;
            const twoStepSquare = Square{ .column = square.column, .row = square.row + twoStep };
            if (moveInBounds(twoStepSquare)) {
                const twoStepMove = Move{ .from = square, .to = twoStepSquare, .movingPiece = piece, .landingSquare = getBoard(self, twoStepSquare) };
                const isStartingRow = if (self.playerColor == Color.White) square.row == 1 else square.row == 6;
                if (twoStepMove.landingSquare == null and isStartingRow and !inCheckAfterMove(self, twoStepMove)) {
                    addMove(self, twoStepMove);
                }
            }
        }
    }

    const diagonalLeftSquare = Square{ .column = square.column - 1, .row = square.row + oneStep };
    if (moveInBounds(diagonalLeftSquare)) {
        const diagonalLeftMove = Move{ .from = square, .to = diagonalLeftSquare, .movingPiece = piece, .landingSquare = getBoard(self, diagonalLeftSquare) };
        if (diagonalLeftMove.landingSquare) |capturedPiece| {
            if (capturedPiece.color != self.playerColor and !inCheckAfterMove(self, diagonalLeftMove)) {
                addMove(self, diagonalLeftMove);
            }
        } else if (self.lastMove) |move| {
            const twoOppositeStep = -2 * oneStep;
            if (move.movingPiece.type == Type.Pawn and
                (square.column - 1) == move.to.column and
                (move.from.row + twoOppositeStep) == square.row)
            {
                const leftPassant = Move{ .from = square, .to = diagonalLeftSquare, .movingPiece = piece, .landingSquare = null, .enPassantSquare = move.to };
                if (!inCheckAfterMove(self, leftPassant)) {
                    addMove(self, leftPassant);
                }
            }
        }
    }
    const diagonalRightSquare = Square{ .column = square.column + 1, .row = square.row + oneStep };
    if (moveInBounds(diagonalRightSquare)) {
        const diagonalRightMove = Move{ .from = square, .to = diagonalRightSquare, .movingPiece = piece, .landingSquare = getBoard(self, diagonalRightSquare) };
        if (diagonalRightMove.landingSquare) |capturedPiece| {
            if (capturedPiece.color != self.playerColor and !inCheckAfterMove(self, diagonalRightMove)) {
                addMove(self, diagonalRightMove);
            }
        } else if (self.lastMove) |move| {
            const twoOppositeStep = -2 * oneStep;
            if (move.movingPiece.type == Type.Pawn and
                (square.column + 1) == move.to.column and
                (move.from.row + twoOppositeStep) == square.row)
            {
                const rightPassant = Move{ .from = square, .to = diagonalRightSquare, .movingPiece = piece, .landingSquare = null, .enPassantSquare = move.to };
                if (!inCheckAfterMove(self, rightPassant)) {
                    addMove(self, rightPassant);
                }
            }
        }
    }
}

fn getKnightMoves(self: *MoveManager, square: Square, piece: Piece) void {
    for (PieceMoves.Knight) |knightMove| {
        const targetSquare = Square{ .column = square.column + knightMove.column, .row = square.row + knightMove.row };
        if (moveInBounds(targetSquare)) {
            const move = Move{ .from = square, .to = targetSquare, .movingPiece = piece, .landingSquare = getBoard(self, targetSquare) };
            if (move.landingSquare) |toPiece| {
                if (toPiece.color == self.playerColor) {
                    continue;
                }
            }
            if (!movePutsYouInCheck(self, move)) {
                addMove(self, move);
            }
        }
    }
}

fn getBRQMoves(self: *MoveManager, square: Square, piece: Piece, pieceMoves: []const Step) void {
    for (pieceMoves) |pieceMove| {
        var targetSquare = Square{ .column = square.column + pieceMove.column, .row = square.row + pieceMove.row };
        while (moveInBounds(targetSquare)) {
            const move = Move{ .from = square, .to = targetSquare, .movingPiece = piece, .landingSquare = getBoard(self, targetSquare) };
            if (!movePutsYouInCheck(self, move)) {
                if (move.landingSquare) |toPiece| {
                    if (toPiece.color != self.playerColor) {
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

fn getKingMoves(self: *MoveManager, square: Square, piece: Piece) void {
    for (PieceMoves.King) |kingMove| {
        const targetSquare = Square{ .column = square.column + kingMove.column, .row = square.row + kingMove.row };
        if (moveInBounds(targetSquare)) {
            const move = Move{ .from = square, .to = targetSquare, .movingPiece = piece, .landingSquare = getBoard(self, targetSquare) };
            if (move.landingSquare) |toPiece| {
                if (toPiece.color == self.playerColor) {
                    continue;
                }
            }
            if (!movePutsYouInCheck(self, move)) {
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
                if (!movePutsYouInCheck(self, oneLeft) and !movePutsYouInCheck(self, longCastle)) {
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
                if (!movePutsYouInCheck(self, oneRight) and !movePutsYouInCheck(self, shortCastle)) {
                    addMove(self, shortCastle);
                }
            }
        }
    }
}
