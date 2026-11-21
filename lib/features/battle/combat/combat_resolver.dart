import 'dart:ui';

import '../../../core/constants/game_constants.dart';
import 'attack_data.dart';
import 'fighter.dart';
import 'fighter_state.dart';

/// Outcome of one attack connecting.
class HitEvent {
  const HitEvent({
    required this.attacker,
    required this.defender,
    required this.type,
    required this.damage,
    required this.blocked,
    required this.point,
    required this.knockout,
  });

  final Fighter attacker;
  final Fighter defender;
  final AttackType type;
  final double damage;
  final bool blocked;
  final Offset point;
  final bool knockout;
}

/// Hitbox versus hurtbox checks and body separation.
abstract final class CombatResolver {
  /// Checks whether [attacker]'s live hitbox touches [defender] and, if so,
  /// applies the hit and returns what happened.
  static HitEvent? resolve(Fighter attacker, Fighter defender) {
    final hitbox = attacker.activeHitbox;
    final attack = attacker.currentAttack;
    if (hitbox == null || attack == null) return null;
    if (defender.state.isFinal || defender.invulnerable > 0) return null;

    final hurt = defender.hurtbox;
    if (!hitbox.overlaps(hurt)) return null;

    attacker.registerHit();
    final direction = defender.x >= attacker.x ? 1 : -1;
    final overlap = hitbox.intersect(hurt);
    final point = overlap.center;

    // A block only works when the defender faces the attacker.
    final blocked =
        defender.state == FighterState.blocking &&
        defender.facing == -direction;

    final damage = blocked
        ? defender.receiveBlockedHit(attack, direction)
        : defender.receiveHit(attack, direction);

    return HitEvent(
      attacker: attacker,
      defender: defender,
      type: attack.type,
      damage: damage,
      blocked: blocked,
      point: point,
      knockout: defender.isKnockedOut,
    );
  }

  /// Keeps fighters from walking through each other.
  static void separate(Fighter a, Fighter b) {
    if (a.isKnockedOut || b.isKnockedOut) return;
    // Let a jumping fighter pass over the other one's head.
    final verticalGap = (a.y - b.y).abs();
    if (verticalGap > GameConstants.fighterHeight * 0.6) return;

    final dx = b.x - a.x;
    final distance = dx.abs();
    if (distance >= GameConstants.minSeparation) return;

    final push = (GameConstants.minSeparation - distance) / 2;
    final dir = dx == 0 ? (a.facing == 1 ? 1 : -1) : dx.sign;
    a.x -= dir * push;
    b.x += dir * push;

    const left = GameConstants.arenaLeft;
    const right = GameConstants.arenaRight;
    a.x = a.x.clamp(left, right);
    b.x = b.x.clamp(left, right);

    // Against a wall, push the other fighter instead.
    if ((b.x - a.x).abs() < GameConstants.minSeparation) {
      if (a.x <= left || a.x >= right) {
        b.x = (a.x + dir * GameConstants.minSeparation).clamp(left, right);
      } else if (b.x <= left || b.x >= right) {
        a.x = (b.x - dir * GameConstants.minSeparation).clamp(left, right);
      }
    }
  }
}
