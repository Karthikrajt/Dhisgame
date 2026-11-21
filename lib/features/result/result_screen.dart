import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/battle_setup.dart';
import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/arcade_button.dart';
import '../../shared/widgets/comic_text.dart';
import '../../shared/widgets/hero_preview.dart';
import '../../shared/widgets/menu_background.dart';
import '../battle/combat/fighter_state.dart';
import '../battle/combat/match_controller.dart';

/// Victory, defeat or draw screen with replay options.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.outcome});

  final MatchOutcome outcome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(battleSetupProvider);
    final won = outcome == MatchOutcome.playerWins;
    final lost = outcome == MatchOutcome.opponentWins;

    final title = won
        ? AppStrings.victory
        : lost
        ? AppStrings.defeat
        : AppStrings.draw;
    final line = won
        ? AppStrings.victoryLine
        : lost
        ? AppStrings.defeatLine
        : AppStrings.drawLine;

    return Scaffold(
      body: MenuBackground(
        child: Stack(
          children: [
            if (won) const Positioned.fill(child: _StarShower()),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: HeroPreview(
                      hero: setup.player,
                      state: won ? FighterState.victory : FighterState.idle,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ComicText(
                            title,
                            key: const ValueKey('result_title'),
                            size: 64,
                            color: won ? AppColors.gold : AppColors.cream,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          line,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ArcadeButton(
                          label: AppStrings.tryAgain,
                          icon: Icons.replay_rounded,
                          width: 270,
                          onPressed: () =>
                              Navigator.of(context)
                                  .pushReplacementNamed(Routes.versus),
                        ),
                        const SizedBox(height: 12),
                        ArcadeButton(
                          label: AppStrings.changeHeroes,
                          icon: Icons.people_alt_rounded,
                          width: 270,
                          fontSize: 20,
                          color: AppColors.playerAccent,
                          onPressed: () => Navigator.of(
                            context,
                          ).popUntil((r) => r.settings.name == Routes.select),
                        ),
                        const SizedBox(height: 12),
                        ArcadeButton(
                          label: AppStrings.mainMenu,
                          icon: Icons.home_rounded,
                          width: 270,
                          fontSize: 20,
                          color: AppColors.cream,
                          onPressed: () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 60, 16, 16),
                    child: HeroPreview(
                      hero: setup.opponent,
                      facing: -1,
                      state: lost ? FighterState.victory : FighterState.idle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Gently falling celebration stars (slow, soft colours, no flashing).
class _StarShower extends StatefulWidget {
  const _StarShower();

  @override
  State<_StarShower> createState() => _StarShowerState();
}

class _StarShowerState extends State<_StarShower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _StarPainter(_c)));
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.anim) : super(repaint: anim);
  final Animation<double> anim;

  static const _colors = [
    Color(0xFFFFD54A),
    Color(0xFFFF8A65),
    Color(0xFF5FE1FF),
    Color(0xFFB9F6CA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 24; i++) {
      final r = math.Random(i);
      final x = r.nextDouble() * size.width;
      final speed = 0.6 + r.nextDouble() * 0.6;
      final y =
          ((anim.value * speed + r.nextDouble()) % 1.0) * (size.height + 40) -
          20;
      final s = 5 + r.nextDouble() * 7;
      paint.color = _colors[i % _colors.length].withValues(alpha: 0.85);
      final path = Path();
      for (var k = 0; k < 10; k++) {
        final rr = k.isEven ? s : s * 0.45;
        final a = -math.pi / 2 + k * math.pi / 5 + anim.value * math.pi * 2;
        final p = Offset(x + math.cos(a) * rr, y + math.sin(a) * rr);
        k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path..close(), paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => false;
}
