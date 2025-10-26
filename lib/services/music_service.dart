// music_service.dart - 배경음악 서비스
import 'package:flame_audio/flame_audio.dart';

class MusicService {
  // 싱글톤 패턴
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  bool _isEnabled = true;
  bool _isPlaying = false;

  /// 초기화
  Future<void> initialize() async {
    try {
      await FlameAudio.audioCache.load('game_music.wav');
    } catch (e) {
      print('Failed to load music: $e');
    }
  }

  /// 배경음악 활성화/비활성화
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stopMusic();
    }
  }

  /// 게임 배경음악 재생
  Future<void> playGameMusic() async {
    if (!_isEnabled || _isPlaying) return;
    try {
      _isPlaying = true;
      await FlameAudio.bgm.play('game_music.wav', volume: 0.3);
    } catch (e) {
      print('Failed to play music: $e');
      _isPlaying = false;
    }
  }

  /// 메뉴 배경음악 재생
  Future<void> playMenuMusic() async {
    if (!_isEnabled || _isPlaying) return;
    try {
      _isPlaying = true;
      await FlameAudio.bgm.play('game_music.wav', volume: 0.3);
    } catch (e) {
      print('Failed to play music: $e');
      _isPlaying = false;
    }
  }

  /// 배경음악 정지
  void stopMusic() {
    _isPlaying = false;
    FlameAudio.bgm.stop();
  }

  /// 배경음악 일시정지
  void pauseMusic() {
    FlameAudio.bgm.pause();
  }

  /// 배경음악 재개
  void resumeMusic() {
    if (_isEnabled && _isPlaying) {
      FlameAudio.bgm.resume();
    }
  }
}
