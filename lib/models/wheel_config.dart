// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';


class WheelConfig {
  final Widget? centerChild;
  final Widget? indicator;
  final Color? wheelColor;
  final Color? indicatorColor;
  final double? imageHeight;
  final double? imageWidth;
  final TextStyle? labelStyle;
  final double minSize;
  final double maxSize;
  final double aspectRatio;
  final ImageProvider? wheelImage;

  WheelConfig({
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
    this.wheelImage,
  }) {
    assert(minSize < maxSize, "minSize cannot be greater than maxSize");
    assert(minSize > 0, "minSize cannot be lower than zero");
  }

  WheelConfig copyWith({
    Widget? centerChild,
    Widget? indicator,
    Color? wheelColor,
    Color? indicatorColor,
    double? imageHeight,
    double? imageWidth,
    TextStyle? labelStyle,
    double? minSize,
    double? maxSize,
    double? aspectRatio,
    ImageProvider? wheelImage,
  }) {
    return WheelConfig(
      centerChild: centerChild ?? this.centerChild,
      indicator: indicator ?? this.indicator,
      wheelColor: wheelColor ?? this.wheelColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      imageHeight: imageHeight ?? this.imageHeight,
      imageWidth: imageWidth ?? this.imageWidth,
      labelStyle: labelStyle ?? this.labelStyle,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      wheelImage: wheelImage ?? this.wheelImage,
    );
  }
}
