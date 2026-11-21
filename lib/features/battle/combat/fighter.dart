import 'dart:math' as math;
import 'dart:ui';

import '../../../core/constants/game_constants.dart';
import '../characters/hero_definition.dart';
import 'attack_data.dart';
import 'fighter_input.dart';
import 'fighter_state.dart';

/// Simulation model of one fighter: physics, state machine, health and
/// attacks. Contains no rendering code, so it can be unit tested directly.
class Fighter {
  Fighter({
    required this.hero,
    required this.x,
    required this.facing,
    this.isPlayer = false,
  }) : y = GameConstants.groundY;

  final HeroDefinition hero;
  final bool isPlayer;

  /// Position of the feet, in world units.
  double x;
  double y;
  double vx = 0;
  double vy = 0;

  /// 1 when facing right, -1 when facing left.
  int facing;

  double health = GameConstants.maxHealth;
  double energy = 0;

  /// Seconds left stuck in a web (purely visual, matches the hit stun).
  double webbed = 0;
  bool _specialReleased = false;
  bool _projectileRequested = false;
  double invulnerable = 0;
  double attackCooldown = 0;
  double hitStun = 0;
  double blockFlash = 0;

  final FighterStateMachine _sm = FighterStateMachine();
  AttackData? _attack;
  bool _attackHasHit = false;
  int _attackSerial = 0;

  /// Total animation clock, used for idle bobbing and walk cycles.
  double animTime = 0;

  FighterState get state => _sm.state;
  double get stateTime => _sm.timeInState;
  AttackData? get currentAttack => _attack;

  /// Increases every time a new attack starts. Useful for effects.
  int get attackSerial => _attackSerial;

  bool get onGround => y >= GameConstants.groundY - 0.01;
  bool get isKnockedOut => state == FighterState.knockout;
  bool get energyFull => energy >= GameConstants.maxEnergy;
  double get energyFraction => (energy / GameConstants.maxEnergy).clamp(0, 1);

  /// While charging a superpower the hero cannot be interrupted, so the big
  /// move always comes out. This makes powers feel reliable for kids.
  bool get superArmor =>
      state == FighterState.special && stateTime < SpecialPower.chargeTime;

  void addEnergy(double amount) {
    energy = math.min(GameConstants.maxEnergy, energy + amount);
  }

  /// Returns true once, when a superpower that fires something is released.
  bool takeProjectileRequest() {
    final r = _projectileRequested;
    _projectileRequested = false;
    return r;
  }

  double get healthFraction => (health / GameConstants.maxHealth).clamp(0, 1);

  /// 0..1 progress of the current attack, or 0 when not attacking.
  double get attackProgress =>
      _attack == null ? 0 : _attack!.progress(stateTime);

  /// Body area that can be hit.
  Rect get hurtbox => Rect.fromLTRB(
    x - GameConstants.fighterHalfWidth,
    y - GameConstants.fighterHeight,
    x + GameConstants.fighterHalfWidth,
    y,
  );

  /// The live attack area, or null when no attack can currently connect.
  ///
  /// Once an attack has connected it reports no hitbox for the rest of the
  /// swing, so one attack can never damage every frame.
  Rect? get activeHitbox {
    final attack = _attack;
    if (attack == null || _attackHasHit || !state.isAttacking) return null;
    if (state == FighterState.special &&
        hero.special.kind != SpecialKind.dash) {
      return null;
    }
    if (!attack.isActiveAt(stateTime)) return null;
    final near = x + facing * GameConstants.fighterHalfWidth * 0.5;
    final far = x + facing * (GameConstants.fighterHalfWidth + attack.reach);
    return Rect.fromLTRB(
      math.min(near, far),
      y - attack.hitboxTop,
      math.max(near, far),
      y - attack.hitboxBottom,
    );
  }

  /// Marks the current attack as having connected.
  void registerHit() => _attackHasHit = true;

  bool get isBlockingToward => state == FighterState.blocking;

  /// Applies one simulation step.
  void update(double dt, FighterInput input) {
    animTime += dt;
    _sm.tick(dt);
    invulnerable = math.max(0, invulnerable - dt);
    attackCooldown = math.max(0, attackCooldown - dt);
    blockFlash = math.max(0, blockFlash - dt);
    webbed = math.max(0, webbed - dt);
    if (!state.isFinal) addEnergy(GameConstants.energyPerSecond * dt);

    switch (state) {
      case FighterState.knockout:
      case FighterState.victory:
        _applyFriction(dt);
      case FighterState.hit:
        hitStun -= dt;
        _applyFriction(dt);
        if (hitStun <= 0) {
          _sm.transition(onGround ? FighterState.idle : FighterState.falling);
        }
      case FighterState.special:
        _updateSpecial(dt);
      case FighterState.punching:
      case FighterState.kicking:
        if (onGround) _applyFriction(dt);
        if (stateTime >= _attack!.total) {
          attackCooldown = _attack!.cooldown;
          _attack = null;
          _sm.transition(onGround ? FighterState.idle : FighterState.falling);
        }
      case FighterState.idle:
      case FighterState.walking:
      case FighterState.jumping:
      case FighterState.falling:
      case FighterState.blocking:
        _handleInput(input);
    }

    _integrate(dt);
  }

