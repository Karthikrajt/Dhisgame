import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../characters/hero_definition.dart';
import '../combat/fighter.dart';
import '../combat/fighter_state.dart';
import '../combat/projectile.dart';

/// Draws a flying superpower. Removes itself when the projectile is done.
///
/// All glows are steady or slowly changing; nothing strobes.
class ProjectileComponent extends Component {
  ProjectileComponent(this.projectile) : super(priority: 15);

  final Projectile projectile;
  final Paint _paint = Paint();
  double _fade = 1;

  @override
  void update(double dt) {
    if (projectile.spent && projectile.kind != SpecialKind.beam) {
      _fade -= dt * 8;
    }
    if (projectile.done || _fade <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = projectile;
    switch (p.kind) {
      case SpecialKind.projectile:
        if (p.power.hitStun > 0.8) {
          _web(canvas, p);
        } else {
          _orb(canvas, p);
        }
      case SpecialKind.beam:
        _beam(canvas, p);
      case SpecialKind.shockwave:
        _wave(canvas, p);
      case SpecialKind.dash:
        break;
    }
  }

  void _orb(Canvas canvas, Projectile p) {
    final c = Offset(p.x, p.y);
    // Soft trail.
    for (var i = 1; i <= 5; i++) {
      _paint.color = p.power.glow.withValues(alpha: 0.18 * _fade * (6 - i) / 5);
      canvas.drawCircle(
        c - Offset(p.direction * i * 16.0, 0),
        22 - i * 2.5,
        _paint,
      );
    }
    _paint
      ..color = p.power.color.withValues(alpha: 0.6 * _fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(c, 30, _paint);
    _paint.maskFilter = null;
    _paint.color = p.power.color.withValues(alpha: _fade);
    canvas.drawCircle(c, 19, _paint);
    _paint.color = const Color(0xFFFFFFFF).withValues(alpha: _fade);
    canvas.drawCircle(c, 10, _paint);
  }

  void _web(Canvas canvas, Projectile p) {
    final c = Offset(p.x, p.y);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(p.age * 6 * p.direction);
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF12142A).withValues(alpha: 0.5 * _fade);
    _webShape(canvas, 36, offset: 1.5);
    _paint.color = p.power.color.withValues(alpha: _fade);
    _webShape(canvas, 35);
    _paint.style = PaintingStyle.fill;
    canvas.restore();
  }

  void _webShape(Canvas canvas, double r, {double offset = 0}) {
    canvas.save();
    canvas.translate(offset, offset);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(a), math.sin(a)) * r,
        _paint,
      );
    }
    for (final k in [0.45, 0.8]) {
      final path = Path();
      for (var i = 0; i <= 8; i++) {
        final a = i * math.pi / 4;
        final pt = Offset(math.cos(a), math.sin(a)) * r * k;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, _paint);
    }
    canvas.restore();
  }

  void _beam(Canvas canvas, Projectile p) {
    final life = (1 - p.age / Projectile.beamLife).clamp(0.0, 1.0);
    final fadeIn = (p.age / 0.06).clamp(0.0, 1.0);
    final a = life * fadeIn;
    final rect = Rect.fromLTRB(
      math.min(p.startX, p.x),
      p.y - 18,
      math.max(p.startX, p.x),
      p.y + 18,
    );
    _paint
      ..color = p.power.glow.withValues(alpha: 0.5 * a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(14), const Radius.circular(30)),
      _paint,
    );
    _paint.maskFilter = null;
    _paint.color = p.power.color.withValues(alpha: a);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      _paint,
    );
    _paint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * a);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(9), const Radius.circular(9)),
      _paint,
    );
    // Little sparkles riding along the beam.
    for (var i = 0; i < 6; i++) {
      final t = ((p.age * 2 + i / 6) % 1.0);
      final x = p.startX + (p.x - p.startX) * t;
      final y = p.y + math.sin(t * 20 + i) * 22;
      _sparkle(canvas, Offset(x, y), 7, p.power.glow.withValues(alpha: a));
    }
  }

  void _wave(Canvas canvas, Projectile p) {
    final g = p.y;
    final x = p.x;
    final dir = p.direction.toDouble();
    // Rolling arc of energy.
    for (var i = 0; i < 3; i++) {
      final r = 48.0 - i * 12;
      final cx = x - dir * i * 22;
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0 - i * 3
        ..strokeCap = StrokeCap.round
        ..color = (i == 0 ? p.power.color : p.power.glow).withValues(
          alpha: (0.95 - i * 0.25) * _fade,
        );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, g), radius: r),
        dir > 0 ? -math.pi * 0.5 : -math.pi,
        math.pi * 0.5,
        false,
        _paint,
      );
    }
    // Zig-zag thunder line on the floor behind it.
    final zig = Path()..moveTo(x, g - 4);
    for (var i = 1; i <= 6; i++) {
      zig.lineTo(x - dir * i * 18, g - 4 - (i.isOdd ? 12 : 0));
    }
    _paint
      ..strokeWidth = 5
      ..color = p.power.glow.withValues(alpha: 0.9 * _fade);
    canvas.drawPath(zig, _paint);
    _paint.style = PaintingStyle.fill;
    // Bouncing pebbles.
    for (var i = 0; i < 4; i++) {
      final h = (math.sin(p.age * 14 + i * 1.7).abs()) * 26;
      _paint.color = const Color(0xFF8D82C4).withValues(alpha: _fade);
      canvas.drawCircle(Offset(x - dir * (10 + i * 16), g - 6 - h), 5, _paint);
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    _paint.color = color;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.3, c.dy - r * 0.3)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.3, c.dy + r * 0.3)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.3, c.dy + r * 0.3)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.3, c.dy - r * 0.3)
      ..close();
    canvas.drawPath(path, _paint);
  }
}

