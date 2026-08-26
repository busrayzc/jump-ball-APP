import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'platform.dart';

class Player extends CircleComponent {
  static const double ballRadius = 20;

  static const double gravity = 1600;
  static const double jumpSpeed = -900;
  static const double horizontalSpeed = 250;

  final double screenWidth;
  final double screenHeight;
  final List<GamePlatform> platforms;
  final void Function(GamePlatform platform) onPlatformLanded;
  final void Function() onPlayerFell;

  bool hasFallen = false;
   
 

  double verticalVelocity = jumpSpeed;
  double horizontalVelocity = 0;

  Player({
  required Vector2 position,
  required this.screenWidth,
  required this.screenHeight,
  required this.platforms,
  required this.onPlatformLanded,
  required this.onPlayerFell,
}) : super(
        position: position,
        radius: ballRadius,
        anchor: Anchor.center,
        priority: 10,
        paint: Paint()..color = const Color.fromARGB(255, 244, 54, 225),
      );

  void moveLeft() {
    horizontalVelocity = -horizontalSpeed;
  }

  void moveRight() {
    horizontalVelocity = horizontalSpeed;
  }

void resetPlayer(Vector2 startPosition) {
  position.setFrom(startPosition);
  verticalVelocity = jumpSpeed;
  horizontalVelocity = 0;
  hasFallen = false;
}

  @override
  void update(double dt) {
    super.update(dt);

    final previousBallBottom = position.y + ballRadius;

    verticalVelocity += gravity * dt;

    position.x += horizontalVelocity * dt;
    position.y += verticalVelocity * dt;

    final minimumX = ballRadius;
    final maximumX = screenWidth - ballRadius;

    position.x = position.x.clamp(
      minimumX,
      maximumX,
    );

    checkPlatformCollisions(previousBallBottom);
    checkIfPlayerFell();
  }

  void checkPlatformCollisions(double previousBallBottom) {
    if (verticalVelocity <= 0) {
      return;
    }

    final ballLeft = position.x - ballRadius;
    final ballRight = position.x + ballRadius;
    final ballBottom = position.y + ballRadius;

    for (final platform in platforms) {
      final platformLeft =
          platform.position.x - (GamePlatform.platformWidth / 2);

      final platformRight =
          platform.position.x + (GamePlatform.platformWidth / 2);

      final platformTop =
          platform.position.y - (GamePlatform.platformHeight / 2);

      final isHorizontallyAbovePlatform =
          ballRight >= platformLeft && ballLeft <= platformRight;

      final crossedPlatformTop =
          previousBallBottom <= platformTop && ballBottom >= platformTop;

      if (isHorizontallyAbovePlatform && crossedPlatformTop) {
        position.y = platformTop - ballRadius;
        verticalVelocity = jumpSpeed;
        horizontalVelocity = 0;

        onPlatformLanded(platform);

        return;
      }
    }
  }

  void checkIfPlayerFell() {
  final ballTop = position.y - ballRadius;

  if (!hasFallen && ballTop > screenHeight) {
    hasFallen = true;
    onPlayerFell();
  }
}
}