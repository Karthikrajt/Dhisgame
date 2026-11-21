import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import '../combat/attack_data.dart';
import '../combat/fighter_state.dart';

/// Facial expression drawn on the hero's mask.
enum EyeMood { normal, focused, hurt, dizzy, happy }

/// A skeletal pose for the vector hero renderer.
///
/// Limb angles are in radians, measured from straight down. Positive values
/// swing the limb toward the direction the hero is facing. Knee values bend
/// the shin backwards; elbow values bend the forearm forwards and up.
class HeroPose {
  const HeroPose({
    this.frontHip = 0,
    this.frontKnee = 0,
    this.backHip = 0,
    this.backKnee = 0,
    this.frontShoulder = 0,
    this.frontElbow = 0,
    this.backShoulder = 0,
    this.backElbow = 0,
    this.lean = 0,
    this.headTilt = 0,
    this.bob = 0,
    this.lie = 0,
    this.grounded = true,
    this.mood = EyeMood.normal,
    this.squash = 1,
  });

  final double frontHip;
  final double frontKnee;
  final double backHip;
  final double backKnee;
  final double frontShoulder;
  final double frontElbow;
  final double backShoulder;
  final double backElbow;

  /// Forward tilt of the torso.
  final double lean;
  final double headTilt;

  /// Vertical body offset in world units (negative is up).
  final double bob;

  /// 0 standing, 1 lying flat on the back (cartoon knockout).
  final double lie;

  /// When true the renderer lowers the hips so the feet touch the ground.
  final bool grounded;
  final EyeMood mood;

  /// Vertical squash and stretch (1 is neutral).
  final double squash;

  HeroPose copyWith({
    double? bob,
    double? lie,
    double? lean,
    double? headTilt,
    bool? grounded,
    EyeMood? mood,
    double? squash,
  }) {
    return HeroPose(
      frontHip: frontHip,
      frontKnee: frontKnee,
      backHip: backHip,
      backKnee: backKnee,
      frontShoulder: frontShoulder,
      frontElbow: frontElbow,
      backShoulder: backShoulder,
      backElbow: backElbow,
      lean: lean ?? this.lean,
      headTilt: headTilt ?? this.headTilt,
      bob: bob ?? this.bob,
      lie: lie ?? this.lie,
      grounded: grounded ?? this.grounded,
      mood: mood ?? this.mood,
      squash: squash ?? this.squash,
    );
  }

  static HeroPose lerp(HeroPose a, HeroPose b, double t) {
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return HeroPose(
      frontHip: l(a.frontHip, b.frontHip),
      frontKnee: l(a.frontKnee, b.frontKnee),
      backHip: l(a.backHip, b.backHip),
      backKnee: l(a.backKnee, b.backKnee),
      frontShoulder: l(a.frontShoulder, b.frontShoulder),
      frontElbow: l(a.frontElbow, b.frontElbow),
      backShoulder: l(a.backShoulder, b.backShoulder),
      backElbow: l(a.backElbow, b.backElbow),
      lean: l(a.lean, b.lean),
      headTilt: l(a.headTilt, b.headTilt),
      bob: l(a.bob, b.bob),
      lie: l(a.lie, b.lie),
      squash: l(a.squash, b.squash),
      grounded: t < 0.5 ? a.grounded : b.grounded,
      mood: t < 0.5 ? a.mood : b.mood,
    );
  }

  // ---- Key poses -------------------------------------------------------

  static const HeroPose guard = HeroPose(
    frontHip: 0.38,
    frontKnee: 0.4,
    backHip: -0.32,
    backKnee: 0.3,
    frontShoulder: 0.85,
    frontElbow: 1.75,
    backShoulder: 0.45,
    backElbow: 2.0,
    lean: 0.08,
  );

  static const HeroPose jumpRise = HeroPose(
    frontHip: 1.05,
    frontKnee: 1.6,
    backHip: 0.25,
    backKnee: 1.2,
    frontShoulder: 2.5,
    frontElbow: 0.5,
    backShoulder: 1.9,
    backElbow: 0.6,
    lean: 0.05,
    grounded: false,
    squash: 1.04,
  );

