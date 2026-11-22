import 'package:material_ui/material_ui.dart';

import '../../core/audio/game_audio.dart';
import '../../core/constants/app_colors.dart';

/// Round speaker button that turns all sound on or off.
class SoundToggle extends StatelessWidget {
  const SoundToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = GameAudio.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: audio.muted,
      builder: (context, muted, _) => IconButton.filled(
        key: const ValueKey('sound_toggle'),
        tooltip: muted ? 'Sound on' : 'Sound off',
        style: IconButton.styleFrom(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.ink,
        ),
        onPressed: audio.toggleMute,
        icon: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded),
      ),
    );
  }
}
