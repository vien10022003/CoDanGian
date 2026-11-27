/// Represents a player faction/side in a folk board game.
///
/// Designed as a value object rather than a fixed binary enum so games with
/// more than two factions or custom faction IDs can be added cleanly.
class PlayerSide {
  const PlayerSide(this.id);

  /// Side A (Red pieces in Cờ Chém, moves first).
  static const PlayerSide a = PlayerSide('A');

  /// Side B (Blue pieces in Cờ Chém, moves second).
  static const PlayerSide b = PlayerSide('B');

  /// Stable serialized identifier for this side (e.g. `'A'`, `'B'`).
  final String id;

  factory PlayerSide.fromJson(Object? json) {
    if (json is String && json.isNotEmpty) {
      return PlayerSide(json);
    }
    throw FormatException('Invalid PlayerSide JSON: $json');
  }

  String toJson() => id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlayerSide && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PlayerSide($id)';
}

