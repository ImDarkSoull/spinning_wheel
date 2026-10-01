import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/wheel_geometry.dart';
import '../models/wheel_options.dart';
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

  /// The angular layout of the slices.
  final WheelGeometry geometry;

  /// How each slice is filled.
  final SliceStyle sliceStyle;

  /// Color of the lines between slices and around the wheel.
  final Color? borderColor;

  /// Width of the lines between slices and around the wheel. 0 draws none.
  final double borderWidth;

  /// The slice to highlight (e.g. the winner), or null for none. Other
  /// slices are dimmed.
  final int? highlightIndex;

  /// Outline color of the highlighted slice.
  final Color highlightColor;

  /// Direction used to lay out label text.
  final TextDirection textDirection;

  /// Creates a [WheelPainter].
  WheelPainter(
    this.segments, {
    this.imageHeight,
    this.imageWidth,
    this.labelStyle,
    this.slicePadding = EdgeInsets.zero,
    WheelGeometry? geometry,
    this.sliceStyle = SliceStyle.gradient,
    this.borderColor,
    this.borderWidth = 0,
    this.highlightIndex,
    this.highlightColor = Colors.white,
    this.textDirection = TextDirection.ltr,
  }) : geometry = geometry ?? WheelGeometry.equal(segments.length);

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final double radius = size.width / 2;
    final Rect rect =
        Rect.fromCircle(center: Offset(radius, radius), radius: radius);

    for (int i = 0; i < segments.length; i++) {
      final double sweep = geometry.sweeps[i];
      if (sweep <= 0) continue;
      final double angle = geometry.startAngle(i);
      _drawSegment(canvas, rect, angle, sweep, segments[i]);
      _drawImage(canvas, radius, angle, sweep, segments[i]);
      _drawLabel(canvas, rect, angle, sweep, segments[i]);
    }

    _drawBorders(canvas, rect);
    _drawHighlight(canvas, rect);
  }

  void _drawSegment(Canvas canvas, Rect rect, double angle, double segmentAngle,
      WheelSegment segment) {
    final Paint segmentPaint = Paint()..style = PaintingStyle.fill;
    switch (sliceStyle) {
      case SliceStyle.gradient:
        segmentPaint.shader = RadialGradient(
          colors: [segment.color.withValues(alpha: 0.7), segment.color],
          stops: const [0.3, 1.0],
        ).createShader(rect);
      case SliceStyle.flat:
        segmentPaint.color = segment.color;
    }

    canvas.drawPath(_segmentPath(rect, angle, segmentAngle), segmentPaint);
  }

  void _drawImage(Canvas canvas, double radius, double angle,
      double segmentAngle, WheelSegment segment) {
    // Segments with a child widget show the widget instead of the image.
    if (segment.image != null && segment.child == null) {
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

  /// The wedge-shaped outline of a single segment.
  Path _segmentPath(Rect rect, double angle, double segmentAngle) {
    if (segmentAngle >= 2 * pi - 1e-9) {
      return Path()..addOval(rect);
    }
    return Path()
      ..moveTo(rect.center.dx, rect.center.dy)
      ..arcTo(rect, angle, segmentAngle, false)
      ..close();
  }

  void _drawLabel(Canvas canvas, Rect rect, double angle, double segmentAngle,
      WheelSegment segment) {
    final double radius = rect.width / 2;
    final TextOverflow overflow = labelStyle?.overflow ?? TextOverflow.clip;

    // Top padding pushes away from rim, bottom pushes from center
    final double labelRadius =
        (radius * 0.75) - slicePadding.top + slicePadding.bottom;

    final Offset labelCenter = Offset(
      radius + cos(angle + segmentAngle / 2) * labelRadius,
      radius + sin(angle + segmentAngle / 2) * labelRadius,
    );

    canvas.save();
    if (overflow != TextOverflow.visible) {
      canvas.clipPath(_segmentPath(rect, angle, segmentAngle));
    }
    canvas.translate(labelCenter.dx, labelCenter.dy);
    canvas
        .rotate(angle + segmentAngle / 2 + pi / 2 + (labelStyle?.angle ?? 0.0));

    final TextStyle baseStyle = labelStyle?.labelStyle ??
        const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold);
    final TextStyle effectiveStyle = baseStyle.merge(segment.textStyle);

    // Calculate available width at this radius minus horizontal padding.
    // The chord only makes sense for slices narrower than a half circle.
    final double baseWidth = segmentAngle >= pi
        ? 2 * labelRadius
        : 2 * labelRadius * sin(segmentAngle / 2);
    final double availableWidth = max(0.0, baseWidth - slicePadding.horizontal);

    TextPainter textPainter = TextPainter(
      text: TextSpan(text: segment.label, style: effectiveStyle),
      textDirection: textDirection,
      textAlign: TextAlign.center,
      ellipsis: overflow == TextOverflow.ellipsis ? '...' : null,
      maxLines: labelStyle?.maxLines,
    );

    textPainter.layout(maxWidth: availableWidth);
    final Offset textOffset =
        Offset(-textPainter.width / 2, -textPainter.height / 2);

    if (overflow == TextOverflow.fade && textPainter.didExceedMaxLines) {
      _paintFaded(canvas, textPainter, textOffset);
    } else {
      textPainter.paint(canvas, textOffset);
    }
    textPainter.dispose();
    canvas.restore();
  }

  /// Paints [textPainter] with its trailing edge faded out, like
  /// [TextOverflow.fade]: horizontally for single-line labels, vertically
  /// for multi-line labels.
  void _paintFaded(Canvas canvas, TextPainter textPainter, Offset offset) {
    final Rect bounds = offset & textPainter.size;
    final double fadeSize = textPainter.preferredLineHeight;
    final bool horizontal = (labelStyle?.maxLines ?? 1) == 1;
    final bool rtl = textDirection == TextDirection.rtl;

    final Shader shader = LinearGradient(
      begin: horizontal
          ? (rtl ? Alignment.centerRight : Alignment.centerLeft)
          : Alignment.topCenter,
      end: horizontal
          ? (rtl ? Alignment.centerLeft : Alignment.centerRight)
          : Alignment.bottomCenter,
      colors: const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
    ).createShader(horizontal
        ? (rtl
            ? Rect.fromLTRB(bounds.left, bounds.top,
                min(bounds.right, bounds.left + fadeSize), bounds.bottom)
            : Rect.fromLTRB(max(bounds.left, bounds.right - fadeSize),
                bounds.top, bounds.right, bounds.bottom))
        : Rect.fromLTRB(bounds.left, max(bounds.top, bounds.bottom - fadeSize),
            bounds.right, bounds.bottom));

    canvas.saveLayer(bounds, Paint());
    textPainter.paint(canvas, offset);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = shader
        ..blendMode = BlendMode.dstIn,
    );
    canvas.restore();
  }

  void _drawBorders(Canvas canvas, Rect rect) {
    if (borderWidth <= 0) return;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderColor ?? Colors.white;
    final int visible = geometry.sweeps.where((s) => s > 0).length;
    if (visible > 1) {
      for (int i = 0; i < segments.length; i++) {
        if (geometry.sweeps[i] <= 0) continue;
        final double a = geometry.startAngle(i);
        canvas.drawLine(
          rect.center,
          rect.center + Offset(cos(a), sin(a)) * (rect.width / 2),
          paint,
        );
      }
    }
    canvas.drawCircle(rect.center, rect.width / 2 - borderWidth / 2, paint);
  }

  void _drawHighlight(Canvas canvas, Rect rect) {
    final int? index = highlightIndex;
    if (index == null || index < 0 || index >= segments.length) return;

    final Paint dim = Paint()..color = const Color(0x73000000);
    for (int i = 0; i < segments.length; i++) {
      if (i == index || geometry.sweeps[i] <= 0) continue;
      canvas.drawPath(
          _segmentPath(rect, geometry.startAngle(i), geometry.sweeps[i]), dim);
    }

    final double width = max(3.0, rect.width * 0.015);
    canvas.save();
    // Keep the outline inside the slice so it isn't cut off at the rim.
    final Path path =
        _segmentPath(rect, geometry.startAngle(index), geometry.sweeps[index]);
    canvas.clipPath(path);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 2
        ..color = highlightColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) =>
      oldDelegate.segments != segments ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.slicePadding != slicePadding ||
      oldDelegate.imageHeight != imageHeight ||
      oldDelegate.imageWidth != imageWidth ||
      !listEquals(oldDelegate.geometry.sweeps, geometry.sweeps) ||
      oldDelegate.sliceStyle != sliceStyle ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.highlightIndex != highlightIndex ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.textDirection != textDirection;
}
