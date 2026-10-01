import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import '../models/wheel_segment.dart';

/// The loading state of a segment's image.
enum ImageLoadState {
  /// The segment has no image to load.
  none,

  /// The image is being loaded.
  loading,

  /// The image is ready.
  loaded,

  /// The image failed to load.
  failed,
}

/// Whether [path] is a network URL (`http://` or `https://`) rather than an
/// asset path.
bool isNetworkPath(String path) {
  final String scheme = Uri.tryParse(path)?.scheme.toLowerCase() ?? '';
  return scheme == 'http' || scheme == 'https';
}

/// The image provider for [segment]: its [WheelSegment.imageProvider], or
/// one created from its [WheelSegment.path]. Null if it has neither.
ImageProvider? imageProviderFor(WheelSegment segment) {
  if (segment.imageProvider != null) return segment.imageProvider;
  final String path = segment.path ?? '';
  if (path.isEmpty) return null;
  return _providerForPath(path);
}

ImageProvider _providerForPath(String path) {
  if (isNetworkPath(path)) return NetworkImage(path);
  return AssetImage(path);
}

/// Resolves [provider] to its first frame.
///
/// Pass a [configuration] (e.g. from `createLocalImageConfiguration`) so that
/// resolution-aware asset variants (2.0x, 3.0x) are picked for the device.
/// The caller owns the returned image and must `dispose` it when done.
Future<ui.Image> loadImageFromProvider(
  ImageProvider provider, {
  ImageConfiguration configuration = ImageConfiguration.empty,
}) {
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

/// Loads an image from either a local asset path or a network URL.
///
/// The caller owns the returned image and must `dispose` it when done.
Future<ui.Image> loadImage(
  String path, {
  ImageConfiguration configuration = ImageConfiguration.empty,
}) {
  return loadImageFromProvider(_providerForPath(path),
      configuration: configuration);
}

/// Loads the icon of a single [segment].
///
/// The caller owns the returned image and must `dispose` it when done.
/// Throws if the segment has no image source or the image fails to load.
Future<ui.Image> loadSegmentImage(
  WheelSegment segment, {
  ImageConfiguration configuration = ImageConfiguration.empty,
}) {
  final ImageProvider? provider = imageProviderFor(segment);
  if (provider == null) {
    throw ArgumentError('Segment "${segment.label}" has no image to load');
  }
  return loadImageFromProvider(provider, configuration: configuration);
}

/// Loads icons for every [WheelSegment] that still needs one (see
/// [WheelSegment.needsImageLoad]). Images are loaded in parallel.
///
/// Returns a list of the same length and order as [segments]. Segments whose
/// image failed to load, or that need no loading, are returned unchanged.
/// Any image in the result that is not identical to the input segment's
/// image was created here, and the caller is responsible for disposing it.
Future<List<WheelSegment<T>>> loadSegmentImages<T>(
  List<WheelSegment<T>> segments, {
  ImageConfiguration configuration = ImageConfiguration.empty,
}) {
  return Future.wait(segments.map((segment) async {
    if (!segment.needsImageLoad) return segment;
    try {
      final ui.Image image =
          await loadSegmentImage(segment, configuration: configuration);
      return segment.copyWith(image: image);
    } catch (e) {
      debugPrint('Error loading image for segment ${segment.label}: $e');
      return segment;
    }
  }));
}
