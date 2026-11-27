import '../contracts/game_rules.dart';
import '../models/engine_results.dart';
import '../models/game_move.dart';
import '../models/game_state.dart';
import '../models/piece.dart';

/// Capture rule where a piece jumps over an adjacent opponent piece along a
/// valid straight line onto an immediately adjacent empty landing position.
///
/// Supports mandatory multi-capture chains when further jumps exist.
class JumpCaptureRule implements CaptureRule {
  const JumpCaptureRule();

  @override
  bool get supportsMultiCaptureChain => true;

  @override
  List<CaptureMoveOption> getJumpCaptureOptions(
    GameState state,
    GamePiece piece,
  ) {
    final origin = state.board.positionById(piece.positionId);
    if (origin == null) return const <CaptureMoveOption>[];

    final options = <CaptureMoveOption>[];

    for (final midId in state.board.neighborsOf(origin.id)) {
      final midPiece = state.pieceAt(midId);
      if (midPiece == null || midPiece.owner == piece.owner) {
        continue;
      }

      final midNode = state.board.positionById(midId);
      if (midNode == null) continue;

      final stepRow = midNode.row - origin.row;
      final stepCol = midNode.col - origin.col;

      for (final landingId in state.board.neighborsOf(midId)) {
        final landingNode = state.board.positionById(landingId);
        if (landingNode == null) continue;

        final isSameLineOneStepPast =
            (landingNode.row - midNode.row == stepRow) &&
                (landingNode.col - midNode.col == stepCol);
        if (!isSameLineOneStepPast) continue;

        if (state.isPositionEmpty(landingId)) {
          options.add(
            CaptureMoveOption(
              pieceId: piece.id,
              fromPositionId: origin.id,
              targetPositionId: landingId,
              capturedPieceIds: <String>[midPiece.id],
            ),
          );
        }
      }
    }

    return List<CaptureMoveOption>.unmodifiable(options);
  }

  @override
  List<String> resolveCaptures(GameState stateAfterMove, GameMove move) =>
      const <String>[];
}

