import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../engine/engine.dart';
import '../theme/viet_theme.dart';
import 'board_painter.dart';
import 'piece_widget.dart';

/// Responsive, data-driven interactive board widget.
///
/// Renders any [BoardGraph] and [GamePiece] snapshot from [GameState] with
/// animated piece transitions and generous per-node touch targets.
class GameBoardWidget extends StatelessWidget {
  const GameBoardWidget({
    super.key,
    required this.state,
    required this.legalMoveTargets,
    this.captureMoveTargets = const <String>{},
    this.capturablePiecePositions = const <String>{},
    required this.onPositionTap,
    this.selectedPieceId,
  });

  final GameState state;
  final String? selectedPieceId;
  final Set<String> legalMoveTargets;
  final Set<String> captureMoveTargets;
  final Set<String> capturablePiecePositions;
  final ValueChanged<String> onPositionTap;

  @override
  Widget build(BuildContext context) {
    final selectedPositionId =
        selectedPieceId == null ? null : state.pieces[selectedPieceId]?.positionId;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VietTheme.boardFrameLight,
              VietTheme.boardFrameDark,
            ],
          ),
          border: Border.all(
            color: VietTheme.bronzeGold.withValues(alpha: 0.72),
            width: 2.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: VietTheme.bronzeGold.withValues(alpha: 0.14),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VietTheme.boardWoodLight,
                  VietTheme.boardWoodDark,
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final gridPadding = boardSize * 0.125;
                final innerSize = boardSize - gridPadding * 2;
                final maxSpan = math.max(
                  1,
                  math.max(state.board.rows - 1, state.board.cols - 1),
                );
                final cellStep = innerSize / maxSpan;
                final pieceSize = cellStep * 0.64;
                final hitSize = cellStep * 0.86;

                Offset centerFor(BoardPosition pos) {
                  final dx = state.board.cols <= 1
                      ? boardSize / 2
                      : gridPadding +
                          (pos.col / (state.board.cols - 1)) * innerSize;
                  final dy = state.board.rows <= 1
                      ? boardSize / 2
                      : gridPadding +
                          (pos.row / (state.board.rows - 1)) * innerSize;
                  return Offset(dx, dy);
                }

                final activePieces = state.pieces.values
                    .where((p) => !p.isCaptured)
                    .toList()
                  ..sort((a, b) => a.id.compareTo(b.id));

                final lastMovedPieceId = state.lastMove?.pieceId;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GameBoardPainter(
                          board: state.board,
                          gridPadding: gridPadding,
                          legalMoveTargets: legalMoveTargets,
                          captureMoveTargets: captureMoveTargets,
                          capturablePiecePositions: capturablePiecePositions,
                          selectedPositionId: selectedPositionId,
                          lastMove: state.lastMove,
                        ),
                      ),
                    ),
                    // Animated pieces rendered underneath node touch targets.
                    for (final piece in activePieces)
                      if (state.board.positionById(piece.positionId)
                          case final pos?)
                        () {
                          final center = centerFor(pos);
                          return AnimatedPositioned(
                            key: ValueKey('piece_${piece.id}'),
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            left: center.dx - pieceSize / 2,
                            top: center.dy - pieceSize / 2,
                            width: pieceSize,
                            height: pieceSize,
                            child: VietPieceWidget(
                              piece: piece,
                              size: pieceSize,
                              isSelected: piece.id == selectedPieceId,
                              isCurrentTurnPiece:
                                  piece.owner == state.currentTurn &&
                                  (!state.isChaining ||
                                      piece.id == state.activeChainPieceId),
                              isLastMoved: piece.id == lastMovedPieceId,
                            ),
                          );
                        }(),
                    // Transparent node touch hitboxes ensuring accurate tap targets.
                    for (final pos in state.board.orderedPositions)
                      () {
                        final center = centerFor(pos);
                        final isCapture = captureMoveTargets.contains(pos.id);
                        final isLegal = legalMoveTargets.contains(pos.id);
                        return Positioned(
                          left: center.dx - hitSize / 2,
                          top: center.dy - hitSize / 2,
                          width: hitSize,
                          height: hitSize,
                          child: Semantics(
                            button: true,
                            label: 'Vị trí ${pos.label}',
                            hint: isCapture
                                ? 'Nước ăn quân hợp lệ'
                                : isLegal
                                    ? 'Nước đi hợp lệ'
                                    : null,
                            child: GestureDetector(
                              key: ValueKey('node_${pos.id}'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onPositionTap(pos.id),
                            ),
                          ),
                        );
                      }(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
