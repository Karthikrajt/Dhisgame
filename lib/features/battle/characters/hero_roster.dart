import 'dart:ui';

import 'hero_definition.dart';

/// All heroes available in this build.
///
/// Milestone 1 ships two heroes. Milestone 2 adds Solar Man, Thunder Giant
/// and Iron Falcon to this list; nothing else needs to change for them to
/// appear on the selection screen.
abstract final class HeroRoster {
  /// Agile web-slinger: quicker attacks, lighter hits, higher jump.
  static const HeroDefinition spiderShadow = HeroDefinition(
    id: 'spider_shadow',
    name: 'Spider Shadow',
    title: 'The Night Weaver',
    abilityName: 'Web Burst',
    abilityDescription: 'Super quick punches and a very high jump.',
    walkSpeed: 285,
    jumpPower: 1.08,
    attackSpeed: 1.15,
    punchDamage: 0.95,
    kickDamage: 0.9,
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

  /// Armoured night guardian: slower, but heavier kicks and longer reach.
  static const HeroDefinition darkKnight = HeroDefinition(
    id: 'dark_knight',
    name: 'Dark Knight',
    title: 'Guardian of the Moon',
    abilityName: 'Night Strike',
    abilityDescription: 'Strong armoured kicks that push foes far away.',
    walkSpeed: 240,
    jumpPower: 0.96,
    attackSpeed: 0.95,
    punchDamage: 1.05,
    kickDamage: 1.2,
    reach: 1.08,
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

  static const List<HeroDefinition> all = [spiderShadow, darkKnight];

  static HeroDefinition byId(String id) =>
      all.firstWhere((h) => h.id == id, orElse: () => all.first);
}
