import 'package:material_ui/material_ui.dart';

import '../../core/audio/game_audio.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/hero_preview.dart';
import '../battle/characters/hero_definition.dart';
import '../battle/combat/fighter_state.dart';

/// A big, tappable hero card with a live animated preview.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.hero,
    required this.selected,
    required this.onTap,
    required this.accent,
    this.disabled = false,
    this.facing = 1,
    this.badge,
  });

  final HeroDefinition hero;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  final Color accent;
  final int facing;

  /// Optional small label in the corner, e.g. "YOU".
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      label: hero.name,
      child: GestureDetector(
        onTap: disabled
            ? null
            : () {
                GameAudio.instance.play(Sfx.tap);
                onTap();
              },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: disabled ? 0.45 : 1,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: selected ? 1.0 : 0.94,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: selected ? AppColors.cream : const Color(0xCCFFF4E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? accent : AppColors.ink,
                  width: selected ? 5 : 3,
                ),
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: accent.withValues(alpha: 0.7),
                      blurRadius: 16,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                hero.look.suit.withValues(alpha: 0.2),
                                hero.special.color.withValues(alpha: 0.45),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: HeroPreview(
                            hero: hero,
                            facing: facing,
                            state: selected
                                ? FighterState.victory
                                : FighterState.idle,
                            animate: !disabled,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          hero.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: Color(0xFFE0A800),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              hero.special.name,
                              style: const TextStyle(
                                color: Color(0xFF3B3D5C),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (badge != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.playerAccent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
