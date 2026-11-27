import '../contracts/game_engine.dart';
import '../contracts/game_rules.dart';
import '../models/engine_results.dart';
import '../models/game_move.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player_side.dart';

/// Reusable rule implementation for graph-based adjacent-movement folk games.
///
/// Subclasses supply board construction, initial piece placement, and optional
/// [CaptureRule] and [WinConditionRule] strategies.
abstract class StandardAdjacentGameRules implements GameRules {
  const StandardAdjacentGameRules({
    this.captureRule = const NoOpCaptureRule(),
    this.winConditionRule = const OngoingWinConditionRule(),
  });

  final CaptureRule captureRule;
  final WinConditionRule winConditionRule;

  @override
  List<String> getLegalMoves(GameState state, String pieceId) {
    if (state.isGameOver) return const <String>[];

    final piece = state.pieces[pieceId];
    if (piece == null || piece.isCaptured) return const <String>[];
    if (piece.owner != state.currentTurn) return const <String>[];

    final neighbors = state.board.neighborsOf(piece.positionId);
    final legalTargets = <String>[];
    for (final neighborId in neighbors) {
      if (state.isPositionEmpty(neighborId)) {
        legalTargets.add(neighborId);
      }
    }
    return List<String>.unmodifiable(legalTargets);
  }

  @override
  List<MoveCandidate> getAllLegalMoves(GameState state, PlayerSide side) {
    if (state.isGameOver || side != state.currentTurn) {
      return const <MoveCandidate>[];
    }

    final candidates = <MoveCandidate>[];
    for (final piece in state.piecesFor(side)) {
      for (final target in getLegalMoves(state, piece.id)) {
        candidates.add(
          MoveCandidate(pieceId: piece.id, targetPositionId: target),
        );
      }
    }
    return List<MoveCandidate>.unmodifiable(candidates);
  }

  @override
  MoveResult applyMove(
    GameState state,
    String pieceId,
    String targetPositionId,
  ) {
    if (state.isGameOver) {
      return MoveResult.failure(
        state: state,
        error: MoveError.gameAlreadyFinished,
        errorMessage: 'Ván đấu đã kết thúc.',
      );
    }

    final piece = state.pieces[pieceId];
    if (piece == null) {
      return MoveResult.failure(
        state: state,
        error: MoveError.pieceNotFound,
        errorMessage: 'Không tìm thấy quân cờ "$pieceId".',
      );
    }
    if (piece.isCaptured) {
      return MoveResult.failure(
        state: state,
        error: MoveError.pieceCaptured,
        errorMessage: 'Quân cờ "$pieceId" đã bị ăn.',
      );
    }
    if (piece.owner != state.currentTurn) {
      return MoveResult.failure(
        state: state,
        error: MoveError.notCurrentTurn,
        errorMessage: 'Không thể di chuyển quân của đối phương.',
      );
    }
    if (state.board.positionById(targetPositionId) == null) {
      return MoveResult.failure(
        state: state,
        error: MoveError.targetPositionNotFound,
        errorMessage: 'Vị trí đích "$targetPositionId" không tồn tại.',
      );
    }
    if (piece.positionId == targetPositionId) {
      return MoveResult.failure(
        state: state,
        error: MoveError.samePosition,
        errorMessage: 'Quân cờ đã ở vị trí đích.',
      );
    }
    if (!state.board.areAdjacent(piece.positionId, targetPositionId)) {
      return MoveResult.failure(
        state: state,
        error: MoveError.notAdjacent,
        errorMessage: 'Không thể di chuyển đến vị trí không có đường nối.',
      );
    }
    if (!state.isPositionEmpty(targetPositionId)) {
      return MoveResult.failure(
        state: state,
        error: MoveError.targetOccupied,
        errorMessage: 'Chỉ được di chuyển đến vị trí đang trống.',
      );
    }

    final updatedPieces = Map<String, GamePiece>.from(state.pieces);
    updatedPieces[pieceId] = piece.copyWith(positionId: targetPositionId);

    final pendingMove = GameMove(
      moveNumber: state.moveHistory.length + 1,
      pieceId: pieceId,
      player: piece.owner,
      fromPositionId: piece.positionId,
      toPositionId: targetPositionId,
      previousTurn: state.currentTurn,
    );

    final stateAfterMove = state.copyWith(pieces: updatedPieces);
    final capturedIds = captureRule.resolveCaptures(stateAfterMove, pendingMove);

    final finalPieces = Map<String, GamePiece>.from(updatedPieces);
    for (final capturedId in capturedIds) {
      final capturedPiece = finalPieces[capturedId];
      if (capturedPiece != null && !capturedPiece.isCaptured) {
        finalPieces[capturedId] = capturedPiece.copyWith(isCaptured: true);
      }
    }

    final recordedMove = GameMove(
      moveNumber: pendingMove.moveNumber,
      pieceId: pendingMove.pieceId,
      player: pendingMove.player,
      fromPositionId: pendingMove.fromPositionId,
      toPositionId: pendingMove.toPositionId,
      capturedPieceIds: capturedIds,
      previousTurn: pendingMove.previousTurn,
    );

    final nextHistory = <GameMove>[...state.moveHistory, recordedMove];
    final stateWithCaptures = state.copyWith(
      pieces: finalPieces,
      moveHistory: nextHistory,
    );

    final winEval = winConditionRule.evaluate(stateWithCaptures);
    final nextState = winEval.isFinished
        ? stateWithCaptures.copyWith(
            phase: GamePhase.finished,
            winner: winEval.winner,
          )
        : stateWithCaptures.copyWith(
            currentTurn: state.nextPlayerAfter(state.currentTurn),
            phase: GamePhase.playing,
            clearWinner: true,
          );

    return MoveResult.success(state: nextState, move: recordedMove);
  }

