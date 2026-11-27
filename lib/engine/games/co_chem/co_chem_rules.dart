import '../../contracts/game_engine.dart';
import '../../contracts/game_rules.dart';
import '../../models/game_state.dart';
import '../../models/player_side.dart';
import '../jump_capture_rule.dart';
import '../standard_graph_game_engine.dart';
import 'co_chem_board.dart';

/// Rule implementation for Cờ Chém (board layout, basic movement, jump capture,
/// and mandatory multi-capture chains).
class CoChemRules extends StandardAdjacentGameRules {
  const CoChemRules({
    super.captureRule = const JumpCaptureRule(),
    super.winConditionRule = const OngoingWinConditionRule(),
  });

  static const String typeId = 'co_chem';

  @override
  String get gameTypeId => typeId;

  @override
  GameState createInitialState() {
    return GameState(
      gameTypeId: gameTypeId,
      board: CoChemBoard.createBoardGraph(),
      pieces: CoChemBoard.createInitialPieces(),
      currentTurn: PlayerSide.a,
      turnOrder: const <PlayerSide>[PlayerSide.a, PlayerSide.b],
    );
  }
}

/// Convenience factory creating an initialized Cờ Chém [GameEngine].
GameEngine createCoChemEngine({
  CaptureRule captureRule = const JumpCaptureRule(),
  WinConditionRule winConditionRule = const OngoingWinConditionRule(),
  GameState? initialState,
}) {
  return StandardGraphGameEngine(
    rules: CoChemRules(
      captureRule: captureRule,
      winConditionRule: winConditionRule,
    ),
    initialState: initialState,
  );
}
