import '../contracts/game_engine.dart';
import '../contracts/game_rules.dart';
import '../models/engine_results.dart';
import '../models/game_move.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player_side.dart';

/// Reusable rule implementation for graph-based adjacent & jump-capture folk games.
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

  GamePiece? _movablePieceFor(GameState state, String pieceId) {
    if (state.isGameOver) return null;
    final piece = state.pieces[pieceId];
    if (piece == null || piece.isCaptured) return null;
    if (piece.owner != state.currentTurn) return null;
    if (state.activeChainPieceId != null &&
        state.activeChainPieceId != pieceId) {
      return null;
    }
    return piece;
  }

  @override
  List<CaptureMoveOption> getCaptureOptions(GameState state, String pieceId) {
    final piece = _movablePieceFor(state, pieceId);
    if (piece == null) return const <CaptureMoveOption>[];
    return captureRule.getJumpCaptureOptions(state, piece);
  }

  @override
  List<String> getCaptureMoves(GameState state, String pieceId) {
    final options = getCaptureOptions(state, pieceId);
    if (options.isEmpty) return const <String>[];
    final targets = <String>[];
    for (final opt in options) {
      if (!targets.contains(opt.targetPositionId)) {
        targets.add(opt.targetPositionId);
      }
    }
    return List<String>.unmodifiable(targets);
  }

  @override
  List<String> getLegalMoves(GameState state, String pieceId) {
    final piece = _movablePieceFor(state, pieceId);
    if (piece == null) return const <String>[];

    final legalTargets = <String>[];

    // Normal adjacent moves are allowed only outside an active capture chain.
    if (!state.isChaining) {
      for (final neighborId in state.board.neighborsOf(piece.positionId)) {
        if (state.isPositionEmpty(neighborId)) {
          legalTargets.add(neighborId);
        }
      }
    }

    for (final captureOption
        in captureRule.getJumpCaptureOptions(state, piece)) {
      if (!legalTargets.contains(captureOption.targetPositionId)) {
        legalTargets.add(captureOption.targetPositionId);
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
    final validationError = _validateMoveRequest(
      state,
      pieceId,
      targetPositionId,
    );
    if (validationError != null) return validationError;

    final piece = state.pieces[pieceId]!;
    final jumpOption = _findMatchingJumpOption(state, piece, targetPositionId);

    if (state.isChaining && jumpOption == null) {
      return MoveResult.failure(
        state: state,
        error: MoveError.mustContinueCaptureChain,
        errorMessage:
            'Đang trong chuỗi ăn liên tiếp, phải chọn nước ăn tiếp theo.',
      );
    }

    final isAdjacentMove =
        state.board.areAdjacent(piece.positionId, targetPositionId);
    if (jumpOption == null && !isAdjacentMove) {
      return MoveResult.failure(
        state: state,
        error: MoveError.notAdjacent,
        errorMessage: 'Không thể di chuyển đến vị trí không có đường nối.',
      );
    }

    return _commitMove(
      state: state,
      piece: piece,
      targetPositionId: targetPositionId,
      jumpOption: jumpOption,
    );
  }

  MoveResult? _validateMoveRequest(
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
    if (state.activeChainPieceId != null &&
        state.activeChainPieceId != pieceId) {
      return MoveResult.failure(
        state: state,
        error: MoveError.mustContinueCaptureChain,
        errorMessage:
            'Đang trong chuỗi ăn liên tiếp, chỉ được di chuyển quân ${state.activeChainPieceId}.',
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
    if (!state.isPositionEmpty(targetPositionId)) {
      return MoveResult.failure(
        state: state,
        error: MoveError.targetOccupied,
        errorMessage: 'Chỉ được di chuyển đến vị trí đang trống.',
      );
    }
    return null;
  }

  CaptureMoveOption? _findMatchingJumpOption(
    GameState state,
    GamePiece piece,
    String targetPositionId,
  ) {
    for (final option in captureRule.getJumpCaptureOptions(state, piece)) {
      if (option.targetPositionId == targetPositionId) {
        return option;
      }
    }
    return null;
  }

  MoveResult _commitMove({
    required GameState state,
    required GamePiece piece,
    required String targetPositionId,
    required CaptureMoveOption? jumpOption,
  }) {
    final movedPiece = piece.copyWith(positionId: targetPositionId);
    final updatedPieces = Map<String, GamePiece>.from(state.pieces)
      ..[piece.id] = movedPiece;

    final pendingMove = GameMove(
      moveNumber: state.moveHistory.length + 1,
      pieceId: piece.id,
      player: piece.owner,
      fromPositionId: piece.positionId,
      toPositionId: targetPositionId,
      previousTurn: state.currentTurn,
      previousChainPieceId: state.activeChainPieceId,
    );

    final stateAfterMove = state.copyWith(
      pieces: updatedPieces,
      clearActiveChain: true,
    );

    final capturedIds = <String>[
      ...?jumpOption?.capturedPieceIds,
      for (final postId in captureRule.resolveCaptures(stateAfterMove, pendingMove))
        if (!(jumpOption?.capturedPieceIds.contains(postId) ?? false)) postId,
    ];

    final finalPieces = Map<String, GamePiece>.from(updatedPieces);
    for (final capturedId in capturedIds) {
      final victim = finalPieces[capturedId];
      if (victim != null && !victim.isCaptured) {
        finalPieces[capturedId] = victim.copyWith(isCaptured: true);
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
      previousChainPieceId: pendingMove.previousChainPieceId,
    );

    final nextHistory = <GameMove>[...state.moveHistory, recordedMove];
    final stateWithCaptures = state.copyWith(
      pieces: finalPieces,
      moveHistory: nextHistory,
      clearActiveChain: true,
    );

    final winEval = winConditionRule.evaluate(stateWithCaptures);
    if (winEval.isFinished) {
      return MoveResult.success(
        state: stateWithCaptures.copyWith(
          phase: GamePhase.finished,
          winner: winEval.winner,
          clearActiveChain: true,
        ),
        move: recordedMove,
      );
    }

    final canContinueChain = capturedIds.isNotEmpty &&
        captureRule.supportsMultiCaptureChain &&
        captureRule.getJumpCaptureOptions(stateWithCaptures, movedPiece).isNotEmpty;

    final nextState = canContinueChain
        ? stateWithCaptures.copyWith(
            currentTurn: state.currentTurn,
            activeChainPieceId: piece.id,
            phase: GamePhase.playing,
            clearWinner: true,
          )
        : stateWithCaptures.copyWith(
            currentTurn: state.nextPlayerAfter(state.currentTurn),
            clearActiveChain: true,
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
      activeChainPieceId: lastMove.previousChainPieceId,
      clearActiveChain: lastMove.previousChainPieceId == null,
      phase: GamePhase.playing,
      clearWinner: true,
    );

    return UndoResult.success(state: restoredState, undoneMove: lastMove);
  }

  @override
  GameStatus checkGameOver(GameState state) {
    final eval = winConditionRule.evaluate(state);
    if (!eval.isFinished) {
      return GameStatus.playing;
    }
    if (eval.winner == PlayerSide.a) return GameStatus.aWon;
    if (eval.winner == PlayerSide.b) return GameStatus.bWon;
    return state.gameStatus;
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
  List<String> getCaptureMoves(String pieceId) =>
      _rules.getCaptureMoves(_state, pieceId);

  @override
  List<CaptureMoveOption> getCaptureOptions(String pieceId) =>
      _rules.getCaptureOptions(_state, pieceId);

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
  GameStatus checkGameOver() {
    final status = _rules.checkGameOver(_state);
    if (status != GameStatus.playing && !_state.isGameOver) {
      final winner = status == GameStatus.aWon ? PlayerSide.a : PlayerSide.b;
      _state = _state.copyWith(
        phase: GamePhase.finished,
        winner: winner,
        clearActiveChain: true,
      );
    }
    return status;
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
