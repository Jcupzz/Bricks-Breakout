import 'dart:html';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum GameState { Playing, Won, Lost }

class Bricks extends BaseGame {
  double x;
  Vector2 screenSize;
  static final blocksWide = 6;
  static final blocksHigh = 8;
  static final blockHeight = 20.0;
  int ballXDirection = 1;
  int ballYDirection = -1;
  Rect ballPos;
  Rect paddlePos;
  GameState gameState = GameState.Playing;

  Bricks() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      x = event.x;
      // print(x);
    });
  }

  List<List<bool>> blocks = List.generate(
      blocksHigh, (int index) => List.filled(blocksWide, true, growable: false),
      growable: false);

  @override
  void onResize(Vector2 canvasSize) {
    // TODO: implement onResize
    super.onResize(canvasSize);

    screenSize = canvasSize;

    print(screenSize.toString());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (ballYDirection == -1) {
      double width = size.x / blocksWide;
      for (int i = 0; i < blocks.length; ++i) {
        for (int j = 0; j < blocks[i].length; ++j) {
          if (blocks[i][j]) {
            if (Rect.fromLTWH(width * j, blockHeight * i, width, blockHeight)
                .deflate(1)
                .overlaps(ballPos)) {
              print('intersect ${i}, ${j}');
              print('pre blocks[0][j] ${blocks[0][j]}');
              blocks[i][j] = false;
              print('blocks[i][j] ${blocks[i][j]}');
              print('blocks[0][j] ${blocks[0][j]}');
              ballYDirection = 1;
              return;
            }
          }
        }
      }
    } else {
      if (paddlePos.overlaps(ballPos)) {
        ballYDirection = -1;
      }
    }

    if (ballXDirection == 1 && ballPos.right > size.x) {
      ballXDirection = -1;
    } else if (ballXDirection == -1 && ballPos.left < 0) {
      ballXDirection = 1;
    }

    if (ballPos.top < 0) {
      gameState = GameState.Won;
    } else if (ballPos.bottom > size.y) {
      gameState = GameState.Lost;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
  }
}
