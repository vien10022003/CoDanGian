import 'package:material_ui/material_ui.dart';

import '../../engine/engine.dart';
import '../theme/viet_theme.dart';

/// Displays both players' status cards, active turn / chain indicator,
/// remaining piece counts, and captured counts derived from [GameState].
class PlayerTurnBar extends StatelessWidget {
  const PlayerTurnBar({
    super.key,
    required this.state,
  });

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final isATurn = state.currentTurn == PlayerSide.a;
    final countA = state.countPieces(PlayerSide.a);
    final countB = state.countPieces(PlayerSide.b);
    final capturedByA = state.countCapturedBy(PlayerSide.a);
    final capturedByB = state.countCapturedBy(PlayerSide.b);

    return Row(
      children: [
        Expanded(
          child: _PlayerCard(
            title: 'Người chơi A',
            subtitle: 'Đỏ · Ăn $capturedByA',
            pieceCount: countA,
            capturedCount: capturedByA,
            isActive: isATurn,
            isChaining: isATurn && state.isChaining,
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
          ),
        ),
        Expanded(
          child: _PlayerCard(
            title: 'Người chơi B',
            subtitle: 'Xanh · Ăn $capturedByB',
            pieceCount: countB,
            capturedCount: capturedByB,
            isActive: !isATurn,
            isChaining: !isATurn && state.isChaining,
            accentColor: VietTheme.sideBBlueLight,
            fillColor: VietTheme.sideBBlue,
            sideBadge: 'B',
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
    required this.isChaining,
    required this.accentColor,
    required this.fillColor,
    required this.sideBadge,
  });

  final String title;
  final String subtitle;
  final int pieceCount;
  final int capturedCount;
  final bool isActive;
  final bool isChaining;
  final Color accentColor;
  final Color fillColor;
  final String sideBadge;

  @override
  Widget build(BuildContext context) {
    final activeHighlight =
        isChaining ? VietTheme.captureHighlightGlow : VietTheme.bronzeGoldLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isActive
            ? fillColor.withValues(alpha: 0.28)
            : Colors.black.withValues(alpha: 0.24),
        border: Border.all(
          color: isActive
              ? activeHighlight
              : VietTheme.bronzeGold.withValues(alpha: 0.22),
          width: isActive ? 1.8 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: (isChaining
                          ? VietTheme.captureHighlight
                          : VietTheme.bronzeGold)
                      .withValues(alpha: 0.26),
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
                color: isActive
                    ? activeHighlight
                    : VietTheme.parchment.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                sideBadge,
                style: const TextStyle(
                  color: VietTheme.parchment,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
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
                    color: isActive
                        ? VietTheme.parchment
                        : VietTheme.parchmentSoft.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isChaining
                      ? 'Ăn tiếp! · Còn $pieceCount'
                      : isActive
                          ? 'Đang đi · Còn $pieceCount · Ăn $capturedCount'
                          : '$subtitle · Còn $pieceCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isChaining
                        ? VietTheme.captureHighlightGlow
                        : isActive
                            ? VietTheme.bronzeGoldLight
                            : accentColor.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
  });

  final int moveCount;
  final PlayerSide currentTurn;
  final bool isChaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isChaining
            ? VietTheme.captureHighlight.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.34),
        border: Border.all(
          color: isChaining
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
            isChaining ? 'Ăn tiếp ${currentTurn.id}' : 'Lượt ${currentTurn.id}',
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
