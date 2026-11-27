import 'package:material_ui/material_ui.dart';

import '../../application/game_controller.dart';
import '../../engine/engine.dart';
import '../theme/viet_theme.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/move_history_sheet.dart';
import '../widgets/player_turn_bar.dart';
import '../widgets/rules_dialog.dart';
import '../widgets/viet_background.dart';

/// Main local 2-player match screen powered by a [GameEngine].
class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({
    super.key,
    required this.game,
    required this.engine,
  });

  final FolkGameDescriptor game;
  final GameEngine engine;

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController(engine: widget.engine);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(widget.game.name),
            actions: [
              IconButton(
                tooltip: 'Luật chơi',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: _showRulesDialog,
              ),
              IconButton(
                tooltip: 'Ván mới',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _confirmReset(context),
              ),
            ],
          ),
          body: VietCulturalBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide =
                      constraints.maxWidth >= 760 && constraints.maxWidth > constraints.maxHeight;
                  return isWide
                      ? _buildWideLayout(context, state)
                      : _buildPortraitLayout(context, state);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, GameState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          PlayerTurnBar(state: state),
          const SizedBox(height: 10),
          _StatusHintBanner(
            hint: _controller.statusHint,
            currentTurn: state.currentTurn,
            lastMove: state.lastMove,
            board: state.board,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: GameBoardWidget(
                state: state,
                selectedPieceId: _controller.selectedPieceId,
                legalMoveTargets: _controller.legalMoveTargets,
                captureMoveTargets: _controller.captureMoveTargets,
                capturablePiecePositions: _controller.capturablePiecePositions,
                onPositionTap: _controller.handlePositionTap,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ActionControlsBar(
            canUndo: _controller.canUndo,
            moveCount: state.moveHistory.length,
            onUndo: _controller.undo,
            onHistory: () => _showMoveHistory(context, state),
            onNewGame: () => _confirmReset(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, GameState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: GameBoardWidget(
                state: state,
                selectedPieceId: _controller.selectedPieceId,
                legalMoveTargets: _controller.legalMoveTargets,
                captureMoveTargets: _controller.captureMoveTargets,
                capturablePiecePositions: _controller.capturablePiecePositions,
                onPositionTap: _controller.handlePositionTap,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlayerTurnBar(state: state),
                const SizedBox(height: 14),
                _StatusHintBanner(
                  hint: _controller.statusHint,
                  currentTurn: state.currentTurn,
                  lastMove: state.lastMove,
                  board: state.board,
                ),
                const SizedBox(height: 18),
                _ActionControlsBar(
                  canUndo: _controller.canUndo,
                  moveCount: state.moveHistory.length,
                  onUndo: _controller.undo,
                  onHistory: () => _showMoveHistory(context, state),
                  onNewGame: () => _confirmReset(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => const CoChemRulesDialog(),
    );
  }

  void _showMoveHistory(BuildContext context, GameState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MoveHistorySheet(state: state),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    if (!_controller.hasMoves) {
      _controller.resetGame();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bắt đầu ván mới?'),
        content: const Text(
          'Bàn cờ và lịch sử nước đi hiện tại sẽ được đặt lại về vị trí ban đầu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: VietTheme.parchmentSoft),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: VietTheme.bronzeGold,
              foregroundColor: VietTheme.lacquerDark,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Chơi lại',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _controller.resetGame();
    }
  }
}

class _StatusHintBanner extends StatelessWidget {
  const _StatusHintBanner({
    required this.hint,
    required this.currentTurn,
    required this.lastMove,
    required this.board,
  });

  final String? hint;
  final PlayerSide currentTurn;
  final GameMove? lastMove;
  final BoardGraph board;

  @override
  Widget build(BuildContext context) {
    final String message;
    if (hint != null) {
      message = hint!;
    } else if (lastMove != null) {
      final move = lastMove!;
      final from = board.positionById(move.fromPositionId)?.label ?? move.fromPositionId;
      final to = board.positionById(move.toPositionId)?.label ?? move.toPositionId;
      message =
          'Vừa đi: Phe ${move.player.id} ($from → $to) · Tới lượt ${GameController.playerDisplayName(currentTurn)}';
    } else {
      message =
          '${GameController.playerDisplayName(currentTurn)} đi trước · Chạm quân cờ để chọn nước đi';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(
          color: VietTheme.bronzeGold.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: VietTheme.parchmentSoft,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ActionControlsBar extends StatelessWidget {
  const _ActionControlsBar({
    required this.canUndo,
    required this.moveCount,
    required this.onUndo,
    required this.onHistory,
    required this.onNewGame,
  });

  final bool canUndo;
  final int moveCount;
  final VoidCallback onUndo;
  final VoidCallback onHistory;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.undo_rounded,
            label: 'Hoàn tác',
            enabled: canUndo,
            onPressed: canUndo ? onUndo : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.history_rounded,
            label: moveCount > 0 ? 'Lịch sử ($moveCount)' : 'Lịch sử',
            enabled: true,
            onPressed: onHistory,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.replay_rounded,
            label: 'Chơi lại',
            enabled: true,
            isPrimary: true,
            onPressed: onNewGame,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary
        ? VietTheme.bronzeGold
        : Colors.black.withValues(alpha: enabled ? 0.34 : 0.16);
    final fgColor = isPrimary
        ? VietTheme.lacquerDark
        : enabled
            ? VietTheme.parchment
            : VietTheme.parchmentSoft.withValues(alpha: 0.35);

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        disabledForegroundColor: VietTheme.parchmentSoft.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        side: BorderSide(
          color: isPrimary
              ? VietTheme.bronzeGoldLight
              : VietTheme.bronzeGold.withValues(alpha: enabled ? 0.42 : 0.14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}

