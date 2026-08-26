import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform.dart';
import 'player.dart';
import 'coin.dart';

class JumpBallGame extends FlameGame with TapCallbacks {
  late final Player player;
  late final TextComponent scoreText;
  late final TextComponent highScoreText;
  late final TextComponent coinText;
  late final TextComponent gameOverText;
  late final RectangleComponent gameOverBox;
  
  late final RectangleComponent restartButton;
  late final TextComponent restartButtonText;
  late final RectangleComponent background;

  late final CircleComponent mistOne;
  late final CircleComponent mistTwo;
  late final CircleComponent mistThree;  

  final List<CircleComponent> backgroundParticles = [];
  final List<SpriteComponent> floatingIslands = [];

  final List<GamePlatform> platforms = [];
  final List<GameCoin> gameCoins = [];
  final Set<GamePlatform> landedPlatforms = {};
  final Random random = Random();

  int score = 0;
  int highScore = 0;
  int coins = 0;
  int createdPlatformCount = 0;

  static const int movingPlatformStartScore = 25;

  bool isGameOver = false;
  bool isGeneratingPlatforms = false;
  bool isRestarting = false;

@override
Color backgroundColor() {
  return const Color(0xFF24133F);
}



  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.load('floating_island.png');
    await images.load('sky_background.png');
    await images.load('platform_green.png');

    background = RectangleComponent(
      position: Vector2.zero(),
      size: size,
      priority: -100,
      paint: Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
        Color(0xFF17102F),
        Color(0xFF3B1E68),
        Color(0xFF7045A0),
      ],
    ).createShader(
      Rect.fromLTWH(0, 0, size.x, size.y),
    ),
);

await add(background);

mistOne = CircleComponent(
  position: Vector2(size.x * 0.15, size.y * 0.25),
  radius: 90,
  priority: -90,
  paint: Paint()
    ..color = Colors.white.withValues(alpha: 0.08),
);

await add(mistOne);

mistTwo = CircleComponent(
  position: Vector2(size.x * 0.85, size.y * 0.45),
  radius: 120,
  priority: -90,
  paint: Paint()
    ..color = Colors.white.withValues(alpha: 0.06),
);

await add(mistTwo);

mistThree = CircleComponent(
  position: Vector2(size.x * 0.35, size.y * 0.75),
  radius: 150,
  priority: -90,
  paint: Paint()
    ..color = Colors.white.withValues(alpha: 0.04),
);

await add(mistThree);

for (int i = 0; i < 20; i++) {
  final particle = CircleComponent(
    position: Vector2(
      random.nextDouble() * size.x,
      random.nextDouble() * size.y,
    ),
    radius: 1 + random.nextDouble() * 2,
    priority: -80,
    paint: Paint()
      ..color = Colors.white.withValues(
        alpha: 0.25 + random.nextDouble() * 0.45,
      ),
  );

  backgroundParticles.add(particle);
  await add(particle);
}

final skyImage = images.fromCache('sky_background.png');

final imageRatio = skyImage.width / skyImage.height;
final screenRatio = size.x / size.y;

double backgroundWidth;
double backgroundHeight;

if (screenRatio > imageRatio) {
  backgroundWidth = size.x;
  backgroundHeight = size.x / imageRatio;
} else {
  backgroundHeight = size.y;
  backgroundWidth = size.y * imageRatio;
}

final skyBackground = SpriteComponent(
  sprite: Sprite(skyImage),
  position: Vector2(size.x / 2, size.y / 2),
  size: Vector2(backgroundWidth, backgroundHeight),
  anchor: Anchor.center,
  priority: -95,
);

await add(skyBackground);

final islandSprite = SpriteComponent(
  sprite: Sprite(images.fromCache('floating_island.png')),
  position: Vector2(size.x * 0.22, size.y * 0.32),
  size: Vector2(170, 125),
  anchor: Anchor.center,
  priority: -70,
);

floatingIslands.add(islandSprite);
await add(islandSprite);

final islandSpriteTwo = SpriteComponent(
  sprite: Sprite(images.fromCache('floating_island.png')),
  position: Vector2(size.x * 0.78, size.y * 0.58),
  size: Vector2(95, 70),
  anchor: Anchor.center,
  priority: -75,
);

floatingIslands.add(islandSpriteTwo);
await add(islandSpriteTwo);

    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;

    await createStartingPlatforms();
    await createInterface();

    final playerStartPosition = getPlayerStartPosition();

    player = Player(
      position: playerStartPosition,
      screenWidth: size.x,
      screenHeight: size.y,
      platforms: platforms,
      onPlatformLanded: updateScore,
      onPlayerFell: endGame,
    );

    await add(player);
  }

