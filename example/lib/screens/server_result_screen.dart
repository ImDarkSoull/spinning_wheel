import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

/// The result is decided before the wheel spins, e.g. by a server, and the
/// wheel lands on it with [SpinnerController.spinTo].
class ServerResultScreen extends StatefulWidget {
  const ServerResultScreen({super.key});

  @override
  State<ServerResultScreen> createState() => _ServerResultScreenState();
}

class _ServerResultScreenState extends State<ServerResultScreen> {
  final SpinnerController _controller = SpinnerController();
  final Random _random = Random();

  final List<WheelSegment<String>> _prizes = [
    WheelSegment('Free coffee', 'COFFEE', color: Colors.brown),
    WheelSegment('10% off', 'TEN', color: Colors.indigo),
    WheelSegment('Free shipping', 'SHIP', color: Colors.teal),
    WheelSegment('Try again', 'NONE', color: Colors.blueGrey),
    WheelSegment('20% off', 'TWENTY', color: Colors.deepPurple),
    WheelSegment('Mystery gift', 'GIFT', color: Colors.pink),
  ];

  bool _waitingForServer = false;
  String _status = 'Ask the server for a prize, or pick one yourself.';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pretends to ask a server which prize the user won.
  Future<int> _fetchPrizeFromServer() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _random.nextInt(_prizes.length);
  }

  Future<void> _askServer() async {
    setState(() {
      _waitingForServer = true;
      _status = 'Contacting server...';
    });
    final int index = await _fetchPrizeFromServer();
    if (!mounted) return;
    setState(() {
      _waitingForServer = false;
      _status = 'Server picked "${_prizes[index].label}". Spinning...';
    });
    await _spinTo(index, decidedBy: 'Server');
  }

  Future<void> _spinTo(int index, {required String decidedBy}) async {
    if (decidedBy != 'Server') {
      setState(() => _status = 'Spinning to "${_prizes[index].label}"...');
    }
    // Resolves when the wheel stops, with the segment it landed on.
    final WheelSpinResult? result = await _controller.spinTo(index);
    if (!mounted || result == null) return;
    final bool matches = result.index == index;
    setState(() {
      _status = '$decidedBy picked "${_prizes[index].label}", wheel landed '
          'on "${result.segment.label}" ${matches ? '✓' : '(stopped early)'}\n'
          'Code: ${result.segment.value}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server-decided result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 300,
            child: SpinnerWheel<String>(
              controller: _controller,
              segments: _prizes,
              spinDuration: const Duration(seconds: 4),
              highlightWinner: true,
              sliceBorderWidth: 2,
              sliceBorderColor: Colors.white,
              labelStyle: const WheelLabelStyle(
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              onComplete: (_, __) {},
            ),
          ),
          const SizedBox(height: 16),
          Text(_status, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final bool busy = _controller.isSpinning || _waitingForServer;
              return Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: busy ? null : _askServer,
                        icon: _waitingForServer
                            ? const SizedBox.square(
                                dimension: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_download),
                        label: const Text('Ask server'),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            _controller.isSpinning ? _controller.stop : null,
                        icon: const Icon(Icons.pan_tool),
                        label: const Text('Stop'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Or rig it yourself:'),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < _prizes.length; i++)
                        ActionChip(
                          label: Text(_prizes[i].label),
                          onPressed:
                              busy ? null : () => _spinTo(i, decidedBy: 'You'),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
