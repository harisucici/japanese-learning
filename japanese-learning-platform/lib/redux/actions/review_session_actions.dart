/// 复习会话 Actions
library;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../app_state.dart';
import '../../shared/models/models.dart';
import '../repositories/review_repository.dart';
import '../repositories/question_repository.dart';

// ========== Action Types ==========

class ReviewSessionStarted {
  final ReviewSession session;
  ReviewSessionStarted(this.session);
}

class ReviewSessionAnswered {
  final String questionId;
  final bool isCorrect;
  final int nextIndex;
  ReviewSessionAnswered(this.questionId, this.isCorrect, this.nextIndex);
}

class ReviewSessionEnded {
  ReviewSessionEnded();
}

// ========== Thunk Actions ==========

ThunkAction<AppState> startReviewSession({
  required List<ReviewItem> items,
  required ReviewMode mode,
}) {
  return (Store<AppState> store) async {
    final session = ReviewSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: items,
      mode: mode,
    );
    store.dispatch(ReviewSessionStarted(session));
  };
}

ThunkAction<AppState> submitReviewAnswer({
  required String questionId,
  required bool isCorrect,
}) {
  return (Store<AppState> store) async {
    final session = store.state.reviewSession.session;
    if (session == null) return;

    final updatedResults = Map<String, bool>.from(session.results);
    updatedResults[questionId] = isCorrect;

    // 更新复习项状态（SM-2）
    try {
      final item = session.items.firstWhere((i) => i.questionId == questionId);
      final repo = ReviewRepository(store.state.localStorageService);
      await repo.markReviewed(itemId: item.id, correct: isCorrect);
    } catch (_) {}

    store.dispatch(ReviewSessionAnswered(
      questionId,
      isCorrect,
      session.currentIndex + 1,
    ));
  };
}

ThunkAction<AppState> endReviewSession() {
  return (Store<AppState> store) async {
    store.dispatch(ReviewSessionEnded());
  };
}
