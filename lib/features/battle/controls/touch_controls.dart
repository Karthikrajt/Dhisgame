import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

import 'package:flutter/foundation.dart';

import '../game/hud_state.dart';
import 'control_input.dart';

/// Large on-screen buttons: movement and jump on the left, attacks and
/// block on the right.
///
/// Each button tracks its own pointers with a [Listener], so several fingers
/// can hold different buttons at once without stealing each other's touches.
class TouchControls extends StatelessWidget {
  const TouchControls({super.key, required this.input, required this.hud});

  final ControlInput input;

  /// Used to light up the POWER button when the energy meter is full.
  final ValueListenable<HudState?> hud;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale buttons with screen height, within comfortable limits.
        final size = (constraints.maxHeight * 0.2).clamp(64.0, 96.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PadButton(
                input: input,
                button: ControlButton.left,
                size: size,
                icon: Icons.arrow_back_rounded,
                color: AppColors.cream,
                label: 'Move left',
              ),
              SizedBox(width: size * 0.2),
              _PadButton(
                input: input,
                button: ControlButton.right,
                size: size,
                icon: Icons.arrow_forward_rounded,
                color: AppColors.cream,
                label: 'Move right',
              ),
              SizedBox(width: size * 0.2),
              Padding(
                padding: EdgeInsets.only(bottom: size * 0.55),
                child: _PadButton(
                  input: input,
                  button: ControlButton.jump,
                  size: size * 0.9,
                  icon: Icons.keyboard_double_arrow_up_rounded,
                  color: const Color(0xFFB9F6CA),
                  label: AppStrings.jump,
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: size * 0.55),
                child: _PadButton(
                  input: input,
                  button: ControlButton.block,
                  size: size * 0.85,
                  icon: Icons.shield_rounded,
                  color: const Color(0xFFB3E5FC),
                  label: AppStrings.block,
                ),
              ),
              SizedBox(width: size * 0.2),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<HudState?>(
                    valueListenable: hud,
                    builder: (context, state, _) => _PowerButton(
                      input: input,
                      size: size * 1.05,
                      ready: (state?.playerEnergy ?? 0) >= 1,
                      energy: state?.playerEnergy ?? 0,
                    ),
                  ),
                  SizedBox(height: size * 0.12),
                  _PadButton(
                    input: input,
                    button: ControlButton.kick,
                    size: size,
                    text: AppStrings.kick,
                    color: AppColors.opponentAccent,
                    label: AppStrings.kick,
                  ),
                ],
              ),
              SizedBox(width: size * 0.2),
              Padding(
                padding: EdgeInsets.only(bottom: size * 0.55),
                child: _PadButton(
                  input: input,
                  button: ControlButton.punch,
                  size: size * 1.05,
                  text: AppStrings.punch,
                  color: AppColors.gold,
                  label: AppStrings.punch,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PadButton extends StatefulWidget {
  const _PadButton({
    required this.input,
    required this.button,
    required this.size,
    required this.color,
    required this.label,
    this.icon,
    this.text,
  });

  final ControlInput input;
  final ControlButton button;
  final double size;
  final Color color;
  final String label;
  final IconData? icon;
  final String? text;

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  final Set<int> _pointers = {};

  void _down(PointerDownEvent e) {
    if (_pointers.add(e.pointer)) {
      widget.input.press(widget.button);
      setState(() {});
    }
  }

  void _up(PointerEvent e) {
    if (_pointers.remove(e.pointer)) {
      widget.input.release(widget.button);
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final _ in _pointers) {
      widget.input.release(widget.button);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pointers.isNotEmpty;
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 60),
          scale: pressed ? 0.9 : 1,
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed
                  ? Color.lerp(widget.color, Colors.white, 0.4)
                  : widget.color.withValues(alpha: 0.72),
              border: Border.all(color: AppColors.ink, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.7),
                  offset: Offset(0, pressed ? 1 : 5),
                ),
              ],
            ),
            child: widget.icon != null
                ? Icon(
                    widget.icon,
                    size: widget.size * 0.5,
                    color: AppColors.ink,
                  )
                : Padding(
                    padding: const EdgeInsets.all(6),
                    child: FittedBox(
                      child: Text(
                        widget.text!.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The big star-shaped superpower button. It fills up with the energy meter
/// and glows softly (no blinking) when ready.
class _PowerButton extends StatefulWidget {
  const _PowerButton({
    required this.input,
    required this.size,
    required this.ready,
    required this.energy,
  });

  final ControlInput input;
  final double size;
  final bool ready;
  final double energy;

  @override
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton> {
  final Set<int> _pointers = {};

  void _down(PointerDownEvent e) {
    if (_pointers.add(e.pointer)) {
      widget.input.press(ControlButton.special);
      setState(() {});
    }
  }

  void _up(PointerEvent e) {
    if (_pointers.remove(e.pointer)) {
      widget.input.release(ControlButton.special);
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final _ in _pointers) {
      widget.input.release(ControlButton.special);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pointers.isNotEmpty;
    return Semantics(
      button: true,
      label: AppStrings.superpower,
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: pressed ? 0.9 : (widget.ready ? 1.08 : 1),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _StarPainter(
                ready: widget.ready,
                energy: widget.energy,
                pressed: pressed,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: widget.size * 0.08),
                  child: Text(
                    AppStrings.power.toUpperCase(),
                    style: TextStyle(
                      fontSize: widget.size * 0.15,
                      fontWeight: FontWeight.w900,
                      color: widget.ready
                          ? AppColors.ink
                          : AppColors.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({
    required this.ready,
    required this.energy,
    required this.pressed,
  });

  final bool ready;
  final double energy;
  final bool pressed;

  Path _star(Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.55;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final star = _star(size);
    if (ready) {
      canvas.drawPath(
        star,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    canvas.drawPath(
      star,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(star, Paint()..color = const Color(0xCC4A4466));
    // Energy fills the star from the bottom up.
    canvas.save();
    canvas.clipPath(star);
    final top = size.height * (1 - energy.clamp(0.0, 1.0));
    canvas.drawRect(
      Rect.fromLTRB(0, top, size.width, size.height),
      Paint()
        ..color = ready
            ? (pressed ? const Color(0xFFFFF59D) : AppColors.gold)
            : const Color(0xFFBFA6FF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.ready != ready || old.energy != energy || old.pressed != pressed;
}