  static const HeroPose jumpFall = HeroPose(
    frontHip: 0.5,
    frontKnee: 0.55,
    backHip: -0.25,
    backKnee: 0.7,
    frontShoulder: 1.7,
    frontElbow: 0.4,
    backShoulder: 1.2,
    backElbow: 0.5,
    lean: 0.04,
    grounded: false,
  );

  static const HeroPose punchWind = HeroPose(
    frontHip: 0.45,
    frontKnee: 0.45,
    backHip: -0.4,
    backKnee: 0.3,
    frontShoulder: 0.55,
    frontElbow: 2.1,
    backShoulder: 0.9,
    backElbow: 1.7,
    lean: -0.04,
    mood: EyeMood.focused,
  );

  static const HeroPose punchHit = HeroPose(
    frontHip: 0.6,
    frontKnee: 0.45,
    backHip: -0.6,
    backKnee: 0.1,
    frontShoulder: 1.62,
    frontElbow: 0.0,
    backShoulder: -0.45,
    backElbow: 1.9,
    lean: 0.24,
    mood: EyeMood.focused,
  );

  static const HeroPose kickWind = HeroPose(
    frontHip: 1.25,
    frontKnee: 1.9,
    backHip: -0.1,
    backKnee: 0.2,
    frontShoulder: 0.7,
    frontElbow: 1.8,
    backShoulder: -0.3,
    backElbow: 1.5,
    lean: -0.14,
    mood: EyeMood.focused,
  );

  static const HeroPose kickHit = HeroPose(
    frontHip: 1.68,
    frontKnee: 0.05,
    backHip: -0.12,
    backKnee: 0.12,
    frontShoulder: 0.4,
    frontElbow: 1.9,
    backShoulder: -0.7,
    backElbow: 0.6,
    lean: -0.32,
    mood: EyeMood.focused,
  );

  static const HeroPose block = HeroPose(
    frontHip: 0.45,
    frontKnee: 0.7,
    backHip: -0.35,
    backKnee: 0.55,
    frontShoulder: 1.9,
    frontElbow: 2.3,
    backShoulder: 1.6,
    backElbow: 2.5,
    lean: -0.06,
    headTilt: 0.12,
    mood: EyeMood.focused,
  );

  static const HeroPose hurt = HeroPose(
    frontHip: 0.55,
    frontKnee: 0.3,
    backHip: -0.45,
    backKnee: 0.25,
    frontShoulder: 1.3,
    frontElbow: 0.4,
    backShoulder: -0.7,
    backElbow: 0.5,
    lean: -0.38,
    headTilt: -0.3,
    mood: EyeMood.hurt,
  );

  static const HeroPose knockedOut = HeroPose(
    frontHip: 0.2,
    frontKnee: 0.3,
    backHip: -0.15,
    backKnee: 0.2,
    frontShoulder: 2.4,
    frontElbow: 0.3,
    backShoulder: 2.8,
    backElbow: 0.2,
    lean: 0,
    headTilt: -0.2,
    lie: 1,
    mood: EyeMood.dizzy,
  );

  static const HeroPose cheer = HeroPose(
    frontHip: 0.25,
    frontKnee: 0.15,
    backHip: -0.25,
    backKnee: 0.15,
    frontShoulder: 1.9,
    frontElbow: 1.2,
    backShoulder: 3.9,
    backElbow: 0.1,
    lean: -0.04,
    headTilt: 0.15,
    mood: EyeMood.happy,
  );

  // ---- Pose selection ---------------------------------------------------

