import '../combat/match_controller.dart';

/// Snapshot of what the Flutter HUD needs to draw, published by the game.
class HudState {
  const HudState({
    required this.playerHealth,
    required this.opponentHealth,
    required this.timeLeft,
    required this.phase,
    required this.phaseTime,
    this.outcome,
  });

  final double playerHealth;
  final double opponentHealth;
  final int timeLeft;
  final MatchPhase phase;
  final double phaseTime;
  final MatchOutcome? outcome;

  /// Only rebuild the HUD when something visible changed.
  bool sameAs(HudState o) =>
      (playerHealth - o.playerHealth).abs() < 0.01 &&
      (opponentHealth - o.opponentHealth).abs() < 0.01 &&
      timeLeft == o.timeLeft &&
      phase == o.phase &&
      outcome == o.outcome &&
      _banner(phaseTime) == _banner(o.phaseTime);

  static int _banner(double t) => (t * 4).floor();
}
