import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flame/gestures.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flame.device.fullScreen();
  await Flame.device.setOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  final breakout = Breakout();
  runApp(
    Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      child: GameWidget(
        game: breakout,
      ),
    ),
  );
}

enum GameState { Playing, Won, Lost }

class Breakout extends Game with HorizontalDragDetector, TapDetector {
  int ballSpeed = 100;
  // int paddleSpeed = 300;
  // int paddleDirection = 1;
  var ballPaint = Paint()
    ..color = Color(0xffffffff)
    ..style = PaintingStyle.fill;
  static final blocksWide = 8;
  static final blocksHigh = 2;
  static final blockHeight = 20.0;
  Rect ballPos;
  Rect paddlePos;
  Rect bR;
  Rect bL;
  int ballXDirection = 1;
  int ballYDirection = -1;
  bool touchDown = false;
  double touchPosition = 0;
  GameState gameState = GameState.Playing;
  bool leftKeyDown = false;
  bool rightKeyDown = false;
  double y = 0;
  NativeDeviceOrientation orientation = NativeDeviceOrientation.landscapeLeft;

  double paddleWeight = 1.5; // The more the weight, the more the lagg
  double paddleSensorStart =
      1.5; // The more the sensor start, the more the tilt needed to move the paddle

  List<List<bool>> blocks = List.generate(
      blocksHigh, (int index) => List.filled(blocksWide, true, growable: false),
      growable: false);

  reset() {
    gameState = GameState.Playing;
    ballPos = Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2), width: 10, height: 10);
    paddlePos = Rect.fromCenter(
        center: Offset(size.x / 2, size.y - 20), width: 100, height: 20);
    bL =
        Rect.fromCenter(center: Offset(-1, size.y - 50), width: 5, height: 100);
    bR = Rect.fromCenter(
        center: Offset(size.x, size.y - 50), width: 5, height: 100);
    ballXDirection = 1;
    ballYDirection = -1;
    for (int i = 0; i < blocks.length; ++i) {
      for (int j = 0; j < blocks[i].length; ++j) {
        blocks[i][j] = true;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    reset();

    NativeDeviceOrientationCommunicator nativeDeviceOrientationCommunicator =
        NativeDeviceOrientationCommunicator();

    nativeDeviceOrientationCommunicator.onOrientationChanged().listen((event) {
      orientation = event;
    });

    accelerometerEvents.listen((AccelerometerEvent event) {
      y = event.y;
      // print(x);
    });
  }

  @override
  void update(double dt) {
    if (gameState != GameState.Playing) {
      return;
    }

    double delta = y * 100 * dt;

    if (orientation == NativeDeviceOrientation.landscapeLeft) {
      print("Fak is left");

      if (y > paddleSensorStart) {
        if (paddlePos.overlaps(bR)) {
        } else {
          paddlePos = paddlePos.translate(delta / paddleWeight, 0);
        }
      } else if (y < -paddleSensorStart) {
        //left
        if (paddlePos.overlaps(bL)) {
        } else {
          paddlePos = paddlePos.translate(delta / paddleWeight, 0);
        }
      } else {
        delta = 0;
      }
    } else {
      print("Fak is right");

      if (y > paddleSensorStart) {
        if (paddlePos.overlaps(bL)) {
        } else {
          paddlePos = paddlePos.translate(-delta / paddleWeight, 0);
        }
      } else if (y < -paddleSensorStart) {
        print("right");

        if (paddlePos.overlaps(bR)) {
        } else {
          paddlePos = paddlePos.translate(delta.abs() / paddleWeight, 0);
        }
      } else {
        delta = 0;
      }
    }

    ballPos = ballPos.translate(
        ballSpeed * ballXDirection * dt, ballSpeed * ballYDirection * dt);

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

    if (ballYDirection == -1 && ballPos.top < 0) {
      ballYDirection = 1;
    } else if (ballYDirection == 1 && ballPos.top < 0) {
      ballYDirection = -1;
    }

    if (blocks
        .every((element) => element.every((element) => element == false))) {
      gameState = GameState.Won;
    } else if (ballPos.bottom > size.y) {
      gameState = GameState.Lost;
    }
  }

  @override
  void render(Canvas canvas) {
    if (gameState != GameState.Playing) {
      final String text = gameState == GameState.Won ? 'You Won!' : 'You Lost!';
      TextSpan span = new TextSpan(
          style: new TextStyle(color: Colors.white, fontSize: 100), text: text);
      TextPainter tp = new TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas,
          new Offset(size.x / 2 - tp.width / 2, size.y / 2 - tp.height / 2));
      return;
    }
    double width = size.x / blocksWide;
    for (int i = 0; i < blocks.length; ++i) {
      for (int j = 0; j < blocks[i].length; ++j) {
        if (blocks[i][j]) {
          canvas.drawRect(
              Rect.fromLTWH(width * j, blockHeight * i, width, blockHeight)
                  .deflate(1),
              ballPaint);
        }
      }
    }
    canvas.drawRect(ballPos, ballPaint);
    canvas.drawRect(paddlePos, ballPaint);
    canvas.drawRect(
        bL,
        Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill);
    canvas.drawRect(
        bR,
        Paint()
          ..color = Colors.transparent
          ..style = PaintingStyle.fill);
  }

  @override
  void onTap() {
    reset();
  }
}
