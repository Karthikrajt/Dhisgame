import 'dart:ui';

import '../../../core/constants/game_constants.dart';
import 'attack_data.dart';
import 'fighter.dart';
import 'fighter_state.dart';
import 'projectile.dart';
import '../characters/hero_definition.dart';

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

  bool get isSpecial => type == AttackType.special;

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
    if (!_canBeHit(defender)) return null;

    final hurt = defender.hurtbox;
    if (!hitbox.overlaps(hurt)) return null;

    attacker.registerHit();
    final direction = defender.x >= attacker.x ? 1 : -1;
    return _apply(
      attacker,
      defender,
      attack,
      direction,
      hitbox.intersect(hurt).center,
    );
  }

  /// Checks a flying superpower against [defender].
  static HitEvent? resolveProjectile(Projectile p, Fighter defender) {
    if (p.spent || p.done || !_canBeHit(defender)) return null;
    final hurt = defender.hurtbox;
    final box = p.hitbox;
    if (!box.overlaps(hurt)) return null;
    p.spent = true;
    final hit = _apply(
      p.owner,
      defender,
      p.power.attackData,
      p.direction,
      box.intersect(hurt).center,
    );
    if (!hit.blocked &&
        p.kind == SpecialKind.projectile &&
        p.power.hitStun > 0.8) {
      defender.webbed = p.power.hitStun;
    }
    return hit;
  }

  static bool _canBeHit(Fighter f) =>
      !f.state.isFinal && f.invulnerable <= 0 && !f.superArmor;

  static HitEvent _apply(
    Fighter attacker,
    Fighter defender,
    AttackData attack,
    int direction,
    Offset point,
  ) {
    // A block only works when the defender faces the attacker.
    final blocked =
        defender.state == FighterState.blocking &&
        defender.facing == -direction;

    final damage = blocked
        ? defender.receiveBlockedHit(attack, direction)
        : defender.receiveHit(attack, direction);
    attacker.addEnergy(GameConstants.energyPerHitDealt);
    defender.addEnergy(GameConstants.energyPerHitTaken);

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
