import '../../models/board_edge.dart';
import '../../models/board_graph.dart';
import '../../models/board_position.dart';
import '../../models/piece.dart';
import '../../models/player_side.dart';

/// Board geometry and initial piece layout for Cờ Chém (5×5, 25 nodes, 20 pieces).
class CoChemBoard {
  const CoChemBoard._();

  static const int rows = 5;
  static const int cols = 5;

  /// Generates a fixed, deterministic node ID for `(row, col)`.
  static String positionIdFor(int row, int col) => 'r${row}_c$col';

  /// Generates human-readable algebraic coordinates (`a5`..`e1`).
  static String labelFor(int row, int col) {
    final file = String.fromCharCode(97 + col);
    final rank = rows - row;
    return '$file$rank';
  }

  /// Builds the exact 5×5 Cờ Chém graph specified in `info.md`.
  ///
  /// Horizontal and vertical links exist between all orthogonal neighbors.
  /// Diagonal links exist precisely at intersections where `(row + col)` is even.
  static BoardGraph createBoardGraph() {
    final positions = <BoardPosition>[];
    final edges = <BoardEdge>[];

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        positions.add(
          BoardPosition(
            id: positionIdFor(row, col),
            row: row,
            col: col,
            label: labelFor(row, col),
          ),
        );
      }
    }

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final currentId = positionIdFor(row, col);

        if (col + 1 < cols) {
          edges.add(
            BoardEdge(
              fromId: currentId,
              toId: positionIdFor(row, col + 1),
              kind: BoardEdgeKind.horizontal,
            ),
          );
        }

        if (row + 1 < rows) {
          edges.add(
            BoardEdge(
              fromId: currentId,
              toId: positionIdFor(row + 1, col),
              kind: BoardEdgeKind.vertical,
            ),
          );
        }

        // Only intersections with even (row + col) carry diagonal connections.
        if ((row + col).isEven && row + 1 < rows) {
          if (col + 1 < cols) {
            edges.add(
              BoardEdge(
                fromId: currentId,
                toId: positionIdFor(row + 1, col + 1),
                kind: BoardEdgeKind.diagonal,
              ),
            );
          }
          if (col - 1 >= 0) {
            edges.add(
              BoardEdge(
                fromId: currentId,
                toId: positionIdFor(row + 1, col - 1),
                kind: BoardEdgeKind.diagonal,
              ),
            );
          }
        }
      }
    }

    return BoardGraph(
      rows: rows,
      cols: cols,
      positions: positions,
      edges: edges,
    );
  }

  /// Creates the initial 20 pieces:
  /// - Rows 0–1: 10 Red pieces for Side A (`A_01`..`A_10`)
  /// - Row 2: Empty
  /// - Rows 3–4: 10 Blue pieces for Side B (`B_01`..`B_10`)
  static Map<String, GamePiece> createInitialPieces() {
    final pieces = <String, GamePiece>{};

    var aIndex = 1;
    for (var row = 0; row <= 1; row++) {
      for (var col = 0; col < cols; col++) {
        final id = 'A_${aIndex.toString().padLeft(2, '0')}';
        pieces[id] = GamePiece(
          id: id,
          owner: PlayerSide.a,
          positionId: positionIdFor(row, col),
        );
        aIndex++;
      }
    }

    var bIndex = 1;
    for (var row = 3; row <= 4; row++) {
      for (var col = 0; col < cols; col++) {
        final id = 'B_${bIndex.toString().padLeft(2, '0')}';
        pieces[id] = GamePiece(
          id: id,
          owner: PlayerSide.b,
          positionId: positionIdFor(row, col),
        );
        bIndex++;
      }
    }

    return Map<String, GamePiece>.unmodifiable(pieces);
  }
}

