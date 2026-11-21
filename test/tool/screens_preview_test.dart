@Tags(['preview'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:superhero_showdown/app/app.dart';
import 'package:superhero_showdown/core/constants/app_strings.dart';
import 'package:superhero_showdown/features/battle/combat/match_controller.dart';
import 'package:superhero_showdown/features/result/result_screen.dart';

/// Captures screenshots of each screen into build/preview/.
/// Run with: flutter test --tags preview
void main() {
  const fontDir = String.fromEnvironment('FONT_DIR');
  final key = GlobalKey();

  Future<void> loadFonts() async {
    final dir = fontDir.isNotEmpty
        ? fontDir
        : '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter'}/bin/cache/artifacts/material_fonts';
    final roboto = FontLoader('Roboto');
    for (final f in [
      'Roboto-Regular.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Black.ttf',
    ]) {
      final file = File('$dir/$f');
      if (file.existsSync()) {
        roboto.addFont(
          Future.value(ByteData.sublistView(file.readAsBytesSync())),
        );
      }
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons');
    final iconFile = File('$dir/MaterialIcons-Regular.otf');
    if (iconFile.existsSync()) {
      icons.addFont(
        Future.value(ByteData.sublistView(iconFile.readAsBytesSync())),
      );
      await icons.load();
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/preview').createSync(recursive: true);
      File('build/preview/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> pumpFor(WidgetTester tester, double seconds) async {
    for (var t = 0.0; t < seconds; t += 1 / 30) {
      await tester.pump(const Duration(microseconds: 33333));
    }
  }

  testWidgets('screens', (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = const Size(1600, 720);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const ProviderScope(child: SuperheroShowdownApp()),
      ),
    );
    await pumpFor(tester, 0.5);
    await shot(tester, 'menu');

    await tester.tap(find.text(AppStrings.startGame));
    await pumpFor(tester, 0.6);

    await tester.tap(find.byKey(const ValueKey('player_solar_man')));
    await pumpFor(tester, 0.4);
    await shot(tester, 'select');
    await tester.tap(find.byKey(const ValueKey('next_step')));
    await pumpFor(tester, 0.3);
    await tester.tap(find.byKey(const ValueKey('opponent_thunder_giant')));
    await pumpFor(tester, 0.4);
    await shot(tester, 'select_opponent');
    await tester.tap(find.byKey(const ValueKey('start_battle')));
    await pumpFor(tester, 1.2);
    await shot(tester, 'versus');

    await pumpFor(tester, 2.0);
    await pumpFor(tester, 0.6);
    await shot(tester, 'battle_intro');
    await pumpFor(tester, 5);
    await shot(tester, 'battle_1');
    await pumpFor(tester, 2.3);
    await shot(tester, 'battle_2');
  });

  testWidgets('result', (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = const Size(1600, 720);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: ResultScreen(outcome: MatchOutcome.playerWins),
          ),
        ),
      ),
    );
    await pumpFor(tester, 1);
    await shot(tester, 'victory');
  });
}
