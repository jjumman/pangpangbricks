// haptic_service.dart - 햅틱 피드백 서비스
import 'package:flutter/services.dart';

/// 햅틱 피드백 서비스
class HapticService {
  // 싱글톤 패턴
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isEnabled = true;

  /// 햅틱 활성화/비활성화
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// 가벼운 진동 (패들 충돌)
  void light() {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// 중간 진동 (벽돌 파괴)
  void medium() {
    if (!_isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// 강한 진동 (폭발)
  void heavy() {
    if (!_isEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// 선택 피드백 (파워업 획득)
  void selection() {
    if (!_isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// 에러 진동 (라이프 감소)
  void error() {
    if (!_isEnabled) return;
    HapticFeedback.vibrate();
  }
}
