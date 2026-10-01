import 'dart:math';
import 'package:flutter/material.dart';

import 'wheel_frame.dart';

/// A red rim with a silver trim, pointed teeth and gold studs.
/// See [WheelFrame.classic].
class ClassicWheelFrame extends WheelFrame {
  /// The main color of the outer rim.
  final Color rimColor;

  /// The lighter color that shines on the rim. Defaults to a lighter,
  /// warmer version of [rimColor].
  final Color? rimHighlightColor;

  /// The color of the trim ring and teeth between the rim and the slices.
  final Color trimColor;

  /// The color of the studs on the rim.
  final Color studColor;

  /// The number of pointed teeth on the trim ring. 0 draws none.
  final int toothCount;

  /// The number of studs on the rim, placed between the teeth. 0 draws none.
  final int studCount;

  /// The color of the plate shown behind the slices.
  final Color plateColor;

  /// Whether to draw a drop shadow and a soft shadow on the slices' edge.
  final bool shadow;

  /// Creates a [ClassicWheelFrame].
  const ClassicWheelFrame({
    this.rimColor = const Color(0xFFE41B23),
    this.rimHighlightColor,
    this.trimColor = const Color(0xFFE8E8EA),
    this.studColor = const Color(0xFFF4C542),
    this.toothCount = 8,
    this.studCount = 8,
    this.plateColor = const Color(0xFFF2F2F2),
    this.shadow = true,
  })  : assert(toothCount >= 0, 'toothCount must not be negative'),
        assert(studCount >= 0, 'studCount must not be negative');

  @override
  double get preferredInset => 0.094;

  /// The highlight color actually used on the rim.
  Color get effectiveRimHighlightColor =>
      rimHighlightColor ?? Color.lerp(rimColor, const Color(0xFFFF8A00), 0.55)!;

