import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../core/animation_handler.dart';
import '../core/spin_calculations.dart';
import '../core/image_loader.dart';
import '../core/wheel_geometry.dart';
import '../widgets/wheel_display.dart';
import '../models/wheel_options.dart';
import '../models/wheel_segment.dart';
import '../models/wheel_label_style.dart';
import '../controller/spin_controller.dart';

/// A customizable spinning wheel widget.
///
/// The [SpinnerWheel] allows you to create an interactive wheel with multiple
/// [WheelSegment]s. It supports custom backgrounds, center widgets, indicators,
/// and smooth spin animations controlled by a [SpinnerController].
///
/// [T] is the type of the segments' [WheelSegment.value]; it is usually
/// inferred from [segments].
class SpinnerWheel<T> extends StatefulWidget {
  /// Controls the spin animation of the wheel.
  final SpinnerController controller;

  /// The list of segments (slices) to display on the wheel.
  final List<WheelSegment<T>> segments;

  /// Callback called when the wheel stops spinning.
  /// Returns the selected [WheelSegment] and its index.
  final void Function(WheelSegment<T> segment, int index) onComplete;

  /// Called when a spin starts, whether from the controller, a tap or a
  /// swipe.
  final VoidCallback? onSpinStart;

  /// Called every time a new segment passes under the indicator, while
  /// spinning or dragging. Handy for tick sounds or haptic feedback.
  final void Function(int index)? onSegmentPass;

  /// How long a spin takes.
  ///
  /// A spin may take longer if it could otherwise only be done by turning
  /// too fast (see [maxSpins]).
  final Duration spinDuration;

  /// The easing of a spin started from the controller or a tap.
  ///
  /// The default, [Curves.decelerate], slows down evenly like friction.
  /// Curves that overshoot, such as [Curves.easeOutBack] or
  /// [Curves.elasticOut], turn the wheel backwards at the end by design.
  /// Swipes always use a curve that starts at the swipe's speed.
  final Curve spinCurve;

  /// The fewest whole turns a spin makes before slowing to a stop.
  final int minSpins;

  /// The most whole turns a spin makes before slowing to a stop.
  ///
  /// The wheel never turns faster than 40% of a slice per frame, because
  /// beyond half a slice per frame it looks like it is spinning backwards
  /// (the "wagon-wheel" effect). If [minSpins]–[maxSpins] turns can't be
  /// done within [spinDuration] at that speed, the spin makes fewer turns.
  /// Wheels with many slices therefore turn fewer times; a longer
  /// [spinDuration] allows more turns.
  final int maxSpins;

  /// Whether tapping the center of the wheel starts a spin.
  final bool tapToSpin;

  /// Whether the wheel can be dragged around and flung to spin it.
  ///
  /// A fast enough fling spins the wheel in the fling's direction; the
  /// result still follows the segments' probabilities.
  final bool swipeToSpin;

  /// Which side of the wheel the indicator sits on.
  final IndicatorPosition indicatorPosition;

  /// Whether the indicator flicks each time a segment passes under it.
  final bool indicatorBounce;

  /// How the sizes of the slices are decided.
  final SliceSizing sliceSizing;

  /// How each slice is filled.
  final SliceStyle sliceStyle;

  /// Color of the lines between slices and around the wheel.
  final Color? sliceBorderColor;

  /// Width of the lines between slices and around the wheel. 0 draws none.
  final double sliceBorderWidth;

  /// Whether to highlight the winning slice (and dim the others) after a
  /// spin. The highlight clears when the next spin starts.
  final bool highlightWinner;

  /// Outline color of the highlighted winning slice.
  final Color highlightColor;

  /// Shown in place of a segment's image while it loads.
  final Widget? imagePlaceholder;

  /// Shown in place of a segment's image if it fails to load.
  final Widget? imageErrorWidget;

  /// Called when a segment's image fails to load.
  final void Function(WheelSegment<T> segment, Object error)? onImageError;

