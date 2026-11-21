import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/hero_preview.dart';
import '../battle/characters/hero_definition.dart';
import '../battle/combat/fighter_state.dart';

/// A selectable hero card with a live animated preview.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.hero,
    required this.selected,
    required this.onTap,
    required this.accent,
    this.disabled = false,
    this.facing = 1,
  });

  final HeroDefinition hero;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  final Color accent;
  final int facing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      label: hero.name,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: disabled ? 0.4 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected ? AppColors.cream : const Color(0xCCFFF4E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? accent : AppColors.ink,
                width: selected ? 5 : 3,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 14),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          hero.look.suit.withValues(alpha: 0.25),
                          hero.look.trim.withValues(alpha: 0.35),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HeroPreview(
                      hero: hero,
                      facing: facing,
                      state: selected ? FighterState.victory : FighterState.idle,
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
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  hero.abilityDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF3B3D5C),
                    fontSize: 11,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