GamePlatform createPlatform(Vector2 position) {
  final shouldMove =
      score >= movingPlatformStartScore &&
      random.nextDouble() < 0.25;

  return GamePlatform(
    position: position,
    screenWidth: size.x,
    isMoving: shouldMove,
    sprite: Sprite(images.fromCache('platform_green.png')),
  );
}

  List<Vector2> getStartingPlatformPositions() {
    return [
      Vector2(size.x * 0.30, size.y * 0.82),
      Vector2(size.x * 0.70, size.y * 0.66),
      Vector2(size.x * 0.30, size.y * 0.50),
      Vector2(size.x * 0.70, size.y * 0.34),
      Vector2(size.x * 0.30, size.y * 0.18),
    ];
  }

  Future<void> createStartingPlatforms() async {
    for (final platformPosition in getStartingPlatformPositions()) {
      final platform = createPlatform(platformPosition);
      platforms.add(platform);
      await add(platform);

      createdPlatformCount++;
    }
  }

  Future<void> createInterface() async {
    scoreText = TextComponent(
      text: 'Skor: 0',
      position: Vector2(20, 20),
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    await add(scoreText);

    highScoreText = TextComponent(
  text: 'Rekor: $highScore',
  position: Vector2(20, 60),
  textRenderer: TextPaint(
    style: const TextStyle(
      color: Colors.yellow,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
);

await add(highScoreText);

coinText = TextComponent(
  text: 'Coin: $coins',
  position: Vector2(size.x - 20, 20),
  anchor: Anchor.topRight,
  textRenderer: TextPaint(
    style: const TextStyle(
      color: Colors.orange,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
);

await add(coinText);

    gameOverBox = RectangleComponent(
      position: Vector2(size.x / 2, size.y / 2),
      size: Vector2(size.x * 0.85, 180),
      anchor: Anchor.center,
      priority: 100,
      paint: Paint()..color = Colors.transparent,
    );
    await add(gameOverBox);

    gameOverText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      priority: 101,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
    );

    await add(gameOverText);

    restartButton = RectangleComponent(
      position: Vector2(size.x / 2, size.y / 2 + 150),
      size: Vector2(size.x * 0.85, 70),
      anchor: Anchor.center,
      priority: 102,
      paint: Paint()..color = Colors.transparent,
    );
    await add(restartButton);

    restartButtonText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, size.y / 2 + 150),
      anchor: Anchor.center,
      priority: 103,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    await add(restartButtonText);
  }

  Vector2 getPlayerStartPosition() {
   
   final firstPlatform = platforms.first;
    final firstPlatformTop =
        firstPlatform.position.y - (GamePlatform.platformHeight / 2);

    return Vector2(
      firstPlatform.position.x,
      firstPlatformTop - Player.ballRadius,
    );
  }

  double getRandomPlatformX() {
    final minimumX = GamePlatform.platformWidth / 2;
    final maximumX = size.x - (GamePlatform.platformWidth / 2);

    return minimumX +
        random.nextDouble() * (maximumX - minimumX);
  }

  Future<void> createNewPlatform(double y) async {
  final platform = createPlatform(
    Vector2(getRandomPlatformX(), y),
  );

  platforms.add(platform);
  await add(platform);

  // Her platformda %35 ihtimalle coin oluştur.
  if (score >= 30 && random.nextDouble() < 0.15) {
    final coin = GameCoin(
      position: Vector2(
        platform.position.x,
        platform.position.y - 40,
      ),
    );

    gameCoins.add(coin);
    await add(coin);
  }
}

  GamePlatform getHighestPlatform() {
    GamePlatform highestPlatform = platforms.first;

    for (final platform in platforms) {
      if (platform.position.y < highestPlatform.position.y) {
        highestPlatform = platform;
      }
    }

    return highestPlatform;
  }

  double getNextPlatformY() {
    const platformGap = 150.0;
    return getHighestPlatform().position.y - platformGap;
  }

  Future<void> generatePlatformsIfNeeded() async {
    if (isGeneratingPlatforms || platforms.isEmpty) {
      return;
    }

    isGeneratingPlatforms = true;

    try {
      while (platforms.length < 10) {
        await createNewPlatform(getNextPlatformY());
      }
    } finally {
      isGeneratingPlatforms = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver || isRestarting) {
      return;
    }

    for (final particle in backgroundParticles) {
  particle.position.y += 4 * dt;

  if (particle.position.y > size.y + 5) {
    particle.position.y = -5;
    particle.position.x = random.nextDouble() * size.x;
  }
}

if (floatingIslands.length >= 2) {
  floatingIslands[0].position.x += 2 * dt;
  floatingIslands[1].position.x -= 1.5 * dt;

  if (floatingIslands[0].position.x > size.x + 60) {
    floatingIslands[0].position.x = -60;
  }

  if (floatingIslands[1].position.x < -50) {
    floatingIslands[1].position.x = size.x + 50;
  }
}

    mistOne.position.x += 5 * dt;
    mistTwo.position.x -= 3 * dt;
    mistThree.position.x += 2 * dt;

    if (mistOne.position.x > size.x + mistOne.radius) {
  mistOne.position.x = -mistOne.radius;
}

if (mistTwo.position.x < -mistTwo.radius) {
  mistTwo.position.x = size.x + mistTwo.radius;
}

if (mistThree.position.x > size.x + mistThree.radius) {
  mistThree.position.x = -mistThree.radius;
}

    final scrollLimit = size.y * 0.40;

    if (player.position.y < scrollLimit) {
      final scrollAmount = scrollLimit - player.position.y;
      player.position.y = scrollLimit;

      for (final platform in platforms) {
        platform.position.y += scrollAmount;
      }

      for (final coin in gameCoins) {
       coin.position.y += scrollAmount;
      }
    }

    final platformsBelowScreen = platforms.where(
      (platform) =>
          platform.position.y >
          size.y + GamePlatform.platformHeight,
    ).toList();

    for (final platform in platformsBelowScreen) {
      platforms.remove(platform);
      landedPlatforms.remove(platform);
      platform.removeFromParent();
    }

    final collectedCoins = gameCoins.where((coin) {
      final distance = player.position.distanceTo(coin.position);

      return distance < Player.ballRadius + GameCoin.coinRadius;
    }).toList();

for (final coin in collectedCoins) {
  gameCoins.remove(coin);
  coin.removeFromParent();

  coins++;
  coinText.text = 'Coin: $coins';

  SharedPreferences.getInstance().then((prefs) {
  prefs.setInt('coins', coins);
});
}

    generatePlatformsIfNeeded();
  }

  void updateScore(GamePlatform landedPlatform) async {
  if (isGameOver || landedPlatforms.contains(landedPlatform)) {
    return;
  }

  landedPlatforms.add(landedPlatform);
  score++;
  scoreText.text = 'Skor: $score';

  if (score > highScore) {
    highScore = score;
    highScoreText.text = 'Rekor: $highScore';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
    coins = prefs.getInt('coins') ?? 0;
  }
}

  void endGame() {
    if (isGameOver) {
      return;
    }

    isGameOver = true;

    gameOverBox.paint.color =
        const Color.fromARGB(204, 171, 4, 160);
    restartButton.paint.color =
        const Color.fromARGB(204, 171, 4, 160);

    restartButtonText.text = 'Tekrar Başla';
    if (score >= highScore) {
      
  gameOverText.text =
      '🎉 YENİ REKOR!\n\n'
      '🏆 $highScore Puan';
} else {
  gameOverText.text =
      '🎮 OYUN BİTTİ!\n\n'
      '⭐ Skor: $score\n'
      '🏆 Rekor: $highScore';
}

    pauseEngine();
  }

  Future<void> restartGame() async {
    if (isRestarting) {
      return;
    }

    isRestarting = true;

    for (final platform in List<GamePlatform>.from(platforms)) {
      platform.removeFromParent();
    }

    platforms.clear();
    landedPlatforms.clear();

    await createStartingPlatforms();

    score = 0;
    isGameOver = false;
    isGeneratingPlatforms = false;

    scoreText.text = 'Skor: 0';
    gameOverText.text = '';
    gameOverBox.paint.color = Colors.transparent;
    restartButtonText.text = '';
    restartButton.paint.color = Colors.transparent;

    player.resetPlayer(getPlayerStartPosition());

    isRestarting = false;
    resumeEngine();
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (isGameOver) {
      final tapPosition = event.canvasPosition;

      final buttonLeft =
          restartButton.position.x - (restartButton.size.x / 2);
      final buttonRight =
          restartButton.position.x + (restartButton.size.x / 2);
      final buttonTop =
          restartButton.position.y - (restartButton.size.y / 2);
      final buttonBottom =
          restartButton.position.y + (restartButton.size.y / 2);

      final tappedRestartButton =
          tapPosition.x >= buttonLeft &&
          tapPosition.x <= buttonRight &&
          tapPosition.y >= buttonTop &&
          tapPosition.y <= buttonBottom;

      if (tappedRestartButton) {
        restartGame();
      }

      return;
    }

    final tapX = event.canvasPosition.x;
    final screenCenterX = size.x / 2;

    if (tapX < screenCenterX) {
      player.moveLeft();
    } else {
      player.moveRight();
    }
  }
}
