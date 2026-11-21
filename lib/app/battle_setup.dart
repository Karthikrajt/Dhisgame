import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/battle/ai/ai_difficulty.dart';
import '../features/battle/characters/hero_definition.dart';
import '../features/battle/characters/hero_roster.dart';

/// The choices made before a battle: heroes and difficulty.
class BattleSetup {
  const BattleSetup({
    required this.player,
    required this.opponent,
    this.difficulty = AiDifficulty.easy,
  });

  final HeroDefinition player;
  final HeroDefinition opponent;
  final AiDifficulty difficulty;

  BattleSetup copyWith({
    HeroDefinition? player,
    HeroDefinition? opponent,
    AiDifficulty? difficulty,
  }) {
    return BattleSetup(
      player: player ?? this.player,
      opponent: opponent ?? this.opponent,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

class BattleSetupNotifier extends Notifier<BattleSetup> {
  @override
  BattleSetup build() => const BattleSetup(
    player: HeroRoster.spiderShadow,
    opponent: HeroRoster.darkKnight,
  );

  /// Picks the player's hero. If it clashes with the opponent, the opponent
  /// switches to another hero so there is always a fair match-up.
  void selectPlayer(HeroDefinition hero) {
    var opponent = state.opponent;
    if (opponent.id == hero.id) {
      opponent = HeroRoster.all.firstWhere((h) => h.id != hero.id);
    }
    state = state.copyWith(player: hero, opponent: opponent);
  }

  void selectOpponent(HeroDefinition hero) {
    if (hero.id == state.player.id) return;
    state = state.copyWith(opponent: hero);
  }

  void setDifficulty(AiDifficulty difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }
}

final battleSetupProvider = NotifierProvider<BattleSetupNotifier, BattleSetup>(
  BattleSetupNotifier.new,
);
