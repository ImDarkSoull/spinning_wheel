import 'dart:async';
import 'dart:ui' as ui;
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
  final void Function(WheelSegment segment, int index) onComplete;

  /// An optional tint color applied to the default wheel background.
  final Color? wheelColor;

  /// How [wheelColor] is blended with the default wheel background.
  ///
  /// The default, [BlendMode.modulate], tints the image while keeping its
  /// shading. Use [BlendMode.srcIn] to paint it as a solid color.
  final BlendMode wheelColorBlendMode;

  /// Gap between the wheel's outer edge and the segments, as a fraction of
  /// the wheel size (0.0 to 0.5).
  ///
  /// The default leaves room for the rim of the built-in background. Use 0
  /// to let the segments fill the whole wheel.
  final double wheelInset;

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
    this.wheelColorBlendMode = BlendMode.modulate,
    this.wheelInset = 0.094,
    this.indicatorColor,
    this.centerChild,
    this.indicator,
    this.imageHeight,
    this.imageWidth,
    this.labelStyle,
    this.background,
    this.shouldDrawBackground = true,
    this.slicePadding = EdgeInsets.zero,
  }) : assert(wheelInset >= 0 && wheelInset < 0.5,
            'wheelInset must be between 0.0 and 0.5');

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

  /// Completes when the current spin finishes.
  Completer<void>? _spinCompleter;

  /// Incremented on every image load so that stale loads are discarded.
  int _loadGeneration = 0;
  bool _imagesRequested = false;

  /// Images this state loaded itself and therefore has to dispose.
  List<ui.Image> _ownedImages = [];

  @override
  void initState() {
    super.initState();
    widget.controller.attachState(this);
    _sourceSegments = List.of(widget.segments);
    processedSegments = _sourceSegments;
    _controller = createSpinController(this, _onSpinComplete);
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Image loading needs the device pixel ratio from context, which isn't
    // available in initState.
    if (!_imagesRequested) {
      _imagesRequested = true;
      processSegments();
    }
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
    _spinCompleter?.complete();
    _spinCompleter = null;
  }

  /// Loads images for all segments asynchronously.
  ///
  /// The segments are shown right away and their images appear once loaded.
  void processSegments() async {
    final int generation = ++_loadGeneration;
    final List<WheelSegment> source = List.of(widget.segments);
    _sourceSegments = source;
    processedSegments = source;

    final List<WheelSegment> loaded = await loadSegmentImages(
      source,
      configuration: createLocalImageConfiguration(context),
    );
    final List<ui.Image> newImages = [
      for (int i = 0; i < loaded.length; i++)
        if (loaded[i].image != null &&
            !identical(loaded[i].image, source[i].image))
          loaded[i].image!,
    ];

    if (!mounted || generation != _loadGeneration) {
      for (final image in newImages) {
        image.dispose();
      }
      return;
    }

    final List<ui.Image> oldImages = _ownedImages;
    setState(() {
      processedSegments = loaded;
      _ownedImages = newImages;
    });
    for (final image in oldImages) {
      image.dispose();
    }
  }

  /// Programmatically starts the spin animation.
  ///
  /// The returned future completes when the wheel stops, after
  /// [SpinnerWheel.onComplete] has been called. If the wheel is already
  /// spinning, no new spin starts and the current spin's future is returned.
  /// If there are no segments, nothing happens.
  Future<void> startSpin() {
    if (_controller.isAnimating && _spinCompleter != null) {
      return _spinCompleter!.future;
    }
    if (widget.segments.isEmpty) {
      debugPrint('SpinnerWheel: cannot spin, segments is empty.');
      return Future.value();
    }
    _controller.reset();
    _spinSegments = List.of(widget.segments);
    final result = spinWheel(_startRotation, _spinSegments);
    setState(() {
      _spinIndex = result.index;
      _endRotation = result.end;
    });
    final completer = Completer<void>();
    _spinCompleter = completer;
    _controller.forward();
    return completer.future;
  }

  @override
  void dispose() {
    widget.controller.detachState(this);
    // Don't leave callers awaiting a spin that will never finish.
    _spinCompleter?.complete();
    _spinCompleter = null;
    _animation.dispose();
    _controller.dispose();
    for (final image in _ownedImages) {
      image.dispose();
    }
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
      wheelColorBlendMode: widget.wheelColorBlendMode,
      wheelInset: widget.wheelInset,
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
