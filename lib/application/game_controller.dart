import 'package:flutter/foundation.dart';

import '../engine/engine.dart';

/// Presentation controller connecting a UI-agnostic [GameEngine] to Flutter UI.
///
/// Holds transient UI selection state ([selectedPieceId], [legalMoveTargets],
/// [captureMoveTargets], [capturablePiecePositions], [statusHint]) while
/// delegating all game rules and state transitions to [GameEngine].
class GameController extends ChangeNotifier {
  GameController({required this._engine});

  final GameEngine _engine;

  String? _selectedPieceId;
  Set<String> _legalMoveTargets = const <String>{};
  Set<String> _captureMoveTargets = const <String>{};
  Set<String> _capturablePiecePositions = const <String>{};
  String? _statusHint;

  GameState get state => _engine.getGameState();
  String? get selectedPieceId => _selectedPieceId;
  Set<String> get legalMoveTargets => _legalMoveTargets;
  Set<String> get captureMoveTargets => _captureMoveTargets;
  Set<String> get capturablePiecePositions => _capturablePiecePositions;
  String? get statusHint => _statusHint;

  bool get canUndo => state.canUndo;
  bool get hasMoves => state.moveHistory.isNotEmpty;
  bool get isChaining => state.isChaining;

  /// Human-readable name for a player side.
  static String playerDisplayName(PlayerSide side) {
    if (side == PlayerSide.a) return 'Người chơi A (Đỏ)';
    if (side == PlayerSide.b) return 'Người chơi B (Xanh)';
    return 'Người chơi ${side.id}';
  }

  /// Short label for a player side.
  static String playerShortLabel(PlayerSide side) {
    if (side == PlayerSide.a) return 'Phe A · Đỏ';
    if (side == PlayerSide.b) return 'Phe B · Xanh';
    return 'Phe ${side.id}';
  }

  /// Formats a board position ID into its coordinate label (e.g. `b4`).
  String formatPosition(String positionId) =>
      state.board.positionById(positionId)?.label ?? positionId;

  /// Handles user tap on any board intersection [positionId].
  void handlePositionTap(String positionId) {
    final current = state;
    if (current.isGameOver) {
      _statusHint = 'Ván đấu đã kết thúc. Nhấn Chơi lại để bắt đầu ván mới.';
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
            'Đang là lượt của ${playerDisplayName(current.currentTurn)}.';
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

    if (updatedState.activeChainPieceId != null) {
      _selectPiece(updatedState.activeChainPieceId!);
      _statusHint =
          'Ăn quân thành công! Tiếp tục ăn liên tiếp bằng quân ${updatedState.activeChainPieceId}.';
    } else {
      _clearSelection();
      if (executedMove.isCapture) {
        _statusHint =
            'Phe ${executedMove.player.id} vừa ăn ${executedMove.capturedPieceIds.length} quân! '
            'Tới lượt ${playerDisplayName(updatedState.currentTurn)}.';
      } else {
        _statusHint = null;
      }
    }
    notifyListeners();
  }

  /// Reverts the most recent move.
  bool undo() {
    final result = _engine.undoMove();
    if (!result.isSuccess) {
      _clearSelection();
      _statusHint = null;
      notifyListeners();
      return false;
    }

    final restored = result.state;
    if (restored.activeChainPieceId != null) {
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
}
