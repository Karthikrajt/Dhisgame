import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:superhero_showdown/app/app.dart';
import 'package:superhero_showdown/app/battle_setup.dart';
import 'package:superhero_showdown/core/constants/app_strings.dart';
import 'package:superhero_showdown/features/battle/battle_screen.dart';
import 'package:superhero_showdown/features/battle/characters/hero_roster.dart';
import 'package:superhero_showdown/features/battle/combat/match_controller.dart';
import 'package:superhero_showdown/features/character_selection/character_select_screen.dart';
import 'package:superhero_showdown/features/result/result_screen.dart';
import 'package:superhero_showdown/features/versus/versus_screen.dart';

Future<void> pumpFor(WidgetTester tester, Duration d) async {
  const step = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < d; t += step) {
    await tester.pump(step);
  }
}

void main() {
  setUp(() {
    // Landscape phone, 2400x1080 at 2.6x.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> setLandscape(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
  }

  testWidgets('menu -> select -> versus -> battle', (tester) async {
    await setLandscape(tester);
    await tester.pumpWidget(const ProviderScope(child: SuperheroShowdownApp()));
    await tester.pump();

    expect(find.text(AppStrings.startGame), findsOneWidget);
    await tester.tap(find.text(AppStrings.startGame));
    await pumpFor(tester, const Duration(milliseconds: 400));
    expect(find.byType(CharacterSelectScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('start_battle')));
    await pumpFor(tester, const Duration(milliseconds: 400));
    expect(find.byType(VersusScreen), findsOneWidget);

    await pumpFor(tester, VersusScreen.showFor + const Duration(milliseconds: 500));
    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.text(AppStrings.punch.toUpperCase()), findsOneWidget);
    expect(find.text(AppStrings.kick.toUpperCase()), findsOneWidget);

    // Pause menu works.
    await tester.tap(find.byKey(const ValueKey('pause_button')));
    await tester.pump();
    expect(find.text(AppStrings.resume), findsOneWidget);
    await tester.tap(find.text(AppStrings.resume));
    await tester.pump();
    expect(find.text(AppStrings.resume), findsNothing);
  });

  testWidgets('choosing the opponent\'s hero as your own swaps the opponent',
      (tester) async {
    await setLandscape(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CharacterSelectScreen()),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('player_dark_knight')));
    await tester.pump();
    final setup = container.read(battleSetupProvider);
    expect(setup.player, HeroRoster.darkKnight);
    expect(setup.opponent, HeroRoster.spiderShadow);
  });

  for (final outcome in MatchOutcome.values) {
    testWidgets('result screen for $outcome has working buttons',
        (tester) async {
      await setLandscape(tester);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(home: ResultScreen(outcome: outcome)),
      ));
      await tester.pump();
      final expected = switch (outcome) {
        MatchOutcome.playerWins => AppStrings.victory,
        MatchOutcome.opponentWins => AppStrings.defeat,
        MatchOutcome.draw => AppStrings.draw,
      };
      expect(find.text(expected), findsWidgets);
      expect(find.text(AppStrings.tryAgain), findsOneWidget);
      expect(find.text(AppStrings.changeHeroes), findsOneWidget);
      expect(find.text(AppStrings.mainMenu), findsOneWidget);
    });
  }
}
