import 'package:flutter/material.dart';
import 'package:spinning_wheel/controller/spinner_controller.dart';
import 'package:spinning_wheel/controller/wheel_animation_controller.dart';
import 'package:spinning_wheel/models/wheel_config.dart';

import '../core/image_loader.dart';
import '../models/wheel_segment.dart';
import '../widgets/wheel_display.dart';

class SpinnerWheel extends StatefulWidget {
  final SpinnerController controller;
  final List<WheelSegment> segments;
  final Function(WheelSegment, int) onComplete;
  final Duration? animationDuration;
  final Color? wheelColor;
  final ImageProvider? wheelImage;
  final Color? indicatorColor;
  final Widget? centerChild;
  final Widget? indicator;
  final double? imageHeight;
  final double? imageWidth;
  final TextStyle? labelStyle;

  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? errorBuilder;

  const SpinnerWheel({
    super.key,
    required this.controller,
    required this.segments,
    required this.onComplete,
    this.animationDuration,
    this.loadingBuilder,
    this.errorBuilder,
    this.wheelColor,
    this.wheelImage,
    this.indicatorColor,
    this.centerChild,
    this.indicator,
    this.imageHeight,
    this.imageWidth,
    this.labelStyle,
  });

  @override
  State<SpinnerWheel> createState() => SpinnerWheelState();
}

class SpinnerWheelState extends State<SpinnerWheel>
    with SingleTickerProviderStateMixin {
  late Future<List<WheelSegment>> processedSegments;
  
  WheelAnimationController? _animationController;
  WheelAnimationController? get animationController => _animationController;

  @override
  void initState() {
    processedSegments = loadSegmentImages(widget.segments);
    widget.controller.attach(this);
    super.initState();
  }

  void onSpinComplete(WheelSegment segment, int index) {
    widget.onComplete(segment, index);
    setState(() {});
  }

  Future<void> start() async => await _animationController?.spin();

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WheelSegment>>(
      future: processedSegments,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          if (widget.loadingBuilder != null) {
            return widget.loadingBuilder!(context);
          }
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (snap.hasError) {
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(context);
          }
          return const Center(child: Text("Error loading segments"));
        }

        final segments = snap.data!;
        _animationController ??= WheelAnimationController(
          vsync: this,
          onSpinComplete: onSpinComplete,
          segments: segments,
          duration: widget.animationDuration ?? const Duration(seconds: 5),
        );

        return WheelDisplay(
          controller: _animationController!,
          segments: segments,
          config: WheelConfig().copyWith(
            centerChild: widget.centerChild,
            indicator: widget.indicator,
            wheelColor: widget.wheelColor,
            wheelImage: widget.wheelImage,
            indicatorColor: widget.indicatorColor,
            imageHeight: widget.imageHeight,
            imageWidth: widget.imageWidth,
            labelStyle: widget.labelStyle,
          ),
        );
      },
    );
  }
}
