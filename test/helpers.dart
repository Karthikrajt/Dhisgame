import 'package:superhero_showdown/core/constants/game_constants.dart';
import 'package:superhero_showdown/features/battle/characters/hero_roster.dart';
import 'package:superhero_showdown/features/battle/combat/fighter.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_input.dart';

const double frame = 1 / 60;

Fighter makeFighter({double x = 500, int facing = 1}) =>
    Fighter(hero: HeroRoster.spiderShadow, x: x, facing: facing);

/// Steps [f] for [seconds] with a constant [input].
void run(Fighter f, double seconds, [FighterInput input = FighterInput.none]) {
  final steps = (seconds / frame).round();
  for (var i = 0; i < steps; i++) {
    f.update(frame, input);
  }
}

double get ground => GameConstants.groundY;
