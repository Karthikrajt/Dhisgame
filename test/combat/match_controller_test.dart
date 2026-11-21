import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/core/constants/game_constants.dart';
import 'package:superhero_showdown/features/battle/ai/ai_controller.dart';
import 'package:superhero_showdown/features/battle/ai/ai_difficulty.dart';
import 'package:superhero_showdown/features/battle/characters/hero_roster.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_input.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_state.dart';
import 'package:superhero_showdown/features/battle/combat/match_controller.dart';

import '../helpers.dart';

MatchController newMatch() => MatchController(
  playerHero: HeroRoster.spiderShadow,
  opponentHero: HeroRoster.darkKnight,
);

void main() {
  test('input is ignored during the intro', () {
    final m = newMatch();
    final x = m.player.x;
    m.update(frame, const FighterInput(right: true), FighterInput.none);
    expect(m.phase, MatchPhase.intro);
    expect(m.player.x, x);
  });

  test('fighting starts after the intro', () {
    final m = newMatch();
    for (var t = 0.0; t < GameConstants.introSeconds + 0.1; t += frame) {
      m.update(frame, FighterInput.none, FighterInput.none);
    }
    expect(m.phase, MatchPhase.fighting);
  });

  test('knocking out the opponent wins the match', () {
    final m = newMatch();
    m.phase = MatchPhase.fighting;
    m.opponent.health = 1;
    m.opponent.x = m.player.x + 100;
    for (var i = 0; i < 60 && m.phase == MatchPhase.fighting; i++) {
      m.update(frame, const FighterInput(punch: true), FighterInput.none);
    }
    expect(m.outcome, MatchOutcome.playerWins);
    expect(m.opponent.state, FighterState.knockout);
    expect(m.player.state, FighterState.victory);
    for (var t = 0.0; t < GameConstants.outroSeconds + 0.1; t += frame) {
      m.update(frame, FighterInput.none, FighterInput.none);
    }
    expect(m.readyForResults, isTrue);
  });

  test('time out decides by remaining health', () {
    final m = newMatch();
    m.phase = MatchPhase.fighting;
    m.timeLeft = 0.05;
    m.player.health = 40;
    for (var i = 0; i < 10; i++) {
      m.update(frame, FighterInput.none, FighterInput.none);
    }
    expect(m.outcome, MatchOutcome.opponentWins);
  });

  test('a button-mashing player can beat the Easy AI', () {
    for (final seed in [1, 2, 3, 4, 5]) {
      final m = newMatch();
      final ai = AiController(random: math.Random(seed));
      var t = 0.0;
      while (t < 90 && m.outcome == null) {
        m.update(
          frame,
          mashScript(m, t),
          ai.think(frame, m.opponent, m.player),
        );
        t += frame;
      }
      expect(m.outcome, MatchOutcome.playerWins, reason: 'seed $seed');
    }
  });

  test('a full AI vs AI match finishes with a result', () {
    final m = newMatch();
    final a = AiController(
      difficulty: AiDifficulty.hard,
      random: math.Random(10),
    );
    final b = AiController(
      difficulty: AiDifficulty.hard,
      random: math.Random(11),
    );
    var hits = 0;
    for (var t = 0.0; t < 120 && !m.readyForResults; t += frame) {
      hits += m
          .update(
            frame,
            a.think(frame, m.player, m.opponent),
            b.think(frame, m.opponent, m.player),
          )
          .length;
    }
    expect(hits, greaterThan(5));
    expect(m.outcome, isNotNull);
    expect(m.readyForResults, isTrue);
  });
}

/// A simple scripted "child" player: walk in and mash punch and kick.
FighterInput mashScript(MatchController m, double t) {
  final dx = m.opponent.x - m.player.x;
  if (dx.abs() > 150) return FighterInput(right: dx > 0, left: dx < 0);
  final kick = (t * 2).floor().isOdd;
  return FighterInput(punch: !kick, kick: kick);
}
