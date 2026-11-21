import 'dart:math' as math;

import '../combat/fighter.dart';
import '../combat/fighter_input.dart';
import '../characters/hero_definition.dart';
import 'ai_difficulty.dart';

/// High level intent of the computer opponent.
enum AiIntent {
  wait,
  approach,
  keepDistance,
  retreat,
  attack,
  block,
  jump,
  special,
}

/// A simple, readable fighting AI.
///
/// It makes a decision every [AiDifficulty.reactionTime] seconds and then
/// holds that decision, which gives young players time to react.
class AiController {
  AiController({this.difficulty = AiDifficulty.easy, math.Random? random})
    : _random = random ?? math.Random();

  final AiDifficulty difficulty;
  final math.Random _random;

  double _thinkTimer = 0;
  double _restTimer = 0.6;
  AiIntent _intent = AiIntent.wait;
  bool _attackWithKick = false;
  bool _attackIssued = false;

  AiIntent get intent => _intent;

  /// Distance at which the AI likes to stand.
  static const double preferredDistance = 140;
  static const double attackRange = 160;

  FighterInput think(double dt, Fighter self, Fighter target) {
    _thinkTimer -= dt;
    _restTimer -= dt;

    if (self.state.isFinal || target.state.isFinal) {
      return FighterInput.none;
    }

    final distance = (target.x - self.x).abs();

    // React to an incoming attack between normal decisions.
    if (target.state.isAttacking &&
        distance < attackRange + 20 &&
        _intent != AiIntent.block &&
        target.stateTime < 0.05 &&
        _random.nextDouble() < difficulty.blockChance * _defenseBoost(self)) {
      _intent = AiIntent.block;
      _thinkTimer = 0.35;
    }

    if (_thinkTimer <= 0) {
      _decide(self, target, distance);
      _thinkTimer =
          difficulty.reactionTime * (0.8 + _random.nextDouble() * 0.4);
    }

    return _act(self, target, distance);
  }

  /// Defends more often when health is low.
  double _defenseBoost(Fighter self) => self.healthFraction < 0.35 ? 1.8 : 1.0;

  void _decide(Fighter self, Fighter target, double distance) {
    _attackIssued = false;
    final lowHealth = self.healthFraction < 0.35;

    if (lowHealth &&
        distance < preferredDistance &&
        _random.nextDouble() < 0.3) {
      _intent = AiIntent.retreat;
      return;
    }
    if (self.energyFull &&
        _specialMakesSense(self, distance) &&
        _random.nextDouble() < difficulty.specialChance) {
      _intent = AiIntent.special;
      return;
    }
    if (_random.nextDouble() < difficulty.jumpChance) {
      _intent = AiIntent.jump;
      return;
    }
    if (distance > attackRange) {
      _intent = AiIntent.approach;
      return;
    }
    if (_restTimer <= 0 && _random.nextDouble() < difficulty.attackChance) {
      _intent = AiIntent.attack;
      _attackWithKick = _random.nextDouble() < 0.45;
      return;
    }
    if (distance < preferredDistance * 0.6) {
      _intent = AiIntent.keepDistance;
      return;
    }
    _intent = _random.nextDouble() < 0.5 ? AiIntent.wait : AiIntent.approach;
  }

  bool _specialMakesSense(Fighter self, double distance) =>
      switch (self.hero.special.kind) {
        SpecialKind.dash => distance < 650,
        _ => distance > 110,
      };

  FighterInput _act(Fighter self, Fighter target, double distance) {
    final toward = target.x > self.x ? 1 : -1;
    switch (_intent) {
      case AiIntent.wait:
        return FighterInput.none;
      case AiIntent.approach:
        if (distance < preferredDistance) return FighterInput.none;
        return _move(toward);
      case AiIntent.keepDistance:
        if (distance > preferredDistance) return FighterInput.none;
        return _move(-toward);
      case AiIntent.retreat:
        return _move(-toward);
      case AiIntent.block:
        return const FighterInput(block: true);
      case AiIntent.special:
        if (_attackIssued) return FighterInput.none;
        _attackIssued = true;
        return const FighterInput(special: true);
      case AiIntent.jump:
        _intent = AiIntent.approach;
        return FighterInput(jump: true, left: toward < 0, right: toward > 0);
      case AiIntent.attack:
        if (distance > attackRange) return _move(toward);
        if (_attackIssued) return FighterInput.none;
        _attackIssued = true;
        _restTimer = difficulty.attackPause;
        return FighterInput(punch: !_attackWithKick, kick: _attackWithKick);
    }
  }

  FighterInput _move(int dir) => FighterInput(left: dir < 0, right: dir > 0);
}
