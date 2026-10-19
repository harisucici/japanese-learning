/// 复习 Repository
library;

import '../../core/storage/local_storage_service.dart';
import '../../shared/models/models.dart';
import 'package:uuid/uuid.dart';

/// 复习项 Repository - 错题本 / 收藏 / 间隔复习管理
class ReviewRepository {
  final LocalStorageService _storage;
  static const _uuid = Uuid();

  ReviewRepository(this._storage);

  /// 获取用户所有复习项
  Future<List<ReviewItem>> getReviewItems(String userId) async {
    final items = await _storage.getReviewItemsByUser(userId);
    return items.map((j) => ReviewItem.fromJson(j)).toList();
  }

  /// 获取到期要复习的题目
  Future<List<ReviewItem>> getDueItems(String userId) async {
    final items = await _storage.getDueReviewItems(userId);
    return items.map((j) => ReviewItem.fromJson(j)).toList();
  }

  /// 添加题目到复习列表
  Future<ReviewItem> addReviewItem({
    required String userId,
    required String questionId,
    required JLPTLevel level,
    required QuestionType type,
    bool isWrong = false,
    bool isFavorite = false,
  }) async {
    final existing = await _storage.getReviewItemByQuestion(userId, questionId);
    if (existing != null) {
      final item = ReviewItem.fromJson(existing);
      final updated = item.copyWith(
        isFavorite: isFavorite || item.isFavorite,
        isWrongAnswer: isWrong || item.isWrongAnswer,
        wrongCount: isWrong ? item.wrongCount + 1 : item.wrongCount,
      );
      await _storage.saveReviewItem(updated.toJson());
      return updated;
    }
    final item = ReviewItem(
      id: _uuid.v4(),
      userId: userId,
      questionId: questionId,
      level: level,
      type: type,
      isWrongAnswer: isWrong,
      wrongCount: isWrong ? 1 : 0,
      isFavorite: isFavorite,
    );
    await _storage.saveReviewItem(item.toJson());
    return item;
  }

  /// 复习后更新状态（简化 SM-2 算法）
  Future<ReviewItem> markReviewed({
    required String itemId,
    required bool correct,
  }) async {
    final items = await _storage.getAll('review_items');
    final target = items.firstWhere((i) => i['id'] == itemId);
    final item = ReviewItem.fromJson(target);

    int newInterval;
    double newEase;
    int newStreak;
    int newWrong;
    ReviewStatus newStatus;

    if (correct) {
      newStreak = item.correctStreak + 1;
      newWrong = item.wrongCount;
      if (item.reviewCount == 0) {
        newInterval = 1;
      } else if (item.reviewCount == 1) {
        newInterval = 3;
      } else {
        newInterval = (item.intervalDays * item.easeFactor).round();
      }
      newEase = (item.easeFactor + 0.1).clamp(1.3, 2.5);
      newStatus = newInterval >= 21
          ? ReviewStatus.mastered
          : ReviewStatus.reviewing;
    } else {
      newStreak = 0;
      newWrong = item.wrongCount + 1;
      newInterval = 1;
      newEase = (item.easeFactor - 0.2).clamp(1.3, 2.5);
      newStatus = ReviewStatus.learning;
    }

    final updated = item.copyWith(
      reviewCount: item.reviewCount + 1,
      intervalDays: newInterval,
      easeFactor: newEase,
      correctStreak: newStreak,
      wrongCount: newWrong,
      lastReviewedAt: DateTime.now(),
      nextReviewAt: DateTime.now().add(Duration(days: newInterval)),
      status: newStatus,
    );
    await _storage.saveReviewItem(updated.toJson());
    return updated;
  }

  /// 切换收藏状态
  Future<ReviewItem> toggleFavorite(String itemId) async {
    final items = await _storage.getAll('review_items');
    final target = items.firstWhere((i) => i['id'] == itemId);
    final item = ReviewItem.fromJson(target);
    final updated = item.copyWith(isFavorite: !item.isFavorite);
    await _storage.saveReviewItem(updated.toJson());
    return updated;
  }

  /// 移除复习项
  Future<void> removeReviewItem(String itemId) async {
    await _storage.delete('review_items', itemId);
  }
}
