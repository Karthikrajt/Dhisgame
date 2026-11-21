import 'dart:ui';

import '../combat/attack_data.dart';

/// Which head design the vector renderer draws.
enum HeadStyle { goggleHood, crestHelm, sunHelm, headband, falconHelm }

/// Which chest emblem the vector renderer draws.
enum EmblemStyle { orbSpinner, crescentStar, sunburst, lightning, energyCore }

/// Which back accessory the vector renderer draws.
enum BackStyle { scarf, scallopCape, flowCape, none, jetWings }

/// How a superpower behaves in battle.
enum SpecialKind {
  /// A ball that flies forward (web, plasma).
  projectile,

  /// A long, very fast ray of light.
  beam,

  /// A wave that rolls along the floor. It can be jumped over.
  shockwave,

  /// The hero zooms forward and hits with their whole body.
  dash,
}

/// A hero's one big superpower, fired with the POWER button.
class SpecialPower {
  const SpecialPower({
    required this.name,
    required this.description,
    required this.kind,
    required this.color,
    required this.glow,
    this.damage = 15,
    this.speed = 800,
    this.hitStun = 0.6,
    this.knockback = 420,
  });

  final String name;
  final String description;
  final SpecialKind kind;

  /// Main colour of the power's effect, and a softer glow colour.
  final Color color;
  final Color glow;

  final double damage;
  final double speed;
  final double hitStun;
  final double knockback;

  /// Wind-up before the power is released.
  static const double chargeTime = 0.32;

  /// How long a dash lasts.
  static const double dashTime = 0.32;

  /// Time after release before the hero can act again.
  static const double recoveryTime = 0.36;

  double get totalTime =>
      chargeTime + (kind == SpecialKind.dash ? dashTime : 0) + recoveryTime;

  AttackData get attackData => AttackData(
    type: AttackType.special,
    startup: chargeTime,
    active: kind == SpecialKind.dash ? dashTime : 0.05,
    recovery: recoveryTime,
    damage: damage,
    reach: 30,
    hitboxBottom: 20,
    hitboxTop: 230,
    knockback: knockback,
    hitStun: hitStun,
    cooldown: 0.2,
  );
}

/// Colours and shape choices for a hero's vector artwork.
class HeroLook {
  const HeroLook({
    required this.suit,
    required this.suitShade,
    required this.trim,
    required this.gloves,
    required this.boots,
    required this.eyes,
    required this.emblem,
    required this.back,
    required this.headStyle,
    required this.emblemStyle,
    required this.backStyle,
    this.eyeGlow = false,
    this.bulk = 1.0,
    this.skin,
  });

  final Color suit;
  final Color suitShade;
  final Color trim;
  final Color gloves;
  final Color boots;
  final Color eyes;
  final Color emblem;
  final Color back;
  final HeadStyle headStyle;
  final EmblemStyle emblemStyle;
  final BackStyle backStyle;

  /// Draws a soft, steady glow around the eyes (never blinking).
  final bool eyeGlow;

  /// Scales limb thickness, so heavier heroes read as heavier.
  final double bulk;

  /// Visible face colour for heroes without a full mask.
  final Color? skin;
}

/// Static description of a playable hero: name, stats, attacks and look.
class HeroDefinition {
  const HeroDefinition({
    required this.id,
    required this.name,
    required this.title,
    required this.look,
    required this.special,
    this.walkSpeed = 260,
    this.jumpPower = 1.0,
    this.attackSpeed = 1.0,
    this.punchDamage = 1.0,
    this.kickDamage = 1.0,
    this.reach = 1.0,
  });

  final String id;
  final String name;
  final String title;
  final HeroLook look;
  final SpecialPower special;

  final double walkSpeed;
  final double jumpPower;
  final double attackSpeed;
  final double punchDamage;
  final double kickDamage;
  final double reach;

  AttackData get punch => AttackData.punch.scaled(
    damage: punchDamage,
    speed: attackSpeed,
    reach: reach,
  );

  AttackData get kick => AttackData.kick.scaled(
    damage: kickDamage,
    speed: attackSpeed,
    reach: reach,
  );

  AttackData attack(AttackType type) => type == AttackType.punch ? punch : kick;
}
