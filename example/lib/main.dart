import 'package:flutter/material.dart';

import 'screens/custom_segments_screen.dart';
import 'screens/frames_screen.dart';
import 'screens/game_screen.dart';
import 'screens/playground_screen.dart';
import 'screens/server_result_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spinning Wheel Example',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      home: const HomeScreen(),
    );
  }
}

/// One entry in the list of demos.
class _Demo {
  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;

  const _Demo(this.title, this.description, this.icon, this.builder);
}

final List<_Demo> _demos = [
  _Demo(
    'Prize game',
    'Five spins to score. Tap the center, swipe the wheel or press spin, '
        'and stop it early if you dare.',
    Icons.casino,
    (_) => const GameScreen(),
  ),
  _Demo(
    'Playground',
    'Try every option live: frames, indicator side, slice sizes and '
        'styles, spin speed, label overflow, right-to-left and more.',
    Icons.tune,
    (_) => const PlaygroundScreen(),
  ),
  _Demo(
    'Frames',
    'Four ready-made frames, recolored versions, a custom-painted frame '
        'and an image used as a frame.',
    Icons.circle_outlined,
    (_) => const FramesScreen(),
  ),
  _Demo(
    'Server-decided result',
    'The result comes from a (pretend) server and the wheel lands on it '
        'with spinTo().',
    Icons.cloud_sync,
    (_) => const ServerResultScreen(),
  ),
  _Demo(
    'Custom segments',
    'Typed values, widgets and image providers on slices, per-slice text '
        'styles and image loading placeholders.',
    Icons.widgets,
    (_) => const CustomSegmentsScreen(),
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spinning Wheel')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _demos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final demo = _demos[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(demo.icon, size: 32),
              title: Text(demo.title),
              subtitle: Text(demo.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: demo.builder)),
            ),
          );
        },
      ),
    );
  }
}
