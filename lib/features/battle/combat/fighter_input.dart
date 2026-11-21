/// One frame of commands for a fighter, from touch controls or the AI.
class FighterInput {
  const FighterInput({
    this.left = false,
    this.right = false,
    this.jump = false,
    this.punch = false,
    this.kick = false,
    this.block = false,
    this.special = false,
  });

  final bool left;
  final bool right;
  final bool jump;
  final bool punch;
  final bool kick;
  final bool block;

  /// Fire the hero's superpower (only works with a full energy meter).
  final bool special;

  static const FighterInput none = FighterInput();

  /// -1 for left, 1 for right, 0 when both or neither are held.
  int get horizontal => (right ? 1 : 0) - (left ? 1 : 0);

  @override
  String toString() =>
      'FighterInput(l:$left r:$right j:$jump p:$punch k:$kick b:$block '
      's:$special)';
}
