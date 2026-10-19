/// 错题本 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/wrong_book_actions.dart';

/// 错题本状态 Reducer
Reducer<WrongBookState> wrongBookReducer = combineReducers<WrongBookState>([
  TypedReducer<WrongBookState, WrongBookLevelFilterChanged>(_levelFilterChanged),
  TypedReducer<WrongBookState, WrongBookTypeFilterChanged>(_typeFilterChanged),
  TypedReducer<WrongBookState, WrongBookSortChanged>(_sortChanged),
  TypedReducer<WrongBookState, WrongBookCleared>(_cleared),
  TypedReducer<WrongBookState, WrongBookItemsFiltered>(_itemsFiltered),
]);

WrongBookState _levelFilterChanged(WrongBookState state, WrongBookLevelFilterChanged action) {
  return state.copyWith(
    levelFilter: action.level,
    clearLevel: action.level == null,
  );
}

WrongBookState _typeFilterChanged(WrongBookState state, WrongBookTypeFilterChanged action) {
  return state.copyWith(
    typeFilter: action.type,
    clearType: action.type == null,
  );
}

WrongBookState _sortChanged(WrongBookState state, WrongBookSortChanged action) {
  return state.copyWith(sortBy: action.sort);
}

WrongBookState _cleared(WrongBookState state, WrongBookCleared action) {
  return const WrongBookState();
}

WrongBookState _itemsFiltered(WrongBookState state, WrongBookItemsFiltered action) {
  return state.copyWith(filteredItems: action.items);
}
