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
const Error = @import("error.zig").Error;

pub fn squareDifferent(square1: Square, square2: Square) bool {
    return (square1.row != square2.row or square1.column != square2.column);
}

pub fn moveCount(moves: *Moves) Error!usize {
    var count: usize = 0;
    if (moves == null) {
        return Error.MovesNull;
    }
    for (moves.playerMoves) |playerMove| {
        count += if (squareDifferent(playerMove.from, playerMove.to)) 1 else 0;
    }
    return count;
}

pub fn pieceIsMyKing(position: *Position, piece: Piece) Error!bool {
    if (position == null) {
        return Error.PositionNull;
    }
    return (position.turn == piece.color and piece.type == Type.King);
}

pub fn moveInBounds(square: Square) bool {
    return (0 <= square.column and square.column <= 7) and (0 <= square.row and square.row <= 7);
}

pub fn squareToNotation(square: Square) Error![2]u8 {
    if (!moveInBounds(square)) {
        return Error.OutOfBounds;
    }
    const letters: []const u8 = "abcdefgh";
    var coordinate: [2]u8 = undefined;
    coordinate[0] = letters[@intCast(square.column)];
    coordinate[1] = '1' + @as(u8, @intCast(square.row));
    return coordinate;
}

// left-to-right
pub fn squaresBetweenEmpty(self: *Position, from: Square, to: Square) Error!bool {
    if (!moveInBounds(from) or !moveInBounds(to)) {
        return Error.OutOfBounds;
    }

    if (from.row != to.row) {
        return Error.NotInSameRow;
    }
    var iColumn = from.column + 1;
    while (iColumn < to.column) : (iColumn += 1) {
        if (self.board[@intCast(from.row)][@intCast(iColumn)] != null) {
            return false;
        }
    }
    return true;
}

pub fn addMove(moves: *Moves, move: Move) Error!void {
    if (moves.iMove.* >= moves.playerMoves.len) {
        return Error.OutOfBounds;
    }
    moves.playerMoves[moves.iMove.*] = move;
    moves.iMove.* += 1;
}

fn oppositeColor(color: Color) Color {
    if (color == Color.White) {
        return Color.Black;
    }
    return Color.White;
}

pub fn undoMove(position: *Position, oldPosition: *Position) Error!void {
    if (position == null or oldPosition == null) {
        return Error.PositionNull;
    }
    position.board = oldPosition.board;
    position.turn = oldPosition.turn;
    position.canWhiteShortCastle = oldPosition.canWhiteShortCastle;
    position.canWhiteLongCastle = oldPosition.canWhiteLongCastle;
    position.canBlackShortCastle = oldPosition.canBlackShortCastle;
    position.canBlackLongCastle = oldPosition.canBlackLongCastle;
    position.enPassantSquare = oldPosition.enPassantSquare;
    position.halfMoveClock = oldPosition.halfMoveClock;
    position.fullMoveNumber = oldPosition.fullMoveNumber;
}

pub fn makeMove(position: *Position, move: Move) Error!*Position {
    if (position == null) {
        return Error.PositionNull;
    }
    const oldPosition = position;

    try movePiece(position, move.from, move.to);

    if (move.castlingRookFrom) |castleFrom| {
        if (move.castlingRookTo) |castleTo| {
            try movePiece(position, castleFrom, castleTo);
        }
    }

    if (position.enPassantSquare) |enPassantSquare| {
        if (move.to.row == enPassantSquare.row and move.to.column == enPassantSquare.column) {
            const oneStep: i64 = if (position.turn == Color.White) -1 else 1;
            try setBoard(position, Square{ .row = enPassantSquare.row + oneStep, .column = enPassantSquare.column }, null);
        }
    }

    return oldPosition;
}

fn movePiece(position: *Position, from: Square, to: Square) Error!void {
    if (position == null) {
        return Error.PositionNull;
    }

    if (!moveInBounds(from) or !moveInBounds(to)) {
        return Error.OutOfBounds;
    }

    position.board[@intCast(to.row)][@intCast(to.column)] = getBoard(position, from);
    position.board[@intCast(from.row)][@intCast(from.column)] = null;
}

