import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import '../models/wheel_segment.dart';

/// Whether [path] is a network URL (`http://` or `https://`) rather than an
/// asset path.
bool isNetworkPath(String path) {
  final String scheme = Uri.tryParse(path)?.scheme.toLowerCase() ?? '';
  return scheme == 'http' || scheme == 'https';
}

/// Loads an image from either a local asset path or a network URL.
///
/// Pass a [configuration] (e.g. from `createLocalImageConfiguration`) so that
/// resolution-aware asset variants (2.0x, 3.0x) are picked for the device.
/// The caller owns the returned image and must `dispose` it when done.
Future<ui.Image> loadImage(
  String path, {
  ImageConfiguration configuration = ImageConfiguration.empty,
}) async {
  ImageProvider provider;
  if (isNetworkPath(path)) {
    provider = NetworkImage(path);
  } else {
    provider = AssetImage(path);
  }

  final Completer<ui.Image> completer = Completer<ui.Image>();
  final ImageStream stream = provider.resolve(configuration);

  ImageStreamListener? listener;
  listener = ImageStreamListener(
    (ImageInfo frame, bool synchronousCall) {
      if (completer.isCompleted) {
        frame.dispose();
      } else {
        completer.complete(frame.image);
      }
      if (listener != null) stream.removeListener(listener);
    },
    onError: (Object exception, StackTrace? stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(exception, stackTrace);
      }
      if (listener != null) stream.removeListener(listener);
    },
  );

  stream.addListener(listener);
  return completer.future;
}

/// Loads icons for every [WheelSegment] that has a [WheelSegment.path] and no
/// [WheelSegment.image] yet. Images are loaded in parallel.
///
/// Returns a list of the same length and order as [segments]. Segments whose
/// image failed to load, or that need no loading, are returned unchanged.
/// Any image in the result that is not identical to the input segment's
/// image was created here, and the caller is responsible for disposing it.
Future<List<WheelSegment>> loadSegmentImages(
  List<WheelSegment> segments, {
  ImageConfiguration configuration = ImageConfiguration.empty,
}) {
  return Future.wait(segments.map((segment) async {
    if ((segment.path ?? '').isEmpty || segment.image != null) {
      return segment;
    }
    try {
      final ui.Image loadedImage =
          await loadImage(segment.path!, configuration: configuration);
      return WheelSegment(
        segment.label,
        segment.value,
        color: segment.color,
        path: segment.path,
        image: loadedImage,
        probability: segment.probability,
      );
    } catch (e) {
      debugPrint('Error loading image for segment ${segment.label}: $e');
      return segment;
    }
  }));
}
