import 'package:co_dan_gian/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoChemBoard topology & initial state', () {
    late BoardGraph board;

    setUp(() {
      board = CoChemBoard.createBoardGraph();
    });

    test('creates 5x5 board with 25 uniquely identified positions', () {
      expect(board.rows, 5);
      expect(board.cols, 5);
      expect(board.nodes.length, 25);
      expect(board.orderedPositions.length, 25);

      final ids = board.orderedPositions.map((p) => p.id).toSet();
      final labels = board.orderedPositions.map((p) => p.label).toSet();
      expect(ids.length, 25);
      expect(labels.length, 25);
    });

    test('creates exact 56 edges matching info.md board diagram', () {
      // 20 horizontal + 20 vertical + 16 diagonal = 56 edges
      expect(board.edges.length, 56);
      expect(
        board.edges.where((e) => e.kind == BoardEdgeKind.horizontal).length,
        20,
      );
      expect(
        board.edges.where((e) => e.kind == BoardEdgeKind.vertical).length,
        20,
      );
      expect(
        board.edges.where((e) => e.kind == BoardEdgeKind.diagonal).length,
        16,
      );
    });

    test('matches exact adjacency of corners, odd nodes, and diagonal hubs', () {
      // Top-left corner (0,0): right (0,1), down (1,0), diagonal (1,1)
      expect(
        board.neighborsOf('r0_c0'),
        unorderedEquals(['r0_c1', 'r1_c0', 'r1_c1']),
      );

      // Odd node (0,1): only orthogonal neighbors, NO diagonals
      expect(
        board.neighborsOf('r0_c1'),
        unorderedEquals(['r0_c0', 'r0_c2', 'r1_c1']),
      );

      // Inner diagonal hub (1,1): 8 neighbors
      expect(
        board.neighborsOf('r1_c1'),
        unorderedEquals([
          'r0_c0',
          'r0_c1',
          'r0_c2',
          'r1_c0',
          'r1_c2',
          'r2_c0',
          'r2_c1',
          'r2_c2',
        ]),
      );

      // Inner orthogonal-only node (1,2): 4 neighbors
      expect(
        board.neighborsOf('r1_c2'),
        unorderedEquals(['r0_c2', 'r1_c1', 'r1_c3', 'r2_c2']),
      );

      // Center node (2,2): 8 neighbors
      expect(board.neighborsOf('r2_c2').length, 8);

      // Bottom odd node (4,3): 3 orthogonal neighbors
      expect(
        board.neighborsOf('r4_c3'),
        unorderedEquals(['r4_c2', 'r4_c4', 'r3_c3']),
      );
    });

    test('places 10 Side A pieces on rows 0-1, empty row 2, 10 Side B on rows 3-4', () {
      final state = createCoChemEngine().getGameState();

      expect(state.pieces.length, 20);
      expect(state.countPieces(PlayerSide.a), 10);
      expect(state.countPieces(PlayerSide.b), 10);
      expect(state.occupancy.length, 20);

      for (var row = 0; row <= 1; row++) {
        for (var col = 0; col < 5; col++) {
          final piece = state.pieceAt(CoChemBoard.positionIdFor(row, col));
          expect(piece, isNotNull);
          expect(piece!.owner, PlayerSide.a);
        }
      }

      for (var col = 0; col < 5; col++) {
        final posId = CoChemBoard.positionIdFor(2, col);
        expect(state.isPositionEmpty(posId), isTrue);
        expect(state.pieceAt(posId), isNull);
      }

      for (var row = 3; row <= 4; row++) {
        for (var col = 0; col < 5; col++) {
          final piece = state.pieceAt(CoChemBoard.positionIdFor(row, col));
          expect(piece, isNotNull);
          expect(piece!.owner, PlayerSide.b);
        }
      }
    });
  });
}

