import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Represents a single slice or segment of the spinning wheel.
///
/// [T] is the type of [value], e.g. `WheelSegment<int>` for prize amounts or
/// `WheelSegment<String>` for coupon codes. It is inferred from the value you
/// pass.
class WheelSegment<T> {
  /// The text displayed on the segment.
  final String label;

  /// The background color of the segment.
  ///
  /// If not provided, a color from [Colors.primaries] is picked based on
  /// [label] and [value], so the same segment keeps the same color across
  /// rebuilds.
  final Color color;

  /// The value associated with this segment (e.g., prize amount).
  final T value;

  /// The path to an image icon displayed on the segment.
  /// Supports both local asset paths and network URLs.
  ///
  /// Ignored when [imageProvider] is set.
  final String? path;

  /// An image provider for the segment's icon, e.g. `MemoryImage`,
  /// `FileImage` or a `NetworkImage` with custom headers.
  ///
  /// Takes precedence over [path].
  final ImageProvider? imageProvider;

  /// The loaded [ui.Image] object, usually populated by the loader.
  final ui.Image? image;

  /// A widget drawn on the segment in place of the image, e.g. an `Icon` or
  /// an animated badge. It is laid out in a box of the wheel's image size
  /// and rotates with the wheel.
  final Widget? child;

  /// Text style for this segment's label, merged on top of the wheel's
  /// [WheelLabelStyle.labelStyle].
  final TextStyle? textStyle;

  /// A description of this segment for screen readers. Defaults to [label].
  final String? semanticLabel;

  /// Weighted probability for this segment to be selected (0.0 to 1.0).
  ///
  /// If null, the segment gets an equal share of the probability left over
  /// after all explicit values (`1.0 - sum`). If no segment sets a
  /// probability, every segment is equally likely. If the explicit values
  /// already add up to 1.0 or more, segments without one can't win.
  final double? probability;

  /// Creates a new [WheelSegment].
  WheelSegment(
    this.label,
    this.value, {
    Color? color,
    this.path,
    this.imageProvider,
    this.image,
    this.child,
    this.textStyle,
    this.semanticLabel,
    this.probability,
  }) : color = color ??
            Colors.primaries[
                Object.hash(label, value).abs() % Colors.primaries.length];

  /// Whether this segment has an image that still needs to be loaded.
  bool get needsImageLoad =>
      image == null &&
      child == null &&
      (imageProvider != null || (path ?? '').isNotEmpty);

  /// Creates a copy of this segment with the given fields replaced.
  WheelSegment<T> copyWith({
    String? label,
    T? value,
    Color? color,
    String? path,
    ImageProvider? imageProvider,
    ui.Image? image,
    Widget? child,
    TextStyle? textStyle,
    String? semanticLabel,
    double? probability,
  }) {
    return WheelSegment<T>(
      label ?? this.label,
      value ?? this.value,
      color: color ?? this.color,
      path: path ?? this.path,
      imageProvider: imageProvider ?? this.imageProvider,
      image: image ?? this.image,
      child: child ?? this.child,
      textStyle: textStyle ?? this.textStyle,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      probability: probability ?? this.probability,
    );
  }

  @override
  String toString() => 'WheelSegment($label, $value)';
}
