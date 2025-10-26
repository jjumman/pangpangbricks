// beep_music_service.dart - 비프음 기반 배경음악 서비스
import 'dart:async';
import 'package:flutter/services.dart';

/// 8비트 스타일 비프음 배경음악 서비스
class BeepMusicService {
  // 싱글톤 패턴
  static final BeepMusicService _instance = BeepMusicService._internal();
  factory BeepMusicService() => _instance;
  BeepMusicService._internal();

  Timer? _musicTimer;
  bool _isEnabled = true;
  bool _isPlaying = false;
  int _beatIndex = 0;

  // 8비트 게임 느낌의 리듬 패턴 (밀리초 단위)
  // 빠른 템포로 반복되는 패턴
  final List<int> _gamePattern = [
    200, // 빠른 비프
    200,
    200,
    400, // 긴 비프
    200,
    200,
    400,
    600, // 쉼표
  ];

  /// 배경음악 활성화/비활성화
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled && _isPlaying) {
      stopMusic();
    }
  }

  /// 게임 배경음악 재생
  void playGameMusic() {
    if (!_isEnabled || _isPlaying) return;

    _isPlaying = true;
    _beatIndex = 0;
    _playNextBeat();
  }

  /// 다음 비트 재생
  void _playNextBeat() {
    if (!_isPlaying || !_isEnabled) return;

    final delay = _gamePattern[_beatIndex];

    // 쉼표가 아니면 비프음 재생
    if (delay < 500) {
      SystemSound.play(SystemSoundType.click);
    }

    // 다음 비트로 이동
    _beatIndex = (_beatIndex + 1) % _gamePattern.length;

    // 다음 비트 스케줄
    _musicTimer = Timer(Duration(milliseconds: delay), _playNextBeat);
  }

  /// 배경음악 정지
  void stopMusic() {
    _isPlaying = false;
    _musicTimer?.cancel();
    _musicTimer = null;
    _beatIndex = 0;
  }

  /// 배경음악 일시정지
  void pauseMusic() {
    if (_isPlaying) {
      _musicTimer?.cancel();
      _musicTimer = null;
    }
  }

  /// 배경음악 재개
  void resumeMusic() {
    if (_isPlaying && _musicTimer == null) {
      _playNextBeat();
    }
  }
}
