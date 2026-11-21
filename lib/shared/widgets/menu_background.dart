import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';

/// Dusk-sky gradient with comic halftone rays, shared by menu screens.
class MenuBackground extends StatelessWidget {
  const MenuBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.menuBackground),
      child: CustomPaint(
        painter: _RaysPainter(),
        child: SafeArea(child: child),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final paint = Paint()..color = const Color(0x14FFFFFF);
    final r = size.longestSide;
    for (var i = 0; i < 18; i++) {
      final a = i * math.pi * 2 / 18;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r)
        ..lineTo(center.dx + math.cos(a + 0.12) * r,
            center.dy + math.sin(a + 0.12) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
    // Rooftop silhouette along the bottom.
    final city = Paint()..color = const Color(0x552B1B5C);
    final rng = math.Random(3);
    var x = 0.0;
    while (x < size.width) {
      final w = 40 + rng.nextDouble() * 70;
      final h = 30 + rng.nextDouble() * size.height * 0.22;
      canvas.drawRect(Rect.fromLTWH(x, size.height - h, w, h), city);
      x += w + 4;
    }
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) => false;
}
