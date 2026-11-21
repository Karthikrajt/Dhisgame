@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/features/battle/characters/hero_pose.dart';
import 'package:superhero_showdown/features/battle/characters/hero_renderer.dart';
import 'package:superhero_showdown/features/battle/characters/hero_roster.dart';
import 'package:superhero_showdown/features/battle/combat/fighter.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_state.dart';
import 'package:superhero_showdown/features/battle/combat/projectile.dart';
import 'package:superhero_showdown/features/battle/effects/power_effects.dart';

/// Renders each hero firing their superpower to build/preview/powers.png.
void main() {
  test('render powers', () async {
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    canvas.drawColor(const ui.Color(0xFF3A2A6E), ui.BlendMode.src);
    for (var i = 0; i < HeroRoster.all.length; i++) {
      final hero = HeroRoster.all[i];
      final f = Fighter(hero: hero, x: 120, facing: 1)..y = 600;
      canvas.save();
      canvas.translate(0, i * 260.0 - 360);
      // Hero mid-release.
      canvas.save();
      canvas.translate(f.x, f.y);
      canvas.scale(1.0, 1.0);
      final t = hero.special.kind.name == 'dash' ? 0.45 : 0.36;
      HeroRenderer.paint(
        canvas,
        hero.look,
        HeroPose.forState(FighterState.special,
            stateTime: t, animTime: 1, specialKind: hero.special.kind),
        time: 1,
      );
      canvas.restore();
      if (hero.special.kind.name == 'dash') {
        canvas.save();
        canvas.translate(f.x, f.y);
        canvas.restore();
      } else {
        final p = Projectile(owner: f)
          ..x = 520
          ..age = 0.25;
        ProjectileComponent(p).render(canvas);
      }
      canvas.restore();
    }
    final img = await rec.endRecording().toImage(800, 1000);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/powers.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
