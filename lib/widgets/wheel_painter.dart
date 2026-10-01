import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wheel_segment.dart';
import '../models/wheel_label_style.dart';

/// Custom painter used to render the wheel segments, labels, and icons.
class WheelPainter extends CustomPainter {
  /// The list of segments to render.
  final List<WheelSegment> segments;

  /// Custom height for segment icons.
  final double? imageHeight;

  /// Custom width for segment icons.
  final double? imageWidth;

  /// Configuration for the label style.
  final WheelLabelStyle? labelStyle;

  /// Radial padding within segments.
  final EdgeInsets slicePadding;

  /// Creates a [WheelPainter].
  WheelPainter(this.segments,
      {this.imageHeight,
      this.imageWidth,
      this.labelStyle,
      this.slicePadding = EdgeInsets.zero});

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final double radius = size.width / 2;
    final Rect rect =
        Rect.fromCircle(center: Offset(radius, radius), radius: radius);
    final double segmentAngle = 2 * pi / segments.length;
    final double startAngle = -pi / 2 - segmentAngle / 40;

    for (int i = 0; i < segments.length; i++) {
      _drawSegment(canvas, rect, startAngle + i * segmentAngle, segmentAngle,
          segments[i]);
      _drawImage(canvas, radius, startAngle + i * segmentAngle, segmentAngle,
          segments[i]);
      _drawLabel(canvas, radius, startAngle + i * segmentAngle, segmentAngle,
          segments[i]);
    }
  }

  void _drawSegment(Canvas canvas, Rect rect, double angle, double segmentAngle,
      WheelSegment segment) {
    final Paint segmentPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [segment.color.withValues(alpha: 0.7), segment.color],
        stops: const [0.3, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, angle, segmentAngle, true, segmentPaint);
  }

  void _drawImage(Canvas canvas, double radius, double angle,
      double segmentAngle, WheelSegment segment) {
    if (segment.image != null) {
      // Top padding pushes away from rim, bottom padding pushes away from center
      final double imageRadius =
          (radius * 0.55) - slicePadding.top + slicePadding.bottom;
      final Offset imageCenter = Offset(
        radius + cos(angle + segmentAngle / 2) * imageRadius,
        radius + sin(angle + segmentAngle / 2) * imageRadius,
      );

      canvas.save();
      canvas.translate(imageCenter.dx, imageCenter.dy);
      canvas.rotate(angle + segmentAngle / 2 + pi / 2);

      final Rect srcRect = Rect.fromLTWH(0, 0, segment.image!.width.toDouble(),
          segment.image!.height.toDouble());
      final Rect dstRect = Rect.fromCenter(
        center: const Offset(0, 0),
        width: imageWidth ?? radius * 0.28,
        height: imageHeight ?? radius * 0.28,
      );

      canvas.drawImageRect(segment.image!, srcRect, dstRect, Paint());
      canvas.restore();
    }
  }

  void _drawLabel(Canvas canvas, double radius, double angle,
      double segmentAngle, WheelSegment segment) {
    // Top padding pushes away from rim, bottom pushes from center
    final double labelRadius =
        (radius * 0.75) - slicePadding.top + slicePadding.bottom;

    final Offset labelCenter = Offset(
      radius + cos(angle + segmentAngle / 2) * labelRadius,
      radius + sin(angle + segmentAngle / 2) * labelRadius,
    );

    canvas.save();
    canvas.translate(labelCenter.dx, labelCenter.dy);
    canvas
        .rotate(angle + segmentAngle / 2 + pi / 2 + (labelStyle?.angle ?? 0.0));

    final TextStyle? effectiveStyle = labelStyle?.labelStyle;

    // Calculate available width at this radius minus horizontal padding
    final double baseWidth = 2 * labelRadius * sin(segmentAngle / 2);
    final double availableWidth = max(0.0, baseWidth - slicePadding.horizontal);

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: segment.label,
        style: effectiveStyle ??
            const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      ellipsis: labelStyle?.overflow == TextOverflow.ellipsis ? '...' : null,
      maxLines: labelStyle?.maxLines,
    );

    textPainter.layout(maxWidth: availableWidth);
    textPainter.paint(
        canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.slicePadding != slicePadding;
}
