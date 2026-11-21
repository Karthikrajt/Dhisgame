import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// A cartoon "pow" burst where a hit lands. Grows and fades over a quarter
/// of a second: bright enough to read, but never a full-screen flash.
class HitBurst extends PositionComponent {
  HitBurst({required Vector2 at, this.big = false, this.color})
    : super(position: at, priority: 20);

  final bool big;

  /// Optional tint for superpower hits.
  final Color? color;
  double _t = 0;
  static const double _life = 0.32;
  final Paint _paint = Paint();

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final grow = 1 - (1 - k) * (1 - k);
    final size = (big ? 48 : 36) * (0.5 + grow * 0.7);
    final alpha = 1 - k;

    final path = Path();
    const spikes = 8;
    for (var i = 0; i < spikes * 2; i++) {
      final r = i.isEven ? size : size * 0.5;
      final a = i * math.pi / spikes + 0.2;
      final p = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    _paint
      ..style = PaintingStyle.fill
      ..color = (color ?? const Color(0xFFFFD64A)).withValues(alpha: alpha);
    canvas.drawPath(path, _paint);
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Color.fromRGBO(255, 255, 255, alpha * 0.9);
    canvas.drawPath(path, _paint);
    _paint.style = PaintingStyle.fill;
    _paint.color = Color.fromRGBO(255, 140, 60, alpha);
    canvas.drawCircle(Offset.zero, size * 0.3, _paint);
  }
}

/// A blue shield ripple shown when an attack is blocked.
class BlockRipple extends PositionComponent {
  BlockRipple({required Vector2 at}) : super(position: at, priority: 20);

  double _t = 0;
  static const double _life = 0.3;
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    _paint
      ..strokeWidth = 7 * (1 - k) + 1
      ..color = Color.fromRGBO(120, 210, 255, 1 - k);
    final r = 22 + k * 30;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r),
      -math.pi * 0.45,
      math.pi * 0.9,
      false,
      _paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.65),
      -math.pi * 0.4,
      math.pi * 0.8,
      false,
      _paint,
    );
  }
}

/// Soft grey cartoon smoke puffs for knockouts and landings.
class SmokePuffs extends PositionComponent {
  SmokePuffs({required Vector2 at, int count = 6, this.spread = 60})
    : _puffs = List.generate(count, (i) {
        final r = math.Random(i * 31 + at.x.toInt());
        return _Puff(
          dx: (r.nextDouble() - 0.5) * 2,
          dy: -r.nextDouble(),
          size: 10 + r.nextDouble() * 12,
        );
      }),
      super(position: at, priority: 19);

  final double spread;
  final List<_Puff> _puffs;
  double _t = 0;
  static const double _life = 0.9;
  final Paint _paint = Paint();

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final ease = 1 - (1 - k) * (1 - k);
    for (final p in _puffs) {
      _paint.color = Color.fromRGBO(235, 232, 245, 0.75 * (1 - k));
      canvas.drawCircle(
        Offset(p.dx * spread * ease, p.dy * spread * 0.6 * ease - 6),
        p.size * (0.6 + ease * 0.8),
        _paint,
      );
    }
  }
}

class _Puff {
  _Puff({required this.dx, required this.dy, required this.size});
  final double dx;
  final double dy;
  final double size;
}
