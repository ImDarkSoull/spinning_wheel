import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spinning_wheel/spinning_wheel.dart';
import 'package:spinning_wheel_example/main.dart';
import 'package:spinning_wheel_example/screens/custom_segments_screen.dart';
import 'package:spinning_wheel_example/screens/game_screen.dart';
import 'package:spinning_wheel_example/screens/playground_screen.dart';
import 'package:spinning_wheel_example/screens/server_result_screen.dart';

/// Image placeholders keep animating while images load, so these tests pump
/// fixed amounts of time instead of using pumpAndSettle.
Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
}

/// Scrolls [finder] into view, then taps it.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  // Lists build lazily, so scroll until the widget exists at all.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 200,
        scrollable: find.byType(Scrollable).last);
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Finder get _wheel => find.byWidgetPredicate((w) => w is SpinnerWheel);

void main() {
  testWidgets('home lists every demo and opens them', (tester) async {
    await _pumpScreen(tester, const HomeScreen());
    for (final title in [
      'Prize game',
      'Playground',
      'Server-decided result',
      'Custom segments',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 100);
      expect(find.text(title), findsOneWidget);
    }
    await _tapVisible(tester, find.text('Playground'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PlaygroundScreen), findsOneWidget);
  });

  group('game', () {
    testWidgets('spinning uses up a spin and shows the result', (tester) async {
      await _pumpScreen(tester, const GameScreen());
      expect(find.text('spin the wheel'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.text('spin!'));
      await tester.pump();
      expect(find.text('Spinning...'), findsOneWidget);
      expect(find.text('stop!'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      expect(find.text('spin!'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data!.startsWith('you won') || w.data == 'you lost All')),
        findsOneWidget,
      );
    });

    testWidgets('the stop button ends a spin early', (tester) async {
      await _pumpScreen(tester, const GameScreen());
      await tester.tap(find.text('spin!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('stop!'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('spin!'), findsOneWidget);
      expect(find.text('Spinning...'), findsNothing);
    });

    testWidgets('tapping the center also spins', (tester) async {
      await _pumpScreen(tester, const GameScreen());
      await tester.tapAt(tester.getCenter(_wheel));
      await tester.pump();
      expect(find.text('Spinning...'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('playground', () {
    testWidgets('spins with the default options and counts ticks',
        (tester) async {
      await _pumpScreen(tester, const PlaygroundScreen());
      expect(find.textContaining('Ticks: 0'), findsOneWidget);
      await tester.tap(find.text('spin!'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(find.textContaining('Ticks: 0'), findsNothing);
      expect(find.textContaining('Last: –'), findsNothing);
    });

    testWidgets('changing options rebuilds the wheel', (tester) async {
      await _pumpScreen(tester, const PlaygroundScreen());
      final wheel = tester.widget<SpinnerWheel<int>>(_wheel);
      expect(wheel.indicatorPosition, IndicatorPosition.top);
      expect(wheel.segments, hasLength(6));

      await _tapVisible(tester, find.text('right'));
      await tester.pump();
      expect(tester.widget<SpinnerWheel<int>>(_wheel).indicatorPosition,
          IndicatorPosition.right);

      await _tapVisible(tester, find.text('by probability'));
      await tester.pump();
      expect(tester.widget<SpinnerWheel<int>>(_wheel).sliceSizing,
          SliceSizing.proportional);
    });

    testWidgets('segments are not recreated on unrelated rebuilds',
        (tester) async {
      await _pumpScreen(tester, const PlaygroundScreen());
      final before = tester.widget<SpinnerWheel<int>>(_wheel).segments;
      await _tapVisible(tester, find.text('right'));
      await tester.pump();
      expect(tester.widget<SpinnerWheel<int>>(_wheel).segments, same(before));
    });
  });

  testWidgets('server result: the wheel lands on the picked prize',
      (tester) async {
    await _pumpScreen(tester, const ServerResultScreen());
    await _tapVisible(tester, find.widgetWithText(ActionChip, '20% off'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.textContaining('landed on "20% off" ✓'), findsOneWidget);
    expect(find.textContaining('Code: TWENTY'), findsOneWidget);

    await _tapVisible(tester, find.text('Ask server'));
    await tester.pump();
    expect(find.text('Contacting server...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 5));
    expect(find.textContaining('Server picked'), findsOneWidget);
    expect(find.textContaining('✓'), findsOneWidget);
  });

  testWidgets('custom segments: shows the widget slice and the reward',
      (tester) async {
    await _pumpScreen(tester, const CustomSegmentsScreen());
    // The "Star" slice shows its Icon child on the wheel.
    expect(find.descendant(of: _wheel, matching: find.byIcon(Icons.star)),
        findsOneWidget);

    tester.widget<SpinnerWheel<Reward>>(_wheel).controller.spinTo(0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('You won: Star'), findsOneWidget);
    expect(find.text('Code: STAR-30'), findsOneWidget);
  });
}