  /// A description of the wheel for screen readers. Defaults to
  /// "Spinning wheel".
  final String? semanticsLabel;

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
  ///
  /// Design it pointing down; it is rotated to point at the center from
  /// the side set by [indicatorPosition].
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
    this.onSpinStart,
    this.onSegmentPass,
    this.spinDuration = const Duration(seconds: 5),
    this.spinCurve = Curves.decelerate,
    this.minSpins = 5,
    this.maxSpins = 9,
    this.tapToSpin = false,
    this.swipeToSpin = false,
    this.indicatorPosition = IndicatorPosition.top,
    this.indicatorBounce = false,
    this.sliceSizing = SliceSizing.equal,
    this.sliceStyle = SliceStyle.gradient,
    this.sliceBorderColor,
    this.sliceBorderWidth = 0,
    this.highlightWinner = false,
    this.highlightColor = Colors.white,
    this.imagePlaceholder,
    this.imageErrorWidget,
    this.onImageError,
    this.semanticsLabel,
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
  })  : assert(wheelInset >= 0 && wheelInset < 0.5,
            'wheelInset must be between 0.0 and 0.5'),
        assert(minSpins >= 0 && minSpins <= maxSpins,
            'minSpins must be between 0 and maxSpins'),
        assert(sliceBorderWidth >= 0, 'sliceBorderWidth must not be negative');

  @override
  State<SpinnerWheel<T>> createState() => SpinnerWheelState<T>();
}

