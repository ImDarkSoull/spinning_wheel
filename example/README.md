# spinning_wheel example

A demo app for the [spinning_wheel](https://pub.dev/packages/spinning_wheel) package. Run it with `flutter run` from this folder.

The home screen lists five demos:

| Demo | File | Shows |
|------|------|-------|
| Prize game | [game_screen.dart](lib/screens/game_screen.dart) | Weighted probabilities, asset and URL images, spinning by button, center tap or swipe, the stop button, haptic ticks and the winner highlight |
| Playground | [playground_screen.dart](lib/screens/playground_screen.dart) | Nearly every `SpinnerWheel` option, changeable live: indicator side and bounce, slice sizing, style and borders, spin duration, curve and turns, a frame picker with its options, inset, label overflow and right-to-left text |
| Frames | [frames_screen.dart](lib/screens/frames_screen.dart) | The four ready-made frames, recolored versions, a custom-painted frame ([candy_frame.dart](lib/frames/candy_frame.dart)) and an image used as a frame |
| Server-decided result | [server_result_screen.dart](lib/screens/server_result_screen.dart) | `spinTo()` with a result from a pretend server, awaiting the result, and `String` segment values |
| Custom segments | [custom_segments_screen.dart](lib/screens/custom_segments_screen.dart) | A themed frame, a custom value type, widgets and `ImageProvider`s on slices, per-slice text styles, image loading and error placeholders, screen reader labels, and slices sized by probability |

[spin_stop_button.dart](lib/widgets/spin_stop_button.dart) shows how to rebuild UI from the `SpinnerController` with a `ListenableBuilder`.
