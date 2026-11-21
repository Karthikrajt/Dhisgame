import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/core/constants/game_constants.dart';
import 'package:superhero_showdown/features/battle/ai/ai_controller.dart';
import 'package:superhero_showdown/features/battle/ai/ai_difficulty.dart';
import 'package:superhero_showdown/features/battle/characters/hero_definition.dart';
import 'package:superhero_showdown/features/battle/characters/hero_roster.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_input.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_state.dart';
import 'package:superhero_showdown/features/battle/combat/match_controller.dart';

import '../helpers.dart';

MatchController fightingMatch(HeroDefinition player, HeroDefinition opponent) {
  final m = MatchController(playerHero: player, opponentHero: opponent)
    ..phase = MatchPhase.fighting;
  return m;
}

/// Fires the player's power and runs until something lands or time runs out.
int firePower(MatchController m, {FighterInput opponentInput = FighterInput.none}) {
  m.player.energy = GameConstants.maxEnergy;
  var hits = 0;
  m.update(frame, const FighterInput(special: true), opponentInput);
  for (var i = 0; i < 120; i++) {
    hits += m
        .update(frame, FighterInput.none, opponentInput)
        .where((e) => e.isSpecial)
        .length;
  }
  return hits;
}

void main() {
  test('energy fills up over time', () {
    final f = makeFighter();
    expect(f.energy, 0);
    run(f, 5);
    expect(f.energy, closeTo(GameConstants.energyPerSecond * 5, 1));
    run(f, 30);
    expect(f.energyFull, isTrue);
  });

  test('power does nothing until the meter is full', () {
    final f = makeFighter();
    f.update(frame, const FighterInput(special: true));
    expect(f.state, isNot(FighterState.special));
    f.energy = GameConstants.maxEnergy;
    f.update(frame, const FighterInput(special: true));
    expect(f.state, FighterState.special);
    expect(f.energy, 0, reason: 'using the power spends the meter');
  });

  test('every hero has a working superpower that lands at mid range', () {
    for (final hero in HeroRoster.all) {
      final m = fightingMatch(hero, HeroRoster.darkKnight);
      m.opponent.x = m.player.x + 260;
      final before = m.opponent.health;
      expect(firePower(m), 1, reason: hero.name);
      expect(m.opponent.health, lessThan(before - 10), reason: hero.name);
    }
  });

  test('projectile powers create a projectile that is then cleaned up', () {
    final m = fightingMatch(HeroRoster.ironFalcon, HeroRoster.spiderShadow);
    m.opponent.x = GameConstants.arenaRight;
    m.player.x = GameConstants.arenaLeft + 50;
    m.player.energy = GameConstants.maxEnergy;
    m.update(frame, const FighterInput(special: true), FighterInput.none);
    var sawProjectile = false;
    for (var i = 0; i < 180; i++) {
      m.update(frame, FighterInput.none, FighterInput.none);
      if (m.projectiles.isNotEmpty) sawProjectile = true;
    }
    expect(sawProjectile, isTrue);
    expect(m.projectiles, isEmpty);
  });

  test('a jump clears the thunder wave', () {
    final m = fightingMatch(HeroRoster.thunderGiant, HeroRoster.spiderShadow);
    m.opponent.x = m.player.x + 380;
    m.player.energy = GameConstants.maxEnergy;
    m.update(frame, const FighterInput(special: true), FighterInput.none);
    var hits = 0;
    for (var i = 0; i < 120; i++) {
      final p = m.projectiles.isEmpty ? null : m.projectiles.first;
      final jump = p != null && (m.opponent.x - p.x).abs() < 170;
      hits += m
          .update(frame, FighterInput.none, FighterInput(jump: jump))
          .length;
    }
    expect(hits, 0);
  });

  test('the web shot sticks the opponent in place', () {
    final m = fightingMatch(HeroRoster.spiderShadow, HeroRoster.solarMan);
    m.opponent.x = m.player.x + 260;
    m.player.energy = GameConstants.maxEnergy;
    m.update(frame, const FighterInput(special: true), FighterInput.none);
    var webbed = false;
    for (var i = 0; i < 60 && !webbed; i++) {
      m.update(frame, FighterInput.none, FighterInput.none);
      webbed = m.opponent.webbed > 0;
    }
    expect(webbed, isTrue);
    expect(m.opponent.state, FighterState.hit);
  });

  test('blocking a power reduces the damage', () {
    final m = fightingMatch(HeroRoster.solarMan, HeroRoster.darkKnight);
    m.opponent.x = m.player.x + 300;
    firePower(m, opponentInput: const FighterInput(block: true));
    expect(m.opponent.health, greaterThan(GameConstants.maxHealth - 5));
  });

  test('a hero powering up cannot be interrupted', () {
    final m = fightingMatch(HeroRoster.solarMan, HeroRoster.thunderGiant);
    m.opponent.x = m.player.x + 100;
    m.player.energy = GameConstants.maxEnergy;
    m.update(frame, const FighterInput(special: true), FighterInput.none);
    m.update(frame, FighterInput.none, const FighterInput(punch: true));
    for (var i = 0; i < 12; i++) {
      m.update(frame, FighterInput.none, FighterInput.none);
    }
    expect(m.player.health, GameConstants.maxHealth);
    expect(m.player.state, FighterState.special);
  });

  test('the AI uses its superpower when the meter is full', () {
    final m = fightingMatch(HeroRoster.spiderShadow, HeroRoster.ironFalcon);
    final ai = AiController(difficulty: AiDifficulty.easy, random: math.Random(5));
    m.opponent.energy = GameConstants.maxEnergy;
    var used = false;
    for (var i = 0; i < 600 && !used; i++) {
      m.update(frame, FighterInput.none, ai.think(frame, m.opponent, m.player));
      used = m.opponent.state == FighterState.special;
    }
    expect(used, isTrue);
  });
}