/// The state of the [SpinnerWheel] which manages animations and image loading.
class SpinnerWheelState<T> extends State<SpinnerWheel<T>>
    with TickerProviderStateMixin {
  /// The list of segments, with their images once they have been loaded.
  List<WheelSegment<T>> processedSegments = [];
  late AnimationController _controller;
  late CurvedAnimation _animation;

  /// Drives the indicator's flick when [SpinnerWheel.indicatorBounce] is on.
  late AnimationController _tickController;

  /// The wheel's rotation is `lerp(_from, _to, _animation.value)`.
  double _from = 0.0, _to = 0.0;

  /// Snapshot of [SpinnerWheel.segments] used to detect changes, including
  /// in-place edits of the same list instance.
  List<WheelSegment<T>> _sourceSegments = [];
  WheelGeometry _geometry = WheelGeometry.equal(0);

  /// The segments, layout and winning index of the spin in progress.
  List<WheelSegment<T>> _spinSegments = [];
  WheelGeometry _spinGeometry = WheelGeometry.equal(0);
  int _spinIndex = 0;
  bool _clockwise = true;
  bool _stopping = false;

  /// Completes when the current spin finishes. Non-null while spinning.
  Completer<WheelSpinResult<T>?>? _spinCompleter;

  int? _highlightIndex;
  int? _lastPassIndex;

  bool _dragging = false;
  Offset _lastDragPosition = Offset.zero;

  /// Fling speed (radians per second) below which a released drag doesn't
  /// spin the wheel.
  static const double _minFlingVelocity = pi;

  /// Incremented on every image load so that stale loads are discarded.
  int _loadGeneration = 0;
  bool _imagesRequested = false;
  List<ImageLoadState> _imageStates = [];

  /// Images this state loaded itself and therefore has to dispose, by
  /// segment index.
  List<ui.Image?> _ownedImages = [];

  double get _pointerAngle => widget.indicatorPosition.angle;

  double get _currentRotation => ui.lerpDouble(_from, _to, _animation.value)!;

  /// The rotation the current (or last) spin started from. For tests.
  @visibleForTesting
  double get debugSpinStart => _from;

  /// The rotation the current (or last) spin ends at. For tests.
  @visibleForTesting
  double get debugSpinEnd => _to;

  @override
  void initState() {
    super.initState();
    widget.controller.attachState(this);
    _controller = createSpinController(this, _onSpinComplete,
        duration: widget.spinDuration);
    _controller.addListener(_checkSegmentPass);
    _animation = CurvedAnimation(parent: _controller, curve: widget.spinCurve);
    _tickController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));
    _resetSegments();
    _lastPassIndex = _indexUnderPointer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Image loading needs the device pixel ratio from context, which isn't
    // available in initState.
    if (!_imagesRequested) {
      _imagesRequested = true;
      _startImageLoads(_loadGeneration);
    }
  }

  @override
  void didUpdateWidget(covariant SpinnerWheel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.detachState(this);
      widget.controller.attachState(this);
    }
    if (!listEquals(_sourceSegments, widget.segments)) {
      processSegments();
    } else if (oldWidget.sliceSizing != widget.sliceSizing) {
      _geometry = geometryFor(_sourceSegments, widget.sliceSizing);
      _highlightIndex = null;
    }
  }

  int? _indexUnderPointer() => _geometry.length == 0
      ? null
      : _geometry.indexAt(_currentRotation, _pointerAngle);

  void _checkSegmentPass() {
    final int? index = _indexUnderPointer();
    if (index == null || index == _lastPassIndex) return;
    _lastPassIndex = index;
    if (widget.indicatorBounce) _tickController.forward(from: 0);
    widget.onSegmentPass?.call(index);
  }

  void _onSpinComplete() {
    final double rest = _to % (2 * pi);
    final WheelSpinResult<T>? result = _spinIndex < _spinSegments.length
        ? WheelSpinResult<T>(_spinSegments[_spinIndex], _spinIndex)
        : null;
    setState(() {
      _from = rest;
      _to = rest;
      _stopping = false;
      if (widget.highlightWinner && result != null) {
        _highlightIndex = result.index;
      }
    });
    final completer = _spinCompleter;
    _spinCompleter = null;
    widget.controller.handleSpinFinished(result);
    if (result != null) widget.onComplete(result.segment, result.index);
    completer?.complete(result);
  }

  /// Loads images for all segments asynchronously.
  ///
  /// The segments are shown right away and each image appears once loaded.
  void processSegments() {
    _resetSegments();
    _startImageLoads(_loadGeneration);
  }

  /// Takes a new snapshot of [SpinnerWheel.segments], keeping images already
  /// loaded for segments that are still there.
  void _resetSegments() {
    _loadGeneration++;
    final List<WheelSegment<T>> previous = _sourceSegments;
    final List<WheelSegment<T>> previousProcessed = processedSegments;
    final List<ui.Image?> previousOwned = _ownedImages;
    final List<ImageLoadState> previousStates = _imageStates;

    final List<WheelSegment<T>> source = List.of(widget.segments);
    final List<WheelSegment<T>> processed = List.of(source);
    final List<ui.Image?> owned = List.filled(source.length, null);
    final List<ImageLoadState> states = [
      for (final s in source)
        s.needsImageLoad
            ? ImageLoadState.loading
            : (s.image != null ? ImageLoadState.loaded : ImageLoadState.none),
    ];

    final Set<int> reused = {};
    for (int i = 0; i < source.length; i++) {
      if (states[i] != ImageLoadState.loading) continue;
      for (int j = 0; j < previous.length; j++) {
        if (identical(previous[j], source[i]) &&
            !reused.contains(j) &&
            j < previousStates.length &&
            previousStates[j] != ImageLoadState.loading) {
          reused.add(j);
          processed[i] = previousProcessed[j];
          owned[i] = previousOwned[j];
          states[i] = previousStates[j];
          break;
        }
      }
    }

    for (int j = 0; j < previousOwned.length; j++) {
      if (!reused.contains(j)) previousOwned[j]?.dispose();
    }

    _sourceSegments = source;
    processedSegments = processed;
    _ownedImages = owned;
    _imageStates = states;
    _geometry = geometryFor(source, widget.sliceSizing);
    _highlightIndex = null;
  }

  void _startImageLoads(int generation) {
    if (!_imagesRequested) return;
    final ImageConfiguration configuration =
        createLocalImageConfiguration(context);
    final List<WheelSegment<T>> source = _sourceSegments;
    for (int i = 0; i < source.length; i++) {
      if (_imageStates[i] != ImageLoadState.loading) continue;
      final WheelSegment<T> segment = source[i];
      final int index = i;
      loadSegmentImage(segment, configuration: configuration).then(
        (ui.Image image) {
          if (!mounted || generation != _loadGeneration) {
            image.dispose();
            return;
          }
          setState(() {
            processedSegments = List.of(processedSegments)
              ..[index] = segment.copyWith(image: image);
            _ownedImages[index] = image;
            _imageStates = List.of(_imageStates)
              ..[index] = ImageLoadState.loaded;
          });
        },
        onError: (Object error) {
          if (!mounted || generation != _loadGeneration) return;
          setState(() {
            _imageStates = List.of(_imageStates)
              ..[index] = ImageLoadState.failed;
          });
          if (widget.onImageError != null) {
            widget.onImageError!(segment, error);
          } else {
            debugPrint(
                'Error loading image for segment ${segment.label}: $error');
          }
        },
      );
    }
  }

  /// Programmatically starts the spin animation.
  ///
  /// If [targetIndex] is given, the wheel lands on that segment; otherwise
  /// the result is picked using the segments' probabilities.
  ///
  /// The returned future completes when the wheel stops, after
  /// [SpinnerWheel.onComplete] has been called. If the wheel is already
  /// spinning, no new spin starts and the current spin's future is returned.
  /// If there are no segments, nothing happens and the future completes with
  /// null.
  Future<WheelSpinResult<T>?> startSpin({int? targetIndex}) {
    if (_spinCompleter != null) return _spinCompleter!.future;
    if (widget.segments.isEmpty) {
      debugPrint('SpinnerWheel: cannot spin, segments is empty.');
      return Future.value();
    }
    final List<WheelSegment<T>> segments = List.of(widget.segments);
    final WheelGeometry geometry = geometryFor(segments, widget.sliceSizing);
    final Random random = Random.secure();

    final int index;
    if (targetIndex != null) {
      RangeError.checkValidIndex(targetIndex, segments, 'targetIndex');
      if (geometry.sweeps[targetIndex] <= 0) {
        throw ArgumentError.value(targetIndex, 'targetIndex',
            'Segment has probability 0 and is not drawn on the wheel');
      }
      index = targetIndex;
    } else {
      index = pickWeightedIndex(effectiveProbabilities(segments), random);
    }

    return _launchSpin(
      segments: segments,
      geometry: geometry,
      index: index,
      fullTurns: widget.minSpins +
          random.nextInt(widget.maxSpins - widget.minSpins + 1),
      clockwise: true,
      duration: widget.spinDuration,
      curve: widget.spinCurve,
      random: random,
    );
  }

  Future<WheelSpinResult<T>?> _launchSpin({
    required List<WheelSegment<T>> segments,
    required WheelGeometry geometry,
    required int index,
    required int fullTurns,
    required bool clockwise,
    required Duration duration,
    required Curve curve,
    required Random random,
  }) {
    _dragging = false;
    final double start = _currentRotation;
    SpinResult plan(int turns) => planSpin(
          startRotation: start,
          geometry: geometry,
          index: index,
          fullTurns: turns,
          pointerAngle: _pointerAngle,
          clockwise: clockwise,
          random: random,
        );

    // Keep the wheel slow enough that it never seems to turn backwards:
    // first drop turns, then, if even a partial turn is too fast, take
    // longer.
    int turns = fullTurns;
    Duration spinDuration = duration;
    SpinResult spin = plan(turns);
    double limit() => maxSpinDistance(
        segmentCount: segments.length, curve: curve, duration: spinDuration);
    double maxDistance = limit();
    while ((spin.end - start).abs() > maxDistance && turns > 0) {
      turns--;
      spin = plan(turns);
    }
    for (int i = 0; i < 20 && (spin.end - start).abs() > maxDistance; i++) {
      spinDuration = spinDuration * 1.25;
      maxDistance = limit();
    }
    _spinSegments = segments;
    _spinGeometry = geometry;
    _spinIndex = index;
    _clockwise = clockwise;
    _stopping = false;
    setState(() {
      _from = start;
      _to = spin.end;
      _highlightIndex = null;
    });
    final completer = Completer<WheelSpinResult<T>?>();
    _spinCompleter = completer;
    _animation.curve = curve;
    _controller.duration = spinDuration;
    _controller.forward(from: 0);
    widget.controller.handleSpinStarted();
    widget.onSpinStart?.call();
    return completer.future;
  }

  /// Brings a spinning wheel to a quick stop on whatever segment it reaches.
  /// Does nothing if the wheel isn't spinning or is already stopping.
  void stopSpin() {
    if (_spinCompleter == null || !_controller.isAnimating || _stopping) {
      return;
    }
    final double current = _currentRotation;

    // Current angular speed, so the stop starts at the same speed.
    final double t = _controller.value;
    const double dt = 1e-3;
    final double seconds =
        (_controller.duration ?? widget.spinDuration).inMicroseconds / 1e6;
    final double progressRate = (_animation.curve.transform(min(1.0, t + dt)) -
            _animation.curve.transform(t)) /
        dt;
    final double speed = ((_to - _from) * progressRate / seconds).abs();

    const Duration stopDuration = Duration(milliseconds: 900);
    // easeOutCubic starts at 3x its average speed. Never faster than the
    // backwards-looking speed limit, though.
    final double maxDistance = maxSpinDistance(
      segmentCount: _spinSegments.length,
      curve: Curves.easeOutCubic,
      duration: stopDuration,
    );
    final double distance = (speed * stopDuration.inMicroseconds / 1e6 / 3)
        .clamp(min(0.4, maxDistance), min(4 * pi, maxDistance));
    final double direction = _clockwise ? 1.0 : -1.0;
    final double probe = current + direction * distance;

    int index = _spinGeometry.indexAt(probe, _pointerAngle);
    final double fraction = _spinGeometry
        .fractionAt(index, probe, _pointerAngle)
        .clamp(0.1, 0.9)
        .toDouble();
    final double resting =
        _spinGeometry.restingRotationFor(index, fraction, _pointerAngle);
    double end = resting + ((probe - resting) / (2 * pi)).round() * 2 * pi;
    if ((end - current) * direction < 0) {
      // Nudging away from a dividing line would turn the wheel backwards.
      end = probe;
      index = _spinGeometry.indexAt(end, _pointerAngle);
    }

    _stopping = true;
    _spinIndex = index;
    setState(() {
      _from = current;
      _to = end;
    });
    _controller.stop();
    _animation.curve = Curves.easeOutCubic;
    _controller.duration = stopDuration;
    _controller.forward(from: 0);
  }

  void _onDragStart() {
    if (_spinCompleter != null) return;
    _dragging = true;
    if (_highlightIndex != null) setState(() => _highlightIndex = null);
  }

  void _onDragUpdate(Offset position, Offset delta, double size) {
    _lastDragPosition = position;
    if (!_dragging || _spinCompleter != null) return;
    final Offset center = Offset(size / 2, size / 2);
    final Offset now = position - center;
    final Offset before = now - delta;
    if (now.distance < size * 0.05 || before.distance < size * 0.05) return;

    double change = now.direction - before.direction;
    if (change > pi) change -= 2 * pi;
    if (change < -pi) change += 2 * pi;

    final double rotation = _currentRotation + change;
    setState(() {
      _from = rotation;
      _to = rotation;
    });
    _checkSegmentPass();
  }

  void _onDragEnd(Velocity velocity, double size) {
    if (!_dragging || _spinCompleter != null) return;
    _dragging = false;

    final double rest = _currentRotation % (2 * pi);
    setState(() {
      _from = rest;
      _to = rest;
    });

    final Offset r = _lastDragPosition - Offset(size / 2, size / 2);
    if (r.distance < size * 0.1 || widget.segments.isEmpty) return;
    final Offset v = velocity.pixelsPerSecond;
    // Angular velocity (radians/second, clockwise positive).
    final double omega = (r.dx * v.dy - r.dy * v.dx) / r.distanceSquared;
    if (omega.abs() < _minFlingVelocity) return;

    final List<WheelSegment<T>> segments = List.of(widget.segments);
    final Random random = Random.secure();
    final double seconds = widget.spinDuration.inMicroseconds / 1e6;
    // easeOutCubic starts at 3x its average speed, so this distance makes
    // the spin continue at the fling's speed.
    final double distance = omega.abs() * seconds / 3;
    final int fullTurns =
        (distance / (2 * pi)).floor().clamp(1, max(1, widget.maxSpins * 2));

    _launchSpin(
      segments: segments,
      geometry: geometryFor(segments, widget.sliceSizing),
      index: pickWeightedIndex(effectiveProbabilities(segments), random),
      fullTurns: fullTurns,
      clockwise: omega > 0,
      duration: widget.spinDuration,
      curve: Curves.easeOutCubic,
      random: random,
    );
  }

  String? _semanticsValue() {
    if (_spinCompleter != null) return 'Spinning';
    final WheelSpinResult? result = widget.controller.lastResult;
    if (result == null) return null;
    return 'Landed on ${result.segment.semanticLabel ?? result.segment.label}';
  }

  @override
  void dispose() {
    widget.controller.detachState(this);
    // Don't leave callers awaiting a spin that will never finish.
    _spinCompleter?.complete(null);
    _spinCompleter = null;
    _animation.dispose();
    _controller.dispose();
    _tickController.dispose();
    for (final image in _ownedImages) {
      image?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WheelDisplay(
      config: widget,
      animation: _animation,
      segments: processedSegments,
      geometry: _geometry,
      startRotation: _from,
      endRotation: _to,
      imageStates: _imageStates,
      highlightIndex: _highlightIndex,
      indicatorTick: _tickController,
      clockwise: _clockwise,
      semanticsValue: _semanticsValue(),
      onCenterTap: widget.tapToSpin ? startSpin : null,
      onDragStart: widget.swipeToSpin ? _onDragStart : null,
      onDragUpdate: widget.swipeToSpin ? _onDragUpdate : null,
      onDragEnd: widget.swipeToSpin ? _onDragEnd : null,
    );
  }
}
