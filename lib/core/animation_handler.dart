import 'package:flutter/material.dart';

/// Creates the [AnimationController] responsible for the spin, lasting
/// [duration] (5 seconds by default).
///
/// Triggers [onSpinComplete] when the animation finishes.
AnimationController createSpinController(
    TickerProvider vsync, VoidCallback onSpinComplete,
    {Duration duration = const Duration(seconds: 5)}) {
  AnimationController controller = AnimationController(
    vsync: vsync,
    duration: duration,
  );

  controller.addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      onSpinComplete(); // Callback when spin finishes
    }
  });

  return controller;
}
