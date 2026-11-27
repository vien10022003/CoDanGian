import 'package:co_dan_gian/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _aiTestState({
  required Map<String, GamePiece> pieces,
  PlayerSide currentTurn = PlayerSide.b,
  String? activeChainPieceId,
}) {
  return GameState(
    gameTypeId: CoChemRules.typeId,
    board: CoChemBoard.createBoardGraph(),
    pieces: pieces,
    currentTurn: currentTurn,
    turnOrder: const [PlayerSide.a, PlayerSide.b],
    activeChainPieceId: activeChainPieceId,
  );
}

void main() {
  group('CoChemAiAgent (Easy, Medium, Hard)', () {
    const rules = CoChemRules();

    test('FolkGameRegistry creates AI agents for all 3 difficulty levels', () {
      final registry = FolkGameRegistry();
      for (final difficulty in AiDifficulty.values) {
        final agent = registry.createAiAgent(CoChemRules.typeId, difficulty);
        expect(agent, isNotNull);
        expect(agent!.difficulty, difficulty);
      }
      expect(registry.createAiAgent('co_ganh', AiDifficulty.easy), isNull);
    });

    test('all difficulty levels always return valid legal moves', () {
      final state = rules.createInitialState();
      final afterFirstMove = rules.applyMove(state, 'A_07', 'r2_c2').state;

      for (final difficulty in AiDifficulty.values) {
        final agent = CoChemAiAgent(difficulty: difficulty, randomSeed: 42);
        final move = agent.chooseNextMove(rules, afterFirstMove);
        expect(move, isNotNull);

        final legalForPiece = rules.getLegalMoves(afterFirstMove, move!.pieceId);
        expect(legalForPiece, contains(move.targetPositionId));
      }
    });

    test('Medium and Hard take immediate winning capture over passive moves', () {
      // B_01 at r2_c0 can jump A_01 at r1_c0 to r0_c0 and win immediately!
      final state = _aiTestState(
        currentTurn: PlayerSide.b,
        pieces: const {
          'A_01': GamePiece(id: 'A_01', owner: PlayerSide.a, positionId: 'r1_c0'),
          'B_01': GamePiece(id: 'B_01', owner: PlayerSide.b, positionId: 'r2_c0'),
        },
      );

      for (final difficulty in [AiDifficulty.medium, AiDifficulty.hard]) {
        final agent = CoChemAiAgent(difficulty: difficulty, randomSeed: 7);
        final move = agent.chooseNextMove(rules, state);
        expect(move, const MoveCandidate(pieceId: 'B_01', targetPositionId: 'r0_c0'));

        final result = rules.applyMove(state, move!.pieceId, move.targetPositionId);
        expect(result.state.gameStatus, GameStatus.bWon);
      }
    });

    test('Hard chooses 2-piece capture chain branch over 1-piece capture branch', () {
      // B_01 at r2_c2 has TWO capture options:
      // 1) Left over A_01 (r2_c1) -> r2_c0 (only 1 capture, dead end)
      // 2) Right over A_02 (r2_c3) -> r2_c4, then DOWN over A_03 (r3_c4) -> r4_c4 (2 captures + win!)
      // Plus keep A_04 far away at r0_c0 so neither is immediate 1-step win,
      // making Hard compare 2-capture chain (+2000) vs 1-capture (+1000).
      final state = _aiTestState(
        currentTurn: PlayerSide.b,
        pieces: const {
          'B_01': GamePiece(id: 'B_01', owner: PlayerSide.b, positionId: 'r2_c2'),
          'A_01': GamePiece(id: 'A_01', owner: PlayerSide.a, positionId: 'r2_c1'),
          'A_02': GamePiece(id: 'A_02', owner: PlayerSide.a, positionId: 'r2_c3'),
          'A_03': GamePiece(id: 'A_03', owner: PlayerSide.a, positionId: 'r3_c4'),
          'A_04': GamePiece(id: 'A_04', owner: PlayerSide.a, positionId: 'r0_c0'),
        },
      );

      final hardAi = CoChemAiAgent(difficulty: AiDifficulty.hard, randomSeed: 1);
      final step1 = hardAi.chooseNextMove(rules, state);
      expect(step1, const MoveCandidate(pieceId: 'B_01', targetPositionId: 'r2_c4'));

      final afterStep1 =
          rules.applyMove(state, step1!.pieceId, step1.targetPositionId).state;
      expect(afterStep1.isChaining, isTrue);
      expect(afterStep1.currentTurn, PlayerSide.b);

      final step2 = hardAi.chooseNextMove(rules, afterStep1);
      expect(step2, const MoveCandidate(pieceId: 'B_01', targetPositionId: 'r4_c4'));
    });

    test('Hard avoids walking into a free opponent capture blunder', () {
      // B_01 at r3_c2: moving to r2_c2 lets A_01 (at r1_c2) jump B_01 to r3_c2 for free!
      // Safe moves (r3_c1, r3_c3, r4_c2) avoid losing material.
      final state = _aiTestState(
        currentTurn: PlayerSide.b,
        pieces: const {
          'A_01': GamePiece(id: 'A_01', owner: PlayerSide.a, positionId: 'r1_c2'),
          'A_02': GamePiece(id: 'A_02', owner: PlayerSide.a, positionId: 'r0_c0'),
          'B_01': GamePiece(id: 'B_01', owner: PlayerSide.b, positionId: 'r3_c2'),
          'B_02': GamePiece(id: 'B_02', owner: PlayerSide.b, positionId: 'r4_c0'),
        },
      );

      final hardAi = CoChemAiAgent(difficulty: AiDifficulty.hard, randomSeed: 3);
      final move = hardAi.chooseNextMove(rules, state);
      expect(move, isNotNull);

      final afterAiMove =
          rules.applyMove(state, move!.pieceId, move.targetPositionId).state;
      expect(rules.getCaptureMoves(afterAiMove, 'A_01'), isEmpty);
    });

    test('simulated multi-turn match runs cleanly without illegal moves', () {
      final engine = createCoChemEngine();
      final aiA = CoChemAiAgent(difficulty: AiDifficulty.medium, randomSeed: 10);
      final aiB = CoChemAiAgent(difficulty: AiDifficulty.hard, randomSeed: 20);

      for (var ply = 0; ply < 16; ply++) {
        final state = engine.getGameState();
        if (state.isGameOver) break;

        final activeAi = state.currentTurn == PlayerSide.a ? aiA : aiB;
        final move = activeAi.chooseNextMove(engine.rules, state);
        expect(move, isNotNull);

        final res = engine.makeMove(move!.pieceId, move.targetPositionId);
        expect(res.isSuccess, isTrue);
      }
    });
  });
}
