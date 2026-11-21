import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/comic_text.dart';
import '../../../shared/widgets/hero_preview.dart';
import '../characters/hero_definition.dart';
import '../characters/hero_pose.dart';
import '../combat/match_controller.dart';
import '../game/hud_state.dart';

/// Health bars, portraits, names, timer and round banners.
class BattleHud extends StatelessWidget {
  const BattleHud({
    super.key,
    required this.state,
    required this.player,
    required this.opponent,
  });

  final HudState state;
  final HeroDefinition player;
  final HeroDefinition opponent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 12,
          right: 12,
          top: 8,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FighterBar(
                  hero: player,
                  health: state.playerHealth,
                  accent: AppColors.playerAccent,
                  alignRight: false,
                ),
              ),
              const SizedBox(width: 10),
              _Timer(seconds: state.timeLeft),
              const SizedBox(width: 10),
              Expanded(
                child: _FighterBar(
                  hero: opponent,
                  health: state.opponentHealth,
                  accent: AppColors.opponentAccent,
                  alignRight: true,
                ),
              ),
            ],
          ),
        ),
        Center(
          child: IgnorePointer(child: _Banner(state: state)),
        ),
      ],
    );
  }
}

class _FighterBar extends StatelessWidget {
  const _FighterBar({
    required this.hero,
    required this.health,
    required this.accent,
    required this.alignRight,
  });

  final HeroDefinition hero;
  final double health;
  final Color accent;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final portrait = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 4),
        boxShadow: const [BoxShadow(color: AppColors.ink, spreadRadius: 2)],
      ),
      child: ClipOval(
        child: Transform.scale(
          scaleX: alignRight ? -1 : 1,
          child: HeroPortrait(
            hero: hero,
            mood: health <= 0
                ? EyeMood.dizzy
                : health < 0.3
                ? EyeMood.focused
                : EyeMood.normal,
          ),
        ),
      ),
    );

    final bars = Expanded(
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          HealthBar(value: health, reversed: alignRight),
          const SizedBox(height: 4),
          Text(
            hero.name.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1,
              shadows: const [Shadow(color: AppColors.ink, blurRadius: 3)],
            ),
          ),
        ],
      ),
    );

    return Row(
      children: alignRight
          ? [bars, const SizedBox(width: 8), portrait]
          : [portrait, const SizedBox(width: 8), bars],
    );
  }
}

/// A chunky health bar. The red "damage" layer drains slowly behind the
/// green bar so children can see how much a hit took.
class HealthBar extends StatelessWidget {
  const HealthBar({super.key, required this.value, this.reversed = false});

  final double value;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final align = reversed ? Alignment.centerRight : Alignment.centerLeft;
    final v = value.clamp(0.0, 1.0);
    final color = Color.lerp(
      AppColors.healthLow,
      AppColors.health,
      ((v - 0.2) / 0.4).clamp(0.0, 1.0),
    )!;
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ink, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF3A3557)),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              alignment: align,
              widthFactor: v,
              child: const ColoredBox(color: AppColors.damage),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 120),
              alignment: align,
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(color, Colors.white, 0.35)!, color],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timer extends StatelessWidget {
  const _Timer({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 4),
      ),
      child: Text(
        '$seconds',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: seconds <= 10 ? const Color(0xFFD84315) : AppColors.ink,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.state});
  final HudState state;

  String? get _text {
    switch (state.phase) {
      case MatchPhase.intro:
        return state.phaseTime < 1.0 ? AppStrings.ready : AppStrings.fight;
      case MatchPhase.fighting:
        return state.phaseTime < 0.6 ? AppStrings.fight : null;
      case MatchPhase.finished:
        return state.timeLeft <= 0 ? AppStrings.timeUp : AppStrings.knockout;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: text == null
          ? const SizedBox.shrink()
          : ComicText(text, key: ValueKey(text), size: 72, outline: 10),
    );
  }
}
