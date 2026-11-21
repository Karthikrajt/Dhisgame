import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/core/constants/game_constants.dart';
import 'package:superhero_showdown/features/battle/combat/combat_resolver.dart';
import 'package:superhero_showdown/features/battle/combat/fighter.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_input.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_state.dart';

import '../helpers.dart';

/// Swings [attacker]'s punch for its full duration against [defender] and
/// returns every hit that landed.
List<HitEvent> swing(Fighter attacker, Fighter defender,
    {FighterInput defend = FighterInput.none}) {
  final hits = <HitEvent>[];
  attacker.update(frame, const FighterInput(punch: true));
  for (var i = 0; i < 40; i++) {
    attacker.update(frame, FighterInput.none);
    defender.update(frame, defend);
    final hit = CombatResolver.resolve(attacker, defender);
    if (hit != null) hits.add(hit);
  }
  return hits;
}

void main() {
  test('a punch in range hits exactly once per swing', () {
    final a = makeFighter(x: 500, facing: 1);
    final d = makeFighter(x: 590, facing: -1);
    final hits = swing(a, d);
    expect(hits, hasLength(1));
    expect(d.health, lessThan(GameConstants.maxHealth));
    expect(hits.single.blocked, isFalse);
  });

  test('out of range misses', () {
    final a = makeFighter(x: 300, facing: 1);
    final d = makeFighter(x: 700, facing: -1);
    expect(swing(a, d), isEmpty);
    expect(d.health, GameConstants.maxHealth);
  });

  test('hits apply knockback, hit stun and invulnerability', () {
    final a = makeFighter(x: 500, facing: 1);
    final d = makeFighter(x: 590, facing: -1);
    a.update(frame, const FighterInput(punch: true));
    HitEvent? hit;
    for (var i = 0; i < 20 && hit == null; i++) {
      a.update(frame, FighterInput.none);
      hit = CombatResolver.resolve(a, d);
    }
    expect(hit, isNotNull);
    expect(d.state, FighterState.hit);
    expect(d.vx, greaterThan(0), reason: 'pushed away from attacker');
    expect(d.invulnerable, greaterThan(0));
  });

  test('invulnerability prevents an immediate second hit', () {
    final a = makeFighter(x: 500, facing: 1);
    final d = makeFighter(x: 590, facing: -1);
    d.invulnerable = 1;
    expect(swing(a, d), isEmpty);
  });

  test('blocking while facing the attacker reduces damage', () {
    final a = makeFighter(x: 500, facing: 1);
    final d = makeFighter(x: 590, facing: -1);
    final hits = swing(a, d, defend: const FighterInput(block: true));
    expect(hits, hasLength(1));
    expect(hits.single.blocked, isTrue);
    final lost = GameConstants.maxHealth - d.health;
    expect(lost, lessThan(a.hero.punch.damage * 0.5));
    expect(d.state, FighterState.blocking);
  });

  test('blocking while facing away does not protect', () {
    final a = makeFighter(x: 500, facing: 1);
    final d = makeFighter(x: 590, facing: 1);
    final hits = swing(a, d, defend: const FighterInput(block: true));
    expect(hits.single.blocked, isFalse);
  });

  test('separate keeps fighters apart', () {
    final a = makeFighter(x: 600);
    final b = makeFighter(x: 610);
    CombatResolver.separate(a, b);
    expect((b.x - a.x).abs(),
        closeTo(GameConstants.minSeparation, 0.001));
  });

  test('separate works against a wall', () {
    final a = makeFighter(x: GameConstants.arenaLeft);
    final b = makeFighter(x: GameConstants.arenaLeft + 5);
    CombatResolver.separate(a, b);
    expect((b.x - a.x).abs(),
        greaterThanOrEqualTo(GameConstants.minSeparation - 0.001));
  });
}
