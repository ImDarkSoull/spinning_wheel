import 'dart:math';
import 'package:flutter/painting.dart';

import 'classic_frame.dart';
import 'neon_frame.dart';
import 'royal_frame.dart';
import 'wooden_frame.dart';

/// Where things are on a wheel, for painting a [WheelFrame].
///
/// All values are in pixels and follow the wheel's size, so a frame painted
/// with them scales with the wheel.
class WheelFrameGeometry {
  /// The size of the area the wheel is painted in.
  final Size size;

  /// The center of the wheel.
  final Offset center;

  /// Half of the wheel's size: from the center to the edge of the area.
  final double radius;

  /// From the center to the outer edge of the slices.
  final double sliceRadius;

  /// Creates a [WheelFrameGeometry] for a wheel of [size] whose slices are
  /// inset by [inset] (a fraction of the size, see `SpinnerWheel.wheelInset`).
  factory WheelFrameGeometry(Size size, double inset) {
    final double side = min(size.width, size.height);
    return WheelFrameGeometry._(
      size: size,
      center: size.center(Offset.zero),
      radius: side / 2,
      sliceRadius: max(0.0, side / 2 - side * inset),
    );
  }

  const WheelFrameGeometry._({
    required this.size,
    required this.center,
    required this.radius,
    required this.sliceRadius,
  });

  /// The outer edge frames should stay inside, leaving a little room for a
  /// drop shadow.
  double get outer => radius * 0.985;

  /// The point at [distance] from the center in the direction [angle]
  /// (radians, clockwise from 3 o'clock).
  Offset pointAt(double angle, double distance) =>
      center + Offset(cos(angle), sin(angle)) * distance;

  /// The bounding square of a circle around the center.
  Rect circle(double r) => Rect.fromCircle(center: center, radius: r);

  /// A ring between two radii, for filling.
  Path ring(double innerRadius, double outerRadius) => Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(circle(outerRadius))
    ..addOval(circle(innerRadius));
}

/// The frame drawn around a `SpinnerWheel`.
///
/// Pick a ready-made frame:
///
/// * [WheelFrame.classic]: a red rim with silver teeth and gold studs.
/// * [WheelFrame.royal]: polished gold set with gems.
/// * [WheelFrame.neon]: glowing tubes on a dark ring.
/// * [WheelFrame.wooden]: a ship's helm with turned wooden handles.
///
/// Or make your own with [WheelFrame.custom], or by extending this class and
/// overriding [paintBack] and [paintFront]. To use an image instead, pass it
/// as `SpinnerWheel.background`.
///
/// Frames are painted in two layers: [paintBack] behind the slices and
/// [paintFront] in front of them, so the slices can sit inside the frame.
abstract class WheelFrame {
  /// Constant constructor for subclasses.
  const WheelFrame();

  /// A red rim with a silver trim, pointed teeth and gold studs.
  const factory WheelFrame.classic({
    Color rimColor,
    Color? rimHighlightColor,
    Color trimColor,
    Color studColor,
    int toothCount,
    int studCount,
    Color plateColor,
    bool shadow,
  }) = ClassicWheelFrame;

  /// Polished gold set with gems and pearls.
  const factory WheelFrame.royal({
    Color goldColor,
    Color gemColor,
    int gemCount,
    Color plateColor,
    bool shadow,
  }) = RoyalWheelFrame;

  /// Two glowing neon tubes on a dark ring.
  const factory WheelFrame.neon({
    Color color,
    Color secondaryColor,
    Color plateColor,
  }) = NeonWheelFrame;

  /// A ship's helm: a wooden rim with brass fittings and turned handles.
  const factory WheelFrame.wooden({
    Color woodColor,
    Color brassColor,
    int handleCount,
    bool shadow,
  }) = WoodenWheelFrame;

  /// A frame painted by your own functions.
  ///
  /// [paintFront] draws over the slices' edge, [paintBack] behind them.
  /// Both get the [WheelFrameGeometry] so they can line up with the slices.
  /// Define them as top-level or static functions rather than inline
  /// closures, so the frame isn't repainted on every rebuild.
  const factory WheelFrame.custom({
    required WheelFramePaint paintFront,
    WheelFramePaint? paintBack,
    double preferredInset,
    Color? indicatorColor,
  }) = CustomWheelFrame;

