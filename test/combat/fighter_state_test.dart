import 'package:flutter_test/flutter_test.dart';
import 'package:superhero_showdown/features/battle/combat/fighter_state.dart';

void main() {
  group('FighterStateMachine', () {
    test('starts idle', () {
      expect(FighterStateMachine().state, FighterState.idle);
    });

    test('allows normal transitions', () {
      final sm = FighterStateMachine();
      expect(sm.transition(FighterState.walking), isTrue);
      expect(sm.transition(FighterState.punching), isTrue);
      expect(sm.transition(FighterState.idle), isTrue);
    });

    test('knockout is final', () {
      final sm = FighterStateMachine()..transition(FighterState.knockout);
      for (final s in FighterState.values) {
        if (s == FighterState.knockout) continue;
        expect(sm.transition(s), isFalse, reason: 'knockout -> $s');
      }
      expect(sm.state, FighterState.knockout);
    });

    test('cannot block in the air or chain attacks directly', () {
      final sm = FighterStateMachine()..transition(FighterState.jumping);
      expect(sm.transition(FighterState.blocking), isFalse);
      sm.transition(FighterState.punching);
      expect(sm.transition(FighterState.kicking), isFalse);
      expect(sm.state, FighterState.punching);
    });

    test('cannot attack while being hit', () {
      final sm = FighterStateMachine()..transition(FighterState.hit);
      expect(sm.transition(FighterState.punching), isFalse);
      expect(sm.transition(FighterState.walking), isFalse);
    });

    test('time in state resets on transition', () {
      final sm = FighterStateMachine()..tick(1);
      expect(sm.timeInState, 1);
      sm.transition(FighterState.walking);
      expect(sm.timeInState, 0);
    });
  });
}
