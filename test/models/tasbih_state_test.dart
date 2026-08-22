import 'package:aldhakereen/models/tasbih_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasbihZahraState', () {
    test('one tap increments only once', () {
      const state = TasbihZahraState();
      final next = state.increment();

      expect(next.stageIndex, 0);
      expect(next.count, 1);
      expect(next.lifetimeTotal, 1);
      expect(next.completedCycles, 0);
    });

    test('34 Allahu Akbar taps transition to Alhamdulillah at zero', () {
      var state = const TasbihZahraState();
      for (var i = 0; i < 34; i++) {
        state = state.increment();
      }

      expect(state.stageIndex, 1);
      expect(state.count, 0);
      expect(state.lifetimeTotal, 34);
      expect(state.completedCycles, 0);
    });

    test('33 Alhamdulillah taps transition to Subhanallah at zero', () {
      var state = const TasbihZahraState(stageIndex: 1);
      for (var i = 0; i < 33; i++) {
        state = state.increment();
      }

      expect(state.stageIndex, 2);
      expect(state.count, 0);
      expect(state.lifetimeTotal, 33);
    });

    test('final 33 taps complete one cycle and restart at Allahu Akbar', () {
      var state = const TasbihZahraState(stageIndex: 2);
      for (var i = 0; i < 33; i++) {
        state = state.increment();
      }

      expect(state.stageIndex, 0);
      expect(state.count, 0);
      expect(state.completedCycles, 1);
      expect(state.lifetimeTotal, 33);
    });

    test('a complete 100-count cycle has correct totals', () {
      var state = const TasbihZahraState();
      for (var i = 0; i < 100; i++) {
        state = state.increment();
      }

      expect(state.count, 0);
      expect(state.stageIndex, 0);
      expect(state.completedCycles, 1);
      expect(state.lifetimeTotal, 100);
    });

    test(
        'reset clears current stage without deleting completed or lifetime data',
        () {
      const state = TasbihZahraState(
        stageIndex: 1,
        count: 12,
        completedCycles: 3,
        lifetimeTotal: 312,
      );
      final reset = state.resetStage();

      expect(reset.stageIndex, 1);
      expect(reset.count, 0);
      expect(reset.completedCycles, 3);
      expect(reset.lifetimeTotal, 312);
    });
  });
}
