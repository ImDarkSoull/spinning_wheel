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
