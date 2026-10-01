import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

/// An example of your own frame: a peppermint-candy ring of red and white
/// stripes, made with [WheelFrame.custom].
///
/// The painting functions are top-level, so the frame can be `const` and is
/// only repainted when the wheel's size changes.
const WheelFrame candyFrame = WheelFrame.custom(
  paintBack: _paintCandyBack,
  paintFront: _paintCandyFront,
  preferredInset: 0.08,
  indicatorColor: Color(0xFF2E7D32),
);

/// Behind the slices: a drop shadow and a white plate.
void _paintCandyBack(Canvas canvas, WheelFrameGeometry g) {
  WheelFrame.paintDropShadow(canvas, g, g.outer);
  WheelFrame.paintPlate(canvas, g, g.sliceRadius, Colors.white);
}

/// In front of the slices: the striped ring, a shine and an outline.
void _paintCandyFront(Canvas canvas, WheelFrameGeometry g) {
  // `sliceRadius` is where the slices end, so the ring starts right there.
  final double inner = g.sliceRadius;
  final double outer = g.outer;
  if (outer <= inner) return;
  WheelFrame.paintSliceShadow(canvas, g);

  // Alternating red and white stripes, each a twisted wedge of the ring.
  const int stripes = 28;
  final double step = 2 * pi / stripes;
  canvas.drawPath(g.ring(inner, outer), Paint()..color = Colors.white);
  // Clip to the ring, so the stripes' corners can't spill out of it.
  canvas.save();
  canvas.clipPath(g.ring(inner, outer));
  final Paint red = Paint()..color = const Color(0xFFE53935);
  for (int i = 0; i < stripes; i += 2) {
    final double a = -pi / 2 + i * step;
    final double twist = step * 0.6;
    final Offset p1 = g.pointAt(a, inner);
    final Offset p2 = g.pointAt(a + twist, outer);
    final Offset p3 = g.pointAt(a + step + twist, outer);
    final Offset p4 = g.pointAt(a + step, inner);
    canvas.drawPath(
      Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close(),
      red,
    );
  }
  canvas.restore();

  // A glossy shine across the top, like hard candy.
  canvas.drawPath(
    g.ring(inner, outer),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x88FFFFFF), Color(0x00FFFFFF), Color(0x22000000)],
      ).createShader(g.circle(outer)),
  );
  final Paint outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.0, g.radius * 0.012)
    ..color = const Color(0xFFB71C1C);
  canvas.drawCircle(g.center, outer, outline);
  canvas.drawCircle(g.center, inner, outline);
}
