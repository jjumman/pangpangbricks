// paddle.dart - 패들 컴포넌트
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';

/// 패들 컴포넌트
class Paddle extends RectangleComponent with CollisionCallbacks {
  // Paint 객체 캐싱 (성능 최적화)
  late final Paint _shadowPaint;
  late final Paint _mainPaint;
  late final Paint _highlightPaint;

  Paddle()
      : super(
          position: Vector2(
            GameConstants.gameWidth / 2 - GameConstants.paddleWidth / 2,
            GameConstants.paddleY,
          ),
          size: Vector2(GameConstants.paddleWidth, GameConstants.paddleHeight),
          anchor: Anchor.topLeft,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 충돌 감지 추가
    add(RectangleHitbox());

    // Paint 객체 초기화 (재사용)
    _shadowPaint = Paint()
      ..color = GameConstants.paddleColor.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    _mainPaint = Paint()
      ..color = GameConstants.paddleColor
      ..style = PaintingStyle.fill;

    _highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(8),
    );

    canvas.drawRRect(rect, _shadowPaint);
    canvas.drawRRect(rect, _mainPaint);

    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y / 3),
      const Radius.circular(8),
    );
    canvas.drawRRect(highlightRect, _highlightPaint);
  }

  /// 패들 이동
  void move(double delta) {
    position.x += delta;

    // 화면 경계 제한
    if (position.x < 10) {
      position.x = 10;
    } else if (position.x + size.x > GameConstants.gameWidth - 10) {
      position.x = GameConstants.gameWidth - 10 - size.x;
    }
  }

  /// 패들 크기 변경 (파워업용)
  void setSize(double width) {
    size.x = width;
  }

  /// 기본 크기로 복원
  void resetSize() {
    size.x = GameConstants.paddleWidth;
  }
}
