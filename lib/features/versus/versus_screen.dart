import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/battle_setup.dart';
import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/comic_text.dart';
import '../../shared/widgets/hero_preview.dart';
import '../../shared/widgets/menu_background.dart';

/// "HERO VS HERO" introduction. Advances on its own, or on tap.
class VersusScreen extends ConsumerStatefulWidget {
  const VersusScreen({super.key});

  static const Duration showFor = Duration(milliseconds: 2600);

  @override
  ConsumerState<VersusScreen> createState() => _VersusScreenState();
}

class _VersusScreenState extends ConsumerState<VersusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  Timer? _timer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(VersusScreen.showFor, _go);
  }

  void _go() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacementNamed(Routes.battle);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(battleSetupProvider);
    final slide = CurvedAnimation(parent: _intro, curve: Curves.easeOutBack);
    final pop = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 1, curve: Curves.elasticOut),
    );

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _go,
        child: MenuBackground(
          child: Row(
            children: [
              Expanded(
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(slide),
                  child: _Side(
                    name: setup.player.name,
                    color: AppColors.playerAccent,
                    child: HeroPreview(hero: setup.player),
                  ),
                ),
              ),
              ScaleTransition(
                scale: pop,
                child: const ComicText('VS', size: 72),
              ),
              Expanded(
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(slide),
                  child: _Side(
                    name: setup.opponent.name,
                    color: AppColors.opponentAccent,
                    child: HeroPreview(hero: setup.opponent, facing: -1),
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

class _Side extends StatelessWidget {
  const _Side({required this.name, required this.color, required this.child});

  final String name;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Expanded(child: child),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: ComicText(
              name.toUpperCase(),
              size: 34,
              color: color,
              outline: 6,
            ),
          ),
        ],
      ),
    );
  }
}
