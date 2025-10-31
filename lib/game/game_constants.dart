// game_constants.dart - 게임 상수 정의

import 'dart:ui';

/// 게임 전역 상수
class GameConstants {
  // 게임 화면 크기
  static const double gameWidth = 400.0;
  static const double gameHeight = 800.0;

  // 패들 설정
  static const double paddleWidth = 100.0;
  static const double paddleHeight = 15.0;
  static const double paddleSpeed = 500.0;
  static const double paddleY = 720.0;

  // 공 설정
  static const double ballRadius = 8.0;
  static const double ballInitialSpeed = 300.0;
  static const double ballMaxSpeed = 500.0;

  // 벽돌 설정
  static const double brickWidth = 45.0;
  static const double brickHeight = 20.0;
  static const double brickSpacing = 5.0;
  static const double brickOffsetY = 150.0;

  // 게임 설정
  static const int initialLives = 3;
  static const int maxLevel = 20;

  // 점수 설정
  static const int scorePerBrick = 10;
  static const int scoreBonusCombo = 5;
  static const int scoreBonusLevel = 100;

  // 색상 팔레트 (네온 스타일)
  static const Color backgroundColor = Color(0xFF1a1a2e);
  static const Color paddleColor = Color(0xFF00d4ff);
  static const Color ballColor = Color(0xFFff006e);

  // 벽돌 색상 (타입별)
  static const Color brickNormalColor = Color(0xFF06ffa5);
  static const Color brickHardColor = Color(0xFFffd700);
  static const Color brickExplosiveColor = Color(0xFFff4500);
  static const Color brickMovingColor = Color(0xFF9d4edd);
  static const Color brickBonusColor = Color(0xFFFFD700); // 진한 금색

  // UI 색상
  static const Color textColor = Color(0xFFffffff);
  static const Color textSecondaryColor = Color(0xFFb0b0b0);
}

/// 벽돌 타입
enum BrickType {
  normal,      // 일반 - 1타
  hard,        // 단단 - 3타
  explosive,   // 폭발 - 주변 파괴
  moving,      // 이동형
  bonus,       // 보너스 - 점수 3배
}

/// 파워업 타입
enum PowerUpType {
  multiball,   // 멀티볼
  largePaddle, // 큰 패들
  laser,       // 레이저
  slowBall,    // 느린 공
  magnet,      // 자석
}

/// 게임 상태
enum GameState {
  menu,
  playing,
  paused,
  gameOver,
  levelComplete,
}
