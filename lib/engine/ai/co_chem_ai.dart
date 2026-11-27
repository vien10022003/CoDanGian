import 'dart:math' as math;

import '../contracts/game_rules.dart';
import '../models/board_position.dart';
import '../models/engine_results.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import '../models/player_side.dart';
import 'game_ai.dart';

/// Pure-Dart AI player for Cờ Chém supporting Easy, Medium, and Hard levels.
///
/// Uses Minimax with Alpha-Beta pruning, capture-aware move ordering,
/// multi-capture chain continuation, and capture quiescence search.
class CoChemAiAgent implements GameAiAgent {
  CoChemAiAgent({
    required this.difficulty,
    int? randomSeed,
    this.hardTimeBudget = const Duration(milliseconds: 850),
  }) : _random = math.Random(randomSeed);

  @override
  final AiDifficulty difficulty;

  /// Maximum search budget for iterative deepening on [AiDifficulty.hard].
  final Duration hardTimeBudget;

  final math.Random _random;

  static const int _winScore = 100000;
  static const int _infinity = 10000000;
  static const int _maxChainExtensions = 8;

  @override
  MoveCandidate? chooseNextMove(GameRules rules, GameState state) {
    if (state.isGameOver) return null;

    final aiSide = state.currentTurn;
    final candidates = rules.getAllLegalMoves(state, aiSide);
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    return switch (difficulty) {
      AiDifficulty.easy => _chooseEasyMove(rules, state, aiSide, candidates),
      AiDifficulty.medium => _chooseAlphaBetaMove(
          rules: rules,
          state: state,
          aiSide: aiSide,
          candidates: candidates,
          maxDepth: 3,
          quiescenceDepth: 2,
          toleranceWindow: 24,
        ),
      AiDifficulty.hard => _chooseIterativeDeepeningMove(
          rules: rules,
          state: state,
          aiSide: aiSide,
          candidates: candidates,
          maxDepth: 5,
          quiescenceDepth: 3,
        ),
    };
  }

  MoveCandidate _chooseEasyMove(
    GameRules rules,
    GameState state,
    PlayerSide aiSide,
    List<MoveCandidate> candidates,
  ) {
    final captureTargets = _captureTargetSet(rules, state, aiSide);
    final ordered = _orderCandidates(
      state: state,
      candidates: candidates,
      captureTargets: captureTargets,
    );

    final scored = <_ScoredMove>[];
    var bestScore = -_infinity;

    for (final candidate in ordered) {
      final res = rules.applyMove(
        state,
        candidate.pieceId,
        candidate.targetPositionId,
      );
      if (!res.isSuccess) continue;

      var score = _evaluate(res.state, aiSide);
      // Slight reluctance to repeat previous non-capture move.
      if (_isImmediateBacktrack(state, aiSide, candidate, captureTargets)) {
        score -= 55;
      }
      if (score > bestScore) {
        bestScore = score;
      }
      scored.add(_ScoredMove(candidate, score));
    }

    if (scored.isEmpty) return candidates.first;

    // Pick randomly among moves within a generous 220-point tactical window
    // so Easy plays plausible moves while still making occasional mistakes.
    final pool = scored
        .where((m) => m.score >= bestScore - 220)
        .map((m) => m.move)
        .toList(growable: false);

    return pool[_random.nextInt(pool.length)];
  }

  MoveCandidate _chooseAlphaBetaMove({
    required GameRules rules,
    required GameState state,
    required PlayerSide aiSide,
    required List<MoveCandidate> candidates,
    required int maxDepth,
    required int quiescenceDepth,
    required int toleranceWindow,
  }) {
    final captureTargets = _captureTargetSet(rules, state, aiSide);
    final ordered = _orderCandidates(
      state: state,
      candidates: candidates,
      captureTargets: captureTargets,
    );

    final scored = <_ScoredMove>[];
    var bestScore = -_infinity;

    for (final candidate in ordered) {
      final res = rules.applyMove(
        state,
        candidate.pieceId,
        candidate.targetPositionId,
      );
      if (!res.isSuccess) continue;

      final nextState = res.state;
      final nextDepth = nextState.isChaining ? maxDepth : maxDepth - 1;
      var score = _alphaBeta(
        rules: rules,
        state: nextState,
        depth: nextDepth,
        quiescenceDepth: quiescenceDepth,
        chainExtensionsLeft:
            nextState.isChaining ? _maxChainExtensions - 1 : _maxChainExtensions,
        alpha: -_infinity,
        beta: _infinity,
        aiSide: aiSide,
        ply: 1,
      );

      if (_isImmediateBacktrack(state, aiSide, candidate, captureTargets)) {
        score -= 45;
      }

      if (score > bestScore) {
        bestScore = score;
      }
      scored.add(_ScoredMove(candidate, score));
    }

    if (scored.isEmpty) return candidates.first;

    final nearBest = scored
        .where((m) => m.score >= bestScore - toleranceWindow)
        .map((m) => m.move)
        .toList(growable: false);
    return nearBest[_random.nextInt(nearBest.length)];
  }

