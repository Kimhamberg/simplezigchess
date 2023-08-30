const Piece = @import("generation.zig").Piece;
const Move = @import("generation.zig").Move;
const Square = @import("generation.zig").Square;
const Step = @import("generation.zig").Step;
const Type = @import("generation.zig").Type;
const Color = @import("generation.zig").Color;
const Board = @import("generation.zig").Board;
const Position = @import("generation.zig").Position;
const Moves = @import("generation.zig").Moves;
const inCheckAfterMove = @import("check.zig").inCheckAfterMove;
const split = @import("std").mem.split;
const parseInt = @import("std").fmt.parseInt;


fn addCastlingMove(position: Position, square: Square, direction: i32) void {
    const rookSquare = Square{ .column = square.column + direction * 4, .row = square.row };
    if (getBoard(position, rookSquare)) |rook| {
        if (rook.type == Type.Rook and squaresBetweenEmpty(position, rookSquare, square)) {
            const oneStep = Move{ .from = square, .to = Square{ .column = square.column + direction, .row = square.row }};
            const castle = Move{ .from = square, .to = Square{ .column = square.column + direction * 2, .row = square.row }, .castlingRookFrom = rookSquare, .castlingRookTo = Square{ .column = rookSquare.column - direction * 2, .row = rookSquare.row }};
            if (!inCheckAfterMove(position, oneStep) and !inCheckAfterMove(position, castle)) {
                addMove(position, castle);
            }
        }
    }
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
pub fn squaresBetweenEmpty(self: *Position, from: Square, to: Square) bool {
    var iColumn = from.column + 1;
    while (iColumn < to.column) : (iColumn += 1) {
        if (self.board[@intCast(from.row)][@intCast(iColumn)] != null) {
            return false;
        }
    }
    return true;
}

pub fn addMove(moves: *Moves, move: Move) void {
    moves.playerMoves[moves.iMove.*] = move;
    moves.iMove.* += 1;
}

pub fn undoMove(self: *Position, move: Move) void {
    movePiece(self, move.to, move.from, move.movingPiece);
    setBoard(self, move.to, move.landingSquare);
    if (move.castlingRookFrom) |castleFrom| {
        if (move.castlingRookTo) |castleTo| {
            movePiece(self, castleTo, castleFrom, Piece{ .type = Type.Rook, .color = self.moveManager.playerColor });
        }
    }
    if (move.enPassantSquare) |capturedSquare| {
        setBoard(self, capturedSquare, Piece{ .type = Type.Pawn, .color = oppositeColor(self.moveManager.playerColor) });
    }
}

pub fn makeMove(self: *Position, move: Move) void {
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

fn movePiece(self: *Position, from: Square, to: Square, piece: Piece) void {
    self.board[@intCast(to.row)][@intCast(to.column)] = piece;
    self.board[@intCast(from.row)][@intCast(from.column)] = null;
}

fn setBoard(self: *Position, square: Square, piece: ?Piece) void {
    self.board[@intCast(square.row)][@intCast(square.column)] = piece;
}

pub fn getBoard(self: *Position, square: Square) ?Piece {
    return self.board[@intCast(square.row)][@intCast(square.column)];
}

fn pieceFromChar(char: u8) ?Piece {
    switch (char) {
        'p' => return Piece{ .type = Type.Pawn, .color = Color.Black },
        'r' => return Piece{ .type = Type.Rook, .color = Color.Black },
        'n' => return Piece{ .type = Type.Knight, .color = Color.Black },
        'b' => return Piece{ .type = Type.Bishop, .color = Color.Black },
        'q' => return Piece{ .type = Type.Queen, .color = Color.Black },
        'k' => return Piece{ .type = Type.King, .color = Color.Black },
        'P' => return Piece{ .type = Type.Pawn, .color = Color.White },
        'R' => return Piece{ .type = Type.Rook, .color = Color.White },
        'N' => return Piece{ .type = Type.Knight, .color = Color.White },
        'B' => return Piece{ .type = Type.Bishop, .color = Color.White },
        'Q' => return Piece{ .type = Type.Queen, .color = Color.White },
        'K' => return Piece{ .type = Type.King, .color = Color.White },
        else => return null,
    }
}

fn squareFromString(string: []const u8) Square {
    return Square{ .column = @intCast(string[0] - 'a'), .row = @intCast(string[1] - '1') };
}

fn indexOf(slice: []const u8, char: u8) ?usize {
    var index: usize = 0;
    for (slice) |element| {
        if (element == char) {
            return index;
        }
        index += 1;
    }
    return null;
}

pub fn gameFromFEN(fen: []const u8) Position {
    var partsIterator = split(u8, fen, " ");
    var parts: [6][]const u8 = undefined;
    var index: usize = 0;
    while (partsIterator.next()) |part| {
        parts[index] = part;
        index += 1;
    }
    var board: Board = undefined;
    var ranksIterator = split(u8, parts[0], "/");
    var row: usize = 0;
    while (ranksIterator.next()) |rank| {
        var column: usize = 0;
        for (rank) |char| {
            switch (char) {
                'p', 'r', 'n', 'b', 'q', 'k', 'P', 'R', 'N', 'B', 'Q', 'K' => {
                    board[row][column] = pieceFromChar(char);
                    column += 1;
                },
                '1'...'8' => {
                    const emptySquares = char - '0';
                    column += emptySquares;
                },
                else => {},
            }
        }
        row += 1;
    }
    const toMove: Color = if (parts[1][0] == 'w') Color.White else Color.Black;
    const canWhiteShortCastle: bool = indexOf(parts[2], 'K') != null;
    const canWhiteLongCastle: bool = indexOf(parts[2], 'Q') != null;
    const canBlackShortCastle: bool = indexOf(parts[2], 'k') != null;
    const canBlackLongCastle: bool = indexOf(parts[2], 'q') != null;
    const enPassantSquare: ?Square = if (parts[3][0] != '-') squareFromString(parts[3]) else null;
    const halfMoveClock: usize = @as(usize, @intCast(parseInt(i64, parts[4], 10)));
    const fullMoveNumber: usize = @as(usize, @intCast(parseInt(i64, parts[5], 10)));
    return Position{
        .board = board,
        .toMove = toMove,
        .canWhiteShortCastle = canWhiteShortCastle,
        .canWhiteLongCastle = canWhiteLongCastle,
        .canBlackShortCastle = canBlackShortCastle,
        .canBlackLongCastle = canBlackLongCastle,
        .enPassantSquare = enPassantSquare,
        .halfMoveClock = halfMoveClock,
        .fullMoveNumber = fullMoveNumber,
    };
}
