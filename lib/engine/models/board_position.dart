/// Immutable representation of a fixed node/intersection on a board graph.
class BoardPosition {
  const BoardPosition({
    required this.id,
    required this.row,
    required this.col,
    required this.label,
  });

  /// Fixed unique identifier for this position (e.g. `'r0_c0'`).
  final String id;

  /// Zero-based logical row index (top = 0).
  final int row;

  /// Zero-based logical column index (left = 0).
  final int col;

  /// Human-readable coordinate label for move logs (e.g. `'a5'`).
  final String label;

  factory BoardPosition.fromJson(Map<String, dynamic> json) {
    return BoardPosition(
      id: json['id'] as String,
      row: json['row'] as int,
      col: json['col'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'row': row,
        'col': col,
        'label': label,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardPosition &&
          other.id == id &&
          other.row == row &&
          other.col == col &&
          other.label == label);

  @override
  int get hashCode => Object.hash(id, row, col, label);

  @override
  String toString() => 'BoardPosition($id, $label)';
}