  /// The `SpinnerWheel.wheelInset` this frame is designed for, used when
  /// the wheel doesn't set one. It decides how much room the frame gets
  /// around the slices.
  double get preferredInset;

  /// A pointer color that suits this frame, used when the wheel doesn't set
  /// `indicatorColor`. Null keeps the default red.
  Color? get indicatorColor => null;

  /// Paints the part of the frame behind the slices.
  void paintBack(Canvas canvas, WheelFrameGeometry geometry) {}

  /// Paints the part of the frame in front of the slices.
  void paintFront(Canvas canvas, WheelFrameGeometry geometry) {}

  /// Whether this frame paints differently from [oldFrame].
  bool shouldRepaint(covariant WheelFrame oldFrame) => oldFrame != this;

  /// Paints a soft drop shadow under a circle of [radius].
  static void paintDropShadow(
      Canvas canvas, WheelFrameGeometry geometry, double radius) {
    canvas.drawCircle(
      geometry.center + Offset(0, geometry.radius * 0.025),
      radius,
      Paint()
        ..color = const Color(0x59000000)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, geometry.radius * 0.035),
    );
  }

  /// Paints a soft shadow on the outer edge of the slices, so they look set
  /// into the frame.
  static void paintSliceShadow(Canvas canvas, WheelFrameGeometry geometry,
      {double strength = 0.33}) {
    final double r = geometry.sliceRadius;
    if (r <= 0) return;
    final double start = max(0.0, (r - geometry.radius * 0.09) / r);
    final Color dark = Color.fromRGBO(0, 0, 0, strength);
    canvas.drawCircle(
      geometry.center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x00000000), const Color(0x00000000), dark],
          stops: [0.0, start, 1.0],
        ).createShader(geometry.circle(r)),
    );
  }

  /// Paints a shiny round stud of [color] at [center].
  static void paintStud(
      Canvas canvas, Offset center, double radius, Color color,
      {bool shadow = true}) {
    if (shadow) {
      canvas.drawCircle(
        center + Offset(0, radius * 0.35),
        radius,
        Paint()
          ..color = const Color(0x66000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4),
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Color.lerp(color, const Color(0xFFFFFFFF), 0.85)!,
            Color.lerp(color, const Color(0xFFFFFFFF), 0.35)!,
            color,
            Color.lerp(color, const Color(0xFF000000), 0.2)!,
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  /// Paints a shaded disc of [color] with [radius], lit from the top left.
  static void paintPlate(
      Canvas canvas, WheelFrameGeometry geometry, double radius, Color color) {
    canvas.drawCircle(
      geometry.center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            Color.lerp(color, const Color(0xFFFFFFFF), 0.5)!,
            color,
            Color.lerp(color, const Color(0xFF000000), 0.25)!,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(geometry.circle(radius)),
    );
  }
}

/// Paints part of a [WheelFrame]. See [WheelFrame.custom].
typedef WheelFramePaint = void Function(
    Canvas canvas, WheelFrameGeometry geometry);

/// A frame painted by functions you provide. See [WheelFrame.custom].
class CustomWheelFrame extends WheelFrame {
  /// Paints in front of the slices.
  final WheelFramePaint paintFrontLayer;

  /// Paints behind the slices.
  final WheelFramePaint? paintBackLayer;

  @override
  final double preferredInset;

  @override
  final Color? indicatorColor;

  /// Creates a [CustomWheelFrame].
  const CustomWheelFrame({
    required WheelFramePaint paintFront,
    WheelFramePaint? paintBack,
    this.preferredInset = 0.094,
    this.indicatorColor,
  })  : paintFrontLayer = paintFront,
        paintBackLayer = paintBack;

  @override
  void paintBack(Canvas canvas, WheelFrameGeometry geometry) =>
      paintBackLayer?.call(canvas, geometry);

  @override
  void paintFront(Canvas canvas, WheelFrameGeometry geometry) =>
      paintFrontLayer(canvas, geometry);

  @override
  bool operator ==(Object other) =>
      other is CustomWheelFrame &&
      other.paintFrontLayer == paintFrontLayer &&
      other.paintBackLayer == paintBackLayer &&
      other.preferredInset == preferredInset &&
      other.indicatorColor == indicatorColor;

  @override
  int get hashCode => Object.hash(
      paintFrontLayer, paintBackLayer, preferredInset, indicatorColor);
}
