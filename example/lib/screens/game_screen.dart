import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

/// A small game: five spins to collect as many points as possible.
///
/// Shows weighted probabilities, image segments (assets and a URL), the
/// three ways to spin (button, tap on the center, swipe), stopping early,
/// haptic ticks and the winner highlight.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int _spinsPerGame = 5;
  static const int _loseAll = -9999;

  final SpinnerController _controller = SpinnerController();

  String _result = 'spin the wheel';
  int _score = 0;
  int _spinsRemaining = _spinsPerGame;
  // Highlights the result banner after a big win.
  bool _isBigWin = false;

  // Probabilities add up to 1.0, so each value is the segment's chance.
  final List<WheelSegment<int>> _segments = [
    WheelSegment('JACKPOT WINNER!', 1000,
        color: const Color(0xFFEC8484),
        path: 'assets/images/coala.png',
        probability: 0.01), // 1%
    WheelSegment('50', 50,
        color: const Color(0xFF1E88E5),
        path: 'https://cdn-icons-png.flaticon.com/512/3273/3273898.png',
        probability: 0.2), // 20%
    WheelSegment('200', 200,
        color: const Color(0xFF00C853),
        path: 'assets/images/lion.png',
        probability: 0.05), // 5%
    WheelSegment('10', 10,
        color: const Color(0xFFFFD700),
        path: 'assets/images/cheeseMouse.png',
        probability: 0.2), // 20%
    WheelSegment('0', 0,
        color: const Color(0xFFFF6D00),
        path: 'assets/images/elephent.png',
        probability: 0.1), // 10%
    WheelSegment('LOSE ALL', _loseAll,
        color: const Color(0xFF4E342E),
        path: 'assets/images/bat.png',
        semanticLabel: 'Lose all points',
        probability: 0.44), // 44%
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSpin => _spinsRemaining > 0;

  // Called for every spin, whether from the button, a tap on the center or
  // a swipe.
  void _onSpinStart() {
    setState(() {
      _spinsRemaining--;
      _result = 'Spinning...';
      _isBigWin = false;
    });
  }

  void _onComplete(WheelSegment<int> win, int index) {
    setState(() {
      if (win.value == _loseAll) {
        _score = 0;
        _result = 'you lost All';
        _isBigWin = false;
      } else {
        // `value` is an int because the segments are WheelSegment<int>.
        _score += win.value;
        _result = 'you won ${win.label}!';
        _isBigWin = win.value > 200;
      }
    });
    if (!_canSpin) _showGameOverDialog();
  }

  void _showGameOverDialog() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.indigo.shade50,
            title: const Text(
              'Game Over',
              style: TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'your final score:',
                  style: TextStyle(color: Colors.indigo.shade800),
                ),
                const SizedBox(height: 8),
                Text(
                  _score.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetGame();
                  },
                  label: const Text('Play Again'),
                  icon: const Icon(Icons.replay),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _spinsRemaining = _spinsPerGame;
      _result = 'spin the wheel';
      _isBigWin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA64D32), Color(0xFFEC5D44)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
                child: Row(
                  children: [
                    const BackButton(color: Colors.white),
                    const Spacer(),
                    _Counter(icon: Icons.attach_money, value: _score),
                    const SizedBox(width: 12),
                    _Counter(icon: Icons.refresh, value: _spinsRemaining),
                  ],
                ),
              ),
              const Text(
                'Spinner Game',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  letterSpacing: 1.5,
                  shadows: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the center or swipe the wheel to spin',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              // Takes the free space (up to 350) and shrinks on short
              // screens instead of overflowing.
              Expanded(
                child: Center(
                  child: SizedBox(
                    height: 350,
                    width: 350,
                    child: SpinnerWheel<int>(
                      controller: _controller,
                      segments: _segments,
                      semanticsLabel: 'Prize wheel',
                      labelStyle: const WheelLabelStyle(
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      // Three ways to spin: the button below, a tap on the
                      // center and a swipe. All of them use up a spin.
                      tapToSpin: _canSpin,
                      swipeToSpin: _canSpin,
                      onSpinStart: _onSpinStart,
                      // A light tick each time a slice passes the pointer.
                      onSegmentPass: (_) => HapticFeedback.selectionClick(),
                      indicatorBounce: true,
                      sliceBorderColor: Colors.white70,
                      sliceBorderWidth: 2,
                      highlightWinner: true,
                      highlightColor: Colors.amber,
                      imagePlaceholder: const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      imageErrorWidget:
                          const Icon(Icons.broken_image, color: Colors.white70),
                      onComplete: _onComplete,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ResultBanner(text: _result, highlighted: _isBigWin),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 20),
                // Rebuilds when the controller starts or stops spinning.
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final bool spinning = _controller.isSpinning;
                    return SizedBox(
                      height: 60,
                      width: 250,
                      child: ElevatedButton(
                        onPressed: spinning
                            ? _controller.stop
                            : (_canSpin ? _controller.startSpin : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              spinning ? Colors.redAccent : Colors.amber,
                          foregroundColor: Colors.brown.shade900,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 30,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: spinning ? 3 : 10,
                          shadowColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              spinning ? Icons.pan_tool : Icons.touch_app,
                              size: 28,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              spinning ? 'stop!' : 'spin!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A translucent chip showing an icon and a number.
class _Counter extends StatelessWidget {
  final IconData icon;
  final int value;

  const _Counter({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the latest result, glowing gold after a big win.
class _ResultBanner extends StatelessWidget {
  final String text;
  final bool highlighted;

  const _ResultBanner({required this.text, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? Colors.amber.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? Colors.amber.shade700
              : Colors.white.withValues(alpha: 0.3),
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: highlighted ? Colors.brown.shade900 : Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
