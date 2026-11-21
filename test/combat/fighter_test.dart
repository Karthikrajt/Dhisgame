import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/core/constants/game_constants.dart';
import 'package:superhero_showdown/features/battle/combat/attack_data.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_input.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_state.dart';

import '../helpers.dart';

void main() {
  test('walks while a direction is held and stops when released', () {
    final f = makeFighter();
    run(f, 0.5, const FighterInput(right: true));
    expect(f.state, FighterState.walking);
    expect(f.x, greaterThan(600));
    run(f, 0.1);
    expect(f.state, FighterState.idle);
  });

  test('jumps, rises, falls and lands on the ground', () {
    final f = makeFighter();
    f.update(frame, const FighterInput(jump: true));
    expect(f.state, FighterState.jumping);
    run(f, 0.2);
    expect(f.y, lessThan(ground - 100));
    var sawFalling = false;
    for (var i = 0; i < 120; i++) {
      f.update(frame, FighterInput.none);
      if (f.state == FighterState.falling) sawFalling = true;
    }
    expect(sawFalling, isTrue);
    expect(f.y, ground);
    expect(f.state, FighterState.idle);
  });

  test('cannot double jump in mid-air', () {
    final f = makeFighter();
    f.update(frame, const FighterInput(jump: true));
    run(f, 0.1);
    final vyBefore = f.vy;
    f.update(frame, const FighterInput(jump: true));
    expect(f.vy, greaterThan(vyBefore));
  });

  test('punch runs through its frames and returns to idle', () {
    final f = makeFighter();
    f.update(frame, const FighterInput(punch: true));
    expect(f.state, FighterState.punching);
    expect(f.activeHitbox, isNull, reason: 'no hitbox during startup');
    run(f, f.currentAttack!.startup + 0.02);
    expect(f.activeHitbox, isNotNull);
    run(f, 1);
    expect(f.state, FighterState.idle);
  });

  test('holding punch repeats attacks', () {
    final f = makeFighter();
    var attacks = 0;
    var last = f.attackSerial;
    for (var i = 0; i < 120; i++) {
      f.update(frame, const FighterInput(punch: true));
      if (f.attackSerial != last) {
        attacks++;
        last = f.attackSerial;
      }
    }
    expect(attacks, greaterThanOrEqualTo(3));
  });

  test('stays inside the arena', () {
    final f = makeFighter(x: GameConstants.arenaLeft + 5);
    run(f, 2, const FighterInput(left: true));
    expect(f.x, GameConstants.arenaLeft);
  });

  test('knockout when health reaches zero, then ignores input', () {
    final f = makeFighter();
    f.health = 3;
    f.receiveHit(AttackData.kick, 1);
    expect(f.state, FighterState.knockout);
    run(f, 2, const FighterInput(punch: true, jump: true));
    expect(f.state, FighterState.knockout);
    expect(f.y, ground);
  });

  test('blocking on the ground stops movement', () {
    final f = makeFighter();
    run(f, 0.2, const FighterInput(block: true, right: true));
    expect(f.state, FighterState.blocking);
    expect(f.vx, 0);
  });
}