  MoveCandidate _chooseIterativeDeepeningMove({
    required GameRules rules,
    required GameState state,
    required PlayerSide aiSide,
    required List<MoveCandidate> candidates,
    required int maxDepth,
    required int quiescenceDepth,
  }) {
    final captureTargets = _captureTargetSet(rules, state, aiSide);
    var ordered = _orderCandidates(
      state: state,
      candidates: candidates,
      captureTargets: captureTargets,
    );

    final stopwatch = Stopwatch()..start();
    MoveCandidate bestMove = ordered.first;

    for (var depth = 2; depth <= maxDepth; depth++) {
      if (depth > 3 && stopwatch.elapsed >= hardTimeBudget) {
        break;
      }

      var bestScore = -_infinity;
      final bestMovesAtDepth = <MoveCandidate>[];
      final scoredForOrdering = <_ScoredMove>[];
      var completedDepth = true;

      for (final candidate in ordered) {
        if (depth > 3 && stopwatch.elapsed >= hardTimeBudget) {
          completedDepth = false;
          break;
        }

        final res = rules.applyMove(
          state,
          candidate.pieceId,
          candidate.targetPositionId,
        );
        if (!res.isSuccess) continue;

        final nextState = res.state;
        final nextDepth = nextState.isChaining ? depth : depth - 1;
        var score = _alphaBeta(
          rules: rules,
          state: nextState,
          depth: nextDepth,
          quiescenceDepth: quiescenceDepth,
          chainExtensionsLeft: nextState.isChaining
              ? _maxChainExtensions - 1
              : _maxChainExtensions,
          alpha: -_infinity,
          beta: _infinity,
          aiSide: aiSide,
          ply: 1,
          deadline: depth > 3 ? stopwatch : null,
        );

        if (_isImmediateBacktrack(state, aiSide, candidate, captureTargets)) {
          score -= 45;
        }

        scoredForOrdering.add(_ScoredMove(candidate, score));
        if (score > bestScore) {
          bestScore = score;
          bestMovesAtDepth
            ..clear()
            ..add(candidate);
        } else if (score == bestScore) {
          bestMovesAtDepth.add(candidate);
        }
      }

      if (completedDepth && bestMovesAtDepth.isNotEmpty) {
        bestMove = bestMovesAtDepth[_random.nextInt(bestMovesAtDepth.length)];
        scoredForOrdering.sort((a, b) => b.score.compareTo(a.score));
        ordered = scoredForOrdering.map((e) => e.move).toList(growable: false);
      } else if (bestMovesAtDepth.isNotEmpty && depth <= 3) {
        bestMove = bestMovesAtDepth.first;
      }
    }

    return bestMove;
  }

  int _alphaBeta({
    required GameRules rules,
    required GameState state,
    required int depth,
    required int quiescenceDepth,
    required int chainExtensionsLeft,
    required int alpha,
    required int beta,
    required PlayerSide aiSide,
    required int ply,
    Stopwatch? deadline,
  }) {
    if (state.isGameOver) {
      return state.winner == aiSide ? (_winScore - ply) : (-_winScore + ply);
    }

    if (deadline != null && deadline.elapsed >= hardTimeBudget) {
      return _evaluate(state, aiSide);
    }

    if (depth <= 0) {
      return _quiescence(
        rules: rules,
        state: state,
        qDepth: quiescenceDepth,
        chainExtensionsLeft: chainExtensionsLeft,
        alpha: alpha,
        beta: beta,
        aiSide: aiSide,
        ply: ply,
      );
    }

    final turnSide = state.currentTurn;
    final isMaximizing = turnSide == aiSide;
    final candidates = rules.getAllLegalMoves(state, turnSide);

    if (candidates.isEmpty) {
      return _evaluate(state, aiSide);
    }

    final captureTargets = _captureTargetSet(rules, state, turnSide);
    final ordered = _orderCandidates(
      state: state,
      candidates: candidates,
      captureTargets: captureTargets,
    );

    if (isMaximizing) {
      var value = -_infinity;
      for (final candidate in ordered) {
        final res = rules.applyMove(
          state,
          candidate.pieceId,
          candidate.targetPositionId,
        );
        if (!res.isSuccess) continue;

        final nextState = res.state;
        final extendForChain = nextState.isChaining && chainExtensionsLeft > 0;
        final nextDepth = extendForChain ? depth : depth - 1;
        final nextChainBudget =
            extendForChain ? chainExtensionsLeft - 1 : chainExtensionsLeft;

        final childScore = _alphaBeta(
          rules: rules,
          state: nextState,
          depth: nextDepth,
          quiescenceDepth: quiescenceDepth,
          chainExtensionsLeft: nextChainBudget,
          alpha: alpha,
          beta: beta,
          aiSide: aiSide,
          ply: ply + 1,
          deadline: deadline,
        );

        if (childScore > value) value = childScore;
        if (value > alpha) alpha = value;
        if (alpha >= beta) break;
      }
      return value;
    } else {
      var value = _infinity;
      for (final candidate in ordered) {
        final res = rules.applyMove(
          state,
          candidate.pieceId,
          candidate.targetPositionId,
        );
        if (!res.isSuccess) continue;

        final nextState = res.state;
        final extendForChain = nextState.isChaining && chainExtensionsLeft > 0;
        final nextDepth = extendForChain ? depth : depth - 1;
        final nextChainBudget =
            extendForChain ? chainExtensionsLeft - 1 : chainExtensionsLeft;

        final childScore = _alphaBeta(
          rules: rules,
          state: nextState,
          depth: nextDepth,
          quiescenceDepth: quiescenceDepth,
          chainExtensionsLeft: nextChainBudget,
          alpha: alpha,
          beta: beta,
          aiSide: aiSide,
          ply: ply + 1,
          deadline: deadline,
        );

        if (childScore < value) value = childScore;
        if (value < beta) beta = value;
        if (alpha >= beta) break;
      }
      return value;
    }
  }

