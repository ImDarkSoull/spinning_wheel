import 'dart:math';
import '../models/wheel_segment.dart';

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
  final int spinCount = 5 + random.nextInt(5);

  // Weighted random selection
  int selectedIndex = -1;
  final List<double> weights = effectiveProbabilities(segments);
  final double totalProbability = weights.fold(0.0, (sum, w) => sum + w);

  // If the total weight is 0, fall back to uniform distribution
  if (totalProbability == 0.0) {
    selectedIndex = random.nextInt(segments.length);
  } else {
    double randomValue = random.nextDouble() * totalProbability;
    double currentSum = 0.0;

    for (int i = 0; i < segments.length; i++) {
      if (weights[i] > 0) {
        currentSum += weights[i];
        if (randomValue <= currentSum) {
          selectedIndex = i;
          break;
        }
      }
    }

    // Robust Fallback:
    // If floating point precision errors cause the loop to finish without selecting,
    // the value technically belongs to the last segment with weight > 0.
    if (selectedIndex == -1) {
      selectedIndex = weights.lastIndexWhere((w) => w > 0);
    }
  }

  // Calculate target angle range for the selected segment
  // The wheel painter draws segments clockwise (or counter depending on logic)
  // determineSegment logic:
  // invertedAngle = 2*pi - normalizedAngle
  // index = invertedAngle ~/ segmentAngle
  // So invertedAngle must be between index*segmentAngle and (index+1)*segmentAngle

  double segmentAngle = 2 * pi / segments.length;

  // Pick a random spot within the segment (10% to 90%) to avoid landing on lines
  double randomOffset = 0.1 + (random.nextDouble() * 0.8);
  double targetInvertedAngle = (selectedIndex + randomOffset) * segmentAngle;

  double targetNormalizedAngle = (2 * pi - targetInvertedAngle) % (2 * pi);

  double currentPhase = startRotation % (2 * pi);
  double diff = targetNormalizedAngle - currentPhase;
  if (diff < 0) diff += 2 * pi;

  double endRotation = startRotation + (spinCount * 2 * pi) + diff;

  return SpinResult(startRotation, endRotation, selectedIndex);
}

/// Determines which segment index is at the top position based on the final [endRotation].
int determineSegment(List<WheelSegment> segments, double endRotation) {
  if (segments.isEmpty) {
    throw ArgumentError.value(
        segments, 'segments', 'SpinnerWheel needs at least one segment');
  }
  final double normalizedAngle = endRotation % (2 * pi);
  final double segmentAngle = 2 * pi / segments.length;
  final double invertedAngle = 2 * pi - normalizedAngle;
  final int segmentIndex = (invertedAngle ~/ segmentAngle) % segments.length;

  return segmentIndex;
}
