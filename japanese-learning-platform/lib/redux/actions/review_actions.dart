/// 复习 Actions - 引用 review_repository
library;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../app_state.dart';
import '../../shared/models/models.dart';
import '../repositories/review_repository.dart';

// ========== Action Types ==========

class ReviewItemsLoaded {
  final List<ReviewItem> items;
  final List<ReviewItem> dueItems;
  ReviewItemsLoaded(this.items, this.dueItems);
}

class ReviewItemsLoading {
  ReviewItemsLoading();
}

class ReviewItemsLoadError {
  final String error;
  ReviewItemsLoadError(this.error);
}

class ReviewItemAdded {
  final ReviewItem item;
  ReviewItemAdded(this.item);
}

class ReviewItemUpdated {
  final ReviewItem item;
  ReviewItemUpdated(this.item);
}

class ReviewItemRemoved {
  final String itemId;
  ReviewItemRemoved(this.itemId);
}

// ========== Thunk Actions ==========

ThunkAction<AppState> loadReviewItems() {
  return (Store<AppState> store) async {
    final user = store.state.auth.user;
    if (user == null) {
      store.dispatch(ReviewItemsLoaded(const [], const []));
      return;
    }
    store.dispatch(ReviewItemsLoading());
    try {
      final repo = ReviewRepository(store.state.localStorageService);
      final items = await repo.getReviewItems(user.id);
      final dueItems = await repo.getDueItems(user.id);
      store.dispatch(ReviewItemsLoaded(items, dueItems));
    } catch (e) {
      store.dispatch(ReviewItemsLoadError(e.toString()));
    }
  };
}

ThunkAction<AppState> addReviewItem({
  required String questionId,
  required JLPTLevel level,
  required QuestionType type,
  bool isWrong = false,
  bool isFavorite = false,
}) {
  return (Store<AppState> store) async {
    final user = store.state.auth.user;
    if (user == null) return;
    try {
      final repo = ReviewRepository(store.state.localStorageService);
      final item = await repo.addReviewItem(
        userId: user.id,
        questionId: questionId,
        level: level,
        type: type,
        isWrong: isWrong,
        isFavorite: isFavorite,
      );
      store.dispatch(ReviewItemAdded(item));
      store.dispatch(loadReviewItems());
    } catch (_) {}
  };
}

ThunkAction<AppState> markReviewed({
  required String itemId,
  required bool correct,
}) {
  return (Store<AppState> store) async {
    try {
      final repo = ReviewRepository(store.state.localStorageService);
      final item = await repo.markReviewed(itemId: itemId, correct: correct);
      store.dispatch(ReviewItemUpdated(item));
      store.dispatch(loadReviewItems());
    } catch (_) {}
  };
}

ThunkAction<AppState> toggleFavorite(String itemId) {
  return (Store<AppState> store) async {
    try {
      final repo = ReviewRepository(store.state.localStorageService);
      final item = await repo.toggleFavorite(itemId);
      store.dispatch(ReviewItemUpdated(item));
      store.dispatch(loadReviewItems());
    } catch (_) {}
  };
}

ThunkAction<AppState> removeReviewItem(String itemId) {
  return (Store<AppState> store) async {
    try {
      final repo = ReviewRepository(store.state.localStorageService);
      await repo.removeReviewItem(itemId);
      store.dispatch(ReviewItemRemoved(itemId));
      store.dispatch(loadReviewItems());
    } catch (_) {}
  };
}
