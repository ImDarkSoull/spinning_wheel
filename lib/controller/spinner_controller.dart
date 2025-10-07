import 'package:spinning_wheel/spinner_wheel.dart';

class SpinnerController {
  SpinnerWheelState? _state;

  bool get hasState => _state != null;

  void attach(SpinnerWheelState state) {
    _state = state;
  }

  Future<void> start() async {
    if (_state == null) {
      throw StateError("Please call the attach function first");
    }
    final controller = _state!.animationController;
    if (controller?.isAnimating == false) await controller?.spin();
  }
}
