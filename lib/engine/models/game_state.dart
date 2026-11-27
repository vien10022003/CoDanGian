import 'board_graph.dart';
import 'game_move.dart';
import 'piece.dart';
import 'player_side.dart';

/// Lifecycle phase of a match.
enum GamePhase {
  playing,
  finished,
}

/// Complete, immutable, serializable snapshot of a board game match.
///
/// Guarantees consistency between [pieces] and [occupancy]: every non-captured
/// piece has an entry in [occupancy] mapping its [GamePiece.positionId] to its
/// [GamePiece.id], with no duplicate occupancy on a single position.
class GameState {
  GameState({
    required this.gameTypeId,
    required this.board,
    required Map<String, GamePiece> pieces,
    required this.currentTurn,
    required List<PlayerSide> turnOrder,
    List<GameMove> moveHistory = const <GameMove>[],
    this.phase = GamePhase.playing,
    this.winner,
  })  : pieces = Map.unmodifiable(pieces),
        occupancy = _buildConsistentOccupancy(board, pieces),
        turnOrder = List.unmodifiable(turnOrder),
        moveHistory = List.unmodifiable(moveHistory);

  final String gameTypeId;
  final BoardGraph board;
  final Map<String, GamePiece> pieces;

  /// Maps `positionId -> pieceId` for all active (non-captured) pieces.
  final Map<String, String> occupancy;

  final PlayerSide currentTurn;
  final List<PlayerSide> turnOrder;
  final List<GameMove> moveHistory;
  final GamePhase phase;
  final PlayerSide? winner;

  static Map<String, String> _buildConsistentOccupancy(
    BoardGraph board,
    Map<String, GamePiece> pieces,
  ) {
    final map = <String, String>{};
    for (final entry in pieces.entries) {
      final piece = entry.value;
      if (piece.id != entry.key) {
        throw ArgumentError(
          'Piece map key ${entry.key} does not match piece id ${piece.id}.',
        );
      }
      if (piece.isCaptured) continue;
      if (board.positionById(piece.positionId) == null) {
        throw ArgumentError(
          'Piece ${piece.id} references unknown position ${piece.positionId}.',
        );
      }
      if (map.containsKey(piece.positionId)) {
        throw StateError(
          'Position ${piece.positionId} is occupied by both '
          '${map[piece.positionId]} and ${piece.id}.',
        );
      }
      map[piece.positionId] = piece.id;
    }
    return Map.unmodifiable(map);
  }

  /// Returns the active piece occupying [positionId], or null if empty.
  GamePiece? pieceAt(String positionId) {
    final pieceId = occupancy[positionId];
    return pieceId == null ? null : pieces[pieceId];
  }

  /// Returns true if [positionId] exists on the board and has no active piece.
  bool isPositionEmpty(String positionId) =>
      board.positionById(positionId) != null &&
      !occupancy.containsKey(positionId);

  /// Returns pieces belonging to [side].
  List<GamePiece> piecesFor(PlayerSide side, {bool activeOnly = true}) {
    return pieces.values
        .where((p) => p.owner == side && (!activeOnly || !p.isCaptured))
        .toList(growable: false);
  }

  /// Counts active pieces owned by [side].
  int countPieces(PlayerSide side) {
    var count = 0;
    for (final piece in pieces.values) {
      if (piece.owner == side && !piece.isCaptured) {
        count++;
      }
    }
    return count;
  }

  GameMove? get lastMove => moveHistory.isEmpty ? null : moveHistory.last;

  bool get canUndo => moveHistory.isNotEmpty;

  bool get isGameOver => phase == GamePhase.finished;

  /// Returns the next player in [turnOrder] after [current].
  PlayerSide nextPlayerAfter(PlayerSide current) {
    final idx = turnOrder.indexOf(current);
    if (idx == -1) return turnOrder.first;
    return turnOrder[(idx + 1) % turnOrder.length];
  }

  GameState copyWith({
    Map<String, GamePiece>? pieces,
    PlayerSide? currentTurn,
    List<GameMove>? moveHistory,
    GamePhase? phase,
    PlayerSide? winner,
    bool clearWinner = false,
  }) {
    return GameState(
      gameTypeId: gameTypeId,
      board: board,
      pieces: pieces ?? this.pieces,
      currentTurn: currentTurn ?? this.currentTurn,
      turnOrder: turnOrder,
      moveHistory: moveHistory ?? this.moveHistory,
      phase: phase ?? this.phase,
      winner: clearWinner ? null : (winner ?? this.winner),
    );
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final board = BoardGraph.fromJson(json['board'] as Map<String, dynamic>);
    final piecesList = (json['pieces'] as List<dynamic>)
        .map((e) => GamePiece.fromJson(e as Map<String, dynamic>))
        .toList();
    final piecesMap = <String, GamePiece>{
      for (final piece in piecesList) piece.id: piece,
    };
    final turnOrder = (json['turnOrder'] as List<dynamic>)
        .map(PlayerSide.fromJson)
        .toList();
    final moveHistory = (json['moveHistory'] as List<dynamic>? ?? const [])
        .map((e) => GameMove.fromJson(e as Map<String, dynamic>))
        .toList();

    return GameState(
      gameTypeId: json['gameTypeId'] as String,
      board: board,
      pieces: piecesMap,
      currentTurn: PlayerSide.fromJson(json['currentTurn']),
      turnOrder: turnOrder,
      moveHistory: moveHistory,
      phase: GamePhase.values.byName(
        (json['phase'] as String?) ?? GamePhase.playing.name,
      ),
      winner: json['winner'] == null ? null : PlayerSide.fromJson(json['winner']),
    );
  }

  Map<String, dynamic> toJson() => {
        'gameTypeId': gameTypeId,
        'board': board.toJson(),
        'pieces': pieces.values.map((p) => p.toJson()).toList(),
        'currentTurn': currentTurn.toJson(),
        'turnOrder': turnOrder.map((s) => s.toJson()).toList(),
        'moveHistory': moveHistory.map((m) => m.toJson()).toList(),
        'phase': phase.name,
        'winner': winner?.toJson(),
      };
}

