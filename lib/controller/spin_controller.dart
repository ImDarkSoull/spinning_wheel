import 'package:flutter/foundation.dart';
import '../spinner_wheel.dart';

/// A controller used to programmatically trigger the spinning wheel.
class SpinnerController {
  SpinnerWheelState? _state;

  /// Attaches the controller to a [SpinnerWheelState].
  /// This is called internally by the [SpinnerWheel].
  void attachState(SpinnerWheelState state) {
    _state = state;
  }

  /// Detaches the controller from [state], if it is the one attached.
  /// This is called internally when the [SpinnerWheel] is disposed or
  /// switches to a different controller.
  void detachState(SpinnerWheelState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }

  /// Triggers the wheel to start spinning based on the configured segments and logic.
  ///
  /// The returned future completes when the wheel stops, after
  /// [SpinnerWheel.onComplete] has been called. Calling this while the wheel
  /// is already spinning does not start a new spin.
  Future<void> startSpin() async {
    if (_state != null) {
      await _state!.startSpin();
    } else {
      debugPrint("Error: SpinnerWheelState is not attached to the controller!");
    }
  }
}
