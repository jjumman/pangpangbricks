// breakout_game.dart - 메인 게임 엔진
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game_constants.dart';
import 'components/paddle.dart';
import 'components/ball.dart';
import 'components/brick.dart';
import 'powerups/powerup.dart';
import 'powerups/multiball_powerup.dart';
import 'powerups/large_paddle_powerup.dart';
import 'powerups/slow_ball_powerup.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/score_service.dart';
import '../services/music_service.dart';

/// PangPang Bricks 메인 게임 클래스
class BreakoutGame extends FlameGame
    with HasCollisionDetection, DragCallbacks, TapCallbacks {
  // 게임 상태
  GameState gameState = GameState.menu;
  int currentLevel = 1;
  int score = 0;
  int lives = GameConstants.initialLives;
  int combo = 0;

  // 게임 컴포넌트
  late Paddle paddle;
  final List<Ball> balls = [];
  final List<Brick> bricks = [];

  // 화면 경계
  late RectangleComponent topWall;
  late RectangleComponent leftWall;
  late RectangleComponent rightWall;

  @override
  Color backgroundColor() => GameConstants.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 게임 화면 크기 고정
    camera.viewfinder.visibleGameSize = Vector2(
      GameConstants.gameWidth,
      GameConstants.gameHeight,
    );

    // 화면 경계 생성
    _createWalls();

    // 패들 생성
    paddle = Paddle();
    await add(paddle);

    // 초기 공 생성
    final ball = Ball(
      position: Vector2(
        GameConstants.gameWidth / 2,
        GameConstants.paddleY - 30,
      ),
    );
    balls.add(ball);
    await add(ball);
  }

  /// 화면 경계 생성
  void _createWalls() {
    // 상단 벽
    topWall = RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(GameConstants.gameWidth, 10),
      paint: Paint()..color = Colors.transparent,
    );
    add(topWall);

    // 좌측 벽
    leftWall = RectangleComponent(
      position: Vector2(0, 0),
      size: Vector2(10, GameConstants.gameHeight),
      paint: Paint()..color = Colors.transparent,
    );
    add(leftWall);

    // 우측 벽
    rightWall = RectangleComponent(
      position: Vector2(GameConstants.gameWidth - 10, 0),
      size: Vector2(10, GameConstants.gameHeight),
      paint: Paint()..color = Colors.transparent,
    );
    add(rightWall);
  }

  /// 레벨 로드
  Future<void> loadLevel(int level) async {
    // 기존 벽돌 제거
    for (final brick in bricks) {
      brick.removeFromParent();
    }
    bricks.clear();

    // 레벨에 따른 벽돌 생성 (간단한 패턴)
    final rows = 5 + (level ~/ 2).clamp(0, 5);
    final cols = 7;
    final random = Random();

    // 보너스 벽돌 위치를 미리 선정 (레벨 2부터 2-3개)
    final Set<String> bonusPositions = {};
    if (level >= 2) {
      final bonusCount = 2 + (level >= 5 ? 1 : 0); // 레벨 5부터 3개
      while (bonusPositions.length < bonusCount) {
        final randomRow = random.nextInt(rows);
        final randomCol = random.nextInt(cols);
        // 첫 줄(hard 브릭)과 너무 가까운 위치는 피하기
        if (randomRow > 0 || level < 3) {
          bonusPositions.add('$randomRow,$randomCol');
        }
      }
    }

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // 레벨에 따라 다양한 벽돌 타입 배치
        BrickType type = BrickType.normal;

        // 보너스 벽돌인지 먼저 체크
        if (bonusPositions.contains('$row,$col')) {
          type = BrickType.bonus;
        } else if (level >= 3 && row == 0) {
          type = BrickType.hard;
        } else if (level >= 5 && col % 3 == 0) {
          type = BrickType.hard; // 폭발형 대신 hard 브릭 사용
        } else if (level >= 7 && row % 2 == 1 && col % 2 == 0) {
          type = BrickType.moving;
        } else if (level >= 4 && row == 1) {
          type = BrickType.hard; // 추가 hard 브릭
        }

        final brick = Brick(
          gridX: col,
          gridY: row,
          type: type,
        );
        bricks.add(brick);
        await add(brick);
      }
    }

    currentLevel = level;
  }

  /// 공 추가 (멀티볼 파워업용)
  Future<void> addBall(Vector2 position, Vector2 velocity) async {
    final ball = Ball(position: position.clone());
    ball.velocity = velocity.clone();
    balls.add(ball);
    await add(ball);
  }

  /// 공 제거 (화면 밖으로 나갔을 때)
  void removeBall(Ball ball) {
    balls.remove(ball);
    ball.removeFromParent();

    // 모든 공이 사라지면 라이프 감소
    if (balls.isEmpty) {
      loseLife();
    }
  }

  /// 벽돌 제거
  void removeBrick(Brick brick) {
    bricks.remove(brick);
    brick.removeFromParent();

    // 점수 추가
    combo++;
    int baseScore = GameConstants.scorePerBrick + (combo * GameConstants.scoreBonusCombo);

    // 보너스 벽돌이면 점수 3배!
    if (brick.type == BrickType.bonus) {
      baseScore *= 3;
    }

    score += baseScore;

    // 레벨 클리어 체크
    if (bricks.isEmpty) {
      onLevelComplete();
    }
  }

  /// 라이프 감소
  void loseLife() {
    lives--;
    combo = 0;

    // 라이프 감소 사운드 & 햅틱
    AudioService().playLifeLost();
    HapticService().error();

    if (lives <= 0) {
      gameState = GameState.gameOver;
      // 게임 오버 사운드
      AudioService().playGameOver();
      // 점수 저장
      ScoreService().saveScore(score, currentLevel);
      // 배경음악 정지
      MusicService().stopMusic();
    } else {
      // 새 공 생성
      resetBall();
    }
  }

  /// 공 리셋
  void resetBall() {
    final ball = Ball(
      position: Vector2(
        GameConstants.gameWidth / 2,
        GameConstants.paddleY - 30,
      ),
    );
    balls.add(ball);
    add(ball);
  }

  /// 레벨 완료
  void onLevelComplete() {
    gameState = GameState.levelComplete;
    score += GameConstants.scoreBonusLevel * currentLevel;
    combo = 0;

    // 레벨 클리어 사운드 & 햅틱
    AudioService().playLevelComplete();
    HapticService().heavy();
  }

  /// 다음 레벨로 이동
  Future<void> nextLevel() async {
    if (currentLevel < GameConstants.maxLevel) {
      await loadLevel(currentLevel + 1);
      resetBall();
      gameState = GameState.playing;
    } else {
      // 게임 클리어
      gameState = GameState.gameOver;
    }
  }

  /// 게임 재시작
  Future<void> restartGame() async {
    score = 0;
    lives = GameConstants.initialLives;
    combo = 0;
    currentLevel = 1;

    // 모든 공 제거
    for (final ball in [...balls]) {
      ball.removeFromParent();
    }
    balls.clear();

    await loadLevel(1);
    resetBall();
    gameState = GameState.playing;

    // 배경음악 재생
    MusicService().playGameMusic();
  }

  /// 게임 시작
  Future<void> startGame() async {
    await restartGame();
  }

  /// 파워업 생성
  Future<void> spawnPowerUp(Vector2 position) async {
    final random = Random();

    // 공이 13개를 넘으면 멀티볼 파워업 제외 (성능 최적화)
    final powerUpTypes = balls.length > 13
        ? [
            PowerUpType.largePaddle,
            PowerUpType.slowBall,
          ]
        : [
            PowerUpType.multiball,
            PowerUpType.largePaddle,
            PowerUpType.slowBall,
          ];

    final type = powerUpTypes[random.nextInt(powerUpTypes.length)];
    PowerUp powerUp;

    switch (type) {
      case PowerUpType.multiball:
        powerUp = MultiballPowerUp(position: position);
        break;
      case PowerUpType.largePaddle:
        powerUp = LargePaddlePowerUp(position: position);
        break;
      case PowerUpType.slowBall:
        powerUp = SlowBallPowerUp(position: position);
        break;
      default:
        return;
    }

    await add(powerUp);
  }

  // 터치 이벤트 처리
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (gameState == GameState.playing) {
      paddle.move(event.localDelta.x);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == GameState.menu) {
      startGame();
    } else if (gameState == GameState.playing) {
      // 공 발사
      for (final ball in balls) {
        if (!ball.isLaunched) {
          ball.launch();
        }
      }
    } else if (gameState == GameState.levelComplete) {
      nextLevel();
    } else if (gameState == GameState.gameOver) {
      restartGame();
    }
  }
}
