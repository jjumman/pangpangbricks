// save_service.dart - 게임 저장/로드 서비스
import 'package:shared_preferences/shared_preferences.dart';

class SaveService {
  static const String _keyHighScore = 'high_score';
  static const String _keyCurrentLevel = 'current_level';
  static const String _keyTotalGames = 'total_games';

  late SharedPreferences _prefs;

  // 싱글톤 패턴
  static final SaveService _instance = SaveService._internal();
  factory SaveService() => _instance;
  SaveService._internal();

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 최고 점수 저장
  Future<void> saveHighScore(int score) async {
    final currentHighScore = getHighScore();
    if (score > currentHighScore) {
      await _prefs.setInt(_keyHighScore, score);
    }
  }

  /// 최고 점수 불러오기
  int getHighScore() {
    return _prefs.getInt(_keyHighScore) ?? 0;
  }

  /// 현재 레벨 저장
  Future<void> saveCurrentLevel(int level) async {
    await _prefs.setInt(_keyCurrentLevel, level);
  }

  /// 현재 레벨 불러오기
  int getCurrentLevel() {
    return _prefs.getInt(_keyCurrentLevel) ?? 1;
  }

  /// 총 게임 횟수 증가
  Future<void> incrementTotalGames() async {
    final total = getTotalGames();
    await _prefs.setInt(_keyTotalGames, total + 1);
  }

  /// 총 게임 횟수 불러오기
  int getTotalGames() {
    return _prefs.getInt(_keyTotalGames) ?? 0;
  }

  /// 모든 데이터 초기화
  Future<void> resetAll() async {
    await _prefs.clear();
  }
}
