/// 复习 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/review_actions.dart';

/// 复习状态 Reducer
Reducer<ReviewState> reviewReducer = combineReducers<ReviewState>([
  TypedReducer<ReviewState, ReviewItemsLoading>(_loading),
  TypedReducer<ReviewState, ReviewItemsLoaded>(_loaded),
  TypedReducer<ReviewState, ReviewItemsLoadError>(_loadError),
  TypedReducer<ReviewState, ReviewItemAdded>(_itemAdded),
  TypedReducer<ReviewState, ReviewItemUpdated>(_itemUpdated),
  TypedReducer<ReviewState, ReviewItemRemoved>(_itemRemoved),
]);

ReviewState _loading(ReviewState state, ReviewItemsLoading action) {
  return state.copyWith(loading: true, clearError: true);
}

ReviewState _loaded(ReviewState state, ReviewItemsLoaded action) {
  return state.copyWith(
    reviewItems: action.items,
    dueItems: action.dueItems,
    loading: false,
  );
}

ReviewState _loadError(ReviewState state, ReviewItemsLoadError action) {
  return state.copyWith(loading: false, error: action.error);
}

ReviewState _itemAdded(ReviewState state, ReviewItemAdded action) {
  final items = [...state.reviewItems, action.item];
  return state.copyWith(reviewItems: items);
}

ReviewState _itemUpdated(ReviewState state, ReviewItemUpdated action) {
  final items = state.reviewItems.map((item) {
    return item.id == action.item.id ? action.item : item;
  }).toList();
  return state.copyWith(reviewItems: items);
}

ReviewState _itemRemoved(ReviewState state, ReviewItemRemoved action) {
  final items = state.reviewItems.where((item) => item.id != action.itemId).toList();
  return state.copyWith(reviewItems: items);
}
