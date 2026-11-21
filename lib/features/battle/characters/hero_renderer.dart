import 'dart:math' as math;
import 'dart:ui';

import 'hero_definition.dart';
import 'hero_pose.dart';

/// Draws original, fully procedural cartoon heroes with bold outlines.
///
/// All artwork is vector geometry computed from a [HeroPose], so the same
/// code drives the battle, the selection previews and the result screens.
/// The hero is drawn facing right with the feet at the canvas origin.
abstract final class HeroRenderer {
  static const Color outline = Color(0xFF12142A);

  // Chibi proportions: a big friendly head on a short, chunky body.
  static const double thigh = 38;
  static const double shin = 36;
  static const double torsoLength = 58;
  static const double upperArm = 30;
  static const double foreArm = 28;
  static const double headRadius = 42;

  static final Paint _outlinePaint = Paint()
    ..color = outline
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _fill = Paint()..isAntiAlias = true;
  static final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Paints the hero. [time] drives cloth sway and orbiting KO stars.
  /// [lift] is how far the feet are above the floor, for the shadow.
  static void paint(
    Canvas canvas,
    HeroLook look,
    HeroPose pose, {
    double time = 0,
    double lift = 0,
    bool drawShadow = true,
  }) {
    if (drawShadow) _paintShadow(canvas, lift, pose.lie);

    canvas.save();
    if (pose.lie > 0) {
      // Topple backwards onto the floor like a cartoon.
      final angle = -math.pi / 2 * pose.lie;
      canvas.translate(-20 * pose.lie, -24 * pose.lie);
      canvas.rotate(angle);
    }
    canvas.translate(0, pose.bob);
    canvas.scale(1, pose.squash);

    final s = _Skeleton.solve(pose);
    final bulk = look.bulk;

    _paintBack(canvas, look, s, time);

    // Back limbs use the darker shade for depth.
    _arm(
      canvas,
      s.backShoulder,
      s.backElbow,
      s.backHand,
      look,
      bulk,
      shade: true,
    );
    _leg(canvas, s.backHip, s.backKnee, s.backFoot, look, bulk, shade: true);

    _leg(canvas, s.frontHip, s.frontKnee, s.frontFoot, look, bulk);
    if (look.backStyle == BackStyle.jetWings && !pose.grounded) {
      _rocketFlame(canvas, s.backFoot, time, 0.8);
      _rocketFlame(canvas, s.frontFoot, time + 0.4, 1);
    }
    _torso(canvas, look, s);
    _head(canvas, look, s, pose, time);

    _arm(canvas, s.frontShoulder, s.frontElbow, s.frontHand, look, bulk);
    if (look.headStyle == HeadStyle.crestHelm) {
      _pauldron(canvas, look, s);
    }

    canvas.restore();

    if (pose.mood == EyeMood.dizzy && pose.lie > 0.6) {
      _koStars(canvas, time);
    }
  }

