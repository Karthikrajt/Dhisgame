import 'dart:ui';

import 'package:flame/components.dart';

import '../../../core/constants/game_constants.dart';
import '../characters/hero_pose.dart';
import '../characters/hero_renderer.dart';
import '../combat/fighter.dart';

/// Draws a [Fighter] model with the vector hero renderer.
class FighterComponent extends PositionComponent {
  FighterComponent(this.fighter) : super(priority: 10);

  final Fighter fighter;

  /// Set to true to draw hitboxes and hurtboxes while tuning combat.
  static bool debugBoxes = false;

  final Paint _flash = Paint();

  @override
  void update(double dt) {
    position.setValues(fighter.x, fighter.y);
    // The fighter in front (attacking) is drawn on top.
    priority = fighter.state.isAttacking ? 11 : 10;
  }

  @override
  void render(Canvas canvas) {
    final f = fighter;
    final moving = f.vx.abs() > 1 ? (f.vx.sign * f.facing) : 1.0;
    final pose = HeroPose.forState(
      f.state,
      stateTime: f.stateTime,
      animTime: f.animTime,
      attack: f.currentAttack,
      moveDir: moving,
      walkSpeed: f.hero.walkSpeed,
    );

    canvas.save();
    const s = GameConstants.fighterArtScale;
    canvas.scale(f.facing * s, s);
    // Invulnerability is shown with a steady soft transparency instead of
    // blinking, so the screen never flickers.
    final dim = f.invulnerable > 0 && !f.state.isFinal;
    if (dim) {
      canvas.saveLayer(null, _flash..color = const Color(0xC0FFFFFF));
    }
    HeroRenderer.paint(
      canvas,
      f.hero.look,
      pose,
      time: f.animTime,
      lift: (GameConstants.groundY - f.y) / s,
    );
    if (dim) canvas.restore();
    canvas.restore();

    if (debugBoxes) _renderDebug(canvas);
  }

  void _renderDebug(Canvas canvas) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.save();
    canvas.translate(-fighter.x, -fighter.y);
    canvas.drawRect(fighter.hurtbox, p..color = const Color(0xFF00FF88));
    final hit = fighter.activeHitbox;
    if (hit != null) canvas.drawRect(hit, p..color = const Color(0xFFFF3355));
    canvas.restore();
  }
}
