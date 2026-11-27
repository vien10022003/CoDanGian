import '../contracts/game_engine.dart';
import '../games/co_chem/co_chem_rules.dart';

/// Metadata and factory registration for a traditional Vietnamese board game.
class FolkGameDescriptor {
  const FolkGameDescriptor({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.boardSummary,
    required this.playerModeLabel,
    required this.isPlayable,
    this.createEngine,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String boardSummary;
  final String playerModeLabel;
  final bool isPlayable;
  final GameEngine Function()? createEngine;
}

/// Central extensible catalog of Vietnamese folk board games.
///
/// New games (Cờ Gánh, Cờ Ba Tướng, etc.) are registered here with their own
/// [GameEngine] factory without modifying the game screen or lobby layout.
class FolkGameRegistry {
  FolkGameRegistry({List<FolkGameDescriptor>? games})
      : _games = List.unmodifiable(games ?? defaultGames);

  final List<FolkGameDescriptor> _games;

  static final List<FolkGameDescriptor> defaultGames = [
    FolkGameDescriptor(
      id: CoChemRules.typeId,
      name: 'Cờ Chém',
      tagline: 'Đấu trí dân gian trên bàn cờ 25 điểm',
      description:
          'Mỗi phe có 10 quân đối trận qua hàng giữa trống, di chuyển linh hoạt theo các đường ngang, dọc và chéo.',
      boardSummary: 'Bàn 5×5 · 20 quân',
      playerModeLabel: '2 người chơi',
      isPlayable: true,
      createEngine: () => createCoChemEngine(),
    ),
    const FolkGameDescriptor(
      id: 'co_ganh',
      name: 'Cờ Gánh',
      tagline: 'Gánh đôi lật thế, biến hóa khôn lường',
      description:
          'Trò chơi dân gian truyền thống với lối đánh gánh và chẹt đầy chiến thuật trên bàn cờ 5×5.',
      boardSummary: 'Bàn 5×5 · 16 quân',
      playerModeLabel: 'Sắp ra mắt',
      isPlayable: false,
    ),
    const FolkGameDescriptor(
      id: 'co_ba_tuong',
      name: 'Cờ Ba Tướng',
      tagline: 'Tam tướng xuất trận, giữ thành phá vây',
      description:
          'Biến thể cờ dân gian độc đáo với hệ thống tướng lĩnh và quân lính phối hợp công thủ.',
      boardSummary: 'Kiến trúc mở rộng',
      playerModeLabel: 'Sắp ra mắt',
      isPlayable: false,
    ),
  ];

  List<FolkGameDescriptor> get allGames => _games;

  FolkGameDescriptor? findById(String id) {
    for (final game in _games) {
      if (game.id == id) return game;
    }
    return null;
  }

  GameEngine createEngine(String gameId) {
    final descriptor = findById(gameId);
    if (descriptor == null) {
      throw ArgumentError('Unknown folk game ID: "$gameId".');
    }
    final factory = descriptor.createEngine;
    if (!descriptor.isPlayable || factory == null) {
      throw StateError(
        'Game "${descriptor.name}" ($gameId) is not playable yet.',
      );
    }
    return factory();
  }
}

