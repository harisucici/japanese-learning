import 'enums.dart';

/// 复习项模型 - 错题本 / 收藏 / 间隔复习
///
/// 字段: id, userId, questionId, level, status, reviewCount,
///       nextReviewAt, lastReviewedAt, easeFactor, interval,
///       isFavorite, isWrongAnswer, wrongCount
class ReviewItem {
  /// 复习项 ID
  final String id;

  /// 用户 ID
  final String userId;

  /// 关联的题目 ID
  final String questionId;

  /// 题目等级（冗余存储，便于查询）
  final JLPTLevel level;

  /// 题目类型（冗余存储）
  final QuestionType type;

  /// 复习状态
  final ReviewStatus status;

  /// 复习次数
  final int reviewCount;

  /// 下次复习时间（间隔复习算法）
  final DateTime? nextReviewAt;

  /// 上次复习时间
  final DateTime? lastReviewedAt;

  /// 创建时间（首次加入复习）
  final DateTime createdAt;

  /// 难度系数（SM-2 算法）
  final double easeFactor;

  /// 间隔天数
  final int intervalDays;

  /// 是否收藏
  final bool isFavorite;

  /// 是否答错过
  final bool isWrongAnswer;

  /// 答错次数
  final int wrongCount;

  /// 连续答对次数
  final int correctStreak;

  /// 用户笔记
  final String? userNote;

  const ReviewItem({
    required this.id,
    required this.userId,
    required this.questionId,
    this.level = JLPTLevel.n5,
    this.type = QuestionType.vocabulary,
    this.status = ReviewStatus.new_,
    this.reviewCount = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
    DateTime? createdAt,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.isFavorite = false,
    this.isWrongAnswer = false,
    this.wrongCount = 0,
    this.correctStreak = 0,
    this.userNote,
  }) : createdAt = createdAt ?? const _EpochDateTime();

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      questionId: json['questionId'] as String,
      level: JLPTLevel.fromString(json['level'] as String?),
      type: QuestionType.fromString(json['type'] as String?),
      status: ReviewStatus.fromString(json['status'] as String?),
      reviewCount: (json['reviewCount'] as int?) ?? 0,
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.parse(json['nextReviewAt'] as String)
          : null,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (json['intervalDays'] as int?) ?? 0,
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      isWrongAnswer: (json['isWrongAnswer'] as bool?) ?? false,
      wrongCount: (json['wrongCount'] as int?) ?? 0,
      correctStreak: (json['correctStreak'] as int?) ?? 0,
      userNote: json['userNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'questionId': questionId,
      'level': level.name,
      'type': type.name,
      'status': status.name,
      'reviewCount': reviewCount,
      'nextReviewAt': nextReviewAt?.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'isFavorite': isFavorite,
      'isWrongAnswer': isWrongAnswer,
      'wrongCount': wrongCount,
      'correctStreak': correctStreak,
      'userNote': userNote,
    };
  }

  /// 是否到了复习时间
  bool get isDue {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  ReviewItem copyWith({
    String? id,
    String? userId,
    String? questionId,
    JLPTLevel? level,
    QuestionType? type,
    ReviewStatus? status,
    int? reviewCount,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    DateTime? createdAt,
    double? easeFactor,
    int? intervalDays,
    bool? isFavorite,
    bool? isWrongAnswer,
    int? wrongCount,
    int? correctStreak,
    String? userNote,
  }) {
    return ReviewItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      level: level ?? this.level,
      type: type ?? this.type,
      status: status ?? this.status,
      reviewCount: reviewCount ?? this.reviewCount,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      isFavorite: isFavorite ?? this.isFavorite,
      isWrongAnswer: isWrongAnswer ?? this.isWrongAnswer,
      wrongCount: wrongCount ?? this.wrongCount,
      correctStreak: correctStreak ?? this.correctStreak,
      userNote: userNote ?? this.userNote,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ReviewItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _EpochDateTime implements DateTime {
  const _EpochDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