  @override
  UndoResult undoLastMove(GameState state) {
    if (state.moveHistory.isEmpty) {
      return UndoResult.failure(
        state: state,
        errorMessage: 'Chưa có nước đi nào để hoàn tác.',
      );
    }

    final lastMove = state.moveHistory.last;
    final restoredPieces = Map<String, GamePiece>.from(state.pieces);

    final movedPiece = restoredPieces[lastMove.pieceId];
    if (movedPiece == null) {
      return UndoResult.failure(
        state: state,
        errorMessage: 'Dữ liệu quân cờ không đồng nhất khi hoàn tác.',
      );
    }
    restoredPieces[lastMove.pieceId] = movedPiece.copyWith(
      positionId: lastMove.fromPositionId,
      isCaptured: false,
    );

    for (final capturedId in lastMove.capturedPieceIds) {
      final capturedPiece = restoredPieces[capturedId];
      if (capturedPiece != null) {
        restoredPieces[capturedId] = capturedPiece.copyWith(isCaptured: false);
      }
    }

    final restoredHistory =
        state.moveHistory.sublist(0, state.moveHistory.length - 1);

    final restoredState = state.copyWith(
      pieces: restoredPieces,
      currentTurn: lastMove.previousTurn,
      moveHistory: restoredHistory,
      phase: GamePhase.playing,
      clearWinner: true,
    );

    return UndoResult.success(state: restoredState, undoneMove: lastMove);
  }
}

/// Stateful [GameEngine] implementation backed by a [GameRules] strategy.
class StandardGraphGameEngine implements GameEngine {
  StandardGraphGameEngine({
    required GameRules rules,
    GameState? initialState,
  })  : _rules = rules,
        _state = initialState ?? rules.createInitialState() {
    if (_state.gameTypeId != _rules.gameTypeId) {
      throw ArgumentError(
        'Initial state gameTypeId (${_state.gameTypeId}) does not match '
        'rules gameTypeId (${_rules.gameTypeId}).',
      );
    }
  }

  final GameRules _rules;
  GameState _state;

  @override
  GameRules get rules => _rules;

  @override
  GameState getGameState() => _state;

  @override
  List<String> getLegalMoves(String pieceId) =>
      _rules.getLegalMoves(_state, pieceId);

  @override
  MoveResult makeMove(String pieceId, String targetPosition) {
    final result = _rules.applyMove(_state, pieceId, targetPosition);
    if (result.isSuccess) {
      _state = result.state;
    }
    return result;
  }

  @override
  UndoResult undoMove() {
    final result = _rules.undoLastMove(_state);
    if (result.isSuccess) {
      _state = result.state;
    }
    return result;
  }

  @override
  GameState resetGame() {
    _state = _rules.createInitialState();
    return _state;
  }

  @override
  void loadState(GameState state) {
    if (state.gameTypeId != _rules.gameTypeId) {
      throw ArgumentError(
        'Cannot load state for "${state.gameTypeId}" into "${_rules.gameTypeId}" engine.',
      );
    }
    _state = state;
  }

  @override
  List<MoveCandidate> getAllLegalMoves() =>
      _rules.getAllLegalMoves(_state, _state.currentTurn);
}

