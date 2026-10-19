/// 统计 Repository
library;

import '../../shared/models/models.dart';
import '../app_state.dart';

/// 统计 Repository - 计算学习统计数据
class StatisticsRepository {
  /// 计算学习统计
  Future<LearningStatistics> calculateStatistics({
    required List<ExamRecord> records,
    required List<ReviewItem> reviewItems,
    required List<ReviewItem> dueItems,
  }) async {
    int totalAnswers = 0;
    int totalCorrect = 0;
    int totalDurationMs = 0;
    final Set<String> activeDates = {};
    final Map<JLPTLevel, int> levelCorrect = {};
    final Map<JLPTLevel, int> levelTotal = {};
    final Map<QuestionType, int> typeCorrect = {};
    final Map<QuestionType, int> typeTotal = {};

    for (final record in records) {
      totalAnswers += record.answers.length;
      totalCorrect += record.correctCount;
      totalDurationMs += record.durationMs;
      activeDates.add(_dateKey(record.completedAt));

      levelTotal[record.level] =
          (levelTotal[record.level] ?? 0) + record.totalQuestions;
      levelCorrect[record.level] =
          (levelCorrect[record.level] ?? 0) + record.correctCount;
    }

    for (final item in reviewItems) {
      typeTotal[item.type] = (typeTotal[item.type] ?? 0) + 1;
      if (item.status == ReviewStatus.mastered) {
        typeCorrect[item.type] = (typeCorrect[item.type] ?? 0) + 1;
      }
    }

    final streakDays = _calculateStreak(activeDates);

    final wrongAnswerCount =
        reviewItems.where((i) => i.isWrongAnswer).length;
    final favoriteCount =
        reviewItems.where((i) => i.isFavorite).length;

    final typeMasteredCount = <QuestionType, int>{};
    for (final item in reviewItems) {
      if (item.status == ReviewStatus.mastered) {
        typeMasteredCount[item.type] =
            (typeMasteredCount[item.type] ?? 0) + 1;
      }
    }

    final levelProgress = JLPTLevel.values.map((level) {
      return LevelProgress(
        level: level,
        totalQuestions: levelTotal[level] ?? 0,
        correctCount: levelCorrect[level] ?? 0,
        totalAttempts: levelTotal[level] ?? 0,
      );
    }).toList();

    final typeMastery = QuestionType.values.map((type) {
      return TypeMastery(
        type: type,
        totalQuestions: typeTotal[type] ?? 0,
        correctCount: typeCorrect[type] ?? 0,
        masteredCount: typeMasteredCount[type] ?? 0,
      );
    }).toList();

    return LearningStatistics(
      totalAnswers: totalAnswers,
      totalCorrect: totalCorrect,
      totalSessions: records.length,
      totalReviews: reviewItems.fold<int>(
          0, (sum, i) => sum + i.reviewCount),
      streakDays: streakDays,
      totalDurationMs: totalDurationMs,
      wrongAnswerCount: wrongAnswerCount,
      dueReviewCount: dueItems.length,
      favoriteCount: favoriteCount,
      levelProgress: levelProgress,
      typeMastery: typeMastery,
    );
  }

  String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  int _calculateStreak(Set<String> activeDates) {
    if (activeDates.isEmpty) return 0;
    final today = _dateKey(DateTime.now());
    final yesterday = _dateKey(
        DateTime.now().subtract(const Duration(days: 1)));
    if (!activeDates.contains(today) && !activeDates.contains(yesterday)) {
      return 0;
    }
    int streak = 0;
    DateTime cursor = DateTime.now();
    while (activeDates.contains(_dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
      if (streak > 1000) break;
    }
    return streak;
  }
}
