import '../contracts/game_rules.dart';
import '../models/engine_results.dart';
import '../models/game_state.dart';

/// Difficulty levels supported by built-in AI opponents.
enum AiDifficulty {
  easy(
    id: 'easy',
    label: 'Dễ',
    description: 'Phù hợp làm quen luật chơi, thỉnh thoảng bỏ sót bẫy.',
  ),
  medium(
    id: 'medium',
    label: 'Trung bình',
    description: 'Tính trước nhiều nước và phản ứng nhanh với nước ăn quân.',
  ),
  hard(
    id: 'hard',
    label: 'Khó',
    description: 'Tìm kiếm sâu với Alpha-Beta, tính chuỗi ăn liên tiếp và giữ thế.',
  );

  const AiDifficulty({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

/// Pure-Dart AI agent contract capable of selecting a legal move for any
/// [GameState] governed by [GameRules].
abstract interface class GameAiAgent {
  AiDifficulty get difficulty;

  /// Selects the next legal move for [state.currentTurn], or returns null
  /// if the game is over or no legal moves exist.
  MoveCandidate? chooseNextMove(GameRules rules, GameState state);
}

