/// Every state a fighter can be in.
enum FighterState {
  idle,
  walking,
  jumping,
  falling,
  punching,
  kicking,
  special,
  blocking,
  hit,
  knockout,
  victory;

  bool get isAttacking =>
      this == punching || this == kicking || this == special;
  bool get isAirborneState => this == jumping || this == falling;
  bool get isFinal => this == knockout || this == victory;

  /// States in which the fighter reads new movement or attack input.
  bool get acceptsInput =>
      this == idle ||
      this == walking ||
      this == jumping ||
      this == falling ||
      this == blocking;
}

/// Guards fighter state changes so only legal transitions can happen.
///
/// For example a knocked-out fighter can never start punching, and a fighter
/// cannot block in mid-air.
class FighterStateMachine {
  FighterStateMachine([this._state = FighterState.idle]);

  FighterState _state;
  double _timeInState = 0;

  FighterState get state => _state;

  /// Seconds spent in the current state.
  double get timeInState => _timeInState;

  static const Map<FighterState, Set<FighterState>> _allowed = {
    FighterState.idle: {
      FighterState.special,
      FighterState.walking,
      FighterState.jumping,
      FighterState.falling,
      FighterState.punching,
      FighterState.kicking,
      FighterState.blocking,
      FighterState.hit,
      FighterState.knockout,
      FighterState.victory,
    },
    FighterState.walking: {
      FighterState.special,
      FighterState.idle,
      FighterState.jumping,
      FighterState.falling,
      FighterState.punching,
      FighterState.kicking,
      FighterState.blocking,
      FighterState.hit,
      FighterState.knockout,
      FighterState.victory,
    },
    FighterState.jumping: {
      FighterState.falling,
      FighterState.idle,
      FighterState.punching,
      FighterState.kicking,
      FighterState.hit,
      FighterState.knockout,
      FighterState.victory,
    },
    FighterState.falling: {
      FighterState.idle,
      FighterState.walking,
      FighterState.punching,
      FighterState.kicking,
      FighterState.hit,
      FighterState.knockout,
      FighterState.victory,
    },
    FighterState.punching: {
      FighterState.idle,
      FighterState.falling,
      FighterState.hit,
      FighterState.knockout,
      FighterState.victory,
    },
    FighterState.kicking: {
      FighterState.idle,
      FighterState.falling,
      FighterState.hit,
      FighterState.knockout,
      FighterState.victory,
    },
    FighterState.blocking: {
      FighterState.special,
      FighterState.idle,
      FighterState.walking,
      FighterState.jumping,
      FighterState.punching,
      FighterState.kicking,
      FighterState.hit,
      FighterState.knockout,
      FighterState.victory,
    },
    FighterState.special: {
      FighterState.idle,
      FighterState.hit,
      FighterState.knockout,
      FighterState.victory,
    },
    FighterState.hit: {
      FighterState.idle,
      FighterState.falling,
      FighterState.hit,
      FighterState.knockout,
      FighterState.victory,
    },
    FighterState.knockout: {},
    FighterState.victory: {},
  };

  bool canTransition(FighterState to) => _allowed[_state]!.contains(to);

  /// Moves to [to] if the transition is legal. Returns whether it happened.
  bool transition(FighterState to) {
    if (to == _state && to != FighterState.hit) return true;
    if (!canTransition(to)) return false;
    _state = to;
    _timeInState = 0;
    return true;
  }

  void tick(double dt) => _timeInState += dt;
}
