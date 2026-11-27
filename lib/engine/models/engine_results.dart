import 'game_move.dart';
import 'game_state.dart';

/// Typed failure reasons for move validation and execution.
enum MoveError {
  gameAlreadyFinished,
  pieceNotFound,
  pieceCaptured,
  notCurrentTurn,
  targetPositionNotFound,
  samePosition,
  notAdjacent,
  targetOccupied,
}

/// Result returned by [GameEngine.makeMove].
class MoveResult {
  const MoveResult._({
    required this.isSuccess,
    required this.state,
    this.move,
    this.error,
    this.errorMessage,
  });

  factory MoveResult.success({
    required GameState state,
    required GameMove move,
  }) {
    return MoveResult._(
      isSuccess: true,
      state: state,
      move: move,
    );
  }

  factory MoveResult.failure({
    required GameState state,
    required MoveError error,
    required String errorMessage,
  }) {
    return MoveResult._(
      isSuccess: false,
      state: state,
      error: error,
      errorMessage: errorMessage,
    );
  }

  final bool isSuccess;
  final GameState state;
  final GameMove? move;
  final MoveError? error;
  final String? errorMessage;
}

/// Result returned by [GameEngine.undoMove].
class UndoResult {
  const UndoResult._({
    required this.isSuccess,
    required this.state,
    this.undoneMove,
    this.errorMessage,
  });

  factory UndoResult.success({
    required GameState state,
    required GameMove undoneMove,
  }) {
    return UndoResult._(
      isSuccess: true,
      state: state,
      undoneMove: undoneMove,
    );
  }

  factory UndoResult.failure({
    required GameState state,
    required String errorMessage,
  }) {
    return UndoResult._(
      isSuccess: false,
      state: state,
      errorMessage: errorMessage,
    );
  }

  final bool isSuccess;
  final GameState state;
  final GameMove? undoneMove;
  final String? errorMessage;
}

/// Represents a legal candidate move `(pieceId -> targetPositionId)` for AI or UI helpers.
class MoveCandidate {
  const MoveCandidate({
    required this.pieceId,
    required this.targetPositionId,
  });

  final String pieceId;
  final String targetPositionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoveCandidate &&
          other.pieceId == pieceId &&
          other.targetPositionId == targetPositionId);

  @override
  int get hashCode => Object.hash(pieceId, targetPositionId);

  @override
  String toString() => 'MoveCandidate($pieceId -> $targetPositionId)';
}

