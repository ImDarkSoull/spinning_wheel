import 'dart:math';
import 'package:flutter/animation.dart';
import '../models/wheel_options.dart';
import '../models/wheel_segment.dart';
import 'wheel_geometry.dart';

/// Holds the calculation results for a wheel spin animation.
class SpinResult {
  /// The starting rotation angle in radians.
  final double start;

  /// The final calculated rotation angle in radians.
  final double end;

  /// The index of the segment the wheel will land on.
  final int index;

  /// Creates a [SpinResult].
  SpinResult(this.start, this.end, this.index);
}

/// Resolves the effective selection weight of each segment.
///
/// Segments with an explicit [WheelSegment.probability] keep it (negative
/// values are treated as 0). Segments without one share the remaining
/// probability (`1.0 - sum of explicit probabilities`) equally. If no segment
/// has a probability, all segments are weighted equally.
List<double> effectiveProbabilities(List<WheelSegment> segments) {
  final int unsetCount = segments.where((s) => s.probability == null).length;
  if (unsetCount == segments.length) {
    return List<double>.filled(segments.length, 1.0);
  }

  final double explicitTotal =
      segments.fold(0.0, (sum, s) => sum + max(0.0, s.probability ?? 0.0));
  final double shared =
      unsetCount == 0 ? 0.0 : max(0.0, 1.0 - explicitTotal) / unsetCount;

  return [
    for (final s in segments)
      s.probability == null ? shared : max(0.0, s.probability!),
  ];
}

/// The slice layout for [segments] with the given [sizing].
WheelGeometry geometryFor(List<WheelSegment> segments, SliceSizing sizing) {
  return switch (sizing) {
    SliceSizing.equal => WheelGeometry.equal(segments.length),
    SliceSizing.proportional =>
      WheelGeometry.weighted(effectiveProbabilities(segments)),
  };
}

/// Picks an index at random, with each index's chance proportional to its
/// weight. Falls back to a uniform pick if all weights are zero.
int pickWeightedIndex(List<double> weights, Random random) {
  final double total = weights.fold(0.0, (sum, w) => sum + w);
  if (total <= 0.0) return random.nextInt(weights.length);

  final double randomValue = random.nextDouble() * total;
  double currentSum = 0.0;
  for (int i = 0; i < weights.length; i++) {
    if (weights[i] > 0) {
      currentSum += weights[i];
      if (randomValue <= currentSum) return i;
    }
  }
  // Floating point rounding: the value belongs to the last positive weight.
  return weights.lastIndexWhere((w) => w > 0);
}

/// Plans a spin that lands on [index].
///
/// The wheel turns at least [fullTurns] whole turns in the given direction
/// and stops at a random point between 10% and 90% of the slice, so it never
/// lands on a dividing line.
SpinResult planSpin({
  required double startRotation,
  required WheelGeometry geometry,
  required int index,
  required int fullTurns,
  double pointerAngle = -pi / 2,
  bool clockwise = true,
  Random? random,
}) {
  final Random rng = random ?? Random.secure();
  final double fraction = 0.1 + rng.nextDouble() * 0.8;
  final double end = geometry.endRotationFor(
    startRotation: startRotation,
    index: index,
    fraction: fraction,
    pointerAngle: pointerAngle,
    fullTurns: fullTurns,
    clockwise: clockwise,
  );
  return SpinResult(startRotation, end, index);
}

/// Calculates the target [end] rotation for a spin based on weighted probabilities.
///
/// [startRotation] is the current angle of the wheel.
/// [segments] is the list of wheel slices to calculate against.
SpinResult spinWheel(double startRotation, List<WheelSegment> segments) {
  if (segments.isEmpty) {
    throw ArgumentError.value(
        segments, 'segments', 'SpinnerWheel needs at least one segment');
  }
  // Use Random.secure() for cryptographically secure randomness (better fairness)
  final Random random = Random.secure();
  return planSpin(
    startRotation: startRotation,
    geometry: WheelGeometry.equal(segments.length),
    index: pickWeightedIndex(effectiveProbabilities(segments), random),
    fullTurns: 5 + random.nextInt(5),
    random: random,
  );
}

/// Determines which segment index is at the top position based on the final [endRotation].
int determineSegment(List<WheelSegment> segments, double endRotation) {
  if (segments.isEmpty) {
    throw ArgumentError.value(
        segments, 'segments', 'SpinnerWheel needs at least one segment');
  }
  return WheelGeometry.equal(segments.length).indexAt(endRotation, -pi / 2);
}

/// The frame rate the speed limit is designed for. Faster screens show
/// smaller steps per frame, so they are safe too.
const double referenceFrameRate = 60;

/// The most a wheel may turn in one frame, as a fraction of a slice.
///
/// Above half a slice per frame the eye pairs each slice with its neighbor
/// behind it and the wheel seems to turn backwards (the "wagon-wheel"
/// effect). This stays safely below that.
const double maxSliceFractionPerFrame = 0.4;

/// The largest share of the whole spin that [curve] covers in a single
/// frame, for a spin lasting [duration].
double peakFrameFraction(Curve curve, Duration duration) {
  final int frames =
      max(1, (duration.inMicroseconds / 1e6 * referenceFrameRate).round());
  double peak = 0;
  double previous = curve.transform(0);
  for (int k = 1; k <= frames; k++) {
    final double current = curve.transform(k / frames);
    peak = max(peak, (current - previous).abs());
    previous = current;
  }
  return peak;
}

/// The farthest (in radians) a wheel with [segmentCount] slices may turn
/// using [curve] over [duration] without ever moving fast enough to look
/// like it is turning backwards.
double maxSpinDistance({
  required int segmentCount,
  required Curve curve,
  required Duration duration,
}) {
  final double peak = peakFrameFraction(curve, duration);
  if (peak <= 0 || segmentCount <= 0) return double.infinity;
  final double maxStep = maxSliceFractionPerFrame * 2 * pi / segmentCount;
  return maxStep / peak;
}