/// Glow behind a hero powering up, afterimages during a dash, and a web
/// wrap on a hero caught by a web shot. Drawn behind/over each fighter.
class PowerAura {
  static final Paint _paint = Paint();

  /// Drawn before the hero (behind it), in world space at the hero's feet.
  static void paintBehind(Canvas canvas, Fighter f) {
    if (f.state != FighterState.special) return;
    final power = f.hero.special;
    final t = f.stateTime;
    if (t < SpecialPower.chargeTime) {
      final k = t / SpecialPower.chargeTime;
      _paint
        ..color = power.glow.withValues(alpha: 0.25 + 0.35 * k)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, -125),
          width: 150 + 40 * k,
          height: 280,
        ),
        _paint,
      );
      _paint.maskFilter = null;
      // Rising sparkles.
      for (var i = 0; i < 6; i++) {
        final y = -((t * 260 + i * 45) % 260);
        final x = math.sin(i * 2.1) * 60;
        _paint.color = power.color.withValues(alpha: 0.8);
        canvas.drawCircle(Offset(x, y), 4, _paint);
      }
    }
    if (power.kind == SpecialKind.dash &&
        t >= SpecialPower.chargeTime &&
        t < SpecialPower.chargeTime + SpecialPower.dashTime + 0.1) {
      // Streaks behind the dashing hero (in facing-local space: behind = -x).
      for (var i = 1; i <= 4; i++) {
        _paint.color = power.color.withValues(alpha: 0.35 - i * 0.07);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-60.0 * i - 40, -200 + i * 12.0, 70, 160 - i * 20.0),
            const Radius.circular(40),
          ),
          _paint,
        );
      }
    }
  }

  /// Drawn after the hero: a web wrapped around a stuck hero.
  static void paintFront(Canvas canvas, Fighter f) {
    if (f.webbed <= 0) return;
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xEEFFFFFF);
    for (var i = 0; i < 5; i++) {
      final y = -40.0 - i * 40;
      canvas.drawLine(Offset(-45, y - 15), Offset(45, y + 15), _paint);
      canvas.drawLine(Offset(-45, y + 15), Offset(45, y - 15), _paint);
    }
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -120), width: 110, height: 240),
      _paint,
    );
    _paint.style = PaintingStyle.fill;
  }
}
