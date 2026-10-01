import 'dart:math';
import 'package:flutter/material.dart';

import 'wheel_frame.dart';

/// Polished gold set with gems and pearls. See [WheelFrame.royal].
class RoyalWheelFrame extends WheelFrame {
  /// The base color of the gold.
  final Color goldColor;

  /// The color of the gems.
  final Color gemColor;

  /// The number of gems around the rim. Pearls sit between them. 0 draws
  /// neither.
  final int gemCount;

  /// The color of the plate shown behind the slices.
  final Color plateColor;

  /// Whether to draw a drop shadow and a soft shadow on the slices' edge.
  final bool shadow;

  /// Creates a [RoyalWheelFrame].
  const RoyalWheelFrame({
    this.goldColor = const Color(0xFFD4A62A),
    this.gemColor = const Color(0xFFD0103A),
    this.gemCount = 12,
    this.plateColor = const Color(0xFF3B2410),
    this.shadow = true,
  }) : assert(gemCount >= 0, 'gemCount must not be negative');

  @override
  double get preferredInset => 0.1;

  @override
  Color? get indicatorColor => gemColor;

  /// Creates a copy of this frame with the given fields replaced.
  RoyalWheelFrame copyWith({
    Color? goldColor,
    Color? gemColor,
    int? gemCount,
    Color? plateColor,
    bool? shadow,
  }) {
    return RoyalWheelFrame(
      goldColor: goldColor ?? this.goldColor,
      gemColor: gemColor ?? this.gemColor,
      gemCount: gemCount ?? this.gemCount,
      plateColor: plateColor ?? this.plateColor,
      shadow: shadow ?? this.shadow,
    );
  }

  Color get _light => Color.lerp(goldColor, const Color(0xFFFFF6D0), 0.7)!;
  Color get _dark => Color.lerp(goldColor, Colors.black, 0.45)!;

  @override
  void paintBack(Canvas canvas, WheelFrameGeometry geometry) {
    final g = geometry;
    if (shadow) WheelFrame.paintDropShadow(canvas, g, g.outer);
    WheelFrame.paintPlate(canvas, g, _inner(g), plateColor);
  }

  /// The inner edge of the gold band, just outside the slices.
  double _inner(WheelFrameGeometry g) =>
      min(g.sliceRadius + g.radius * 0.02, g.outer);

  @override
  void paintFront(Canvas canvas, WheelFrameGeometry geometry) {
    final g = geometry;
    final double inner = _inner(g);
    final double band = g.outer - inner;
    if (shadow) WheelFrame.paintSliceShadow(canvas, g, strength: 0.4);

    // Polished gold: bright and dark streaks sweeping round the ring.
    final Rect bounds = g.circle(g.outer);
    canvas.drawPath(
      g.ring(inner, g.outer),
      Paint()
        ..shader = SweepGradient(
          colors: [
            _light, goldColor, _dark, goldColor, _light, goldColor, //
            _dark, goldColor, _light,
          ],
        ).createShader(bounds),
    );

    if (band > 0) {
      // A raised lip on each edge and a groove through the middle.
      final Paint lip = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = band * 0.14
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_light, goldColor, _dark],
        ).createShader(bounds);
      canvas.drawCircle(g.center, g.outer - band * 0.07, lip);
      canvas.drawCircle(g.center, inner + band * 0.07, lip);
      canvas.drawCircle(
        g.center,
        inner + band * 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, band * 0.04)
          ..color = _dark.withValues(alpha: 0.6),
      );
      _paintJewels(canvas, g, inner, band);
    }

    // A fine dark line where the gold meets the slices.
    canvas.drawCircle(
      g.center,
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, g.radius * 0.006)
        ..color = const Color(0x66000000),
    );
  }

  void _paintJewels(
      Canvas canvas, WheelFrameGeometry g, double inner, double band) {
    if (gemCount <= 0) return;
    final double ring = inner + band * 0.5;
    final double gemSize = band * 0.42;
    final Color gemLight = Color.lerp(gemColor, Colors.white, 0.6)!;
    final Color gemDark = Color.lerp(gemColor, Colors.black, 0.45)!;

    for (int i = 0; i < gemCount; i++) {
      // Offset by half a step so the pointer covers a pearl, not a gem.
      final double a = -pi / 2 + (i + 0.5) * 2 * pi / gemCount;
      final Offset c = g.pointAt(a, ring);

      // A diamond-shaped gem in a gold setting, pointing at the center.
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a + pi / 2);
      final Path gem = Path()
        ..moveTo(0, -gemSize)
        ..lineTo(gemSize * 0.7, 0)
        ..lineTo(0, gemSize)
        ..lineTo(-gemSize * 0.7, 0)
        ..close();
      if (shadow) {
        canvas.drawShadow(gem, Colors.black, gemSize * 0.25, false);
      }
      canvas.drawPath(
        gem,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gemLight, gemColor, gemDark],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: gemSize)),
      );
      // Facets and a glint.
      canvas.drawPath(
        Path()
          ..moveTo(0, -gemSize)
          ..lineTo(gemSize * 0.7, 0)
          ..lineTo(0, 0)
          ..close(),
        Paint()..color = const Color(0x33FFFFFF),
      );
      canvas.drawCircle(Offset(-gemSize * 0.18, -gemSize * 0.35),
          gemSize * 0.14, Paint()..color = const Color(0xCCFFFFFF));
      canvas.drawPath(
        gem,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, gemSize * 0.16)
          ..color = _light,
      );
      canvas.restore();

      // A pearl between this gem and the next.
      final double b = a + pi / gemCount;
      final Offset p = g.pointAt(b, ring);
      final double pr = band * 0.13;
      canvas.drawCircle(
        p,
        pr,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.4),
            colors: [Colors.white, Color(0xFFF3EBDD), Color(0xFFB9AE9A)],
          ).createShader(Rect.fromCircle(center: p, radius: pr)),
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RoyalWheelFrame &&
      other.goldColor == goldColor &&
      other.gemColor == gemColor &&
      other.gemCount == gemCount &&
      other.plateColor == plateColor &&
      other.shadow == shadow;

  @override
  int get hashCode =>
      Object.hash(goldColor, gemColor, gemCount, plateColor, shadow);
}
