import 'package:flutter/foundation.dart';

import '../engine/engine.dart';

/// Presentation controller connecting a UI-agnostic [GameEngine] to Flutter UI.
///
/// Holds transient UI selection state ([selectedPieceId], [legalMoveTargets],
/// [statusHint]) while delegating all game rules and state transitions to
/// the underlying [GameEngine].
class GameController extends ChangeNotifier {
  GameController({required this._engine});

  final GameEngine _engine;

  String? _selectedPieceId;
  Set<String> _legalMoveTargets = const <String>{};
  String? _statusHint;

  GameState get state => _engine.getGameState();
  String? get selectedPieceId => _selectedPieceId;
  Set<String> get legalMoveTargets => _legalMoveTargets;
  String? get statusHint => _statusHint;

  bool get canUndo => state.canUndo;
  bool get hasMoves => state.moveHistory.isNotEmpty;

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

      // Tapped an opponent piece.
      if (_selectedPieceId != null) {
        _statusHint =
            'Ô đã có quân đối phương. Chỉ được di chuyển đến ô trống có đường nối.';
      } else {
        _statusHint =
            'Đang là lượt của ${playerDisplayName(current.currentTurn)}.';
      }
      notifyListeners();
      return;
    }

    // Tapped an empty position.
    final selectedId = _selectedPieceId;
    if (selectedId == null) {
      _statusHint =
          'Chọn một quân ${current.currentTurn == PlayerSide.a ? 'Đỏ (A)' : 'Xanh (B)'} để di chuyển.';
      notifyListeners();
      return;
    }

    if (_legalMoveTargets.contains(positionId)) {
      final result = _engine.makeMove(selectedId, positionId);
      if (result.isSuccess) {
        _clearSelection();
        _statusHint = null;
      } else {
        _statusHint = result.errorMessage;
      }
      notifyListeners();
      return;
    }

    // Empty position is not adjacent/legal for the currently selected piece.
    _clearSelection();
    _statusHint = 'Chỉ được di chuyển đến vị trí trống có đường nối trực tiếp.';
    notifyListeners();
  }

  /// Reverts the most recent move.
  bool undo() {
    final result = _engine.undoMove();
    _clearSelection();
    _statusHint = result.isSuccess ? 'Đã hoàn tác nước đi gần nhất.' : null;
    notifyListeners();
    return result.isSuccess;
  }

  /// Resets the board back to its initial state.
  void resetGame() {
    _engine.resetGame();
    _clearSelection();
    _statusHint = null;
    notifyListeners();
  }

  void _selectPiece(String pieceId) {
    final moves = _engine.getLegalMoves(pieceId);
    _selectedPieceId = pieceId;
    _legalMoveTargets = Set<String>.unmodifiable(moves);
    _statusHint = moves.isEmpty
        ? 'Quân này hiện bị chặn, hãy chọn quân khác.'
        : 'Chạm vào điểm sáng màu xanh ngọc để di chuyển.';
  }

  void _clearSelection() {
    _selectedPieceId = null;
    _legalMoveTargets = const <String>{};
  }
}
