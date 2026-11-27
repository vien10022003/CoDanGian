import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../engine/engine.dart';
import 'game_session_config.dart';

/// Asynchronous executor used to compute an AI move without blocking UI frames.
typedef AiMoveExecutor = Future<MoveCandidate?> Function(
  GameAiAgent agent,
  GameRules rules,
  GameState state,
);

/// Default production executor running AI search in a background Dart [Isolate].
Future<MoveCandidate?> defaultIsolateAiExecutor(
  GameAiAgent agent,
  GameRules rules,
  GameState state,
) {
  return Isolate.run(() => agent.chooseNextMove(rules, state));
}

/// Presentation controller connecting a UI-agnostic [GameEngine] (and optional
/// [GameAiAgent]) to Flutter UI.
class GameController extends ChangeNotifier {
  GameController({
    required this._engine,
    this.sessionConfig = const GameSessionConfig.localTwoPlayer(),
    this._aiAgent,
    AiMoveExecutor? aiMoveExecutor,
    this.aiMoveDelay = const Duration(milliseconds: 380),
  }) : _aiMoveExecutor = aiMoveExecutor ?? defaultIsolateAiExecutor;

  final GameEngine _engine;
  final GameSessionConfig sessionConfig;
  final GameAiAgent? _aiAgent;
  final AiMoveExecutor _aiMoveExecutor;
  final Duration aiMoveDelay;

  String? _selectedPieceId;
  Set<String> _legalMoveTargets = const <String>{};
  Set<String> _captureMoveTargets = const <String>{};
  Set<String> _capturablePiecePositions = const <String>{};
  String? _statusHint;

  bool _isAiThinking = false;
  bool _disposed = false;
  int _aiTurnEpoch = 0;

  GameState get state => _engine.getGameState();
  String? get selectedPieceId => _selectedPieceId;
  Set<String> get legalMoveTargets => _legalMoveTargets;
  Set<String> get captureMoveTargets => _captureMoveTargets;
  Set<String> get capturablePiecePositions => _capturablePiecePositions;
  String? get statusHint => _statusHint;

  bool get isVsAi => sessionConfig.isVsAi && _aiAgent != null;
  bool get isAiThinking => _isAiThinking;
  bool get isAiTurn =>
      isVsAi && !state.isGameOver && state.currentTurn == sessionConfig.aiSide;
  AiDifficulty? get aiDifficulty => sessionConfig.aiDifficulty;

  bool get canUndo => !_isAiThinking && state.canUndo;
  bool get hasMoves => state.moveHistory.isNotEmpty;
  bool get isChaining => state.isChaining;
  bool get isGameOver => state.isGameOver;
  GameStatus get gameStatus => _engine.checkGameOver();
  PlayerSide? get winner => state.winner;

  /// Human-readable name for a player side given optional [sessionConfig].
  static String playerDisplayName(
    PlayerSide side, {
    GameSessionConfig sessionConfig = const GameSessionConfig.localTwoPlayer(),
  }) {
    if (sessionConfig.isVsAi) {
      if (side == sessionConfig.humanSide) return 'Bạn (Đỏ)';
      if (side == sessionConfig.aiSide) {
        final level = sessionConfig.aiDifficulty?.label ?? 'AI';
        return 'Máy ($level)';
      }
    }
    if (side == PlayerSide.a) return 'Người chơi A (Đỏ)';
    if (side == PlayerSide.b) return 'Người chơi B (Xanh)';
    return 'Người chơi ${side.id}';
  }

  /// Starts an AI turn if the match is currently waiting on the AI side.
  void triggerAiTurnIfNeeded() {
    if (_disposed || !isAiTurn || _isAiThinking) return;
    _scheduleAiTurn();
  }

