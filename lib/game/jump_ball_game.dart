import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

import 'platform.dart';
import 'player.dart';

class JumpBallGame extends FlameGame with TapCallbacks {
  late final Player player;
  late final TextComponent scoreText;
  late final TextComponent gameOverText;

  final List<GamePlatform> platforms = [];

  int score = 0;
  int highestPlatformIndex = 0;

  @override
  Color backgroundColor() {
    return BasicPalette.black.color;
  }

  GamePlatform createPlatform(Vector2 position) {
    return GamePlatform(
      position: position,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final platformPositions = <Vector2>[
      Vector2(size.x * 0.30, size.y * 0.82),
      Vector2(size.x * 0.70, size.y * 0.66),
      Vector2(size.x * 0.30, size.y * 0.50),
      Vector2(size.x * 0.70, size.y * 0.34),
      Vector2(size.x * 0.30, size.y * 0.18),
    ];

    for (final platformPosition in platformPositions) {
      final platform = createPlatform(
        platformPosition,
      );

      platforms.add(platform);
      await add(platform);
    }

    scoreText = TextComponent(
      text: 'Skor: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    await add(scoreText);

    gameOverText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    await add(gameOverText);

    final firstPlatform = platforms.first;

    final firstPlatformTop =
        firstPlatform.position.y - (GamePlatform.platformHeight / 2);

    final playerPosition = Vector2(
      firstPlatform.position.x,
      firstPlatformTop - Player.ballRadius,
    );

    player = Player(
      position: playerPosition,
      screenWidth: size.x,
      screenHeight: size.y,
      platforms: platforms,
      onPlatformLanded: updateScore,
      onPlayerFell: endGame,
    );

    await add(player);
  }

  void updateScore(GamePlatform landedPlatform) {
    final platformIndex = platforms.indexOf(landedPlatform);

    if (platformIndex > highestPlatformIndex) {
      highestPlatformIndex = platformIndex;
      score = platformIndex;

      scoreText.text = 'Skor: $score';
    }
  }

  void endGame() {
    gameOverText.text = 'Oyun Bitti!\nSkor: $score';
    pauseEngine();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    final tapX = event.canvasPosition.x;
    final screenCenterX = size.x / 2;

    if (tapX < screenCenterX) {
      player.moveLeft();
    } else {
      player.moveRight();
    }
  }
}