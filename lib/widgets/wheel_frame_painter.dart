import 'package:flutter/rendering.dart';

import '../frames/wheel_frame.dart';

/// Which part of the frame a [WheelFramePainter] draws.
enum WheelFrameLayer {
  /// Drawn behind the slices.
  back,

  /// Drawn in front of the slices.
  front,
}

/// Paints one layer of a [WheelFrame], sized to the wheel.
class WheelFramePainter extends CustomPainter {
  /// The frame to paint.
  final WheelFrame frame;

  /// The gap between the wheel's edge and the slices, as a fraction of the
  /// wheel's size.
  final double inset;

  /// Which layer to draw.
  final WheelFrameLayer layer;

  /// Creates a [WheelFramePainter].
  const WheelFramePainter({
    required this.frame,
    required this.inset,
    required this.layer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final WheelFrameGeometry geometry = WheelFrameGeometry(size, inset);
    switch (layer) {
      case WheelFrameLayer.back:
        frame.paintBack(canvas, geometry);
      case WheelFrameLayer.front:
        frame.paintFront(canvas, geometry);
    }
  }

  @override
  bool shouldRepaint(WheelFramePainter oldDelegate) =>
      oldDelegate.inset != inset ||
      oldDelegate.layer != layer ||
      frame.shouldRepaint(oldDelegate.frame);
}
