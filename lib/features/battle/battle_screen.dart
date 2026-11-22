import 'package:flame/game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/battle_setup.dart';
import '../../core/audio/game_audio.dart';
import '../../app/routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/arcade_button.dart';
import '../../shared/widgets/comic_text.dart';
import '../../shared/widgets/sound_toggle.dart';
import 'combat/match_controller.dart';
import 'controls/control_input.dart';
import 'controls/touch_controls.dart';
import 'game/hud_state.dart';
import 'game/superhero_game.dart';
import 'hud/battle_hud.dart';

/// Hosts the Flame battle with the Flutter HUD, touch controls and pause
/// menu on top. Pauses automatically when the app goes to the background.
class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with WidgetsBindingObserver {
  final ControlInput _input = ControlInput();
  late SuperheroGame _game;
  bool _paused = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = _createGame();
    GameAudio.instance.playMusic(Music.battle);
  }

  SuperheroGame _createGame() {
    final setup = ref.read(battleSetupProvider);
    return SuperheroGame(
      playerHero: setup.player,
      opponentHero: setup.opponent,
      difficulty: setup.difficulty,
      input: _input,
      onMatchEnd: _onMatchEnd,
    );
  }

  void _onMatchEnd(MatchOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    GameAudio.instance
      ..stopMusic()
      ..play(outcome == MatchOutcome.opponentWins ? Sfx.defeat : Sfx.victory);
    Navigator.of(context)
        .pushReplacementNamed(Routes.result, arguments: outcome);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pause();
    }
  }

  void _pause() {
    if (_paused || _finished) return;
    _input.releaseAll();
    _game.pauseEngine();
    setState(() => _paused = true);
  }

  void _resume() {
    _input.releaseAll();
    _game.resumeEngine();
    setState(() => _paused = false);
  }

  void _restart() {
    _input.releaseAll();
    _game.hud.dispose();
    setState(() {
      _game = _createGame();
      _paused = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.hud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(battleSetupProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _paused ? _resume() : _pause();
      },
      child: Scaffold(
        backgroundColor: AppColors.night,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(key: ObjectKey(_game), game: _game, autofocus: true),
            SafeArea(
              child: ValueListenableBuilder<HudState?>(
                valueListenable: _game.hud,
                builder: (context, hud, _) => hud == null
                    ? const SizedBox.shrink()
                    : BattleHud(
                        state: hud,
                        player: setup.player,
                        opponent: setup.opponent,
                      ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TouchControls(
                  key: ObjectKey(_game),
                  input: _input,
                  hud: _game.hud,
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 68),
                  child: IconButton.filled(
                    key: const ValueKey('pause_button'),
                    tooltip: AppStrings.paused,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cream,
                      foregroundColor: AppColors.ink,
                    ),
                    onPressed: _pause,
                    icon: const Icon(Icons.pause_rounded),
                  ),
                ),
              ),
            ),
            if (_paused)
              _PauseMenu(
                onResume: _resume,
                onRestart: _restart,
                onMenu: () {
                  GameAudio.instance.playMusic(Music.menu);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PauseMenu extends StatelessWidget {
  const _PauseMenu({
    required this.onResume,
    required this.onRestart,
    required this.onMenu,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xAA12142A),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ComicText(AppStrings.paused, size: 52),
              const SizedBox(height: 8),
              const SoundToggle(),
              const SizedBox(height: 12),
              ArcadeButton(
                label: AppStrings.resume,
                icon: Icons.play_arrow_rounded,
                width: 260,
                onPressed: onResume,
              ),
              const SizedBox(height: 12),
              ArcadeButton(
                label: AppStrings.restart,
                icon: Icons.replay_rounded,
                width: 260,
                color: AppColors.playerAccent,
                fontSize: 20,
                onPressed: onRestart,
              ),
              const SizedBox(height: 12),
              ArcadeButton(
                label: AppStrings.mainMenu,
                icon: Icons.home_rounded,
                width: 260,
                color: AppColors.cream,
                fontSize: 20,
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
