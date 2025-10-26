// large_paddle_powerup.dart - 큰 패들 파워업
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import 'powerup.dart';

/// 큰 패들 파워업 - 패들 크기 2배
class LargePaddlePowerUp extends PowerUp {
  LargePaddlePowerUp({required Vector2 position})
      : super(position: position, type: PowerUpType.largePaddle);

  @override
  void activate() {
    // 패들 크기를 150으로 확대
    game.paddle.setSize(150);

    // 5초 후 원래대로
    Future.delayed(const Duration(seconds: 5), () {
      if (game.paddle.isMounted) {
        game.paddle.resetSize();
      }
    });
  }

  @override
  Color getColor() {
    return const Color(0xFF00d4ff);
  }
}
