# 🎡 Spinning Wheel - Flutter Package

[![pub package](https://img.shields.io/pub/v/spinning_wheel.svg)](https://pub.dev/packages/spinning_wheel) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![GitHub stars](https://img.shields.io/github/stars/nitesh695/spinning_wheel?style=social)](https://github.com/nitesh695/spinning_wheel)


A fully customizable spinning wheel for Flutter applications! Easily create fortune wheels, prize spinners, or game-based random selectors with smooth animations and custom segments.

## 🌟 Features

- ✅ **Fully customizable spinning wheel** 🎨
- ✅ **Weighted Probability Support** (Control win frequencies) ⚖️
- ✅ **Rigged or server-decided results** with `spinTo(index)` 🎯
- ✅ **Swipe to spin & tap to spin** 👆
- ✅ **Stop button support**, `isSpinning` and results you can `await` ⏱️
- ✅ **Tick callbacks** for sounds and haptics as each slice passes 🔊
- ✅ **Configurable spin**: duration, curve and number of turns 🌀
- ✅ **Indicator on any side**, with an optional flick animation 📍
- ✅ **Slices sized by probability**, flat or gradient fill, borders 🍕
- ✅ **Winner highlight** 💡
- ✅ **4 ready-made frames** (classic, royal, neon, wooden) **or your own** 🛞
- ✅ **Images from assets, URLs or any `ImageProvider`**, with loading and error placeholders 🖼️🌐
- ✅ **Any widget on a slice**, and per-slice text styles ✍️
- ✅ **Advanced Label Styling** (rotation, ellipsis, fade, clipping) 🛡️
- ✅ **Typed values**: `WheelSegment<String>`, `WheelSegment<MyPrize>`… 🧩
- ✅ **Screen reader support** and right-to-left text ♿

## 📸 Preview

<div align="center">
  <img src="https://raw.githubusercontent.com/nitesh695/spinning_wheel/main/example/assets/images/img.png" alt="Spinning Wheel Demo" width="300" style="border-radius: 30px; border: 8px solid #222; box-shadow: 0 10px 30px rgba(0,0,0,0.3);">
</div>

## 📦 Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  spinning_wheel: ^0.1.0
```

Requires Flutter 3.27 or newer.

## 🔧 Usage

### 1️⃣ Import the Package

```dart
import 'package:spinning_wheel/spinning_wheel.dart';
```

### 2️⃣ Create a `SpinnerController`

```dart
final SpinnerController controller = SpinnerController();

@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

### 3️⃣ Define `Wheel Segments`

```dart
final List<WheelSegment<int>> segments = [
  WheelSegment("Jackpot!", 1000, color: Colors.orange, probability: 0.05),
  WheelSegment("Prize 2", 20, color: Colors.blue, probability: 0.3),
  // Supports Network Images! 🌐
  // No probability: shares what's left of 1.0 (here 0.45) with other such segments.
  WheelSegment("Gift", 100, path: "https://example.com/gift_icon.png"),
  WheelSegment("Empty", 0, color: Colors.grey, probability: 0.2),
];
```

### 4️⃣ Add the `SpinnerWheel` Widget

```dart
SpinnerWheel(
  controller: controller,
  segments: segments,
  slicePadding: const EdgeInsets.only(top: 20, bottom: 10, left: 5, right: 5),
  labelStyle: const WheelLabelStyle(
    labelStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    ),
    overflow: TextOverflow.ellipsis, // Auto-handle long text
    maxLines: 1,
    angle: 0.0,
  ),
  onComplete: (result, index) {
    print("You won: ${result.label}!");
  },
),
```

### 5️⃣ Start Spinning!

```dart
controller.startSpin();

// Or wait for the result:
final result = await controller.startSpin();
print('Landed on ${result?.segment.label}');
```

Calling `startSpin()` while the wheel is already spinning does not start a new spin.

## 🎮 Controlling the spin

```dart
// Land on a specific segment, e.g. one decided by your server.
await controller.spinTo(2);

// Bring a spinning wheel to a quick stop on whatever segment it reaches.
controller.stop();

// The controller is a ChangeNotifier, so you can rebuild on changes.
ListenableBuilder(
  listenable: controller,
  builder: (context, _) => ElevatedButton(
    onPressed: controller.isSpinning ? controller.stop : controller.startSpin,
    child: Text(controller.isSpinning ? 'Stop' : 'Spin'),
  ),
);
```

Tune how the wheel spins:

```dart
SpinnerWheel(
  // ...
  spinDuration: const Duration(seconds: 3),
  spinCurve: Curves.easeOutCubic,
  minSpins: 3,
  maxSpins: 6,
  onSpinStart: () => print('Here we go!'),
  // Fires every time a new slice passes the indicator.
  onSegmentPass: (index) => HapticFeedback.selectionClick(),
);
```

The wheel never turns faster than 40% of a slice per frame. Any faster and it looks like it is spinning backwards (the "wagon-wheel" effect). If the requested turns don't fit in `spinDuration` at that speed, the spin makes fewer turns, so wheels with many slices turn fewer times. Use a longer `spinDuration` for more turns. Curves that overshoot, like `Curves.easeOutBack` or `Curves.elasticOut`, turn the wheel backwards at the end on purpose.

## 👆 Interaction

```dart
SpinnerWheel(
  // ...
  tapToSpin: true,      // Tap the center to spin
  swipeToSpin: true,    // Drag the wheel around, fling it to spin
  indicatorPosition: IndicatorPosition.right,
  indicatorBounce: true, // The pointer flicks as slices pass
);
```

A fling spins the wheel in the direction you threw it. The result still follows the segments' probabilities. A custom `indicator` should be designed pointing down; it is rotated to point at the center from whichever side you choose.

## 🎨 Visuals

### 🛞 Frames

The frame around the wheel is painted, not an image, so it stays sharp at any size and scales with the wheel. Pick one of four ready-made frames:

```dart
SpinnerWheel(
  // ...
  frame: const WheelFrame.classic(),  // Red rim, silver teeth, gold studs (default)
  // frame: const WheelFrame.royal(),  // Polished gold with gems and pearls
  // frame: const WheelFrame.neon(),   // Glowing tubes on a dark ring
  // frame: const WheelFrame.wooden(), // A ship's helm with wooden handles
);
```

Each one can be recolored and tuned:

```dart
const WheelFrame.classic(rimColor: Color(0xFF14532D), toothCount: 12, studCount: 12);
const WheelFrame.royal(goldColor: Color(0xFFC0C6CC), gemColor: Color(0xFF1565C0), gemCount: 8);
const WheelFrame.neon(color: Color(0xFF39FF14), secondaryColor: Color(0xFFFFEA00));
const WheelFrame.wooden(woodColor: Color(0xFF5D3A1A), handleCount: 6);
```

Every frame sets how much room it needs around the slices and a matching pointer color. Override them with `wheelInset` and `indicatorColor`. `wheelColor: Colors.purple` is a shortcut for `frame: WheelFrame.classic(rimColor: Colors.purple)`.

#### Your own frame

Paint it yourself with `WheelFrame.custom`. `paintBack` draws behind the slices and `paintFront` over their edge. The `WheelFrameGeometry` tells you where the center, the outer edge and the slices' edge are, so your frame lines up at any size:

```dart
void paintRing(Canvas canvas, WheelFrameGeometry g) {
  canvas.drawPath(
    g.ring(g.sliceRadius, g.outer), // From the slices' edge to the outside
    Paint()..color = Colors.indigo,
  );
}

const myFrame = WheelFrame.custom(
  paintFront: paintRing,
  preferredInset: 0.08,       // Room for the ring
  indicatorColor: Colors.amber,
);
```

Use top-level or static functions (not inline closures) so the frame isn't repainted on every rebuild. For more control, extend `WheelFrame` and override `paintBack`, `paintFront` and `preferredInset`. Helpers like `WheelFrame.paintDropShadow`, `WheelFrame.paintSliceShadow`, `WheelFrame.paintPlate` and `WheelFrame.paintStud` are there to reuse.

To use an image (or any widget) instead, pass it as `background`, and set `wheelInset` to fit its rim:

```dart
SpinnerWheel(
  // ...
  background: Image.asset('assets/my_frame.png', fit: BoxFit.contain),
  wheelInset: 0.094,
);
```

`shouldDrawBackground: false` hides the frame.

### Slices

```dart
SpinnerWheel(
  // ...
  sliceSizing: SliceSizing.proportional, // Slice size matches its chance
  sliceStyle: SliceStyle.flat,           // Or SliceStyle.gradient (default)
  sliceBorderColor: Colors.white,
  sliceBorderWidth: 2,
  highlightWinner: true,                 // Outline the winner, dim the rest
  highlightColor: Colors.yellow,
);
```

Each segment can have its own text style, any widget in place of an image, and any `ImageProvider`:

```dart
WheelSegment('Star', 5, child: const Icon(Icons.star, color: Colors.white)),
WheelSegment('Bold', 10, textStyle: const TextStyle(fontSize: 20)),
WheelSegment('Photo', 15, imageProvider: FileImage(file)),
```

### Image loading

Images appear one by one as they load. Show something while they load or if they fail:

```dart
SpinnerWheel(
  // ...
  imagePlaceholder: const CircularProgressIndicator(strokeWidth: 2),
  imageErrorWidget: const Icon(Icons.broken_image),
  onImageError: (segment, error) => print('${segment.label}: $error'),
);
```

### ⚖️ How probability works

- If no segment sets `probability`, every segment is equally likely.
- Segments without a `probability` share whatever is left of `1.0` equally.
- If the explicit values already add up to `1.0` or more, segments without one can't win.
- With `SliceSizing.proportional`, a segment with probability `0` is not drawn.

### ♿ Accessibility

The wheel is announced to screen readers as "Spinning wheel" (change it with `semanticsLabel`) along with its segments, and announces "Spinning" and the result as they happen. Use `WheelSegment.semanticLabel` for a better description than the label text. With `tapToSpin`, screen reader users can spin it by activating it. Labels follow the app's text direction, so right-to-left text works.

## 🔄 Upgrading from 0.0.x

`WheelSegment` and `SpinnerWheel` now take a type for the segment value. If you wrote the list type without one, `value` becomes `dynamic`:

```dart
// Before: value was always an int
List<WheelSegment> segments = [...];
_score += win.value; // Error now: can't assign num to int

// After: say what the values are
List<WheelSegment<int>> segments = [...];
```

In widget tests, `find.byType(SpinnerWheel)` only matches `SpinnerWheel<dynamic>`. Use `find.byType(SpinnerWheel<int>)` or `find.byWidgetPredicate((w) => w is SpinnerWheel)`.

## 📜 API Reference

### SpinnerWheel

| Property            | Type                     | Description                                     | Default    |
|---------------------|--------------------------|-------------------------------------------------|------------|
| `controller`        | `SpinnerController`      | Controls the spin animation                     | Required   |
| `segments`          | `List<WheelSegment<T>>`  | List of wheel segments (labels, colors, images) | Required   |
| `onComplete`        | `void Function(WheelSegment<T>, int)` | Called when a spin completes       | Required   |
| `onSpinStart`       | `VoidCallback?`          | Called when a spin starts                       | Optional   |
| `onSegmentPass`     | `void Function(int)?`    | Called for every slice that passes the indicator | Optional   |
| `spinDuration`      | `Duration`               | How long a spin takes                           | 5 seconds  |
| `spinCurve`         | `Curve`                  | Easing of a spin                                | `decelerate` |
| `minSpins` / `maxSpins` | `int`                | Range of whole turns per spin                   | `5` / `9`  |
| `tapToSpin`         | `bool`                   | Tap the center to spin                          | `false`    |
| `swipeToSpin`       | `bool`                   | Drag and fling to spin                          | `false`    |
| `indicatorPosition` | `IndicatorPosition`      | Side the indicator sits on                      | `top`      |
| `indicatorBounce`   | `bool`                   | Indicator flicks as slices pass                 | `false`    |
| `sliceSizing`       | `SliceSizing`            | `equal` or `proportional` slice sizes           | `equal`    |
| `sliceStyle`        | `SliceStyle`             | `gradient` or `flat` fill                       | `gradient` |
| `sliceBorderColor`  | `Color?`                 | Color of slice dividers and outer ring          | white      |
| `sliceBorderWidth`  | `double`                 | Width of slice dividers and outer ring          | `0` (none) |
| `highlightWinner`   | `bool`                   | Highlight the winning slice after a spin        | `false`    |
| `highlightColor`    | `Color`                  | Outline color of the winning slice              | white      |
| `imagePlaceholder`  | `Widget?`                | Shown while a segment image loads               | Optional   |
| `imageErrorWidget`  | `Widget?`                | Shown if a segment image fails to load          | Optional   |
| `onImageError`      | `void Function(WheelSegment<T>, Object)?` | Called when an image fails to load | Optional |
| `semanticsLabel`    | `String?`                | Screen reader label for the wheel               | `Spinning wheel` |
| `labelStyle`        | `WheelLabelStyle?`       | Advanced styling for segment labels             | Optional   |
| `slicePadding`      | `EdgeInsets`             | Padding inside slices (rim, center, and sides)  | `zero`     |
| `imageWidth` / `imageHeight` | `double?`       | Size of segment images and widgets              | 11% of wheel |
| `frame`             | `WheelFrame?`            | The frame around the wheel                      | `WheelFrame.classic()` |
| `wheelColor`        | `Color?`                 | Rim color of the classic frame (shortcut)       | Optional   |
| `wheelInset`        | `double?`                | Gap between wheel edge and segments (fraction of size) | the frame's own |
| `indicatorColor`    | `Color?`                 | Color of the default indicator                  | the frame's own, or red |
| `centerChild`       | `Widget?`                | Custom widget for the wheel center              | Optional   |
| `indicator`         | `Widget?`                | Custom widget for the indicator                 | Optional   |
| `background`        | `Widget?`                | Custom widget in place of the frame             | Optional   |
| `shouldDrawBackground`| `bool`                 | Show the frame (or `background`)                | `true`     |

### SpinnerController

| Member          | Description                                                        |
|-----------------|--------------------------------------------------------------------|
| `startSpin()`   | Spins using the probabilities; completes with the `WheelSpinResult` |
| `spinTo(index)` | Spins and lands on the segment at `index`                          |
| `stop()`        | Quickly stops a spinning wheel                                     |
| `isSpinning`    | Whether the wheel is spinning                                      |
| `lastResult`    | The result of the last finished spin                               |
| `isAttached`    | Whether a wheel is using this controller                           |

### WheelSegment

| Property        | Type             | Description                                          |
|-----------------|------------------|------------------------------------------------------|
| `label`         | `String`         | Text shown on the slice (required)                   |
| `value`         | `T`              | Your value for this slice (required)                 |
| `color`         | `Color?`         | Slice color; picked from the label if not set        |
| `probability`   | `double?`        | Chance of winning (see above)                        |
| `path`          | `String?`        | Asset path or `http(s)` URL of the slice image       |
| `imageProvider` | `ImageProvider?` | Any image provider; takes precedence over `path`     |
| `child`         | `Widget?`        | A widget shown in place of the image                 |
| `textStyle`     | `TextStyle?`     | Merged on top of the wheel's label style             |
| `semanticLabel` | `String?`        | Screen reader description; defaults to `label`       |

### Frames

| Frame | Options |
|-------|---------|
| `WheelFrame.classic()` | `rimColor`, `rimHighlightColor`, `trimColor`, `studColor`, `toothCount`, `studCount`, `plateColor`, `shadow` |
| `WheelFrame.royal()`   | `goldColor`, `gemColor`, `gemCount`, `plateColor`, `shadow` |
| `WheelFrame.neon()`    | `color`, `secondaryColor`, `plateColor` |
| `WheelFrame.wooden()`  | `woodColor`, `brassColor`, `handleCount`, `shadow` |
| `WheelFrame.custom()`  | `paintFront`, `paintBack`, `preferredInset`, `indicatorColor` |

### WheelLabelStyle

| Property     | Type          | Description                                           | Default |
|--------------|---------------|-------------------------------------------------------|---------|
| `labelStyle` | `TextStyle?`  | The theme/style of the text                           | Default |
| `angle`      | `double`      | Additional rotation for the text (in radians)         | `0.0`   |
| `overflow`   | `TextOverflow`| Long text handling: `clip`, `ellipsis` and `fade` keep the label inside its slice, `visible` lets it overflow | `clip`  |
| `maxLines`   | `int?`        | Maximum number of lines for the label                 | `1`     |

## 📄 License

This package is licensed under the **MIT License**.

## 🙏 Support

If you like this package, ⭐ **Star it on [GitHub](https://github.com/nitesh695/spinning_wheel)**!  
For issues or feature requests, open an issue on [GitHub](https://github.com/nitesh695/spinning_wheel/issues).
