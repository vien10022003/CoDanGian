import 'package:material_ui/material_ui.dart';

import '../../engine/engine.dart';
import '../theme/viet_theme.dart';

/// Displays both players' status cards, active turn indicator, and dynamic
/// piece counts derived directly from [GameState].
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

    return Row(
      children: [
        Expanded(
          child: _PlayerCard(
            title: 'Người chơi A',
            subtitle: 'Quân Đỏ · Đi trước',
            pieceCount: countA,
            isActive: isATurn,
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
          ),
        ),
        Expanded(
          child: _PlayerCard(
            title: 'Người chơi B',
            subtitle: 'Quân Xanh · Đi sau',
            pieceCount: countB,
            isActive: !isATurn,
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
    required this.isActive,
    required this.accentColor,
    required this.fillColor,
    required this.sideBadge,
  });

  final String title;
  final String subtitle;
  final int pieceCount;
  final bool isActive;
  final Color accentColor;
  final Color fillColor;
  final String sideBadge;

  @override
  Widget build(BuildContext context) {
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
              ? VietTheme.bronzeGoldLight
              : VietTheme.bronzeGold.withValues(alpha: 0.22),
          width: isActive ? 1.8 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: VietTheme.bronzeGold.withValues(alpha: 0.22),
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
                    ? VietTheme.bronzeGoldLight
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
                  isActive ? 'Đang đến lượt · $pieceCount quân' : '$subtitle · $pieceCount quân',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive
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
  });

  final int moveCount;
  final PlayerSide currentTurn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.34),
        border: Border.all(
          color: VietTheme.bronzeGold.withValues(alpha: 0.35),
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
            'Lượt ${currentTurn.id}',
            style: const TextStyle(
              color: VietTheme.bronzeGoldLight,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

