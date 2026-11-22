import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/arcade_button.dart';
import '../../shared/widgets/comic_text.dart';
import '../../shared/widgets/hero_preview.dart';
import '../../shared/widgets/menu_background.dart';
import '../../shared/widgets/sound_toggle.dart';
import '../battle/characters/hero_roster.dart';
import '../battle/combat/fighter_state.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MenuBackground(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FittedBox(
                          child: ComicText('SUPERHERO\nSHOWDOWN', size: 56),
                        ),
                        const SizedBox(height: 24),
                        ArcadeButton(
                          label: AppStrings.startGame,
                          icon: Icons.play_arrow_rounded,
                          width: 280,
                          onPressed: () =>
                              Navigator.of(context).pushNamed(Routes.select),
                        ),
                        const SizedBox(height: 16),
                        ArcadeButton(
                          label: AppStrings.howToPlay,
                          icon: Icons.help_outline_rounded,
                          color: AppColors.playerAccent,
                          width: 280,
                          fontSize: 20,
                          onPressed: () => _showHowToPlay(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: [
                        const Expanded(
                          child: HeroPreview(hero: HeroRoster.spiderShadow),
                        ),
                        const Expanded(
                          child: HeroPreview(
                            hero: HeroRoster.solarMan,
                            state: FighterState.victory,
                          ),
                        ),
                        const Expanded(
                          child: HeroPreview(
                            hero: HeroRoster.thunderGiant,
                            facing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(top: 4, right: 8, child: SoundToggle()),
          ],
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.ink, width: 4),
        ),
        title: const Text(
          AppStrings.howToPlay,
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final step in AppStrings.howToPlaySteps)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFE0A800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          ArcadeButton(
            label: AppStrings.close,
            fontSize: 18,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
