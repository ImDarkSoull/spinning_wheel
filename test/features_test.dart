import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spinning_wheel/core/spin_calculations.dart';
import 'package:spinning_wheel/core/wheel_geometry.dart';
import 'package:spinning_wheel/spinning_wheel.dart';
import 'package:spinning_wheel/widgets/wheel_frame_painter.dart';
import 'package:spinning_wheel/widgets/wheel_painter.dart';

/// A 1x1 transparent PNG.
final MemoryImage _pixel = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='));

List<WheelSegment<int>> _segments(int count) =>
    List.generate(count, (i) => WheelSegment('S$i', i));

/// Pumps a 300x300 wheel centered in the test window.
Future<void> _pumpWheel(
  WidgetTester tester,
  SpinnerWheel<int> wheel, {
  TextDirection textDirection = TextDirection.ltr,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: Center(child: SizedBox(width: 300, height: 300, child: wheel)),
    ),
  ));
}

Finder get _wheelFinder => find.byWidgetPredicate((w) => w is SpinnerWheel);

WheelPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<WheelPainter>()
    .single;

SpinnerWheelState<int> _state(WidgetTester tester) =>
    tester.state<SpinnerWheelState<int>>(_wheelFinder);

/// The wheel's current rotation in radians, read from its transform.
double _rotation(WidgetTester tester) {
  final Matrix4 m = tester
      .widget<Transform>(find.ancestor(
          of: find.byType(RepaintBoundary).last,
          matching: find.byType(Transform)))
      .transform;
  return atan2(m.storage[1], m.storage[0]);
}