  /// Creates a copy of this frame with the given fields replaced.
  ClassicWheelFrame copyWith({
    Color? rimColor,
    Color? rimHighlightColor,
    Color? trimColor,
    Color? studColor,
    int? toothCount,
    int? studCount,
    Color? plateColor,
    bool? shadow,
  }) {
    return ClassicWheelFrame(
      rimColor: rimColor ?? this.rimColor,
      rimHighlightColor: rimHighlightColor ?? this.rimHighlightColor,
      trimColor: trimColor ?? this.trimColor,
      studColor: studColor ?? this.studColor,
      toothCount: toothCount ?? this.toothCount,
      studCount: studCount ?? this.studCount,
      plateColor: plateColor ?? this.plateColor,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  void paintBack(Canvas canvas, WheelFrameGeometry geometry) {
    final g = geometry;
    final _Layout f = _Layout(g);
    if (shadow) WheelFrame.paintDropShadow(canvas, g, g.outer);
    WheelFrame.paintPlate(canvas, g, f.trimOuter, plateColor);
  }

  @override
  void paintFront(Canvas canvas, WheelFrameGeometry geometry) {
    final g = geometry;
    final _Layout f = _Layout(g);
    if (shadow) WheelFrame.paintSliceShadow(canvas, g);
    if (f.band > 0) _paintRim(canvas, g, f);
    _paintTrim(canvas, g, f);
    if (f.band > 0) _paintStuds(canvas, g, f);
  }

  /// The colored outer ring with a sweeping shine.
  void _paintRim(Canvas canvas, WheelFrameGeometry g, _Layout f) {
    final Color base = rimColor;
    final Color light = effectiveRimHighlightColor;
    final Color dark = Color.lerp(base, Colors.black, 0.18)!;
    final Rect outerRect = g.circle(g.outer);
    final Path ring = g.ring(f.trimOuter, g.outer);

    // Shine at the top left and bottom right, shade at the bottom left.
    // SweepGradient starts at 3 o'clock and runs clockwise.
    canvas.drawPath(
      ring,
      Paint()
        ..shader = SweepGradient(
          colors: [base, light, base, dark, base, light, base, base],
          stops: const [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.78, 1.0],
        ).createShader(outerRect),
    );

    // Bevel: the ring darkens toward its outer edge...
    canvas.drawPath(
      ring,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x00000000),
            Color(0x00000000),
            Color(0x26000000),
          ],
          stops: [0.0, f.trimOuter / g.outer, 1.0],
        ).createShader(outerRect),
    );
    // ...and catches light on its outer lip.
    canvas.drawCircle(
      g.center,
      g.outer - g.radius * 0.006,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.radius * 0.012
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x99FFFFFF), Color(0x00FFFFFF), Color(0x33000000)],
        ).createShader(outerRect),
    );
  }

  /// The silver ring around the slices, with pointed teeth.
  void _paintTrim(Canvas canvas, WheelFrameGeometry g, _Layout f) {
    final Paint silver = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          trimColor,
          Color.lerp(trimColor, Colors.black, 0.22)!,
          trimColor,
          Colors.white,
        ],
        stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
      ).createShader(g.circle(g.outer));

    if (toothCount > 0 && f.band > 0) {
      final double height = f.toothApex - f.trimOuter;
      // 90° points: the base is twice the height. Start the base a little
      // inside the ring so there is no seam.
      final double halfBase = height / f.trimOuter;
      final double baseRadius = f.trimOuter - g.radius * 0.01;
      final Path teeth = Path();
      for (int i = 0; i < toothCount; i++) {
        final double a = -pi / 2 + i * 2 * pi / toothCount;
        final Offset left = g.pointAt(a - halfBase, baseRadius);
        final Offset tip = g.pointAt(a, f.toothApex);
        final Offset right = g.pointAt(a + halfBase, baseRadius);
        teeth
          ..moveTo(left.dx, left.dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(right.dx, right.dy)
          ..close();
      }
      if (shadow) {
        canvas.drawShadow(
            teeth, const Color(0xFF000000), g.radius * 0.01, false);
      }
      canvas.drawPath(teeth, silver);
    }

    canvas.drawPath(g.ring(f.trimInner, f.trimOuter), silver);

    // A fine dark line where the trim meets the slices.
    canvas.drawCircle(
      g.center,
      f.trimInner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, g.radius * 0.006)
        ..color = const Color(0x40000000),
    );
  }

  /// Gold studs around the rim, between the teeth.
  void _paintStuds(Canvas canvas, WheelFrameGeometry g, _Layout f) {
    if (studCount <= 0 || f.studRadius <= 0) return;
    for (int i = 0; i < studCount; i++) {
      final double a = -pi / 2 + (i + 0.5) * 2 * pi / studCount;
      WheelFrame.paintStud(
          canvas, g.pointAt(a, f.studRing), f.studRadius, studColor,
          shadow: shadow);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ClassicWheelFrame &&
      other.rimColor == rimColor &&
      other.rimHighlightColor == rimHighlightColor &&
      other.trimColor == trimColor &&
      other.studColor == studColor &&
      other.toothCount == toothCount &&
      other.studCount == studCount &&
      other.plateColor == plateColor &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(rimColor, rimHighlightColor, trimColor,
      studColor, toothCount, studCount, plateColor, shadow);
}

/// The radii of the classic frame's parts.
class _Layout {
  final double trimOuter;
  final double trimInner;
  final double band;
  final double toothApex;
  final double studRing;
  final double studRadius;

  factory _Layout(WheelFrameGeometry g) {
    final double trimOuter = min(g.sliceRadius + g.radius * 0.045, g.outer);
    final double band = max(0.0, g.outer - trimOuter);
    return _Layout._(
      trimOuter: trimOuter,
      trimInner: max(0.0, g.sliceRadius - g.radius * 0.012),
      band: band,
      toothApex: trimOuter + band * 0.68,
      studRing: trimOuter + band * 0.5,
      studRadius: min(band * 0.19, g.radius * 0.026),
    );
  }

  const _Layout._({
    required this.trimOuter,
    required this.trimInner,
    required this.band,
    required this.toothApex,
    required this.studRing,
    required this.studRadius,
  });
}
