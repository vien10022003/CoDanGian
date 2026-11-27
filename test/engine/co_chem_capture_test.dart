import 'package:co_dan_gian/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _customCoChemState({
  required Map<String, GamePiece> pieces,
  PlayerSide currentTurn = PlayerSide.a,
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
  group('CoChem jump capture & multi-capture chains', () {
    test('supports horizontal, vertical, and diagonal jump captures', () {
      final state = _customCoChemState(
        pieces: const {
          'A_01': GamePiece(
            id: 'A_01',
            owner: PlayerSide.a,
            positionId: 'r1_c1',
          ),
          'B_01': GamePiece(
            id: 'B_01',
            owner: PlayerSide.b,
            positionId: 'r1_c2', // horizontal
          ),
          'B_02': GamePiece(
            id: 'B_02',
            owner: PlayerSide.b,
            positionId: 'r2_c1', // vertical
          ),
          'B_03': GamePiece(
            id: 'B_03',
            owner: PlayerSide.b,
            positionId: 'r2_c2', // diagonal (1,1 -> 2,2 -> 3,3)
          ),
        },
      );

      final engine = createCoChemEngine(initialState: state);

      expect(
        engine.getCaptureMoves('A_01'),
        unorderedEquals(['r1_c3', 'r3_c1', 'r3_c3']),
      );

      // getLegalMoves includes BOTH normal adjacent empty moves and capture targets
      expect(
        engine.getLegalMoves('A_01'),
        unorderedEquals([
          'r0_c0',
          'r0_c1',
          'r0_c2',
          'r1_c0',
          'r2_c0',
          'r1_c3',
          'r3_c1',
          'r3_c3',
        ]),
      );

      // Diagonal jump over B_03 onto r3_c3
      final result = engine.makeMove('A_01', 'r3_c3');
      expect(result.isSuccess, isTrue);
      expect(result.move?.capturedPieceIds, ['B_03']);

      final after = engine.getGameState();
      expect(after.pieceAt('r1_c1'), isNull);
      expect(after.pieceAt('r2_c2'), isNull);
      expect(after.pieceAt('r3_c3')?.id, 'A_01');
      expect(after.pieces['B_03']?.isCaptured, isTrue);
      expect(after.countPieces(PlayerSide.b), 2);
      expect(after.countCapturedBy(PlayerSide.a), 1);
      expect(after.currentTurn, PlayerSide.b);
      expect(after.activeChainPieceId, isNull);
    });

    test('blocks jumping over friendly pieces', () {
      final engine = createCoChemEngine(
        initialState: _customCoChemState(
          pieces: const {
            'A_01': GamePiece(id: 'A_01', owner: PlayerSide.a, positionId: 'r2_c0'),
            'A_02': GamePiece(id: 'A_02', owner: PlayerSide.a, positionId: 'r2_c1'),
          },
        ),
      );

      expect(engine.getCaptureMoves('A_01'), isEmpty);
      final jumpFriendly = engine.makeMove('A_01', 'r2_c2');
      expect(jumpFriendly.isSuccess, isFalse);
      expect(jumpFriendly.error, MoveError.notAdjacent);
    });

    test('blocks jumping when landing is occupied or farther than immediate behind', () {
      final engine = createCoChemEngine(
        initialState: _customCoChemState(
          pieces: const {
            'A_01': GamePiece(id: 'A_01', owner: PlayerSide.a, positionId: 'r0_c2'),
            'B_01': GamePiece(id: 'B_01', owner: PlayerSide.b, positionId: 'r1_c2'),
            'B_02': GamePiece(id: 'B_02', owner: PlayerSide.b, positionId: 'r2_c2'),
            // Separate isolated piece A_02 with empty r4_c0 behind B_03 at r3_c0?
            // Check jumping 2 squares past an enemy (r4_c4 -> B_03 r3_c4 -> r2_c4 empty, try r1_c4)
            'A_02': GamePiece(id: 'A_02', owner: PlayerSide.a, positionId: 'r4_c4'),
            'B_03': GamePiece(id: 'B_03', owner: PlayerSide.b, positionId: 'r3_c4'),
          },
        ),
      );

      expect(engine.getCaptureMoves('A_01'), isEmpty);
      expect(engine.makeMove('A_01', 'r2_c2').error, MoveError.targetOccupied);
      expect(engine.makeMove('A_01', 'r3_c2').error, MoveError.notAdjacent);

      // A_02 can jump to r2_c4 (immediately behind B_03), NOT r1_c4 (farther behind)
      expect(engine.getCaptureMoves('A_02'), ['r2_c4']);
      final tooFar = engine.makeMove('A_02', 'r1_c4');
      expect(tooFar.isSuccess, isFalse);
      expect(tooFar.error, MoveError.notAdjacent);
    });

    test('blocks jumping along bent paths or missing diagonal board edges', () {
      final engine = createCoChemEngine(
        initialState: _customCoChemState(
          pieces: const {
            // Odd-sum node r0_c1 cannot jump diagonally over r1_c2 to r2_c3
            'A_01': GamePiece(id: 'A_01', owner: PlayerSide.a, positionId: 'r0_c1'),
            'B_01': GamePiece(id: 'B_01', owner: PlayerSide.b, positionId: 'r1_c2'),
            // Bent line: A_02 at r3_c0 -> B_02 at r3_c1 -> r4_c2 (diagonal edge from r3_c1)
            'A_02': GamePiece(id: 'A_02', owner: PlayerSide.a, positionId: 'r3_c0'),
            'B_02': GamePiece(id: 'B_02', owner: PlayerSide.b, positionId: 'r3_c1'),
            'B_03': GamePiece(id: 'B_03', owner: PlayerSide.b, positionId: 'r3_c2'),
          },
        ),
      );

      expect(engine.getCaptureMoves('A_01'), isEmpty);
      expect(engine.makeMove('A_01', 'r2_c3').error, MoveError.notAdjacent);

      expect(engine.getCaptureMoves('A_02'), isEmpty);
      expect(engine.makeMove('A_02', 'r4_c2').error, MoveError.notAdjacent);
    });

    test('enforces mandatory multi-capture chain and locks other pieces until chain ends', () {
      // A_01 at r0_c0 -> jumps B_01 at r1_c0 -> lands r2_c0
      // Then MUST continue jumping B_02 at r2_c1 -> lands r2_c2
      // Also B_03 at r1_c1 cannot be jumped from r2_c0? Wait: r2_c0 -> r1_c1 -> r0_c2 (no, B_03 not there)
      final state = _customCoChemState(
        pieces: const {
          'A_01': GamePiece(
            id: 'A_01',
            owner: PlayerSide.a,
            positionId: 'r0_c0',
          ),
          'A_02': GamePiece(
            id: 'A_02',
            owner: PlayerSide.a,
            positionId: 'r0_c4',
          ),
          'B_01': GamePiece(
            id: 'B_01',
            owner: PlayerSide.b,
            positionId: 'r1_c0',
          ),
          'B_02': GamePiece(
            id: 'B_02',
            owner: PlayerSide.b,
            positionId: 'r2_c1',
          ),
          // Keep an extra B piece on board so match stays ongoing after 2-step chain
          'B_03': GamePiece(
            id: 'B_03',
            owner: PlayerSide.b,
            positionId: 'r4_c4',
          ),
        },
      );

      final engine = createCoChemEngine(initialState: state);

      // Step 1: jump B_01
      final step1 = engine.makeMove('A_01', 'r2_c0');
      expect(step1.isSuccess, isTrue);
      expect(step1.move?.capturedPieceIds, ['B_01']);

      var current = engine.getGameState();
      expect(current.currentTurn, PlayerSide.a);
      expect(current.isChaining, isTrue);
      expect(current.activeChainPieceId, 'A_01');
      expect(current.pieces['B_01']?.isCaptured, isTrue);

      // During chain, only A_01 can move and only to capture targets
      expect(engine.getLegalMoves('A_01'), ['r2_c2']);
      expect(engine.getCaptureMoves('A_01'), ['r2_c2']);
      expect(engine.getLegalMoves('A_02'), isEmpty);
      expect(engine.getCaptureMoves('A_02'), isEmpty);

      final switchPiece = engine.makeMove('A_02', 'r0_c3');
      expect(switchPiece.isSuccess, isFalse);
      expect(switchPiece.error, MoveError.mustContinueCaptureChain);

      final nonCaptureStep = engine.makeMove('A_01', 'r3_c0');
      expect(nonCaptureStep.isSuccess, isFalse);
      expect(nonCaptureStep.error, MoveError.mustContinueCaptureChain);

      // Step 2: continue chain by jumping B_02
      final step2 = engine.makeMove('A_01', 'r2_c2');
      expect(step2.isSuccess, isTrue);
      expect(step2.move?.capturedPieceIds, ['B_02']);
      expect(step2.move?.isChainContinuation, isTrue);
      expect(step2.move?.previousChainPieceId, 'A_01');

      current = engine.getGameState();
      expect(current.isChaining, isFalse);
      expect(current.activeChainPieceId, isNull);
      expect(current.currentTurn, PlayerSide.b);
      expect(current.pieces['B_01']?.isCaptured, isTrue);
      expect(current.pieces['B_02']?.isCaptured, isTrue);
      expect(current.moveHistory.length, 2);
    });

    test('allows player to choose branch during multi-capture chain and supports undo & JSON mid-chain', () {
      // A_01 at r0_c2 jumps B_01 at r1_c2 to r2_c2.
      // At r2_c2, A_01 has TWO capture options:
      // 1) right over B_02 (r2_c3) -> r2_c4
      // 2) diagonal down-left over B_03 (r3_c1) -> r4_c0
      final state = _customCoChemState(
        pieces: const {
          'A_01': GamePiece(
            id: 'A_01',
            owner: PlayerSide.a,
            positionId: 'r0_c2',
          ),
          'B_01': GamePiece(
            id: 'B_01',
            owner: PlayerSide.b,
            positionId: 'r1_c2',
          ),
          'B_02': GamePiece(
            id: 'B_02',
            owner: PlayerSide.b,
            positionId: 'r2_c3',
          ),
          'B_03': GamePiece(
            id: 'B_03',
            owner: PlayerSide.b,
            positionId: 'r3_c1',
          ),
        },
      );

      final engine = createCoChemEngine(initialState: state);

      expect(engine.makeMove('A_01', 'r2_c2').isSuccess, isTrue);

      // Verify both capture directions available
      expect(
        engine.getCaptureMoves('A_01'),
        unorderedEquals(['r2_c4', 'r4_c0']),
      );

      // Verify JSON serialization round-trip mid-chain preserves activeChainPieceId
      final midChainJson = engine.getGameState().toJson();
      final reloadedEngine = createCoChemEngine();
      reloadedEngine.loadState(GameState.fromJson(midChainJson));
      expect(reloadedEngine.getGameState().activeChainPieceId, 'A_01');
      expect(
        reloadedEngine.getLegalMoves('A_01'),
        unorderedEquals(['r2_c4', 'r4_c0']),
      );

      // Choose branch 1 (r2_c4)
      expect(engine.makeMove('A_01', 'r2_c4').isSuccess, isTrue);
      expect(engine.getGameState().currentTurn, PlayerSide.b);
      expect(engine.getGameState().pieces['B_02']?.isCaptured, isTrue);
      expect(engine.getGameState().pieces['B_03']?.isCaptured, isFalse);

      // Undo step 2 -> returns to mid-chain choice at r2_c2
      final undoStep2 = engine.undoMove();
      expect(undoStep2.isSuccess, isTrue);
      var restored = engine.getGameState();
      expect(restored.currentTurn, PlayerSide.a);
      expect(restored.activeChainPieceId, 'A_01');
      expect(restored.pieceAt('r2_c2')?.id, 'A_01');
      expect(restored.pieces['B_02']?.isCaptured, isFalse);
      expect(restored.pieceAt('r2_c3')?.id, 'B_02');

      // Now choose branch 2 instead (r4_c0)
      expect(engine.makeMove('A_01', 'r4_c0').isSuccess, isTrue);
      expect(engine.getGameState().pieces['B_03']?.isCaptured, isTrue);
      expect(engine.getGameState().pieces['B_02']?.isCaptured, isFalse);

      // Undo both moves back to clean start
      expect(engine.undoMove().isSuccess, isTrue);
      expect(engine.undoMove().isSuccess, isTrue);
      restored = engine.getGameState();
      expect(restored.activeChainPieceId, isNull);
      expect(restored.currentTurn, PlayerSide.a);
      expect(restored.pieceAt('r0_c2')?.id, 'A_01');
      expect(restored.pieces['B_01']?.isCaptured, isFalse);
      expect(restored.moveHistory, isEmpty);
    });
  });
}