void main() {
  group('WheelGeometry', () {
    test('equal geometry agrees with determineSegment', () {
      final segs = _segments(7);
      final geometry = WheelGeometry.equal(7);
      for (double r = -20; r < 20; r += 0.137) {
        expect(geometry.indexAt(r, -pi / 2), determineSegment(segs, r));
      }
    });

    test('weighted geometry sizes slices by weight', () {
      final geometry = WheelGeometry.weighted([1, 3, 0, 4]);
      expect(geometry.sweeps[0], closeTo(2 * pi / 8, 1e-9));
      expect(geometry.sweeps[1], closeTo(2 * pi * 3 / 8, 1e-9));
      expect(geometry.sweeps[2], 0);
      expect(geometry.sweeps[3], closeTo(2 * pi / 2, 1e-9));
      expect(geometry.offsets, [
        0,
        closeTo(2 * pi / 8, 1e-9),
        closeTo(2 * pi / 2, 1e-9),
        closeTo(2 * pi / 2, 1e-9),
      ]);
    });

    test('all-zero weights fall back to equal slices', () {
      expect(WheelGeometry.weighted([0, 0]).sweeps, [pi, pi]);
    });

    test('a slice of zero size is never under the pointer', () {
      final geometry = WheelGeometry.weighted([1, 0, 1]);
      for (double r = 0; r < 2 * pi; r += 0.01) {
        expect(geometry.indexAt(r, -pi / 2), isNot(1));
      }
    });

    test('planned spins land on the target for every pointer and direction',
        () {
      final random = Random(42);
      final geometry = WheelGeometry.weighted([1, 2, 3, 0.5, 4]);
      for (final position in IndicatorPosition.values) {
        for (final clockwise in [true, false]) {
          for (int i = 0; i < 200; i++) {
            final int index = random.nextInt(5);
            final double start = random.nextDouble() * 40 - 20;
            final plan = planSpin(
              startRotation: start,
              geometry: geometry,
              index: index,
              fullTurns: 3,
              pointerAngle: position.angle,
              clockwise: clockwise,
              random: random,
            );
            expect(geometry.indexAt(plan.end, position.angle), index);
            final double travelled = plan.end - start;
            expect(clockwise ? travelled : -travelled,
                greaterThanOrEqualTo(3 * 2 * pi));
            expect(clockwise ? travelled : -travelled, lessThan(4 * 2 * pi));
          }
        }
      }
    });

    test('slicesEntered matches stepping through slowly', () {
      final random = Random(7);
      for (final geometry in [
        WheelGeometry.equal(6),
        WheelGeometry.weighted([1, 0, 2, 3, 0.5]),
        WheelGeometry.equal(1),
      ]) {
        for (int trial = 0; trial < 50; trial++) {
          final double from = random.nextDouble() * 20 - 10;
          final double to = from + random.nextDouble() * 30 - 15;
          final big = geometry.slicesEntered(from, to, -pi / 2);
          // The same turn in tiny steps, noting each change of slice.
          final small = <int>[];
          int last = geometry.indexAt(from, -pi / 2);
          const int steps = 20000;
          for (int k = 1; k <= steps; k++) {
            final int now =
                geometry.indexAt(from + (to - from) * k / steps, -pi / 2);
            if (now != last) small.add(now);
            last = now;
          }
          if (geometry.length > 1) {
            expect(big, small, reason: 'from $from to $to');
          } else {
            // One slice: entered again each time its one edge passes the
            // pointer, which depends on where the turn starts.
            final int turns = ((to - from).abs() / (2 * pi)).floor();
            expect(big.length, inInclusiveRange(turns, turns + 1),
                reason: 'from $from to $to');
          }
          if (geometry.sweeps.length > 1 && geometry.sweeps[1] == 0) {
            expect(big, isNot(contains(1)),
                reason: 'zero-size slices are never entered');
          }
        }
      }
    });

    test('pickWeightedIndex never picks a zero weight', () {
      final random = Random(1);
      for (int i = 0; i < 2000; i++) {
        expect(pickWeightedIndex([0, 1, 0, 2], random), isIn([1, 3]));
      }
    });
  });

  group('SpinnerController', () {
    testWidgets('reports isSpinning and lastResult, and notifies',
        (tester) async {
      final controller = SpinnerController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: controller,
              segments: _segments(4),
              onComplete: (_, __) {}));
      expect(controller.isAttached, isTrue);
      expect(controller.isSpinning, isFalse);

      final future = controller.startSpin();
      expect(controller.isSpinning, isTrue);
      expect(notifications, 1);
      await tester.pumpAndSettle();
      final result = await future;

      expect(controller.isSpinning, isFalse);
      expect(notifications, 2);
      expect(result, isNotNull);
      expect(controller.lastResult!.index, result!.index);
    });

    testWidgets('startSpin resolves with the segment under the pointer',
        (tester) async {
      for (final position in IndicatorPosition.values) {
        final controller = SpinnerController();
        await _pumpWheel(
            tester,
            SpinnerWheel(
              controller: controller,
              segments: _segments(7),
              indicatorPosition: position,
              onComplete: (_, __) {},
            ));
        final future = controller.startSpin();
        await tester.pumpAndSettle();
        final result = (await future)!;
        expect(
            WheelGeometry.equal(7).indexAt(_rotation(tester), position.angle),
            result.index,
            reason: '$position');
      }
    });

    testWidgets('spinTo lands on the requested segment', (tester) async {
      final controller = SpinnerController();
      final completed = <int>[];
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(6),
            onComplete: (_, i) => completed.add(i),
          ));
      for (final target in [3, 0, 5, 5, 1]) {
        final future = controller.spinTo(target);
        await tester.pumpAndSettle();
        expect((await future)!.index, target);
        expect(
            WheelGeometry.equal(6).indexAt(_rotation(tester), -pi / 2), target);
      }
      expect(completed, [3, 0, 5, 5, 1]);
    });

    testWidgets('spinTo rejects bad indexes', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            sliceSizing: SliceSizing.proportional,
            segments: [
              WheelSegment('a', 1, probability: 0.5),
              WheelSegment('b', 2, probability: 0),
              WheelSegment('c', 3, probability: 0.5),
            ],
            onComplete: (_, __) {},
          ));
      await expectLater(controller.spinTo(9), throwsRangeError);
      await expectLater(controller.spinTo(1), throwsArgumentError);
      expect(controller.isSpinning, isFalse);
    });

    testWidgets('stop ends the spin early on the segment it reaches',
        (tester) async {
      final controller = SpinnerController();
      WheelSpinResult? fromCallback;
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(8),
            onComplete: (s, i) => fromCallback = WheelSpinResult(s, i),
          ));
      final future = controller.startSpin();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      controller.stop();
      controller.stop(); // A second stop is ignored.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(controller.isSpinning, isFalse,
          reason: 'stopped well before the 5 second spin would end');

      final result = (await future)!;
      expect(fromCallback!.index, result.index);
      expect(WheelGeometry.equal(8).indexAt(_rotation(tester), -pi / 2),
          result.index);
    });

    testWidgets('stop does nothing when idle', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: controller,
              segments: _segments(3),
              onComplete: (_, __) {}));
      controller.stop();
      await tester.pump();
      expect(controller.isSpinning, isFalse);
      expect(controller.lastResult, isNull);
    });

    testWidgets('disposing mid-spin resets isSpinning without errors',
        (tester) async {
      final controller = SpinnerController();
      var notified = false;
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: controller,
              segments: _segments(3),
              onComplete: (_, __) {}));
      final future = controller.startSpin();
      await tester.pump();
      controller.addListener(() => notified = true);
      await tester.pumpWidget(const SizedBox());
      expect(await future, isNull);
      await tester.pump();
      expect(controller.isSpinning, isFalse);
      expect(controller.isAttached, isFalse);
      expect(notified, isTrue);
    });

    test('startSpin without a wheel resolves with null', () async {
      expect(await SpinnerController().startSpin(), isNull);
      expect(await SpinnerController().spinTo(0), isNull);
    });
  });

  group('spin options and callbacks', () {
    testWidgets('spinDuration controls how long a spin takes', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(4),
            spinDuration: const Duration(seconds: 2),
            spinCurve: Curves.linear,
            onComplete: (_, __) {},
          ));
      controller.startSpin();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      expect(controller.isSpinning, isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.isSpinning, isFalse);
    });

    testWidgets('minSpins and maxSpins bound the number of turns',
        (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(4),
            minSpins: 2,
            maxSpins: 2,
            onComplete: (_, __) {},
          ));
      for (int i = 0; i < 5; i++) {
        controller.startSpin();
        await tester.pump();
        final double travelled = _plannedTravel(_state(tester));
        expect(travelled, greaterThanOrEqualTo(2 * 2 * pi));
        expect(travelled, lessThan(3 * 2 * pi));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('onSpinStart and onSegmentPass fire', (tester) async {
      final controller = SpinnerController();
      var starts = 0;
      final passes = <int>[];
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(6),
            minSpins: 1,
            maxSpins: 1,
            onSpinStart: () => starts++,
            onSegmentPass: passes.add,
            onComplete: (_, __) {},
          ));
      final future = controller.startSpin();
      await tester.pumpAndSettle();
      final result = (await future)!;
      expect(starts, 1);
      // At least one full turn passes every segment.
      expect(passes.toSet(), {0, 1, 2, 3, 4, 5});
      expect(passes.last, result.index);
      for (int i = 1; i < passes.length; i++) {
        expect(passes[i], isNot(passes[i - 1]));
      }
    });

    testWidgets('onSegmentPass reports every slice even if frames drop',
        (tester) async {
      final controller = SpinnerController();
      final passes = <int>[];
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(6),
            minSpins: 2,
            maxSpins: 2,
            onSegmentPass: passes.add,
            onComplete: (_, __) {},
          ));
      final future = controller.startSpin();
      await tester.pump();
      // The whole spin in a single frame.
      await tester.pump(const Duration(seconds: 6));
      final result = (await future)!;
      expect(passes.length, greaterThanOrEqualTo(12));
      expect(passes.length, lessThan(19));
      for (int i = 1; i < passes.length; i++) {
        // Clockwise: one slice back each time.
        expect(passes[i], (passes[i - 1] - 1) % 6);
      }
      expect(passes.last, result.index);

      // Settling after the spin isn't counted as more turns.
      final int count = passes.length;
      await tester.pump(const Duration(seconds: 1));
      expect(passes.length, count);
    });

    testWidgets('generic values come back typed', (tester) async {
      final controller = SpinnerController();
      String? won;
      await tester.pumpWidget(MaterialApp(
        home: SpinnerWheel<String>(
          controller: controller,
          segments: [WheelSegment('A', 'CODE-A'), WheelSegment('B', 'CODE-B')],
          onComplete: (segment, _) => won = segment.value,
        ),
      ));
      controller.spinTo(1);
      await tester.pumpAndSettle();
      expect(won, 'CODE-B');
    });
  });

  group('never appears to spin backwards', () {
    /// Pumps 60 fps frames until the spin ends and returns every frame's
    /// rotation step (radians, clockwise positive).
    Future<List<double>> recordSteps(
        WidgetTester tester, SpinnerController controller) async {
      final steps = <double>[];
      // Draw the frame that starts the spin (and shows any drag) first.
      await tester.pump();
      double last = _rotation(tester);
      for (int i = 0; i < 60 * 30 && controller.isSpinning; i++) {
        await tester.pump(const Duration(microseconds: 16667));
        final double now = _rotation(tester);
        double step = now - last;
        if (step > pi) step -= 2 * pi;
        if (step < -pi) step += 2 * pi;
        steps.add(step);
        last = now;
      }
      return steps;
    }

    void expectSafe(List<double> steps, int slices, {bool clockwise = true}) {
      final double limit = maxSliceFractionPerFrame * 2 * pi / slices + 1e-6;
      for (final step in steps) {
        expect(clockwise ? step : -step, greaterThanOrEqualTo(-1e-9),
            reason: 'the wheel turned the other way');
        expect(step.abs(), lessThanOrEqualTo(limit),
            reason: 'faster than ${maxSliceFractionPerFrame * 100}% of a '
                'slice per frame');
      }
    }

    for (final slices in [4, 6, 12, 24]) {
      testWidgets('default spin with $slices slices', (tester) async {
        final controller = SpinnerController();
        await _pumpWheel(
            tester,
            SpinnerWheel(
              controller: controller,
              segments: _segments(slices),
              onComplete: (_, __) {},
            ));
        controller.startSpin();
        expectSafe(await recordSteps(tester, controller), slices);
      });
    }

    testWidgets('many turns and a steep curve are slowed down', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(12),
            minSpins: 9,
            maxSpins: 9,
            spinCurve: Curves.easeOutCirc,
            onComplete: (_, __) {},
          ));
      final future = controller.startSpin();
      expectSafe(await recordSteps(tester, controller), 12);
      // Still lands on the reported segment.
      final result = (await future)!;
      expect(WheelGeometry.equal(12).indexAt(_rotation(tester), -pi / 2),
          result.index);
    });

    testWidgets('a very fast fling is capped', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(10),
            swipeToSpin: true,
            onComplete: (_, __) {},
          ));
      final Offset center = tester.getCenter(_wheelFinder);
      await tester.flingFrom(
          center + const Offset(-60, -100), const Offset(120, 0), 20000);
      expect(controller.isSpinning, isTrue);
      expectSafe(await recordSteps(tester, controller), 10);
    });

    testWidgets('stopping keeps turning forward', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(8),
            onComplete: (_, __) {},
          ));
      controller.startSpin();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      controller.stop();
      expectSafe(await recordSteps(tester, controller), 8);
    });

    test('maxSpinDistance matches the per-frame limit', () {
      const duration = Duration(seconds: 5);
      final double distance = maxSpinDistance(
          segmentCount: 12, curve: Curves.decelerate, duration: duration);
      final double peak = peakFrameFraction(Curves.decelerate, duration);
      expect(distance * peak,
          closeTo(maxSliceFractionPerFrame * 2 * pi / 12, 1e-9));
      // decelerate starts at twice its average speed: 2 / 300 frames.
      expect(peak, closeTo(2 / 300, 1e-4));
    });
  });

  group('interaction', () {
    testWidgets('tapToSpin spins when the center is tapped', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(4),
            tapToSpin: true,
            onComplete: (_, __) {},
          ));
      await tester.tapAt(tester.getCenter(_wheelFinder));
      expect(controller.isSpinning, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('tapping the center does nothing by default', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: controller,
              segments: _segments(4),
              onComplete: (_, __) {}));
      await tester.tapAt(tester.getCenter(_wheelFinder));
      expect(controller.isSpinning, isFalse);
    });

    testWidgets('a fling spins the wheel in the fling direction',
        (tester) async {
      for (final clockwise in [true, false]) {
        final controller = SpinnerController();
        await _pumpWheel(
            tester,
            SpinnerWheel(
              controller: controller,
              segments: _segments(6),
              swipeToSpin: true,
              onComplete: (_, __) {},
            ));
        final Offset center = tester.getCenter(_wheelFinder);
        // Drag across the top of the wheel: rightwards turns it clockwise.
        await tester.flingFrom(center + const Offset(-60, -100),
            Offset(clockwise ? 120 : -120, 0), 2000);
        await tester.pump();
        expect(controller.isSpinning, isTrue);

        final state = _state(tester);
        expect(_plannedTravel(state, signed: true) > 0, clockwise);

        final future = controller.startSpin(); // Joins the fling's spin.
        await tester.pumpAndSettle();
        final result = (await future)!;
        expect(WheelGeometry.equal(6).indexAt(_rotation(tester), -pi / 2),
            result.index);
      }
    });

    testWidgets('a slow drag turns the wheel without spinning it',
        (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(6),
            swipeToSpin: true,
            onComplete: (_, __) {},
          ));
      final Offset center = tester.getCenter(_wheelFinder);
      final gesture = await tester.startGesture(center + const Offset(0, -100));
      for (int i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(10, 4));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pump();
      expect(controller.isSpinning, isFalse);
      expect(_rotation(tester), isNot(closeTo(0, 0.05)));
    });

    testWidgets('dragging does nothing unless swipeToSpin is on',
        (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: controller,
              segments: _segments(6),
              onComplete: (_, __) {}));
      final Offset center = tester.getCenter(_wheelFinder);
      await tester.flingFrom(
          center + const Offset(-60, -100), const Offset(120, 0), 2000);
      await tester.pump();
      expect(controller.isSpinning, isFalse);
      expect(_rotation(tester), 0);
    });

    testWidgets('the indicator flicks as segments pass', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(6),
            indicatorBounce: true,
            onComplete: (_, __) {},
          ));
      controller.startSpin();
      double maxFlick = 0;
      await tester.pump();
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        for (final t in tester.widgetList<Transform>(find.descendant(
            of: find.byType(RotatedBox), matching: find.byType(Transform)))) {
          maxFlick = max(maxFlick,
              atan2(t.transform.storage[1], t.transform.storage[0]).abs());
        }
      }
      expect(maxFlick, greaterThan(0.05));
      await tester.pumpAndSettle();
    });

    testWidgets('the indicator is placed on the chosen side', (tester) async {
      for (final position in IndicatorPosition.values) {
        await _pumpWheel(
            tester,
            SpinnerWheel(
              controller: SpinnerController(),
              segments: _segments(4),
              indicatorPosition: position,
              onComplete: (_, __) {},
            ));
        final Rect wheel = tester.getRect(_wheelFinder);
        final Rect pointer = tester.getRect(find.byType(RotatedBox));
        final Offset offset = pointer.center - wheel.center;
        switch (position) {
          case IndicatorPosition.top:
            expect(offset.dy, lessThan(-100));
          case IndicatorPosition.right:
            expect(offset.dx, greaterThan(100));
          case IndicatorPosition.bottom:
            expect(offset.dy, greaterThan(100));
          case IndicatorPosition.left:
            expect(offset.dx, lessThan(-100));
        }
        expect(tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns,
            position.quarterTurns);
      }
    });
  });

  group('visuals', () {
    testWidgets('proportional slices follow probabilities', (tester) async {
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: SpinnerController(),
            sliceSizing: SliceSizing.proportional,
            segments: [
              WheelSegment('a', 1, probability: 0.25),
              WheelSegment('b', 2, probability: 0.75),
            ],
            onComplete: (_, __) {},
          ));
      final sweeps = _painter(tester).geometry.sweeps;
      expect(sweeps[0], closeTo(pi / 2, 1e-9));
      expect(sweeps[1], closeTo(3 * pi / 2, 1e-9));
    });

    testWidgets('style options reach the painter', (tester) async {
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: SpinnerController(),
            segments: _segments(4),
            sliceStyle: SliceStyle.flat,
            sliceBorderColor: Colors.amber,
            sliceBorderWidth: 3,
            onComplete: (_, __) {},
          ));
      final painter = _painter(tester);
      expect(painter.sliceStyle, SliceStyle.flat);
      expect(painter.borderColor, Colors.amber);
      expect(painter.borderWidth, 3);
    });

    testWidgets('highlightWinner highlights until the next spin',
        (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(5),
            highlightWinner: true,
            onComplete: (_, __) {},
          ));
      expect(_painter(tester).highlightIndex, isNull);
      controller.spinTo(3);
      await tester.pumpAndSettle();
      expect(_painter(tester).highlightIndex, 3);
      controller.startSpin();
      await tester.pump();
      expect(_painter(tester).highlightIndex, isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('no highlight unless highlightWinner is on', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: controller,
              segments: _segments(5),
              onComplete: (_, __) {}));
      controller.spinTo(3);
      await tester.pumpAndSettle();
      expect(_painter(tester).highlightIndex, isNull);
    });

    testWidgets('segment child widgets are shown and rotate with the wheel',
        (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: [
              WheelSegment('a', 1, child: const Icon(Icons.star)),
              WheelSegment('b', 2),
            ],
            onComplete: (_, __) {},
          ));
      expect(find.byIcon(Icons.star), findsOneWidget);
      final before = tester.getCenter(find.byIcon(Icons.star));
      controller.spinTo(1);
      await tester.pumpAndSettle();
      final after = tester.getCenter(find.byIcon(Icons.star));
      expect((after - before).distance, greaterThan(10));
    });

    testWidgets('label text follows the ambient text direction',
        (tester) async {
      await _pumpWheel(
        tester,
        SpinnerWheel(
            controller: SpinnerController(),
            segments: _segments(3),
            onComplete: (_, __) {}),
        textDirection: TextDirection.rtl,
      );
      expect(_painter(tester).textDirection, TextDirection.rtl);
    });
  });

  group('frame', () {
    List<WheelFramePainter> framePainters(WidgetTester tester) => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<WheelFramePainter>()
        .toList();

    testWidgets('the classic frame is painted behind and in front by default',
        (tester) async {
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: SpinnerController(),
              segments: _segments(4),
              onComplete: (_, __) {}));
      final painters = framePainters(tester);
      expect(painters.map((p) => p.layer),
          [WheelFrameLayer.back, WheelFrameLayer.front]);
      expect(painters.first.frame, const WheelFrame.classic());
      expect(painters.first.inset, 0.094);
    });

    testWidgets('wheelColor sets the rim color, frame wins over it',
        (tester) async {
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: SpinnerController(),
              segments: _segments(4),
              wheelColor: Colors.purple,
              onComplete: (_, __) {}));
      expect(framePainters(tester).first.frame,
          const WheelFrame.classic(rimColor: Colors.purple));

      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: SpinnerController(),
              segments: _segments(4),
              wheelColor: Colors.purple,
              frame: const WheelFrame.neon(),
              onComplete: (_, __) {}));
      expect(framePainters(tester).first.frame, const WheelFrame.neon());
    });

    for (final frame in const [
      WheelFrame.classic(),
      WheelFrame.royal(),
      WheelFrame.neon(),
      WheelFrame.wooden(),
    ]) {
      testWidgets('${frame.runtimeType} sets the inset and pointer color',
          (tester) async {
        await _pumpWheel(
            tester,
            SpinnerWheel(
                controller: SpinnerController(),
                segments: _segments(4),
                frame: frame,
                onComplete: (_, __) {}));
        expect(framePainters(tester).first.inset, frame.preferredInset);
        final wheel = tester.widget<SpinnerWheel<int>>(_wheelFinder);
        expect(wheel.effectiveWheelInset, frame.preferredInset);
        // The default pointer uses the frame's color.
        final Iterable<Color?> colors = tester
            .widgetList<Container>(find.descendant(
                of: find.byType(RotatedBox), matching: find.byType(Container)))
            .map((c) => (c.decoration as BoxDecoration?)?.color);
        expect(colors, contains(frame.indicatorColor ?? Colors.red));
      });
    }

    testWidgets('wheelInset and indicatorColor override the frame',
        (tester) async {
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: SpinnerController(),
              segments: _segments(4),
              frame: const WheelFrame.wooden(),
              wheelInset: 0.05,
              indicatorColor: Colors.green,
              onComplete: (_, __) {}));
      expect(framePainters(tester).first.inset, 0.05);
      final Iterable<Color?> colors = tester
          .widgetList<Container>(find.descendant(
              of: find.byType(RotatedBox), matching: find.byType(Container)))
          .map((c) => (c.decoration as BoxDecoration?)?.color);
      expect(colors, contains(Colors.green));
    });

    testWidgets('a custom frame gets geometry that matches the slices',
        (tester) async {
      final calls = <String>[];
      WheelFrameGeometry? front;
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: SpinnerController(),
            segments: _segments(4),
            frame: WheelFrame.custom(
              paintBack: (canvas, g) => calls.add('back'),
              paintFront: (canvas, g) {
                calls.add('front');
                front = g;
              },
              preferredInset: 0.12,
              indicatorColor: Colors.teal,
            ),
            onComplete: (_, __) {},
          ));
      expect(calls, containsAllInOrder(['back', 'front']));
      // The wheel is 300 wide: radius 150, slices inset by 12% of 300.
      expect(front!.radius, 150);
      expect(front!.sliceRadius, closeTo(150 - 300 * 0.12, 1e-9));
      expect(front!.center, const Offset(150, 150));
    });

    testWidgets('a custom background or shouldDrawBackground: false removes it',
        (tester) async {
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: SpinnerController(),
              segments: _segments(4),
              frame: const WheelFrame.wooden(),
              background: const ColoredBox(color: Colors.black),
              onComplete: (_, __) {}));
      expect(framePainters(tester), isEmpty);
      expect(find.byType(ColoredBox), findsWidgets);
      // Without the frame, the frame's inset doesn't apply.
      expect(tester.widget<SpinnerWheel<int>>(_wheelFinder).effectiveWheelInset,
          0.094);

      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: SpinnerController(),
              segments: _segments(4),
              shouldDrawBackground: false,
              onComplete: (_, __) {}));
      expect(framePainters(tester), isEmpty);
    });

    testWidgets('the rim does not block swipes', (tester) async {
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: _segments(6),
            swipeToSpin: true,
            onComplete: (_, __) {},
          ));
      // Start on the rim, outside the slices.
      final Offset center = tester.getCenter(_wheelFinder);
      await tester.flingFrom(
          center + const Offset(-40, -137), const Offset(100, 0), 2000);
      await tester.pump();
      expect(controller.isSpinning, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('every frame paints at any size, inset and option',
        (tester) async {
      const frames = [
        WheelFrame.classic(),
        WheelFrame.classic(toothCount: 0, studCount: 0, shadow: false),
        WheelFrame.classic(toothCount: 24, studCount: 3),
        WheelFrame.royal(),
        WheelFrame.royal(gemCount: 0, shadow: false),
        WheelFrame.neon(),
        WheelFrame.wooden(),
        WheelFrame.wooden(handleCount: 0, shadow: false),
        WheelFrame.wooden(handleCount: 20),
      ];
      for (final size in [60.0, 150.0, 300.0, 900.0]) {
        for (final inset in [0.0, 0.03, null, 0.3]) {
          for (final frame in frames) {
            await tester.pumpWidget(MaterialApp(
              home: Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: SpinnerWheel(
                    controller: SpinnerController(),
                    segments: _segments(5),
                    wheelInset: inset,
                    frame: frame,
                    onComplete: (_, __) {},
                  ),
                ),
              ),
            ));
            expect(tester.takeException(), isNull,
                reason: '$frame, size $size, inset $inset');
          }
        }
      }
    });

    test('frames have value equality and copyWith', () {
      expect(const WheelFrame.royal(gemCount: 6),
          const WheelFrame.royal(gemCount: 6));
      expect(const WheelFrame.royal(gemCount: 6).hashCode,
          const WheelFrame.royal(gemCount: 6).hashCode);
      expect(const WheelFrame.royal(), isNot(const WheelFrame.neon()));
      const classic = ClassicWheelFrame(rimColor: Colors.blue);
      expect(classic.copyWith(studCount: 3).studCount, 3);
      expect(classic.copyWith(studCount: 3).rimColor, Colors.blue);
      expect(
          const NeonWheelFrame().copyWith(color: Colors.red).color, Colors.red);
      expect(const WoodenWheelFrame().copyWith(handleCount: 4).handleCount, 4);
      expect(const RoyalWheelFrame().copyWith(gemColor: Colors.green),
          const WheelFrame.royal(gemColor: Colors.green));
    });
  });

  group('images', () {
    testWidgets('imageProvider is loaded and drawn', (tester) async {
      await tester.runAsync(() async {
        await _pumpWheel(
            tester,
            SpinnerWheel(
              controller: SpinnerController(),
              segments: [
                WheelSegment('a', 1, imageProvider: _pixel),
                WheelSegment('b', 2),
              ],
              onComplete: (_, __) {},
            ));
        for (int i = 0;
            i < 20 && _state(tester).processedSegments[0].image == null;
            i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      expect(_state(tester).processedSegments[0].image, isNotNull);
      expect(_painter(tester).segments[0].image, isNotNull);
    });

    testWidgets('placeholder while loading, error widget on failure',
        (tester) async {
      Object? reported;
      await tester.runAsync(() async {
        await _pumpWheel(
            tester,
            SpinnerWheel(
              controller: SpinnerController(),
              segments: [
                WheelSegment('a', 1, path: 'assets/does_not_exist.png'),
                WheelSegment('b', 2),
              ],
              imagePlaceholder: const Icon(Icons.hourglass_empty),
              imageErrorWidget: const Icon(Icons.broken_image),
              onImageError: (_, error) => reported = error,
              onComplete: (_, __) {},
            ));
        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
        for (int i = 0; i < 20 && reported == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      await tester.pump();
      expect(reported, isNotNull);
      expect(find.byIcon(Icons.hourglass_empty), findsNothing);
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('editing the list keeps already loaded images', (tester) async {
      final segments = [
        WheelSegment('a', 1, imageProvider: _pixel),
        WheelSegment('b', 2),
      ];
      final controller = SpinnerController();
      await tester.runAsync(() async {
        await _pumpWheel(
            tester,
            SpinnerWheel(
                controller: controller,
                segments: segments,
                onComplete: (_, __) {}));
        for (int i = 0;
            i < 20 && _state(tester).processedSegments[0].image == null;
            i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      final image = _state(tester).processedSegments[0].image;
      expect(image, isNotNull);

      segments.add(WheelSegment('c', 3));
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: controller,
              segments: segments,
              onComplete: (_, __) {}));
      expect(_state(tester).processedSegments.length, 3);
      expect(_state(tester).processedSegments[0].image, same(image));
    });
  });

  group('accessibility', () {
    testWidgets('describes the wheel and announces the result', (tester) async {
      final handle = tester.ensureSemantics();
      final controller = SpinnerController();
      await _pumpWheel(
          tester,
          SpinnerWheel(
            controller: controller,
            segments: [
              WheelSegment('Gold', 1),
              WheelSegment('Silver', 2, semanticLabel: 'Silver prize'),
            ],
            semanticsLabel: 'Prize wheel',
            tapToSpin: true,
            onComplete: (_, __) {},
          ));
      final finder = find.bySemanticsLabel('Prize wheel');
      expect(finder, findsOneWidget);
      expect(
          tester.getSemantics(finder),
          isSemantics(
            label: 'Prize wheel',
            hint: '2 segments: Gold, Silver prize',
            isButton: true,
            isLiveRegion: true,
            hasTapAction: true,
          ));

      controller.spinTo(1);
      await tester.pump();
      expect(tester.getSemantics(finder).getSemanticsData().value, 'Spinning');
      await tester.pumpAndSettle();
      expect(tester.getSemantics(finder),
          isSemantics(value: 'Landed on Silver prize'));
      handle.dispose();
    });

    testWidgets('not a button unless tapToSpin is on', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpWheel(
          tester,
          SpinnerWheel(
              controller: SpinnerController(),
              segments: _segments(2),
              onComplete: (_, __) {}));
      expect(tester.getSemantics(find.bySemanticsLabel('Spinning wheel')),
          isSemantics(isButton: false, hasTapAction: false));
      handle.dispose();
    });
  });
}

/// How far the current spin will turn the wheel, read from the painted
/// transform at the start and end of the animation.
double _plannedTravel(SpinnerWheelState<int> state, {bool signed = false}) {
  final double travelled = state.debugSpinEnd - state.debugSpinStart;
  return signed ? travelled : travelled.abs();
}
