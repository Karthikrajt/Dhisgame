import 'dart:ui';

import '../combat/attack_data.dart';

/// Which head design the vector renderer draws.
enum HeadStyle { goggleHood, crestHelm }

/// Which chest emblem the vector renderer draws.
enum EmblemStyle { orbSpinner, crescentStar }

/// Which back accessory the vector renderer draws.
enum BackStyle { scarf, scallopCape }

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
}

/// Static description of a playable hero: name, stats, attacks and look.
class HeroDefinition {
  const HeroDefinition({
    required this.id,
    required this.name,
    required this.title,
    required this.abilityName,
    required this.abilityDescription,
    required this.look,
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
  final String abilityName;
  final String abilityDescription;
  final HeroLook look;

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
