// score_record.dart - 점수 기록 모델
class ScoreRecord {
  final int score;
  final int level;
  final DateTime dateTime;

  ScoreRecord({
    required this.score,
    required this.level,
    required this.dateTime,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  /// JSON에서 생성
  factory ScoreRecord.fromJson(Map<String, dynamic> json) {
    return ScoreRecord(
      score: json['score'] as int,
      level: json['level'] as int,
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }

  /// 날짜/시간을 이름으로 포맷
  String get displayName {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$year.$month.$day $hour:$minute';
  }
}
