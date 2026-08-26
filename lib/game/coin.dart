import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GameCoin extends CircleComponent {
  static const double coinRadius = 12;

  GameCoin({
    required Vector2 position,
  }) : super(
          position: position,
          radius: coinRadius,
          anchor: Anchor.center,
          paint: Paint()..color = Colors.amber,
        );
}