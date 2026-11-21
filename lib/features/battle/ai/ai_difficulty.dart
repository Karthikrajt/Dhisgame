/// Tuning for the computer opponent. Easy is the default for young players.
enum AiDifficulty {
  easy(
    label: 'Easy',
    reactionTime: 0.75,
    attackChance: 0.38,
    blockChance: 0.15,
    jumpChance: 0.04,
    attackPause: 0.9,
  ),
  normal(
    label: 'Normal',
    reactionTime: 0.45,
    attackChance: 0.6,
    blockChance: 0.35,
    jumpChance: 0.07,
    attackPause: 0.45,
  ),
  hard(
    label: 'Hard',
    reactionTime: 0.25,
    attackChance: 0.8,
    blockChance: 0.55,
    jumpChance: 0.09,
    attackPause: 0.2,
  );

  const AiDifficulty({
    required this.label,
    required this.reactionTime,
    required this.attackChance,
    required this.blockChance,
    required this.jumpChance,
    required this.attackPause,
  });

  final String label;

  /// Seconds between decisions. Longer means more time for the player.
  final double reactionTime;

  /// Chance to attack when in range at a decision point.
  final double attackChance;

  /// Chance to block when the player is attacking nearby.
  final double blockChance;

  /// Chance to hop at a decision point.
  final double jumpChance;

  /// Minimum rest between AI attacks.
  final double attackPause;
}
