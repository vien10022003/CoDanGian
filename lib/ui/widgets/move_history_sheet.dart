import 'package:material_ui/material_ui.dart';

import '../../application/game_controller.dart';
import '../../application/game_session_config.dart';
import '../../engine/engine.dart';
import '../theme/viet_theme.dart';

/// Displays chronological move history recorded by the [GameEngine],
/// including capture targets and multi-capture chain steps.
class MoveHistorySheet extends StatelessWidget {
  const MoveHistorySheet({
    super.key,
    required this.state,
    this.sessionConfig = const GameSessionConfig.localTwoPlayer(),
  });

  final GameState state;
  final GameSessionConfig sessionConfig;

  @override
  Widget build(BuildContext context) {
    final moves = state.moveHistory.reversed.toList(growable: false);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2B100E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: VietTheme.bronzeGold.withValues(alpha: 0.45),
              width: 1.4,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VietTheme.bronzeGold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: VietTheme.bronzeGoldLight,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Lịch sử nước đi',
                    style: TextStyle(
                      color: VietTheme.parchment,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${moves.length} nước',
                  style: const TextStyle(
                    color: VietTheme.bronzeGoldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (moves.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'Chưa có nước đi nào được thực hiện.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: VietTheme.parchmentSoft),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: moves.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: VietTheme.bronzeGold.withValues(alpha: 0.14),
                  ),
                  itemBuilder: (context, index) {
                    final move = moves[index];
                    final isSideA = move.player == PlayerSide.a;
                    final fromLabel =
                        state.board.positionById(move.fromPositionId)?.label ??
                            move.fromPositionId;
                    final toLabel =
                        state.board.positionById(move.toPositionId)?.label ??
                            move.toPositionId;
                    final playerLabel = GameController.playerDisplayName(
                      move.player,
                      sessionConfig: sessionConfig,
                    );
                    final captureSummary = move.isCapture
                        ? ' · Ăn ${move.capturedPieceIds.join(', ')}'
                            '${move.isChainContinuation ? ' (liên tiếp)' : ''}'
                        : '';

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: isSideA
                            ? VietTheme.sideARed
                            : VietTheme.sideBBlue,
                        child: Text(
                          move.player.id,
                          style: const TextStyle(
                            color: VietTheme.parchment,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        'Nước #${move.moveNumber} · ${move.pieceId}',
                        style: const TextStyle(
                          color: VietTheme.parchment,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '$playerLabel$captureSummary',
                        style: TextStyle(
                          color: move.isCapture
                              ? VietTheme.captureHighlightGlow
                              : VietTheme.parchmentSoft.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: move.isCapture
                                ? VietTheme.captureHighlight.withValues(alpha: 0.55)
                                : VietTheme.bronzeGold.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '$fromLabel → $toLabel',
                          style: TextStyle(
                            color: move.isCapture
                                ? VietTheme.captureHighlightGlow
                                : VietTheme.bronzeGoldLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
