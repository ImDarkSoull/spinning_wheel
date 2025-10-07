import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spinning_wheel/controller/wheel_animation_controller.dart';
import 'package:spinning_wheel/models/wheel_config.dart';
import 'package:spinning_wheel/widgets/wheel_painter.dart';

import '../models/wheel_segment.dart';
import 'indicator.dart';

class WheelDisplay extends StatelessWidget {
  final WheelAnimationController controller;
  final List<WheelSegment> segments;
  final WheelConfig config;

  const WheelDisplay({
    super.key,
    required this.controller,
    required this.segments,
    required this.config,
  });

  ImageProvider get _imageProvider {
    if (config.wheelImage != null) return config.wheelImage!;
    return const AssetImage("assets/images/wheel.png", package: "spinning_wheel");
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive size with constraints
        double availableWidth = constraints.maxWidth;
        double availableHeight = constraints.maxHeight;

        // Respect aspect ratio while fitting within constraints
        double targetSize =
            min(availableWidth, availableHeight / config.aspectRatio);
        targetSize = targetSize.clamp(config.minSize, config.maxSize);

        // Ensure the widget fits within the available space
        double finalWidth = min(targetSize, availableWidth);
        double finalHeight =
            min(targetSize * config.aspectRatio, availableHeight);
        double size = min(finalWidth, finalHeight);

        return SizedBox(
          width: constraints.maxWidth == double.infinity ? size : null,
          height: constraints.maxHeight == double.infinity ? size : null,
          child: Center(
            child: AspectRatio(
              aspectRatio: config.aspectRatio,
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
            SizedBox(
              width: size,
              height: size,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image(
                  image: _imageProvider,
                  fit: BoxFit.contain,
                  color: config.wheelColor,
                ),
              ),
            ),
            // Rotating wheel content
            SizedBox(
              width: size,
              height: size,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: Tween(begin: controller.startRotation, end: controller.endRotation)
                        .animate(
                          CurvedAnimation(
                            parent: controller,
                            curve: Curves.easeOutCirc,
                          ),
                        )
                        .value,
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.094),
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: WheelPainter(
                          segments,
                          imageHeight: config.imageHeight ?? (size * 0.11),
                          imageWidth: config.imageWidth ?? (size * 0.11),
                          style: _getResponsiveLabelStyle(size),
                        ),
                      ),
                    ),
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
      child: config.indicator ??
          ClipPath(
            clipper: TriangleBottomClipper(),
            child: Container(
              width: size * 0.03,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: config.indicatorColor ?? Colors.red,
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
  }

  TextStyle? _getResponsiveLabelStyle(double size) {
    if (config.labelStyle != null) return config.labelStyle;

    // Provide a default responsive text style
    return TextStyle(
      fontSize: size * 0.025, // Responsive font size
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
  }
}
