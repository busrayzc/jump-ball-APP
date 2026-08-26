import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GamePlatform extends SpriteComponent {
  static const double platformWidth = 120;
  static const double platformHeight = 36;

  final bool isMoving;
  final double screenWidth;

  double moveDirection = 1;

GamePlatform({
    required Vector2 position,
    required this.screenWidth,
    this.isMoving = false,
    Sprite? sprite,
  }) : super(
          position: position,
          size: Vector2(
            platformWidth,
            platformHeight,
          ),
          anchor: Anchor.center,
          sprite: sprite,
        );


@override
void update(double dt) {
  super.update(dt);

  if (!isMoving) {
    return;
  }

  position.x += 80 * moveDirection * dt;
  
  final halfWidth = platformWidth / 2;

if (position.x + halfWidth >= screenWidth) {
  position.x = screenWidth - halfWidth;
  moveDirection = -1;
}

if (position.x - halfWidth <= 0) {
  position.x = halfWidth;
  moveDirection = 1;
}

  }
 }
