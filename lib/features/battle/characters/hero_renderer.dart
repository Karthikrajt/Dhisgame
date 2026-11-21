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

  static const double thigh = 52;
  static const double shin = 50;
  static const double torsoLength = 72;
  static const double upperArm = 40;
  static const double foreArm = 37;
  static const double headRadius = 33;

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
    _limb(canvas, [s.backShoulder, s.backElbow, s.backHand], 15 * bulk,
        look.suitShade);
    _glove(canvas, s.backHand, look.gloves, bulk, shade: true);
    _leg(canvas, s.backHip, s.backKnee, s.backFoot, look, bulk, shade: true);

    _leg(canvas, s.frontHip, s.frontKnee, s.frontFoot, look, bulk);
    _torso(canvas, look, s);
    _head(canvas, look, s, pose, time);

    _limb(canvas, [s.frontShoulder, s.frontElbow, s.frontHand], 16 * bulk,
        look.suit);
    if (look.headStyle == HeadStyle.crestHelm) {
      _pauldron(canvas, look, s);
    }
    _glove(canvas, s.frontHand, look.gloves, bulk);

    canvas.restore();

    if (pose.mood == EyeMood.dizzy && pose.lie > 0.6) {
      _koStars(canvas, time);
    }
  }

  /// Paints just the head, centred in [size], for HUD portraits.
  static void paintPortrait(Canvas canvas, HeroLook look, Size size,
      {EyeMood mood = EyeMood.normal}) {
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
          center: Offset(-110 * lie, lift + 2), width: width * 2, height: 16),
      _fill,
    );
  }

  static void _limb(Canvas canvas, List<Offset> pts, double width, Color c) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    _outlinePaint.strokeWidth = width + 7;
    canvas.drawPath(path, _outlinePaint);
    _stroke
      ..color = c
      ..strokeWidth = width;
    canvas.drawPath(path, _stroke);
    // Soft highlight along the limb for a comic-book shaded look.
    _stroke
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = width * 0.3;
    canvas.save();
    canvas.translate(-width * 0.18, -width * 0.12);
    canvas.drawPath(path, _stroke);
    canvas.restore();
  }

  static void _leg(Canvas canvas, Offset hip, Offset knee, Offset foot,
      HeroLook look, double bulk,
      {bool shade = false}) {
    final suit = shade ? look.suitShade : look.suit;
    _limb(canvas, [hip, knee, foot], 19 * bulk, suit);

    // Boot covers the lower half of the shin.
    final bootTop = Offset.lerp(knee, foot, 0.45)!;
    final bootColor = shade ? _darken(look.boots, 0.25) : look.boots;
    _limb(canvas, [bootTop, foot], 20 * bulk, bootColor);

    // Foot points forward along the ground.
    final dir = (foot - knee);
    final len = dir.distance == 0 ? 1.0 : dir.distance;
    final down = Offset(dir.dx / len, dir.dy / len);
    final forward = Offset(-down.dy, down.dx) * -1;
    final toe = foot + forward * 16 + down * 2;
    final footPath = Path()
      ..moveTo(foot.dx, foot.dy)
      ..lineTo(toe.dx, toe.dy);
    _outlinePaint.strokeWidth = 18 * bulk + 6;
    canvas.drawPath(footPath, _outlinePaint);
    _stroke
      ..color = bootColor
      ..strokeWidth = 18 * bulk;
    canvas.drawPath(footPath, _stroke);
  }

  static void _glove(Canvas canvas, Offset hand, Color color, double bulk,
      {bool shade = false}) {
    final r = 12.5 * bulk;
    _fill.color = outline;
    canvas.drawCircle(hand, r + 3.5, _fill);
    _fill.color = shade ? _darken(color, 0.25) : color;
    canvas.drawCircle(hand, r, _fill);
    _fill.color = const Color(0x55FFFFFF);
    canvas.drawCircle(hand + Offset(-r * 0.3, -r * 0.35), r * 0.35, _fill);
  }

  static void _torso(Canvas canvas, HeroLook look, _Skeleton s) {
    final hipW = 21 * look.bulk;
    final chestW = 28 * look.bulk;
    final up = s.torsoUp;
    final side = Offset(-up.dy, up.dx);
    final hip = s.pelvis;
    final chest = s.neck + up * -10;

    final path = Path()
      ..moveTo((hip + side * hipW).dx, (hip + side * hipW).dy)
      ..quadraticBezierTo(
        (Offset.lerp(hip, chest, 0.55)! + side * (chestW + 6)).dx,
        (Offset.lerp(hip, chest, 0.55)! + side * (chestW + 6)).dy,
        (chest + side * chestW).dx,
        (chest + side * chestW).dy,
      )
      ..quadraticBezierTo(
        (chest + up * 14).dx,
        (chest + up * 14).dy,
        (chest - side * chestW).dx,
        (chest - side * chestW).dy,
      )
      ..quadraticBezierTo(
        (Offset.lerp(hip, chest, 0.55)! - side * (chestW + 4)).dx,
        (Offset.lerp(hip, chest, 0.55)! - side * (chestW + 4)).dy,
        (hip - side * hipW).dx,
        (hip - side * hipW).dy,
      )
      ..quadraticBezierTo(
        (hip - up * 8).dx,
        (hip - up * 8).dy,
        (hip + side * hipW).dx,
        (hip + side * hipW).dy,
      )
      ..close();

    _outlinePaint.strokeWidth = 7;
    canvas.drawPath(path, _outlinePaint);
    _fill.color = look.suit;
    canvas.drawPath(path, _fill);

    // Side shading on the back half of the body.
    canvas.save();
    canvas.clipPath(path);
    _fill.color = _withAlpha(look.suitShade, 0.7);
    canvas.drawCircle(hip + side * hipW * 1.9 + up * 30, 34, _fill);
    canvas.restore();

    // Belt.
    final beltA = hip + up * 10 + side * (hipW + 2);
    final beltB = hip + up * 10 - side * (hipW + 2);
    _stroke
      ..color = outline
      ..strokeWidth = 11;
    canvas.drawLine(beltA, beltB, _stroke);
    _stroke
      ..color = look.trim
      ..strokeWidth = 6;
    canvas.drawLine(beltA, beltB, _stroke);

    _emblem(canvas, look, Offset.lerp(hip, chest, 0.66)!, up);
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
          final mid = start +
              Offset(-len * 0.5, 14 + i * 8 + math.sin(phase) * 5);
          final end =
              start + Offset(-len * 0.9, 38 + i * 10 + math.sin(phase + 1.2) * 8);
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
          ..quadraticBezierTo(
              hem.dx + 30, hem.dy - 40, hem.dx + 26, hem.dy - 4)
          ..quadraticBezierTo(hem.dx + 16, hem.dy - 18, hem.dx + 6, hem.dy + 6)
          ..quadraticBezierTo(
              hem.dx - 6, hem.dy - 14, hem.dx - 16, hem.dy + 10)
          ..quadraticBezierTo(
              hem.dx - 26, hem.dy - 10, hem.dx - 40 - sway, hem.dy + 2)
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
    }
  }

  static void _head(
      Canvas canvas, HeroLook look, _Skeleton s, HeroPose pose, double t) {
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
    }
    canvas.restore();
  }

  static void _goggleHood(Canvas canvas, HeroLook look, double r, EyeMood mood) {
    // Hood points: two small rounded tips, like a stylised spider's palps.
    for (final x in [-0.45, 0.2]) {
      final tip = Path()
        ..moveTo(r * (x - 0.22), -r * 0.7)
        ..quadraticBezierTo(r * (x - 0.05), -r * 1.35, r * (x + 0.22), -r * 0.72)
        ..close();
      _outlinePaint.strokeWidth = 6;
      canvas.drawPath(tip, _outlinePaint);
      _fill.color = look.trim;
      canvas.drawPath(tip, _fill);
    }

    _fill.color = outline;
    canvas.drawCircle(Offset.zero, r + 3.5, _fill);
    _fill.color = look.suit;
    canvas.drawCircle(Offset.zero, r, _fill);

    // Red hood rim framing the face.
    _stroke
      ..color = look.trim
      ..strokeWidth = 7;
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r - 4),
        math.pi * 0.95, math.pi * 1.1, false, _stroke);

    // Shading on the back of the head.
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
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
    canvas.drawCircle(Offset.zero, r + 3.5, _fill);
    _fill.color = look.suit;
    canvas.drawCircle(Offset.zero, r, _fill);

    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
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

  static void _eyes(
    Canvas canvas,
    HeroLook look,
    EyeMood mood, {
    required Offset front,
    required Offset back,
    required double frontRadius,
    required double backRadius,
    required bool round,
  }) {
    for (final (center, radius) in [(back, backRadius), (front, frontRadius)]) {
      switch (mood) {
        case EyeMood.hurt:
          // Squeezed-shut cartoon eyes: > <
          _stroke
            ..color = look.eyes
            ..strokeWidth = 4;
          final w = radius * 0.8;
          final path = Path()
            ..moveTo(center.dx - w, center.dy - w * 0.7)
            ..lineTo(center.dx + w * 0.4, center.dy)
            ..lineTo(center.dx - w, center.dy + w * 0.7);
          canvas.drawPath(path, _stroke);
        case EyeMood.dizzy:
          _stroke
            ..color = look.eyes
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
            ..color = look.eyes
            ..strokeWidth = 4.5;
          canvas.drawArc(
            Rect.fromCircle(center: center + Offset(0, radius * 0.3),
                radius: radius * 0.75),
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
            ..strokeWidth = 4.5;
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
    const center = Offset(-250, -60);
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
    final head = neck + up * (HeroRenderer.headRadius + 8) + const Offset(3, 0);

    final fShoulder = neck + const Offset(5, 12);
    final bShoulder = neck + const Offset(-5, 10);
    final fElbow = fShoulder + _dir(p.frontShoulder) * HeroRenderer.upperArm;
    final fHand = fElbow +
        _dir(p.frontShoulder + p.frontElbow) * HeroRenderer.foreArm;
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
