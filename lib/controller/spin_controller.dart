import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wheel_options.dart';
import '../spinner_wheel.dart';

/// A controller used to programmatically trigger the spinning wheel.
///
/// It is a [ChangeNotifier]: listen to it (e.g. with a `ListenableBuilder`)
/// to rebuild when [isSpinning] or [lastResult] change. If you add listeners,
/// call [dispose] when you no longer need the controller.
class SpinnerController extends ChangeNotifier {
  SpinnerWheelState? _state;
  bool _isSpinning = false;
  WheelSpinResult? _lastResult;
  bool _disposed = false;

  /// Whether a [SpinnerWheel] is currently using this controller.
  bool get isAttached => _state != null;

  /// Whether the wheel is currently spinning.
  bool get isSpinning => _isSpinning;

  /// The result of the most recent finished spin, if any.
  WheelSpinResult? get lastResult => _lastResult;

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
      if (_isSpinning) {
        _isSpinning = false;
        // Detaching happens while the widget tree is being torn down, where
        // listeners must not call setState. Tell them afterwards.
        scheduleMicrotask(_notifyIfAlive);
      }
    }
  }

  /// Triggers the wheel to start spinning based on the configured segments and logic.
  ///
  /// The returned future completes when the wheel stops, after
  /// [SpinnerWheel.onComplete] has been called, with the result of the spin.
  /// It completes with null if the wheel can't spin (no wheel attached, no
  /// segments) or is removed before it stops. Calling this while the wheel
  /// is already spinning does not start a new spin; the current spin's
  /// future is returned instead.
  Future<WheelSpinResult?> startSpin() async {
    if (_state == null) {
      debugPrint("Error: SpinnerWheelState is not attached to the controller!");
      return null;
    }
    return _state!.startSpin();
  }

  /// Spins the wheel so that it lands on the segment at [index], ignoring
  /// probabilities. Useful when the result is decided elsewhere, e.g. by a
  /// server.
  ///
  /// Throws a [RangeError] if [index] is out of range, or an [ArgumentError]
  /// if that segment isn't drawn (a 0-probability segment with
  /// [SliceSizing.proportional]). Otherwise behaves like [startSpin].
  Future<WheelSpinResult?> spinTo(int index) async {
    if (_state == null) {
      debugPrint("Error: SpinnerWheelState is not attached to the controller!");
      return null;
    }
    return _state!.startSpin(targetIndex: index);
  }

  /// Brings a spinning wheel to a quick stop.
  ///
  /// The wheel slows down over a short time and the spin completes with the
  /// segment it actually stops on, which may differ from the one a
  /// [spinTo] call aimed for. Does nothing if the wheel isn't spinning.
  void stop() {
    _state?.stopSpin();
  }

  /// Called internally by the [SpinnerWheel] when a spin starts.
  void handleSpinStarted() {
    _isSpinning = true;
    _notifyIfAlive();
  }

  /// Called internally by the [SpinnerWheel] when a spin ends, with its
  /// [result], or null if the spin was abandoned.
  void handleSpinFinished(WheelSpinResult? result) {
    _isSpinning = false;
    if (result != null) _lastResult = result;
    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
