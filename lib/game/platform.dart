import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GamePlatform extends RectangleComponent {
  static const double platformWidth = 120;
  static const double platformHeight = 24;

  GamePlatform({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(
            platformWidth,
            platformHeight,
          ),
          anchor: Anchor.center,
          paint: Paint()..color = Colors.blue,
        );
}