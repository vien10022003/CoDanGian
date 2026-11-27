import 'package:material_ui/material_ui.dart';

import '../../application/game_session_config.dart';
import '../../engine/engine.dart';
import '../theme/viet_theme.dart';

/// Displays both players' status cards, active turn / AI thinking / chain /
/// victory indicator, remaining piece counts, and captured counts.
class PlayerTurnBar extends StatelessWidget {
  const PlayerTurnBar({
    super.key,
    required this.state,
    this.sessionConfig = const GameSessionConfig.localTwoPlayer(),
    this.isAiThinking = false,
  });

  final GameState state;
  final GameSessionConfig sessionConfig;
  final bool isAiThinking;

  @override
  Widget build(BuildContext context) {
    final isGameOver = state.isGameOver;
    final winner = state.winner;
    final isATurn = !isGameOver && state.currentTurn == PlayerSide.a;
    final isBTurn = !isGameOver && state.currentTurn == PlayerSide.b;
    final aWon = isGameOver && winner == PlayerSide.a;
    final bWon = isGameOver && winner == PlayerSide.b;

    final countA = state.countPieces(PlayerSide.a);
    final countB = state.countPieces(PlayerSide.b);
    final capturedByA = state.countCapturedBy(PlayerSide.a);
    final capturedByB = state.countCapturedBy(PlayerSide.b);

    final titleA = sessionConfig.isVsAi ? 'Bạn' : 'Người chơi A';
    final titleB = sessionConfig.isVsAi
        ? 'Máy (${sessionConfig.aiDifficulty?.label ?? 'AI'})'
        : 'Người chơi B';

    return Row(
      children: [
        Expanded(
          child: _PlayerCard(
            title: titleA,
            subtitle: 'Đỏ · Ăn $capturedByA',
            pieceCount: countA,
            capturedCount: capturedByA,
            isActive: isATurn,
            isWinner: aWon,
            isChaining: isATurn && state.isChaining,
            isThinking: false,
            accentColor: VietTheme.sideARedLight,
            fillColor: VietTheme.sideARed,
            sideBadge: 'A',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _TurnCounterPill(
            moveCount: state.moveHistory.length,
            currentTurn: state.currentTurn,
            isChaining: state.isChaining,
            winner: isGameOver ? winner : null,
            isAiTurn: isBTurn && sessionConfig.isVsAi,
          ),
        ),
        Expanded(
          child: _PlayerCard(
            title: titleB,
            subtitle: 'Xanh · Ăn $capturedByB',
            pieceCount: countB,
            capturedCount: capturedByB,
            isActive: isBTurn,
            isWinner: bWon,
            isChaining: isBTurn && state.isChaining,
            isThinking: isBTurn && isAiThinking,
            accentColor: VietTheme.sideBBlueLight,
            fillColor: VietTheme.sideBBlue,
            sideBadge: sessionConfig.isVsAi ? 'AI' : 'B',
          ),
        ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.title,
    required this.subtitle,
    required this.pieceCount,
    required this.capturedCount,
    required this.isActive,
    required this.isWinner,
    required this.isChaining,
    required this.isThinking,
    required this.accentColor,
    required this.fillColor,
    required this.sideBadge,
  });

  final String title;
  final String subtitle;
  final int pieceCount;
  final int capturedCount;
  final bool isActive;
  final bool isWinner;
  final bool isChaining;
  final bool isThinking;
  final Color accentColor;
  final Color fillColor;
  final String sideBadge;

  @override
  Widget build(BuildContext context) {
    final highlighted = isActive || isWinner;
    final activeHighlight =
        isChaining ? VietTheme.captureHighlightGlow : VietTheme.bronzeGoldLight;

    final String statusLine;
    if (isWinner) {
      statusLine = 'Chiến thắng! · Còn $pieceCount';
    } else if (isThinking) {
      statusLine = 'Đang nghĩ... · Còn $pieceCount';
    } else if (isChaining) {
      statusLine = 'Ăn tiếp! · Còn $pieceCount';
    } else if (isActive) {
      statusLine = 'Đang đi · Còn $pieceCount · Ăn $capturedCount';
    } else {
      statusLine = '$subtitle · Còn $pieceCount';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: highlighted
            ? fillColor.withValues(alpha: isWinner ? 0.42 : 0.28)
            : Colors.black.withValues(alpha: 0.24),
        border: Border.all(
          color: highlighted
              ? activeHighlight
              : VietTheme.bronzeGold.withValues(alpha: 0.22),
          width: highlighted ? 1.8 : 1.0,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: (isChaining
                          ? VietTheme.captureHighlight
                          : VietTheme.bronzeGold)
                      .withValues(alpha: isWinner ? 0.36 : 0.26),
                  blurRadius: 12,
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fillColor,
              border: Border.all(
                color: highlighted
                    ? activeHighlight
                    : VietTheme.parchment.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Center(
              child: isWinner
                  ? const Icon(
                      Icons.emoji_events_rounded,
                      color: VietTheme.bronzeGoldLight,
                      size: 16,
                    )
                  : Text(
                      sideBadge,
                      style: TextStyle(
                        color: VietTheme.parchment,
                        fontWeight: FontWeight.w800,
                        fontSize: sideBadge.length > 1 ? 11 : 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: highlighted
                        ? VietTheme.parchment
                        : VietTheme.parchmentSoft.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  statusLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isChaining
                        ? VietTheme.captureHighlightGlow
                        : highlighted
                            ? VietTheme.bronzeGoldLight
                            : accentColor.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnCounterPill extends StatelessWidget {
  const _TurnCounterPill({
    required this.moveCount,
    required this.currentTurn,
    required this.isChaining,
    required this.isAiTurn,
    this.winner,
  });

  final int moveCount;
  final PlayerSide currentTurn;
  final bool isChaining;
  final bool isAiTurn;
  final PlayerSide? winner;

  @override
  Widget build(BuildContext context) {
    final isFinished = winner != null;
    final label = isFinished
        ? '${winner!.id} thắng'
        : isChaining
            ? 'Ăn tiếp ${isAiTurn ? 'Máy' : currentTurn.id}'
            : isAiTurn
                ? 'Lượt Máy'
                : 'Lượt ${currentTurn.id}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isFinished
            ? VietTheme.bronzeGold.withValues(alpha: 0.25)
            : isChaining
                ? VietTheme.captureHighlight.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.34),
        border: Border.all(
          color: isFinished
              ? VietTheme.bronzeGoldLight
              : isChaining
                  ? VietTheme.captureHighlightGlow.withValues(alpha: 0.8)
                  : VietTheme.bronzeGold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nước $moveCount',
            style: const TextStyle(
              color: VietTheme.parchmentSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isChaining
                  ? VietTheme.captureHighlightGlow
                  : VietTheme.bronzeGoldLight,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
