import 'package:material_ui/material_ui.dart';

import '../../application/game_controller.dart';
import '../../engine/engine.dart';
import '../theme/viet_theme.dart';

/// Victory dialog celebrating the winning side and offering instant replay.
class VictoryDialog extends StatelessWidget {
  const VictoryDialog({
    super.key,
    required this.state,
  });

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final winner = state.winner ?? state.currentTurn;
    final isSideA = winner == PlayerSide.a;
    final badgeColor = isSideA ? VietTheme.sideARed : VietTheme.sideBBlue;
    final winnerName = GameController.playerDisplayName(winner);
    final loserLabel = isSideA ? 'Phe B (Xanh)' : 'Phe A (Đỏ)';

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  badgeColor,
                  isSideA ? VietTheme.sideARedDark : VietTheme.sideBBlueDark,
                ],
              ),
              border: Border.all(
                color: VietTheme.bronzeGoldLight,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: VietTheme.bronzeGold.withValues(alpha: 0.45),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: VietTheme.bronzeGoldLight,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chiến thắng!',
            style: TextStyle(
              color: VietTheme.bronzeGoldLight,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$winnerName thắng cuộc!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VietTheme.parchment,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Toàn bộ quân của $loserLabel đã bị ăn hết sau ${state.moveHistory.length} nước đi.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: VietTheme.parchmentSoft,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Xem bàn cờ',
            style: TextStyle(color: VietTheme.parchmentSoft),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: VietTheme.bronzeGold,
            foregroundColor: VietTheme.lacquerDark,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: const Text(
            'Chơi lại',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

