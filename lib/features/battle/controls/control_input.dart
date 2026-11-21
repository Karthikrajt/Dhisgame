import '../combat/fighter_input.dart';

/// Buttons on the touch control pad (and their keyboard equivalents).
enum ControlButton { left, right, jump, punch, kick, block }

/// Collects pressed buttons from the touch overlay and keyboard, and turns
/// them into a [FighterInput] each frame.
///
/// Taps are buffered for [bufferSeconds], so a quick tap on Punch is never
/// lost, even if it lands while the previous attack is still recovering. Holding an attack button repeats the attack as soon as the
/// previous one recovers.
class ControlInput {
  final Map<ControlButton, int> _holds = {};
  final Map<ControlButton, double> _queued = {};

  static const double bufferSeconds = 0.15;

  bool isDown(ControlButton b) => (_holds[b] ?? 0) > 0;

  void press(ControlButton b) {
    _holds[b] = (_holds[b] ?? 0) + 1;
    _queued[b] = bufferSeconds;
  }

  void release(ControlButton b) {
    final n = (_holds[b] ?? 0) - 1;
    if (n <= 0) {
      _holds.remove(b);
    } else {
      _holds[b] = n;
    }
  }

  void releaseAll() {
    _holds.clear();
    _queued.clear();
  }

  bool _active(ControlButton b) => isDown(b) || _queued.containsKey(b);

  /// Reads the current input and ages buffered taps by [dt] seconds.
  FighterInput consume([double dt = 1 / 60]) {
    final input = FighterInput(
      left: _active(ControlButton.left),
      right: _active(ControlButton.right),
      jump: _active(ControlButton.jump),
      punch: _active(ControlButton.punch),
      kick: _active(ControlButton.kick),
      block: _active(ControlButton.block),
    );
    _queued.updateAll((_, t) => t - dt);
    _queued.removeWhere((_, t) => t <= 0);
    return input;
  }
}
