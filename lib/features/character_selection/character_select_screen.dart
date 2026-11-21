import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/battle_setup.dart';
import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/arcade_button.dart';
import '../../shared/widgets/comic_text.dart';
import '../../shared/widgets/menu_background.dart';
import '../battle/ai/ai_difficulty.dart';
import '../battle/characters/hero_roster.dart';
import 'hero_card.dart';

/// Pick your hero, pick the computer's hero, choose difficulty, fight.
class CharacterSelectScreen extends ConsumerWidget {
  const CharacterSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(battleSetupProvider);
    final notifier = ref.read(battleSetupProvider.notifier);

    return Scaffold(
      body: MenuBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton.filled(
                    tooltip: 'Back',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cream,
                      foregroundColor: AppColors.ink,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ComicText(
                        AppStrings.selectHero,
                        size: 30,
                        outline: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Panel(
                        title: AppStrings.you,
                        accent: AppColors.playerAccent,
                        children: [
                          for (final hero in HeroRoster.all)
                            HeroCard(
                              key: ValueKey('player_${hero.id}'),
                              hero: hero,
                              selected: setup.player.id == hero.id,
                              accent: AppColors.playerAccent,
                              onTap: () => notifier.selectPlayer(hero),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Center(
                      child: ComicText('VS', size: 34, color: AppColors.cream),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Panel(
                        title: AppStrings.cpu,
                        accent: AppColors.opponentAccent,
                        children: [
                          for (final hero in HeroRoster.all)
                            HeroCard(
                              key: ValueKey('opponent_${hero.id}'),
                              hero: hero,
                              facing: -1,
                              selected: setup.opponent.id == hero.id,
                              disabled: setup.player.id == hero.id,
                              accent: AppColors.opponentAccent,
                              onTap: () => notifier.selectOpponent(hero),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    '${AppStrings.difficulty}:',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.cream,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final d in AiDifficulty.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(d.label),
                        selected: setup.difficulty == d,
                        onSelected: (_) => notifier.setDifficulty(d),
                      ),
                    ),
                  const Spacer(),
                  ArcadeButton(
                    key: const ValueKey('start_battle'),
                    label: AppStrings.startBattle,
                    icon: Icons.sports_mma_rounded,
                    fontSize: 20,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.versus),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.accent,
    required this.children,
  });

  final String title;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0x3312142A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: children[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
