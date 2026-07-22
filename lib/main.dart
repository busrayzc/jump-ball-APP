import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/jump_ball_game.dart';

void main() {
  runApp(
    GameWidget(
      game: JumpBallGame(),
    ),
  );
}