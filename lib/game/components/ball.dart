// ball.dart - 공 컴포넌트
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../breakout_game.dart';
import 'paddle.dart';
import 'brick.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';

/// 공 컴포넌트
class Ball extends CircleComponent with CollisionCallbacks, HasGameReference<BreakoutGame> {
  Vector2 velocity = Vector2.zero();
  bool isLaunched = false;

  // Paint 객체 캐싱 (성능 최적화)
  late final Paint _shadowPaint;
  late final Paint _mainPaint;
  late final Paint _highlightPaint;

  Ball({required Vector2 position})
      : super(
          position: position,
          radius: GameConstants.ballRadius,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 충돌 감지 추가
    add(CircleHitbox());

    // Paint 객체 초기화 (재사용)
    _shadowPaint = Paint()
      ..color = GameConstants.ballColor.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    _mainPaint = Paint()
      ..color = GameConstants.ballColor
      ..style = PaintingStyle.fill;

    _highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius + 5, _shadowPaint);
    canvas.drawCircle(Offset.zero, radius, _mainPaint);
    canvas.drawCircle(
      Offset(-radius / 3, -radius / 3),
      radius / 3,
      _highlightPaint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isLaunched) {
      // 발사되지 않았으면 패들 위에 유지
      position.x = game.paddle.position.x + game.paddle.size.x / 2;
      position.y = GameConstants.paddleY - 30;
      return;
    }

    // 공 이동
    position += velocity * dt;

    // 속도 제한 (성능 최적화)
    final speed = velocity.length;
    if (speed > GameConstants.ballMaxSpeed) {
      velocity = velocity.normalized() * GameConstants.ballMaxSpeed;
    }

    // 벽과의 충돌 체크
    _checkWallCollisions();

    // 화면 아래로 떨어졌는지 체크
    if (position.y > GameConstants.gameHeight + 50) {
      game.removeBall(this);
    }
  }

  /// 벽 충돌 체크
  void _checkWallCollisions() {
    // 좌측 벽
    if (position.x - radius < 10) {
      position.x = 10 + radius;
      velocity.x = velocity.x.abs();
    }
    // 우측 벽
    else if (position.x + radius > GameConstants.gameWidth - 10) {
      position.x = GameConstants.gameWidth - 10 - radius;
      velocity.x = -velocity.x.abs();
    }

    // 상단 벽
    if (position.y - radius < 10) {
      position.y = 10 + radius;
      velocity.y = velocity.y.abs();
    }
  }

  /// 공 발사
  void launch() {
    if (!isLaunched) {
      isLaunched = true;
      // 랜덤한 각도로 위쪽으로 발사
      final random = Random();
      final angle = -pi / 2 + (random.nextDouble() - 0.5) * pi / 3;
      velocity = Vector2(
        cos(angle) * GameConstants.ballInitialSpeed,
        sin(angle) * GameConstants.ballInitialSpeed,
      );
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Paddle) {
      _handlePaddleCollision(other, intersectionPoints);
    } else if (other is Brick) {
      _handleBrickCollision(other, intersectionPoints);
    }
  }

  /// 패들 충돌 처리
  void _handlePaddleCollision(Paddle paddle, Set<Vector2> intersectionPoints) {
    // 공이 아래로 이동 중일 때만 반사
    if (velocity.y > 0) {
      // 공 발사
      if (!isLaunched) {
        launch();
        return;
      }

      // 패들의 어느 위치에 맞았는지에 따라 반사 각도 조정
      final paddleCenter = paddle.position.x + paddle.size.x / 2;
      final hitPosition = position.x - paddleCenter;
      final normalizedHit = hitPosition / (paddle.size.x / 2);

      // 속도 조정
      velocity.y = -velocity.y.abs();
      velocity.x = normalizedHit * GameConstants.ballInitialSpeed;

      // 속도 제한
      final speed = velocity.length;
      if (speed > GameConstants.ballMaxSpeed) {
        velocity = velocity.normalized() * GameConstants.ballMaxSpeed;
      } else if (speed < GameConstants.ballInitialSpeed * 0.8) {
        velocity = velocity.normalized() * GameConstants.ballInitialSpeed;
      }

      // 위치 조정 (패들 안에 끼지 않도록)
      position.y = paddle.position.y - radius - 1;

      // 사운드 & 햅틱 피드백
      AudioService().playPaddleHit();
      HapticService().light();
    }
  }

  /// 벽돌 충돌 처리
  void _handleBrickCollision(Brick brick, Set<Vector2> intersectionPoints) {
    if (intersectionPoints.isEmpty) return;

    final intersectionPoint = intersectionPoints.first;

    // 충돌 방향 계산
    final brickCenter = brick.position + brick.size / 2;

    // 수평/수직 충돌 판정
    final dx = (intersectionPoint.x - brickCenter.x).abs();
    final dy = (intersectionPoint.y - brickCenter.y).abs();

    if (dx > dy) {
      // 좌우 충돌
      velocity.x = -velocity.x;
    } else {
      // 상하 충돌
      velocity.y = -velocity.y;
    }

    // 벽돌 피해 입히기
    brick.takeDamage();

    // 사운드 & 햅틱 피드백
    AudioService().playBrickBreak();
    HapticService().medium();
  }
}
