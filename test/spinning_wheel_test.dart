import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spinning_wheel/core/spin_calculations.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

Widget _wheel(
  SpinnerController controller,
  List<WheelSegment> segments, {
  void Function(WheelSegment, int)? onComplete,
}) {
  return MaterialApp(
    home: SizedBox(
      width: 300,
      height: 300,
      child: SpinnerWheel(
        controller: controller,
        segments: segments,
        onComplete: onComplete ?? (_, __) {},
      ),
    ),
  );
}

/// The rotation applied to the wheel's segments.
Matrix4 _wheelTransform(WidgetTester tester) => tester
    .widget<Transform>(find.ancestor(
        of: find.byType(RepaintBoundary).last,
        matching: find.byType(Transform)))
    .transform;

void main() {
  group('effectiveProbabilities', () {
    test('all null gives equal weights', () {
      final segs = [WheelSegment('a', 1), WheelSegment('b', 2)];
      expect(effectiveProbabilities(segs), [1.0, 1.0]);
    });

    test('null segments share the remaining probability', () {
      final segs = [
        WheelSegment('a', 1, probability: 0.4),
        WheelSegment('b', 2),
        WheelSegment('c', 3),
      ];
      final w = effectiveProbabilities(segs);
      expect(w[0], 0.4);
      expect(w[1], closeTo(0.3, 1e-9));
      expect(w[2], closeTo(0.3, 1e-9));
    });

    test('negative probabilities are treated as zero', () {
      final segs = [
        WheelSegment('a', 1, probability: -1),
        WheelSegment('b', 2, probability: 0.5),
      ];
      expect(effectiveProbabilities(segs), [0.0, 0.5]);
    });
  });

  group('spinWheel', () {
    test('segments without probability can still win', () {
      final segs = [
        WheelSegment('A', 1, probability: 0.25),
        WheelSegment('B', 2),
        WheelSegment('C', 3, probability: 0.25),
      ];
      final counts = [0, 0, 0];
      for (var i = 0; i < 4000; i++) {
        counts[spinWheel(0, segs).index]++;
      }
      // B should get the remaining 50%.
      expect(counts[1], greaterThan(1600));
      expect(counts[1], lessThan(2400));
    });

    test('end rotation lands on the selected index', () {
      final segs = List.generate(7, (i) => WheelSegment('$i', i));
      var start = 0.0;
      for (var i = 0; i < 500; i++) {
        final r = spinWheel(start, segs);
        expect(determineSegment(segs, r.end), r.index);
        start = r.end;
      }
    });

    test('throws a clear error for empty segments', () {
      expect(() => spinWheel(0, []), throwsArgumentError);
    });
  });

  group('SpinnerWheel', () {
    testWidgets('reports the result of the spin', (tester) async {
      final controller = SpinnerController();
      final segs = [WheelSegment('a', 1), WheelSegment('b', 2)];
      WheelSegment? won;
      int? wonIndex;
      await tester.pumpWidget(_wheel(controller, segs, onComplete: (s, i) {
        won = s;
        wonIndex = i;
      }));
      await controller.startSpin();
      await tester.pumpAndSettle();
      expect(wonIndex, isNotNull);
      expect(won, same(segs[wonIndex!]));
    });

    testWidgets('startSpin while spinning is ignored', (tester) async {
      final controller = SpinnerController();
      var completions = 0;
      await tester.pumpWidget(_wheel(
        controller,
        [WheelSegment('a', 1), WheelSegment('b', 2)],
        onComplete: (_, __) => completions++,
      ));
      await controller.startSpin();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      final angleMidSpin = _wheelTransform(tester);
      expect(angleMidSpin, isNot(equals(Matrix4.identity())));
      await controller.startSpin();
      await tester.pump(Duration.zero);
      final angleAfterSecondCall = _wheelTransform(tester);
      // The wheel must not snap back to its start position.
      expect(angleAfterSecondCall, equals(angleMidSpin));
      await tester.pumpAndSettle();
      expect(completions, 1);
    });

    testWidgets('picks up new segments on rebuild', (tester) async {
      final controller = SpinnerController();
      await tester.pumpWidget(
          _wheel(controller, [WheelSegment('a', 1), WheelSegment('b', 2)]));
      final next = [
        WheelSegment('x', 1),
        WheelSegment('y', 2),
        WheelSegment('z', 3),
      ];
      await tester.pumpWidget(_wheel(controller, next));
      final state = tester.state<SpinnerWheelState>(find.byType(SpinnerWheel));
      expect(state.processedSegments.map((s) => s.label), ['x', 'y', 'z']);
    });

    testWidgets('picks up in-place edits of the same list', (tester) async {
      final controller = SpinnerController();
      final segs = [WheelSegment('a', 1), WheelSegment('b', 2)];
      await tester.pumpWidget(_wheel(controller, segs));
      segs.add(WheelSegment('c', 3));
      await tester.pumpWidget(_wheel(controller, segs));
      final state = tester.state<SpinnerWheelState>(find.byType(SpinnerWheel));
      expect(state.processedSegments.map((s) => s.label), ['a', 'b', 'c']);
    });

    testWidgets('controller is detached on dispose', (tester) async {
      final controller = SpinnerController();
      await tester.pumpWidget(
          _wheel(controller, [WheelSegment('a', 1), WheelSegment('b', 2)]));
      await tester.pumpWidget(const SizedBox());
      // Must not throw "AnimationController used after dispose".
      await controller.startSpin();
    });

    testWidgets('empty segments do not crash', (tester) async {
      final controller = SpinnerController();
      await tester.pumpWidget(_wheel(controller, []));
      await controller.startSpin();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not create a CurvedAnimation per frame',
        (tester) async {
      var created = 0;
      void listener(ObjectEvent event) {
        if (event is ObjectCreated && event.object is CurvedAnimation) {
          created++;
        }
      }

      FlutterMemoryAllocations.instance.addListener(listener);
      addTearDown(
          () => FlutterMemoryAllocations.instance.removeListener(listener));

      final controller = SpinnerController();
      await tester.pumpWidget(
          _wheel(controller, [WheelSegment('a', 1), WheelSegment('b', 2)]));
      final createdBeforeSpin = created;
      await controller.startSpin();
      await tester.pumpAndSettle();
      expect(created - createdBeforeSpin, 0);
    });
  });
}
