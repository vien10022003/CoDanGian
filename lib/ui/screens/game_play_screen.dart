import 'package:material_ui/material_ui.dart';

import '../../application/game_controller.dart';
import '../../application/game_session_config.dart';
import '../../engine/engine.dart';
import '../theme/viet_theme.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/move_history_sheet.dart';
import '../widgets/player_turn_bar.dart';
import '../widgets/rules_dialog.dart';
import '../widgets/victory_dialog.dart';
import '../widgets/viet_background.dart';

/// Main match screen supporting both local 2-player hot-seat and vs-AI play.
class GamePlayScreen extends StatefulWidget {
  const GamePlayScreen({
    super.key,
    required this.game,
    required this.engine,
    this.sessionConfig = const GameSessionConfig.localTwoPlayer(),
    this.aiAgent,
    this.aiMoveExecutor,
    this.aiMoveDelay = const Duration(milliseconds: 380),
  });

  final FolkGameDescriptor game;
  final GameEngine engine;
  final GameSessionConfig sessionConfig;
  final GameAiAgent? aiAgent;
  final AiMoveExecutor? aiMoveExecutor;
  final Duration aiMoveDelay;

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late final GameController _controller;
  bool _victoryDialogShown = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      engine: widget.engine,
      sessionConfig: widget.sessionConfig,
      aiAgent: widget.aiAgent,
      aiMoveExecutor: widget.aiMoveExecutor,
      aiMoveDelay: widget.aiMoveDelay,
    );
    _controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.isGameOver && !_victoryDialogShown) {
        _victoryDialogShown = true;
        _showVictoryDialog(_controller.state);
      } else {
        _controller.triggerAiTurnIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller.isGameOver) {
      if (!_victoryDialogShown) {
        _victoryDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _controller.isGameOver) {
            _showVictoryDialog(_controller.state);
          }
        });
      }
    } else {
      _victoryDialogShown = false;
    }
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
            title: Text(
              widget.sessionConfig.isVsAi
                  ? '${widget.game.name} · Đấu Máy'
                  : widget.game.name,
            ),
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
                  final isWide = constraints.maxWidth >= 760 &&
                      constraints.maxWidth > constraints.maxHeight;
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
          PlayerTurnBar(
            state: state,
            sessionConfig: widget.sessionConfig,
            isAiThinking: _controller.isAiThinking,
          ),
          const SizedBox(height: 10),
          _StatusHintBanner(
            hint: _controller.statusHint,
            state: state,
            sessionConfig: widget.sessionConfig,
            isAiThinking: _controller.isAiThinking,
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
                PlayerTurnBar(
                  state: state,
                  sessionConfig: widget.sessionConfig,
                  isAiThinking: _controller.isAiThinking,
                ),
                const SizedBox(height: 14),
                _StatusHintBanner(
                  hint: _controller.statusHint,
                  state: state,
                  sessionConfig: widget.sessionConfig,
                  isAiThinking: _controller.isAiThinking,
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
      builder: (_) => MoveHistorySheet(
        state: state,
        sessionConfig: widget.sessionConfig,
      ),
    );
  }

  Future<void> _showVictoryDialog(GameState state) async {
    final replay = await showDialog<bool>(
      context: context,
      builder: (_) => VictoryDialog(
        state: state,
        sessionConfig: widget.sessionConfig,
      ),
    );
    if (replay == true && mounted) {
      _controller.resetGame();
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    if (!_controller.hasMoves || _controller.isGameOver) {
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
    required this.state,
    required this.sessionConfig,
    required this.isAiThinking,
  });

  final String? hint;
  final GameState state;
  final GameSessionConfig sessionConfig;
  final bool isAiThinking;

  @override
  Widget build(BuildContext context) {
    final isGameOver = state.isGameOver;
    final winner = state.winner;
    final lastMove = state.lastMove;

    final String message;
    if (isGameOver && winner != null) {
      message =
          'Chiến thắng! ${GameController.playerDisplayName(winner, sessionConfig: sessionConfig)} thắng cuộc!';
    } else if (hint != null) {
      message = hint!;
    } else if (lastMove != null) {
      final from = state.board.positionById(lastMove.fromPositionId)?.label ??
          lastMove.fromPositionId;
      final to = state.board.positionById(lastMove.toPositionId)?.label ??
          lastMove.toPositionId;
      final actor = GameController.playerDisplayName(
        lastMove.player,
        sessionConfig: sessionConfig,
      );
      final nextActor = GameController.playerDisplayName(
        state.currentTurn,
        sessionConfig: sessionConfig,
      );
      message = 'Vừa đi: $actor ($from → $to) · Tới lượt $nextActor';
    } else {
      final firstActor = GameController.playerDisplayName(
        state.currentTurn,
        sessionConfig: sessionConfig,
      );
      message = '$firstActor đi trước · Chạm quân cờ để chọn nước đi';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isGameOver
            ? VietTheme.bronzeGold.withValues(alpha: 0.22)
            : Colors.black.withValues(alpha: 0.28),
        border: Border.all(
          color: isGameOver
              ? VietTheme.bronzeGoldLight
              : VietTheme.bronzeGold.withValues(alpha: 0.25),
          width: isGameOver ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isGameOver) ...[
            const Icon(
              Icons.emoji_events_rounded,
              color: VietTheme.bronzeGoldLight,
              size: 18,
            ),
            const SizedBox(width: 8),
          ] else if (isAiThinking) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: VietTheme.bronzeGoldLight,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isGameOver
                    ? VietTheme.bronzeGoldLight
                    : VietTheme.parchmentSoft,
                fontSize: isGameOver ? 13 : 12.5,
                fontWeight: isGameOver ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
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