  int _quiescence({
    required GameRules rules,
    required GameState state,
    required int qDepth,
    required int chainExtensionsLeft,
    required int alpha,
    required int beta,
    required PlayerSide aiSide,
    required int ply,
  }) {
    if (state.isGameOver) {
      return state.winner == aiSide ? (_winScore - ply) : (-_winScore + ply);
    }

    if (qDepth <= 0) {
      return _evaluate(state, aiSide);
    }

    final turnSide = state.currentTurn;
    final isMaximizing = turnSide == aiSide;

    // Must not stand pat while a mandatory multi-capture chain is active.
    if (!state.isChaining) {
      final standPat = _evaluate(state, aiSide);
      if (isMaximizing) {
        if (standPat >= beta) return beta;
        if (standPat > alpha) alpha = standPat;
      } else {
        if (standPat <= alpha) return alpha;
        if (standPat < beta) beta = standPat;
      }
    }

    final captureCandidates = _captureCandidatesOnly(rules, state, turnSide);
    if (captureCandidates.isEmpty) {
      return _evaluate(state, aiSide);
    }

    if (isMaximizing) {
      var value = state.isChaining ? -_infinity : alpha;
      for (final candidate in captureCandidates) {
        final res = rules.applyMove(
          state,
          candidate.pieceId,
          candidate.targetPositionId,
        );
        if (!res.isSuccess) continue;

        final nextState = res.state;
        final extendForChain = nextState.isChaining && chainExtensionsLeft > 0;
        final score = _quiescence(
          rules: rules,
          state: nextState,
          qDepth: extendForChain ? qDepth : qDepth - 1,
          chainExtensionsLeft:
              extendForChain ? chainExtensionsLeft - 1 : chainExtensionsLeft,
          alpha: alpha,
          beta: beta,
          aiSide: aiSide,
          ply: ply + 1,
        );
        if (score > value) value = score;
        if (value > alpha) alpha = value;
        if (alpha >= beta) break;
      }
      return value;
    } else {
      var value = state.isChaining ? _infinity : beta;
      for (final candidate in captureCandidates) {
        final res = rules.applyMove(
          state,
          candidate.pieceId,
          candidate.targetPositionId,
        );
        if (!res.isSuccess) continue;

        final nextState = res.state;
        final extendForChain = nextState.isChaining && chainExtensionsLeft > 0;
        final score = _quiescence(
          rules: rules,
          state: nextState,
          qDepth: extendForChain ? qDepth : qDepth - 1,
          chainExtensionsLeft:
              extendForChain ? chainExtensionsLeft - 1 : chainExtensionsLeft,
          alpha: alpha,
          beta: beta,
          aiSide: aiSide,
          ply: ply + 1,
        );
        if (score < value) value = score;
        if (value < beta) beta = value;
        if (alpha >= beta) break;
      }
      return value;
    }
  }

