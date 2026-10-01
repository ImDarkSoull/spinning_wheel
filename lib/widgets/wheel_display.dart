import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:spinning_wheel/widgets/wheel_painter.dart';
import '../models/wheel_segment.dart';
import '../models/wheel_label_style.dart';
import 'indicator.dart';

/// Internal widget that handles the layout and rendering of the wheel components.
class WheelDisplay extends StatelessWidget {
  /// The (already curved) animation driving the wheel's rotation.
  final Animation<double> animation;

  /// The list of segments to draw.
  final List<WheelSegment> segments;

  /// The starting rotation angle.
  final double startRotation;

  /// The target end rotation angle.
  final double endRotation;

  /// Optional widget to display in the center hub.
  final Widget? centerChild;

  /// Optional custom indicator widget.
  final Widget? indicator;

  /// Tint color for the default wheel asset.
  final Color? wheelColor;

  /// Background color for the default indicator.
  final Color? indicatorColor;

  /// Fixed height for segment images.
  final double? imageHeight;

  /// Fixed width for segment images.
  final double? imageWidth;

  /// Configuration for the label style.
  final WheelLabelStyle? labelStyle;

  /// Minimum allowed size for the wheel.
  final double minSize;

  /// Maximum allowed size for the wheel.
  final double maxSize;

  /// Aspect ratio for the wheel (default 1.0).
  final double aspectRatio;

  /// Custom background widget.
  final Widget? background;

  /// Whether to render the background layer.
  final bool shouldDrawBackground;

  /// Radial padding within segments.
  final EdgeInsets slicePadding;

  /// Creates a [WheelDisplay].
  const WheelDisplay({
    super.key,
    required this.animation,
    required this.segments,
    required this.startRotation,
    required this.endRotation,
    this.centerChild,
    this.indicator,
    this.wheelColor,
    this.indicatorColor,
    this.imageHeight,
    this.imageWidth,
    this.labelStyle,
    this.minSize = 100.0,
    this.maxSize = double.infinity,
    this.aspectRatio = 1.0,
    this.background,
    this.shouldDrawBackground = true,
    this.slicePadding = EdgeInsets.zero,
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

        return SizedBox(
          width: constraints.maxWidth == double.infinity ? size : null,
          height: constraints.maxHeight == double.infinity ? size : null,
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: SizedBox(
                width: size,
                height: size,
                child: _buildWheel(size),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWheel(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main wheel container
        Stack(
          alignment: Alignment.center,
          children: [
            // Wheel background image
            if (shouldDrawBackground)
              SizedBox(
                width: size,
                height: size,
                child: background ??
                    FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'assets/wheel.png',
                        package: 'spinning_wheel',
                        fit: BoxFit.contain,
                        color: wheelColor,
                      ),
                    ),
              ),
            // Rotating wheel content
            SizedBox(
              width: size,
              height: size,
              child: AnimatedBuilder(
                animation: animation,
                child: RepaintBoundary(
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.094),
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: WheelPainter(
                        segments,
                        imageHeight: imageHeight ?? (size * 0.11),
                        imageWidth: imageWidth ?? (size * 0.11),
                        labelStyle: labelStyle ??
                            WheelLabelStyle(
                                labelStyle: _getResponsiveLabelStyle(size)),
                        slicePadding: slicePadding,
                      ),
                    ),
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
          ],
        ),
        // Indicator
        _buildIndicator(size),
        // Center button
        _buildCenterButton(size),
      ],
    );
  }

  Widget _buildIndicator(double size) {
    return Positioned(
      top: size * 0.02, // More responsive positioning
      child: indicator ??
          ClipPath(
            clipper: TriangleBottomClipper(),
            child: Container(
              width: size * 0.03,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: indicatorColor ?? Colors.red,
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
          ),
    );
  }

  Widget _buildCenterButton(double size) {
    return Container(
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
      child: centerChild ??
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
  }

  TextStyle? _getResponsiveLabelStyle(double size) {
    if (labelStyle?.labelStyle != null) {
      return labelStyle!.labelStyle;
    }

    // Provide a default responsive text style
    return TextStyle(
      fontSize: size * 0.025, // Responsive font size
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
  }
}
