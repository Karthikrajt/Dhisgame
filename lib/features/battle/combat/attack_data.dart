enum AttackType { punch, kick }

/// Frame data for a single attack, expressed in seconds and world units.
class AttackData {
  const AttackData({
    required this.type,
    required this.startup,
    required this.active,
    required this.recovery,
    required this.damage,
    required this.reach,
    required this.hitboxBottom,
    required this.hitboxTop,
    required this.knockback,
    required this.hitStun,
    required this.cooldown,
  });

  final AttackType type;

  /// Wind-up before the hitbox appears.
  final double startup;

  /// How long the hitbox is live.
  final double active;

  /// Time after the hitbox disappears before the fighter can act again.
  final double recovery;

  final double damage;

  /// How far the hitbox extends in front of the fighter's body edge.
  final double reach;

  /// Hitbox vertical extent, measured upwards from the feet.
  final double hitboxBottom;
  final double hitboxTop;

  /// Horizontal speed applied to the defender on a clean hit.
  final double knockback;

  /// Seconds the defender is stunned on a clean hit.
  final double hitStun;

  /// Extra delay after the attack ends before the next one can start.
  final double cooldown;

  double get total => startup + active + recovery;

  /// 0..1 progress through the whole attack, used by the animation.
  double progress(double t) => (t / total).clamp(0.0, 1.0);

  bool isActiveAt(double t) => t >= startup && t < startup + active;

  AttackData scaled({double damage = 1, double speed = 1, double reach = 1}) {
    return AttackData(
      type: type,
      startup: startup / speed,
      active: active,
      recovery: recovery / speed,
      damage: this.damage * damage,
      reach: this.reach * reach,
      hitboxBottom: hitboxBottom,
      hitboxTop: hitboxTop,
      knockback: knockback,
      hitStun: hitStun,
      cooldown: cooldown / speed,
    );
  }

  static const AttackData punch = AttackData(
    type: AttackType.punch,
    startup: 0.08,
    active: 0.10,
    recovery: 0.16,
    damage: 6,
    reach: 82,
    hitboxBottom: 150,
    hitboxTop: 215,
    knockback: 220,
    hitStun: 0.28,
    cooldown: 0.06,
  );

  static const AttackData kick = AttackData(
    type: AttackType.kick,
    startup: 0.14,
    active: 0.12,
    recovery: 0.24,
    damage: 9,
    reach: 106,
    hitboxBottom: 70,
    hitboxTop: 145,
    knockback: 360,
    hitStun: 0.36,
    cooldown: 0.10,
  );
}
