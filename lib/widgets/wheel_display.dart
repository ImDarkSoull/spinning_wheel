import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../core/image_loader.dart';
import '../core/wheel_geometry.dart';
import '../models/wheel_segment.dart';
import '../models/wheel_label_style.dart';
import '../models/wheel_options.dart';
import '../spinner_wheel.dart';
import 'indicator.dart';
import 'wheel_frame_painter.dart';
import 'wheel_painter.dart';

/// Internal widget that handles the layout and rendering of the wheel components.
class WheelDisplay extends StatelessWidget {
  /// The wheel's configuration.
  final SpinnerWheel config;

  /// The (already curved) animation driving the wheel's rotation.
  final Animation<double> animation;

  /// The list of segments to draw.
  final List<WheelSegment> segments;

  /// The angular layout of [segments].
  final WheelGeometry geometry;

  /// The starting rotation angle.
  final double startRotation;

  /// The target end rotation angle.
  final double endRotation;

  /// The image loading state of each segment.
  final List<ImageLoadState> imageStates;

  /// The slice to highlight, if any.
  final int? highlightIndex;

  /// Runs from 0 to 1 each time the indicator should flick.
  final Animation<double>? indicatorTick;

  /// Whether the wheel is turning clockwise (sets the flick direction).
  final bool clockwise;

  /// The wheel's current state for screen readers.
  final String? semanticsValue;

  /// Called when the center is tapped, or null if tapping does nothing.
  final VoidCallback? onCenterTap;

  /// Called when a drag on the wheel starts.
  final VoidCallback? onDragStart;

  /// Called as a drag moves, with the pointer position and movement in the
  /// wheel's coordinates and the wheel's size.
  final void Function(Offset position, Offset delta, double size)? onDragUpdate;

  /// Called when a drag ends, with the release velocity.
  final void Function(Velocity velocity, double size)? onDragEnd;

  /// Minimum allowed size for the wheel.
  final double minSize;

  /// Maximum allowed size for the wheel.
  final double maxSize;

  /// Aspect ratio for the wheel (default 1.0).
  final double aspectRatio;

  /// Size used when neither the width nor the height is constrained.
  static const double fallbackSize = 300.0;

  /// Creates a [WheelDisplay].
  const WheelDisplay({
    super.key,
    required this.config,
    required this.animation,
    required this.segments,
    required this.geometry,
    required this.startRotation,
    required this.endRotation,
    this.imageStates = const [],
    this.highlightIndex,
    this.indicatorTick,
    this.clockwise = true,
    this.semanticsValue,
    this.onCenterTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.minSize = 100.0,
    this.maxSize = double.infinity,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive size with constraints
        double availableWidth = constraints.maxWidth;
        double availableHeight = constraints.maxHeight;

        // Respect aspect ratio while fitting within constraints
        double targetSize = min(availableWidth, availableHeight / aspectRatio);
        targetSize = targetSize.clamp(minSize, maxSize);

        // Ensure the widget fits within the available space
        double finalWidth = min(targetSize, availableWidth);
        double finalHeight = min(targetSize * aspectRatio, availableHeight);
        double size = min(finalWidth, finalHeight);

        // Unbounded in both directions (e.g. inside a scroll view in a Row).
        if (!size.isFinite) {
          size = fallbackSize.clamp(minSize, maxSize);
        }

        return SizedBox(
          width: constraints.maxWidth == double.infinity ? size : null,
          height: constraints.maxHeight == double.infinity ? size : null,
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: SizedBox(
                width: size,
                height: size,
                child: _buildSemantics(_buildWheel(context, size)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSemantics(Widget child) {
    final String names =
        segments.map((s) => s.semanticLabel ?? s.label).join(', ');
    return Semantics(
      container: true,
      label: config.semanticsLabel ?? 'Spinning wheel',
      value: semanticsValue,
      hint: '${segments.length} segments: $names',
      liveRegion: true,
      button: onCenterTap != null,
      onTap: onCenterTap,
      child: child,
    );
  }

  Widget _buildWheel(BuildContext context, double size) {
    Widget wheel = Stack(
      alignment: Alignment.center,
      children: [
        // Main wheel container
        Stack(
          alignment: Alignment.center,
          children: [
            // The user's background, or the back of the default frame.
            if (config.shouldDrawBackground)
              SizedBox(
                width: size,
                height: size,
                child: config.background ??
                    CustomPaint(painter: _framePainter(WheelFrameLayer.back)),
              ),
            // Rotating wheel content
            SizedBox(
              width: size,
              height: size,
              child: AnimatedBuilder(
                animation: animation,
                child: RepaintBoundary(
                  child: Padding(
                    padding: EdgeInsets.all(size * config.effectiveWheelInset),
                    child: _buildSlices(context, size),
                  ),
                ),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: lerpDouble(
                        startRotation, endRotation, animation.value)!,
                    child: child,
                  );
                },
              ),
            ),
            // The front of the default frame, over the slices' edge.
            if (_drawsDefaultFrame)
              IgnorePointer(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                      painter: _framePainter(WheelFrameLayer.front)),
                ),
              ),
          ],
        ),
        // Indicator
        _buildIndicator(size),
        // Center button
        _buildCenterButton(size),
      ],
    );

    if (onDragUpdate != null) {
      wheel = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onDragStart?.call(),
        onPanUpdate: (details) =>
            onDragUpdate!(details.localPosition, details.delta, size),
        onPanEnd: (details) => onDragEnd?.call(details.velocity, size),
        child: wheel,
      );
    }
    return wheel;
  }

