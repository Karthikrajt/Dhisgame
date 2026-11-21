import 'dart:ui';

import '../../../core/constants/game_constants.dart';
import '../characters/hero_definition.dart';
import 'fighter.dart';

/// Something a superpower sends flying: a web, plasma ball, sun beam or
/// thunder wave.
class Projectile {
  Projectile({required this.owner})
    : power = owner.hero.special,
      direction = owner.facing,
      startX = owner.x + owner.facing * 40,
      x = owner.x + owner.facing * 40,
      y = owner.hero.special.kind == SpecialKind.shockwave
          ? GameConstants.groundY
          : owner.y - 125;

  final Fighter owner;
  final SpecialPower power;
  final int direction;
  final double startX;
  double x;
  final double y;
  double age = 0;

  /// Set once it has hit someone; it then fades out without hitting again.
  bool spent = false;

  /// Set when it should be removed.
  bool done = false;

  SpecialKind get kind => power.kind;

  /// Beams stay on screen briefly after reaching full length.
  static const double beamLife = 0.7;

  Rect get hitbox {
    switch (kind) {
      case SpecialKind.beam:
        final a = startX;
        final b = x;
        return Rect.fromLTRB(a < b ? a : b, y - 24, a < b ? b : a, y + 24);
      case SpecialKind.shockwave:
        return Rect.fromCenter(
          center: Offset(x, y - 35),
          width: 70,
          height: 70,
        );
      case SpecialKind.projectile:
      case SpecialKind.dash:
        return Rect.fromCenter(center: Offset(x, y), width: 48, height: 48);
    }
  }

  void update(double dt) {
    age += dt;
    const margin = 60.0;
    final edge = direction > 0
        ? GameConstants.arenaRight + margin
        : GameConstants.arenaLeft - margin;
    final next = x + direction * power.speed * dt;
    x = direction > 0
        ? (next > edge ? edge : next)
        : (next < edge ? edge : next);

    if (kind == SpecialKind.beam) {
      if (age > beamLife) done = true;
    } else if (spent || x == edge) {
      done = true;
    }
  }
}