  /// Handles user tap on any board intersection [positionId].
  void handlePositionTap(String positionId) {
    final current = state;
    if (current.isGameOver) {
      final winnerSide = current.winner ?? current.currentTurn;
      _statusHint =
          '${playerDisplayName(winnerSide, sessionConfig: sessionConfig)} đã chiến thắng! Nhấn Chơi lại để bắt đầu ván mới.';
      notifyListeners();
      return;
    }

    if (isAiTurn || _isAiThinking) {
      _statusHint = 'Đang là lượt của Máy, vui lòng chờ trong giây lát...';
      notifyListeners();
      return;
    }

    if (current.isChaining) {
      _handleTapDuringChain(current, positionId);
      return;
    }

    final tappedPiece = current.pieceAt(positionId);

    if (tappedPiece != null) {
      if (tappedPiece.owner == current.currentTurn) {
        if (_selectedPieceId == tappedPiece.id) {
          _clearSelection();
          _statusHint = null;
        } else {
          _selectPiece(tappedPiece.id);
        }
        notifyListeners();
        return;
      }

      if (_selectedPieceId != null) {
        _statusHint =
            'Ô đã có quân đối phương. Chọn ô trống liền kề hoặc nhảy qua đầu để ăn.';
      } else {
        _statusHint =
            'Đang là lượt của ${playerDisplayName(current.currentTurn, sessionConfig: sessionConfig)}.';
      }
      notifyListeners();
      return;
    }

    final selectedId = _selectedPieceId;
    if (selectedId == null) {
      _statusHint =
          'Chọn một quân ${current.currentTurn == PlayerSide.a ? 'Đỏ (A)' : 'Xanh (B)'} để di chuyển.';
      notifyListeners();
      return;
    }

    if (_legalMoveTargets.contains(positionId)) {
      _executeMove(selectedId, positionId);
      return;
    }

    _clearSelection();
    _statusHint =
        'Chỉ được đi đến ô trống liền kề có đường nối hoặc nhảy ăn quân hợp lệ.';
    notifyListeners();
  }

  void _handleTapDuringChain(GameState current, String positionId) {
    final chainPieceId = current.activeChainPieceId!;
    if (_selectedPieceId != chainPieceId) {
      _selectPiece(chainPieceId);
    }

    if (_captureMoveTargets.contains(positionId)) {
      _executeMove(chainPieceId, positionId);
      return;
    }

    final tappedPiece = current.pieceAt(positionId);
    if (tappedPiece?.id == chainPieceId) {
      _statusHint =
          'Đang trong chuỗi ăn liên tiếp: chọn ô viền đỏ-vàng để nhảy ăn tiếp.';
    } else {
      _statusHint =
          'Bắt buộc ăn liên tiếp bằng quân $chainPieceId, không thể đổi sang quân khác.';
    }
    notifyListeners();
  }

  void _executeMove(String pieceId, String targetPositionId) {
    final result = _engine.makeMove(pieceId, targetPositionId);
    if (!result.isSuccess) {
      _statusHint = result.errorMessage;
      notifyListeners();
      return;
    }

    final updatedState = result.state;
    final executedMove = result.move!;

    if (updatedState.isGameOver) {
      _clearSelection();
      final winnerSide = updatedState.winner ?? executedMove.player;
      _statusHint =
          'Chiến thắng! ${playerDisplayName(winnerSide, sessionConfig: sessionConfig)} thắng cuộc!';
      notifyListeners();
      return;
    }

    if (updatedState.currentTurn == sessionConfig.aiSide && isVsAi) {
      _clearSelection();
      if (executedMove.isCapture) {
        _statusHint =
            '${playerDisplayName(executedMove.player, sessionConfig: sessionConfig)} vừa ăn ${executedMove.capturedPieceIds.length} quân!';
      } else {
        _statusHint = null;
      }
      notifyListeners();
      _scheduleAiTurn();
      return;
    }

    if (updatedState.activeChainPieceId != null) {
      _selectPiece(updatedState.activeChainPieceId!);
      _statusHint =
          'Ăn quân thành công! Tiếp tục ăn liên tiếp bằng quân ${updatedState.activeChainPieceId}.';
    } else {
      _clearSelection();
      if (executedMove.isCapture) {
        _statusHint =
            '${playerDisplayName(executedMove.player, sessionConfig: sessionConfig)} vừa ăn ${executedMove.capturedPieceIds.length} quân! '
            'Tới lượt ${playerDisplayName(updatedState.currentTurn, sessionConfig: sessionConfig)}.';
      } else {
        _statusHint = null;
      }
    }
    notifyListeners();
  }

