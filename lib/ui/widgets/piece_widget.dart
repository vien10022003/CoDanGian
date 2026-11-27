import 'package:material_ui/material_ui.dart';

import '../../engine/engine.dart';
import '../theme/viet_theme.dart';

/// Tactile carved wooden/lacquer chess piece token for Side A (Red) and Side B (Blue).
class VietPieceWidget extends StatelessWidget {
  const VietPieceWidget({
    super.key,
    required this.piece,
    required this.size,
    required this.isSelected,
    required this.isCurrentTurnPiece,
    required this.isLastMoved,
  });

  final GamePiece piece;
  final double size;
  final bool isSelected;
  final bool isCurrentTurnPiece;
  final bool isLastMoved;

  @override
  Widget build(BuildContext context) {
    final isRed = piece.owner == PlayerSide.a;
    final lightColor =
        isRed ? VietTheme.sideARedLight : VietTheme.sideBBlueLight;
    final baseColor = isRed ? VietTheme.sideARed : VietTheme.sideBBlue;
    final darkColor = isRed ? VietTheme.sideARedDark : VietTheme.sideBBlueDark;

    final borderColor = isSelected
        ? VietTheme.bronzeGoldLight
        : isLastMoved
            ? VietTheme.bronzeGold.withValues(alpha: 0.9)
            : isCurrentTurnPiece
                ? VietTheme.parchment.withValues(alpha: 0.72)
                : Colors.black.withValues(alpha: 0.35);

    return AnimatedScale(
      scale: isSelected ? 1.14 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      child: Semantics(
        label:
            'Quân ${isRed ? 'Đỏ A' : 'Xanh B'} (${piece.id}) tại ${piece.positionId}',
        selected: isSelected,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.32, -0.35),
              radius: 0.88,
              colors: [
                lightColor,
                baseColor,
                darkColor,
              ],
              stops: const [0.0, 0.58, 1.0],
            ),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.8 : 1.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.55 : 0.42),
                blurRadius: isSelected ? 12 : 6,
                offset: Offset(0, isSelected ? 5 : 3),
              ),
              if (isSelected)
                BoxShadow(
                  color: VietTheme.bronzeGold.withValues(alpha: 0.65),
                  blurRadius: 14,
                  spreadRadius: 1.5,
                ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: VietTheme.bronzeGoldLight.withValues(
                    alpha: isSelected ? 0.85 : 0.42,
                  ),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  piece.owner.id,
                  style: TextStyle(
                    color: VietTheme.parchment.withValues(alpha: 0.95),
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

