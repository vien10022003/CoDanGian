/// Geometric orientation of a board connection.
enum BoardEdgeKind {
  horizontal,
  vertical,
  diagonal,
}

/// Undirected connection between two adjacent board positions.
class BoardEdge {
  const BoardEdge({
    required this.fromId,
    required this.toId,
    required this.kind,
  });

  final String fromId;
  final String toId;
  final BoardEdgeKind kind;

  /// Returns true if this edge connects [positionA] and [positionB] in either order.
  bool connects(String positionA, String positionB) =>
      (fromId == positionA && toId == positionB) ||
      (fromId == positionB && toId == positionA);

  /// Returns the opposite endpoint of this edge given [positionId], or null.
  String? otherEnd(String positionId) {
    if (fromId == positionId) return toId;
    if (toId == positionId) return fromId;
    return null;
  }

  factory BoardEdge.fromJson(Map<String, dynamic> json) {
    return BoardEdge(
      fromId: json['fromId'] as String,
      toId: json['toId'] as String,
      kind: BoardEdgeKind.values.byName(json['kind'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'fromId': fromId,
        'toId': toId,
        'kind': kind.name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardEdge &&
          other.fromId == fromId &&
          other.toId == toId &&
          other.kind == kind);

  @override
  int get hashCode => Object.hash(fromId, toId, kind);

  @override
  String toString() => 'BoardEdge($fromId <-> $toId, ${kind.name})';
}

