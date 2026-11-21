@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/features/battle/characters/hero_pose.dart';
import 'package:superhero_showdown/features/battle/characters/hero_renderer.dart';
import 'package:superhero_showdown/features/battle/characters/hero_roster.dart';
import 'package:superhero_showdown/features/battle/combat/attack_data.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_state.dart';

/// Renders every pose of every hero to build/preview/heroes.png.
/// Run with: flutter test --tags preview
void main() {
  test('render hero sheet', () async {
    final states = [
      (FighterState.idle, 0.3, null),
      (FighterState.walking, 0.2, null),
      (FighterState.jumping, 0.3, null),
      (FighterState.falling, 0.3, null),
      (FighterState.punching, 0.12, AttackData.punch),
      (FighterState.kicking, 0.2, AttackData.kick),
      (FighterState.blocking, 0.3, null),
      (FighterState.hit, 0.2, null),
      (FighterState.knockout, 1.0, null),
      (FighterState.victory, 0.6, null),
    ];
    const cell = 260.0;
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    canvas.drawColor(const ui.Color(0xFFDDE6F5), ui.BlendMode.src);
    for (var r = 0; r < HeroRoster.all.length; r++) {
      for (var c = 0; c < states.length; c++) {
        final (st, t, atk) = states[c];
        canvas.save();
        canvas.translate(c * cell + cell * 0.55, (r + 1) * 300.0 - 20);
        HeroRenderer.paint(
          canvas,
          HeroRoster.all[r].look,
          HeroPose.forState(st, stateTime: t, animTime: 1.3, attack: atk),
          time: 1.3,
        );
        canvas.restore();
      }
    }
    final img = await rec.endRecording().toImage(
      (cell * states.length).toInt(),
      300 * HeroRoster.all.length,
    );
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/preview').createSync(recursive: true);
    File('build/preview/heroes.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });

  test('render close-up', () async {
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    canvas.drawColor(const ui.Color(0xFFDDE6F5), ui.BlendMode.src);
    final poses = [
      (FighterState.idle, 0.3, null),
      (FighterState.punching, 0.12, AttackData.punch),
      (FighterState.kicking, 0.2, AttackData.kick),
    ];
    for (var h = 0; h < HeroRoster.all.length; h++) {
      for (var i = 0; i < poses.length; i++) {
        final (st, t, atk) = poses[i];
        canvas.save();
        canvas.translate((h * 3 + i) * 330.0 + 140, 580);
        canvas.scale(2);
        HeroRenderer.paint(
          canvas,
          HeroRoster.all[h].look,
          HeroPose.forState(st, stateTime: t, animTime: 1.3, attack: atk),
          time: 1.3,
        );
        canvas.restore();
      }
    }
    final img = await rec.endRecording().toImage(1980, 600);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/preview/heroes_closeup.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
