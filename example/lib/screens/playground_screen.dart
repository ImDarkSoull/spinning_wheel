import 'package:flutter/material.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

import '../widgets/spin_stop_button.dart';

/// Every [SpinnerWheel] option on one screen, so you can see what each does.
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  static const Map<String, Curve> _curves = {
    'decelerate (default)': Curves.decelerate,
    'easeOutCubic': Curves.easeOutCubic,
    'easeOutQuart': Curves.easeOutQuart,
    'linear': Curves.linear,
  };

  static const Map<String, Color?> _tints = {
    'None': null,
    'Purple': Colors.purple,
    'Teal': Colors.teal,
  };

  final SpinnerController _controller = SpinnerController();

  // Segments
  int _segmentCount = 6;
  bool _weighted = false;
  bool _longLabels = false;

  // Spin
  double _durationSeconds = 5;
  RangeValues _spins = const RangeValues(5, 9);
  String _curve = _curves.keys.first;

  // Interaction
  bool _tapToSpin = true;
  bool _swipeToSpin = true;
  IndicatorPosition _indicatorPosition = IndicatorPosition.top;
  bool _indicatorBounce = true;

  // Slices
  SliceSizing _sliceSizing = SliceSizing.equal;
  SliceStyle _sliceStyle = SliceStyle.gradient;
  double _borderWidth = 2;
  bool _highlightWinner = true;

  // Wheel
  bool _drawBackground = true;
  double _wheelInset = 0.094;
  String _tint = _tints.keys.first;
  bool _solidTint = false;

  // Labels
  TextOverflow _overflow = TextOverflow.ellipsis;
  int _maxLines = 1;
  bool _rtl = false;

  // Status. A notifier, so counting ticks doesn't rebuild the wheel.
  final ValueNotifier<int> _ticks = ValueNotifier(0);

  // Rebuilt only when a segment option changes. Passing new segment objects
  // on every build would make the wheel re-process them each time.
  late List<WheelSegment<int>> _segments = _buildSegments();

  @override
  void dispose() {
    _controller.dispose();
    _ticks.dispose();
    super.dispose();
  }

  /// Applies a change to a segment option and rebuilds the segments.
  void _updateSegments(VoidCallback change) {
    setState(() {
      change();
      _segments = _buildSegments();
    });
  }

  List<WheelSegment<int>> _buildSegments() {
    return [
      for (int i = 0; i < _segmentCount; i++)
        WheelSegment(
          _longLabels ? 'Prize number ${i + 1} with a long name' : '${i + 1}',
          i + 1,
          color: Colors.primaries[(i * 3) % Colors.primaries.length],
          // The first segment gets a 40% chance; the rest share the other
          // 60% equally.
          probability: _weighted && i == 0 ? 0.4 : null,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final wheel = SpinnerWheel<int>(
      controller: _controller,
      segments: _segments,
      onComplete: (_, __) {},
      onSpinStart: () => _ticks.value = 0,
      onSegmentPass: (_) => _ticks.value++,
      spinDuration: Duration(milliseconds: (_durationSeconds * 1000).round()),
      spinCurve: _curves[_curve]!,
      minSpins: _spins.start.round(),
      maxSpins: _spins.end.round(),
      tapToSpin: _tapToSpin,
      swipeToSpin: _swipeToSpin,
      indicatorPosition: _indicatorPosition,
      indicatorBounce: _indicatorBounce,
      sliceSizing: _sliceSizing,
      sliceStyle: _sliceStyle,
      sliceBorderColor: Colors.white,
      sliceBorderWidth: _borderWidth,
      highlightWinner: _highlightWinner,
      highlightColor: Colors.yellowAccent,
      shouldDrawBackground: _drawBackground,
      wheelInset: _wheelInset,
      wheelColor: _tints[_tint],
      wheelColorBlendMode: _solidTint ? BlendMode.srcIn : BlendMode.modulate,
      labelStyle: WheelLabelStyle(
        labelStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        overflow: _overflow,
        maxLines: _maxLines,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Playground')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: Directionality(
              textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
              child: wheel,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinStopButton(controller: _controller),
                const SizedBox(width: 16),
                ListenableBuilder(
                  listenable: Listenable.merge([_controller, _ticks]),
                  builder: (context, _) {
                    final result = _controller.lastResult;
                    return Text(
                      'Ticks: ${_ticks.value}\n'
                      'Last: ${result == null ? '–' : result.segment.label}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildControls()),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _Section('Segments'),
        _SliderTile(
          label: 'Segments: $_segmentCount',
          value: _segmentCount.toDouble(),
          min: 1,
          max: 12,
          divisions: 11,
          onChanged: (v) => _updateSegments(() => _segmentCount = v.round()),
        ),
        SwitchListTile(
          title: const Text('Weighted'),
          subtitle: const Text('Segment 1 wins 40% of the time'),
          value: _weighted,
          onChanged: (v) => _updateSegments(() => _weighted = v),
        ),
        SwitchListTile(
          title: const Text('Long labels'),
          value: _longLabels,
          onChanged: (v) => _updateSegments(() => _longLabels = v),
        ),
        const _Section('Spin'),
        _SliderTile(
          label: 'Duration: ${_durationSeconds.toStringAsFixed(1)} s',
          value: _durationSeconds,
          min: 1,
          max: 10,
          divisions: 18,
          onChanged: (v) => setState(() => _durationSeconds = v),
        ),
        ListTile(
          title:
              Text('Turns: ${_spins.start.round()} to ${_spins.end.round()}'),
          subtitle: RangeSlider(
            values: _spins,
            min: 0,
            max: 15,
            divisions: 15,
            onChanged: (v) => setState(() => _spins = v),
          ),
        ),
        _ChoiceTile<String>(
          label: 'Curve',
          value: _curve,
          options: {for (final name in _curves.keys) name: name},
          onChanged: (v) => setState(() => _curve = v),
        ),
        const _Section('Interaction'),
        SwitchListTile(
          title: const Text('Tap center to spin'),
          value: _tapToSpin,
          onChanged: (v) => setState(() => _tapToSpin = v),
        ),
        SwitchListTile(
          title: const Text('Swipe to spin'),
          subtitle: const Text('Drag the wheel, fling it to spin'),
          value: _swipeToSpin,
          onChanged: (v) => setState(() => _swipeToSpin = v),
        ),
        _ChoiceTile<IndicatorPosition>(
          label: 'Indicator',
          value: _indicatorPosition,
          options: {
            for (final p in IndicatorPosition.values) p: p.name,
          },
          onChanged: (v) => setState(() => _indicatorPosition = v),
        ),
        SwitchListTile(
          title: const Text('Indicator bounce'),
          value: _indicatorBounce,
          onChanged: (v) => setState(() => _indicatorBounce = v),
        ),
        const _Section('Slices'),
        _ChoiceTile<SliceSizing>(
          label: 'Sizing',
          value: _sliceSizing,
          options: const {
            SliceSizing.equal: 'equal',
            SliceSizing.proportional: 'by probability',
          },
          onChanged: (v) => setState(() => _sliceSizing = v),
        ),
        _ChoiceTile<SliceStyle>(
          label: 'Style',
          value: _sliceStyle,
          options: const {
            SliceStyle.gradient: 'gradient',
            SliceStyle.flat: 'flat',
          },
          onChanged: (v) => setState(() => _sliceStyle = v),
        ),
        _SliderTile(
          label: 'Border width: ${_borderWidth.toStringAsFixed(1)}',
          value: _borderWidth,
          min: 0,
          max: 6,
          divisions: 12,
          onChanged: (v) => setState(() => _borderWidth = v),
        ),
        SwitchListTile(
          title: const Text('Highlight winner'),
          value: _highlightWinner,
          onChanged: (v) => setState(() => _highlightWinner = v),
        ),
        const _Section('Wheel'),
        SwitchListTile(
          title: const Text('Background'),
          value: _drawBackground,
          onChanged: (v) => setState(() => _drawBackground = v),
        ),
        _SliderTile(
          label: 'Inset: ${(_wheelInset * 100).toStringAsFixed(1)}%',
          value: _wheelInset,
          min: 0,
          max: 0.2,
          divisions: 40,
          onChanged: (v) => setState(() => _wheelInset = v),
        ),
        _ChoiceTile<String>(
          label: 'Background tint',
          value: _tint,
          options: {for (final name in _tints.keys) name: name},
          onChanged: (v) => setState(() => _tint = v),
        ),
        SwitchListTile(
          title: const Text('Solid tint'),
          subtitle: const Text('BlendMode.srcIn instead of modulate'),
          value: _solidTint,
          onChanged: _tints[_tint] == null
              ? null
              : (v) => setState(() => _solidTint = v),
        ),
        const _Section('Labels'),
        _ChoiceTile<TextOverflow>(
          label: 'Overflow',
          value: _overflow,
          options: const {
            TextOverflow.clip: 'clip',
            TextOverflow.ellipsis: 'ellipsis',
            TextOverflow.fade: 'fade',
            TextOverflow.visible: 'visible',
          },
          onChanged: (v) => setState(() => _overflow = v),
        ),
        _ChoiceTile<int>(
          label: 'Max lines',
          value: _maxLines,
          options: const {1: '1', 2: '2', 3: '3'},
          onChanged: (v) => setState(() => _maxLines = v),
        ),
        SwitchListTile(
          title: const Text('Right-to-left'),
          value: _rtl,
          onChanged: (v) => setState(() => _rtl = v),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

/// A row of choice chips for picking one of [options].
class _ChoiceTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _ChoiceTile({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Wrap(
        spacing: 8,
        children: [
          for (final entry in options.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: entry.key == value,
              onSelected: (_) => onChanged(entry.key),
            ),
        ],
      ),
    );
  }
}
