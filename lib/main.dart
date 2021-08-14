import 'package:bricks_breakout/Game/game_controller.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final game = Bricks();
  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: game,
    );
  }
}
