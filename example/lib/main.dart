import 'package:flutter/material.dart';
import 'package:spinning_wheel/controller/spinner_controller.dart';
import 'package:spinning_wheel/spinning_wheel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spinning Wheel Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  // double _startRotation = 0.0;
  // double _endRotation = 0.0;

  SpinnerController controller = SpinnerController();

  bool _isSpinning = false;
  String _result = 'spin the wheel';
  int _score = 0;
  //total spins
  int _spinsRemaining = 5;
  bool _showConfetti = false;

  final List<WheelSegment> _segments = [
    WheelSegment('+1 spin', const Color(0xFFEC8484), 1,
        path: 'assets/images/coala.png'), // Soft White
    WheelSegment('50', const Color(0xFF1E88E5), 50,
        path: 'assets/images/bunny.png'), // Royal Blue
    WheelSegment('200', const Color(0xFF00C853), 200,
        path: 'assets/images/lion.png'), // Emerald Green
    WheelSegment('10', const Color(0xFFFFD700), 10,
        path: 'assets/images/cheeseMouse.png'), // Gold
    WheelSegment('0', const Color(0xFFFF6D00), 0,
        path: 'assets/images/elephent.png'), // Bright Orange
    WheelSegment('LOSE ALL', const Color(0xFF4E342E), -9999,
        path: 'assets/images/bat.png'), // Deep Chocolate Brown
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void _spinWheel() {
    if (_isSpinning || _spinsRemaining <= 0) return;
    setState(() {
      _spinsRemaining--;
      _isSpinning = true;
      _result = "Spinning...";
      _showConfetti = false;
    });
    controller.start();
  }

  void _showGameOverDialog() {
    Future.delayed(Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.indigo.shade50,
            title: Text(
              "Game Over",
              style: TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                SizedBox(height: 16),
                Text(
                  "your final score:",
                  style: TextStyle(color: Colors.indigo.shade800),
                ),
                SizedBox(height: 8),
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
                  label: Text("Play Again"),
                  icon: Icon(Icons.replay),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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
      _spinsRemaining = 5;
      _result = "spin the wheel";
      _showConfetti = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA64D32), Color(0xFFEC5D44)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.attach_money, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                _score.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.refresh, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                _spinsRemaining.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Spinner Game",
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
                  SizedBox(height: 20),
                  SizedBox(
                    height: 350,
                    width: 350,
                    child: SpinnerWheel(
                      controller: controller,
                      segments: _segments,
                      onComplete: (win, index) {
                        print("index......$index");
                        setState(() {
                          if (win.value == -9999) {
                            _score = 0;
                            _result = "you lost All";
                            _showConfetti = false;
                          } else if (win.value == 1) {
                            _result = 'you got 1 spin';
                            _spinsRemaining++;
                            _showConfetti = false;
                          } else if (win.value > 200) {
                            _score += win.value;
                            _result = 'you won ${win.label}!';
                            _showConfetti = true;
                          } else {
                            _score += win.value;
                            _result = "you won ${win.label}!";
                            _showConfetti = win.value >= 500;
                          }

                          _isSpinning = false;

                          if (_spinsRemaining <= 0) {
                            _showGameOverDialog();
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _showConfetti
                          ? Colors.amber.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showConfetti
                            ? Colors.amber.shade700
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                      boxShadow: _showConfetti
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
                      _result,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _showConfetti
                            ? Colors.brown.shade900
                            : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 10, top: 20),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      height: 60,
                      width: 250,
                      transform: Matrix4.identity()
                        ..scale(_isSpinning ? 0.9 : 1.0),
                      child: ElevatedButton(
                        onPressed: _isSpinning ? null : _spinWheel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isSpinning ? Colors.grey : Colors.amber,
                          foregroundColor: Colors.brown.shade900,
                          padding: EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 30,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: _isSpinning ? 3 : 10,
                          shadowColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSpinning
                                  ? Icons.hourglass_top
                                  : Icons.touch_app,
                              size: 28,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              _isSpinning ? "spinning..." : "spin!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
