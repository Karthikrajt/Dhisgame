import 'package:material_ui/material_ui.dart';

import '../../core/audio/game_audio.dart';
import '../../core/constants/app_colors.dart';

/// Chunky comic-book style button with a press-down animation.
class ArcadeButton extends StatefulWidget {
  const ArcadeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.gold,
    this.icon,
    this.width,
    this.fontSize = 24,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final double? width;
  final double fontSize;

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : Colors.grey.shade500;
    return Semantics(
      button: true,
      label: widget.label,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                GameAudio.instance.play(Sfx.tap);
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.width,
          transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.ink, width: 4),
            boxShadow: [
              BoxShadow(color: AppColors.ink, offset: Offset(0, _down ? 2 : 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: AppColors.ink,
                  size: widget.fontSize + 4,
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