  Future<void> _scheduleAiTurn() async {
    final agent = _aiAgent;
    if (agent == null || _disposed || !isAiTurn) return;

    final epoch = ++_aiTurnEpoch;
    final snapshot = state;
    _isAiThinking = true;
    _statusHint = snapshot.isChaining
        ? 'Máy (${agent.difficulty.label}) đang tiếp tục chuỗi ăn...'
        : 'Máy (${agent.difficulty.label}) đang suy nghĩ...';
    notifyListeners();

    final aiComputationFuture = _aiMoveExecutor(agent, _engine.rules, snapshot);
    final delayFuture = aiMoveDelay > Duration.zero
        ? Future<void>.delayed(aiMoveDelay)
        : Future<void>.value();

    MoveCandidate? chosenMove;
    try {
      final results = await Future.wait<Object?>([
        aiComputationFuture,
        delayFuture,
      ]);
      chosenMove = results[0] as MoveCandidate?;
    } catch (_) {
      chosenMove = null;
    }

    if (_disposed || epoch != _aiTurnEpoch) return;
    _isAiThinking = false;

    if (chosenMove == null) {
      _statusHint = 'Máy không còn nước đi hợp lệ.';
      notifyListeners();
      return;
    }

    _executeMove(chosenMove.pieceId, chosenMove.targetPositionId);
  }

  /// Reverts the most recent move (in vs-AI mode, reverts back to the human
  /// player's turn so the player can redo their decision).
  bool undo() {
    if (_isAiThinking) return false;
    _aiTurnEpoch++;

    final result = _engine.undoMove();
    if (!result.isSuccess) {
      _clearSelection();
      _statusHint = null;
      notifyListeners();
      return false;
    }

    if (isVsAi) {
      while (state.canUndo && state.currentTurn == sessionConfig.aiSide) {
        _engine.undoMove();
      }
    }

    final restored = state;
    if (restored.activeChainPieceId != null &&
        restored.currentTurn == sessionConfig.humanSide) {
      _selectPiece(restored.activeChainPieceId!);
      _statusHint =
          'Đã hoàn tác: tiếp tục chuỗi ăn của quân ${restored.activeChainPieceId}.';
    } else {
      _clearSelection();
      _statusHint = 'Đã hoàn tác nước đi gần nhất.';
    }
    notifyListeners();
    return true;
  }

  /// Resets the board back to its initial state.
  void resetGame() {
    _aiTurnEpoch++;
    _isAiThinking = false;
    _engine.resetGame();
    _clearSelection();
    _statusHint = null;
    notifyListeners();
  }

  void _selectPiece(String pieceId) {
    final current = state;
    final moves = _engine.getLegalMoves(pieceId);
    final captureOptions = _engine.getCaptureOptions(pieceId);

    final captureTargets = <String>{
      for (final opt in captureOptions) opt.targetPositionId,
    };
    final victimPositions = <String>{
      for (final opt in captureOptions)
        for (final victimId in opt.capturedPieceIds)
          if (current.pieces[victimId] case final victim?) victim.positionId,
    };

    _selectedPieceId = pieceId;
    _legalMoveTargets = Set<String>.unmodifiable(moves);
    _captureMoveTargets = Set<String>.unmodifiable(captureTargets);
    _capturablePiecePositions = Set<String>.unmodifiable(victimPositions);

    if (current.isChaining) {
      _statusHint =
          'Ăn liên tiếp! Chạm ô viền đỏ-vàng để nhảy qua quân đối phương.';
    } else if (moves.isEmpty) {
      _statusHint = 'Quân này hiện bị chặn, hãy chọn quân khác.';
    } else if (captureTargets.isNotEmpty) {
      _statusHint =
          'Chọn ô xanh ngọc để đi thường hoặc ô đỏ-vàng để nhảy ăn quân.';
    } else {
      _statusHint = 'Chạm vào điểm sáng màu xanh ngọc để di chuyển.';
    }
  }

  void _clearSelection() {
    _selectedPieceId = null;
    _legalMoveTargets = const <String>{};
    _captureMoveTargets = const <String>{};
    _capturablePiecePositions = const <String>{};
  }

  @override
  void dispose() {
    _disposed = true;
    _aiTurnEpoch++;
    super.dispose();
  }
}
