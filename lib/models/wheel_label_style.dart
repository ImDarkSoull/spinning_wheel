import 'package:flutter/material.dart';

/// Configuration for the segment labels' appearance and orientation.
class WheelLabelStyle {
  /// The text style for the label.
  final TextStyle? labelStyle;

  /// The additional rotation angle for the label text in radians.
  ///
  /// By default, labels are oriented outward from the center.
  /// Use this to tweak the alignment (e.g., pi/2 for perpendicular).
  final double angle;

  /// How visual overflow should be handled.
  ///
  /// * [TextOverflow.clip]: the label is clipped to its slice.
  /// * [TextOverflow.ellipsis]: truncated text ends with `...`, clipped to
  ///   its slice.
  /// * [TextOverflow.fade]: truncated text fades out, clipped to its slice.
  /// * [TextOverflow.visible]: the label may draw over neighboring slices.
  final TextOverflow overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  final int? maxLines;

  /// Creates a [WheelLabelStyle].
  const WheelLabelStyle({
    this.labelStyle,
    this.angle = 0.0,
    this.overflow = TextOverflow.clip,
    this.maxLines = 1,
  });

  /// Creates a copy of this style with the given fields replaced.
  WheelLabelStyle copyWith({
    TextStyle? labelStyle,
    double? angle,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return WheelLabelStyle(
      labelStyle: labelStyle ?? this.labelStyle,
      angle: angle ?? this.angle,
      overflow: overflow ?? this.overflow,
      maxLines: maxLines ?? this.maxLines,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WheelLabelStyle &&
      other.labelStyle == labelStyle &&
      other.angle == angle &&
      other.overflow == overflow &&
      other.maxLines == maxLines;

  @override
  int get hashCode => Object.hash(labelStyle, angle, overflow, maxLines);
}
