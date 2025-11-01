// powerup.dart - 파워업 베이스 클래스
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../breakout_game.dart';
import '../components/paddle.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';

/// 파워업 베이스 클래스
abstract class PowerUp extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BreakoutGame> {
  final PowerUpType type;
  final Vector2 velocity = Vector2(0, 100); // 아래로 떨어지는 속도

  PowerUp({
    required Vector2 position,
    required this.type,
  }) : super(
          position: position,
          size: Vector2(30, 30),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 아래로 떨어짐
    position += velocity * dt;

    // 화면 밖으로 나가면 제거 (동적 화면 크기 사용)
    if (position.y > game.gameHeight + 50) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Paddle) {
      // 사운드 & 햅틱 피드백
      AudioService().playPowerUp();
      HapticService().selection();

      activate();
      removeFromParent();
    }
  }

  /// 파워업 활성화 (서브클래스에서 구현)
  void activate();

  /// 파워업 색상 (서브클래스에서 구현)
  Color getColor();

  @override
  void render(Canvas canvas) {
    final color = getColor();

    // 네온 효과
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final rect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(6),
    );

    canvas.drawRRect(rect, shadowPaint);

    // 메인 파워업
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, mainPaint);

    // 아이콘 (간단한 텍스트)
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getIcon(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
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

  String _getIcon() {
    switch (type) {
      case PowerUpType.multiball:
        return 'M';
      case PowerUpType.largePaddle:
        return 'L';
      case PowerUpType.laser:
        return 'Z';
      case PowerUpType.slowBall:
        return 'S';
      case PowerUpType.magnet:
        return 'G';
    }
  }
}
