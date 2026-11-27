import '../contracts/game_rules.dart';
import '../models/game_state.dart';
import '../models/player_side.dart';

/// Victory rule where a player wins immediately when all opponent pieces
/// are captured (0 remaining active pieces).
class EliminationWinConditionRule implements WinConditionRule {
  const EliminationWinConditionRule();

  @override
  WinEvaluation evaluate(GameState stateAfterMove) {
    final activeSides = <PlayerSide>[];
    for (final side in stateAfterMove.turnOrder) {
      if (stateAfterMove.countPieces(side) > 0) {
        activeSides.add(side);
      }
    }

    if (activeSides.length == 1) {
      return WinEvaluation.finished(winner: activeSides.first);
    }

    if (activeSides.isEmpty && stateAfterMove.turnOrder.isNotEmpty) {
      return WinEvaluation.finished(winner: stateAfterMove.currentTurn);
    }

    return const WinEvaluation.ongoing();
  }
}

