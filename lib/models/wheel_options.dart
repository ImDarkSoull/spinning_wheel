import 'dart:math';
import 'wheel_segment.dart';

/// Which side of the wheel the indicator (pointer) sits on.
enum IndicatorPosition {
  /// Above the wheel, pointing down.
  top,

  /// Right of the wheel, pointing left.
  right,

  /// Below the wheel, pointing up.
  bottom,

  /// Left of the wheel, pointing right.
  left;

  /// The canvas angle (radians, clockwise from the positive x-axis) at which
  /// the indicator touches the wheel.
  double get angle => switch (this) {
        IndicatorPosition.top => -pi / 2,
        IndicatorPosition.right => 0.0,
        IndicatorPosition.bottom => pi / 2,
        IndicatorPosition.left => pi,
      };

  /// Clockwise quarter turns that rotate a downward-pointing indicator so it
  /// points at the wheel's center from this side.
  int get quarterTurns => switch (this) {
        IndicatorPosition.top => 0,
        IndicatorPosition.right => 1,
        IndicatorPosition.bottom => 2,
        IndicatorPosition.left => 3,
      };
}

/// How the sizes of the slices are decided.
enum SliceSizing {
  /// Every slice has the same size, whatever its probability.
  equal,

  /// Each slice's size matches its chance of winning, so a 50% segment
  /// takes half the wheel. Segments with a probability of 0 are not drawn.
  proportional,
}

/// How each slice is filled.
enum SliceStyle {
  /// A radial gradient from a lighter center to the full color at the rim.
  gradient,

  /// A single flat color.
  flat,
}

/// The outcome of a finished spin.
class WheelSpinResult<T> {
  /// The segment the wheel landed on.
  final WheelSegment<T> segment;

  /// The index of [segment] in the wheel's segment list.
  final int index;

  /// Creates a [WheelSpinResult].
  const WheelSpinResult(this.segment, this.index);

  @override
  String toString() => 'WheelSpinResult(${segment.label}, index: $index)';
}
