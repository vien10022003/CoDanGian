import 'package:material_ui/material_ui.dart';

import '../../engine/engine.dart';
import '../theme/viet_theme.dart';

/// Renders the game board surface, graph connections, coordinate labels,
/// intersection markers, last-move trail, and legal destination highlights.
///
/// Completely data-driven from [board]: never hardcodes board geometry.
class GameBoardPainter extends CustomPainter {
  GameBoardPainter({
    required this.board,
    required this.gridPadding,
    required this.legalMoveTargets,
    this.selectedPositionId,
    this.lastMove,
  });

  final BoardGraph board;
  final double gridPadding;
  final Set<String> legalMoveTargets;
  final String? selectedPositionId;
  final GameMove? lastMove;

  @override
  void paint(Canvas canvas, Size size) {
    final innerWidth = size.width - gridPadding * 2;
    final innerHeight = size.height - gridPadding * 2;
    if (innerWidth <= 0 || innerHeight <= 0) return;

    Offset pointFor(BoardPosition pos) {
      final dx = board.cols <= 1
          ? size.width / 2
          : gridPadding + (pos.col / (board.cols - 1)) * innerWidth;
      final dy = board.rows <= 1
          ? size.height / 2
          : gridPadding + (pos.row / (board.rows - 1)) * innerHeight;
      return Offset(dx, dy);
    }

    // Subtle wood grain horizontal bands.
    final grainPaint = Paint()
      ..color = VietTheme.boardInk.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;
    for (var y = 12.0; y < size.height; y += 14.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grainPaint);
    }

    // Subtle outer border engraved inside wood surface.
    final innerFramePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = VietTheme.boardInk.withValues(alpha: 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
        const Radius.circular(12),
      ),
      innerFramePaint,
    );

    // Draw all edges from BoardGraph.
    final lineShadowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = VietTheme.boardInk.withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (final edge in board.edges) {
      final from = board.positionById(edge.fromId);
      final to = board.positionById(edge.toId);
      if (from == null || to == null) continue;
      final p1 = pointFor(from);
      final p2 = pointFor(to);
      canvas.drawLine(
        p1.translate(0.7, 0.9),
        p2.translate(0.7, 0.9),
        lineShadowPaint,
      );
      canvas.drawLine(p1, p2, linePaint);
    }

    // Highlight last move path & origin ring.
    final recent = lastMove;
    if (recent != null) {
      final fromNode = board.positionById(recent.fromPositionId);
      final toNode = board.positionById(recent.toPositionId);
      if (fromNode != null && toNode != null) {
        final pFrom = pointFor(fromNode);
        final pTo = pointFor(toNode);
        final trailPaint = Paint()
          ..color = VietTheme.bronzeGoldDark.withValues(alpha: 0.45)
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(pFrom, pTo, trailPaint);

        final originRingPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = VietTheme.bronzeGoldDark.withValues(alpha: 0.65);
        canvas.drawCircle(pFrom, innerWidth * 0.032, originRingPaint);
      }
    }

    // Coordinate labels (subtle, inside margin).
    final coordStyle = TextStyle(
      color: VietTheme.boardInk.withValues(alpha: 0.55),
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
    );
    for (var col = 0; col < board.cols; col++) {
      final label = String.fromCharCode(97 + col);
      final x = gridPadding + (col / (board.cols - 1)) * innerWidth;
      _drawCenteredText(
        canvas,
        label,
        Offset(x, size.height - 13),
        coordStyle,
      );
    }
    for (var row = 0; row < board.rows; row++) {
      final label = '${board.rows - row}';
      final y = gridPadding + (row / (board.rows - 1)) * innerHeight;
      _drawCenteredText(
        canvas,
        label,
        Offset(13, y),
        coordStyle,
      );
    }

    // Intersection nodes and legal/selected highlights.
    final nodeRadius = (innerWidth / 4) * 0.075;
    final nodePaint = Paint()..color = VietTheme.boardInk;
    final nodeCenterPaint = Paint()..color = VietTheme.bronzeGoldLight;

    for (final pos in board.orderedPositions) {
      final center = pointFor(pos);

      if (pos.id == selectedPositionId) {
        final selectedGlow = Paint()
          ..color = VietTheme.bronzeGold.withValues(alpha: 0.42);
        canvas.drawCircle(center, innerWidth * 0.088, selectedGlow);
      }

      if (legalMoveTargets.contains(pos.id)) {
        final outerHalo = Paint()
          ..color = VietTheme.legalHighlightGlow.withValues(alpha: 0.30);
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = VietTheme.legalHighlight;
        final innerDot = Paint()..color = VietTheme.legalHighlight;

        canvas.drawCircle(center, innerWidth * 0.068, outerHalo);
        canvas.drawCircle(center, innerWidth * 0.052, ringPaint);
        canvas.drawCircle(center, innerWidth * 0.024, innerDot);
      } else {
        canvas.drawCircle(center, nodeRadius, nodePaint);
        canvas.drawCircle(center, nodeRadius * 0.42, nodeCenterPaint);
      }
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant GameBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.gridPadding != gridPadding ||
        oldDelegate.selectedPositionId != selectedPositionId ||
        oldDelegate.lastMove != lastMove ||
        !_sameSet(oldDelegate.legalMoveTargets, legalMoveTargets);
  }

  bool _sameSet(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

