import 'dart:math' as math;

import '../../../core/constants/game_constants.dart';
import '../characters/hero_definition.dart';
import 'combat_resolver.dart';
import 'fighter.dart';
import 'fighter_input.dart';

enum MatchPhase { intro, fighting, finished }

enum MatchOutcome { playerWins, opponentWins, draw }

/// Runs one round between the player and the computer: timer, hits,
/// knockouts and the final result. Pure Dart, independent of Flame.
class MatchController {
  MatchController({
    required HeroDefinition playerHero,
    required HeroDefinition opponentHero,
  }) : player = Fighter(
         hero: playerHero,
         x: GameConstants.worldWidth * 0.3,
         facing: 1,
         isPlayer: true,
       ),
       opponent = Fighter(
         hero: opponentHero,
         x: GameConstants.worldWidth * 0.7,
         facing: -1,
       );

  final Fighter player;
  final Fighter opponent;

  MatchPhase phase = MatchPhase.intro;
  MatchOutcome? outcome;
  double phaseTime = 0;
  double timeLeft = GameConstants.roundSeconds;

  /// True once the outro has played and the result screen should show.
  bool get readyForResults =>
      phase == MatchPhase.finished && phaseTime >= GameConstants.outroSeconds;

  /// Advances the match and returns any hits that landed this step.
  List<HitEvent> update(
    double dt,
    FighterInput playerInput,
    FighterInput opponentInput,
  ) {
    phaseTime += dt;
    final events = <HitEvent>[];

    final controlsLive = phase == MatchPhase.fighting;
    player.faceToward(opponent);
    opponent.faceToward(player);
    player.update(dt, controlsLive ? playerInput : FighterInput.none);
    opponent.update(dt, controlsLive ? opponentInput : FighterInput.none);

    if (phase == MatchPhase.intro) {
      if (phaseTime >= GameConstants.introSeconds) {
        _setPhase(MatchPhase.fighting);
      }
      return events;
    }

    if (phase == MatchPhase.fighting) {
      final a = CombatResolver.resolve(player, opponent);
      final b = CombatResolver.resolve(opponent, player);
      if (a != null) events.add(a);
      if (b != null) events.add(b);

      timeLeft = math.max(0, timeLeft - dt);
      _checkForEnd();
    }

    CombatResolver.separate(player, opponent);
    return events;
  }

  void _checkForEnd() {
    if (opponent.isKnockedOut) {
      _finish(MatchOutcome.playerWins);
    } else if (player.isKnockedOut) {
      _finish(MatchOutcome.opponentWins);
    } else if (timeLeft <= 0) {
      if ((player.health - opponent.health).abs() < 0.5) {
        _finish(MatchOutcome.draw);
      } else {
        _finish(
          player.health > opponent.health
              ? MatchOutcome.playerWins
              : MatchOutcome.opponentWins,
        );
      }
    }
  }

  void _finish(MatchOutcome result) {
    outcome = result;
    _setPhase(MatchPhase.finished);
    switch (result) {
      case MatchOutcome.playerWins:
        player.celebrate();
      case MatchOutcome.opponentWins:
        opponent.celebrate();
      case MatchOutcome.draw:
        break;
    }
  }

  void _setPhase(MatchPhase next) {
    phase = next;
    phaseTime = 0;
  }
}
