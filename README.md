# 🎡 Spinning Wheel for Flutter

[![pub package](https://img.shields.io/pub/v/spinning_wheel.svg)](https://pub.dev/packages/spinning_wheel)
[![pub points](https://img.shields.io/pub/points/spinning_wheel)](https://pub.dev/packages/spinning_wheel/score)
[![likes](https://img.shields.io/pub/likes/spinning_wheel)](https://pub.dev/packages/spinning_wheel/score)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/nitesh695/spinning_wheel?style=social)](https://github.com/nitesh695/spinning_wheel)

A customizable, animated **spinning wheel** widget for Flutter: build a **fortune wheel**, **wheel of fortune**, **prize wheel**, **lucky draw**, **spin-to-win** promotion or **random picker** in a few lines. Weighted odds, server-decided results, swipe to spin, haptic ticks, four ready-made frames, and it stays sharp and smooth at any size.

<div align="center">
  <img src="https://raw.githubusercontent.com/nitesh695/spinning_wheel/main/example/assets/images/img.png" alt="Spinning wheel demo" width="300">
</div>

## Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quick start](#-quick-start)
- [Segments and probability](#-segments-and-probability)
- [Controlling the spin](#-controlling-the-spin)
- [How the spin feels](#-how-the-spin-feels)
- [Interaction](#-interaction)
- [Frames](#-frames)
- [Slices and labels](#-slices-and-labels)
- [Images and widgets on slices](#-images-and-widgets-on-slices)
- [Accessibility](#-accessibility)
- [Recipes](#-recipes)
- [API reference](#-api-reference)
- [Upgrading from 0.0.x](#-upgrading-from-00x)
- [Example app](#-example-app)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

**Spinning**
- 🎯 Weighted probabilities, or equal odds by default
- 🖥️ Land on a result chosen in advance (for example by your server) with `spinTo(index)`
- ⏹️ Stop a spin early, and `await` the result of any spin
- 🌀 Choose the duration, easing curve and number of turns
- 👀 Never looks like it is spinning backwards: speed is kept below the "wagon-wheel" effect

**Interaction**
- 👆 Tap the center to spin
- 🤚 Drag the wheel around, and fling it to spin in that direction
- 🔊 A callback for every slice that passes the pointer, for tick sounds and haptics
- 📍 Put the pointer on any side, with an optional flick animation

**Look**
- 🛞 Four ready-made frames: classic, royal gold, neon and wooden ship's helm. You can also paint your own or use an image.
- 🍕 Equal slices, or slices sized by their chance of winning
- 🎨 Gradient or flat slices, slice borders, winner highlight
- 🖼️ Images from assets, URLs or any `ImageProvider`, with loading and error placeholders
- 🧩 Any widget on a slice, and a text style per slice
- ✍️ Label rotation, wrapping, ellipsis, fading and clipping

**Developer friendly**
- 🔤 Typed values: `WheelSegment<String>`, `WheelSegment<MyPrize>`, ...
- 📐 Responsive: fills the space it's given and scales everything with it
- ♿ Screen reader support and right-to-left text
- 📱 Pure Flutter, works on Android, iOS, web, macOS, Windows and Linux

## 📦 Installation

```sh
flutter pub add spinning_wheel
```

Or add it to your `pubspec.yaml` yourself:

```yaml
dependencies:
  spinning_wheel: ^1.0.0
```

Requires Flutter 3.27 (Dart 3.6) or newer. Then import it:

```dart
import 'package:spinning_wheel/spinning_wheel.dart';
```

## 🚀 Quick start

A complete screen with a wheel and a button:

```dart
import 'package:flutter/material.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

class PrizeWheelPage extends StatefulWidget {
  const PrizeWheelPage({super.key});

  @override
  State<PrizeWheelPage> createState() => _PrizeWheelPageState();
}

class _PrizeWheelPageState extends State<PrizeWheelPage> {
  final SpinnerController _controller = SpinnerController();

  final List<WheelSegment<int>> _segments = [
    WheelSegment('100', 100, color: Colors.red),
    WheelSegment('200', 200, color: Colors.blue),
    WheelSegment('500', 500, color: Colors.green),
    WheelSegment('Try again', 0, color: Colors.grey),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 320,
            height: 320,
            child: SpinnerWheel<int>(
              controller: _controller,
              segments: _segments,
              onComplete: (segment, index) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('You won ${segment.label}!')),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _controller.startSpin,
            child: const Text('Spin'),
          ),
        ],
      ),
    );
  }
}
```

The wheel fills the space its parent gives it, so give it a size (a `SizedBox`, `Expanded`, `AspectRatio`, ...). With no size limit at all, it uses 300 × 300.

## 🎯 Segments and probability

Each `WheelSegment` has a label, a value of any type, and optional color, probability, image, widget and text style:

```dart
final segments = [
  WheelSegment('Jackpot', 1000, color: Colors.amber, probability: 0.05),
  WheelSegment('Prize', 20, color: Colors.blue, probability: 0.30),
  WheelSegment('Gift', 100, path: 'https://example.com/gift.png'),
  WheelSegment('Nothing', 0, color: Colors.grey, probability: 0.20),
];
```

How the winner is picked:

- If no segment sets `probability`, every segment is equally likely.
- Segments without a `probability` share whatever is left of `1.0` equally. Above, "Gift" gets the remaining `0.45`.
- If the explicit values already add up to `1.0` or more, segments without one can't win.
- Negative values count as `0`.
- Results use `Random.secure()`.

Without a `color`, a segment gets one picked from its label and value, so it stays the same across rebuilds.

## 🎮 Controlling the spin

`SpinnerController` starts, steers and stops the wheel:

```dart
// Spin using the probabilities. Completes when the wheel stops.
final WheelSpinResult? result = await controller.startSpin();
print('Landed on ${result?.segment.label} (index ${result?.index})');

// Land on a specific segment, e.g. one your server decided.
await controller.spinTo(2);

// Bring a spinning wheel to a quick stop on whatever it reaches.
controller.stop();
```

The controller is a `ChangeNotifier`, so you can rebuild on `isSpinning` and `lastResult`:

```dart
ListenableBuilder(
  listenable: controller,
  builder: (context, _) => FilledButton(
    onPressed: controller.isSpinning ? controller.stop : controller.startSpin,
    child: Text(controller.isSpinning ? 'Stop' : 'Spin'),
  ),
);
```

Good to know:

- Calling `startSpin()` or `spinTo()` while the wheel is spinning doesn't start a new spin; it returns the current spin's result.
- `onComplete` is called when the wheel stops, before the future completes.
- If the wheel is removed mid-spin, the future completes with `null`.
- Dispose the controller when you're done with it.

## 🌀 How the spin feels

```dart
SpinnerWheel(
  // ...
  spinDuration: const Duration(seconds: 4),
  spinCurve: Curves.easeOutCubic,   // Default: Curves.decelerate
  minSpins: 3,                      // Whole turns before stopping
  maxSpins: 6,
  onSpinStart: () => print('Spinning...'),
  onSegmentPass: (index) => HapticFeedback.selectionClick(),
);
```

`onSegmentPass` fires for every slice that passes the pointer, in order, even when frames are dropped, so it's reliable for tick sounds and haptics.

**Why the wheel sometimes makes fewer turns than `minSpins`.** On a screen that redraws 60 times a second, a wheel turning more than half a slice per frame looks like it's turning backwards (the "wagon-wheel" effect). The wheel never turns faster than 40% of a slice per frame. If the requested turns don't fit into `spinDuration` at that speed, it makes fewer turns, so wheels with many slices turn fewer times. A longer `spinDuration` allows more turns. Curves that overshoot, like `Curves.easeOutBack` or `Curves.elasticOut`, do turn backwards at the end on purpose.

## 👆 Interaction

```dart
SpinnerWheel(
  // ...
  tapToSpin: true,                            // Tap the center to spin
  swipeToSpin: true,                          // Drag the wheel; fling it to spin
  indicatorPosition: IndicatorPosition.right, // top, right, bottom or left
  indicatorBounce: true,                      // The pointer flicks as slices pass
);
```

- A fling spins the wheel in the direction it was thrown, and the result still follows the probabilities.
- A slow drag just turns the wheel.
- A custom `indicator` widget should be designed pointing down; it's rotated to point at the center from whichever side you choose.
- If the wheel sits inside a scrolling list, `swipeToSpin` competes with the list for drags.

## 🛞 Frames

The frame around the wheel is painted, not an image, so it stays sharp at any size and scales with the wheel. There are four ready-made frames:

```dart
frame: const WheelFrame.classic(), // Red rim, silver teeth, gold studs (default)
frame: const WheelFrame.royal(),   // Polished gold set with gems and pearls
frame: const WheelFrame.neon(),    // Two glowing tubes on a dark ring
frame: const WheelFrame.wooden(),  // A ship's helm with turned wooden handles
```

Each one can be recolored and tuned:

```dart
const WheelFrame.classic(
    rimColor: Color(0xFF14532D), toothCount: 12, studCount: 12);
const WheelFrame.royal(
    goldColor: Color(0xFFC0C6CC), gemColor: Color(0xFF1565C0), gemCount: 8);
const WheelFrame.neon(
    color: Color(0xFF39FF14), secondaryColor: Color(0xFFFFEA00));
const WheelFrame.wooden(woodColor: Color(0xFF5D3A1A), handleCount: 6);
```

Every frame decides how much room it needs around the slices and suggests a matching pointer color. Override them with `wheelInset` and `indicatorColor`. `wheelColor: Colors.purple` is a shortcut for `frame: WheelFrame.classic(rimColor: Colors.purple)`.

### Paint your own frame

`WheelFrame.custom` takes painting functions. `paintBack` draws behind the slices and `paintFront` over their edge. The `WheelFrameGeometry` gives you the center, the outer edge and the slices' edge, so your frame lines up at any size:

```dart
void paintRing(Canvas canvas, WheelFrameGeometry g) {
  canvas.drawPath(
    g.ring(g.sliceRadius, g.outer), // From the slices' edge to the outside
    Paint()..color = Colors.indigo,
  );
}

const myFrame = WheelFrame.custom(
  paintFront: paintRing,
  preferredInset: 0.08, // Room for the ring, as a fraction of the size
  indicatorColor: Colors.amber,
);
```

- Use top-level or static functions, not inline closures, so the frame isn't repainted on every rebuild.
- For full control, extend `WheelFrame` and override `paintBack`, `paintFront` and `preferredInset`.
- `WheelFrame.paintDropShadow`, `paintSliceShadow`, `paintPlate` and `paintStud` are there to reuse.

### Use an image or any widget

```dart
SpinnerWheel(
  // ...
  background: Image.asset('assets/my_frame.png', fit: BoxFit.contain),
  wheelInset: 0.094, // Match the image's rim
);
```

`shouldDrawBackground: false` hides the frame completely.

## 🍕 Slices and labels

```dart
SpinnerWheel(
  // ...
  sliceSizing: SliceSizing.proportional, // Slice size matches its chance
  sliceStyle: SliceStyle.flat,           // Or SliceStyle.gradient (default)
  sliceBorderColor: Colors.white,
  sliceBorderWidth: 2,
  highlightWinner: true,                 // Outline the winner, dim the rest
  highlightColor: Colors.yellow,
  slicePadding: const EdgeInsets.only(top: 8, left: 4, right: 4),
  labelStyle: const WheelLabelStyle(
    labelStyle: TextStyle(color: Colors.white, fontSize: 14),
    overflow: TextOverflow.ellipsis, // clip, ellipsis, fade or visible
    maxLines: 2,
    angle: 0.0,                      // Extra rotation, in radians
  ),
);
```

- With `SliceSizing.proportional`, a segment with probability `0` isn't drawn.
- `clip`, `ellipsis` and `fade` keep each label inside its slice; `visible` lets it overflow.
- `slicePadding.top` moves labels and images toward the center, `bottom` toward the rim, and `left`/`right` narrow the label.

## 🧩 Images and widgets on slices

```dart
WheelSegment('Lion', 1, path: 'assets/lion.png'),               // Asset
WheelSegment('Gift', 2, path: 'https://example.com/gift.png'),  // URL
WheelSegment('Photo', 3, imageProvider: FileImage(file)),       // Any ImageProvider
WheelSegment('Star', 4, child: const Icon(Icons.star)),         // Any widget
WheelSegment('Big', 5, textStyle: const TextStyle(fontSize: 22)),
```

- Images load in parallel and appear as they arrive.
- Asset images use the device's 2x/3x versions.
- Set the size with `imageWidth` and `imageHeight`.

Show something while they load, or if they fail:

```dart
SpinnerWheel(
  // ...
  imagePlaceholder: const CircularProgressIndicator(strokeWidth: 2),
  imageErrorWidget: const Icon(Icons.broken_image),
  onImageError: (segment, error) => debugPrint('${segment.label}: $error'),
);
```

On the web, network images need the server to allow cross-origin requests (CORS).

## ♿ Accessibility

- **Screen readers:** the wheel is announced as "Spinning wheel" (change it with `semanticsLabel`) along with its segments. While it spins it announces "Spinning", and then the result.
- **Better descriptions:** use `WheelSegment.semanticLabel` when the label text alone isn't clear.
- **Spinning without sight:** with `tapToSpin`, screen reader users can spin the wheel by activating it.
- **Right-to-left text:** labels follow the app's text direction.

## 🍳 Recipes

**Prize decided by your server**

```dart
final int prizeIndex = await api.claimPrize(); // Your backend picks the prize
final WheelSpinResult? result = await controller.spinTo(prizeIndex);
showPrize(result!.segment.value);
```

**Random name picker or decision maker**

```dart
final names = ['Alice', 'Bob', 'Chen', 'Dana'];
SpinnerWheel<String>(
  controller: controller,
  segments: [for (final n in names) WheelSegment(n, n)],
  tapToSpin: true,
  swipeToSpin: true,
  highlightWinner: true,
  onComplete: (segment, _) => print('Picked ${segment.value}'),
);
```

**Coupon codes with your own type**

```dart
class Coupon {
  final String code;
  const Coupon(this.code);
}

SpinnerWheel<Coupon>(
  controller: controller,
  segments: [
    WheelSegment('10% off', const Coupon('TEN'), probability: 0.6),
    WheelSegment('Free ship', const Coupon('SHIP'), probability: 0.3),
    WheelSegment('50% off', const Coupon('HALF'), probability: 0.1),
  ],
  sliceSizing: SliceSizing.proportional,
  onComplete: (segment, _) => applyCoupon(segment.value.code),
);
```

**Tick sound on every slice**

```dart
SpinnerWheel(
  // ...
  indicatorBounce: true,
  onSegmentPass: (_) {
    HapticFeedback.selectionClick();
    tickPlayer.play(); // e.g. from the audioplayers package
  },
);
```

## 📖 API reference

### SpinnerWheel

**Required**

| Property | Type | Description |
|---|---|---|
| `controller` | `SpinnerController` | Starts, steers and stops the wheel |
| `segments` | `List<WheelSegment<T>>` | The slices |
| `onComplete` | `void Function(WheelSegment<T>, int)` | Called when a spin ends, with the winner and its index |

**Spinning**

| Property | Type | Default | Description |
|---|---|---|---|
| `spinDuration` | `Duration` | 5 seconds | How long a spin takes |
| `spinCurve` | `Curve` | `Curves.decelerate` | Easing of button and tap spins |
| `minSpins` / `maxSpins` | `int` | `5` / `9` | Range of whole turns per spin |
| `onSpinStart` | `VoidCallback?` | | Called when any spin starts |
| `onSegmentPass` | `void Function(int)?` | | Called for every slice that passes the pointer |

**Interaction**

| Property | Type | Default | Description |
|---|---|---|---|
| `tapToSpin` | `bool` | `false` | Tap the center to spin |
| `swipeToSpin` | `bool` | `false` | Drag the wheel and fling it to spin |
| `indicatorPosition` | `IndicatorPosition` | `top` | Side the pointer sits on |
| `indicatorBounce` | `bool` | `false` | Pointer flicks as slices pass |

**Frame**

| Property | Type | Default | Description |
|---|---|---|---|
| `frame` | `WheelFrame?` | `WheelFrame.classic()` | The frame around the wheel |
| `wheelColor` | `Color?` | | Rim color of the classic frame |
| `wheelInset` | `double?` | the frame's | Gap between the wheel's edge and the slices, as a fraction of its size |
| `background` | `Widget?` | | A widget (e.g. an image) in place of the frame |
| `shouldDrawBackground` | `bool` | `true` | Show the frame or `background` |

**Slices and labels**

| Property | Type | Default | Description |
|---|---|---|---|
| `sliceSizing` | `SliceSizing` | `equal` | `equal`, or `proportional` to probability |
| `sliceStyle` | `SliceStyle` | `gradient` | `gradient` or `flat` fill |
| `sliceBorderColor` | `Color?` | white | Color of slice dividers and outer ring |
| `sliceBorderWidth` | `double` | `0` | Width of slice dividers and outer ring |
| `highlightWinner` | `bool` | `false` | Outline the winning slice after a spin |
| `highlightColor` | `Color` | white | Outline color of the winning slice |
| `labelStyle` | `WheelLabelStyle?` | | Text style, rotation and overflow of labels |
| `slicePadding` | `EdgeInsets` | `zero` | Padding for labels and images inside slices |

**Images**

| Property | Type | Default | Description |
|---|---|---|---|
| `imageWidth` / `imageHeight` | `double?` | 11% of the wheel | Size of slice images and widgets |
| `imagePlaceholder` | `Widget?` | | Shown while an image loads |
| `imageErrorWidget` | `Widget?` | | Shown if an image fails to load |
| `onImageError` | `void Function(WheelSegment<T>, Object)?` | | Called when an image fails to load |

**Pointer, center and accessibility**

| Property | Type | Default | Description |
|---|---|---|---|
| `indicator` | `Widget?` | | Custom pointer, designed pointing down |
| `indicatorColor` | `Color?` | the frame's, or red | Color of the default pointer |
| `centerChild` | `Widget?` | | Custom widget in the center hub |
| `semanticsLabel` | `String?` | `Spinning wheel` | Screen reader label |

### SpinnerController

| Member | Description |
|---|---|
| `Future<WheelSpinResult?> startSpin()` | Spins using the probabilities |
| `Future<WheelSpinResult?> spinTo(int index)` | Spins and lands on `index` |
| `void stop()` | Quickly stops a spinning wheel |
| `bool isSpinning` | Whether the wheel is spinning |
| `WheelSpinResult? lastResult` | The result of the last finished spin |
| `bool isAttached` | Whether a wheel is using this controller |

### WheelSegment\<T\>

| Property | Type | Description |
|---|---|---|
| `label` | `String` | Text on the slice (required) |
| `value` | `T` | Your value for this slice (required) |
| `color` | `Color?` | Slice color; picked from the label if not set |
| `probability` | `double?` | Chance of winning (see [probability](#-segments-and-probability)) |
| `path` | `String?` | Asset path or `http(s)` URL of the slice image |
| `imageProvider` | `ImageProvider?` | Any image provider; takes precedence over `path` |
| `child` | `Widget?` | A widget shown in place of the image |
| `textStyle` | `TextStyle?` | Merged on top of the wheel's label style |
| `semanticLabel` | `String?` | Screen reader description; defaults to `label` |

### WheelLabelStyle

| Property | Type | Default | Description |
|---|---|---|---|
| `labelStyle` | `TextStyle?` | bold, sized to the wheel | Text style of the labels |
| `angle` | `double` | `0.0` | Extra rotation of the text, in radians |
| `overflow` | `TextOverflow` | `clip` | `clip`, `ellipsis`, `fade` or `visible` |
| `maxLines` | `int?` | `1` | Maximum lines per label |

### WheelSpinResult\<T\>

| Property | Type | Description |
|---|---|---|
| `segment` | `WheelSegment<T>` | The segment the wheel landed on |
| `index` | `int` | Its index in `segments` |

### Frames

| Frame | Options |
|---|---|
| `WheelFrame.classic()` | `rimColor`, `rimHighlightColor`, `trimColor`, `studColor`, `toothCount`, `studCount`, `plateColor`, `shadow` |
| `WheelFrame.royal()` | `goldColor`, `gemColor`, `gemCount`, `plateColor`, `shadow` |
| `WheelFrame.neon()` | `color`, `secondaryColor`, `plateColor` |
| `WheelFrame.wooden()` | `woodColor`, `brassColor`, `handleCount`, `shadow` |
| `WheelFrame.custom()` | `paintFront`, `paintBack`, `preferredInset`, `indicatorColor` |

## 🔄 Upgrading from 0.0.x

Version 1.0.0 has a few breaking changes. See the [changelog](CHANGELOG.md) for everything.

**Segment values are typed.** If you wrote the list type without one, `value` becomes `dynamic`:

```dart
// Before: value was always an int
List<WheelSegment> segments = [...];
score += win.value; // Error now: can't assign num to int

// After: say what the values are
List<WheelSegment<int>> segments = [...];
```

**Widget tests.** `find.byType(SpinnerWheel)` only matches `SpinnerWheel<dynamic>`. Use `find.byType(SpinnerWheel<int>)` or `find.byWidgetPredicate((w) => w is SpinnerWheel)`.

**Other changes**
- `startSpin()` now completes when the wheel stops, not right away.
- The frame is painted instead of an image, and `wheelColor` sets its rim color.
- The default `spinCurve` is `Curves.decelerate`.

## 📱 Example app

The [example](example) app has five demos:

- **Prize game:** a complete game.
- **Playground:** a live control for every option.
- **Frames:** a gallery of all the frames.
- **Server-decided result:** spins to a result picked in advance.
- **Custom segments:** typed values, widgets and images on slices.

```sh
cd example
flutter run
```

## 🤝 Contributing

Bug reports, ideas and pull requests are welcome on [GitHub](https://github.com/nitesh695/spinning_wheel/issues). If this package helps you, please give it a ⭐ on [GitHub](https://github.com/nitesh695/spinning_wheel) and a 👍 on [pub.dev](https://pub.dev/packages/spinning_wheel).

## 📄 License

MIT. See [LICENSE](LICENSE).

---

**Keywords:** flutter spinning wheel, fortune wheel, wheel of fortune, spin the wheel, prize wheel, lucky wheel, lucky draw, spin to win, roulette wheel, random picker, random name picker, decision wheel, raffle, giveaway, gamification, rewards, coupon wheel.

#flutter #dart #flutterpackage #flutterwidget #spinningwheel #spinwheel #fortunewheel #wheeloffortune #spinthewheel #luckywheel #luckydraw #prizewheel #spintowin #roulette #randompicker #decisionwheel #giveaway #raffle #gamification #flutterui #flutteranimation #mobilegame
