import 'player_side.dart';

/// Role of a piece on the board.
///
/// Stage 1 Cờ Chém uses [soldier]. Additional roles such as [general] support
/// future games like Cờ Ba Tướng without altering core piece identity logic.
enum PieceRole {
  soldier,
  general,
}

/// Immutable representation of a single game piece.
class GamePiece {
  const GamePiece({
    required this.id,
    required this.owner,
    required this.positionId,
    this.role = PieceRole.soldier,
    this.isCaptured = false,
  });

  /// Unique piece identifier (e.g. `'A_01'`, `'B_01'`).
  final String id;

  /// Player side owning this piece.
  final PlayerSide owner;

  /// Current position ID on the board (last occupied position if captured).
  final String positionId;

  /// Role/rank of the piece.
  final PieceRole role;

  /// Whether this piece has been captured (always false in Stage 1).
  final bool isCaptured;

  GamePiece copyWith({
    String? positionId,
    PieceRole? role,
    bool? isCaptured,
  }) {
    return GamePiece(
      id: id,
      owner: owner,
      positionId: positionId ?? this.positionId,
      role: role ?? this.role,
      isCaptured: isCaptured ?? this.isCaptured,
    );
  }

  factory GamePiece.fromJson(Map<String, dynamic> json) {
    return GamePiece(
      id: json['id'] as String,
      owner: PlayerSide.fromJson(json['owner']),
      positionId: json['positionId'] as String,
      role: PieceRole.values.byName(
        (json['role'] as String?) ?? PieceRole.soldier.name,
      ),
      isCaptured: (json['isCaptured'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner.toJson(),
        'positionId': positionId,
        'role': role.name,
        'isCaptured': isCaptured,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GamePiece &&
          other.id == id &&
          other.owner == owner &&
          other.positionId == positionId &&
          other.role == role &&
          other.isCaptured == isCaptured);

  @override
  int get hashCode => Object.hash(id, owner, positionId, role, isCaptured);

  @override
  String toString() =>
      'GamePiece($id, owner: ${owner.id}, pos: $positionId, captured: $isCaptured)';
}

