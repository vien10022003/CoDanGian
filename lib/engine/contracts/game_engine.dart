import '../models/engine_results.dart';
import '../models/game_state.dart';
import 'game_rules.dart';

/// Independent, UI-agnostic contract for folk board game engines.
///
/// Designed to support local play, AI search/simulation, save/load, and
/// future online synchronization.
abstract interface class GameEngine {
  /// Returns the current immutable game state snapshot.
  GameState getGameState();

  /// Returns all legal capture target position IDs for [pieceId] in the current state.
  List<String> getCaptureMoves(String pieceId);

  /// Returns detailed capture options (including target enemy piece IDs) for [pieceId].
  List<CaptureMoveOption> getCaptureOptions(String pieceId);

  /// Returns all valid target position IDs (normal and capture) for [pieceId].
  List<String> getLegalMoves(String pieceId);

  /// Validates and executes moving [pieceId] to [targetPosition].
  MoveResult makeMove(String pieceId, String targetPosition);

  /// Checks remaining pieces and returns the current [GameStatus] (`playing`, `A_won`, `B_won`).
  GameStatus checkGameOver();

  /// Reverts the most recently executed move if one exists.
  UndoResult undoMove();

  /// Resets the match back to the game's initial board state.
  GameState resetGame();

  /// Restores a previously serialized or externally synchronized [GameState].
  void loadState(GameState state);

  /// Returns every legal move for the active player (useful for AI and hints).
  List<MoveCandidate> getAllLegalMoves();

  /// Underlying stateless rules definition used by this engine.
  GameRules get rules;
}