  /// Builds the pose for a fighter in [state].
  ///
  /// [moveDir] is +1 walking forward and -1 walking backward.
  static HeroPose forState(
    FighterState state, {
    required double stateTime,
    required double animTime,
    AttackData? attack,
    double moveDir = 1,
    double walkSpeed = 260,
  }) {
    switch (state) {
      case FighterState.idle:
        return _idle(animTime);
      case FighterState.walking:
        return _walk(animTime, moveDir, walkSpeed);
      case FighterState.jumping:
        return HeroPose.lerp(jumpFall, jumpRise, _ease(stateTime / 0.18));
      case FighterState.falling:
        return HeroPose.lerp(jumpRise, jumpFall, _ease(stateTime / 0.2));
      case FighterState.punching:
        return _attackPose(attack, stateTime, punchWind, punchHit);
      case FighterState.kicking:
        return _attackPose(attack, stateTime, kickWind, kickHit);
      case FighterState.blocking:
        return HeroPose.lerp(guard, block, _ease(stateTime / 0.08));
      case FighterState.hit:
        final t = _ease(stateTime / 0.07);
        return HeroPose.lerp(guard, hurt, t);
      case FighterState.knockout:
        final t = _ease(stateTime / 0.45);
        return HeroPose.lerp(
          hurt,
          knockedOut,
          t,
        ).copyWith(lie: t, grounded: true, mood: EyeMood.dizzy);
      case FighterState.victory:
        final bounce = -(math.sin(animTime * 5.5).abs()) * 10;
        final arm = 0.15 * math.sin(animTime * 5.5);
        final base = HeroPose.lerp(guard, cheer, _ease(stateTime / 0.3));
        return HeroPose(
          frontHip: base.frontHip,
          frontKnee: base.frontKnee,
          backHip: base.backHip,
          backKnee: base.backKnee,
          frontShoulder: base.frontShoulder,
          frontElbow: base.frontElbow + arm,
          backShoulder: base.backShoulder + arm,
          backElbow: base.backElbow,
          lean: base.lean,
          headTilt: base.headTilt,
          bob: bounce * _ease(stateTime / 0.3),
          mood: EyeMood.happy,
        );
    }
  }

  static HeroPose _idle(double t) {
    final breathe = math.sin(t * 3.2);
    return HeroPose(
      frontHip: guard.frontHip,
      frontKnee: guard.frontKnee + breathe * 0.05,
      backHip: guard.backHip,
      backKnee: guard.backKnee + breathe * 0.05,
      frontShoulder: guard.frontShoulder + breathe * 0.05,
      frontElbow: guard.frontElbow,
      backShoulder: guard.backShoulder + breathe * 0.04,
      backElbow: guard.backElbow,
      lean: guard.lean + breathe * 0.015,
      squash: 1 + breathe * 0.012,
    );
  }

  static HeroPose _walk(double t, double dir, double speed) {
    final p = t * speed / 26 * dir;
    final s = math.sin(p);
    final c = math.cos(p);
    return HeroPose(
      frontHip: 0.12 + s * 0.5,
      frontKnee: 0.3 + math.max(0, c) * 0.6,
      backHip: 0.12 - s * 0.5,
      backKnee: 0.3 + math.max(0, -c) * 0.6,
      frontShoulder: 0.8 - s * 0.15,
      frontElbow: 1.7,
      backShoulder: 0.45 + s * 0.2,
      backElbow: 1.9,
      lean: 0.1 * dir.sign,
      bob: -(s.abs()) * 4,
    );
  }

  static HeroPose _attackPose(
    AttackData? attack,
    double t,
    HeroPose wind,
    HeroPose strike,
  ) {
    if (attack == null) return guard;
    final windEnd = attack.startup;
    final strikeEnd = attack.startup + attack.active;
    if (t < windEnd) {
      return HeroPose.lerp(guard, wind, _ease(t / windEnd));
    }
    if (t < strikeEnd) {
      final k = _ease((t - windEnd) / (attack.active * 0.4));
      return HeroPose.lerp(wind, strike, k);
    }
    final k = _ease((t - strikeEnd) / attack.recovery);
    return HeroPose.lerp(strike, guard, k);
  }

  static double _ease(double t) {
    final x = t.clamp(0.0, 1.0);
    return 1 - (1 - x) * (1 - x);
  }
}
