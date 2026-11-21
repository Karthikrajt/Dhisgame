import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../core/constants/game_constants.dart';

/// Neon City Rooftop: dusk skyline with parallax layers, softly glowing
/// signs, drifting clouds and floating light motes.
///
/// Everything is drawn procedurally. Animations are slow and smooth, with no
/// flashing or strobing, to stay comfortable for young children.
class NeonRooftopArena extends Component {
  NeonRooftopArena({required this.focusX});

  /// Returns the horizontal point the camera is interested in (between the
  /// fighters). Background layers shift relative to it for parallax.
  final double Function() focusX;

  static const double _left = -700;
  static const double _right = GameConstants.worldWidth + 700;
  static const double _top = -400;
  static const double _bottom = GameConstants.worldHeight + 400;

  final _rng = math.Random(7);
  late final List<_Building> _far;
  late final List<_Building> _mid;
  late final List<_Cloud> _clouds;
  late final List<_Mote> _motes;
  late final Picture _farPicture;
  double _time = 0;

  final Paint _paint = Paint();

  @override
  Future<void> onLoad() async {
    _far = _makeBuildings(count: 26, minH: 160, maxH: 330, minW: 70, maxW: 140);
    _mid = _makeBuildings(count: 16, minH: 220, maxH: 420, minW: 110, maxW: 190);
    _clouds = List.generate(
      6,
      (i) => _Cloud(
        x: _left + _rng.nextDouble() * (_right - _left),
        y: 40 + _rng.nextDouble() * 160,
        scale: 0.7 + _rng.nextDouble() * 0.8,
        speed: 8 + _rng.nextDouble() * 10,
      ),
    );
    _motes = List.generate(
      28,
      (i) => _Mote(
        x: _rng.nextDouble() * GameConstants.worldWidth,
        y: _rng.nextDouble() * GameConstants.groundY,
        speed: 10 + _rng.nextDouble() * 20,
        phase: _rng.nextDouble() * math.pi * 2,
        size: 1.5 + _rng.nextDouble() * 2.5,
      ),
    );
    _farPicture = _recordFarSkyline();
  }

  List<_Building> _makeBuildings({
    required int count,
    required double minH,
    required double maxH,
    required double minW,
    required double maxW,
  }) {
    final list = <_Building>[];
    var x = _left;
    while (list.length < count && x < _right) {
      final w = minW + _rng.nextDouble() * (maxW - minW);
      final h = minH + _rng.nextDouble() * (maxH - minH);
      list.add(_Building(
        x: x,
        width: w,
        height: h,
        hue: _rng.nextInt(3),
        sign: _rng.nextDouble() < 0.35,
        seed: _rng.nextInt(1 << 20),
      ));
      x += w + 6 + _rng.nextDouble() * 30;
    }
    return list;
  }

  @override
  void update(double dt) {
    _time += dt;
    for (final c in _clouds) {
      c.x += c.speed * dt;
      if (c.x > _right + 200) c.x = _left - 200;
    }
    for (final m in _motes) {
      m.y -= m.speed * dt;
      if (m.y < 60) {
        m.y = GameConstants.groundY - 10;
        m.x = _rng.nextDouble() * GameConstants.worldWidth;
      }
    }
  }

  double get _parallax => (focusX() - GameConstants.worldWidth / 2);

  @override
  void render(Canvas canvas) {
    _sky(canvas);

    // Far skyline: barely moves.
    canvas.save();
    canvas.translate(-_parallax * 0.08, 0);
    canvas.drawPicture(_farPicture);
    canvas.restore();

    _cloudsLayer(canvas);

    // Mid skyline with neon signs.
    canvas.save();
    canvas.translate(-_parallax * 0.2, 0);
    _midSkyline(canvas);
    canvas.restore();

    _roof(canvas);
    _motesLayer(canvas);
  }

