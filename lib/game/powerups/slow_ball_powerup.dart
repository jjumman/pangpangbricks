// slow_ball_powerup.dart - 느린 공 파워업
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import 'powerup.dart';

/// 슬로우 볼 파워업 - 공 속도 50% 감소
class SlowBallPowerUp extends PowerUp {
  SlowBallPowerUp({required Vector2 position})
      : super(position: position, type: PowerUpType.slowBall);

  @override
  void activate() {
    // 모든 공의 속도를 50% 감소
    for (final ball in game.balls) {
      ball.velocity *= 0.5;
    }

    // 5초 후 원래대로
    Future.delayed(const Duration(seconds: 5), () {
      for (final ball in game.balls) {
        if (ball.isMounted) {
          ball.velocity *= 2.0;
        }
      }
    });
  }

  @override
  Color getColor() {
    return const Color(0xFF06ffa5);
  }
}
