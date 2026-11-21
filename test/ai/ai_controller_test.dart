import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/features/battle/ai/ai_controller.dart';
import 'package:superhero_showdown/features/battle/ai/ai_difficulty.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_input.dart';

import '../helpers.dart';

void main() {
  test('approaches a distant player', () {
    final ai = AiController(difficulty: AiDifficulty.hard, random: math.Random(1));
    final self = makeFighter(x: 1000, facing: -1);
    final target = makeFighter(x: 200);
    final startX = self.x;
    for (var i = 0; i < 120; i++) {
      self.update(frame, ai.think(frame, self, target));
      target.update(frame, FighterInput.none);
    }
    expect(self.x, lessThan(startX - 100));
  });

  test('attacks when in range', () {
    final ai = AiController(difficulty: AiDifficulty.normal, random: math.Random(2));
    final self = makeFighter(x: 600, facing: -1);
    final target = makeFighter(x: 480);
    final start = self.attackSerial;
    for (var i = 0; i < 600; i++) {
      self.update(frame, ai.think(frame, self, target));
      target.update(frame, FighterInput.none);
      target.x = self.x - 120;
    }
    expect(self.attackSerial - start, greaterThan(2));
  });

  test('easy attacks less often than hard', () {
    int attacksFor(AiDifficulty d) {
      final ai = AiController(difficulty: d, random: math.Random(3));
      final self = makeFighter(x: 600, facing: -1);
      final target = makeFighter(x: 480);
      for (var i = 0; i < 1800; i++) {
        self.update(frame, ai.think(frame, self, target));
        target.x = self.x - 120;
      }
      return self.attackSerial;
    }

    expect(attacksFor(AiDifficulty.easy), lessThan(attacksFor(AiDifficulty.hard)));
  });

  test('does nothing once the round is over', () {
    final ai = AiController(random: math.Random(4));
    final self = makeFighter(x: 600, facing: -1);
    final target = makeFighter(x: 480)..health = 0;
    target.receiveHit(target.hero.punch, 1);
    final input = ai.think(frame, self, target);
    expect(input.horizontal, 0);
    expect(input.punch || input.kick || input.jump, isFalse);
  });
}