  /// Heuristic evaluation of [state] from [aiSide]'s perspective.
  int _evaluate(GameState state, PlayerSide aiSide) {
    if (state.isGameOver) {
      return state.winner == aiSide ? _winScore : -_winScore;
    }

    var score = 0;
    final board = state.board;

    for (final piece in state.pieces.values) {
      if (piece.isCaptured) continue;
      final isMine = piece.owner == aiSide;
      final sign = isMine ? 1 : -1;

      // Material value dominates tactical play.
      score += 1000 * sign;

      final pos = board.positionById(piece.positionId);
      if (pos == null) continue;

      final neighbors = board.neighborsOf(pos.id);

      // Control of central 8-way intersections and center square.
      var positional = 0;
      if (pos.row == 2 && pos.col == 2) {
        positional += 38;
      } else if (neighbors.length >= 8) {
        positional += 26;
      } else if (neighbors.length >= 5) {
        positional += 14;
      }

      // Gentle centralization bonus.
      final distFromCenter = (pos.row - 2).abs() + (pos.col - 2).abs();
      positional += (4 - distFromCenter) * 5;

      // Local mobility (empty neighbor count).
      var emptyNeighbors = 0;
      for (final neighborId in neighbors) {
        if (state.isPositionEmpty(neighborId)) {
          emptyNeighbors++;
        }
      }
      positional += emptyNeighbors * 11;

      // Threat/vulnerability check: penalize if an adjacent opponent can jump
      // directly over this piece on a straight board line.
      if (_isExposedToJumpCapture(state, piece, pos)) {
        positional -= (piece.owner == state.currentTurn) ? 35 : 130;
      }

      score += positional * sign;
    }

    return score;
  }

  bool _isExposedToJumpCapture(
    GameState state,
    GamePiece piece,
    BoardPosition pos,
  ) {
    final board = state.board;
    for (final neighborId in board.neighborsOf(piece.positionId)) {
      final attacker = state.pieceAt(neighborId);
      if (attacker == null || attacker.owner == piece.owner) continue;

      final attackerPos = board.positionById(neighborId);
      if (attackerPos == null) continue;

      final stepRow = pos.row - attackerPos.row;
      final stepCol = pos.col - attackerPos.col;

      for (final oppositeId in board.neighborsOf(piece.positionId)) {
        final oppositePos = board.positionById(oppositeId);
        if (oppositePos == null) continue;
        if (oppositePos.row - pos.row == stepRow &&
            oppositePos.col - pos.col == stepCol &&
            state.isPositionEmpty(oppositeId)) {
          return true;
        }
      }
    }
    return false;
  }

  Set<String> _captureTargetSet(
    GameRules rules,
    GameState state,
    PlayerSide side,
  ) {
    final set = <String>{};
    for (final piece in state.piecesFor(side)) {
      for (final target in rules.getCaptureMoves(state, piece.id)) {
        set.add('${piece.id}->$target');
      }
    }
    return set;
  }

  List<MoveCandidate> _captureCandidatesOnly(
    GameRules rules,
    GameState state,
    PlayerSide side,
  ) {
    final list = <MoveCandidate>[];
    for (final piece in state.piecesFor(side)) {
      for (final target in rules.getCaptureMoves(state, piece.id)) {
        list.add(MoveCandidate(pieceId: piece.id, targetPositionId: target));
      }
    }
    return list;
  }

  List<MoveCandidate> _orderCandidates({
    required GameState state,
    required List<MoveCandidate> candidates,
    required Set<String> captureTargets,
  }) {
    final sorted = List<MoveCandidate>.from(candidates);
    sorted.sort((a, b) {
      final aCap = captureTargets.contains('${a.pieceId}->${a.targetPositionId}')
          ? 1
          : 0;
      final bCap = captureTargets.contains('${b.pieceId}->${b.targetPositionId}')
          ? 1
          : 0;
      if (aCap != bCap) return bCap.compareTo(aCap);

      final aPos = state.board.positionById(a.targetPositionId);
      final bPos = state.board.positionById(b.targetPositionId);
      final aDeg = aPos == null ? 0 : state.board.neighborsOf(aPos.id).length;
      final bDeg = bPos == null ? 0 : state.board.neighborsOf(bPos.id).length;
      return bDeg.compareTo(aDeg);
    });
    return sorted;
  }

  bool _isImmediateBacktrack(
    GameState state,
    PlayerSide aiSide,
    MoveCandidate candidate,
    Set<String> captureTargets,
  ) {
    if (captureTargets.contains('${candidate.pieceId}->${candidate.targetPositionId}')) {
      return false;
    }
    for (var i = state.moveHistory.length - 1; i >= 0; i--) {
      final move = state.moveHistory[i];
      if (move.isCapture) return false;
      if (move.player == aiSide) {
        return move.pieceId == candidate.pieceId &&
            move.fromPositionId == candidate.targetPositionId;
      }
    }
    return false;
  }
}

class _ScoredMove {
  const _ScoredMove(this.move, this.score);

  final MoveCandidate move;
  final int score;
}
