import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/features/battle/characters/hero_pose.dart';
import 'package:superhero_showdown/features/battle/characters/hero_renderer.dart';
import 'package:superhero_showdown/features/battle/characters/hero_roster.dart';
import 'package:superhero_showdown/features/battle/combat/attack_data.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_state.dart';

void main() {
  test('every hero renders every state without errors', () {
    for (final hero in HeroRoster.all) {
      for (final state in FighterState.values) {
        for (final t in [0.0, 0.05, 0.2, 1.0]) {
          final rec = PictureRecorder();
          final canvas = Canvas(rec);
          final attack = state == FighterState.kicking
              ? AttackData.kick
              : AttackData.punch;
          HeroRenderer.paint(
            canvas,
            hero.look,
            HeroPose.forState(state, stateTime: t, animTime: t, attack: attack),
            time: t,
          );
          rec.endRecording().dispose();
        }
      }
      final rec = PictureRecorder();
      HeroRenderer.paintPortrait(Canvas(rec), hero.look, const Size(60, 60));
      rec.endRecording().dispose();
    }
  });

  test('grounded poses keep the feet on the floor', () {
    // Lerping between poses must never produce NaN angles.
    final p = HeroPose.lerp(HeroPose.guard, HeroPose.kickHit, 0.5);
    expect(p.frontHip.isFinite, isTrue);
    expect(p.grounded, isTrue);
  });

  test('roster heroes have unique ids and names', () {
    final ids = HeroRoster.all.map((h) => h.id).toSet();
    final names = HeroRoster.all.map((h) => h.name).toSet();
    expect(ids.length, HeroRoster.all.length);
    expect(names.length, HeroRoster.all.length);
    expect(HeroRoster.byId('dark_knight'), HeroRoster.darkKnight);
  });
}
