import 'enums.dart';

/// 单个答题记录（一次作答）
class AnswerRecord {
  /// 题目 ID
  final String questionId;

  /// 用户选择的答案 optionId
  final String userAnswer;

  /// 是否正确
  final bool isCorrect;

  /// 答题用时（毫秒）
  final int timeSpentMs;

  const AnswerRecord({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    this.timeSpentMs = 0,
  });

  factory AnswerRecord.fromJson(Map<String, dynamic> json) {
    return AnswerRecord(
      questionId: json['questionId'] as String,
      userAnswer: json['userAnswer'] as String,
      isCorrect: json['isCorrect'] as bool? ?? false,
      timeSpentMs: (json['timeSpentMs'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timeSpentMs': timeSpentMs,
    };
  }
}

/// 考试记录模型 - 一次练习或模拟考
///
/// 字段: id, userId, level, type (practice/exam), answers,
///       score, totalQuestions, correctCount, duration, completedAt
class ExamRecord {
  /// 记录 ID
  final String id;

  /// 用户 ID
  final String userId;

  /// 关联的等级
  final JLPTLevel level;

  /// 记录类型: practice / exam
  final ExamRecordType recordType;

  /// 题目 ID 列表（按顺序）
  final List<String> questionIds;

  /// 每题作答记录
  final List<AnswerRecord> answers;

  /// 得分
  final int score;

  /// 题目总数
  final int totalQuestions;

  /// 正确数
  final int correctCount;

  /// 总用时（毫秒）
  final int durationMs;

  /// 完成时间
  final DateTime completedAt;

  /// 关联的试卷/练习集 ID（可选）
  final String? setId;

  /// 备注
  final String? note;

  const ExamRecord({
    required this.id,
    required this.userId,
    required this.level,
    this.recordType = ExamRecordType.practice,
    required this.questionIds,
    this.answers = const [],
    this.score = 0,
    required this.totalQuestions,
    this.correctCount = 0,
    this.durationMs = 0,
    DateTime? completedAt,
    this.setId,
    this.note,
  }) : completedAt = completedAt ?? const _EpochDateTime();

  factory ExamRecord.fromJson(Map<String, dynamic> json) {
    return ExamRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      level: JLPTLevel.fromString(json['level'] as String?),
      recordType: ExamRecordType.fromString(json['recordType'] as String?),
      questionIds:
          (json['questionIds'] as List?)?.cast<String>() ?? const [],
      answers: ((json['answers'] as List?) ?? const [])
          .map((a) => AnswerRecord.fromJson(a as Map<String, dynamic>))
          .toList(),
      score: (json['score'] as int?) ?? 0,
      totalQuestions: (json['totalQuestions'] as int?) ?? 0,
      correctCount: (json['correctCount'] as int?) ?? 0,
      durationMs: (json['durationMs'] as int?) ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
      setId: json['setId'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'level': level.name,
      'recordType': recordType.name,
      'questionIds': questionIds,
      'answers': answers.map((a) => a.toJson()).toList(),
      'score': score,
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'durationMs': durationMs,
      'completedAt': completedAt.toIso8601String(),
      'setId': setId,
      'note': note,
    };
  }

  /// 正确率（0.0 - 1.0）
  double get accuracy =>
      totalQuestions == 0 ? 0.0 : correctCount / totalQuestions;

  ExamRecord copyWith({
    String? id,
    String? userId,
    JLPTLevel? level,
    ExamRecordType? recordType,
    List<String>? questionIds,
    List<AnswerRecord>? answers,
    int? score,
    int? totalQuestions,
    int? correctCount,
    int? durationMs,
    DateTime? completedAt,
    String? setId,
    String? note,
  }) {
    return ExamRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      level: level ?? this.level,
      recordType: recordType ?? this.recordType,
      questionIds: questionIds ?? this.questionIds,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      durationMs: durationMs ?? this.durationMs,
      completedAt: completedAt ?? this.completedAt,
      setId: setId ?? this.setId,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExamRecord && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 考试记录类型
enum ExamRecordType {
  /// 练习
  practice,

  /// 模拟考试
  exam,

  /// 复习
  review;

  String get displayName {
    switch (this) {
      case ExamRecordType.practice:
        return '练习';
      case ExamRecordType.exam:
        return '模拟考试';
      case ExamRecordType.review:
        return '复习';
    }
  }

  static ExamRecordType fromString(String? value) {
    if (value == null) return ExamRecordType.practice;
    return ExamRecordType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExamRecordType.practice,
    );
  }
}

class _EpochDateTime implements DateTime {
  const _EpochDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
