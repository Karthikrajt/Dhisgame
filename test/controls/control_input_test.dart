import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/features/battle/controls/control_input.dart';

void main() {
  test('held buttons stay active', () {
    final c = ControlInput()..press(ControlButton.right);
    for (var i = 0; i < 30; i++) {
      expect(c.consume().right, isTrue);
    }
    c.release(ControlButton.right);
    for (var i = 0; i < 30; i++) {
      c.consume();
    }
    expect(c.consume().right, isFalse);
  });

  test('a quick tap is buffered for a few frames', () {
    final c = ControlInput()
      ..press(ControlButton.punch)
      ..release(ControlButton.punch);
    expect(c.consume().punch, isTrue);
    expect(c.consume().punch, isTrue);
    for (var i = 0; i < 20; i++) {
      c.consume();
    }
    expect(c.consume().punch, isFalse);
  });

  test('two fingers on one button need two releases', () {
    final c = ControlInput()
      ..press(ControlButton.left)
      ..press(ControlButton.left)
      ..release(ControlButton.left);
    expect(c.isDown(ControlButton.left), isTrue);
    c.release(ControlButton.left);
    expect(c.isDown(ControlButton.left), isFalse);
  });

  test('left and right together cancel out', () {
    final c = ControlInput()
      ..press(ControlButton.left)
      ..press(ControlButton.right);
    expect(c.consume().horizontal, 0);
  });

  test('releaseAll clears everything', () {
    final c = ControlInput()
      ..press(ControlButton.kick)
      ..press(ControlButton.block)
      ..releaseAll();
    final input = c.consume();
    expect(input.kick || input.block, isFalse);
  });
}
