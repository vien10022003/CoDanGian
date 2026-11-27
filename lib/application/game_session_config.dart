import '../engine/engine.dart';

/// Play mode for a local match session.
enum GameMode {
  localTwoPlayer,
  vsAi,
}

/// Session configuration defining player mode and optional AI opponent settings.
class GameSessionConfig {
  const GameSessionConfig.localTwoPlayer()
      : mode = GameMode.localTwoPlayer,
        aiDifficulty = null,
        humanSide = PlayerSide.a,
        aiSide = PlayerSide.b;

  const GameSessionConfig.vsAi({
    required AiDifficulty difficulty,
  })  : mode = GameMode.vsAi,
        aiDifficulty = difficulty,
        humanSide = PlayerSide.a,
        aiSide = PlayerSide.b;

  final GameMode mode;
  final AiDifficulty? aiDifficulty;
  final PlayerSide humanSide;
  final PlayerSide aiSide;

  bool get isVsAi => mode == GameMode.vsAi;
}

