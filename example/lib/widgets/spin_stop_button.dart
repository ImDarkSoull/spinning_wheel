import 'package:flutter/material.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

/// A button that spins the wheel, and turns into a stop button while it
/// spins.
///
/// It listens to [controller], so it rebuilds by itself when a spin starts
/// or ends, even when the spin was started by a tap or swipe on the wheel.
class SpinStopButton extends StatelessWidget {
  final SpinnerController controller;

  /// Called to start a spin. Defaults to [SpinnerController.startSpin].
  final VoidCallback? onSpin;

  /// Whether a new spin may start.
  final bool enabled;

  const SpinStopButton({
    super.key,
    required this.controller,
    this.onSpin,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final bool spinning = controller.isSpinning;
        return FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 56),
            backgroundColor: spinning ? Colors.redAccent : null,
            textStyle:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          onPressed: spinning
              ? controller.stop
              : (enabled ? (onSpin ?? controller.startSpin) : null),
          icon: Icon(spinning ? Icons.pan_tool : Icons.touch_app),
          label: Text(spinning ? 'stop!' : 'spin!'),
        );
      },
    );
  }
}
