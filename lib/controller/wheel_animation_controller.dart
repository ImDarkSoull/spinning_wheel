import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

class WheelAnimationController extends AnimationController {
  final Function(WheelSegment segment, int lastIndex)? onSpinComplete;
  final List<WheelSegment> segments;
  double startRotation;
  double endRotation;
  WheelAnimationController(
      {required super.vsync,
      super.duration,
      required this.segments,
      this.onSpinComplete,
      this.startRotation = 0,
      this.endRotation = 0}) {
    _init();
  }

  int _determineSegment() {
    final double normalizedAngle = endRotation % (2 * pi);
    final double segmentAngle = 2 * pi / segments.length;
    final double invertedAngle = 2 * pi - normalizedAngle;
    final int segmentIndex = (invertedAngle ~/ segmentAngle) % segments.length;

    return segmentIndex;
  }

  Future<void> spin() async {
    reset();
    final Random random = Random();
    final int spinCount = 5 + random.nextInt(5);
    final double extraSpin = random.nextDouble() * 2 * pi;
    endRotation = startRotation + (spinCount * 2 * pi) + extraSpin;
    await forward();
  }

  void _init() {
    addStatusListener(_listener);
  }

  void _listener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      startRotation = endRotation % (2 * pi);
      int index = _determineSegment();
      onSpinComplete?.call(segments.elementAt(index), index);
    }
  }

  @override
  void dispose() {
    removeStatusListener(_listener);
    super.dispose();
  }
}
