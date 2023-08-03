const Piece = @import("generation.zig").Piece;
const Move = @import("generation.zig").Move;
const Square = @import("generation.zig").Square;
const Step = @import("generation.zig").Step;
const Type = @import("generation.zig").Type;
const Color = @import("generation.zig").Color;
const MoveGenerator = @import("generation.zig").MoveGenerator;

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

pub fn getBoard(self: *MoveGenerator, square: Square) Square {
    return self.board[@intCast(square.row)][@intCast(square.column)];
}
