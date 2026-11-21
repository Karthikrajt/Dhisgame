import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'control_input.dart';

/// Large on-screen buttons: movement and jump on the left, attacks and
/// block on the right.
///
/// Each button tracks its own pointers with a [Listener], so several fingers
/// can hold different buttons at once without stealing each other's touches.
class TouchControls extends StatelessWidget {
  const TouchControls({super.key, required this.input});

  final ControlInput input;

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
              _PadButton(
                input: input,
                button: ControlButton.kick,
                size: size,
                text: AppStrings.kick,
                color: AppColors.opponentAccent,
                label: AppStrings.kick,
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
