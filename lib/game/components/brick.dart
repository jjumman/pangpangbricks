// brick.dart - 벽돌 컴포넌트
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../breakout_game.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';

/// 벽돌 컴포넌트
class Brick extends RectangleComponent with CollisionCallbacks, HasGameReference<BreakoutGame> {
  final BrickType type;
  int hitPoints;
  bool isMoving = false;
  bool isDestroying = false; // 파괴 중 플래그 (무한 루프 방지)
  double moveSpeed = 30.0;
  double moveDirection = 1.0;
  double moveRange = 50.0;
  double initialX = 0;

  // Paint 객체 캐싱 (성능 최적화)
  late final Paint _shadowPaint;
  late final Paint _mainPaint;

  // 그리드 위치 저장
  final int gridX;
  final int gridY;

  Brick({
    required this.gridX,
    required this.gridY,
    this.type = BrickType.normal,
  })  : hitPoints = _getInitialHitPoints(type),
        super(
          size: Vector2(GameConstants.brickWidth, GameConstants.brickHeight),
          anchor: Anchor.topLeft,
        ) {
    isMoving = type == BrickType.moving;
  }

  static int _getInitialHitPoints(BrickType type) {
    switch (type) {
      case BrickType.normal:
        return 1;
      case BrickType.hard:
        return 3;
      case BrickType.explosive:
        return 1;
      case BrickType.moving:
        return 2;
      case BrickType.bonus:
        return 1;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 화면 크기 기반 위치 계산
    final brickWidth = GameConstants.brickWidth;
    final brickSpacing = GameConstants.brickSpacing;
    final paddingX = (game.gameWidth - (7 * brickWidth + 6 * brickSpacing)) / 2; // 7열 기준 중앙 정렬

    position = Vector2(
      paddingX + gridX * (brickWidth + brickSpacing),
      game.brickOffsetY + gridY * (GameConstants.brickHeight + brickSpacing),
    );
    initialX = position.x;

    // 충돌 감지 추가
    add(RectangleHitbox());

    // Paint 객체 초기화 (재사용)
    final color = _getBrickColor();
    _shadowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    _mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 이동형 벽돌 로직
    if (isMoving) {
      position.x += moveSpeed * moveDirection * dt;

      if ((position.x - initialX).abs() > moveRange) {
        moveDirection *= -1;
        position.x = initialX + moveRange * moveDirection;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // 체력 변경 시 색상 업데이트
    final color = _getBrickColor();
    _shadowPaint.color = color.withOpacity(0.4);
    _mainPaint.color = color;

    final rect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(4),
    );

    canvas.drawRRect(rect, _shadowPaint);
    canvas.drawRRect(rect, _mainPaint);

    // 체력 및 특수 표시
    String? displayText;
    if (type == BrickType.bonus) {
      displayText = '\$';
    } else if (hitPoints > 1) {
      displayText = hitPoints.toString();
    }

    if (displayText != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayText,
          style: TextStyle(
            color: type == BrickType.bonus ? const Color(0xFF000000) : Colors.white,
            fontSize: type == BrickType.bonus ? 16 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          size.x / 2 - textPainter.width / 2,
          size.y / 2 - textPainter.height / 2,
        ),
      );
    }

    // 하이라이트 효과
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y / 3),
      const Radius.circular(4),
    );
    canvas.drawRRect(highlightRect, highlightPaint);
  }

  Color _getBrickColor() {
    switch (type) {
      case BrickType.normal:
        return GameConstants.brickNormalColor;
      case BrickType.hard:
        return GameConstants.brickHardColor;
      case BrickType.explosive:
        return GameConstants.brickExplosiveColor;
      case BrickType.moving:
        return GameConstants.brickMovingColor;
      case BrickType.bonus:
        return GameConstants.brickBonusColor;
    }
  }

  /// 데미지 받기
  void takeDamage() {
    if (isDestroying) return; // 이미 파괴 중이면 무시

    hitPoints--;

    if (hitPoints <= 0) {
      destroy();
    }
  }

  /// 벽돌 파괴
  void destroy() {
    if (isDestroying) return; // 이미 파괴 중이면 무시
    isDestroying = true; // 파괴 시작

    // 폭발형 벽돌인 경우 주변 벽돌도 파괴
    if (type == BrickType.explosive) {
      _explode();
      // 폭발 사운드 & 햅틱
      AudioService().playExplosion();
      HapticService().heavy();
    }

    // 파워업 드롭 (20% 확률)
    final random = Random();
    if (random.nextDouble() < 0.2) {
      game.spawnPowerUp(position + size / 2);
    }

    // 게임에서 제거
    game.removeBrick(this);
  }

  /// 폭발 효과 (주변 벽돌 파괴)
  void _explode() {
    final explosionRadius = 60.0;
    final center = position + size / 2;

    // 주변 벽돌 찾기
    final nearbyBricks = game.bricks.where((brick) {
      if (brick == this) return false;
      final brickCenter = brick.position + brick.size / 2;
      final distance = (brickCenter - center).length;
      return distance < explosionRadius;
    }).toList();

    // 주변 벽돌에 데미지
    for (final brick in nearbyBricks) {
      brick.takeDamage();
    }
  }
}
