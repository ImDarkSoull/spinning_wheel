## 0.0.1
* initial draft of the fortune wheel.

## 0.0.2
* SetState issue of view fixed.

## 0.0.3
* Wheel responsiveness is fixed.

## 0.0.4
* Added `background` parameter to `SpinnerWheel` for custom background widgets.
* Added `shouldDrawBackground` to toggle background visibility.
* Added weighted probability support (`probability` field in `WheelSegment`).
* Added performance optimizations (`RepaintBoundary`) for smoother animations.
* Made `color` optional in `WheelSegment` (defaults to random color).

## 0.0.5
* **Dual Image Support**: Pass both local asset paths and Network URLs (e.g., `https://...`) to `WheelSegment`.
* Improved `image_loader` logic to automatically detect and fetch network images.
* **Documentation Update**: Added comprehensive Dartdoc comments to improve pub.dev score.

## 0.0.6
* **Advanced Label Styling**: Introduced `WheelLabelStyle` class for professional label configuration.
* **Text Rotation**: Added `angle` support in `WheelLabelStyle` to allow manual rotation of segment labels.
* **Refactoring**: Renamed `labelStyle` and `labelDesignConfig` to a unified `WheelLabelStyle` object.

## 0.0.7
* **Automatic Text Clipping**: Added `overflow` and `maxLines` to `WheelLabelStyle` for smart label containment.
* **Slice Padding**: Upgraded `slicePadding` to use `EdgeInsets` for precise radial and horizontal control inside segments.
* **Layout Optimization**: Text labels now automatically calculate available width to prevent slice overlapping.

## 1.0.0
**Breaking changes**
* `WheelSegment<T>` and `SpinnerWheel<T>` are generic over the segment value. Lists typed as `List<WheelSegment>` now have `dynamic` values; use `List<WheelSegment<int>>`. See "Upgrading from 0.0.x" in the README.
* Requires Flutter 3.27 / Dart 3.6 or newer.
* `startSpin()` now completes when the wheel stops, with a `WheelSpinResult`, instead of right away.
* The wheel's frame is now painted instead of an image, so it stays sharp at any size. `wheelColor` sets the frame's rim color. The `assets/wheel.png` image was removed (about 1 MB less in apps).
* Segments without a `color` get a stable color based on their label and value instead of a random one.
* The default `spinCurve` is now `Curves.decelerate`, and spins are limited to 40% of a slice per frame, so the wheel no longer appears to spin backwards at high speed. Wheels with many slices may make fewer turns than `minSpins`; a longer `spinDuration` allows more.

**New**
* `SpinnerController` is a `ChangeNotifier` with `isSpinning`, `lastResult`, `isAttached`, `spinTo(index)` and `stop()`.
* `spinDuration`, `spinCurve`, `minSpins` and `maxSpins` to tune spins.
* `onSpinStart` and `onSegmentPass` callbacks.
* `tapToSpin` and `swipeToSpin` (drag and fling the wheel).
* `indicatorPosition` (top, right, bottom, left) and `indicatorBounce`.
* `sliceSizing` (slices sized by probability), `sliceStyle` (flat or gradient), `sliceBorderColor` and `sliceBorderWidth`.
* `highlightWinner` and `highlightColor`.
* Per-segment `child` widget, `imageProvider`, `textStyle` and `semanticLabel`.
* `imagePlaceholder`, `imageErrorWidget` and `onImageError`. Images now appear one by one as they load.
* `frame` with four ready-made frames: `WheelFrame.classic()`, `WheelFrame.royal()`, `WheelFrame.neon()` and `WheelFrame.wooden()`, each with its own colors and options.
* `WheelFrame.custom()` and subclassing `WheelFrame` to paint your own frame, with `WheelFrameGeometry` to line it up with the slices.
* `wheelInset` to set how wide the frame is. It defaults to what the frame needs.
* `WheelLabelStyle.copyWith` and value equality.
* Screen reader support and right-to-left label text.

**Fixes**
* Segments without a `probability` could never win when others had one.
* Changing `segments` after the first build had no effect.
* Calling `startSpin()` mid-spin made the wheel jump back; it is now ignored.
* `startSpin()` after the wheel was disposed threw an error.
* An empty `segments` list crashed.
* A `CurvedAnimation` was leaked on every animation frame.
* Labels with `clip`, `fade` or `ellipsis` overflow now stay inside their slice; `fade` actually fades.
* A one-segment wheel showed no label.
* The wheel crashed when given no size limits on either axis.
* Loaded images were never disposed, and 2x/3x asset variants weren't used.
* Asset paths starting with "http" were treated as URLs.
