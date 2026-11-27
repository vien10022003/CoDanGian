import 'player_side.dart';

/// Immutable record of a single executed move in the game history.
class GameMove {
  GameMove({
    required this.moveNumber,
    required this.pieceId,
    required this.player,
    required this.fromPositionId,
    required this.toPositionId,
    List<String> capturedPieceIds = const <String>[],
    required this.previousTurn,
    this.previousChainPieceId,
  }) : capturedPieceIds = List.unmodifiable(capturedPieceIds);

  /// 1-based sequential move number.
  final int moveNumber;

  /// ID of the piece that moved.
  final String pieceId;

  /// Side that executed this move.
  final PlayerSide player;

  /// Origin board position ID.
  final String fromPositionId;

  /// Destination board position ID.
  final String toPositionId;

  /// Piece IDs captured as a result of this move.
  final List<String> capturedPieceIds;

  /// Turn active prior to this move (restored on undo).
  final PlayerSide previousTurn;

  /// Piece locked into a multi-capture chain prior to this move, or null.
  final String? previousChainPieceId;

  /// True if at least one opponent piece was captured during this move.
  bool get isCapture => capturedPieceIds.isNotEmpty;

  /// True if this move continued an active multi-capture chain.
  bool get isChainContinuation => previousChainPieceId != null;

  factory GameMove.fromJson(Map<String, dynamic> json) {
    return GameMove(
      moveNumber: json['moveNumber'] as int,
      pieceId: json['pieceId'] as String,
      player: PlayerSide.fromJson(json['player']),
      fromPositionId: json['fromPositionId'] as String,
      toPositionId: json['toPositionId'] as String,
      capturedPieceIds: (json['capturedPieceIds'] as List<dynamic>? ?? const [])
          .cast<String>(),
      previousTurn: PlayerSide.fromJson(json['previousTurn']),
      previousChainPieceId: json['previousChainPieceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'moveNumber': moveNumber,
        'pieceId': pieceId,
        'player': player.toJson(),
        'fromPositionId': fromPositionId,
        'toPositionId': toPositionId,
        'capturedPieceIds': capturedPieceIds,
        'previousTurn': previousTurn.toJson(),
        'previousChainPieceId': previousChainPieceId,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GameMove) return false;
    if (moveNumber != other.moveNumber ||
        pieceId != other.pieceId ||
        player != other.player ||
        fromPositionId != other.fromPositionId ||
        toPositionId != other.toPositionId ||
        previousTurn != other.previousTurn ||
        previousChainPieceId != other.previousChainPieceId ||
        capturedPieceIds.length != other.capturedPieceIds.length) {
      return false;
    }
    for (var i = 0; i < capturedPieceIds.length; i++) {
      if (capturedPieceIds[i] != other.capturedPieceIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        moveNumber,
        pieceId,
        player,
        fromPositionId,
        toPositionId,
        previousTurn,
        previousChainPieceId,
        Object.hashAll(capturedPieceIds),
      );

  @override
  String toString() =>
      'GameMove(#$moveNumber ${player.id}: $pieceId $fromPositionId -> $toPositionId, captured: $capturedPieceIds)';
}
