import 'package:material_ui/material_ui.dart';

import '../../application/game_session_config.dart';
import '../../engine/engine.dart';
import '../theme/viet_theme.dart';

/// Bottom sheet allowing the player to choose between 2-player local mode
/// and playing against the AI at Easy, Medium, or Hard difficulty.
class GameModeSheet extends StatefulWidget {
  const GameModeSheet({
    super.key,
    required this.game,
  });

  final FolkGameDescriptor game;

  @override
  State<GameModeSheet> createState() => _GameModeSheetState();
}

class _GameModeSheetState extends State<GameModeSheet> {
  AiDifficulty _selectedDifficulty = AiDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2B100E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: VietTheme.bronzeGold.withValues(alpha: 0.5),
              width: 1.4,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VietTheme.bronzeGold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Chọn chế độ · ${widget.game.name}',
                style: const TextStyle(
                  color: VietTheme.parchment,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                icon: Icons.people_alt_rounded,
                title: '2 người chơi',
                subtitle: 'Đấu tại chỗ trên cùng một thiết bị · A đi trước, B đi sau',
                onTap: () => Navigator.of(context).pop(
                  const GameSessionConfig.localTwoPlayer(),
                ),
              ),
              const SizedBox(height: 12),
              _AiModeCard(
                selectedDifficulty: _selectedDifficulty,
                onDifficultySelected: (difficulty) {
                  setState(() => _selectedDifficulty = difficulty);
                },
                onStartVsAi: () => Navigator.of(context).pop(
                  GameSessionConfig.vsAi(difficulty: _selectedDifficulty),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.black.withValues(alpha: 0.28),
            border: Border.all(
              color: VietTheme.bronzeGold.withValues(alpha: 0.45),
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VietTheme.lacquerRed.withValues(alpha: 0.8),
                  border: Border.all(
                    color: VietTheme.bronzeGold.withValues(alpha: 0.6),
                  ),
                ),
                child: Icon(icon, color: VietTheme.bronzeGoldLight, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: VietTheme.parchment,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: VietTheme.parchmentSoft.withValues(alpha: 0.8),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: VietTheme.bronzeGoldLight,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiModeCard extends StatelessWidget {
  const _AiModeCard({
    required this.selectedDifficulty,
    required this.onDifficultySelected,
    required this.onStartVsAi,
  });

  final AiDifficulty selectedDifficulty;
  final ValueChanged<AiDifficulty> onDifficultySelected;
  final VoidCallback onStartVsAi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF471815).withValues(alpha: 0.92),
            Colors.black.withValues(alpha: 0.36),
          ],
        ),
        border: Border.all(
          color: VietTheme.bronzeGold.withValues(alpha: 0.72),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VietTheme.sideBBlue,
                  border: Border.all(
                    color: VietTheme.bronzeGoldLight.withValues(alpha: 0.8),
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: VietTheme.parchment,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đấu với Máy',
                      style: TextStyle(
                        color: VietTheme.parchment,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Bạn cầm quân Đỏ (đi trước) · Máy cầm quân Xanh (đi sau)',
                      style: TextStyle(
                        color: VietTheme.parchmentSoft,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'MỨC ĐỘ KHÓ',
            style: TextStyle(
              color: VietTheme.bronzeGoldLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < AiDifficulty.values.length; i++) ...[
                Expanded(
                  child: _DifficultyButton(
                    difficulty: AiDifficulty.values[i],
                    isSelected: AiDifficulty.values[i] == selectedDifficulty,
                    onTap: () => onDifficultySelected(AiDifficulty.values[i]),
                  ),
                ),
                if (i < AiDifficulty.values.length - 1)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selectedDifficulty.description,
            style: TextStyle(
              color: VietTheme.parchmentSoft.withValues(alpha: 0.82),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: VietTheme.bronzeGold,
              foregroundColor: VietTheme.lacquerDark,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            onPressed: onStartVsAi,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(
              'Bắt đầu đấu với Máy (${selectedDifficulty.label})',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  final AiDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: isSelected
                ? VietTheme.bronzeGold.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.28),
            border: Border.all(
              color: isSelected
                  ? VietTheme.bronzeGoldLight
                  : VietTheme.bronzeGold.withValues(alpha: 0.25),
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                difficulty.label,
                style: TextStyle(
                  color: isSelected
                      ? VietTheme.bronzeGoldLight
                      : VietTheme.parchmentSoft.withValues(alpha: 0.78),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