  /// The painted slices plus any per-segment widgets, rotating together.
  Widget _buildSlices(BuildContext context, double size) {
    final double innerSize = size * (1 - 2 * config.effectiveWheelInset);
    final double imageWidth = config.imageWidth ?? (size * 0.11);
    final double imageHeight = config.imageHeight ?? (size * 0.11);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: WheelPainter(
              segments,
              imageHeight: imageHeight,
              imageWidth: imageWidth,
              labelStyle: _effectiveLabelStyle(size),
              slicePadding: config.slicePadding,
              geometry: geometry,
              sliceStyle: config.sliceStyle,
              borderColor: config.sliceBorderColor,
              borderWidth: config.sliceBorderWidth,
              highlightIndex: highlightIndex,
              highlightColor: config.highlightColor,
              textDirection:
                  Directionality.maybeOf(context) ?? TextDirection.ltr,
            ),
          ),
        ),
        for (int i = 0; i < segments.length && i < geometry.length; i++)
          if (geometry.sweeps[i] > 0)
            if (_overlayFor(i) case final Widget overlay)
              _positionOnSlice(i, innerSize, imageWidth, imageHeight, overlay),
      ],
    );
  }

  /// The widget drawn in place of segment [index]'s image, if any.
  Widget? _overlayFor(int index) {
    final WheelSegment segment = segments[index];
    if (segment.child != null) return segment.child;
    final ImageLoadState state =
        index < imageStates.length ? imageStates[index] : ImageLoadState.none;
    return switch (state) {
      ImageLoadState.loading => config.imagePlaceholder,
      ImageLoadState.failed => config.imageErrorWidget,
      _ => null,
    };
  }

  /// Places [child] where segment [index]'s image goes, facing outward.
  Widget _positionOnSlice(
      int index, double innerSize, double width, double height, Widget child) {
    final double radius = innerSize / 2;
    final double distance =
        radius * 0.55 - config.slicePadding.top + config.slicePadding.bottom;
    final double angle = geometry.midAngle(index);
    final Offset center =
        Offset(radius, radius) + Offset(cos(angle), sin(angle)) * distance;
    return Positioned(
      left: center.dx - width / 2,
      top: center.dy - height / 2,
      width: width,
      height: height,
      child: Transform.rotate(angle: angle + pi / 2, child: child),
    );
  }

  bool get _drawsDefaultFrame => config.drawsFrame;

  WheelFramePainter _framePainter(WheelFrameLayer layer) => WheelFramePainter(
      frame: config.effectiveFrame,
      inset: config.effectiveWheelInset,
      layer: layer);

  Widget _buildIndicator(double size) {
    Widget pointer = config.indicator ??
        ClipPath(
          clipper: TriangleBottomClipper(),
          child: Container(
            width: size * 0.03,
            height: size * 0.15,
            decoration: BoxDecoration(
              color: config.indicatorColor ??
                  (config.drawsFrame
                      ? config.effectiveFrame.indicatorColor
                      : null) ??
                  Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: size * 0.01,
                  spreadRadius: size * 0.002,
                  offset: Offset(0, size * 0.005),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: size * 0.015,
                height: size * 0.015,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );

    final Animation<double>? tick = indicatorTick;
    if (config.indicatorBounce && tick != null) {
      // The wheel's surface drags the pointer's tip along with it, then it
      // springs back. A clockwise wheel pushes the tip counterclockwise
      // around its anchor.
      final double direction = clockwise ? -1.0 : 1.0;
      final Widget still = pointer;
      pointer = AnimatedBuilder(
        animation: tick,
        child: still,
        builder: (context, child) => Transform.rotate(
          alignment: Alignment.topCenter,
          angle: direction * sin(pi * tick.value) * 0.35,
          child: child,
        ),
      );
    }

    pointer = RotatedBox(
      quarterTurns: config.indicatorPosition.quarterTurns,
      child: pointer,
    );

    final double gap = size * 0.02; // More responsive positioning
    return switch (config.indicatorPosition) {
      IndicatorPosition.top => Positioned(top: gap, child: pointer),
      IndicatorPosition.right => Positioned(right: gap, child: pointer),
      IndicatorPosition.bottom => Positioned(bottom: gap, child: pointer),
      IndicatorPosition.left => Positioned(left: gap, child: pointer),
    };
  }

  Widget _buildCenterButton(double size) {
    final Widget button = Container(
      width: size * 0.12,
      height: size * 0.12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: size * 0.01,
            spreadRadius: size * 0.002,
          ),
        ],
      ),
      child: config.centerChild ??
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.radio_button_checked,
                color: Colors.redAccent,
                size: size * 0.08, // Slightly smaller for better proportion
              ),
            ),
          ),
    );
    if (onCenterTap == null) return button;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onCenterTap, child: button),
    );
  }

  /// The user's [SpinnerWheel.labelStyle], with a text style sized to the
  /// wheel filled in when none was given.
  WheelLabelStyle _effectiveLabelStyle(double size) {
    final WheelLabelStyle style = config.labelStyle ?? const WheelLabelStyle();
    if (style.labelStyle != null) return style;
    return style.copyWith(
      labelStyle: TextStyle(
        fontSize: size * 0.025, // Responsive font size
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
