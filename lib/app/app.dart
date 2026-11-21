import 'package:material_ui/material_ui.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../features/battle/battle_screen.dart';
import '../features/battle/combat/match_controller.dart';
import '../features/character_selection/character_select_screen.dart';
import '../features/home/main_menu_screen.dart';
import '../features/result/result_screen.dart';
import '../features/versus/versus_screen.dart';
import 'routes.dart';

class SuperheroShowdownApp extends StatelessWidget {
  const SuperheroShowdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.violet,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.night,
        useMaterial3: true,
      ),
      initialRoute: Routes.menu,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  static Route<void> _onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      Routes.select => const CharacterSelectScreen(),
      Routes.versus => const VersusScreen(),
      Routes.battle => const BattleScreen(),
      Routes.result => ResultScreen(
        outcome: settings.arguments as MatchOutcome? ?? MatchOutcome.draw,
      ),
      _ => const MainMenuScreen(),
    };
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}
