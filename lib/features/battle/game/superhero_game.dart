import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../../../core/constants/game_constants.dart';
import '../ai/ai_controller.dart';
import '../ai/ai_difficulty.dart';
import '../arenas/neon_rooftop_arena.dart';
import '../characters/hero_definition.dart';
import '../combat/combat_resolver.dart';
import '../combat/match_controller.dart';
import '../components/fighter_component.dart';
import '../controls/control_input.dart';
import '../effects/hit_effects.dart';
import 'hud_state.dart';

/// The Flame game that hosts one battle.
///
/// Game rules live in [MatchController]; this class wires them to the
/// screen: camera, arena, fighter drawing, effects and input.
class SuperheroGame extends FlameGame with KeyboardEvents {
  SuperheroGame({
    required this.playerHero,
    required this.opponentHero,
    required this.input,
    this.difficulty = AiDifficulty.easy,
    this.onMatchEnd,
    this.random,
  });

  final HeroDefinition playerHero;
  final HeroDefinition opponentHero;
  final ControlInput input;
  final AiDifficulty difficulty;

  /// Optional seeded random source for deterministic AI in tests.
  final math.Random? random;

  /// Called once, after the knockout outro has finished.
  final void Function(MatchOutcome outcome)? onMatchEnd;

  late MatchController match;
  late AiController ai;
  final ValueNotifier<HudState?> hud = ValueNotifier(null);
  bool _ended = false;
  bool _koEffectsShown = false;

  @override
  Color backgroundColor() => const Color(0xFF1B1238);

  @override
  Future<void> onLoad() async {
    match = MatchController(playerHero: playerHero, opponentHero: opponentHero);
    ai = AiController(difficulty: difficulty, random: random);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(
      GameConstants.worldWidth / 2,
      GameConstants.worldHeight / 2,
    );
    _fitCamera(size);

    world.add(NeonRooftopArena(focusX: () => (match.player.x + match.opponent.x) / 2));
    world.add(FighterComponent(match.opponent));
    world.add(FighterComponent(match.player));
    // The HUD is first published from update(), never during the widget
    // build in which the game loads.
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _fitCamera(size);
  }

  /// Fits the 1280x720 battle area on any screen; extra space shows more of
  /// the sky and skyline instead of black bars.
  void _fitCamera(Vector2 size) {
    if (size.x <= 0 || size.y <= 0) return;
    camera.viewfinder.zoom = math.min(
      size.x / GameConstants.worldWidth,
      size.y / GameConstants.worldHeight,
    );
  }

  @override
  void update(double dt) {
    // Clamp long frames (e.g. after resume) so physics stays stable.
    final step = math.min(dt, 1 / 30);
    super.update(step);
    if (!isLoaded) return;

    final aiInput = ai.think(step, match.opponent, match.player);
    final events = match.update(step, input.consume(step), aiInput);
    for (final e in events) {
      _spawnHitEffect(e);
    }

    if (match.phase == MatchPhase.finished && !_koEffectsShown) {
      _koEffectsShown = true;
      for (final f in [match.player, match.opponent]) {
        if (f.isKnockedOut) {
          world.add(SmokePuffs(
            at: Vector2(f.x, GameConstants.groundY - 10),
            count: 8,
            spread: 90,
          ));
        }
      }
    }

    _publishHud();

    if (match.readyForResults && !_ended) {
      _ended = true;
      onMatchEnd?.call(match.outcome!);
    }
  }

  void _spawnHitEffect(HitEvent e) {
    final at = Vector2(e.point.dx, e.point.dy);
    if (e.blocked) {
      world.add(BlockRipple(at: at));
    } else {
      world.add(HitBurst(at: at, big: e.knockout || e.damage >= 9));
    }
  }

  void _publishHud() {
    final next = HudState(
      playerHealth: match.player.healthFraction,
      opponentHealth: match.opponent.healthFraction,
      timeLeft: match.timeLeft.ceil(),
      phase: match.phase,
      phaseTime: match.phaseTime,
      outcome: match.outcome,
    );
    final current = hud.value;
    if (current == null || !current.sameAs(next)) hud.value = next;
  }

  /// Keyboard support for emulators and Chromebooks:
  /// arrows or A/D to move, W/Up/Space to jump, J punch, K kick, L block.
  static final Map<LogicalKeyboardKey, ControlButton> keyMap = {
    LogicalKeyboardKey.arrowLeft: ControlButton.left,
    LogicalKeyboardKey.keyA: ControlButton.left,
    LogicalKeyboardKey.arrowRight: ControlButton.right,
    LogicalKeyboardKey.keyD: ControlButton.right,
    LogicalKeyboardKey.arrowUp: ControlButton.jump,
    LogicalKeyboardKey.keyW: ControlButton.jump,
    LogicalKeyboardKey.space: ControlButton.jump,
    LogicalKeyboardKey.keyJ: ControlButton.punch,
    LogicalKeyboardKey.keyK: ControlButton.kick,
    LogicalKeyboardKey.keyL: ControlButton.block,
  };

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final button = keyMap[event.logicalKey];
    if (button == null) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      input.press(button);
    } else if (event is KeyUpEvent) {
      input.release(button);
    }
    return KeyEventResult.handled;
  }
}
