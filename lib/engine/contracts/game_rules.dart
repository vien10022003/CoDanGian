import '../models/engine_results.dart';
import '../models/game_move.dart';
import '../models/game_state.dart';
import '../models/player_side.dart';

/// Strategy hook for resolving piece captures after a move completes.
///
/// In Stage 1 of Cờ Chém, [NoOpCaptureRule] is used. Later stages inject a
/// concrete capture implementation without altering the UI or core engine API.
abstract interface class CaptureRule {
  List<String> resolveCaptures(GameState stateAfterMove, GameMove move);
}

/// Default Stage 1 capture rule that performs no captures.
class NoOpCaptureRule implements CaptureRule {
  const NoOpCaptureRule();

  @override
  List<String> resolveCaptures(GameState stateAfterMove, GameMove move) =>
      const <String>[];
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

/// Default Stage 1 win condition rule (keeps match ongoing for free movement).
class OngoingWinConditionRule implements WinConditionRule {
  const OngoingWinConditionRule();

  @override
  WinEvaluation evaluate(GameState stateAfterMove) =>
      const WinEvaluation.ongoing();
}

/// Pure, stateless rule specification for a folk board game.
///
/// Future AI agents can call [getLegalMoves], [getAllLegalMoves], and
/// [applyMove] directly on candidate [GameState] snapshots during search.
abstract interface class GameRules {
  String get gameTypeId;

  GameState createInitialState();

  List<String> getLegalMoves(GameState state, String pieceId);

  List<MoveCandidate> getAllLegalMoves(GameState state, PlayerSide side);

  MoveResult applyMove(
    GameState state,
    String pieceId,
    String targetPositionId,
  );

  UndoResult undoLastMove(GameState state);
}

