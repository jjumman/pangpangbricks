// score_service.dart - 점수 기록 서비스
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/score_record.dart';

class ScoreService {
  static const String _keyScores = 'score_records';
  static const int _maxRecords = 100; // 최대 100개 기록 유지

  late SharedPreferences _prefs;

  // 싱글톤 패턴
  static final ScoreService _instance = ScoreService._internal();
  factory ScoreService() => _instance;
  ScoreService._internal();

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 새로운 점수 저장
  Future<void> saveScore(int score, int level) async {
    final records = await getScores();

    // 새로운 기록 추가
    records.add(ScoreRecord(
      score: score,
      level: level,
      dateTime: DateTime.now(),
    ));

    // 점수 순으로 정렬 (높은 점수가 먼저)
    records.sort((a, b) => b.score.compareTo(a.score));

    // 최대 개수만 유지
    if (records.length > _maxRecords) {
      records.removeRange(_maxRecords, records.length);
    }

    // 저장
    final jsonList = records.map((r) => r.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_keyScores, jsonString);
  }

  /// 모든 점수 기록 불러오기
  Future<List<ScoreRecord>> getScores() async {
    final jsonString = _prefs.getString(_keyScores);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => ScoreRecord.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 상위 N개 점수 가져오기
  Future<List<ScoreRecord>> getTopScores(int count) async {
    final records = await getScores();
    if (records.length <= count) return records;
    return records.sublist(0, count);
  }

  /// 특정 점수의 순위 계산 (1위부터 시작)
  Future<int> getRank(int score) async {
    final records = await getScores();
    int rank = 1;

    for (final record in records) {
      if (record.score > score) {
        rank++;
      } else {
        break;
      }
    }

    return rank;
  }

  /// 최고 점수 가져오기
  Future<int> getHighScore() async {
    final records = await getScores();
    if (records.isEmpty) return 0;
    return records.first.score;
  }

  /// 모든 기록 삭제
  Future<void> clearAllScores() async {
    await _prefs.remove(_keyScores);
  }
}
