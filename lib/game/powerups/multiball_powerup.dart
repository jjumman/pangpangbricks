// multiball_powerup.dart - 멀티볼 파워업
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import 'powerup.dart';

/// 멀티볼 파워업 - 공을 2개 추가
class MultiballPowerUp extends PowerUp {
  MultiballPowerUp({required Vector2 position})
      : super(position: position, type: PowerUpType.multiball);

  @override
  void activate() {
    // 현재 공의 위치와 속도를 기반으로 2개의 공 추가
    if (game.balls.isNotEmpty) {
      final originalBall = game.balls.first;
      final random = Random();

      for (int i = 0; i < 2; i++) {
        final angle = random.nextDouble() * pi * 2;
        final velocity = Vector2(
          cos(angle) * GameConstants.ballInitialSpeed,
          sin(angle) * GameConstants.ballInitialSpeed,
        );

        game.addBall(originalBall.position.clone(), velocity);
      }
    }
  }

  @override
  Color getColor() {
    return const Color(0xFFff006e);
  }
}
