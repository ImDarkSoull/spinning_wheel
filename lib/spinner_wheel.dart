import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../core/animation_handler.dart';
import '../core/spin_calculations.dart';
import '../core/image_loader.dart';
import '../widgets/wheel_display.dart';
import '../models/wheel_segment.dart';
import '../models/wheel_label_style.dart';
import '../controller/spin_controller.dart';

/// A customizable spinning wheel widget.
///
/// The [SpinnerWheel] allows you to create an interactive wheel with multiple
/// [WheelSegment]s. It supports custom backgrounds, center widgets, indicators,
/// and smooth spin animations controlled by a [SpinnerController].
class SpinnerWheel extends StatefulWidget {
  /// Controls the spin animation of the wheel.
  final SpinnerController controller;

  /// The list of segments (slices) to display on the wheel.
  final List<WheelSegment> segments;

  /// Callback called when the wheel stops spinning.
  /// Returns the selected [WheelSegment] and its index.
  final Function(WheelSegment, int) onComplete;

  /// An optional tint color applied to the default wheel background.
  final Color? wheelColor;

  /// The color of the default indicator.
  final Color? indicatorColor;

  /// A custom widget to display at the center of the wheel (e.g., a button or logo).
  final Widget? centerChild;

  /// A custom widget for the wheel's indicator (the "pointer").
  final Widget? indicator;

  /// The height of images displayed within segments.
  final double? imageHeight;

  /// The width of images displayed within segments.
  final double? imageWidth;

  /// Configuration for the label style (text style, angle, etc.).
  final WheelLabelStyle? labelStyle;

  /// A custom background widget displayed behind the segments.
  final Widget? background;

  /// Whether to draw the default or provided background layer.
  final bool shouldDrawBackground;

  /// Padding within segments for images and text.
  final EdgeInsets slicePadding;

  /// Creates a [SpinnerWheel].
  const SpinnerWheel({
    super.key,
    required this.controller,
    required this.segments,
    required this.onComplete,
    this.wheelColor,
    this.indicatorColor,
    this.centerChild,
    this.indicator,
    this.imageHeight,
    this.imageWidth,
    this.labelStyle,
    this.background,
    this.shouldDrawBackground = true,
    this.slicePadding = EdgeInsets.zero,
  });

  @override
  State<SpinnerWheel> createState() => SpinnerWheelState();
}

/// The state of the [SpinnerWheel] which manages animations and image loading.
class SpinnerWheelState extends State<SpinnerWheel>
    with SingleTickerProviderStateMixin {
  /// The list of segments after their images have been loaded.
  List<WheelSegment> processedSegments = [];
  late AnimationController _controller;
  late CurvedAnimation _animation;
  double _startRotation = 0.0, _endRotation = 0.0;

  /// Snapshot of [SpinnerWheel.segments] used to detect changes, including
  /// in-place edits of the same list instance.
  List<WheelSegment> _sourceSegments = [];

  /// The segments and winning index of the spin currently in progress.
  List<WheelSegment> _spinSegments = [];
  int _spinIndex = 0;

  /// Incremented on every image load so that stale loads are discarded.
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.attachState(this);
    processSegments();
    _controller = createSpinController(this, _onSpinComplete);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc);
  }

  @override
  void didUpdateWidget(covariant SpinnerWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.detachState(this);
      widget.controller.attachState(this);
    }
    if (!listEquals(_sourceSegments, widget.segments)) {
      processSegments();
    }
  }

  void _onSpinComplete() {
    setState(() {
      _startRotation = _endRotation % (2 * pi);
    });
    if (_spinIndex < _spinSegments.length) {
      widget.onComplete(_spinSegments[_spinIndex], _spinIndex);
    }
  }

  /// Loads images for all segments asynchronously.
  ///
  /// The segments are shown right away and their images appear once loaded.
  void processSegments() async {
    final int generation = ++_loadGeneration;
    _sourceSegments = List.of(widget.segments);
    processedSegments = _sourceSegments;
    final loaded = await loadSegmentImages(_sourceSegments);
    if (mounted && generation == _loadGeneration) {
      setState(() {
        processedSegments = loaded;
      });
    }
  }

  /// Programmatically starts the spin animation.
  ///
  /// Does nothing if the wheel is already spinning or has no segments.
  Future<void> startSpin() async {
    if (_controller.isAnimating) return;
    if (widget.segments.isEmpty) {
      debugPrint('SpinnerWheel: cannot spin, segments is empty.');
      return;
    }
    _controller.reset();
    _spinSegments = List.of(widget.segments);
    final result = spinWheel(_startRotation, _spinSegments);
    setState(() {
      _spinIndex = result.index;
      _endRotation = result.end;
    });
    _controller.forward();
  }

  @override
  void dispose() {
    widget.controller.detachState(this);
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WheelDisplay(
      animation: _animation,
      segments: processedSegments,
      startRotation: _startRotation,
      endRotation: _endRotation,
      centerChild: widget.centerChild,
      indicator: widget.indicator,
      wheelColor: widget.wheelColor,
      indicatorColor: widget.indicatorColor,
      imageHeight: widget.imageHeight,
      imageWidth: widget.imageWidth,
      labelStyle: widget.labelStyle,
      background: widget.background,
      shouldDrawBackground: widget.shouldDrawBackground,
      slicePadding: widget.slicePadding,
    );
  }
}
