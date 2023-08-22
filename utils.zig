const Piece = @import("generation.zig").Piece;
const Move = @import("generation.zig").Move;
const Square = @import("generation.zig").Square;
const Step = @import("generation.zig").Step;
const Type = @import("generation.zig").Type;
const Color = @import("generation.zig").Color;
const MoveGenerator = @import("generation.zig").MoveManager;

pub fn oppositeColor(color: Color) Color {
    switch (color) {
        Color.Black => return Color.White,
        Color.White => return Color.Black,
    }
}

pub fn pieceIsMyKing(self: *MoveGenerator, piece: Piece) bool {
    return (piece.color == self.playerColor and piece.type == Type.King);
}

pub fn moveInBounds(square: Square) bool {
    return (0 <= square.column and square.column <= 7) and (0 <= square.row and square.row <= 7);
}

pub fn squareToNotation(square: Square) [2]u8 {
    const letters: []const u8 = "abcdefgh";
    var coordinate: [2]u8 = undefined;
    coordinate[0] = letters[@intCast(square.column)];
    coordinate[1] = '1' + @as(u8, @intCast(square.row));

    return coordinate;
}

// left-to-right
pub fn squaresBetweenEmpty(self: *MoveGenerator, from: Square, to: Square) bool {
    var iColumn = from.column + 1;
    while (iColumn < to.column) : (iColumn += 1) {
        if (self.board[@intCast(from.row)][@intCast(iColumn)] != null) {
            return false;
        }
    }
    return true;
}

pub fn addMove(self: *MoveGenerator, move: Move) void {
    self.playerMoves[self.iMove.*] = move;
    self.iMove.* += 1;
}

pub fn undoMove(self: *MoveGenerator, move: Move) void {
    movePiece(self, move.to, move.from, move.movingPiece);
    setBoard(self, move.to, move.landingSquare);
    if (move.castlingRookFrom) |castleFrom| {
        if (move.castlingRookTo) |castleTo| {
            movePiece(self, castleTo, castleFrom, Piece{ .type = Type.Rook, .color = self.playerColor });
        }
    }
    if (move.enPassantSquare) |capturedSquare| {
        setBoard(self, capturedSquare, Piece{ .type = Type.Pawn, .color = oppositeColor(self.playerColor) });
    }
}

pub fn makeMove(self: *MoveGenerator, move: Move) void {
    movePiece(self, move.from, move.to, move.movingPiece);
    if (move.castlingRookFrom) |castleFrom| {
        if (move.castlingRookTo) |castleTo| {
            movePiece(self, castleFrom, castleTo, getBoard(self, castleFrom));
        }
    }
    if (move.enPassantSquare) |capturedSquare| {
        setBoard(self, capturedSquare, null);
    }
}

fn movePiece(self: *MoveGenerator, from: Square, to: Square, piece: Piece) void {
    self.board[@intCast(to.row)][@intCast(to.column)] = piece;
    self.board[@intCast(from.row)][@intCast(from.column)] = null;
}

fn setBoard(self: *MoveGenerator, square: Square, piece: ?Piece) void {
    self.board[@intCast(square.row)][@intCast(square.column)] = piece;
}

pub fn getBoard(self: *MoveGenerator, square: Square) ?Piece {
    return self.board[@intCast(square.row)][@intCast(square.column)];
}

pub fn setupFromFEN(self: *MoveGenerator, fen: []const u8) void {
    var iRow: usize = 7;
    var iColumn: usize = 0;

    var iFEN: usize = 0;
    while (fen[iFEN] != ' ' and iFEN < fen.len) {
        switch (fen[iFEN]) {
            '1'...'8' => {
                const skip = fen[iFEN] - '0';
                for (0..skip) |_| {
                    self.board[iRow][iColumn] = null;
                    iColumn += 1;
                }
            },
            'r' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Rook, .color = Color.Black };
                iColumn += 1;
            },
            'n' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Knight, .color = Color.Black };
                iColumn += 1;
            },
            'b' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Bishop, .color = Color.Black };
                iColumn += 1;
            },
            'q' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Queen, .color = Color.Black };
                iColumn += 1;
            },
            'k' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.King, .color = Color.Black };
                iColumn += 1;
            },
            'p' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Pawn, .color = Color.Black };
                iColumn += 1;
            },
            'R' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Rook, .color = Color.White };
                iColumn += 1;
            },
            'N' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Knight, .color = Color.White };
                iColumn += 1;
            },
            'B' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Bishop, .color = Color.White };
                iColumn += 1;
            },
            'Q' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Queen, .color = Color.White };
                iColumn += 1;
            },
            'K' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.King, .color = Color.White };
                iColumn += 1;
            },
            'P' => {
                self.board[iRow][iColumn] = Piece{ .type = Type.Pawn, .color = Color.White };
                iColumn += 1;
            },
            '/' => {
                iRow -= 1;
                iColumn = 0;
            },
            else => unreachable,
        }
        iFEN += 1;
    }

    // Optionally, you can also handle other parts of FEN such as the active color, castling availability, en passant target square, half-move clock, and full-move number.
}
