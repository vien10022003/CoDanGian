import 'package:material_ui/material_ui.dart';

import '../../engine/engine.dart';
import '../theme/viet_theme.dart';
import '../widgets/viet_background.dart';
import 'game_play_screen.dart';

/// Game selection lobby populated dynamically from [FolkGameRegistry].
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.registry,
  });

  final FolkGameRegistry registry;

  @override
  Widget build(BuildContext context) {
    final games = registry.allGames;

    return Scaffold(
      body: VietCulturalBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  const Text(
                    'CHỌN TRÒ CHƠI',
                    style: TextStyle(
                      color: VietTheme.bronzeGoldLight,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < games.length; i++) ...[
                    _GameCatalogCard(
                      game: games[i],
                      onTap: () => _handleGameTap(context, games[i]),
                    ),
                    if (i < games.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VietTheme.lacquerRed.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(
          color: VietTheme.bronzeGold.withValues(alpha: 0.52),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  VietTheme.bronzeGoldLight,
                  VietTheme.bronzeGold,
                  VietTheme.bronzeGoldDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: VietTheme.bronzeGold.withValues(alpha: 0.35),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Icon(
              Icons.grid_on_rounded,
              color: VietTheme.lacquerDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cờ Dân Gian',
                  style: TextStyle(
                    color: VietTheme.parchment,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tinh hoa trò chơi bàn cờ truyền thống Việt Nam',
                  style: TextStyle(
                    color: VietTheme.parchmentSoft,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleGameTap(BuildContext context, FolkGameDescriptor game) {
    if (!game.isPlayable) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF331412),
            content: Text(
              '${game.name} đang được phát triển ở giai đoạn tiếp theo.',
              style: const TextStyle(color: VietTheme.parchment),
            ),
          ),
        );
      return;
    }

    final engine = registry.createEngine(game.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePlayScreen(
          game: game,
          engine: engine,
        ),
      ),
    );
  }
}

class _GameCatalogCard extends StatelessWidget {
  const _GameCatalogCard({
    required this.game,
    required this.onTap,
  });

  final FolkGameDescriptor game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPlayable = game.isPlayable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPlayable
                  ? [
                      const Color(0xFF4B1815).withValues(alpha: 0.94),
                      const Color(0xFF280D0C).withValues(alpha: 0.96),
                    ]
                  : [
                      const Color(0xFF2D1412).withValues(alpha: 0.72),
                      const Color(0xFF1E0B0A).withValues(alpha: 0.78),
                    ],
            ),
            border: Border.all(
              color: isPlayable
                  ? VietTheme.bronzeGold.withValues(alpha: 0.75)
                  : VietTheme.bronzeGold.withValues(alpha: 0.24),
              width: isPlayable ? 1.6 : 1.0,
            ),
            boxShadow: isPlayable
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.42),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          style: TextStyle(
                            color: isPlayable
                                ? VietTheme.parchment
                                : VietTheme.parchmentSoft.withValues(alpha: 0.75),
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          game.tagline,
                          style: TextStyle(
                            color: isPlayable
                                ? VietTheme.bronzeGoldLight
                                : VietTheme.bronzeGold.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(
                    label: game.playerModeLabel,
                    isPlayable: isPlayable,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                game.description,
                style: TextStyle(
                  color: VietTheme.parchmentSoft.withValues(
                    alpha: isPlayable ? 0.92 : 0.62,
                  ),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: VietTheme.bronzeGold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        game.boardSummary,
                        style: const TextStyle(
                          color: VietTheme.parchmentSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isPlayable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [
                              VietTheme.bronzeGoldLight,
                              VietTheme.bronzeGold,
                            ],
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Chơi ngay',
                              style: TextStyle(
                                color: VietTheme.lacquerDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: VietTheme.lacquerDark,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.isPlayable,
  });

  final String label;
  final bool isPlayable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isPlayable
            ? VietTheme.legalHighlight.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: isPlayable
              ? VietTheme.legalHighlightGlow.withValues(alpha: 0.65)
              : VietTheme.parchmentSoft.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPlayable
              ? VietTheme.legalHighlightGlow
              : VietTheme.parchmentSoft.withValues(alpha: 0.72),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

