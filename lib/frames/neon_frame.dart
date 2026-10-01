import 'dart:math';
import 'package:flutter/material.dart';

import 'wheel_frame.dart';

/// Two glowing neon tubes on a dark ring. See [WheelFrame.neon].
class NeonWheelFrame extends WheelFrame {
  /// The color of the outer tube.
  final Color color;

  /// The color of the inner tube, around the slices.
  final Color secondaryColor;

  /// The color of the dark ring and the plate behind the slices.
  final Color plateColor;

  /// Creates a [NeonWheelFrame].
  const NeonWheelFrame({
    this.color = const Color(0xFF00E5FF),
    this.secondaryColor = const Color(0xFFFF2BD6),
    this.plateColor = const Color(0xFF0D0B1E),
  });

  @override
  double get preferredInset => 0.07;

  @override
  Color? get indicatorColor => secondaryColor;

  /// Creates a copy of this frame with the given fields replaced.
  NeonWheelFrame copyWith({
    Color? color,
    Color? secondaryColor,
    Color? plateColor,
  }) {
    return NeonWheelFrame(
      color: color ?? this.color,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      plateColor: plateColor ?? this.plateColor,
    );
  }

  /// The inner edge of the dark ring, just outside the slices.
  double _inner(WheelFrameGeometry g) =>
      min(g.sliceRadius + g.radius * 0.015, g.outer);

  @override
  void paintBack(Canvas canvas, WheelFrameGeometry geometry) {
    final g = geometry;
    // The glow the tubes cast around the wheel.
    canvas.drawCircle(
      g.center,
      g.outer * 0.97,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.radius * 0.06
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, g.radius * 0.05),
    );
    canvas.drawCircle(g.center, g.outer, Paint()..color = plateColor);
  }

  @override
  void paintFront(Canvas canvas, WheelFrameGeometry geometry) {
    final g = geometry;
    final double inner = _inner(g);
    final double band = g.outer - inner;
    WheelFrame.paintSliceShadow(canvas, g, strength: 0.55);

    // The dark ring the tubes are mounted on.
    canvas.drawPath(
      g.ring(inner, g.outer),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(plateColor, Colors.white, 0.08)!,
            plateColor,
          ],
          stops: [inner / g.outer, 1.0],
        ).createShader(g.circle(g.outer)),
    );
    if (band <= 0) return;

    _paintTube(canvas, g, inner + band * 0.55, band * 0.22, color);
    _paintTube(canvas, g, inner + band * 0.12, band * 0.12, secondaryColor);
  }

  /// A glowing tube: a wide soft glow, a brighter halo and a near-white
  /// core.
  void _paintTube(Canvas canvas, WheelFrameGeometry g, double radius,
      double width, Color tubeColor) {
    canvas.drawCircle(
      g.center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2.4
        ..color = tubeColor.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 1.2),
    );
    canvas.drawCircle(
      g.center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = tubeColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.25),
    );
    canvas.drawCircle(
      g.center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, width * 0.35)
        ..color = Color.lerp(tubeColor, Colors.white, 0.75)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NeonWheelFrame &&
      other.color == color &&
      other.secondaryColor == secondaryColor &&
      other.plateColor == plateColor;

  @override
  int get hashCode => Object.hash(color, secondaryColor, plateColor);
}
