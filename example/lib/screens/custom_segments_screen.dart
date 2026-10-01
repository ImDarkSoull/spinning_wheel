import 'package:flutter/material.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

/// Your own type for segment values. The wheel hands it back, typed, when a
/// spin ends.
class Reward {
  final String code;
  final String description;

  const Reward(this.code, this.description);
}

/// Segments with widgets, image providers, their own text styles and
/// screen reader labels, sized by probability.
class CustomSegmentsScreen extends StatefulWidget {
  const CustomSegmentsScreen({super.key});

  @override
  State<CustomSegmentsScreen> createState() => _CustomSegmentsScreenState();
}

class _CustomSegmentsScreenState extends State<CustomSegmentsScreen> {
  final SpinnerController _controller = SpinnerController();
  final List<String> _imageErrors = [];

  // Slices are sized by probability (see sliceSizing below), so "Star" takes
  // 30% of the wheel and "Nothing" just 5%.
  final List<WheelSegment<Reward>> _segments = [
    WheelSegment(
      'Star',
      const Reward('STAR-30', 'A shiny gold star'),
      color: Colors.indigo,
      probability: 0.3,
      // Any widget can sit on a slice. It rotates with the wheel.
      child: const Icon(Icons.star, color: Colors.amber, size: 36),
    ),
    WheelSegment(
      'Bunny',
      const Reward('BUNNY-25', 'A fluffy bunny sticker'),
      color: Colors.pink,
      probability: 0.25,
      // Any ImageProvider works: assets, files, memory, network...
      imageProvider: const AssetImage('assets/images/bunny.png'),
    ),
    WheelSegment(
      'Gift',
      const Reward('GIFT-15', 'A surprise gift'),
      color: Colors.teal,
      probability: 0.15,
      // A NetworkImage lets you send headers, which a plain URL path can't.
      imageProvider: const NetworkImage(
        'https://cdn-icons-png.flaticon.com/512/3273/3273898.png',
        headers: {'Accept': 'image/png'},
      ),
    ),
    WheelSegment(
      'BIG',
      const Reward('BIG-15', 'Big text, big prize'),
      color: Colors.deepOrange,
      probability: 0.15,
      // Merged on top of the wheel's label style.
      textStyle: const TextStyle(
        fontSize: 26,
        fontStyle: FontStyle.italic,
        color: Colors.yellowAccent,
      ),
    ),
    WheelSegment(
      'Broken',
      const Reward('OOPS-10', 'Its image failed to load'),
      color: Colors.blueGrey,
      probability: 0.1,
      // Fails on purpose to show imageErrorWidget.
      path: 'https://example.invalid/missing.png',
    ),
    WheelSegment(
      'Nothing',
      const Reward('NONE', 'Better luck next time'),
      color: Colors.black87,
      probability: 0.05,
      semanticLabel: 'No reward',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showReward(WheelSegment<Reward> segment) {
    // `segment.value` is a Reward, no casting needed.
    final Reward reward = segment.value;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You won: ${segment.label}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(reward.description),
            const SizedBox(height: 16),
            SelectableText('Code: ${reward.code}',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom segments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 320,
            child: SpinnerWheel<Reward>(
              controller: _controller,
              segments: _segments,
              semanticsLabel: 'Reward wheel',
              sliceSizing: SliceSizing.proportional,
              sliceStyle: SliceStyle.flat,
              sliceBorderColor: Colors.white,
              sliceBorderWidth: 3,
              indicatorPosition: IndicatorPosition.left,
              indicatorBounce: true,
              tapToSpin: true,
              swipeToSpin: true,
              imageWidth: 44,
              imageHeight: 44,
              imagePlaceholder: const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              imageErrorWidget:
                  const Icon(Icons.broken_image, color: Colors.white),
              onImageError: (segment, error) =>
                  setState(() => _imageErrors.add(segment.label)),
              labelStyle: const WheelLabelStyle(
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.fade,
              ),
              onComplete: (segment, _) => _showReward(segment),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap the center or swipe the wheel. Slice sizes match each '
            "reward's chance of winning.",
            textAlign: TextAlign.center,
          ),
          if (_imageErrors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Images that failed to load: ${_imageErrors.join(', ')}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          const _Legend(),
        ],
      ),
    );
  }
}

/// Explains what each slice demonstrates.
class _Legend extends StatelessWidget {
  const _Legend();

  static const List<(String, String)> _rows = [
    ('Star', 'child: an Icon widget'),
    ('Bunny', 'imageProvider: AssetImage'),
    ('Gift', 'imageProvider: NetworkImage with headers'),
    ('BIG', 'textStyle: per-slice text style'),
    ('Broken', 'a URL that fails, showing imageErrorWidget'),
    ('Nothing', 'semanticLabel for screen readers'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final (name, what) in _rows)
            ListTile(dense: true, title: Text(name), subtitle: Text(what)),
        ],
      ),
    );
  }
}
