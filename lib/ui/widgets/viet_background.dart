import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/viet_theme.dart';

/// Atmospheric Vietnamese cultural backdrop featuring deep lacquer gradients
/// and a subtle Dong Son bronze drum (Trống Đồng) geometric watermark.
class VietCulturalBackground extends StatelessWidget {
  const VietCulturalBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.25),
          radius: 1.15,
          colors: [
            VietTheme.lacquerRed,
            VietTheme.lacquerMid,
            VietTheme.lacquerDark,
          ],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: CustomPaint(
              painter: _DongSonPatternPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DongSonPatternPainter extends CustomPainter {
  const _DongSonPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final maxRadius = math.max(size.width, size.height) * 0.56;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = VietTheme.bronzeGold.withValues(alpha: 0.085);

    final finePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = VietTheme.bronzeGoldLight.withValues(alpha: 0.065);

    // Concentric bronze drum bands.
    const ratios = [0.16, 0.28, 0.42, 0.56, 0.72, 0.88, 1.0];
    for (final ratio in ratios) {
      canvas.drawCircle(center, maxRadius * ratio, ringPaint);
    }

    // 12-point Dong Son central sun star.
    final sunOuter = maxRadius * 0.155;
    final sunInner = maxRadius * 0.068;
    final starPath = Path();
    const rays = 12;
    for (var i = 0; i < rays * 2; i++) {
      final angle = (i * math.pi) / rays - math.pi / 2;
      final r = i.isEven ? sunOuter : sunInner;
      final pt = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        starPath.moveTo(pt.dx, pt.dy);
      } else {
        starPath.lineTo(pt.dx, pt.dy);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, ringPaint);

    // Subtle radial comb/tick marks in middle bands.
    final bandInner = maxRadius * 0.29;
    final bandOuter = maxRadius * 0.41;
    const ticks = 48;
    for (var i = 0; i < ticks; i++) {
      final angle = (i * 2 * math.pi) / ticks;
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      canvas.drawLine(
        Offset(center.dx + cosA * bandInner, center.dy + sinA * bandInner),
        Offset(center.dx + cosA * bandOuter, center.dy + sinA * bandOuter),
        finePaint,
      );
    }

    // Outer geometric sawtooth motif.
    final toothInner = maxRadius * 0.58;
    final toothOuter = maxRadius * 0.69;
    const teeth = 36;
    final toothPath = Path();
    for (var i = 0; i <= teeth; i++) {
      final angle = (i * 2 * math.pi) / teeth;
      final r = i.isEven ? toothOuter : toothInner;
      final pt = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        toothPath.moveTo(pt.dx, pt.dy);
      } else {
        toothPath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(toothPath, finePaint);

    // Traditional corner border flourishes.
    _drawCornerAccent(canvas, const Offset(16, 16), 1, 1, finePaint);
    _drawCornerAccent(canvas, Offset(size.width - 16, 16), -1, 1, finePaint);
    _drawCornerAccent(canvas, Offset(16, size.height - 16), 1, -1, finePaint);
    _drawCornerAccent(
      canvas,
      Offset(size.width - 16, size.height - 16),
      -1,
      -1,
      finePaint,
    );
  }

  void _drawCornerAccent(
    Canvas canvas,
    Offset origin,
    double dxSign,
    double dySign,
    Paint paint,
  ) {
    const outer = 28.0;
    const step = 12.0;
    final path = Path()
      ..moveTo(origin.dx + dxSign * outer, origin.dy)
      ..lineTo(origin.dx, origin.dy)
      ..lineTo(origin.dx, origin.dy + dySign * outer)
      ..moveTo(origin.dx + dxSign * step, origin.dy + dySign * step)
      ..lineTo(origin.dx + dxSign * outer, origin.dy + dySign * step)
      ..moveTo(origin.dx + dxSign * step, origin.dy + dySign * step)
      ..lineTo(origin.dx + dxSign * step, origin.dy + dySign * outer);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DongSonPatternPainter oldDelegate) => false;
}