fn setBoard(position: *Position, square: Square, piece: ?Piece) !void {
        if (position == null) {
        return Error.NullPosition;
    }

    if (!moveInBounds(square)) {
        return Error.InvalidSquare;
    }

    position.board[@intCast(square.row)][@intCast(square.column)] = piece;
}

pub fn getBoard(position: *Position, square: Square) ?Piece {
    return position.board[@intCast(square.row)][@intCast(square.column)];
}

fn pieceFromChar(char: u8) Error!?Piece {
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
        else => return Error.CharInvalid,
    }
}

fn squareFromString(string: []const u8) Error!Square {
    if (string.len != 2) {
        return Error.InvalidInputLength;
    }
    const column = string[0] - 'a';
    const row = string[1] - '1';

    if (column < 0 or column > 7 or row < 0 or row > 7) {
        return Error.InvalidSquareRepresentation;
    }
    return Square{ .column = @intCast(column), .row = @intCast(row)};
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

pub fn positionFromFEN(fen: []const u8) Error!Position {
    var partsIterator = split(u8, fen, " ");
    var parts: [6][]const u8 = undefined;
    var index: usize = 0;
    while (partsIterator.next()) |part| {
        if (index >= 6) {
            return Error.InvalidFenParts;
        }
        parts[index] = part;
        index += 1;
    }
    if (index != 6) {
        return Error.InvalidFenParts;
    }

    var board: Board = undefined;
    var ranksIterator = split(u8, parts[0], "/");
    var row: usize = 0;
    while (ranksIterator.next()) |rank| {
        var column: usize = 0;
        for (rank) |char| {
            switch (char) {
                'p', 'r', 'n', 'b', 'q', 'k', 'P', 'R', 'N', 'B', 'Q', 'K' => {
                    if (column >= 8) {
                        return Error.InvalidBoardSetup;
                    }
                    board[row][column] = pieceFromChar(char) orelse return Error.InvalidBoardSetup;
                    column += 1;
                },
                '1'...'8' => {
                    const emptySquares = char - '0';
                    column += emptySquares;
                },
                else => return Error.InvalidBoardSetup,
            }
        }
        row += 1;
    }
    if (row != 8) {
        return Error.InvalidBoardSetup;
    }

    const turn: Color = switch (parts[1][0]) {
        'w' => Color.White,
        'b' => Color.Black,
        else => return Error.InvalidTurnCharacter,
    };

    const canWhiteShortCastle: bool = indexOf(parts[2], 'K') != null;
    const canWhiteLongCastle: bool = indexOf(parts[2], 'Q') != null;
    const canBlackShortCastle: bool = indexOf(parts[2], 'k') != null;
    const canBlackLongCastle: bool = indexOf(parts[2], 'q') != null;

    const enPassantSquare: ?Square = if (parts[3][0] != '-') squareFromString(parts[3]) else null;

    const parsedHalfMoveClock = parseInt(i64, parts[4], 10) catch return Error.InvalidHalfMoveClock;
    const halfMoveClock: usize = @as(usize, @intCast(parsedHalfMoveClock));

    const parsedFullMoveNumber = parseInt(i64, parts[5], 10) catch return Error.InvalidFullMoveNumber;
    const fullMoveNumber: usize = @as(usize, @intCast(parsedFullMoveNumber));

    return Position{
        .board = board,
        .turn = turn,
        .canWhiteShortCastle = canWhiteShortCastle,
        .canWhiteLongCastle = canWhiteLongCastle,
        .canBlackShortCastle = canBlackShortCastle,
        .canBlackLongCastle = canBlackLongCastle,
        .enPassantSquare = enPassantSquare,
        .halfMoveClock = halfMoveClock,
        .fullMoveNumber = fullMoveNumber,
    };
}
