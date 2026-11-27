import 'package:co_dan_gian/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _winTestState({
  required Map<String, GamePiece> pieces,
  PlayerSide currentTurn = PlayerSide.a,
}) {
  return GameState(
    gameTypeId: CoChemRules.typeId,
    board: CoChemBoard.createBoardGraph(),
    pieces: pieces,
    currentTurn: currentTurn,
    turnOrder: const [PlayerSide.a, PlayerSide.b],
  );
}

void main() {
  group('CoChem victory conditions (checkGameOver & gameStatus)', () {
    test('returns playing while both sides have remaining pieces', () {
      final engine = createCoChemEngine();
      expect(engine.checkGameOver(), GameStatus.playing);
      expect(engine.checkGameOver().code, 'playing');
      expect(engine.getGameState().gameStatus, GameStatus.playing);
    });

    test('Side A wins (A_won) immediately when last Side B piece is captured', () {
      final engine = createCoChemEngine(
        initialState: _winTestState(
          pieces: const {
            'A_01': GamePiece(id: 'A_01', owner: PlayerSide.a, positionId: 'r0_c0'),
            'B_01': GamePiece(id: 'B_01', owner: PlayerSide.b, positionId: 'r1_c0'),
          },
        ),
      );

      final result = engine.makeMove('A_01', 'r2_c0');
      expect(result.isSuccess, isTrue);

      final state = engine.getGameState();
      expect(engine.checkGameOver(), GameStatus.aWon);
      expect(state.gameStatus, GameStatus.aWon);
      expect(state.gameStatus.code, 'A_won');
      expect(state.isGameOver, isTrue);
      expect(state.winner, PlayerSide.a);
      expect(state.countPieces(PlayerSide.b), 0);
      expect(state.isChaining, isFalse);
      expect(state.activeChainPieceId, isNull);
      // Turn must not switch to opponent after game ends
      expect(state.currentTurn, PlayerSide.a);

      // No moves allowed once finished
      expect(engine.getLegalMoves('A_01'), isEmpty);
      expect(engine.getCaptureMoves('A_01'), isEmpty);
      expect(engine.getAllLegalMoves(), isEmpty);
      final afterEnd = engine.makeMove('A_01', 'r2_c1');
      expect(afterEnd.isSuccess, isFalse);
      expect(afterEnd.error, MoveError.gameAlreadyFinished);
    });

    test('Side B wins (B_won) immediately when last Side A piece is captured', () {
      final engine = createCoChemEngine(
        initialState: _winTestState(
          currentTurn: PlayerSide.b,
          pieces: const {
            'A_01': GamePiece(id: 'A_01', owner: PlayerSide.a, positionId: 'r2_c2'),
            'B_01': GamePiece(id: 'B_01', owner: PlayerSide.b, positionId: 'r3_c3'),
          },
        ),
      );

      final result = engine.makeMove('B_01', 'r1_c1');
      expect(result.isSuccess, isTrue);

      final state = engine.getGameState();
      expect(engine.checkGameOver(), GameStatus.bWon);
      expect(state.gameStatus, GameStatus.bWon);
      expect(state.gameStatus.code, 'B_won');
      expect(state.winner, PlayerSide.b);
      expect(state.countPieces(PlayerSide.a), 0);
      expect(state.currentTurn, PlayerSide.b);
    });

    test('terminates multi-capture chain immediately without switching turn on final capture', () {
      final engine = createCoChemEngine(
        initialState: _winTestState(
          pieces: const {
            'A_01': GamePiece(id: 'A_01', owner: PlayerSide.a, positionId: 'r0_c0'),
            'B_01': GamePiece(id: 'B_01', owner: PlayerSide.b, positionId: 'r1_c0'),
            'B_02': GamePiece(id: 'B_02', owner: PlayerSide.b, positionId: 'r2_c1'),
          },
        ),
      );

      // Jump 1 captures B_01, B_02 remains -> chain continues for A_01
      final step1 = engine.makeMove('A_01', 'r2_c0');
      expect(step1.isSuccess, isTrue);
      expect(engine.checkGameOver(), GameStatus.playing);
      expect(engine.getGameState().isChaining, isTrue);
      expect(engine.getGameState().activeChainPieceId, 'A_01');

      // Jump 2 captures final B piece (B_02) -> ends chain & match immediately
      final step2 = engine.makeMove('A_01', 'r2_c2');
      expect(step2.isSuccess, isTrue);

      final finalState = engine.getGameState();
      expect(engine.checkGameOver(), GameStatus.aWon);
      expect(finalState.gameStatus, GameStatus.aWon);
      expect(finalState.isChaining, isFalse);
      expect(finalState.activeChainPieceId, isNull);
      expect(finalState.currentTurn, PlayerSide.a);
      expect(finalState.winner, PlayerSide.a);

      // JSON round-trip preserves A_won status
      final restored = GameState.fromJson(finalState.toJson());
      expect(restored.gameStatus, GameStatus.aWon);
      expect(restored.isGameOver, isTrue);
      expect(restored.winner, PlayerSide.a);

      // Undo reverts back to mid-chain state cleanly
      final undo = engine.undoMove();
      expect(undo.isSuccess, isTrue);
      expect(engine.checkGameOver(), GameStatus.playing);
      expect(engine.getGameState().isChaining, isTrue);
      expect(engine.getGameState().activeChainPieceId, 'A_01');

      // Reset restores standard initial 20-piece board
      final reset = engine.resetGame();
      expect(engine.checkGameOver(), GameStatus.playing);
      expect(reset.countPieces(PlayerSide.a), 10);
      expect(reset.countPieces(PlayerSide.b), 10);
    });
  });
}

