import 'package:flutter/material.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

import '../frames/candy_frame.dart';

/// One frame in the gallery.
class _FrameDemo {
  final String title;
  final String code;
  final WheelFrame? frame;
  final Widget? background;
  final Color backdrop;

  const _FrameDemo(
    this.title,
    this.code, {
    this.frame,
    this.background,
    this.backdrop = const Color(0xFFF4F1EC),
  });
}

const List<_FrameDemo> _demos = [
  _FrameDemo('Classic', 'WheelFrame.classic()', frame: WheelFrame.classic()),
  _FrameDemo('Royal', 'WheelFrame.royal()', frame: WheelFrame.royal()),
  _FrameDemo('Neon', 'WheelFrame.neon()',
      frame: WheelFrame.neon(), backdrop: Color(0xFF15122B)),
  _FrameDemo('Wooden', 'WheelFrame.wooden()', frame: WheelFrame.wooden()),
  _FrameDemo(
    'Classic, recolored',
    'WheelFrame.classic(\n'
        '  rimColor: Color(0xFF14532D),\n'
        '  trimColor: Color(0xFFF4C542),\n'
        '  toothCount: 12, studCount: 12)',
    frame: WheelFrame.classic(
      rimColor: Color(0xFF14532D),
      trimColor: Color(0xFFF4C542),
      toothCount: 12,
      studCount: 12,
    ),
  ),
  _FrameDemo(
    'Royal, silver & sapphire',
    'WheelFrame.royal(\n'
        '  goldColor: Color(0xFFC0C6CC),\n'
        '  gemColor: Color(0xFF1565C0))',
    frame: WheelFrame.royal(
      goldColor: Color(0xFFC0C6CC),
      gemColor: Color(0xFF1565C0),
    ),
  ),
  _FrameDemo(
    'Custom painted',
    'WheelFrame.custom(\n'
        '  paintFront: ..., paintBack: ...)\n'
        '// see lib/frames/candy_frame.dart',
    frame: candyFrame,
  ),
  _FrameDemo(
    'Your own image',
    "background: Image.asset(\n  'assets/images/wheel-01.png')",
    background: Image(
        image: AssetImage('assets/images/wheel-01.png'), fit: BoxFit.contain),
  ),
];

/// A gallery of the ready-made frames and two ways to make your own.
class FramesScreen extends StatelessWidget {
  const FramesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frames')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          // A fixed height: the wheel takes what the text leaves.
          mainAxisExtent: 400,
        ),
        itemCount: _demos.length,
        itemBuilder: (context, index) => _FrameCard(demo: _demos[index]),
      ),
    );
  }
}

class _FrameCard extends StatefulWidget {
  final _FrameDemo demo;

  const _FrameCard({required this.demo});

  @override
  State<_FrameCard> createState() => _FrameCardState();
}

class _FrameCardState extends State<_FrameCard> {
  final SpinnerController _controller = SpinnerController();

  static final List<WheelSegment<int>> _segments = [
    for (int i = 0; i < 8; i++)
      WheelSegment('${(i + 1) * 10}', (i + 1) * 10,
          color: Colors.primaries[(i * 2) % Colors.primaries.length]),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = widget.demo;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ColoredBox(
              color: demo.backdrop,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SpinnerWheel<int>(
                  controller: _controller,
                  segments: _segments,
                  frame: demo.frame,
                  background: demo.background,
                  tapToSpin: true,
                  spinDuration: const Duration(seconds: 3),
                  labelStyle: const WheelLabelStyle(
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onComplete: (_, __) {},
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(demo.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  demo.code,
                  maxLines: 4,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
