import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/battle/characters/hero_definition.dart';
import '../../features/battle/characters/hero_pose.dart';
import '../../features/battle/characters/hero_renderer.dart';
import '../../features/battle/combat/fighter_state.dart';

/// Animated, vector-drawn hero for menus (idle or victory loop).
class HeroPreview extends StatefulWidget {
  const HeroPreview({
    super.key,
    required this.hero,
    this.state = FighterState.idle,
    this.facing = 1,
    this.animate = true,
  });

  final HeroDefinition hero;
  final FighterState state;
  final int facing;

  /// When false the hero is drawn in a single still pose.
  final bool animate;

  @override
  State<HeroPreview> createState() => _HeroPreviewState();
}

class _HeroPreviewState extends State<HeroPreview>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  final ValueNotifier<double> _time = ValueNotifier(0.5);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6 + 0.5)
        ..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _HeroPainter(
          hero: widget.hero,
          state: widget.state,
          facing: widget.facing,
          time: _time,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({
    required this.hero,
    required this.state,
    required this.facing,
    required this.time,
  }) : super(repaint: time);

  final HeroDefinition hero;
  final FighterState state;
  final int facing;
  final ValueListenable<double> time;

  /// Height of a standing hero in renderer units, plus some headroom.
  static const double _heroHeight = 300;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final scale = size.height / _heroHeight;
    canvas.save();
    canvas.translate(size.width / 2, size.height - 14 * scale);
    canvas.scale(scale * facing, scale);
    HeroRenderer.paint(
      canvas,
      hero.look,
      HeroPose.forState(state, stateTime: t, animTime: t),
      time: t,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.hero != hero || old.state != state || old.facing != facing;
}

/// Static head portrait used in the HUD.
class HeroPortrait extends StatelessWidget {
  const HeroPortrait({super.key, required this.hero, this.mood = EyeMood.normal});

  final HeroDefinition hero;
  final EyeMood mood;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PortraitPainter(hero, mood));
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.hero, this.mood);
  final HeroDefinition hero;
  final EyeMood mood;

  @override
  void paint(Canvas canvas, Size size) =>
      HeroRenderer.paintPortrait(canvas, hero.look, size, mood: mood);

  @override
  bool shouldRepaint(_PortraitPainter old) =>
      old.hero != hero || old.mood != mood;
}
