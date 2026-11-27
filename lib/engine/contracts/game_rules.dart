import '../models/engine_results.dart';
import '../models/game_move.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player_side.dart';

/// Strategy hook for pre-move jump captures, post-move flanking captures,
/// and multi-capture chain continuation.
abstract interface class CaptureRule {
  /// Returns jump-over-opponent capture options available to [piece] in [state].
  List<CaptureMoveOption> getJumpCaptureOptions(
    GameState state,
    GamePiece piece,
  );

  /// Returns IDs of additional enemy pieces captured after [pendingMove] lands
  /// (used for flanking/trap rules such as Cờ Gánh).
  List<String> resolveCaptures(GameState stateAfterMove, GameMove move);

  /// Whether a capturing piece must keep jumping while captures remain.
  bool get supportsMultiCaptureChain;
}

/// Capture rule that performs no captures and no chaining.
class NoOpCaptureRule implements CaptureRule {
  const NoOpCaptureRule();

  @override
  List<CaptureMoveOption> getJumpCaptureOptions(
    GameState state,
    GamePiece piece,
  ) =>
      const <CaptureMoveOption>[];

  @override
  List<String> resolveCaptures(GameState stateAfterMove, GameMove move) =>
      const <String>[];

  @override
  bool get supportsMultiCaptureChain => false;
}

/// Result of evaluating whether a match has reached a win/end condition.
class WinEvaluation {
  const WinEvaluation.ongoing()
      : isFinished = false,
        winner = null;

  const WinEvaluation.finished({this.winner}) : isFinished = true;

  final bool isFinished;
  final PlayerSide? winner;
}

/// Strategy hook for determining game-over and winner state after a move.
abstract interface class WinConditionRule {
  WinEvaluation evaluate(GameState stateAfterMove);
}

/// Default win condition rule keeping match ongoing.
class OngoingWinConditionRule implements WinConditionRule {
  const OngoingWinConditionRule();

  @override
  WinEvaluation evaluate(GameState stateAfterMove) =>
      const WinEvaluation.ongoing();
}

/// Pure, stateless rule specification for a folk board game.
///
/// Future AI agents can call [getCaptureMoves], [getLegalMoves], [getAllLegalMoves],
/// and [applyMove] directly on candidate [GameState] snapshots during search.
abstract interface class GameRules {
  String get gameTypeId;

  GameState createInitialState();

  /// Returns all valid capture destination position IDs for [pieceId].
  List<String> getCaptureMoves(GameState state, String pieceId);

  /// Returns detailed capture move options (target + captured pieces) for [pieceId].
  List<CaptureMoveOption> getCaptureOptions(GameState state, String pieceId);

  /// Returns all legal destination position IDs (normal + capture) for [pieceId].
  List<String> getLegalMoves(GameState state, String pieceId);

  List<MoveCandidate> getAllLegalMoves(GameState state, PlayerSide side);

  MoveResult applyMove(
    GameState state,
    String pieceId,
    String targetPositionId,
  );

  UndoResult undoLastMove(GameState state);
}
