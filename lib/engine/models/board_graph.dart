import 'board_edge.dart';
import 'board_position.dart';

/// Immutable graph representation of a folk game board.
///
/// Stores fixed positions ([nodes]) and explicit connections ([edges]) along with
/// an unmodifiable adjacency index for fast legal-move lookup.
class BoardGraph {
  BoardGraph({
    required this.rows,
    required this.cols,
    required List<BoardPosition> positions,
    required List<BoardEdge> edges,
  })  : nodes = Map.unmodifiable({
          for (final pos in positions) pos.id: pos,
        }),
        orderedPositions = List.unmodifiable(positions),
        edges = List.unmodifiable(edges),
        _adjacency = _buildAdjacency(positions, edges);

  final int rows;
  final int cols;
  final Map<String, BoardPosition> nodes;
  final List<BoardPosition> orderedPositions;
  final List<BoardEdge> edges;
  final Map<String, List<String>> _adjacency;

  static Map<String, List<String>> _buildAdjacency(
    List<BoardPosition> positions,
    List<BoardEdge> edges,
  ) {
    final map = <String, List<String>>{
      for (final pos in positions) pos.id: <String>[],
    };

    for (final edge in edges) {
      final fromList = map[edge.fromId];
      final toList = map[edge.toId];
      if (fromList == null || toList == null) {
        throw ArgumentError(
          'Edge ${edge.fromId} <-> ${edge.toId} references unknown board node.',
        );
      }
      if (!fromList.contains(edge.toId)) {
        fromList.add(edge.toId);
      }
      if (!toList.contains(edge.fromId)) {
        toList.add(edge.fromId);
      }
    }

    return Map.unmodifiable({
      for (final entry in map.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    });
  }

  /// Looks up a position by its fixed [positionId], or returns null.
  BoardPosition? positionById(String positionId) => nodes[positionId];

  /// Returns all directly connected adjacent position IDs for [positionId].
  List<String> neighborsOf(String positionId) =>
      _adjacency[positionId] ?? const <String>[];

  /// Returns true if [fromId] and [toId] share a direct edge.
  bool areAdjacent(String fromId, String toId) {
    final neighbors = _adjacency[fromId];
    return neighbors != null && neighbors.contains(toId);
  }

  factory BoardGraph.fromJson(Map<String, dynamic> json) {
    final positions = (json['positions'] as List<dynamic>)
        .map((e) => BoardPosition.fromJson(e as Map<String, dynamic>))
        .toList();
    final edges = (json['edges'] as List<dynamic>)
        .map((e) => BoardEdge.fromJson(e as Map<String, dynamic>))
        .toList();
    return BoardGraph(
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      positions: positions,
      edges: edges,
    );
  }

  Map<String, dynamic> toJson() => {
        'rows': rows,
        'cols': cols,
        'positions': orderedPositions.map((p) => p.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };
}

