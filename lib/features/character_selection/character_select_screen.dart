import 'dart:math' as math;

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

/// Two simple steps: tap your hero, then tap who to fight.
class CharacterSelectScreen extends ConsumerStatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  ConsumerState<CharacterSelectScreen> createState() =>
      _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends ConsumerState<CharacterSelectScreen> {
  bool _pickingOpponent = false;

  void _back() {
    if (_pickingOpponent) {
      setState(() => _pickingOpponent = false);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _surprise() {
    final setup = ref.read(battleSetupProvider);
    final others = HeroRoster.all
        .where((h) => h.id != setup.player.id)
        .toList();
    ref
        .read(battleSetupProvider.notifier)
        .selectOpponent(others[math.Random().nextInt(others.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(battleSetupProvider);
    final notifier = ref.read(battleSetupProvider.notifier);
    final accent = _pickingOpponent
        ? AppColors.opponentAccent
        : AppColors.playerAccent;

    return PopScope(
      canPop: !_pickingOpponent,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
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
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ComicText(
                          _pickingOpponent
                              ? AppStrings.chooseOpponent
                              : AppStrings.chooseHero,
                          key: ValueKey(_pickingOpponent),
                          size: 30,
                          outline: 6,
                          color: _pickingOpponent
                              ? AppColors.opponentAccent
                              : AppColors.gold,
                        ),
                      ),
                    ),
                    _StepDots(step: _pickingOpponent ? 1 : 0),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final hero in HeroRoster.all) ...[
                        if (hero != HeroRoster.all.first)
                          const SizedBox(width: 8),
                        Expanded(
                          child: HeroCard(
                            key: ValueKey(
                              '${_pickingOpponent ? 'opponent' : 'player'}_${hero.id}',
                            ),
                            hero: hero,
                            accent: accent,
                            facing: _pickingOpponent ? -1 : 1,
                            selected: _pickingOpponent
                                ? setup.opponent.id == hero.id
                                : setup.player.id == hero.id,
                            disabled:
                                _pickingOpponent && setup.player.id == hero.id,
                            badge:
                                _pickingOpponent && setup.player.id == hero.id
                                ? AppStrings.you
                                : null,
                            onTap: () => _pickingOpponent
                                ? notifier.selectOpponent(hero)
                                : notifier.selectPlayer(hero),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: _pickingOpponent
                      ? Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final d in AiDifficulty.values)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(d.label),
                                          selected: setup.difficulty == d,
                                          onSelected: (_) =>
                                              notifier.setDifficulty(d),
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    ActionChip(
                                      avatar: const Icon(
                                        Icons.casino_rounded,
                                        size: 18,
                                      ),
                                      label: const Text(AppStrings.random),
                                      onPressed: _surprise,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ArcadeButton(
                              key: const ValueKey('start_battle'),
                              label: AppStrings.startBattle,
                              icon: Icons.sports_mma_rounded,
                              fontSize: 20,
                              onPressed: () =>
                                  Navigator.of(context)
                                      .pushNamed(Routes.versus),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${AppStrings.superpower}: '
                                '${setup.player.special.name}  ·  '
                                '${setup.player.special.description}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.cream,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ArcadeButton(
                              key: const ValueKey('next_step'),
                              label: AppStrings.next,
                              icon: Icons.arrow_forward_rounded,
                              fontSize: 20,
                              onPressed: () =>
                                  setState(() => _pickingOpponent = true),
                            ),
                          ],
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

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 2; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == step ? 16 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i == step ? AppColors.gold : AppColors.cream,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}
