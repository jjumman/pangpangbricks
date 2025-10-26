// audio_service.dart - 오디오 서비스
import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';

/// 오디오 서비스 (효과음 전용 - AudioPool 사용)
class AudioService {
  // 싱글톤 패턴
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _isEnabled = true;
  bool _isInitialized = false;

  // AudioPool로 성능 최적화 (동시 재생 가능)
  late AudioPool _brickHitPool;
  late AudioPool _paddleHitPool;
  late AudioPool _explosionPool;
  late AudioPool _powerupPool;

  AudioPlayer? _lifeLostPlayer;
  AudioPlayer? _gameOverPlayer;
  AudioPlayer? _levelCompletePlayer;

  // Throttle을 위한 마지막 재생 시간 기록 (밀리초)
  int _lastBrickHitTime = 0;
  int _lastPaddleHitTime = 0;
  int _lastExplosionTime = 0;
  int _lastPowerupTime = 0;

  // Throttle 간격 (밀리초) - AudioPool이 꽉 차지 않도록
  static const int _throttleMs = 30;

  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // AudioPool 생성 (자주 재생되는 효과음 - 멀티볼 대응)
      _brickHitPool = await FlameAudio.createPool(
        'brick_hit.wav',
        minPlayers: 12,
        maxPlayers: 16,
      );

      _paddleHitPool = await FlameAudio.createPool(
        'paddle_hit.wav',
        minPlayers: 12,
        maxPlayers: 16,
      );

      _explosionPool = await FlameAudio.createPool(
        'explosion.wav',
        minPlayers: 12,
        maxPlayers: 16,
      );

      _powerupPool = await FlameAudio.createPool(
        'powerup.wav',
        minPlayers: 12,
        maxPlayers: 16,
      );

      // 단일 재생 효과음 (드물게 재생)
      await FlameAudio.audioCache.loadAll([
        'life_lost.wav',
        'game_over.wav',
        'level_complete.wav',
      ]);

      _isInitialized = true;
      print('AudioService initialized with AudioPools');
    } catch (e) {
      print('Failed to initialize AudioService: $e');
    }
  }

  /// 사운드 활성화/비활성화
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// 패들 충돌 사운드
  void playPaddleHit() {
    if (!_isEnabled || !_isInitialized) return;

    // Throttle 체크
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPaddleHitTime < _throttleMs) return;

    _lastPaddleHitTime = now;
    _paddleHitPool.start(volume: 0.4);
  }

  /// 벽돌 파괴 사운드
  void playBrickBreak() {
    if (!_isEnabled || !_isInitialized) return;

    // Throttle 체크
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastBrickHitTime < _throttleMs) return;

    _lastBrickHitTime = now;
    _brickHitPool.start(volume: 0.5);
  }

  /// 폭발 사운드
  void playExplosion() {
    if (!_isEnabled || !_isInitialized) return;

    // Throttle 체크
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastExplosionTime < _throttleMs) return;

    _lastExplosionTime = now;
    _explosionPool.start(volume: 0.6);
  }

  /// 파워업 획득 사운드
  void playPowerUp() {
    if (!_isEnabled || !_isInitialized) return;

    // Throttle 체크
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPowerupTime < _throttleMs) return;

    _lastPowerupTime = now;
    _powerupPool.start(volume: 0.5);
  }

  /// 레벨 클리어 사운드
  void playLevelComplete() {
    if (!_isEnabled || !_isInitialized) return;
    FlameAudio.play('level_complete.wav', volume: 0.6);
  }

  /// 게임 오버 사운드
  void playGameOver() {
    if (!_isEnabled || !_isInitialized) return;
    FlameAudio.play('game_over.wav', volume: 0.6);
  }

  /// 라이프 감소 사운드
  void playLifeLost() {
    if (!_isEnabled || !_isInitialized) return;
    FlameAudio.play('life_lost.wav', volume: 0.5);
  }

  /// 리소스 정리
  void dispose() {
    _lifeLostPlayer?.dispose();
    _gameOverPlayer?.dispose();
    _levelCompletePlayer?.dispose();
  }
}