  void _sky(Canvas canvas) {
    const rect = Rect.fromLTRB(_left, _top, _right, _bottom);
    _paint.shader = Gradient.linear(
      const Offset(0, 0),
      const Offset(0, GameConstants.groundY),
      const [Color(0xFF2B1B5C), Color(0xFF6B3A8E), Color(0xFFF08A6B)],
      const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(rect, _paint);
    _paint.shader = null;

    // Big friendly moon with a soft halo (steady, never pulsing fast).
    const moon = Offset(960, 140);
    _paint
      ..color = const Color(0x33FFF3D6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(moon, 90, _paint);
    _paint.maskFilter = null;
    _paint.color = const Color(0xFFFFF0CF);
    canvas.drawCircle(moon, 56, _paint);
    _paint.color = const Color(0x22B08A60);
    canvas.drawCircle(moon + const Offset(-18, -10), 12, _paint);
    canvas.drawCircle(moon + const Offset(16, 18), 8, _paint);
  }

  Picture _recordFarSkyline() {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    final p = Paint();
    const base = GameConstants.groundY - 60;
    for (final b in _far) {
      p.color = const Color(0xFF3A2A6E);
      c.drawRect(Rect.fromLTWH(b.x, base - b.height, b.width, b.height + 400), p);
      final r = math.Random(b.seed);
      p.color = const Color(0x66FFD98A);
      for (var wy = base - b.height + 16; wy < base - 10; wy += 22) {
        for (var wx = b.x + 10; wx < b.x + b.width - 12; wx += 18) {
          if (r.nextDouble() < 0.3) {
            c.drawRect(Rect.fromLTWH(wx, wy, 7, 9), p);
          }
        }
      }
    }
    return rec.endRecording();
  }

  void _cloudsLayer(Canvas canvas) {
    _paint.color = const Color(0x40FFE1F0);
    for (final cl in _clouds) {
      final s = cl.scale;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cl.x, cl.y), width: 180 * s, height: 40 * s),
          _paint);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cl.x + 30 * s, cl.y - 14 * s),
              width: 100 * s,
              height: 36 * s),
          _paint);
    }
  }

  static const _neon = [Color(0xFFFF5FA2), Color(0xFF5FE1FF), Color(0xFFFFD25F)];
  static const _bodies = [Color(0xFF241A4A), Color(0xFF2C1F55), Color(0xFF1E1840)];

  void _midSkyline(Canvas canvas) {
    const base = GameConstants.groundY - 30;
    for (final b in _mid) {
      final rect = Rect.fromLTWH(b.x, base - b.height, b.width, b.height + 400);
      _paint.color = _bodies[b.hue];
      canvas.drawRect(rect, _paint);
      // Roof edge highlight.
      _paint.color = const Color(0x55FF9AC8);
      canvas.drawRect(Rect.fromLTWH(b.x, base - b.height, b.width, 4), _paint);

      final r = math.Random(b.seed);
      for (var wy = base - b.height + 22; wy < base - 20; wy += 30) {
        for (var wx = b.x + 14; wx < b.x + b.width - 20; wx += 26) {
          final lit = r.nextDouble() < 0.45;
          _paint.color = lit ? const Color(0xAAFFE7A8) : const Color(0x33000000);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(wx, wy, 12, 16), const Radius.circular(2)),
            _paint,
          );
        }
      }

      if (b.sign) {
        // Slow breathing glow: a 4 second cycle with a gentle range.
        final glow = 0.75 + 0.25 * math.sin(_time * 1.6 + b.seed % 10);
        final color = _neon[b.hue];
        final sign = Rect.fromLTWH(
            b.x + b.width * 0.2, base - b.height + 26, b.width * 0.6, 26);
        _paint
          ..color = color.withValues(alpha: 0.35 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawRRect(
            RRect.fromRectAndRadius(sign.inflate(6), const Radius.circular(10)),
            _paint);
        _paint.maskFilter = null;
        _paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = color.withValues(alpha: 0.6 + 0.4 * glow);
        canvas.drawRRect(
            RRect.fromRectAndRadius(sign, const Radius.circular(8)), _paint);
        _paint.style = PaintingStyle.fill;
      }
    }
  }

  void _roof(Canvas canvas) {
    const g = GameConstants.groundY;

    // Back railing.
    _paint.color = const Color(0xFF1A1433);
    canvas.drawRect(const Rect.fromLTRB(_left, g - 70, _right, g - 64), _paint);
    for (var x = _left; x < _right; x += 48) {
      canvas.drawRect(Rect.fromLTWH(x, g - 70, 5, 70), _paint);
    }

    // Water tower on the left and a vent unit on the right.
    _waterTower(canvas, const Offset(-10, g));
    _ventUnit(canvas, const Offset(1150, g));
    _antenna(canvas, const Offset(1290, g));

    // Roof floor.
    _paint.shader = Gradient.linear(
      const Offset(0, g),
      const Offset(0, g + 140),
      const [Color(0xFF4B4470), Color(0xFF2A2546)],
    );
    canvas.drawRect(const Rect.fromLTRB(_left, g, _right, _bottom), _paint);
    _paint.shader = null;

    // Floor edge and tiles.
    _paint.color = const Color(0xFF8D82C4);
    canvas.drawRect(const Rect.fromLTRB(_left, g, _right, g + 5), _paint);
    _paint
      ..color = const Color(0x332A2546)
      ..strokeWidth = 2;
    for (var x = _left; x < _right; x += 90) {
      canvas.drawLine(Offset(x, g + 5), Offset(x - 40, g + 140), _paint);
    }
    canvas.drawLine(const Offset(_left, g + 50), const Offset(_right, g + 50), _paint);

    // Neon floor strip reflecting the city glow.
    _paint.color = const Color(0x40FF5FA2);
    canvas.drawRect(const Rect.fromLTRB(_left, g + 5, _right, g + 9), _paint);
  }

  void _waterTower(Canvas canvas, Offset base) {
    _paint.color = const Color(0xFF231B42);
    for (final dx in [-40.0, 40.0]) {
      canvas.drawRect(Rect.fromLTWH(base.dx + dx - 4, base.dy - 150, 8, 150), _paint);
    }
    final tank = RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx - 60, base.dy - 260, 120, 120),
      const Radius.circular(16),
    );
    _paint.color = const Color(0xFF3C2E66);
    canvas.drawRRect(tank, _paint);
    _paint.color = const Color(0xFF4C3B80);
    canvas.drawRect(Rect.fromLTWH(base.dx - 60, base.dy - 220, 120, 8), _paint);
    final roof = Path()
      ..moveTo(base.dx - 66, base.dy - 258)
      ..lineTo(base.dx, base.dy - 300)
      ..lineTo(base.dx + 66, base.dy - 258)
      ..close();
    _paint.color = const Color(0xFF2E2352);
    canvas.drawPath(roof, _paint);
  }

  void _ventUnit(Canvas canvas, Offset base) {
    _paint.color = const Color(0xFF3A3263);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(base.dx - 70, base.dy - 80, 140, 80),
          const Radius.circular(8)),
      _paint,
    );
    // Slowly spinning fan.
    final c = Offset(base.dx, base.dy - 42);
    _paint.color = const Color(0xFF241D45);
    canvas.drawCircle(c, 28, _paint);
    _paint.color = const Color(0xFF6E62A8);
    for (var i = 0; i < 4; i++) {
      final a = _time * 2 + i * math.pi / 2;
      canvas.drawLine(
        c,
        c + Offset(math.cos(a), math.sin(a)) * 24,
        _paint..strokeWidth = 7,
      );
    }
  }

  void _antenna(Canvas canvas, Offset base) {
    _paint
      ..color = const Color(0xFF231B42)
      ..strokeWidth = 6;
    canvas.drawLine(base, base + const Offset(0, -240), _paint);
    canvas.drawLine(base + const Offset(-30, -180), base + const Offset(30, -180), _paint);
    // Soft beacon light that fades in and out slowly (no blinking).
    final glow = 0.5 + 0.5 * math.sin(_time * 1.2);
    _paint
      ..color = Color.fromRGBO(255, 120, 120, 0.25 + 0.35 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(base + const Offset(0, -244), 14, _paint);
    _paint.maskFilter = null;
    _paint.color = const Color(0xFFFF8A8A);
    canvas.drawCircle(base + const Offset(0, -244), 6, _paint);
  }

  void _motesLayer(Canvas canvas) {
    for (final m in _motes) {
      final x = m.x + math.sin(_time + m.phase) * 12;
      final a = 0.35 + 0.25 * math.sin(_time * 0.8 + m.phase);
      _paint.color = Color.fromRGBO(255, 230, 190, a);
      canvas.drawCircle(Offset(x, m.y), m.size, _paint);
    }
  }
}

class _Building {
  _Building({
    required this.x,
    required this.width,
    required this.height,
    required this.hue,
    required this.sign,
    required this.seed,
  });
  final double x;
  final double width;
  final double height;
  final int hue;
  final bool sign;
  final int seed;
}

class _Cloud {
  _Cloud({required this.x, required this.y, required this.scale, required this.speed});
  double x;
  final double y;
  final double scale;
  final double speed;
}

class _Mote {
  _Mote({
    required this.x,
    required this.y,
    required this.speed,
    required this.phase,
    required this.size,
  });
  double x;
  double y;
  final double speed;
  final double phase;
  final double size;
}
