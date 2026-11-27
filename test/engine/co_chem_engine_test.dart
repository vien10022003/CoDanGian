import 'package:co_dan_gian/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestCaptureRule extends NoOpCaptureRule {
  const _TestCaptureRule(this.targetToCapture);

  final String targetToCapture;

  @override
  List<String> resolveCaptures(GameState stateAfterMove, GameMove move) {
    final victim = stateAfterMove.pieces[targetToCapture];
    if (victim != null && !victim.isCaptured && victim.owner != move.player) {
      return [targetToCapture];
    }
    return const [];
  }
}

class _TestWinAfterOneMoveRule implements WinConditionRule {
  const _TestWinAfterOneMoveRule();

  @override
  WinEvaluation evaluate(GameState stateAfterMove) {
    if (stateAfterMove.moveHistory.isNotEmpty) {
      return WinEvaluation.finished(winner: stateAfterMove.moveHistory.last.player);
    }
    return const WinEvaluation.ongoing();
  }
}

void main() {
  group('CoChem GameEngine', () {
    late GameEngine engine;

    setUp(() {
      engine = createCoChemEngine();
    });

    test('starts with Side A turn and empty move history', () {
      final state = engine.getGameState();
      expect(state.currentTurn, PlayerSide.a);
      expect(state.moveHistory, isEmpty);
      expect(state.canUndo, isFalse);
      expect(state.phase, GamePhase.playing);
      expect(state.winner, isNull);
    });

    test('computes initial legal moves accurately per board edge', () {
      // Row 0 piece A_01 at r0_c0 is completely blocked by row 1
      expect(engine.getLegalMoves('A_01'), isEmpty);

      // A_06 at r1_c0 (odd sum) only goes straight down to r2_c0
      expect(engine.getLegalMoves('A_06'), ['r2_c0']);

      // A_07 at r1_c1 (even sum) has diagonal + vertical empty neighbors in row 2
      expect(
        engine.getLegalMoves('A_07'),
        unorderedEquals(['r2_c0', 'r2_c1', 'r2_c2']),
      );

      // A_08 at r1_c2 (odd sum) only goes straight down to r2_c2
      expect(engine.getLegalMoves('A_08'), ['r2_c2']);

      // Side B pieces cannot move during Side A turn
      expect(engine.getLegalMoves('B_01'), isEmpty);
    });

    test('executes valid moves, updates occupancy & history, alternates turns', () {
      // Turn 1: Side A moves A_07 (r1_c1 -> r2_c2)
      final move1 = engine.makeMove('A_07', 'r2_c2');
      expect(move1.isSuccess, isTrue);
      expect(move1.move?.fromPositionId, 'r1_c1');
      expect(move1.move?.toPositionId, 'r2_c2');
      expect(move1.move?.player, PlayerSide.a);

      var state = engine.getGameState();
      expect(state.currentTurn, PlayerSide.b);
      expect(state.isPositionEmpty('r1_c1'), isTrue);
      expect(state.pieceAt('r2_c2')?.id, 'A_07');
      expect(state.moveHistory.length, 1);

      // Turn 2: Side B moves B_02 (r3_c1 -> r2_c1)
      final move2 = engine.makeMove('B_02', 'r2_c1');
      expect(move2.isSuccess, isTrue);

      state = engine.getGameState();
      expect(state.currentTurn, PlayerSide.a);
      expect(state.isPositionEmpty('r3_c1'), isTrue);
      expect(state.pieceAt('r2_c1')?.id, 'B_02');
      expect(state.moveHistory.length, 2);
    });

    test('rejects invalid moves without mutating state', () {
      // Opponent piece on A turn
      final oppResult = engine.makeMove('B_01', 'r2_c0');
      expect(oppResult.isSuccess, isFalse);
      expect(oppResult.error, MoveError.notCurrentTurn);

      // Non-adjacent position (A_06 at r1_c0 cannot reach r2_c1)
      final nonAdjResult = engine.makeMove('A_06', 'r2_c1');
      expect(nonAdjResult.isSuccess, isFalse);
      expect(nonAdjResult.error, MoveError.notAdjacent);

      // Occupied position (A_01 at r0_c0 -> r1_c0 occupied by A_06)
      final occupiedResult = engine.makeMove('A_01', 'r1_c0');
      expect(occupiedResult.isSuccess, isFalse);
      expect(occupiedResult.error, MoveError.targetOccupied);

      // Unknown piece
      final unknownPieceResult = engine.makeMove('NO_SUCH_PIECE', 'r2_c0');
      expect(unknownPieceResult.isSuccess, isFalse);
      expect(unknownPieceResult.error, MoveError.pieceNotFound);

      // Unknown position
      final unknownPosResult = engine.makeMove('A_06', 'r9_c9');
      expect(unknownPosResult.isSuccess, isFalse);
      expect(unknownPosResult.error, MoveError.targetPositionNotFound);

      // Same position
      final samePosResult = engine.makeMove('A_06', 'r1_c0');
      expect(samePosResult.isSuccess, isFalse);
      expect(samePosResult.error, MoveError.samePosition);

      // Verify state remained completely intact
      final state = engine.getGameState();
      expect(state.currentTurn, PlayerSide.a);
      expect(state.moveHistory, isEmpty);
      expect(state.pieceAt('r1_c0')?.id, 'A_06');
    });

    test('undoMove restores previous positions, occupancy, and turn', () {
      expect(engine.undoMove().isSuccess, isFalse);

      engine.makeMove('A_07', 'r2_c2');
      engine.makeMove('B_02', 'r2_c1');

      final undo1 = engine.undoMove();
      expect(undo1.isSuccess, isTrue);
      expect(undo1.undoneMove?.pieceId, 'B_02');
      var state = engine.getGameState();
      expect(state.currentTurn, PlayerSide.b);
      expect(state.pieceAt('r3_c1')?.id, 'B_02');
      expect(state.isPositionEmpty('r2_c1'), isTrue);
      expect(state.moveHistory.length, 1);

      final undo2 = engine.undoMove();
      expect(undo2.isSuccess, isTrue);
      expect(undo2.undoneMove?.pieceId, 'A_07');
      state = engine.getGameState();
      expect(state.currentTurn, PlayerSide.a);
      expect(state.pieceAt('r1_c1')?.id, 'A_07');
      expect(state.isPositionEmpty('r2_c2'), isTrue);
      expect(state.moveHistory, isEmpty);
    });

    test('resetGame restores clean initial state', () {
      engine.makeMove('A_07', 'r2_c2');
      engine.makeMove('B_02', 'r2_c1');

      final resetState = engine.resetGame();
      expect(resetState.currentTurn, PlayerSide.a);
      expect(resetState.moveHistory, isEmpty);
      expect(resetState.pieceAt('r1_c1')?.id, 'A_07');
      expect(resetState.pieceAt('r3_c1')?.id, 'B_02');
      expect(resetState.isPositionEmpty('r2_c2'), isTrue);
    });

    test('supports full JSON serialization round-trip and loadState', () {
      engine.makeMove('A_07', 'r2_c2');
      engine.makeMove('B_04', 'r2_c4');

      final json = engine.getGameState().toJson();
      final restored = GameState.fromJson(json);

      final secondEngine = createCoChemEngine();
      secondEngine.loadState(restored);

      final s1 = engine.getGameState();
      final s2 = secondEngine.getGameState();
      expect(s2.currentTurn, s1.currentTurn);
      expect(s2.moveHistory, equals(s1.moveHistory));
      expect(s2.occupancy, equals(s1.occupancy));
      expect(s2.pieces, equals(s1.pieces));
    });

    test('extensible capture and win hooks integrate cleanly with undo', () {
      final extensibleEngine = createCoChemEngine(
        captureRule: const _TestCaptureRule('B_01'),
        winConditionRule: const _TestWinAfterOneMoveRule(),
      );

      final move = extensibleEngine.makeMove('A_07', 'r2_c2');
      expect(move.isSuccess, isTrue);
      expect(move.move?.capturedPieceIds, ['B_01']);

      var state = extensibleEngine.getGameState();
      expect(state.pieces['B_01']?.isCaptured, isTrue);
      expect(state.countPieces(PlayerSide.b), 9);
      expect(state.isGameOver, isTrue);
      expect(state.winner, PlayerSide.a);

      // Cannot move after game finished
      final afterWinMove = extensibleEngine.makeMove('B_02', 'r2_c1');
      expect(afterWinMove.isSuccess, isFalse);
      expect(afterWinMove.error, MoveError.gameAlreadyFinished);

      // Undo restores captured piece and resumes play
      final undo = extensibleEngine.undoMove();
      expect(undo.isSuccess, isTrue);
      state = extensibleEngine.getGameState();
      expect(state.isGameOver, isFalse);
      expect(state.winner, isNull);
      expect(state.pieces['B_01']?.isCaptured, isFalse);
      expect(state.countPieces(PlayerSide.b), 10);
    });
  });
}

