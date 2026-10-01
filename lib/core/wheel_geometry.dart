import 'dart:math';

/// The angular layout of the wheel's slices.
///
/// Slices are laid out clockwise starting at the top of the (unrotated)
/// wheel. A rotation `R` (radians, clockwise) moves a point drawn at canvas
/// angle `θ` to `θ + R` on screen.
class WheelGeometry {
  /// The angle each slice covers, in radians. Adds up to `2π`.
  final List<double> sweeps;

  /// Where each slice starts, measured clockwise from the top, in radians.
  final List<double> offsets;

  WheelGeometry._(this.sweeps) : offsets = _runningTotals(sweeps);

  static List<double> _runningTotals(List<double> sweeps) {
    double total = 0.0;
    return [
      for (final sweep in sweeps) (total += sweep) - sweep,
    ];
  }

  /// [count] slices of equal size.
  factory WheelGeometry.equal(int count) => WheelGeometry._(
      List<double>.filled(count, count == 0 ? 0.0 : 2 * pi / count));

  /// Slices sized in proportion to [weights]. Falls back to equal sizes if
  /// all weights are zero.
  factory WheelGeometry.weighted(List<double> weights) {
    final double total = weights.fold(0.0, (a, b) => a + max(0.0, b));
    if (total <= 0) return WheelGeometry.equal(weights.length);
    return WheelGeometry._(
        [for (final w in weights) max(0.0, w) / total * 2 * pi]);
  }

  /// The number of slices.
  int get length => sweeps.length;

  /// The canvas angle at which slice [index] starts (before rotation).
  double startAngle(int index) => -pi / 2 + offsets[index];

  /// The canvas angle through the middle of slice [index] (before rotation).
  double midAngle(int index) => startAngle(index) + sweeps[index] / 2;

  /// How far clockwise from the slice origin the point under the pointer is,
  /// in `[0, 2π)`.
  double _positionUnderPointer(double rotation, double pointerAngle) =>
      (pointerAngle - rotation + pi / 2) % (2 * pi);

  /// The index of the slice under the pointer at [pointerAngle] when the
  /// wheel is rotated by [rotation].
  int indexAt(double rotation, double pointerAngle) {
    final double u = _positionUnderPointer(rotation, pointerAngle);
    for (int i = 0; i < length; i++) {
      if (u < offsets[i] + sweeps[i]) {
        if (sweeps[i] > 0) return i;
      }
    }
    // Rounding at the very end of the circle: the last visible slice.
    return sweeps.lastIndexWhere((s) => s > 0);
  }

  /// The slices that come under the pointer, in order, as the wheel turns
  /// from rotation [from] to rotation [to]. A slice is listed each time the
  /// pointer enters it, so a full turn lists every visible slice once.
  ///
  /// Stops after [limit] entries.
  List<int> slicesEntered(double from, double to, double pointerAngle,
      {int limit = 100000}) {
    final List<int> entered = [];
    if (length == 0 || from == to || !from.isFinite || !to.isFinite) {
      return entered;
    }
    // Turning the wheel clockwise moves the pointer backwards over the
    // slices (towards lower indexes).
    final bool backwards = to > from;
    double remaining = (to - from).abs();
    int index = indexAt(from, pointerAngle);
    if (index < 0) return entered;
    double u = _positionUnderPointer(from, pointerAngle);
    // The position can sit a hair past its slice's end from rounding.
    u = u.clamp(offsets[index], offsets[index] + sweeps[index]);

    while (entered.length < limit) {
      final double toEdge =
          backwards ? u - offsets[index] : offsets[index] + sweeps[index] - u;
      if (remaining <= toEdge) break;
      remaining -= toEdge;
      index = _nextVisible(index, backwards ? -1 : 1);
      u = backwards ? offsets[index] + sweeps[index] : offsets[index];
      entered.add(index);
    }
    return entered;
  }

  int _nextVisible(int index, int step) {
    int i = index;
    for (int n = 0; n < length; n++) {
      i = (i + step) % length;
      if (sweeps[i] > 0) return i;
    }
    return index;
  }

  /// Where within slice [index] the pointer is, from 0.0 (slice start) to
  /// 1.0 (slice end).
  double fractionAt(int index, double rotation, double pointerAngle) {
    if (sweeps[index] == 0) return 0.5;
    final double u = _positionUnderPointer(rotation, pointerAngle);
    return ((u - offsets[index]) / sweeps[index]).clamp(0.0, 1.0);
  }

  /// A rotation in `[0, 2π)` that puts the point at [fraction] of slice
  /// [index] under the pointer.
  double restingRotationFor(int index, double fraction, double pointerAngle) {
    final double u = offsets[index] + fraction * sweeps[index];
    return (pointerAngle + pi / 2 - u) % (2 * pi);
  }

  /// The end rotation for a spin starting at [startRotation] that turns at
  /// least [fullTurns] whole turns in the given direction and stops with
  /// [fraction] of slice [index] under the pointer.
  double endRotationFor({
    required double startRotation,
    required int index,
    required double fraction,
    required double pointerAngle,
    required int fullTurns,
    bool clockwise = true,
  }) {
    final double target = restingRotationFor(index, fraction, pointerAngle);
    final double phase = startRotation % (2 * pi);
    if (clockwise) {
      final double diff = (target - phase) % (2 * pi);
      return startRotation + fullTurns * 2 * pi + diff;
    }
    final double diff = (phase - target) % (2 * pi);
    return startRotation - fullTurns * 2 * pi - diff;
  }
}
