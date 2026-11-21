import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';

/// Bold title text with a thick ink outline, comic-book style.
class ComicText extends StatelessWidget {
  const ComicText(
    this.text, {
    super.key,
    this.size = 48,
    this.color = AppColors.gold,
    this.outline = 8,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final double size;
  final Color color;
  final double outline;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.5,
      height: 1.05,
    );
    return Stack(
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outline
              ..strokeJoin = StrokeJoin.round
              ..color = AppColors.ink,
          ),
        ),
        Text(
          text,
          textAlign: textAlign,
          style: style.copyWith(color: color),
        ),
      ],
    );
  }
}
