import 'package:material_ui/material_ui.dart';

abstract final class AppColors {
  static const Color night = Color(0xFF1B1238);
  static const Color deepPurple = Color(0xFF2B1B5C);
  static const Color violet = Color(0xFF6B3A8E);
  static const Color sunset = Color(0xFFF08A6B);
  static const Color gold = Color(0xFFFFD54A);
  static const Color ink = Color(0xFF12142A);
  static const Color cream = Color(0xFFFFF4E0);
  static const Color health = Color(0xFF5BE37D);
  static const Color healthLow = Color(0xFFFFB347);
  static const Color damage = Color(0xFFFF6B6B);
  static const Color playerAccent = Color(0xFF5FE1FF);
  static const Color opponentAccent = Color(0xFFFF8A65);

  static const LinearGradient menuBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepPurple, violet, sunset],
    stops: [0, 0.6, 1],
  );
}
