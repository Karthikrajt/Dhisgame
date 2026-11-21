import 'dart:ui';

import 'hero_definition.dart';

/// All heroes available in the game. Every hero is an original design.
abstract final class HeroRoster {
  /// Agile web-slinger: quick attacks, high jump, a sticky web shot.
  static const HeroDefinition spiderShadow = HeroDefinition(
    id: 'spider_shadow',
    name: 'Spider Shadow',
    title: 'Quick and bouncy',
    walkSpeed: 285,
    jumpPower: 1.08,
    attackSpeed: 1.15,
    punchDamage: 0.95,
    kickDamage: 0.9,
    special: SpecialPower(
      name: 'Web Shot',
      description: 'Shoots a sticky web that holds the foe in place.',
      kind: SpecialKind.projectile,
      color: Color(0xFFFFFFFF),
      glow: Color(0xFFFF8A80),
      damage: 13,
      speed: 720,
      hitStun: 1.1,
      knockback: 120,
    ),
    look: HeroLook(
      suit: Color(0xFF233A8C),
      suitShade: Color(0xFF15245E),
      trim: Color(0xFFE8473C),
      gloves: Color(0xFFE8473C),
      boots: Color(0xFFE8473C),
      eyes: Color(0xFFFFFFFF),
      emblem: Color(0xFFFF6A4D),
      back: Color(0xFFE8473C),
      headStyle: HeadStyle.goggleHood,
      emblemStyle: EmblemStyle.orbSpinner,
      backStyle: BackStyle.scarf,
    ),
  );

  /// Armoured night guardian: strong kicks and a shadow dash.
  static const HeroDefinition darkKnight = HeroDefinition(
    id: 'dark_knight',
    name: 'Dark Knight',
    title: 'Strong armoured kicks',
    walkSpeed: 240,
    jumpPower: 0.96,
    attackSpeed: 0.95,
    punchDamage: 1.05,
    kickDamage: 1.2,
    reach: 1.08,
    special: SpecialPower(
      name: 'Night Strike',
      description: 'Zooms across the arena wrapped in moonlight.',
      kind: SpecialKind.dash,
      color: Color(0xFF9C8CFF),
      glow: Color(0xFF6FE3FF),
      damage: 16,
      speed: 950,
    ),
    look: HeroLook(
      suit: Color(0xFF3A3F5C),
      suitShade: Color(0xFF23263A),
      trim: Color(0xFF7B6CD9),
      gloves: Color(0xFF5A4FA8),
      boots: Color(0xFF2C2F47),
      eyes: Color(0xFF6FE3FF),
      emblem: Color(0xFFB9C4FF),
      back: Color(0xFF2E7A8C),
      headStyle: HeadStyle.crestHelm,
      emblemStyle: EmblemStyle.crescentStar,
      backStyle: BackStyle.scallopCape,
      eyeGlow: true,
      bulk: 1.12,
    ),
  );

  /// Sunny flying hero: balanced, super jump, a golden sun beam.
  static const HeroDefinition solarMan = HeroDefinition(
    id: 'solar_man',
    name: 'Solar Man',
    title: 'Super jump, all-rounder',
    walkSpeed: 265,
    jumpPower: 1.12,
    special: SpecialPower(
      name: 'Sun Beam',
      description: 'Fires a warm golden beam of sunshine.',
      kind: SpecialKind.beam,
      color: Color(0xFFFFD54A),
      glow: Color(0xFFFFF3B0),
      damage: 15,
      speed: 1500,
    ),
    look: HeroLook(
      suit: Color(0xFF2F8FE0),
      suitShade: Color(0xFF1C5FA6),
      trim: Color(0xFFFFC233),
      gloves: Color(0xFFE5483A),
      boots: Color(0xFFE5483A),
      eyes: Color(0xFFFFFFFF),
      emblem: Color(0xFFFFC233),
      back: Color(0xFFE5483A),
      headStyle: HeadStyle.sunHelm,
      emblemStyle: EmblemStyle.sunburst,
      backStyle: BackStyle.flowCape,
    ),
  );

  /// Big friendly giant: slow, very strong, shakes the ground.
  static const HeroDefinition thunderGiant = HeroDefinition(
    id: 'thunder_giant',
    name: 'Thunder Giant',
    title: 'Huge punches, slow steps',
    walkSpeed: 215,
    jumpPower: 0.9,
    attackSpeed: 0.85,
    punchDamage: 1.3,
    kickDamage: 1.2,
    reach: 1.1,
    special: SpecialPower(
      name: 'Thunder Stomp',
      description: 'Stomps so hard a thunder wave rolls along the ground.',
      kind: SpecialKind.shockwave,
      color: Color(0xFFB388FF),
      glow: Color(0xFFFFF59D),
      damage: 18,
      speed: 560,
    ),
    look: HeroLook(
      suit: Color(0xFF7E57C2),
      suitShade: Color(0xFF5335A0),
      trim: Color(0xFF8BD34A),
      gloves: Color(0xFF8BD34A),
      boots: Color(0xFF4A2F7A),
      eyes: Color(0xFFFFFFFF),
      emblem: Color(0xFFFFEB3B),
      back: Color(0xFF7E57C2),
      skin: Color(0xFF6CC24A),
      headStyle: HeadStyle.headband,
      emblemStyle: EmblemStyle.lightning,
      backStyle: BackStyle.none,
      bulk: 1.32,
    ),
  );

  /// High-tech flyer: fast and nimble, fires plasma from the chest core.
  static const HeroDefinition ironFalcon = HeroDefinition(
    id: 'iron_falcon',
    name: 'Iron Falcon',
    title: 'Fast rocket armour',
    walkSpeed: 275,
    jumpPower: 1.04,
    attackSpeed: 1.08,
    special: SpecialPower(
      name: 'Plasma Blast',
      description: 'Blasts a bright plasma ball from the energy core.',
      kind: SpecialKind.projectile,
      color: Color(0xFF64F0FF),
      glow: Color(0xFFB2FFFF),
      damage: 15,
      speed: 980,
      hitStun: 0.55,
    ),
    look: HeroLook(
      suit: Color(0xFFC62828),
      suitShade: Color(0xFF8E1B1B),
      trim: Color(0xFFFFC233),
      gloves: Color(0xFFFFC233),
      boots: Color(0xFFFFC233),
      eyes: Color(0xFF64F0FF),
      emblem: Color(0xFF64F0FF),
      back: Color(0xFFFFC233),
      headStyle: HeadStyle.falconHelm,
      emblemStyle: EmblemStyle.energyCore,
      backStyle: BackStyle.jetWings,
      eyeGlow: true,
      bulk: 1.05,
    ),
  );

  static const List<HeroDefinition> all = [
    spiderShadow,
    darkKnight,
    solarMan,
    thunderGiant,
    ironFalcon,
  ];

  static HeroDefinition byId(String id) =>
      all.firstWhere((h) => h.id == id, orElse: () => all.first);
}
