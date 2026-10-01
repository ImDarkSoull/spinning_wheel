import 'dart:math';
import 'package:flutter/material.dart';

import 'wheel_frame.dart';

/// A ship's helm: a wooden rim with brass fittings and turned handles
/// sticking out of it. See [WheelFrame.wooden].
class WoodenWheelFrame extends WheelFrame {
  /// The base color of the wood.
  final Color woodColor;

  /// The color of the brass rings and caps.
  final Color brassColor;

  /// The number of handles. 0 draws none.
  final int handleCount;

  /// Whether to draw a drop shadow and a soft shadow on the slices' edge.
  final bool shadow;

  /// Creates a [WoodenWheelFrame].
  const WoodenWheelFrame({
    this.woodColor = const Color(0xFF8B5A2B),
    this.brassColor = const Color(0xFFC9A44C),
    this.handleCount = 8,
    this.shadow = true,
  }) : assert(handleCount >= 0, 'handleCount must not be negative');

  @override
  double get preferredInset => 0.165;

  @override
  Color? get indicatorColor => const Color(0xFFB3261E);

  /// Creates a copy of this frame with the given fields replaced.
  WoodenWheelFrame copyWith({
    Color? woodColor,
    Color? brassColor,
    int? handleCount,
    bool? shadow,
  }) {
    return WoodenWheelFrame(
      woodColor: woodColor ?? this.woodColor,
      brassColor: brassColor ?? this.brassColor,
      handleCount: handleCount ?? this.handleCount,
      shadow: shadow ?? this.shadow,
    );
  }

  Color get _woodLight => Color.lerp(woodColor, const Color(0xFFF0C890), 0.35)!;
  Color get _woodDark => Color.lerp(woodColor, Colors.black, 0.4)!;

  /// The radii of the rim: inside edge, outside edge.
  (double, double) _rim(WheelFrameGeometry g) {
    final double inner = min(g.sliceRadius + g.radius * 0.03, g.outer);
    // Handles take the outer 16% if there is room for a rim as well.
    final double outer =
        max(inner + g.radius * 0.04, g.outer - g.radius * 0.16);
    return (inner, min(outer, g.outer));
  }

  @override
  void paintBack(Canvas canvas, WheelFrameGeometry geometry) {
    final g = geometry;
    final (inner, outer) = _rim(g);
    if (shadow) WheelFrame.paintDropShadow(canvas, g, outer);
    WheelFrame.paintPlate(canvas, g, inner, const Color(0xFFE9D8B4));
  }

  @override
  void paintFront(Canvas canvas, WheelFrameGeometry geometry) {
    final g = geometry;
    final (inner, outer) = _rim(g);
    if (shadow) WheelFrame.paintSliceShadow(canvas, g, strength: 0.4);
    _paintHandles(canvas, g, outer);
    _paintRim(canvas, g, inner, outer);
    _paintBrass(canvas, g, inner, outer);
  }

  void _paintHandles(Canvas canvas, WheelFrameGeometry g, double rimOuter) {
    final double length = g.outer - rimOuter;
    if (handleCount <= 0 || length <= g.radius * 0.02) return;
    final double neck = g.radius * 0.06;
    final double knob = g.radius * 0.1;
    // Shaded across the handle, so it looks round.
    final Paint wood = Paint()..shader = _crossShade(knob);

    for (int i = 0; i < handleCount; i++) {
      // Offset by half a step so no handle sits under the pointer.
      final double a = -pi / 2 + (i + 0.5) * 2 * pi / handleCount;
      canvas.save();
      canvas.translate(g.center.dx, g.center.dy);
      canvas.rotate(a);
      // Now the handle runs along +x, from the rim outwards.
      final double start = rimOuter - g.radius * 0.02;
      // A turned spindle: a neck, a collar, then a bulb with a round end.
      final Path handle = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(start, -neck / 2, start + length * 0.5, neck / 2),
          Radius.circular(neck * 0.25),
        ))
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(start + length * 0.22, -knob * 0.42,
              start + length * 0.34, knob * 0.42),
          Radius.circular(knob * 0.15),
        ))
        ..addOval(
            Rect.fromLTRB(start + length * 0.4, -knob / 2, g.outer, knob / 2));
      if (shadow) {
        canvas.drawShadow(handle, Colors.black, g.radius * 0.012, false);
      }
      canvas.drawPath(handle, wood);
      canvas.restore();
    }
  }

  /// A shader shading a handle across its width (the local y axis).
  Shader _crossShade(double width) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_woodDark, _woodLight, woodColor, _woodDark],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromLTRB(0, -width / 2, 1, width / 2));

  void _paintRim(
      Canvas canvas, WheelFrameGeometry g, double inner, double outer) {
    final Rect bounds = g.circle(outer);
    final Path ring = g.ring(inner, outer);
    canvas.drawPath(
      ring,
      Paint()
        ..shader = SweepGradient(
          colors: [
            woodColor, _woodLight, woodColor, _woodDark, woodColor, //
            _woodLight, woodColor, _woodDark, woodColor,
          ],
        ).createShader(bounds),
    );
    // Wood grain: fine rings of darker wood.
    final double band = outer - inner;
    final Paint grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.6, band * 0.03)
      ..color = _woodDark.withValues(alpha: 0.35);
    for (final f in const [0.18, 0.31, 0.47, 0.6, 0.78]) {
      canvas.drawCircle(g.center, inner + band * f, grain);
    }
    // Rounded edge: lighter on top, darker underneath.
    canvas.drawPath(
      ring,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0x26000000),
            Color(0x00000000),
            Color(0x14FFFFFF),
            Color(0x33000000),
          ],
          stops: [inner / outer, (inner + band * 0.3) / outer, 0.9, 1.0],
        ).createShader(bounds),
    );
  }

  void _paintBrass(
      Canvas canvas, WheelFrameGeometry g, double inner, double outer) {
    final Color light = Color.lerp(brassColor, Colors.white, 0.6)!;
    final Color dark = Color.lerp(brassColor, Colors.black, 0.4)!;
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, g.radius * 0.018)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [light, brassColor, dark, brassColor],
      ).createShader(g.circle(outer));
    canvas.drawCircle(g.center, inner, ring);
    canvas.drawCircle(g.center, outer - ring.strokeWidth / 2, ring);

    // Brass caps where the handles meet the rim.
    if (handleCount <= 0) return;
    final double r = min((outer - inner) * 0.28, g.radius * 0.03);
    for (int i = 0; i < handleCount; i++) {
      final double a = -pi / 2 + (i + 0.5) * 2 * pi / handleCount;
      final Offset c = g.pointAt(a, (inner + outer) / 2);
      if (shadow) {
        canvas.drawCircle(
          c + Offset(0, r * 0.3),
          r,
          Paint()
            ..color = const Color(0x66000000)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
        );
      }
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: [light, brassColor, dark],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is WoodenWheelFrame &&
      other.woodColor == woodColor &&
      other.brassColor == brassColor &&
      other.handleCount == handleCount &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(woodColor, brassColor, handleCount, shadow);
}