  void _handleInput(FighterInput input) {
    final canAttack = attackCooldown <= 0;

    if (onGround && input.block) {
      _sm.transition(FighterState.blocking);
      vx = 0;
      return;
    }
    if (state == FighterState.blocking) {
      _sm.transition(FighterState.idle);
    }

    if (input.special && energyFull && onGround) {
      _startSpecial();
      return;
    }

    if (canAttack && (input.punch || input.kick)) {
      _startAttack(
        input.kick && !input.punch ? AttackType.kick : AttackType.punch,
      );
      return;
    }

    if (onGround && input.jump) {
      vy = GameConstants.jumpVelocity * hero.jumpPower;
      _sm.transition(FighterState.jumping);
    }

    final dir = input.horizontal;
    if (onGround && !state.isAirborneState) {
      vx = dir * hero.walkSpeed;
      _sm.transition(dir == 0 ? FighterState.idle : FighterState.walking);
    } else {
      // Gentle air steering so jumps feel controllable for young players.
      final target = dir * hero.walkSpeed * GameConstants.airControl;
      vx += (target - vx) * 0.12;
    }
  }

  void _startAttack(AttackType type) {
    final target = type == AttackType.punch
        ? FighterState.punching
        : FighterState.kicking;
    if (!_sm.transition(target)) return;
    _attack = hero.attack(type);
    _attackHasHit = false;
    _attackSerial++;
    if (onGround) vx = 0;
  }

  void _startSpecial() {
    if (!_sm.transition(FighterState.special)) return;
    energy = 0;
    _attack = hero.special.attackData;
    _attackHasHit = false;
    _specialReleased = false;
    _attackSerial++;
    vx = 0;
  }

  void _updateSpecial(double dt) {
    final power = hero.special;
    final t = stateTime;
    if (!_specialReleased && t >= SpecialPower.chargeTime) {
      _specialReleased = true;
      if (power.kind != SpecialKind.dash) _projectileRequested = true;
    }
    final dashing =
        power.kind == SpecialKind.dash &&
        t >= SpecialPower.chargeTime &&
        t < SpecialPower.chargeTime + SpecialPower.dashTime;
    if (dashing) {
      vx = facing * power.speed;
    } else {
      _applyFriction(dt * 2);
    }
    if (t >= power.totalTime) {
      attackCooldown = 0.15;
      _attack = null;
      _sm.transition(FighterState.idle);
    }
  }

  void _applyFriction(double dt) {
    if (!onGround) return;
    vx *= math.max(0, 1 - GameConstants.groundFriction * dt);
    if (vx.abs() < 4) vx = 0;
  }

  void _integrate(double dt) {
    if (!onGround || vy < 0) {
      vy += GameConstants.gravity * dt;
    }
    x += vx * dt;
    y += vy * dt;

    if (y >= GameConstants.groundY) {
      final wasAirborne = vy > 0;
      y = GameConstants.groundY;
      vy = 0;
      if (wasAirborne && state.isAirborneState) {
        _sm.transition(FighterState.idle);
      }
    } else if (vy > 0 && state == FighterState.jumping) {
      _sm.transition(FighterState.falling);
    }

    x = x.clamp(GameConstants.arenaLeft, GameConstants.arenaRight);
  }

  /// Turns to face [other] when free to do so.
  void faceToward(Fighter other) {
    if (!state.acceptsInput || state.isAirborneState) return;
    if ((other.x - x).abs() < 4) return;
    facing = other.x > x ? 1 : -1;
  }

  /// Applies a clean hit. Returns the damage dealt.
  double receiveHit(AttackData attack, int fromDirection) {
    health = math.max(0, health - attack.damage);
    invulnerable = GameConstants.hitInvulnerability;
    _attack = null;
    if (health <= 0) {
      _sm.transition(FighterState.knockout);
      vx = fromDirection * attack.knockback * 1.4;
      vy = -520;
      return attack.damage;
    }
    hitStun = attack.hitStun;
    vx = fromDirection * attack.knockback;
    if (!onGround) vy = math.min(vy, -180);
    _sm.transition(FighterState.hit);
    return attack.damage;
  }

  /// Applies a blocked hit. Returns the chip damage dealt.
  double receiveBlockedHit(AttackData attack, int fromDirection) {
    final chip = attack.damage * GameConstants.blockDamageFactor;
    health = math.max(1, health - chip);
    invulnerable = GameConstants.hitInvulnerability * 0.5;
    vx = fromDirection * attack.knockback * 0.45;
    blockFlash = 0.2;
    return chip;
  }

  void celebrate() {
    _attack = null;
    _sm.transition(FighterState.victory);
  }
}