  /// Paints just the head, centred in [size], for HUD portraits.
  static void paintPortrait(
    Canvas canvas,
    HeroLook look,
    Size size, {
    EyeMood mood = EyeMood.normal,
  }) {
    final scale = size.shortestSide / (headRadius * 2.6);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 4 * scale);
    canvas.scale(scale);
    final s = _Skeleton.portrait();
    _head(canvas, look, s, HeroPose(mood: mood), 0);
    canvas.restore();
  }

  // ---- Parts ------------------------------------------------------------

  static void _paintShadow(Canvas canvas, double lift, double lie) {
    final shrink = (1 - lift / 400).clamp(0.4, 1.0);
    final width = (70 + 90 * lie) * shrink;
    _fill.color = const Color(0x44000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-110 * lie, lift + 2),
        width: width * 2,
        height: 16,
      ),
      _fill,
    );
  }

  /// Direction of the key light in hero space (from upper front).
  static const Offset _light = Offset(-0.55, -0.83);

  /// Builds a muscular, tapered capsule from [a] to [b].
  ///
  /// [ra] and [rb] are the end radii and [rm] the radius at the middle,
  /// which gives limbs a bulging, cartoon-muscle silhouette.
  static Path _capsule(Offset a, Offset b, double ra, double rm, double rb) {
    final d = b - a;
    final len = d.distance;
    final path = Path();
    if (len < 0.01) {
      return path;
    }
    final u = d / len;
    final n = Offset(-u.dy, u.dx);
    final mid = Offset.lerp(a, b, 0.42)!;
    path
      ..moveTo((a + n * ra).dx, (a + n * ra).dy)
      ..quadraticBezierTo(
        (mid + n * rm * 1.22).dx,
        (mid + n * rm * 1.22).dy,
        (b + n * rb).dx,
        (b + n * rb).dy,
      )
      ..lineTo((b - n * rb).dx, (b - n * rb).dy)
      ..quadraticBezierTo(
        (mid - n * rm * 1.22).dx,
        (mid - n * rm * 1.22).dy,
        (a - n * ra).dx,
        (a - n * ra).dy,
      )
      ..close();
    return path;
  }

  /// Fills a capsule. The body and the round end caps are drawn as separate
  /// shapes so overlapping contours can never cancel out into holes.
  static void _drawCapsule(
    Canvas canvas,
    Offset a,
    Offset b,
    double ra,
    double rm,
    double rb,
    Paint paint,
  ) {
    canvas.drawPath(_capsule(a, b, ra, rm, rb), paint);
    canvas.drawCircle(a, ra, paint);
    canvas.drawCircle(b, rb, paint);
  }

  /// Draws a shaded, outlined limb segment.
  static void _segment(
    Canvas canvas,
    Offset a,
    Offset b,
    double ra,
    double rm,
    double rb,
    Color color, {
    bool outlined = true,
  }) {
    if (outlined) {
      _fill
        ..shader = null
        ..color = outline;
      _drawCapsule(canvas, a, b, ra + 3.5, rm + 3, rb + 3.5, _fill);
    }
    // Cylinder shading: lit along the side of the limb facing the light,
    // with a crisp cel-shaded shadow along the opposite side.
    final d = b - a;
    final len = d.distance == 0 ? 1.0 : d.distance;
    var n = Offset(-d.dy / len, d.dx / len);
    if (n.dx * _light.dx + n.dy * _light.dy > 0) n = -n;
    final mid = Offset.lerp(a, b, 0.45)!;
    final r = math.max(rm, math.max(ra, rb)) * 1.2;
    _fill.color = const Color(0xFF000000);
    _fill.shader = Gradient.linear(
      mid + n * r,
      mid - n * r,
      [_lighten(color, 0.22), color, color, _darken(color, 0.3)],
      const [0.15, 0.4, 0.66, 0.66],
    );
    _drawCapsule(canvas, a, b, ra, rm, rb, _fill);
    _fill.shader = null;
  }

  static void _arm(
    Canvas canvas,
    Offset shoulder,
    Offset elbow,
    Offset hand,
    HeroLook look,
    double bulk, {
    bool shade = false,
  }) {
    final suit = shade ? look.suitShade : look.suit;
    final glove = shade ? _darken(look.gloves, 0.25) : look.gloves;
    final b = bulk;
    // Outline both segments first so the joint reads as one shape.
    _fill.color = outline;
    _drawCapsule(canvas, shoulder, elbow, 13 * b, 13.5 * b, 11 * b, _fill);
    _drawCapsule(canvas, elbow, hand, 11 * b, 12 * b, 10.5 * b, _fill);

    _segment(
      canvas,
      shoulder,
      elbow,
      10 * b,
      10.5 * b,
      7.8 * b,
      suit,
      outlined: false,
    );
    _segment(
      canvas,
      elbow,
      hand,
      7.8 * b,
      8.8 * b,
      7.2 * b,
      suit,
      outlined: false,
    );

    // Glove cuff flares over the lower forearm.
    final cuff = Offset.lerp(elbow, hand, 0.5)!;
    _segment(canvas, cuff, hand, 8.6 * b, 9.6 * b, 9.2 * b, glove);
    _fist(canvas, hand, elbow, glove, b);
  }

  static void _fist(
    Canvas canvas,
    Offset hand,
    Offset elbow,
    Color color,
    double bulk,
  ) {
    final d = hand - elbow;
    final len = d.distance == 0 ? 1.0 : d.distance;
    final u = d / len;
    final c = hand + u * 6 * bulk;
    final r = 12.5 * bulk;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.atan2(u.dy, u.dx));
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: r * 2.2,
      height: r * 2,
    );
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.8));
    _fill.color = outline;
    canvas.drawRRect(rr.inflate(3.5), _fill);
    _fill.color = const Color(0xFF000000);
    _fill.shader = Gradient.linear(
      Offset(0, -r),
      Offset(0, r),
      [_lighten(color, 0.3), color, color, _darken(color, 0.3)],
      const [0.0, 0.35, 0.65, 0.65],
    );
    canvas.drawRRect(rr, _fill);
    _fill.shader = null;
    // Finger groove.
    _stroke
      ..color = _withAlpha(outline, 0.5)
      ..strokeWidth = 2.5;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(r * 0.25, 0),
        width: r * 1.2,
        height: r * 1.3,
      ),
      -math.pi * 0.35,
      math.pi * 0.7,
      false,
      _stroke,
    );
    canvas.restore();
  }

  static void _leg(
    Canvas canvas,
    Offset hip,
    Offset knee,
    Offset foot,
    HeroLook look,
    double bulk, {
    bool shade = false,
  }) {
    final suit = shade ? look.suitShade : look.suit;
    final boot = shade ? _darken(look.boots, 0.25) : look.boots;
    final b = bulk;

    _fill.color = outline;
    _drawCapsule(canvas, hip, knee, 16.5 * b, 17 * b, 12.5 * b, _fill);
    _drawCapsule(canvas, knee, foot, 12.5 * b, 13.5 * b, 10.5 * b, _fill);
    _segment(
      canvas,
      hip,
      knee,
      13 * b,
      13.5 * b,
      9.5 * b,
      suit,
      outlined: false,
    );
    _segment(
      canvas,
      knee,
      foot,
      9.5 * b,
      10.6 * b,
      7.5 * b,
      suit,
      outlined: false,
    );

    // Foot direction: perpendicular to the shin, pointing forward.
    final d = foot - knee;
    final len = d.distance == 0 ? 1.0 : d.distance;
    final down = d / len;
    final forward = Offset(down.dy, -down.dx);

    // Boot shaft with a folded cuff.
    final bootTop = Offset.lerp(knee, foot, 0.42)!;
    _segment(canvas, bootTop, foot, 10.2 * b, 10.6 * b, 9.6 * b, boot);
    _segment(
      canvas,
      bootTop - down * 2,
      bootTop + down * 6,
      12 * b,
      12 * b,
      11.5 * b,
      _lighten(boot, 0.12),
    );

    // Boot foot and sole.
    final heel = foot - forward * 3 + down * 3;
    final toe = foot + forward * 19 * b + down * 4;
    _segment(canvas, heel, toe, 10 * b, 10 * b, 8.5 * b, boot);
  }

  static void _torso(Canvas canvas, HeroLook look, _Skeleton s) {
    final b = look.bulk;
    final up = s.torsoUp;
    final side = Offset(-up.dy, up.dx);
    final hip = s.pelvis + up * -4;
    final top = s.neck + up * 4;
    Offset at(double t, double w) => Offset.lerp(hip, top, t)! + side * w;

    // Heroic V-shape: narrow waist, broad chest and shoulders.
    final hipW = 20 * b;
    final waistW = 17.5 * b;
    final chestW = 29 * b;
    final shoulderW = 27 * b;
    final path = Path()
      ..moveTo(at(0, hipW).dx, at(0, hipW).dy)
      ..cubicTo(
        at(0.2, hipW).dx,
        at(0.2, hipW).dy,
        at(0.3, waistW).dx,
        at(0.3, waistW).dy,
        at(0.45, waistW + 3).dx,
        at(0.45, waistW + 3).dy,
      )
      ..cubicTo(
        at(0.62, chestW + 4).dx,
        at(0.62, chestW + 4).dy,
        at(0.86, chestW + 2).dx,
        at(0.86, chestW + 2).dy,
        at(0.96, shoulderW).dx,
        at(0.96, shoulderW).dy,
      )
      ..quadraticBezierTo(
        at(1.08, 0).dx,
        at(1.08, 0).dy,
        at(0.96, -shoulderW).dx,
        at(0.96, -shoulderW).dy,
      )
      ..cubicTo(
        at(0.86, -chestW - 2).dx,
        at(0.86, -chestW - 2).dy,
        at(0.62, -chestW - 3).dx,
        at(0.62, -chestW - 3).dy,
        at(0.45, -waistW - 2).dx,
        at(0.45, -waistW - 2).dy,
      )
      ..cubicTo(
        at(0.3, -waistW).dx,
        at(0.3, -waistW).dy,
        at(0.2, -hipW).dx,
        at(0.2, -hipW).dy,
        at(0, -hipW).dx,
        at(0, -hipW).dy,
      )
      ..quadraticBezierTo(
        at(-0.12, 0).dx,
        at(-0.12, 0).dy,
        at(0, hipW).dx,
        at(0, hipW).dy,
      )
      ..close();

    _outlinePaint.strokeWidth = 7;
    canvas.drawPath(path, _outlinePaint);
    final c = Offset.lerp(hip, top, 0.6)!;
    _fill.color = const Color(0xFF000000);
    _fill.shader = Gradient.linear(
      c + _light * 40,
      c - _light * 40,
      [_lighten(look.suit, 0.25), look.suit, look.suit, look.suitShade],
      const [0.0, 0.3, 0.62, 0.62],
    );
    canvas.drawPath(path, _fill);
    _fill.shader = null;

    // Chest muscle line and a hint of abs, drawn softly.
    _stroke
      ..color = _withAlpha(outline, 0.45)
      ..strokeWidth = 3;
    final pec = Path()
      ..moveTo(at(0.62, chestW * 0.75).dx, at(0.62, chestW * 0.75).dy)
      ..quadraticBezierTo(
        at(0.55, 0).dx,
        at(0.55, 0).dy,
        at(0.62, -chestW * 0.6).dx,
        at(0.62, -chestW * 0.6).dy,
      );
    canvas.drawPath(pec, _stroke);
    canvas.drawLine(at(0.5, 3), at(0.3, 3), _stroke);

    // Trim stripes down the sides of the suit.
    _stroke
      ..color = look.trim
      ..strokeWidth = 4;
    final stripe = Path()
      ..moveTo(at(0.95, -shoulderW + 4).dx, at(0.95, -shoulderW + 4).dy)
      ..quadraticBezierTo(
        at(0.6, -chestW + 2).dx,
        at(0.6, -chestW + 2).dy,
        at(0.3, -waistW + 3).dx,
        at(0.3, -waistW + 3).dy,
      );
    canvas.drawPath(stripe, _stroke);

    // Belt with buckle.
    final beltA = at(0.12, hipW + 2);
    final beltB = at(0.12, -hipW - 2);
    _stroke
      ..color = outline
      ..strokeWidth = 12;
    canvas.drawLine(beltA, beltB, _stroke);
    _stroke
      ..color = look.trim
      ..strokeWidth = 7;
    canvas.drawLine(beltA, beltB, _stroke);
    final buckle = at(0.12, 4);
    _fill.color = outline;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: buckle, width: 15, height: 13),
        const Radius.circular(3),
      ),
      _fill,
    );
    _fill.color = _lighten(look.emblem, 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: buckle, width: 9, height: 7),
        const Radius.circular(2),
      ),
      _fill,
    );

    _emblem(canvas, look, at(0.72, 3), up);
  }

  static void _emblem(Canvas canvas, HeroLook look, Offset c, Offset up) {
    canvas.save();
    canvas.translate(c.dx + 4, c.dy);
    canvas.rotate(math.atan2(up.dy, up.dx) + math.pi / 2);
    switch (look.emblemStyle) {
      case EmblemStyle.orbSpinner:
        // An original "web wheel": a ring with four swirling spokes.
        _fill.color = outline;
        canvas.drawCircle(Offset.zero, 15, _fill);
        _fill.color = look.emblem;
        canvas.drawCircle(Offset.zero, 12, _fill);
        _fill.color = look.suitShade;
        canvas.drawCircle(Offset.zero, 5.5, _fill);
        _stroke
          ..color = look.suitShade
          ..strokeWidth = 2.6;
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2;
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: 9),
            a,
            0.9,
            false,
            _stroke,
          );
        }
      case EmblemStyle.crescentStar:
        // An original crescent moon with a small star.
        final moon = Path()
          ..addOval(Rect.fromCircle(center: Offset.zero, radius: 13));
        final bite = Path()
          ..addOval(Rect.fromCircle(center: const Offset(6, -3), radius: 11));
        final crescent = Path.combine(PathOperation.difference, moon, bite);
        _outlinePaint.strokeWidth = 4;
        canvas.drawPath(crescent, _outlinePaint);
        _fill.color = look.emblem;
        canvas.drawPath(crescent, _fill);
        _star(canvas, const Offset(7, -1), 5.5, look.emblem);
      case EmblemStyle.sunburst:
        // Golden sun with eight friendly rays.
        final rays = Path();
        for (var i = 0; i < 16; i++) {
          final rr = i.isEven ? 16.0 : 10.0;
          final a = i * math.pi / 8;
          final p = Offset(math.cos(a) * rr, math.sin(a) * rr);
          i == 0 ? rays.moveTo(p.dx, p.dy) : rays.lineTo(p.dx, p.dy);
        }
        rays.close();
        _outlinePaint.strokeWidth = 4;
        canvas.drawPath(rays, _outlinePaint);
        _fill.color = look.emblem;
        canvas.drawPath(rays, _fill);
        _fill.color = _lighten(look.emblem, 0.45);
        canvas.drawCircle(Offset.zero, 6.5, _fill);
      case EmblemStyle.lightning:
        final bolt = Path()
          ..moveTo(3, -16)
          ..lineTo(-9, 2)
          ..lineTo(-1, 2)
          ..lineTo(-5, 16)
          ..lineTo(9, -3)
          ..lineTo(1, -3)
          ..close();
        _outlinePaint.strokeWidth = 4;
        canvas.drawPath(bolt, _outlinePaint);
        _fill.color = look.emblem;
        canvas.drawPath(bolt, _fill);
      case EmblemStyle.energyCore:
        // Glowing chest core: a steady glow, never blinking.
        _fill
          ..color = _withAlpha(look.emblem, 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
        canvas.drawCircle(Offset.zero, 15, _fill);
        _fill.maskFilter = null;
        _fill.color = outline;
        canvas.drawCircle(Offset.zero, 13, _fill);
        _fill.color = const Color(0xFF8A8F99);
        canvas.drawCircle(Offset.zero, 10.5, _fill);
        _fill.color = look.emblem;
        canvas.drawCircle(Offset.zero, 8, _fill);
        _fill.color = const Color(0xFFFFFFFF);
        canvas.drawCircle(Offset.zero, 3.5, _fill);
    }
    canvas.restore();
  }

  static void _pauldron(Canvas canvas, HeroLook look, _Skeleton s) {
    final rect = Rect.fromCircle(center: s.frontShoulder, radius: 17);
    _fill.color = outline;
    canvas.drawArc(rect.inflate(3.5), math.pi, math.pi, true, _fill);
    _fill.color = look.trim;
    canvas.drawArc(rect, math.pi, math.pi, true, _fill);
    _fill.color = const Color(0x44FFFFFF);
    canvas.drawArc(rect.deflate(6), math.pi * 1.1, math.pi * 0.5, true, _fill);
  }

  static void _paintBack(Canvas canvas, HeroLook look, _Skeleton s, double t) {
    final up = s.torsoUp;
    final neck = s.neck;
    switch (look.backStyle) {
      case BackStyle.scarf:
        // Two scarf tails trailing behind and waving gently.
        for (var i = 0; i < 2; i++) {
          final phase = t * 6 + i * 1.3;
          final len = 58.0 - i * 12;
          final start = neck + const Offset(-6, 6);
          final mid =
              start + Offset(-len * 0.5, 14 + i * 8 + math.sin(phase) * 5);
          final end =
              start +
              Offset(-len * 0.9, 38 + i * 10 + math.sin(phase + 1.2) * 8);
          final path = Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo(mid.dx, mid.dy - 6, end.dx, end.dy);
          _outlinePaint.strokeWidth = 17;
          canvas.drawPath(path, _outlinePaint);
          _stroke
            ..color = i == 0 ? look.back : _darken(look.back, 0.2)
            ..strokeWidth = 10;
          canvas.drawPath(path, _stroke);
        }
      case BackStyle.scallopCape:
        // Short cape with a wing-like scalloped hem.
        final sway = math.sin(t * 2.4) * 5;
        final top = neck + up * -4;
        final side = Offset(-up.dy, up.dx);
        final hem = s.pelvis + up * -44 + Offset(-34 + sway, 0);
        final a = top + side * 18;
        final b = top - side * 22 + const Offset(-6, 0);
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(hem.dx + 30, hem.dy - 40, hem.dx + 26, hem.dy - 4)
          ..quadraticBezierTo(hem.dx + 16, hem.dy - 18, hem.dx + 6, hem.dy + 6)
          ..quadraticBezierTo(hem.dx - 6, hem.dy - 14, hem.dx - 16, hem.dy + 10)
          ..quadraticBezierTo(
            hem.dx - 26,
            hem.dy - 10,
            hem.dx - 40 - sway,
            hem.dy + 2,
          )
          ..quadraticBezierTo(b.dx - 34, b.dy + 30, b.dx, b.dy)
          ..close();
        _outlinePaint.strokeWidth = 7;
        canvas.drawPath(path, _outlinePaint);
        _fill.color = look.back;
        canvas.drawPath(path, _fill);
        // Inner lining peeks out along the top edge.
        _stroke
          ..color = _darken(look.back, 0.35)
          ..strokeWidth = 5;
        canvas.drawLine(a, b, _stroke);
      case BackStyle.flowCape:
        // Long cape that flows and ripples gently behind the hero.
        final side = Offset(-up.dy, up.dx);
        final top = neck + up * -6;
        final a = top + side * 16;
        final b = top - side * 20;
        final w1 = math.sin(t * 3.0) * 6;
        final w2 = math.sin(t * 3.0 + 1.4) * 8;
        final hemY = s.pelvis.dy + 52;
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(a.dx - 10, hemY - 50, a.dx - 18 + w1, hemY)
          ..quadraticBezierTo(
            a.dx - 40,
            hemY + 10 + w1,
            a.dx - 62 + w2,
            hemY + 2,
          )
          ..quadraticBezierTo(
            a.dx - 84 + w2,
            hemY + 8,
            a.dx - 92 + w2,
            hemY - 6,
          )
          ..quadraticBezierTo(b.dx - 50, b.dy + 30, b.dx, b.dy)
          ..close();
        _outlinePaint.strokeWidth = 7;
        canvas.drawPath(path, _outlinePaint);
        _fill.color = const Color(0xFF000000);
        _fill.shader = Gradient.linear(a, Offset(a.dx - 80, hemY), [
          look.back,
          _darken(look.back, 0.3),
        ]);
        canvas.drawPath(path, _fill);
        _fill.shader = null;
        _stroke
          ..color = _withAlpha(_darken(look.back, 0.4), 0.6)
          ..strokeWidth = 3;
        canvas.drawLine(
          Offset(a.dx - 30, a.dy + 30),
          Offset(a.dx - 44 + w1, hemY - 4),
          _stroke,
        );
      case BackStyle.none:
        break;
      case BackStyle.jetWings:
        // A compact jet pack with two swept golden wings.
        final side = Offset(-up.dy, up.dx);
        final base = Offset.lerp(s.pelvis, neck, 0.7)! - side * 14;
        for (final k in [0.0, 1.0]) {
          final tip = base + up * (34 - k * 18) + Offset(-48 + k * 10, 0);
          final wing = Path()
            ..moveTo(base.dx, base.dy - 10 + k * 14)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(base.dx - 8, base.dy + 10 + k * 14)
            ..close();
          _outlinePaint.strokeWidth = 6;
          canvas.drawPath(wing, _outlinePaint);
          _fill.color = k == 0 ? look.back : _darken(look.back, 0.2);
          canvas.drawPath(wing, _fill);
        }
        final pack = RRect.fromRectAndRadius(
          Rect.fromCenter(center: base, width: 22, height: 40),
          const Radius.circular(8),
        );
        _fill.color = outline;
        canvas.drawRRect(pack.inflate(3.5), _fill);
        _fill.color = _lighten(look.suitShade, 0.1);
        canvas.drawRRect(pack, _fill);
    }
  }

  static void _rocketFlame(Canvas canvas, Offset foot, double t, double k) {
    final len = (26 + math.sin(t * 9) * 4) * k;
    final c = foot + const Offset(0, 12);
    final path = Path()
      ..moveTo(c.dx - 9, c.dy)
      ..quadraticBezierTo(c.dx - 6, c.dy + len * 0.6, c.dx, c.dy + len)
      ..quadraticBezierTo(c.dx + 6, c.dy + len * 0.6, c.dx + 9, c.dy)
      ..close();
    _fill.color = const Color(0xCCFF9800);
    canvas.drawPath(path, _fill);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(0.55, 0.6);
    canvas.translate(-c.dx, -c.dy);
    _fill.color = const Color(0xEEFFF59D);
    canvas.drawPath(path, _fill);
    canvas.restore();
  }

  static void _head(
    Canvas canvas,
    HeroLook look,
    _Skeleton s,
    HeroPose pose,
    double t,
  ) {
    final c = s.head;
    final r = headRadius;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(pose.headTilt + pose.lean * 0.5);

    // Neck.
    _fill.color = outline;
    canvas.drawCircle(Offset(0, r * 0.82), 12, _fill);
    _fill.color = look.suitShade;
    canvas.drawCircle(Offset(0, r * 0.82), 8.5, _fill);

    switch (look.headStyle) {
      case HeadStyle.goggleHood:
        _goggleHood(canvas, look, r, pose.mood);
      case HeadStyle.crestHelm:
        _crestHelm(canvas, look, r, pose.mood);
      case HeadStyle.sunHelm:
        _sunHelm(canvas, look, r, pose.mood);
      case HeadStyle.headband:
        _headband(canvas, look, r, pose.mood);
      case HeadStyle.falconHelm:
        _falconHelm(canvas, look, r, pose.mood);
    }
    canvas.restore();
  }

  static final Map<int, Path> _headCache = {};

  /// Rounded helmet/mask silhouette with a strong cartoon jaw that juts
  /// slightly forward, so heads read as faces rather than balls.
  static Path _headShape(double r, {double grow = 0}) {
    final key = ((r + grow) * 100).round();
    return _headCache.putIfAbsent(key, () {
      final skull = Path()
        ..addOval(Rect.fromCircle(center: Offset.zero, radius: r + grow));
      final jaw = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              -r * 0.55 - grow,
              r * 0.05 - grow,
              r * 1.05 + grow,
              r * 1.08 + grow,
            ),
            Radius.circular(r * 0.5 + grow),
          ),
        );
      return Path.combine(PathOperation.union, skull, jaw);
    });
  }

  static void _goggleHood(
    Canvas canvas,
    HeroLook look,
    double r,
    EyeMood mood,
  ) {
    // Hood points: two small rounded tips, like a stylised spider's palps.
    for (final x in [-0.45, 0.2]) {
      final tip = Path()
        ..moveTo(r * (x - 0.22), -r * 0.7)
        ..quadraticBezierTo(
          r * (x - 0.05),
          -r * 1.35,
          r * (x + 0.22),
          -r * 0.72,
        )
        ..close();
      _outlinePaint.strokeWidth = 6;
      canvas.drawPath(tip, _outlinePaint);
      _fill.color = look.trim;
      canvas.drawPath(tip, _fill);
    }

    _fill.color = outline;
    canvas.drawPath(_headShape(r, grow: 3.5), _fill);
    _fill.color = look.suit;
    canvas.drawPath(_headShape(r), _fill);

    // Red hood rim framing the face.
    _stroke
      ..color = look.trim
      ..strokeWidth = 7;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r - 4),
      math.pi * 0.95,
      math.pi * 1.1,
      false,
      _stroke,
    );

    // Shading on the back of the head.
    canvas.save();
    canvas.clipPath(_headShape(r));
    _fill.color = _withAlpha(look.suitShade, 0.8);
    canvas.drawCircle(Offset(-r * 1.1, r * 0.2), r * 0.8, _fill);
    canvas.restore();

    _eyes(
      canvas,
      look,
      mood,
      front: Offset(r * 0.42, r * 0.02),
      back: Offset(-r * 0.12, r * 0.02),
      frontRadius: r * 0.34,
      backRadius: r * 0.28,
      round: true,
    );
  }

  static void _crestHelm(Canvas canvas, HeroLook look, double r, EyeMood mood) {
    // Swept-back crest fin running over the helmet.
    final crest = Path()
      ..moveTo(r * 0.5, -r * 0.75)
      ..quadraticBezierTo(r * 0.1, -r * 1.55, -r * 1.05, -r * 1.25)
      ..quadraticBezierTo(-r * 0.5, -r * 1.0, -r * 0.6, -r * 0.4)
      ..close();
    _outlinePaint.strokeWidth = 6;
    canvas.drawPath(crest, _outlinePaint);
    _fill.color = look.trim;
    canvas.drawPath(crest, _fill);

    // Helmet dome.
    _fill.color = outline;
    canvas.drawPath(_headShape(r, grow: 3.5), _fill);
    _fill.color = look.suit;
    canvas.drawPath(_headShape(r), _fill);

    canvas.save();
    canvas.clipPath(_headShape(r));
    _fill.color = _withAlpha(look.suitShade, 0.85);
    canvas.drawCircle(Offset(-r * 1.05, r * 0.1), r * 0.85, _fill);
    // Light jaw guard.
    _fill.color = _lighten(look.suit, 0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-r * 0.1, r * 0.35, r * 1.2, r * 0.7),
        Radius.circular(r * 0.3),
      ),
      _fill,
    );
    // Dark visor band.
    _fill.color = const Color(0xFF15172B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-r * 0.45, -r * 0.3, r * 1.6, r * 0.55),
        Radius.circular(r * 0.25),
      ),
      _fill,
    );
    canvas.restore();

    _eyes(
      canvas,
      look,
      mood,
      front: Offset(r * 0.5, -r * 0.03),
      back: Offset(-r * 0.05, -r * 0.03),
      frontRadius: r * 0.24,
      backRadius: r * 0.2,
      round: false,
    );
  }

  static void _headBase(Canvas canvas, Color color, Color shade, double r) {
    _fill.color = outline;
    canvas.drawPath(_headShape(r, grow: 3.5), _fill);
    _fill.color = color;
    canvas.drawPath(_headShape(r), _fill);
    canvas.save();
    canvas.clipPath(_headShape(r));
    _fill.color = _withAlpha(shade, 0.8);
    canvas.drawCircle(Offset(-r * 1.1, r * 0.25), r * 0.8, _fill);
    _fill.color = const Color(0x33FFFFFF);
    canvas.drawCircle(Offset(r * 0.15, -r * 0.55), r * 0.35, _fill);
    canvas.restore();
  }

  static void _sunHelm(Canvas canvas, HeroLook look, double r, EyeMood mood) {
    // Three sun-ray spikes crowning a golden helmet.
    for (final (x, h) in [(-0.55, 1.35), (-0.05, 1.55), (0.45, 1.3)]) {
      final ray = Path()
        ..moveTo(r * (x - 0.2), -r * 0.75)
        ..lineTo(r * x, -r * h)
        ..lineTo(r * (x + 0.2), -r * 0.75)
        ..close();
      _outlinePaint.strokeWidth = 6;
      canvas.drawPath(ray, _outlinePaint);
      _fill.color = look.trim;
      canvas.drawPath(ray, _fill);
    }
    _headBase(canvas, look.suit, look.suitShade, r);
    canvas.save();
    canvas.clipPath(_headShape(r));
    _fill.color = look.trim;
    canvas.drawRect(
      Rect.fromLTRB(-r * 1.2, -r * 1.2, r * 1.2, -r * 0.42),
      _fill,
    );
    _fill.color = _darken(look.trim, 0.2);
    canvas.drawRect(
      Rect.fromLTRB(-r * 1.2, -r * 0.5, r * 1.2, -r * 0.4),
      _fill,
    );
    canvas.restore();
    _eyes(
      canvas,
      look,
      mood,
      front: Offset(r * 0.42, r * 0.05),
      back: Offset(-r * 0.12, r * 0.05),
      frontRadius: r * 0.3,
      backRadius: r * 0.25,
      round: true,
    );
    _smile(canvas, Offset(r * 0.38, r * 0.62), r * 0.22, mood);
  }

  static void _headband(Canvas canvas, HeroLook look, double r, EyeMood mood) {
    final skin = look.skin ?? look.suit;
    // Spiky tuft of hair.
    final hair = Path()..moveTo(-r * 0.9, -r * 0.45);
    for (var i = 0; i < 5; i++) {
      final x0 = -r * 0.9 + i * r * 0.36;
      hair
        ..lineTo(x0 + r * 0.12, -r * (1.25 + (i.isEven ? 0.1 : 0)))
        ..lineTo(x0 + r * 0.36, -r * 0.7);
    }
    hair.close();
    _outlinePaint.strokeWidth = 6;
    canvas.drawPath(hair, _outlinePaint);
    _fill.color = const Color(0xFF3B2A5C);
    canvas.drawPath(hair, _fill);

    _headBase(canvas, skin, _darken(skin, 0.3), r);
    canvas.save();
    canvas.clipPath(_headShape(r));
    final band = Rect.fromLTRB(-r * 1.2, -r * 0.62, r * 1.2, -r * 0.3);
    _fill.color = outline;
    canvas.drawRect(band.inflate(2.5), _fill);
    _fill.color = look.suit;
    canvas.drawRect(band, _fill);
    canvas.restore();
    // Little lightning bolt on the band.
    canvas.save();
    canvas.translate(r * 0.35, -r * 0.46);
    canvas.scale(0.55);
    final bolt = Path()
      ..moveTo(3, -16)
      ..lineTo(-9, 2)
      ..lineTo(-1, 2)
      ..lineTo(-5, 16)
      ..lineTo(9, -3)
      ..lineTo(1, -3)
      ..close();
    _fill.color = look.emblem;
    canvas.drawPath(bolt, _fill);
    canvas.restore();

    _eyes(
      canvas,
      look,
      mood,
      front: Offset(r * 0.42, r * 0.02),
      back: Offset(-r * 0.1, r * 0.02),
      frontRadius: r * 0.27,
      backRadius: r * 0.22,
      round: true,
      lineColor: outline,
      thickBrows: true,
    );
    _smile(canvas, Offset(r * 0.38, r * 0.6), r * 0.3, mood, teeth: true);
  }

  static void _falconHelm(
    Canvas canvas,
    HeroLook look,
    double r,
    EyeMood mood,
  ) {
    // Two swept-back wing fins.
    for (final k in [0.0, 1.0]) {
      final fin = Path()
        ..moveTo(-r * 0.3, -r * (0.75 - k * 0.3))
        ..lineTo(-r * (1.45 - k * 0.15), -r * (1.1 - k * 0.35))
        ..lineTo(-r * 0.8, -r * (0.35 - k * 0.3))
        ..close();
      _outlinePaint.strokeWidth = 6;
      canvas.drawPath(fin, _outlinePaint);
      _fill.color = k == 0 ? look.trim : _darken(look.trim, 0.2);
      canvas.drawPath(fin, _fill);
    }
    _headBase(canvas, look.suit, look.suitShade, r);
    canvas.save();
    canvas.clipPath(_headShape(r));
    // Golden faceplate that comes to a falcon-beak point.
    final plate = Path()
      ..moveTo(-r * 0.15, -r * 0.55)
      ..quadraticBezierTo(r * 0.7, -r * 0.7, r * 1.2, -r * 0.1)
      ..lineTo(r * 1.0, r * 0.5)
      ..quadraticBezierTo(r * 0.6, r * 1.2, r * 0.1, r * 1.1)
      ..quadraticBezierTo(-r * 0.2, r * 0.4, -r * 0.15, -r * 0.55)
      ..close();
    _fill.color = outline;
    canvas.drawPath(plate.shift(const Offset(-3, 0)), _fill);
    _fill.color = look.trim;
    canvas.drawPath(plate, _fill);
    _stroke
      ..color = _withAlpha(outline, 0.4)
      ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(r * 0.25, r * 0.55),
      Offset(r * 0.85, r * 0.55),
      _stroke,
    );
    canvas.restore();
    _eyes(
      canvas,
      look,
      mood,
      front: Offset(r * 0.55, -r * 0.08),
      back: Offset(r * 0.02, -r * 0.08),
      frontRadius: r * 0.22,
      backRadius: r * 0.18,
      round: false,
      lineColor: outline,
    );
  }

  /// A friendly mouth that changes with the mood.
  static void _smile(
    Canvas canvas,
    Offset c,
    double w,
    EyeMood mood, {
    bool teeth = false,
  }) {
    _stroke
      ..color = outline
      ..strokeWidth = 3.5;
    switch (mood) {
      case EyeMood.hurt:
        _fill.color = outline;
        canvas.drawOval(
          Rect.fromCenter(center: c, width: w * 0.8, height: w * 0.9),
          _fill,
        );
      case EyeMood.dizzy:
        final p = Path()..moveTo(c.dx - w, c.dy);
        for (var i = 1; i <= 4; i++) {
          p.lineTo(c.dx - w + i * w / 2, c.dy + (i.isOdd ? -3 : 3));
        }
        canvas.drawPath(p, _stroke);
      case EyeMood.happy:
      case EyeMood.focused:
        final mouth = Path()
          ..moveTo(c.dx - w, c.dy - w * 0.25)
          ..quadraticBezierTo(c.dx, c.dy + w * 1.1, c.dx + w, c.dy - w * 0.25)
          ..close();
        _fill.color = outline;
        canvas.drawPath(mouth, _fill);
        if (teeth || mood == EyeMood.focused) {
          _fill.color = const Color(0xFFFFFFFF);
          canvas.drawRect(
            Rect.fromLTRB(
              c.dx - w * 0.75,
              c.dy - w * 0.15,
              c.dx + w * 0.75,
              c.dy + w * 0.12,
            ),
            _fill,
          );
        }
      case EyeMood.normal:
        canvas.drawArc(
          Rect.fromCenter(center: c, width: w * 2, height: w * 1.2),
          0.2,
          math.pi - 0.4,
          false,
          _stroke,
        );
    }
  }

  static void _eyes(
    Canvas canvas,
    HeroLook look,
    EyeMood mood, {
    required Offset front,
    required Offset back,
    required double frontRadius,
    required double backRadius,
    required bool round,
    Color? lineColor,
    bool thickBrows = false,
  }) {
    final line = lineColor ?? look.eyes;
    for (final (center, radius) in [(back, backRadius), (front, frontRadius)]) {
      switch (mood) {
        case EyeMood.hurt:
          // Squeezed-shut cartoon eyes: > <
          _stroke
            ..color = line
            ..strokeWidth = 4;
          final w = radius * 0.8;
          final path = Path()
            ..moveTo(center.dx - w, center.dy - w * 0.7)
            ..lineTo(center.dx + w * 0.4, center.dy)
            ..lineTo(center.dx - w, center.dy + w * 0.7);
          canvas.drawPath(path, _stroke);
        case EyeMood.dizzy:
          _stroke
            ..color = line
            ..strokeWidth = 3;
          final spiral = Path();
          for (var i = 0; i <= 24; i++) {
            final a = i / 24 * math.pi * 3.5;
            final rr = radius * 0.9 * i / 24;
            final p = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
            i == 0 ? spiral.moveTo(p.dx, p.dy) : spiral.lineTo(p.dx, p.dy);
          }
          canvas.drawPath(spiral, _stroke);
        case EyeMood.happy:
          _stroke
            ..color = line
            ..strokeWidth = 4.5;
          canvas.drawArc(
            Rect.fromCircle(
              center: center + Offset(0, radius * 0.3),
              radius: radius * 0.75,
            ),
            math.pi * 1.1,
            math.pi * 0.8,
            false,
            _stroke,
          );
        case EyeMood.normal:
        case EyeMood.focused:
          final focused = mood == EyeMood.focused;
          if (look.eyeGlow) {
            _fill
              ..color = _withAlpha(look.eyes, 0.55)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
            canvas.drawOval(_eyeRect(center, radius * 1.3, round), _fill);
            _fill.maskFilter = null;
          }
          final rect = _eyeRect(center, radius, round);
          _fill.color = outline;
          canvas.drawOval(rect.inflate(2.5), _fill);
          _fill.color = look.eyes;
          canvas.drawOval(rect, _fill);
          if (round) {
            // Pupils give the mask big, friendly, expressive eyes.
            _fill.color = outline;
            canvas.drawCircle(
              center + Offset(radius * 0.3, radius * 0.05),
              radius * (focused ? 0.38 : 0.48),
              _fill,
            );
            _fill.color = const Color(0xFFFFFFFF);
            canvas.drawCircle(
              center + Offset(radius * 0.42, -radius * 0.15),
              radius * 0.15,
              _fill,
            );
          }
          // Brow line that angles down when focused.
          _stroke
            ..color = outline
            ..strokeWidth = thickBrows ? 7 : 4.5;
          final tilt = focused ? radius * 0.45 : 0.0;
          canvas.drawLine(
            center + Offset(-radius, -radius * 1.2 - tilt * 0.3),
            center + Offset(radius, -radius * 1.2 + tilt),
            _stroke,
          );
      }
    }
  }

  static Rect _eyeRect(Offset c, double r, bool round) => round
      ? Rect.fromCenter(center: c, width: r * 1.8, height: r * 2.1)
      : Rect.fromCenter(center: c, width: r * 2.2, height: r * 1.0);

  static void _koStars(Canvas canvas, double t) {
    // Head position when lying on the back (see the lie rotation above).
    const center = Offset(-205, -80);
    for (var i = 0; i < 3; i++) {
      final a = t * 2.2 + i * math.pi * 2 / 3;
      final p = center + Offset(math.cos(a) * 34, math.sin(a) * 10 - 20);
      _star(canvas, p, 9, const Color(0xFFFFD54A));
    }
  }

  static void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    _outlinePaint.strokeWidth = 3.5;
    canvas.drawPath(path, _outlinePaint);
    _fill.color = color;
    canvas.drawPath(path, _fill);
  }

  static Color _darken(Color c, double amount) =>
      Color.lerp(c, const Color(0xFF000000), amount)!;
  static Color _lighten(Color c, double amount) =>
      Color.lerp(c, const Color(0xFFFFFFFF), amount)!;
  static Color _withAlpha(Color c, double a) => c.withValues(alpha: a);
}

/// Joint positions solved from a pose (forward kinematics).
class _Skeleton {
  _Skeleton({
    required this.pelvis,
    required this.neck,
    required this.head,
    required this.torsoUp,
    required this.frontHip,
    required this.backHip,
    required this.frontKnee,
    required this.backKnee,
    required this.frontFoot,
    required this.backFoot,
    required this.frontShoulder,
    required this.backShoulder,
    required this.frontElbow,
    required this.backElbow,
    required this.frontHand,
    required this.backHand,
  });

  final Offset pelvis;
  final Offset neck;
  final Offset head;

  /// Unit vector pointing up along the spine.
  final Offset torsoUp;
  final Offset frontHip;
  final Offset backHip;
  final Offset frontKnee;
  final Offset backKnee;
  final Offset frontFoot;
  final Offset backFoot;
  final Offset frontShoulder;
  final Offset backShoulder;
  final Offset frontElbow;
  final Offset backElbow;
  final Offset frontHand;
  final Offset backHand;

  /// Direction for an angle measured from straight down, positive forward.
  static Offset _dir(double a) => Offset(math.sin(a), math.cos(a));

  static _Skeleton solve(HeroPose p) {
    const thigh = HeroRenderer.thigh;
    const shin = HeroRenderer.shin;

    final fKneeRel = _dir(p.frontHip) * thigh;
    final fFootRel = fKneeRel + _dir(p.frontHip - p.frontKnee) * shin;
    final bKneeRel = _dir(p.backHip) * thigh;
    final bFootRel = bKneeRel + _dir(p.backHip - p.backKnee) * shin;

    // Lower the hips until the lowest foot touches the floor.
    final drop = p.grounded
        ? math.max(fFootRel.dy, bFootRel.dy)
        : (thigh + shin) * 0.92;
    final pelvis = Offset(0, -drop - 6);
    final frontHip = pelvis + const Offset(4, 0);
    final backHip = pelvis + const Offset(-4, 0);

    final up = Offset(math.sin(p.lean), -math.cos(p.lean));
    final neck = pelvis + up * HeroRenderer.torsoLength;
    final head = neck + up * (HeroRenderer.headRadius + 4) + const Offset(3, 0);

    final fShoulder = neck + const Offset(5, 12);
    final bShoulder = neck + const Offset(-5, 10);
    final fElbow = fShoulder + _dir(p.frontShoulder) * HeroRenderer.upperArm;
    final fHand =
        fElbow + _dir(p.frontShoulder + p.frontElbow) * HeroRenderer.foreArm;
    final bElbow = bShoulder + _dir(p.backShoulder) * HeroRenderer.upperArm;
    final bHand =
        bElbow + _dir(p.backShoulder + p.backElbow) * HeroRenderer.foreArm;

    return _Skeleton(
      pelvis: pelvis,
      neck: neck,
      head: head,
      torsoUp: up,
      frontHip: frontHip,
      backHip: backHip,
      frontKnee: frontHip + fKneeRel,
      backKnee: backHip + bKneeRel,
      frontFoot: frontHip + fFootRel,
      backFoot: backHip + bFootRel,
      frontShoulder: fShoulder,
      backShoulder: bShoulder,
      frontElbow: fElbow,
      backElbow: bElbow,
      frontHand: fHand,
      backHand: bHand,
    );
  }

  static _Skeleton portrait() {
    const z = Offset.zero;
    return _Skeleton(
      pelvis: z,
      neck: z,
      head: z,
      torsoUp: const Offset(0, -1),
      frontHip: z,
      backHip: z,
      frontKnee: z,
      backKnee: z,
      frontFoot: z,
      backFoot: z,
      frontShoulder: z,
      backShoulder: z,
      frontElbow: z,
      backElbow: z,
      frontHand: z,
      backHand: z,
    );
  }
}
